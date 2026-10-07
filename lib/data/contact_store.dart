import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/contact.dart';
import '../models/field_schema.dart';
import 'crypto.dart';

/// Хранит контакты в зашифрованном JSON-файле, а фото — зашифрованными
/// копиями в отдельной папке, чтобы не зависеть от исходных файлов.
class ContactStore extends ChangeNotifier {
  static const _uuid = Uuid();

  /// Сколько контакт лежит в корзине, прежде чем удалиться навсегда.
  static const trashDays = 30;

  late final Directory _root;
  late final Directory _photos;
  late final DataCipher _cipher;

  /// Все контакты, включая корзину.
  final List<Contact> _all = [];
  final List<FieldSection> _sections = [];

  /// Интересы, созданные заранее, — даже если их пока нет ни у кого.
  final Set<String> _interestCatalog = {};

  /// Скрытые столбцы таблицы контактов.
  final Set<String> _hiddenColumns = {};
  final List<String> _columnOrder = [];

  /// Расшифрованные фото — чтобы не расшифровывать их при каждой перерисовке.
  final Map<String, Uint8List> _photoCache = {};

  /// Активные контакты, без корзины.
  List<Contact> get contacts => List.unmodifiable(_all.where((c) => !c.isDeleted));

  /// Корзина: сначала недавно удалённые.
  List<Contact> get trash =>
      _all.where((c) => c.isDeleted).toList()..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));

  DataCipher get cipher => _cipher;

  /// Папка с данными приложения — для «Открыть папку приложения».
  Directory get rootDir => _root;
  List<FieldSection> get sections => List.unmodifiable(_sections);
  Iterable<CustomField> get allFields => _sections.expand((s) => s.fields);
  List<CustomField> get tableFields =>
      allFields.where((f) => f.showInTable).toList();

  /// Читает базу из [root], расшифровывая ключом [cipher]. Данные,
  /// сохранённые до появления шифрования, при этом зашифровываются.
  Future<void> load({required Directory root, required DataCipher cipher}) async {
    _root = root;
    _cipher = cipher;
    _photos = Directory('${_root.path}/photos');
    await _photos.create(recursive: true);

    final (raw, plainDb) = await _readJson(_dbFile);
    _all
      ..clear()
      ..addAll([
        for (final e in (raw as List?) ?? const []) Contact.fromJson(e as Map<String, dynamic>),
      ]);
    _sort();
    final plainSchema = await _loadSchema();
    final (prefs, _) = await _readJson(_prefsFile);
    if (prefs is Map) {
      _interestCatalog
        ..clear()
        ..addAll(((prefs['interests'] as List?) ?? const []).cast<String>());
      _hiddenColumns
        ..clear()
        ..addAll(((prefs['hiddenColumns'] as List?) ?? const []).cast<String>());
      _columnOrder
        ..clear()
        ..addAll(((prefs['columnOrder'] as List?) ?? const []).cast<String>());
    }
    if (plainDb) await _persist();
    if (plainSchema) await _writeJson(_schemaFile, _sections.map((s) => s.toJson()).toList());
    await _encryptLegacyPhotos();
    await _purgeExpiredTrash();
    await _collectOrphanPhotos();
    notifyListeners();
  }

  File get _schemaFile => File('${_root.path}/schema.json');
  File get _prefsFile => File('${_root.path}/prefs.json');

  Future<void> _savePrefs() => _writeJson(_prefsFile, {
        'interests': _interestCatalog.toList()..sort(),
        'hiddenColumns': _hiddenColumns.toList()..sort(),
        'columnOrder': _columnOrder,
      });

  /// Возвращает true, если файл схемы был незашифрованным.
  Future<bool> _loadSchema() async {
    _sections.clear();
    final (raw, plain) = await _readJson(_schemaFile);
    if (raw != null) {
      _sections.addAll((raw as List).map((e) => FieldSection.fromJson(e as Map<String, dynamic>)));
    }
    // Стандартные разделы есть всегда, даже если файл схемы старый.
    for (final b in BuiltIn.sections) {
      if (!_sections.any((s) => s.id == b.id)) _sections.add(b);
    }
    return plain;
  }

  File get _dbFile => File('${_root.path}/contacts.json');

  /// Есть ли файл фото на диске — чтобы не рисовать пустой кружок.
  bool hasPhoto(String? name) =>
      name != null && (_photoCache.containsKey(name) || File('${_photos.path}/$name').existsSync());

  /// Расшифрованное фото; null — фото нет или файл потерян.
  Future<Uint8List?> readPhoto(String name) async {
    final cached = _photoCache[name];
    if (cached != null) return cached;
    final f = File('${_photos.path}/$name');
    if (!await f.exists()) return null;
    final bytes = await f.readAsBytes();
    final plain = DataCipher.isEncrypted(bytes) ? await _cipher.decrypt(bytes) : bytes;
    return _photoCache[name] = plain;
  }

  /// Ищет и среди активных, и в корзине.
  Contact? byId(String id) {
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Все известные интересы: созданные заранее и указанные у контактов.
  Set<String> get allInterests => {..._interestCatalog, for (final c in contacts) ...c.interests};

  /// Все интересы с числом активных контактов, по алфавиту.
  List<MapEntry<String, int>> get interestCatalog {
    final counts = {for (final i in allInterests) i: 0};
    for (final c in contacts) {
      for (final i in c.interests) {
        counts[i] = counts[i]! + 1;
      }
    }
    return counts.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
  }

  /// Сколько активных контактов с этим интересом.
  int interestUsage(String interest) => contacts.where((c) => c.interests.contains(interest)).length;

  /// Создаёт интерес заранее. Возвращает false, если такой уже есть.
  Future<bool> addInterest(String name) async {
    final value = name.trim();
    if (value.isEmpty || allInterests.any((i) => i.toLowerCase() == value.toLowerCase())) return false;
    _interestCatalog.add(value);
    await _savePrefs();
    notifyListeners();
    return true;
  }

  /// Удаляет интерес отовсюду — и из списка, и у всех контактов, включая корзину.
  Future<void> deleteInterest(String interest) async {
    _interestCatalog.remove(interest);
    var changed = false;
    for (var i = 0; i < _all.length; i++) {
      final c = _all[i];
      if (c.interests.contains(interest)) {
        _all[i] = c.copyWith(interests: [...c.interests]..remove(interest));
        changed = true;
      }
    }
    await _savePrefs();
    if (changed) await _persist();
    notifyListeners();
  }

  Set<String> get hiddenColumns => Set.unmodifiable(_hiddenColumns);

  Future<void> setColumnHidden(String column, bool hidden) async {
    hidden ? _hiddenColumns.add(column) : _hiddenColumns.remove(column);
    // Таблица меняется сразу, не дожидаясь записи на диск.
    notifyListeners();
    await _savePrefs();
  }

  /// Порядок столбцов таблицы, как его расставил пользователь. Пустой —
  /// порядок по умолчанию.
  List<String> get columnOrder => List.unmodifiable(_columnOrder);

  Future<void> setColumnOrder(List<String> order) async {
    _columnOrder
      ..clear()
      ..addAll(order);
    // Таблица меняется сразу, не дожидаясь записи на диск.
    notifyListeners();
    await _savePrefs();
  }

  /// Интересы с числом контактов, от популярных к редким.
  List<MapEntry<String, int>> get interestCounts {
    final counts = <String, int>{};
    for (final c in contacts) {
      for (final i in c.interests) {
        counts[i] = (counts[i] ?? 0) + 1;
      }
    }
    return counts.entries.toList()
      ..sort((a, b) => b.value != a.value
          ? b.value.compareTo(a.value)
          : a.key.toLowerCase().compareTo(b.key.toLowerCase()));
  }

  Contact newDraft() {
    final now = DateTime.now();
    return Contact(id: _uuid.v4(), name: '', createdAt: now, updatedAt: now);
  }

  Future<void> save(Contact contact) async {
    final old = byId(contact.id);
    // Фото заменили или убрали — старый файл больше не нужен.
    if (old?.photoFile != null && old!.photoFile != contact.photoFile) {
      await _deletePhoto(old.photoFile!);
    }
    final updated = contact.copyWith(updatedAt: DateTime.now());
    final i = _all.indexWhere((c) => c.id == contact.id);
    if (i == -1) {
      _all.add(updated);
    } else {
      _all[i] = updated;
    }
    _sort();
    await _persist();
    notifyListeners();
  }

  Future<void> toggleFavorite(Contact c) =>
      save(c.copyWith(favorite: !c.favorite));

  Future<void> setFavorite(Set<String> ids, bool value) async {
    _update(ids, (c) => c.copyWith(favorite: value));
    await _persist();
    notifyListeners();
  }

  void _update(Set<String> ids, Contact Function(Contact) change) {
    for (var i = 0; i < _all.length; i++) {
      if (ids.contains(_all[i].id)) _all[i] = change(_all[i]);
    }
  }

  /// Переносит в корзину — восстановить можно ещё [trashDays] дней.
  Future<void> delete(Contact contact) => deleteMany({contact.id});

  Future<void> deleteMany(Set<String> ids) async {
    final now = DateTime.now();
    _update(ids, (c) => c.copyWith(deletedAt: () => now));
    await _persist();
    notifyListeners();
  }

  Future<void> restore(Set<String> ids) async {
    _update(ids, (c) => c.copyWith(deletedAt: () => null));
    await _persist();
    notifyListeners();
  }

  /// Удаляет навсегда, вместе с фото.
  Future<void> purge(Set<String> ids) async {
    final removed = _all.where((c) => ids.contains(c.id)).toList();
    _all.removeWhere((c) => ids.contains(c.id));
    for (final c in removed) {
      if (c.photoFile != null) await _deletePhoto(c.photoFile!);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> emptyTrash() => purge({for (final c in trash) c.id});

  Future<void> _purgeExpiredTrash() async {
    final limit = DateTime.now().subtract(const Duration(days: trashDays));
    final expired = {for (final c in _all) if (c.isDeleted && c.deletedAt!.isBefore(limit)) c.id};
    if (expired.isNotEmpty) await purge(expired);
  }

  // ── Импорт и резервные копии ──

  /// Телефоны и почта в сравнимом виде: последние 10 цифр номера
  /// (+7 и 8 в начале не важны) и адрес в нижнем регистре.
  static Set<String> _reachKeys(Contact c) => {
        for (final p in c.phones)
          if (p.value.replaceAll(RegExp(r'\D'), '') case final d when d.isNotEmpty)
            'tel:${d.length > 10 ? d.substring(d.length - 10) : d}',
        for (final e in c.emails)
          if (e.value.trim().isNotEmpty) 'mail:${e.value.trim().toLowerCase()}',
      };

  /// Уже есть такой человек среди активных: то же имя и общий номер или
  /// почта. Если ни номеров, ни почты нет ни у кого — совпадение по имени.
  bool isDuplicate(Contact c) {
    final name = c.name.trim().toLowerCase();
    final keys = _reachKeys(c);
    return contacts.any((x) {
      if (x.name.trim().toLowerCase() != name) return false;
      final other = _reachKeys(x);
      return keys.isEmpty && other.isEmpty || keys.intersection(other).isNotEmpty;
    });
  }

  /// Добавляет импортированные контакты; [photos] — фото по id контакта.
  /// Возвращает id добавленных, чтобы импорт можно было отменить.
  Future<Set<String>> addImported(List<Contact> drafts, {Map<String, Uint8List> photos = const {}}) async {
    final now = DateTime.now();
    final added = <String>{};
    for (final d in drafts) {
      final photo = photos[d.id];
      final c = Contact(
        id: _uuid.v4(),
        name: d.name,
        phones: d.phones,
        telegram: d.telegram,
        instagram: d.instagram,
        emails: d.emails,
        position: d.position,
        company: d.company,
        whereMet: d.whereMet,
        metDate: d.metDate,
        birthday: d.birthday,
        interests: d.interests,
        notes: d.notes,
        custom: d.custom,
        photoFile: photo == null ? null : await _writePhoto(photo),
        favorite: d.favorite,
        createdAt: now,
        updatedAt: now,
      );
      _all.add(c);
      added.add(c.id);
    }
    _sort();
    await _persist();
    notifyListeners();
    return added;
  }

  /// Снимок всей базы для резервной копии — фото уже расшифрованы.
  Future<Map<String, dynamic>> snapshot() async => {
        'contacts': _all.map((c) => c.toJson()).toList(),
        'sections': _sections.map((s) => s.toJson()).toList(),
        'interests': _interestCatalog.toList(),
        'photos': {
          for (final c in _all)
            if (c.photoFile != null)
              if (await readPhoto(c.photoFile!) case final bytes?) c.photoFile!: base64.encode(bytes),
        },
      };

  /// Вливает резервную копию: новых людей добавляет, у известных
  /// оставляет более свежую версию. Свои поля и разделы объединяет.
  Future<({int added, int updated})> mergeSnapshot(Map<String, dynamic> snap) async {
    final photos = (snap['photos'] as Map?)?.cast<String, String>() ?? const {};
    var added = 0, updated = 0;
    for (final e in (snap['contacts'] as List?) ?? const []) {
      final c = Contact.fromJson(e as Map<String, dynamic>);
      final i = _all.indexWhere((x) => x.id == c.id);
      if (i != -1 && !c.updatedAt.isAfter(_all[i].updatedAt)) continue;
      var photoFile = c.photoFile;
      if (photoFile != null) {
        final data = photos[photoFile];
        photoFile = data == null ? null : await _writePhoto(base64.decode(data));
      }
      final restored = c.copyWith(photoFile: () => photoFile, updatedAt: c.updatedAt);
      if (i == -1) {
        _all.add(restored);
        added++;
      } else {
        if (_all[i].photoFile != null) await _deletePhoto(_all[i].photoFile!);
        _all[i] = restored;
        updated++;
      }
    }
    final interests = ((snap['interests'] as List?) ?? const []).cast<String>();
    if (interests.any((i) => !_interestCatalog.contains(i))) {
      _interestCatalog.addAll(interests);
      await _savePrefs();
    }
    for (final e in (snap['sections'] as List?) ?? const []) {
      final s = FieldSection.fromJson(e as Map<String, dynamic>);
      final existing = sectionById(s.id);
      if (existing == null) {
        _sections.add(s);
      } else {
        final known = {for (final f in existing.fields) f.id};
        _replaceSection(existing.copyWith(
            fields: [...existing.fields, ...s.fields.where((f) => !known.contains(f.id))]));
      }
    }
    _sort();
    await _persist();
    await _schemaChanged();
    return (added: added, updated: updated);
  }

  // ── Схема пользовательских полей ──

  String newId() => _uuid.v4();

  FieldSection? sectionById(String id) {
    for (final s in _sections) {
      if (s.id == id) return s;
    }
    return null;
  }

  FieldSection? sectionOfField(String fieldId) {
    for (final s in _sections) {
      if (s.fields.any((f) => f.id == fieldId)) return s;
    }
    return null;
  }

  /// Добавляет раздел или обновляет существующий с тем же id.
  Future<void> saveSection(FieldSection section) async {
    final i = _sections.indexWhere((s) => s.id == section.id);
    if (i == -1) {
      _sections.add(section);
    } else {
      _sections[i] = section;
    }
    await _schemaChanged();
  }

  Future<void> deleteSection(String id) async {
    final s = sectionById(id);
    if (s == null || s.builtIn) return;
    _sections.remove(s);
    await _purgeValues(s.fields.map((f) => f.id).toSet());
    await _schemaChanged();
  }

  /// Индексы — как их передаёт ReorderableListView.onReorderItem
  /// (новая позиция уже с учётом убранного элемента).
  Future<void> reorderSections(int from, int to) async {
    _sections.insert(to, _sections.removeAt(from));
    await _schemaChanged();
  }

  /// Сохраняет поле в раздел [sectionId]; если поле жило в другом
  /// разделе, переносит его в конец нового.
  Future<void> saveField(String sectionId, CustomField field) async {
    final old = sectionOfField(field.id);
    if (old != null && old.id == sectionId) {
      _replaceSection(old.copyWith(
          fields: [for (final f in old.fields) f.id == field.id ? field : f]));
    } else {
      if (old != null) {
        _replaceSection(old.copyWith(
            fields: old.fields.where((f) => f.id != field.id).toList()));
      }
      final target = sectionById(sectionId)!;
      _replaceSection(target.copyWith(fields: [...target.fields, field]));
    }
    await _schemaChanged();
  }

  Future<void> deleteField(String fieldId) async {
    final s = sectionOfField(fieldId);
    if (s == null) return;
    _replaceSection(
        s.copyWith(fields: s.fields.where((f) => f.id != fieldId).toList()));
    await _purgeValues({fieldId});
    await _schemaChanged();
  }

  Future<void> reorderFields(String sectionId, int from, int to) async {
    final s = sectionById(sectionId)!;
    final fields = [...s.fields];
    fields.insert(to, fields.removeAt(from));
    _replaceSection(s.copyWith(fields: fields));
    await _schemaChanged();
  }

  void _replaceSection(FieldSection section) =>
      _sections[_sections.indexWhere((s) => s.id == section.id)] = section;

  /// Убирает у всех контактов значения удалённых полей.
  Future<void> _purgeValues(Set<String> fieldIds) async {
    var changed = false;
    for (var i = 0; i < _all.length; i++) {
      final c = _all[i];
      if (c.custom.keys.any(fieldIds.contains)) {
        _all[i] = c.copyWith(
            custom: {...c.custom}..removeWhere((k, _) => fieldIds.contains(k)));
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  Future<void> _schemaChanged() async {
    await _writeJson(_schemaFile, _sections.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  /// Шифрует выбранное изображение в хранилище и возвращает имя файла.
  Future<String> importPhoto(String sourcePath) async =>
      _writePhoto(await File(sourcePath).readAsBytes());

  Future<String> _writePhoto(Uint8List bytes) async {
    final name = '${_uuid.v4()}.enc';
    await File('${_photos.path}/$name').writeAsBytes(await _cipher.encrypt(bytes));
    _photoCache[name] = bytes;
    return name;
  }

  /// Удаляет фото, которое было импортировано в черновик, но не сохранено.
  Future<void> discardPhoto(String fileName) async {
    final usedBySaved = _all.any((c) => c.photoFile == fileName);
    if (!usedBySaved) await _deletePhoto(fileName);
  }

  Future<void> _deletePhoto(String fileName) async {
    _photoCache.remove(fileName);
    final f = File('${_photos.path}/$fileName');
    if (await f.exists()) await f.delete();
  }

  /// Фото, сохранённые до появления шифрования, шифруем на месте.
  Future<void> _encryptLegacyPhotos() async {
    await for (final f in _photos.list()) {
      if (f is! File) continue;
      // Достаточно заголовка, чтобы не читать целиком уже зашифрованные.
      final head = await f.openRead(0, 4).expand((b) => b).toList();
      if (DataCipher.isEncrypted(head)) continue;
      final bytes = await f.readAsBytes();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsBytes(await _cipher.encrypt(bytes));
      await tmp.rename(f.path);
    }
  }

  /// Фото из черновиков, закрытых без сохранения, ни на что не ссылаются.
  Future<void> _collectOrphanPhotos() async {
    final used = {for (final c in _all) c.photoFile};
    await for (final f in _photos.list()) {
      final name = f.uri.pathSegments.last;
      if (f is File && !used.contains(name)) await f.delete();
    }
  }

  void _sort() => _all.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<void> _persist() =>
      _writeJson(_dbFile, _all.map((c) => c.toJson()).toList());

  /// Читает JSON-файл: (данные или null, был ли файл незашифрованным).
  Future<(Object?, bool)> _readJson(File file) async {
    if (!await file.exists()) return (null, false);
    final bytes = await file.readAsBytes();
    if (DataCipher.isEncrypted(bytes)) {
      return (jsonDecode(utf8.decode(await _cipher.decrypt(bytes))), false);
    }
    return (jsonDecode(utf8.decode(bytes)), true);
  }

  Future<void> _writeJson(File file, Object data) async {
    // Пишем во временный файл и переименовываем, чтобы сбой посреди
    // записи не оставил файл обрезанным.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(await _cipher.encrypt(utf8.encode(jsonEncode(data))));
    await tmp.rename(file.path);
  }
}
