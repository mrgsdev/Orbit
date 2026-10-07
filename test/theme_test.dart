import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/main.dart';
import 'package:orbit/ui/appearance.dart';
import 'package:orbit/ui/theme.dart';

void main() {
  late Directory root;

  setUpAll(() => initializeDateFormatting('ru'));
  setUp(() => root = Directory.systemTemp.createTempSync('orbit_theme'));
  tearDown(() {
    Pal.current = Palette.dark;
    root.deleteSync(recursive: true);
  });

  Finder canvas(Palette p) => find.byWidgetPredicate((w) => w is ColoredBox && w.color == p.canvas);

  testWidgets('тема меняется сразу, без перезапуска и без потери ввода', (t) async {
    final vault = Vault(root);
    await t.runAsync(vault.load);
    final appearance = Appearance.memory(ThemeChoice.dark);
    await t.pumpWidget(ContactsApp(root: root, vault: vault, appearance: appearance));
    expect(canvas(Palette.dark), findsOneWidget);
    await t.enterText(find.byType(CupertinoTextField).first, '1357');

    appearance.choice = ThemeChoice.light;
    await t.pumpAndSettle();
    expect(Pal.current, same(Palette.light));
    expect(canvas(Palette.light), findsOneWidget);
    expect(canvas(Palette.dark), findsNothing);
    // Состояние экрана сохранилось.
    expect(find.text('Защитите базу'), findsOneWidget);
    expect(t.widget<CupertinoTextField>(find.byType(CupertinoTextField).first).controller!.text, '1357');

    // Системная тема следует за настройкой macOS.
    t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
    appearance.choice = ThemeChoice.system;
    await t.pumpAndSettle();
    expect(canvas(Palette.dark), findsOneWidget);
    t.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await t.pumpAndSettle();
    expect(canvas(Palette.light), findsOneWidget);
  });

  test('выбор темы сохраняется рядом с базой', () async {
    final a = await Appearance.load(root);
    expect(a.choice, ThemeChoice.system);
    a.choice = ThemeChoice.light;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await Appearance.load(root)).choice, ThemeChoice.light);
  });
}
