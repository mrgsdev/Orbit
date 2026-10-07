import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/ui/home_page.dart';
import 'package:orbit/ui/widgets.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  Finder art(String name) => find.byWidgetPredicate(
      (w) => w is Image && w.image is ResizeImage && '${(w.image as ResizeImage).imageProvider}'.contains(name));

  for (final withContacts in [false, true]) {
    testWidgets('пустые «Избранные» и «Корзина» со своими картинками (контакты: $withContacts)', (t) async {
      t.view.physicalSize = const Size(1440, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final root = Directory.systemTemp.createTempSync('orbit_empty');
      addTearDown(() => root.deleteSync(recursive: true));
      if (withContacts) {
        File('${root.path}/contacts.json').writeAsStringSync(
            '[{"id":"c","name":"Иван","createdAt":"2026-10-01T00:00:00.000","updatedAt":"2026-10-01T00:00:00.000"}]');
      }
      final store = ContactStore();
      await t.runAsync(() async => store.load(root: root, cipher: await DataCipher.generate()));
      await t.pumpWidget(CupertinoApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        builder: (context, child) => ToastHost(child: child!),
        home: HomePage(store: store, vault: Vault(root), onLock: () {}),
      ));

      await t.tap(find.byIcon(CupertinoIcons.star).first);
      await t.pumpAndSettle();
      expect(find.text('В избранном пока никого'), findsOneWidget);
      expect(art('empty_favorites.png'), findsOneWidget);

      if (!withContacts) {
        // Новые за месяц: тестовый контакт может попасть в последние 30 дней, поэтому — на пустой базе.
        await t.tap(find.byIcon(Segment.recent.icon).first);
        await t.pumpAndSettle();
        expect(find.text('Новых знакомств пока нет'), findsOneWidget);
        expect(art('card_new.png'), findsOneWidget);

        await t.tap(find.byIcon(Segment.birthdays.icon).first);
        await t.pumpAndSettle();
        expect(find.text('Ближайших дней рождения нет'), findsOneWidget);
        expect(art('card_birthdays.png'), findsOneWidget);
      }

      await t.tap(find.byIcon(CupertinoIcons.trash).first);
      await t.pumpAndSettle();
      expect(find.text('Корзина пуста'), findsOneWidget);
      expect(art('empty_trash.png'), findsOneWidget);
    });
  }
}
