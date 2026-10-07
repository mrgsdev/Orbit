import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/data/csv_export.dart';
import 'package:orbit/data/importers.dart';
import 'package:orbit/l10n/ru.dart';
import 'package:orbit/l10n/strings.dart';
import 'package:orbit/main.dart';
import 'package:orbit/models/contact.dart';
import 'package:orbit/ui/appearance.dart';
import 'package:orbit/ui/home_page.dart';
import 'package:orbit/ui/language.dart';
import 'package:orbit/ui/settings_page.dart';
import 'package:orbit/ui/widgets.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    EditableText.debugDeterministicCursor = true;
  });
  tearDown(() => tr = const Ru());

  for (final lang in languages) {
    testWidgets('${lang.languageName}: главные экраны без переполнений в маленьком окне', (t) async {
      tr = lang;
      t.view.physicalSize = const Size(1080, 680);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final root = Directory.systemTemp.createTempSync('orbit_l10n');
      addTearDown(() => root.deleteSync(recursive: true));
      final now = DateTime.now();
      File('${root.path}/contacts.json').writeAsStringSync(jsonEncode([
        {
          'id': 'a',
          'name': 'Анна Смирнова',
          'phones': [
            {'label': 'мобильный', 'value': '+7 900 000-00-00'},
            {'label': 'рабочий', 'value': '+7 900 000-00-01'},
          ],
          'interests': ['Дизайн'],
          'birthday': DateTime(1990, now.month, now.day).add(const Duration(days: 3)).toIso8601String(),
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      ]));
      final store = ContactStore();
      await t.runAsync(() async => store.load(root: root, cipher: await DataCipher.generate()));

      await t.pumpWidget(CupertinoApp(
        locale: Locale(lang.locale),
        supportedLocales: [for (final l in languages) Locale(l.locale)],
        localizationsDelegates: const [GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        builder: (context, child) => ToastHost(child: child!),
        home: HomePage(store: store, vault: Vault(root), onLock: () {}),
      ));
      await t.pumpAndSettle();
      expect(find.text(lang.totalContacts), findsOneWidget);
      expect(t.takeException(), isNull, reason: 'главная');

      await t.tap(find.text(lang.personalBase));
      await t.pumpAndSettle();
      expect(find.text(lang.menuImport), findsOneWidget);
      expect(t.takeException(), isNull, reason: 'меню');
      await t.tapAt(const Offset(500, 600));
      await t.pumpAndSettle();

      await t.tap(find.byIcon(Segment.all.icon).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Анна Смирнова').first);
      await t.pumpAndSettle();
      expect(find.text('${lang.phone} · ${lang.labelMobile}'), findsOneWidget);
      expect(t.takeException(), isNull, reason: 'контакты');

      await t.tap(find.text(lang.columns));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'столбцы');
      await t.tapAt(const Offset(500, 600));
      await t.pumpAndSettle();

      await t.tap(find.text(lang.edit));
      await t.pumpAndSettle();
      expect(find.text(lang.editContact), findsOneWidget);
      expect(t.takeException(), isNull, reason: 'редактор');
      await t.tap(find.text(lang.cancel).last);
      await t.pumpAndSettle();

      for (final s in [Segment.favorites, Segment.recent, Segment.trash]) {
        await t.tap(find.byIcon(s.icon).first);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: s.name);
      }

      // Настройки по ⌘, — каждый раздел без переполнений.
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.comma);
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await t.pumpAndSettle();
      expect(find.text(lang.languageHint), findsOneWidget);
      for (final section in SettingsSection.values) {
        await t.tap(find.text(section.label).first);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'настройки: ${section.name}');
      }
    });

    test('${lang.languageName}: экспорт CSV читается обратно', () {
      tr = lang;
      final now = DateTime(2026, 1, 1);
      final csv = contactsToCsv([
        Contact(
          id: 'x',
          name: 'Ann',
          phones: const [LabeledValue('мобильный', '+1 555')],
          company: 'Orbit',
          favorite: true,
          createdAt: now,
          updatedAt: now,
        ),
      ], []);
      tr = const Ru();
      final back = parseContactsFile(csv, []).contacts.single;
      expect(back.name, 'Ann');
      expect(back.phone, '+1 555');
      expect(back.company, 'Orbit');
      expect(back.favorite, isTrue);
    });
  }

  testWidgets('язык меняется сразу и сохраняется выбор «как в системе»', (t) async {
    final root = Directory.systemTemp.createTempSync('orbit_lang');
    addTearDown(() => root.deleteSync(recursive: true));
    final vault = Vault(root);
    await t.runAsync(vault.load);
    final language = LanguageSetting.memory('ru');
    await t.pumpWidget(ContactsApp(root: root, vault: vault, appearance: Appearance.memory(), language: language));
    expect(find.text('Защитите базу'), findsOneWidget);

    language.code = 'en';
    await t.pumpAndSettle();
    expect(find.text('Protect your base'), findsOneWidget);

    language.code = 'zh';
    await t.pumpAndSettle();
    expect(find.text('保护你的通讯录'), findsOneWidget);

    // «Как в системе»: берётся первый поддерживаемый язык macOS.
    t.platformDispatcher.localesTestValue = const [Locale('de'), Locale('fr')];
    addTearDown(t.platformDispatcher.clearLocalesTestValue);
    language.code = null;
    await t.pumpAndSettle();
    expect(find.text('Protégez votre base'), findsOneWidget);
  });
}
