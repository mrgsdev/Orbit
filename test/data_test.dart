import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/data/backup.dart';
import 'package:orbit/data/contact_store.dart';
import 'package:orbit/data/crypto.dart';
import 'package:orbit/data/csv_export.dart';
import 'package:orbit/data/importers.dart';
import 'package:orbit/models/contact.dart';
import 'package:orbit/models/field_schema.dart';
import 'package:orbit/ui/contacts_table.dart' show orderedColumnKeys;

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

    test('recovery code можно показать по PIN и выпустить новый', () async {
      final vault = Vault(root);
      final (cipher, code) = await vault.create('111111');
      expect(await vault.revealRecoveryCode('111111'), code);
      await expectLater(vault.revealRecoveryCode('000000'), throwsA(isA<WrongSecretException>()));
      // После смены PIN код по-прежнему доступен.
      await vault.changePin(cipher, '222222');
      expect(await vault.revealRecoveryCode('222222'), code);

      final fresh = await vault.regenerateRecoveryCode(cipher);
      expect(fresh, isNot(code));
      expect(await vault.revealRecoveryCode('222222'), fresh);
      await expectLater(vault.unlockWithRecovery(code), throwsA(isA<WrongSecretException>()));
      final secret = await cipher.encrypt([7]);
      expect(await (await vault.unlockWithRecovery(fresh)).decrypt(secret), [7]);
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
        {
          'id': 'a', 'name': 'Анна', 'phone': '+7 900', 'email': 'a@x.io',
          'photoFile': 'p.jpg', 'createdAt': now, 'updatedAt': now,
        },
      ]));
      Directory('${root.path}/photos').createSync();
      File('${root.path}/photos/p.jpg').writeAsBytesSync([9, 9, 9]);

      final cipher = await DataCipher.generate();
      final store = ContactStore();
      await store.load(root: root, cipher: cipher);
      expect(store.contacts.single.name, 'Анна');
      // Одиночные телефон и почта из старого формата стали списками.
      expect(store.contacts.single.phones, [const LabeledValue('мобильный', '+7 900')]);
      expect(store.contacts.single.emails, [const LabeledValue('личный', 'a@x.io')]);

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

    test('интересы: создание заранее, удаление у всех контактов, сохранение', () async {
      final cipher = await DataCipher.generate();
      final store = ContactStore();
      await store.load(root: root, cipher: cipher);
      expect(await store.addInterest('Бег'), isTrue);
      expect(await store.addInterest('бег'), isFalse, reason: 'регистр не важен');
      final ids = await store.addImported(parseContactsFile('Имя,Интересы\nАнна,"Бег, Книги"\nБорис,Книги', []).contacts);
      expect(store.interestCatalog.map((e) => '${e.key}:${e.value}'), ['Бег:1', 'Книги:2']);

      await store.deleteMany({ids.first});
      await store.deleteInterest('Книги');
      expect(store.allInterests, {'Бег'});
      // И у контакта в корзине интерес тоже убран.
      expect(store.trash.single.interests, ['Бег']);

      await store.setColumnHidden('phone', true);
      final again = ContactStore();
      await again.load(root: root, cipher: cipher);
      expect(again.allInterests, {'Бег'});
      expect(again.hiddenColumns, {'phone'});
    });

    test('порядок столбцов сохраняется, а пропущенные встают на своё место', () async {
      final cipher = await DataCipher.generate();
      final store = ContactStore();
      await store.load(root: root, cipher: cipher);
      expect(orderedColumnKeys(store), ['phone', 'work', 'met', 'interests', 'birthday', 'created', 'favorite']);

      // Сохранён только частичный порядок (например, из старой версии):
      // остальные встают следом за своими соседями по умолчанию.
      await store.setColumnOrder(['created', 'phone']);
      expect(orderedColumnKeys(store), ['created', 'favorite', 'phone', 'work', 'met', 'interests', 'birthday']);

      final again = ContactStore();
      await again.load(root: root, cipher: cipher);
      expect(again.columnOrder, ['created', 'phone']);
    });

    test('дубль находится по любому из номеров, а не только по первому', () async {
      final store = ContactStore();
      await store.load(root: root, cipher: await DataCipher.generate());
      final now = DateTime.now();
      Contact person(List<String> phones, [List<String> emails = const []]) => Contact(
            id: 'x',
            name: 'Анна',
            phones: [for (final p in phones) LabeledValue('мобильный', p)],
            emails: [for (final e in emails) LabeledValue('личный', e)],
            createdAt: now,
            updatedAt: now,
          );
      await store.addImported([person(['+7 900 111-11-11', '8 (900) 222-22-22'])]);
      expect(store.isDuplicate(person(['+79002222222'])), isTrue);
      expect(store.isDuplicate(person(['+7 900 333-33-33'])), isFalse);
      expect(store.isDuplicate(person([], ['new@x.io'])), isFalse);
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

    test('экспорт в CSV и обратный импорт сохраняют все номера и адреса', () {
      final now = DateTime.now();
      final original = Contact(
        id: 'a',
        name: 'Анна',
        phones: const [LabeledValue('мобильный', '+7 900'), LabeledValue('рабочий', '+7 495')],
        emails: const [LabeledValue('личный', 'a@x.io'), LabeledValue('рабочий', 'a@work.io')],
        createdAt: now,
        updatedAt: now,
      );
      final back = parseContactsFile(contactsToCsv([original], []), []).contacts.single;
      expect(back.phones.map((p) => p.value), ['+7 900', '+7 495']);
      expect(back.emails.map((e) => e.value), ['a@x.io', 'a@work.io']);
    });

    test('Telegram: ссылка t.me/ник при любой записи ника', () {
      final now = DateTime.now();
      for (final v in [
        '@anna_s', 'anna_s', ' @anna_s ', 't.me/anna_s', 'https://t.me/anna_s/', 'https://t.me/@anna_s',
        'http://telegram.me/anna_s?start=1', 'tg://resolve?domain=anna_s',
      ]) {
        final c = Contact(id: 'a', name: 'A', telegram: v, createdAt: now, updatedAt: now);
        expect(c.telegramHandle, 'anna_s', reason: v);
        expect(c.telegramUrl, 'https://t.me/anna_s', reason: v);
      }
    });

    test('Instagram: ник из ссылки, CSV и vCard', () {
      final now = DateTime.now();
      Contact withInsta(String v) => Contact(id: 'a', name: 'A', instagram: v, createdAt: now, updatedAt: now);
      for (final v in ['@anna.s', 'anna.s', 'https://www.instagram.com/anna.s/?igsh=xyz', 'instagram.com/anna.s']) {
        expect(withInsta(v).instagramHandle, 'anna.s', reason: v);
        expect(withInsta(v).instagramUrl, 'https://instagram.com/anna.s', reason: v);
      }
      expect(withInsta('anna.s').instagramUrl, 'https://instagram.com/anna.s');

      final csv = contactsToCsv([withInsta('https://instagram.com/anna.s')], []);
      expect(parseContactsFile(csv, []).contacts.single.instagramHandle, 'anna.s');

      final cards = parseContactsFile(
        'BEGIN:VCARD\nFN:Анна\n'
        'X-SOCIALPROFILE;type=instagram;x-user=anna.s:http://www.instagram.com/anna.s\nEND:VCARD\n'
        'BEGIN:VCARD\nFN:Борис\nX-SOCIALPROFILE;type=instagram:x-apple:boris_b\nEND:VCARD\n'
        'BEGIN:VCARD\nFN:Вера\nX-SOCIALPROFILE;type=instagram:\nEND:VCARD\n',
        [],
      ).contacts;
      expect(cards.map((c) => c.instagramHandle), ['anna.s', 'boris_b', '']);
    });

    test('Google CSV: несколько номеров с подписями', () {
      final c = parseContactsFile(
        'Name,Phone 1 - Label,Phone 1 - Value,Phone 2 - Label,Phone 2 - Value,E-mail 1 - Label,E-mail 1 - Value\n'
        'Ann,* Mobile,+1 555 0100 ::: +1 555 0101,Work,+1 555 0199,Home,ann@x.io\n',
        [],
      ).contacts.single;
      expect(c.phones, const [
        LabeledValue('мобильный', '+1 555 0100'),
        LabeledValue('мобильный', '+1 555 0101'),
        LabeledValue('рабочий', '+1 555 0199'),
      ]);
      expect(c.emails, const [LabeledValue('личный', 'ann@x.io')]);
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
        'ORG:Яндекс;\r\nTITLE:Продакт\r\nTEL;type=WORK;type=VOICE:+7 495 000-00-00\r\n'
        'TEL;type=CELL;type=VOICE;type=pref:+7 900 123-45-67\r\n'
        'EMAIL;type=INTERNET:anna@ya.ru\r\nitem1.EMAIL;type=INTERNET;type=WORK:anna@yandex-team.ru\r\n'
        'BDAY:1993-10-09\r\n'
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
      // Номер с pref — основной, хотя в файле он второй.
      expect(anna.phones, const [
        LabeledValue('мобильный', '+7 900 123-45-67'),
        LabeledValue('рабочий', '+7 495 000-00-00'),
      ]);
      expect(anna.emails, const [
        LabeledValue('личный', 'anna@ya.ru'),
        LabeledValue('рабочий', 'anna@yandex-team.ru'),
      ]);
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
