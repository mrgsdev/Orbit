import 'dart:convert';
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
  setUpAll(() async {
    await initializeDateFormatting('ru');
    EditableText.debugDeterministicCursor = true;
  });

  // Ни при каком размере окна ничего не должно вылезать за границы.
  // Даже если окно на мгновение меньше минимума (700×300), полос нет.
  // Окно резко тянут: проходим высоты подряд — панель слева не должна
  // переполниться ни на одной.
  testWidgets('высота окна от 300 до 950: левая панель без переполнений', (t) async {
    final root = Directory.systemTemp.createTempSync('orbit_rail');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = ContactStore();
    await t.runAsync(() async => store.load(root: root, cipher: await DataCipher.generate()));
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    for (var h = 300.0; h <= 950; h += 7) {
      t.view.physicalSize = Size(1080, h);
      await t.pumpWidget(CupertinoApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        builder: (context, child) => ToastHost(child: child!),
        home: HomePage(store: store, vault: Vault(root), onLock: () {}),
      ));
      await t.pump();
      expect(t.takeException(), isNull, reason: 'высота $h');
    }
  });

  for (final size in const [Size(700, 300), Size(1080, 480), Size(1080, 630), Size(1080, 720), Size(1440, 900)]) {
    testWidgets('окно ${size.width.round()}×${size.height.round()}: без переполнений', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      final root = Directory.systemTemp.createTempSync('orbit_layout');
      addTearDown(() => root.deleteSync(recursive: true));
      final now = DateTime.now().toIso8601String();
      File('${root.path}/contacts.json').writeAsStringSync(jsonEncode([
        {'id': 'a', 'name': 'Анна Смирнова', 'interests': ['Дизайн'], 'createdAt': now, 'updatedAt': now},
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
      expect(t.takeException(), isNull, reason: 'главная');

      await t.tap(find.byIcon(CupertinoIcons.person_2).first);
      await t.pumpAndSettle();
      await t.tap(find.text('Анна Смирнова').first);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'контакты');
    });
  }
}
