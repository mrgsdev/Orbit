import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/ui/home_page.dart';
import 'package:orbit/ui/widgets.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    EditableText.debugDeterministicCursor = true;
  });

  testWidgets('⌘F: поиск по имени, стрелки и Enter открывают карточку отдельным окном', (t) async {
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final root = Directory.systemTemp.createTempSync('orbit_spot');
    addTearDown(() => root.deleteSync(recursive: true));
    final now = DateTime.now().toIso8601String();
    File('${root.path}/contacts.json').writeAsStringSync(jsonEncode([
      for (final (id, name) in [('a', 'Анна Смирнова'), ('b', 'Борис Иванов'), ('c', 'Иван Анисимов')])
        {'id': id, 'name': name, 'createdAt': now, 'updatedAt': now},
    ]));
    final store = ContactStore();
    final vault = Vault(root);
    await t.runAsync(() async => store.load(root: root, cipher: await DataCipher.generate()));

    await t.pumpWidget(CupertinoApp(
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      builder: (context, child) => ToastHost(child: child!),
      home: HomePage(store: store, vault: vault, onLock: () {}),
    ));
    await t.pumpAndSettle();

    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyF);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(find.text('Имя человека…'), findsOneWidget);

    // «ан»: сначала те, у кого имя или фамилия начинается с «ан».
    await t.enterText(find.widgetWithText(CupertinoTextField, 'Имя человека…'), 'ан');
    await t.pumpAndSettle();
    expect(find.text('КОНТАКТЫ'), findsOneWidget);
    // «Борис Иванов» тоже подходит («Иванов»), но идёт последним.
    double y(String name) => t.getTopLeft(find.textContaining(name, findRichText: true).last).dy;
    expect(y('Анна'), lessThan(y('Иван Анисимов')));
    expect(y('Иван Анисимов'), lessThan(y('Борис')));

    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    // Открылась отдельная карточка — второй по порядку: «Иван Анисимов»,
    // а главный экран остался на месте.
    expect(find.text('Имя человека…'), findsNothing);
    expect(find.text('Изменить'), findsOneWidget);
    expect(find.text('Иван Анисимов'), findsOneWidget);
    expect(find.text('Всего контактов'), findsOneWidget);

    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('Изменить'), findsNothing);
    expect(find.text('Всего контактов'), findsOneWidget);
  });
}
