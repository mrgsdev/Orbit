import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../models/contact.dart';
import '../models/field_schema.dart';
import '../l10n/strings.dart';

/// Результат разбора файла: черновики контактов и фото к ним (по id черновика).
class ParsedContacts {
  final List<Contact> contacts;
  final Map<String, Uint8List> photos;

  const ParsedContacts(this.contacts, [this.photos = const {}]);
}

/// Определяет формат по содержимому: vCard или CSV.
ParsedContacts parseContactsFile(String text, List<CustomField> fields) {
  final body = text.replaceFirst('﻿', '');
  return RegExp(r'^\s*BEGIN:VCARD', caseSensitive: false).hasMatch(body)
      ? parseVCards(body)
      : contactsFromCsv(parseCsv(body), fields);
}

Contact _draft(int i) {
  final now = DateTime.now();
  return Contact(id: 'import-$i', name: '', createdAt: now, updatedAt: now);
}

// ── CSV ──

/// Разбор CSV по RFC 4180: кавычки, переносы строк внутри ячеек.
/// Разделитель — запятая или точка с запятой (так сохраняет русский Excel).
List<List<String>> parseCsv(String text) {
  text = text.replaceFirst('﻿', '');
  final firstLine = text.split(RegExp(r'\r?\n')).first;
  final sep = ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length ? ';' : ',';

  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == sep) {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    rows.add(row);
  }
  return rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
}

/// Названия колонок: экспорт Orbit на любом языке интерфейса, Google Контакты,
/// Outlook и просто английские.
final _aliases = () {
  final aliases = {for (final e in _baseAliases.entries) e.key: {...e.value}};
  const order = [
    'name', 'phone', 'telegram', 'instagram', 'email', 'position', 'company',
    'whereMet', 'metDate', 'birthday', 'interests', 'notes', 'favorite',
  ];
  for (final l in languages) {
    for (final (i, h) in l.csvHeaders.indexed) {
      aliases[order[i]]!.add(h.toLowerCase());
    }
  }
  return aliases;
}();

const _baseAliases = <String, List<String>>{
  'name': ['имя', 'фио', 'name', 'full name', 'display name'],
  'first': ['first name', 'given name', 'имя (first name)'],
  'last': ['last name', 'family name', 'surname', 'фамилия'],
  'phone': ['телефон', 'телефоны', 'phone', 'mobile', 'mobile phone', 'primary phone', 'мобильный'],
  'telegram': ['telegram', 'телеграм'],
  'instagram': ['instagram', 'инстаграм', 'инстаграмм', 'insta'],
  'email': ['email', 'e-mail', 'почта', 'email address', 'e-mail address'],
  'position': ['должность', 'title', 'job title', 'organization 1 - title', 'organization title'],
  'company': ['компания', 'company', 'organization', 'organization 1 - name', 'organization name'],
  'whereMet': ['где познакомились'],
  'metDate': ['дата знакомства'],
  'birthday': ['день рождения', 'birthday', 'дата рождения'],
  'interests': ['интересы', 'interests', 'tags', 'теги'],
  'notes': ['заметки', 'notes', 'note', 'комментарий'],
  'favorite': ['избранное', 'favorite', 'starred'],
};

ParsedContacts contactsFromCsv(List<List<String>> rows, List<CustomField> fields) {
  if (rows.length < 2) return const ParsedContacts([]);
  final header = [for (final h in rows.first) h.trim().toLowerCase()];
  int col(String key) => header.indexWhere((h) => _aliases[key]!.contains(h));
  final cols = {for (final k in _aliases.keys) k: col(k)};
  final custom = {
    for (final f in fields)
      if (header.indexOf(f.label.trim().toLowerCase()) case final i when i != -1) f: i,
  };
  final phoneCols = _valueColumns(header, phone: true);
  final emailCols = _valueColumns(header, phone: false);

  final out = <Contact>[];
  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    String get(String key) {
      final i = cols[key]!;
      return i == -1 || i >= row.length ? '' : row[i].trim();
    }

    var name = get('name');
    if (name.isEmpty) name = [get('first'), get('last')].where((s) => s.isNotEmpty).join(' ');
    if (name.isEmpty) continue;

    final values = <String, Object?>{};
    for (final MapEntry(key: f, value: i) in custom.entries) {
      if (i >= row.length || row[i].trim().isEmpty) continue;
      final v = row[i].trim();
      values[f.id] = switch (f.type) {
        FieldType.checkbox => _truthy(v),
        FieldType.date => switch (parseDate(v)) { final d? => DateFormat('yyyy-MM-dd').format(d), null => null },
        FieldType.select => f.options.contains(v) ? v : null,
        _ => v,
      };
    }
    values.removeWhere((_, v) => v == null);

    out.add(_draft(r).copyWith(
      name: name,
      phones: _collect(row, phoneCols, phone: true),
      telegram: get('telegram'),
      instagram: get('instagram'),
      emails: _collect(row, emailCols, phone: false),
      position: get('position'),
      company: get('company'),
      whereMet: get('whereMet'),
      metDate: () => parseDate(get('metDate')),
      birthday: () => parseDate(get('birthday')),
      interests: _splitList(get('interests')),
      notes: get('notes'),
      favorite: _truthy(get('favorite')),
      custom: values,
    ));
  }
  return ParsedContacts(out);
}

/// Колонки с номерами или почтой: (колонка значения, колонка подписи или -1).
/// Их бывает несколько — Google пишет «Phone 1 - Value», «Phone 1 - Label», …
List<(int, int)> _valueColumns(List<String> header, {required bool phone}) {
  final numbered = RegExp(phone ? r'^phone (\d+) - value$' : r'^e-?mail (\d+) - value$');
  final prefix = phone ? 'phone' : 'e-mail';
  return [
    for (var i = 0; i < header.length; i++)
      if (_aliases[phone ? 'phone' : 'email']!.contains(header[i]))
        (i, -1)
      else if (numbered.firstMatch(header[i]) case final m?)
        (
          i,
          header.indexWhere((h) =>
              h == '$prefix ${m[1]} - label' ||
              h == '$prefix ${m[1]} - type' ||
              h == 'email ${m[1]} - label' ||
              h == 'email ${m[1]} - type'),
        ),
  ];
}

/// Значения из всех колонок; в одной ячейке их может быть несколько
/// (экспорт Orbit пишет через «;», Google — через « ::: »).
List<LabeledValue> _collect(List<String> row, List<(int, int)> cols, {required bool phone}) {
  final out = <LabeledValue>[];
  for (final (vi, li) in cols) {
    if (vi >= row.length) continue;
    final label = normalizeLabel(li == -1 || li >= row.length ? '' : row[li], phone: phone);
    for (final v in row[vi].split(RegExp(r'\s*(?::::|;|,)\s*'))) {
      final value = v.trim();
      if (value.isNotEmpty && !out.any((x) => x.value == value)) out.add(LabeledValue(label, value));
    }
  }
  return out;
}

/// Подпись из файла — к нашим: «Mobile», «CELL», «work» → «мобильный», «рабочий».
String normalizeLabel(String raw, {required bool phone}) {
  final types = raw.toLowerCase().replaceAll('*', '').split(RegExp(r'[\s,:]+')).where((s) => s.isNotEmpty).toSet();
  bool has(Set<String> any) => types.intersection(any).isNotEmpty;
  if (phone && has({'cell', 'mobile', 'iphone', 'мобильный'})) return 'мобильный';
  if (has({'work', 'рабочий'})) return 'рабочий';
  if (has({'home', 'домашний', 'личный', 'personal'})) return phone ? 'домашний' : 'личный';
  if (has({'other', 'другой'})) return 'другой';
  return phone ? LabeledValue.phoneLabels.first : LabeledValue.emailLabels.first;
}

bool _truthy(String v) {
  final s = v.trim().toLowerCase();
  return const {'да', 'yes', 'true', '1', '+', 'y', 'д'}.contains(s) ||
      languages.any((l) => s == l.csvYes.toLowerCase() || s == l.yes.toLowerCase());
}

List<String> _splitList(String v) =>
    v.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();

/// Даты в форматах 2024-05-12, 20240512, 12.05.2024 и 12/05/2024.
DateTime? parseDate(String v) {
  v = v.trim();
  if (v.isEmpty) return null;
  final iso = RegExp(r'^(\d{4})-?(\d{2})-?(\d{2})').firstMatch(v);
  if (iso != null) {
    return _date(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));
  }
  final dmy = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})$').firstMatch(v);
  if (dmy != null) {
    return _date(int.parse(dmy[3]!), int.parse(dmy[2]!), int.parse(dmy[1]!));
  }
  return null;
}

DateTime? _date(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final date = DateTime(y, m, d);
  return date.month == m ? date : null;
}

// ── vCard ──

/// Разбор vCard 2.1–4.0: «Контакты» macOS и iPhone, Google, Android.
ParsedContacts parseVCards(String text) {
  // Склеиваем перенесённые строки (продолжение начинается с пробела или таба).
  final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll(RegExp(r'\n[ \t]'), '').split('\n');

  final contacts = <Contact>[];
  final photos = <String, Uint8List>{};
  List<_Prop>? card;
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    // Quoted-printable переносит строки знаком «=» в конце.
    while (line.toUpperCase().contains('QUOTED-PRINTABLE') && line.endsWith('=') && i + 1 < lines.length) {
      line = line.substring(0, line.length - 1) + lines[++i];
    }
    final upper = line.trim().toUpperCase();
    if (upper == 'BEGIN:VCARD') {
      card = [];
    } else if (upper == 'END:VCARD') {
      if (card != null) {
        final draft = _draft(contacts.length);
        final (contact, photo) = _fromProps(draft, card);
        if (contact.name.isNotEmpty) {
          contacts.add(contact);
          if (photo != null) photos[contact.id] = photo;
        }
      }
      card = null;
    } else if (card != null) {
      if (_Prop.parse(line) case final p?) card.add(p);
    }
  }
  return ParsedContacts(contacts, photos);
}

class _Prop {
  final String name;
  final Map<String, String> params;
  final String raw;

  _Prop(this.name, this.params, this.raw);

  static _Prop? parse(String line) {
    final colon = _unquotedColon(line);
    if (colon == -1) return null;
    final parts = line.substring(0, colon).split(';');
    // «item1.TEL» — группа перед точкой нам не нужна.
    final name = parts.first.split('.').last.toUpperCase();
    final params = <String, String>{};
    for (final p in parts.skip(1)) {
      final eq = p.indexOf('=');
      if (eq == -1) {
        // vCard 2.1: «TEL;CELL;VOICE:…» — тип без ключа.
        params.update('TYPE', (v) => '$v,${p.toUpperCase()}', ifAbsent: () => p.toUpperCase());
      } else {
        final key = p.substring(0, eq).toUpperCase();
        final value = p.substring(eq + 1).replaceAll('"', '');
        params.update(key, (v) => '$v,$value', ifAbsent: () => value);
      }
    }
    return _Prop(name, params, line.substring(colon + 1));
  }

  static int _unquotedColon(String line) {
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == '"') quoted = !quoted;
      if (line[i] == ':' && !quoted) return i;
    }
    return -1;
  }

  bool hasType(String t) => (params['TYPE'] ?? '').toUpperCase().split(',').contains(t);

  /// Значение с учётом кодировки и экранирования (\n, \, \;).
  String get text {
    var v = raw;
    if ((params['ENCODING'] ?? '').toUpperCase() == 'QUOTED-PRINTABLE') {
      final bytes = <int>[];
      for (var i = 0; i < v.length; i++) {
        if (v[i] == '=' && i + 2 < v.length) {
          final hex = int.tryParse(v.substring(i + 1, i + 3), radix: 16);
          if (hex != null) {
            bytes.add(hex);
            i += 2;
            continue;
          }
        }
        bytes.addAll(utf8.encode(v[i]));
      }
      v = utf8.decode(bytes, allowMalformed: true);
    }
    return v;
  }

  /// Компоненты структурированного значения (N, ORG), уже без экранирования.
  List<String> get components => _splitEscaped(text, ';').map(_unescape).toList();

  String get value => _unescape(text);
}

List<String> _splitEscaped(String s, String sep) {
  final out = <String>[];
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (s[i] == '\\' && i + 1 < s.length) {
      b
        ..write(s[i])
        ..write(s[i + 1]);
      i++;
    } else if (s[i] == sep) {
      out.add(b.toString());
      b.clear();
    } else {
      b.write(s[i]);
    }
  }
  out.add(b.toString());
  return out;
}

String _unescape(String s) => s.replaceAllMapped(
    RegExp(r'\\(.)'), (m) => switch (m[1]!) { 'n' || 'N' => '\n', final c => c }).trim();

/// Instagram в vCard: соцсеть «instagram» (так пишут «Контакты» Apple,
/// иногда с ником в x-user) или просто ссылка на профиль.
String _instagram(List<_Prop> props) {
  for (final p in props.where((p) => const {'X-SOCIALPROFILE', 'URL', 'X-INSTAGRAM'}.contains(p.name))) {
    final m = RegExp(r'instagr(?:am\.com|\.am)/@?([A-Za-z0-9_.]+)').firstMatch(p.value);
    if (m != null) return '@${m[1]}';
    if (p.name == 'X-INSTAGRAM' || (p.params['TYPE'] ?? '').toLowerCase().contains('instagram')) {
      final user = p.params['X-USER'];
      if (user != null && user.isNotEmpty) return '@$user';
      final parts = p.value.replaceFirst(RegExp(r'^x-apple:'), '').split('/').where((s) => s.isNotEmpty);
      if (parts.isEmpty) continue;
      return parts.last.startsWith('@') ? parts.last : '@${parts.last}';
    }
  }
  return '';
}

(Contact, Uint8List?) _fromProps(Contact draft, List<_Prop> props) {
  _Prop? first(String name, [bool Function(_Prop)? prefer]) {
    final all = props.where((p) => p.name == name).toList();
    if (all.isEmpty) return null;
    return (prefer == null ? null : all.where(prefer).firstOrNull) ?? all.first;
  }

  var name = first('FN')?.value ?? '';
  if (name.isEmpty) {
    if (first('N') case final n?) {
      final c = n.components;
      name = [if (c.length > 1) c[1], c[0]].where((s) => s.isNotEmpty).join(' ');
    }
  }
  if (name.isEmpty) name = first('ORG')?.components.first ?? '';

  /// Все номера или адреса; помеченный PREF — первым, он станет основным.
  List<LabeledValue> labeled(String name, {required bool phone}) {
    final all = props.where((p) => p.name == name && p.value.isNotEmpty).toList();
    // vCard 3 пишет «TYPE=pref», vCard 4 — отдельный параметр «PREF=1».
    int pref(_Prop p) => p.hasType('PREF') || p.params.containsKey('PREF') ? 1 : 0;
    all.sort((a, b) => pref(b) - pref(a));
    final out = <LabeledValue>[];
    for (final p in all) {
      if (out.any((x) => x.value == p.value)) continue;
      out.add(LabeledValue(normalizeLabel(p.params['TYPE'] ?? '', phone: phone), p.value));
    }
    return out;
  }

  // Telegram прячется в разных полях: соцсети, мессенджеры, ссылки.
  var telegram = '';
  for (final p in props.where((p) => const {'X-SOCIALPROFILE', 'IMPP', 'URL', 'X-TELEGRAM'}.contains(p.name))) {
    final v = p.value;
    final m = RegExp(r'(?:t(?:elegram)?\.me/|telegram:|tg://resolve\?domain=)@?([A-Za-z0-9_]{3,})').firstMatch(v);
    if (m != null) {
      telegram = '@${m[1]}';
      break;
    }
    if (p.name == 'X-TELEGRAM' || (p.params['TYPE'] ?? '').toLowerCase().contains('telegram')) {
      telegram = v.startsWith('@') ? v : '@${v.split('/').last}';
      break;
    }
  }

  Uint8List? photo;
  if (first('PHOTO') case final p?) {
    final raw = p.raw.trim();
    final enc = (p.params['ENCODING'] ?? '').toUpperCase();
    try {
      if (raw.startsWith('data:')) {
        photo = base64.decode(raw.substring(raw.indexOf(',') + 1).replaceAll(RegExp(r'\s'), ''));
      } else if (enc == 'B' || enc == 'BASE64') {
        photo = base64.decode(raw.replaceAll(RegExp(r'\s'), ''));
      }
    } on FormatException {
      photo = null;
    }
  }

  final categories = first('CATEGORIES')?.value ?? '';
  return (
    draft.copyWith(
      name: name,
      phones: labeled('TEL', phone: true),
      emails: labeled('EMAIL', phone: false),
      telegram: telegram,
      instagram: _instagram(props),
      company: first('ORG')?.components.first ?? '',
      position: first('TITLE')?.value ?? '',
      birthday: () => parseDate(first('BDAY')?.value ?? ''),
      notes: first('NOTE')?.value ?? '',
      interests: _splitList(categories),
    ),
    photo,
  );
}
