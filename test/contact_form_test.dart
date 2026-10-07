import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/models/contact.dart';
import 'package:orbit/ui/contact_detail.dart';
import 'package:orbit/ui/contact_form.dart';
import 'package:orbit/ui/widgets.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    // Мигающий курсор не даёт pumpAndSettle дождаться покоя.
    EditableText.debugDeterministicCursor = true;
  });

  testWidgets('несколько телефонов и адресов: ввод, сохранение, просмотр', (t) async {
    t.view.physicalSize = const Size(1400, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final root = Directory.systemTemp.createTempSync('orbit_form');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = ContactStore();
    await t.runAsync(() async => store.load(root: root, cipher: await DataCipher.generate()));

    Contact? saved;
    late BuildContext host;
    Widget app(Widget child) => CupertinoApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: const [GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          builder: (context, child) => ToastHost(child: child!),
          home: Builder(builder: (context) {
            host = context;
            return child;
          }),
        );
    await t.pumpWidget(app(const SizedBox()));
    showContactEditor(host, store: store).then((c) => saved = c);
    await t.pumpAndSettle();

    Finder field(String placeholder) => find.widgetWithText(CupertinoTextField, placeholder);
    await t.enterText(field('Имя и фамилия'), 'Анна');
    await t.enterText(field('+7 900 000-00-00'), '+7 900 111-11-11');
    await t.tap(find.text('Добавить телефон'));
    await t.pump();
    // Второй номер по умолчанию получает следующую подпись — «рабочий».
    await t.enterText(field('+7 900 000-00-00').last, '+7 495 222-22-22');
    await t.enterText(field('name@example.com'), 'anna@x.io');
    await t.tap(find.text('Добавить email'));
    await t.pump();
    await t.enterText(field('name@example.com').last, 'не почта');

    // Неверный второй адрес не даёт сохранить.
    await t.tap(find.text('Добавить'));
    await t.pump();
    expect(find.text('Некорректный email'), findsOneWidget);

    await t.enterText(find.widgetWithText(CupertinoTextField, 'не почта'), 'anna@work.io');
    await t.tap(find.text('Добавить'));
    for (var i = 0; i < 100 && saved == null; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
    }
    expect(saved!.phones, const [
      LabeledValue('мобильный', '+7 900 111-11-11'),
      LabeledValue('рабочий', '+7 495 222-22-22'),
    ]);
    expect(saved!.emails, const [
      LabeledValue('личный', 'anna@x.io'),
      LabeledValue('рабочий', 'anna@work.io'),
    ]);

    await t.pumpWidget(app(ContactDetail(
      contact: store.contacts.single,
      store: store,
      onEdit: () {},
      onDelete: () {},
      onRestore: () {},
      onPurge: () {},
    )));
    await t.pumpAndSettle();
    expect(find.text('Телефон · рабочий'), findsOneWidget);
    expect(find.text('+7 495 222-22-22'), findsOneWidget);
    expect(find.text('Email · рабочий'), findsOneWidget);
    // Звонить из карточки нельзя — номера только показываются.
    expect(find.text('Позвонить'), findsNothing);
  });
}
