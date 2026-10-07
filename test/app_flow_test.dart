import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/main.dart';
import 'package:orbit/ui/appearance.dart';
import 'package:orbit/ui/widgets.dart';

void main() {
  late Directory root;

  setUpAll(() async {
    await initializeDateFormatting('ru');
    // Мигающий курсор не даёт pumpAndSettle дождаться покоя.
    EditableText.debugDeterministicCursor = true;
  });
  setUp(() => root = Directory.systemTemp.createTempSync('orbit_flow'));
  tearDown(() => root.deleteSync(recursive: true));

  /// Ждёт реальной асинхронной работы (Argon2 в изоляте, файлы), пока не появится [finder].
  Future<void> waitFor(WidgetTester t, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(finder, findsWidgets);
  }

  Finder fields() => find.byType(CupertinoTextField);
  Finder hint(String prefix) => find.byWidgetPredicate((w) => w is Hint && w.message.startsWith(prefix));

  testWidgets('настройка PIN, шифрование, корзина с отменой, блокировка', (t) async {
    t.view.physicalSize = const Size(1600, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    final now = DateTime.now().toIso8601String();
    File('${root.path}/contacts.json').writeAsStringSync(jsonEncode([
      {'id': 'a', 'name': 'Анна Смирнова', 'createdAt': now, 'updatedAt': now},
      {'id': 'b', 'name': 'Борис Иванов', 'createdAt': now, 'updatedAt': now},
    ]));
    final vault = Vault(root);
    await t.runAsync(vault.load);

    await t.pumpWidget(ContactsApp(root: root, vault: vault, appearance: Appearance.memory()));
    expect(find.text('Защитите базу'), findsOneWidget);

    // Короткий PIN не принимается.
    await t.enterText(fields().at(0), '123');
    await t.enterText(fields().at(1), '123');
    await t.tap(find.text('Продолжить'));
    await t.pump();
    expect(find.text('Не короче 6 символов'), findsOneWidget);

    await t.enterText(fields().at(0), '135790');
    await t.enterText(fields().at(1), '135790');
    await t.tap(find.text('Продолжить'));
    await waitFor(t, find.text('Сохраните recovery code'));

    final code = (t.widget(find.byKey(const Key('recovery-code'))) as Text).data!;
    expect(RecoveryCode.looksValid(code), isTrue);

    // Пока не отмечено «сохранил», открыть нельзя.
    await t.tap(find.text('Открыть Orbit'));
    await t.pump();
    expect(find.text('Сохраните recovery code'), findsOneWidget);
    await t.tap(find.byType(Check));
    await t.pump();
    await t.tap(find.text('Открыть Orbit'));
    await waitFor(t, find.text('Всего контактов'));

    // Первый запуск — знакомство. Его можно пропустить.
    await waitFor(t, find.text('Добро пожаловать в Orbit'));
    await t.tap(find.text('Пропустить'));
    await t.pumpAndSettle();
    expect(find.text('Добро пожаловать в Orbit'), findsNothing);

    // Старая открытая база теперь зашифрована.
    final db = await t.runAsync(() => File('${root.path}/contacts.json').readAsBytes());
    expect(DataCipher.isEncrypted(db!), isTrue);

    // Список контактов; удаление уходит в корзину, «Отменить» возвращает.
    await t.tap(hint('Контакты'));
    await t.pumpAndSettle();
    await t.tap(find.text('Анна Смирнова').first);
    await t.pumpAndSettle();
    await t.tap(hint('В корзину'));
    await waitFor(t, find.text('Отменить'));
    expect(find.text('Анна Смирнова'), findsNothing);
    await t.tap(find.text('Отменить'));
    await waitFor(t, find.text('Анна Смирнова'));

    // Ещё раз удаляем — клавишей ⌫ — и восстанавливаем уже из корзины.
    await t.tap(find.text('Анна Смирнова').first);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.backspace);
    await waitFor(t, find.text('Отменить'));
    await t.tap(hint('Корзина'));
    await t.pumpAndSettle();
    await t.tap(find.text('Анна Смирнова').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Восстановить'));
    await waitFor(t, find.text('Корзина пуста'));

    // Блокировка и неверный PIN.
    await t.tap(hint('Заблокировать'));
    await t.pumpAndSettle();
    expect(find.text('Orbit заблокирован'), findsOneWidget);
    await t.enterText(fields(), '000000');
    await t.tap(find.text('Открыть'));
    await waitFor(t, find.text('Неверный PIN-код'));
    await t.enterText(fields(), '135790');
    await t.tap(find.text('Открыть'));
    await waitFor(t, find.text('Всего контактов'));
    // Знакомство показывается только при первом запуске.
    await t.pumpAndSettle();
    expect(find.text('Добро пожаловать в Orbit'), findsNothing);
  });
}
