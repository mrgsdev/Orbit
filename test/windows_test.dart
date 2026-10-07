import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/l10n/strings.dart';
import 'package:orbit/ui/home_page.dart';
import 'package:orbit/ui/hotkeys.dart';
import 'package:orbit/ui/platform.dart';
import 'package:orbit/ui/settings_page.dart';
import 'package:orbit/ui/widgets.dart';

/// Windows: Ctrl вместо ⌘, подписи «Ctrl+F», без упоминаний Mac.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    EditableText.debugDeterministicCursor = true;
  });
  setUp(() => Os.isMac = false);
  tearDown(() => Os.isMac = true);

  test('сочетания по умолчанию — с Ctrl, подписи в стиле Windows', () {
    final h = Hotkeys.memory();
    expect(h.of(HotkeyAction.search).label, 'Ctrl+F');
    expect(h.of(HotkeyAction.lock).label, 'Ctrl+Shift+L');
    expect(h.of(HotkeyAction.goTrash).label, 'Ctrl+6');
    expect(reservedCombos, contains(const Combo(LogicalKeyboardKey.f4, alt: true)));
    // Клавиша Win сама по себе модификатором не считается.
    expect(const Combo(LogicalKeyboardKey.keyK, meta: true).hasModifier, isFalse);
    for (final (keys, _) in fixedHotkeys) {
      expect(keys, isNot(contains('⌘')));
    }
  });

  test('в текстах нет Mac, macOS, Finder и ⌘', () {
    for (final l in languages) {
      tr = l;
      for (final s in [
        l.revealIntro, l.saveRecoverySubtitle, l.recoveryRowHint, l.appearanceHint,
        l.onbPrivacyTitle, l.onbPrivacyText, l.noSelectionSubtitle(Os.mod, Os.shift),
        l.formShortcuts('Ctrl+S'), l.lockRowHint('Ctrl+Shift+L'), Os.showFolderLabel,
      ]) {
        expect(s, isNot(matches(RegExp(r'\bMac\b|macOS|Finder|⌘'))), reason: '${l.locale}: $s');
      }
    }
    tr = languages.first;
  });

  testWidgets('Ctrl+цифра переключает разделы, Ctrl+клик выделяет несколько', (t) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final root = Directory.systemTemp.createTempSync('orbit_win');
    addTearDown(() => root.deleteSync(recursive: true));
    final now = DateTime.now().toIso8601String();
    File('${root.path}/contacts.json').writeAsStringSync(jsonEncode([
      {'id': 'a', 'name': 'Анна', 'createdAt': now, 'updatedAt': now},
      {'id': 'b', 'name': 'Борис', 'createdAt': now, 'updatedAt': now},
    ]));
    final store = ContactStore();
    await t.runAsync(() async => store.load(root: root, cipher: await DataCipher.generate()));
    await t.pumpWidget(CupertinoApp(
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      builder: (context, child) => ToastHost(child: child!),
      home: HomePage(store: store, vault: Vault(root), onLock: () {}),
    ));
    await t.pumpAndSettle();
    expect(find.text('Ctrl+F'), findsOneWidget, reason: 'подсказка в поиске');

    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.digit2);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(find.text('Анна'), findsWidgets);

    await t.tap(find.text('Анна').first);
    await t.pumpAndSettle();
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.tap(find.text('Борис').first);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(find.text('Выбрано: 2 контакта'), findsOneWidget);

    // Настройки по Ctrl+, — сочетания подписаны по-виндовому.
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.comma);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    await t.tap(find.text(SettingsSection.shortcuts.label).first);
    await t.pumpAndSettle();
    expect(find.text('Ctrl+Shift+L'), findsOneWidget);
    expect(find.textContaining('⌘'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
