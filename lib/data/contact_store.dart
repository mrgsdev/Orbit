import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/contact.dart';
import '../models/field_schema.dart';

/// Хранит контакты в JSON-файле, а фото — копиями в отдельной папке
/// внутри Application Support, чтобы не зависеть от исходных файлов.
class ContactStore extends ChangeNotifier {
  static const _uuid = Uuid();

  late final Directory _root;
  late final Directory _photos;
  final List<Contact> _contacts = [];
  final List<FieldSection> _sections = [];

  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<FieldSection> get sections => List.unmodifiable(_sections);
  Iterable<CustomField> get allFields => _sections.expand((s) => s.fields);
  List<CustomField> get tableFields =>
      allFields.where((f) => f.showInTable).toList();

  /// [root] задают тесты; приложение хранит данные в Application Support.
  Future<void> load({Directory? root}) async {
    _root = root ?? await getApplicationSupportDirectory();
    _photos = Directory('${_root.path}/photos');
    await _photos.create(recursive: true);

    final file = _dbFile;
    if (await file.exists()) {
      final raw = jsonDecode(await file.readAsString()) as List;
      _contacts
        ..clear()
        ..addAll(raw.map((e) => Contact.fromJson(e as Map<String, dynamic>)));
    }
    _sort();
    await _loadSchema();
    await _collectOrphanPhotos();
    notifyListeners();
  }

  File get _schemaFile => File('${_root.path}/schema.json');

  Future<void> _loadSchema() async {
    _sections.clear();
    if (await _schemaFile.exists()) {
      final raw = jsonDecode(await _schemaFile.readAsString()) as List;
      _sections.addAll(raw.map((e) => FieldSection.fromJson(e as Map<String, dynamic>)));
    }
    // Стандартные разделы есть всегда, даже если файл схемы старый.
    for (final b in BuiltIn.sections) {
      if (!_sections.any((s) => s.id == b.id)) _sections.add(b);
    }
  }

  File get _dbFile => File('${_root.path}/contacts.json');

  File? photoOf(Contact c) => photoFile(c.photoFile);

  File? photoFile(String? name) =>
      name == null ? null : File('${_photos.path}/$name');

  Contact? byId(String id) {
    for (final c in _contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  Set<String> get allInterests =>
      {for (final c in _contacts) ...c.interests};

  /// Интересы с числом контактов, от популярных к редким.
  List<MapEntry<String, int>> get interestCounts {
    final counts = <String, int>{};
    for (final c in _contacts) {
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
    final i = _contacts.indexWhere((c) => c.id == contact.id);
    if (i == -1) {
      _contacts.add(updated);
    } else {
      _contacts[i] = updated;
    }
    _sort();
    await _persist();
    notifyListeners();
  }

  Future<void> toggleFavorite(Contact c) =>
      save(c.copyWith(favorite: !c.favorite));

  Future<void> setFavorite(Set<String> ids, bool value) async {
    for (var i = 0; i < _contacts.length; i++) {
      if (ids.contains(_contacts[i].id)) {
        _contacts[i] = _contacts[i].copyWith(favorite: value);
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<void> delete(Contact contact) => deleteMany({contact.id});

  Future<void> deleteMany(Set<String> ids) async {
    final removed = _contacts.where((c) => ids.contains(c.id)).toList();
    _contacts.removeWhere((c) => ids.contains(c.id));
    for (final c in removed) {
      if (c.photoFile != null) await _deletePhoto(c.photoFile!);
    }
    await _persist();
    notifyListeners();
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
    for (var i = 0; i < _contacts.length; i++) {
      final c = _contacts[i];
      if (c.custom.keys.any(fieldIds.contains)) {
        _contacts[i] = c.copyWith(
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

  /// Копирует выбранное изображение в хранилище и возвращает имя файла.
  Future<String> importPhoto(String sourcePath) async {
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot == -1 ? '' : sourcePath.substring(dot).toLowerCase();
    final name = '${_uuid.v4()}$ext';
    await File(sourcePath).copy('${_photos.path}/$name');
    return name;
  }

  /// Удаляет фото, которое было импортировано в черновик, но не сохранено.
  Future<void> discardPhoto(String fileName) async {
    final usedBySaved = _contacts.any((c) => c.photoFile == fileName);
    if (!usedBySaved) await _deletePhoto(fileName);
  }

  Future<void> _deletePhoto(String fileName) async {
    final f = File('${_photos.path}/$fileName');
    if (await f.exists()) await f.delete();
  }

  /// Фото из черновиков, закрытых без сохранения, ни на что не ссылаются.
  Future<void> _collectOrphanPhotos() async {
    final used = {for (final c in _contacts) c.photoFile};
    await for (final f in _photos.list()) {
      final name = f.uri.pathSegments.last;
      if (f is File && !used.contains(name)) await f.delete();
    }
  }

  void _sort() => _contacts.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<void> _persist() =>
      _writeJson(_dbFile, _contacts.map((c) => c.toJson()).toList());

  Future<void> _writeJson(File file, Object data) async {
    // Пишем во временный файл и переименовываем, чтобы сбой посреди
    // записи не оставил файл обрезанным.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await tmp.rename(file.path);
  }
}
