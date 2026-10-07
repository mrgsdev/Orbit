import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/ui/home_page.dart';
import 'package:orbit/ui/hotkeys.dart';
import 'package:orbit/ui/widgets.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    EditableText.debugDeterministicCursor = true;
  });

  Future<(ContactStore, Directory)> setUp(WidgetTester t, {Hotkeys? hotkeys}) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final root = Directory.systemTemp.createTempSync('orbit_onb');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = ContactStore();
    await t.runAsync(() async => store.load(root: root, cipher: await DataCipher.generate()));
    Widget app = CupertinoApp(
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      builder: (context, child) => ToastHost(child: child!),
      home: HomePage(store: store, vault: Vault(root), onLock: () {}, onboarding: true),
    );
    if (hotkeys != null) app = HotkeysScope(hotkeys: hotkeys, child: app);
    await t.pumpWidget(app);
    await t.pumpAndSettle();
    return (store, root);
  }

  testWidgets('знакомство: пять шагов, без длинных тире', (t) async {
    await setUp(t);
    expect(find.text('Добро пожаловать в Orbit'), findsOneWidget);

    for (final title in ['Все люди под рукой', 'Ничего не забудете', 'Только на вашем компьютере', 'Горячие клавиши']) {
      await t.tap(find.text('Далее'));
      await t.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining('—'), findsNothing);
      expect(t.takeException(), isNull);
    }
    // На последнем шаге — сочетания и подсказка, где их поменять.
    expect(find.text('⌘F'), findsWidgets);
    expect(find.textContaining('Настройках → Горячие клавиши'), findsOneWidget);

    await t.tap(find.text('Начать'));
    await t.pumpAndSettle();
    expect(find.text('Горячие клавиши'), findsNothing);
  });

  testWidgets('«Изменить сочетания» открывает настройки клавиш; новое сочетание работает', (t) async {
    final hotkeys = Hotkeys.memory();
    await setUp(t, hotkeys: hotkeys);
    for (var i = 0; i < 4; i++) {
      await t.tap(find.text('Далее'));
      await t.pumpAndSettle();
    }
    await t.tap(find.text('Изменить сочетания'));
    await t.pumpAndSettle();
    expect(find.text('Быстрый поиск'), findsOneWidget);

    // Переназначаем «Быстрый поиск» на ⌥⌘K.
    await t.tap(find.text('Изменить').first);
    await t.pumpAndSettle();
    expect(find.text('Нажмите сочетание…'), findsOneWidget);
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(hotkeys.of(HotkeyAction.search).label, '⌥⌘K');
    expect(find.text('⌥⌘K'), findsWidgets);

    // Занятое другим действием сочетание не принимается.
    await t.tap(find.text('Изменить').first);
    await t.pumpAndSettle();
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyN);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(hotkeys.of(HotkeyAction.search).label, '⌥⌘K');
    expect(find.textContaining('уже у действия «Новый контакт»'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();

    // Новое сочетание открывает быстрый поиск, старое — нет.
    await t.tap(find.byIcon(CupertinoIcons.house).first);
    await t.pumpAndSettle();
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyF);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(find.text('Имя человека…'), findsNothing);
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(find.text('Имя человека…'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();

    // Остальные сочетания после смены работают без перезапуска.
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.digit2);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(find.text('Поиск по контактам…'), findsOneWidget);
    expect(find.text('Контакты'), findsWidgets);
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.comma);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(find.text('Основные'), findsWidgets);
  });
}
