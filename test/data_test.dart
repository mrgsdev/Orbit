import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/data/backup.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/data/importers.dart';
import 'package:orbit/models/field_schema.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('orbit_test'));
  tearDown(() => root.deleteSync(recursive: true));

  group('vault', () {
    test('PIN и recovery code открывают один и тот же ключ', () async {
      final vault = Vault(root);
      final (cipher, code) = await vault.create('123456');
      expect(RecoveryCode.looksValid(code), isTrue);
      final secret = await cipher.encrypt(utf8.encode('привет'));

      final reopened = Vault(root);
      await reopened.load();
      expect(reopened.isSetUp, isTrue);
      final byPin = await reopened.unlock('123456');
      expect(utf8.decode(await byPin.decrypt(secret)), 'привет');
      // Код вводят с пробелами вместо дефисов — это не важно.
      final byCode = await reopened.unlockWithRecovery(code.replaceAll('-', ' '));
      expect(utf8.decode(await byCode.decrypt(secret)), 'привет');

      await expectLater(reopened.unlock('000000'), throwsA(isA<WrongSecretException>()));
      await expectLater(reopened.unlockWithRecovery(RecoveryCode.generate()),
          throwsA(isA<WrongSecretException>()));
    });

    test('смена PIN не меняет ключ данных', () async {
      final vault = Vault(root);
      final (cipher, code) = await vault.create('111111');
      final secret = await cipher.encrypt([1, 2, 3]);
      await vault.changePin(cipher, '222222');
      await expectLater(vault.unlock('111111'), throwsA(isA<WrongSecretException>()));
      expect(await (await vault.unlock('222222')).decrypt(secret), [1, 2, 3]);
      expect(await (await vault.unlockWithRecovery(code)).decrypt(secret), [1, 2, 3]);
    });
  });

  group('store', () {
    test('старая открытая база шифруется при первой загрузке', () async {
      final now = DateTime.now().toIso8601String();
      File('${root.path}/contacts.json').writeAsStringSync(jsonEncode([
        {'id': 'a', 'name': 'Анна', 'photoFile': 'p.jpg', 'createdAt': now, 'updatedAt': now},
      ]));
      Directory('${root.path}/photos').createSync();
      File('${root.path}/photos/p.jpg').writeAsBytesSync([9, 9, 9]);

      final cipher = await DataCipher.generate();
      final store = ContactStore();
      await store.load(root: root, cipher: cipher);
      expect(store.contacts.single.name, 'Анна');

      final db = File('${root.path}/contacts.json').readAsBytesSync();
      expect(DataCipher.isEncrypted(db), isTrue);
      expect(utf8.decode(db, allowMalformed: true), isNot(contains('Анна')));
      expect(DataCipher.isEncrypted(File('${root.path}/photos/p.jpg').readAsBytesSync()), isTrue);
      expect(await store.readPhoto('p.jpg'), [9, 9, 9]);

      // Повторная загрузка тем же ключом читает зашифрованную базу.
      final again = ContactStore();
      await again.load(root: root, cipher: cipher);
      expect(again.contacts.single.name, 'Анна');
    });

    test('корзина: удаление, восстановление, очистка', () async {
      final store = ContactStore();
      await store.load(root: root, cipher: await DataCipher.generate());
      final ids = await store.addImported(parseContactsFile('Имя,Телефон\nАнна,1\nБорис,2', []).contacts);
      expect(store.contacts, hasLength(2));

      await store.deleteMany({ids.first});
      expect(store.contacts, hasLength(1));
      expect(store.trash.single.id, ids.first);

      await store.restore({ids.first});
      expect(store.contacts, hasLength(2));
      expect(store.trash, isEmpty);

      await store.deleteMany(ids);
      await store.emptyTrash();
      expect(store.contacts, isEmpty);
      expect(store.trash, isEmpty);
    });

    test('резервная копия открывается на другой установке по recovery code', () async {
      final vault = Vault(root);
      final (cipher, code) = await vault.create('123456');
      final store = ContactStore();
      await store.load(root: root, cipher: cipher);
      await store.addImported(
        parseContactsFile('Имя,Email\nАнна,anna@mail.ru', []).contacts,
        photos: const {},
      );
      final file = await Backup.build(
        snapshot: await store.snapshot(),
        cipher: cipher,
        envelope: vault.envelope!,
      );
      expect(utf8.decode(file, allowMalformed: true), isNot(contains('anna@mail.ru')));

      final otherRoot = Directory.systemTemp.createTempSync('orbit_other');
      addTearDown(() => otherRoot.deleteSync(recursive: true));
      final other = ContactStore();
      final otherCipher = await DataCipher.generate();
      await other.load(root: otherRoot, cipher: otherCipher);

      final backup = Backup.parse(file);
      expect(backup.contactCount, 1);
      await expectLater(backup.open(otherCipher), throwsA(isA<WrongSecretException>()));
      final result = await other.mergeSnapshot(await backup.openWithRecovery(code));
      expect(result.added, 1);
      expect(other.contacts.single.email, 'anna@mail.ru');

      // Повторное восстановление той же копии ничего не дублирует.
      expect((await other.mergeSnapshot(await backup.openWithRecovery(code))).added, 0);
    });
  });

  group('import', () {
    test('CSV-экспорт Orbit и Excel с точкой с запятой', () {
      final fields = [const CustomField(id: 'city', label: 'Город')];
      final orbit = parseContactsFile(
        '﻿Имя,Телефон,Telegram,Интересы,День рождения,Избранное,Город\r\n'
        '"Иванов, Пётр",+7 900,@petr,"Бег, Книги",1990-05-12,да,Москва\r\n',
        fields,
      ).contacts.single;
      expect(orbit.name, 'Иванов, Пётр');
      expect(orbit.telegramHandle, 'petr');
      expect(orbit.interests, ['Бег', 'Книги']);
      expect(orbit.birthday, DateTime(1990, 5, 12));
      expect(orbit.favorite, isTrue);
      expect(orbit.custom['city'], 'Москва');

      final excel = parseContactsFile('Имя;Заметки\nОля;"строка 1\nстрока 2"\n', []).contacts.single;
      expect(excel.notes, 'строка 1\nстрока 2');
    });

    test('Google CSV: имя из двух колонок', () {
      final c = parseContactsFile(
        'First Name,Last Name,E-mail 1 - Value,Organization 1 - Name\nJohn,Smith,j@x.io,ACME\n',
        [],
      ).contacts.single;
      expect(c.name, 'John Smith');
      expect(c.email, 'j@x.io');
      expect(c.company, 'ACME');
    });

    test('vCard из «Контактов» macOS', () {
      final photo = base64.encode([1, 2, 3, 4]);
      final parsed = parseContactsFile(
        'BEGIN:VCARD\r\nVERSION:3.0\r\nN:Смирнова;Анна;;;\r\nFN:Анна Смирнова\r\n'
        'ORG:Яндекс;\r\nTITLE:Продакт\r\nTEL;type=CELL;type=VOICE:+7 900 123-45-67\r\n'
        'EMAIL;type=INTERNET:anna@ya.ru\r\nBDAY:1993-10-09\r\n'
        'NOTE:Первая строка\\nвторая\\, с запятой\r\n'
        'X-SOCIALPROFILE;type=telegram:https://t.me/anna_s\r\n'
        'PHOTO;ENCODING=b;TYPE=JPEG:${photo.substring(0, 4)}\r\n ${photo.substring(4)}\r\n'
        'END:VCARD\r\n'
        'BEGIN:VCARD\r\nVERSION:2.1\r\nN;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=D0=9E=D0=BB=D0=B5=D0=B3;;;;\r\n'
        'TEL;CELL:+7911\r\nEND:VCARD\r\n',
        [],
      );
      final anna = parsed.contacts.first;
      expect(anna.name, 'Анна Смирнова');
      expect(anna.company, 'Яндекс');
      expect(anna.position, 'Продакт');
      expect(anna.phone, '+7 900 123-45-67');
      expect(anna.email, 'anna@ya.ru');
      expect(anna.birthday, DateTime(1993, 10, 9));
      expect(anna.notes, 'Первая строка\nвторая, с запятой');
      expect(anna.telegramHandle, 'anna_s');
      expect(parsed.photos[anna.id], [1, 2, 3, 4]);

      final oleg = parsed.contacts.last;
      expect(oleg.name, 'Олег');
      expect(oleg.phone, '+7911');
    });
  });
}
