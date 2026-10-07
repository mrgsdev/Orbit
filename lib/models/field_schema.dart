import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../l10n/strings.dart';

enum FieldType {
  text('text'),
  multiline('notes'),
  number('number'),
  phone('phone'),
  email('email'),
  url('link'),
  date('date'),
  select('list'),
  checkbox('check');

  final String defaultIcon;
  const FieldType(this.defaultIcon);

  String get label => tr.fieldTypeLabel(this);

  /// Значение вводится в обычное текстовое поле.
  bool get isTextual => switch (this) {
        FieldType.date || FieldType.select || FieldType.checkbox => false,
        _ => true,
      };
}

/// Иконки, из которых пользователь выбирает. Хранится ключ, а не codepoint:
/// константные IconData нужны, чтобы сборка не тянула весь шрифт иконок.
const fieldIcons = <String, IconData>{
  'text': CupertinoIcons.textformat,
  'notes': CupertinoIcons.doc_text,
  'number': CupertinoIcons.number,
  'phone': CupertinoIcons.phone,
  'email': CupertinoIcons.envelope,
  'link': CupertinoIcons.link,
  'date': CupertinoIcons.calendar,
  'list': CupertinoIcons.list_bullet,
  'check': CupertinoIcons.checkmark_square,
  'person': CupertinoIcons.person,
  'group': CupertinoIcons.person_2,
  'home': CupertinoIcons.house,
  'place': CupertinoIcons.location,
  'work': CupertinoIcons.briefcase,
  'business': CupertinoIcons.building_2_fill,
  'school': CupertinoIcons.book,
  'handshake': CupertinoIcons.hand_raised,
  'cake': CupertinoIcons.gift,
  'gift': CupertinoIcons.gift_fill,
  'heart': CupertinoIcons.heart,
  'star': CupertinoIcons.star,
  'chat': CupertinoIcons.chat_bubble,
  'send': CupertinoIcons.paperplane,
  'language': CupertinoIcons.globe,
  'code': CupertinoIcons.chevron_left_slash_chevron_right,
  'idea': CupertinoIcons.lightbulb,
  'money': CupertinoIcons.money_dollar_circle,
  'flight': CupertinoIcons.airplane,
  'car': CupertinoIcons.car,
  'pet': CupertinoIcons.paw,
  'music': CupertinoIcons.music_note,
  'sport': CupertinoIcons.sportscourt,
  'game': CupertinoIcons.gamecontroller,
  'book': CupertinoIcons.book,
  'camera': CupertinoIcons.camera,
  'folder': CupertinoIcons.folder,
  'interests': CupertinoIcons.sparkles,
  'label': CupertinoIcons.tag,
};

IconData iconFor(String key) => fieldIcons[key] ?? CupertinoIcons.textformat;

class CustomField {
  final String id;
  final String label;
  final FieldType type;
  final String icon;

  /// Варианты для [FieldType.select].
  final List<String> options;
  final bool showInTable;

  const CustomField({
    required this.id,
    required this.label,
    this.type = FieldType.text,
    this.icon = 'text',
    this.options = const [],
    this.showInTable = false,
  });

  CustomField copyWith({
    String? label,
    FieldType? type,
    String? icon,
    List<String>? options,
    bool? showInTable,
  }) =>
      CustomField(
        id: id,
        label: label ?? this.label,
        type: type ?? this.type,
        icon: icon ?? this.icon,
        options: options ?? this.options,
        showInTable: showInTable ?? this.showInTable,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'icon': icon,
        'options': options,
        'showInTable': showInTable,
      };

  factory CustomField.fromJson(Map<String, dynamic> j) => CustomField(
        id: j['id'] as String,
        label: j['label'] as String? ?? '',
        type: FieldType.values.asNameMap()[j['type']] ?? FieldType.text,
        icon: j['icon'] as String? ?? 'text',
        options: (j['options'] as List?)?.cast<String>() ?? const [],
        showInTable: j['showInTable'] as bool? ?? false,
      );

  /// Значение для показа человеку; null — поле не заполнено.
  String? format(Object? value) {
    if (value == null || value == '') return null;
    return switch (type) {
      FieldType.checkbox => value == true ? tr.yes : tr.no,
      FieldType.date => switch (DateTime.tryParse('$value')) {
          final d? => DateFormat('d MMMM y', tr.locale).format(d),
          null => '$value',
        },
      _ => '$value',
    };
  }
}

class FieldSection {
  final String id;
  final String title;
  final String icon;

  /// Стандартный раздел со встроенными полями: его нельзя удалить,
  /// но можно переименовать, переставить и добавить в него свои поля.
  final bool builtIn;
  final List<CustomField> fields;

  const FieldSection({
    required this.id,
    required this.title,
    this.icon = 'folder',
    this.builtIn = false,
    this.fields = const [],
  });

  FieldSection copyWith({String? title, String? icon, List<CustomField>? fields}) =>
      FieldSection(
        id: id,
        title: title ?? this.title,
        icon: icon ?? this.icon,
        builtIn: builtIn,
        fields: fields ?? this.fields,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'builtIn': builtIn,
        'fields': fields.map((f) => f.toJson()).toList(),
      };

  factory FieldSection.fromJson(Map<String, dynamic> j) => FieldSection(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        icon: j['icon'] as String? ?? 'folder',
        builtIn: j['builtIn'] as bool? ?? false,
        fields: [
          for (final f in (j['fields'] as List?) ?? const [])
            CustomField.fromJson(f as Map<String, dynamic>),
        ],
      );
}

/// Стандартные разделы и встроенные в них поля модели [Contact].
abstract final class BuiltIn {
  static const main = 'main';
  static const work = 'work';
  static const meet = 'meet';
  static const interests = 'interests';
  static const notes = 'notes';

  static const sections = [
    FieldSection(id: main, title: 'Основное', icon: 'person', builtIn: true),
    FieldSection(id: work, title: 'Работа', icon: 'work', builtIn: true),
    FieldSection(id: meet, title: 'Знакомство', icon: 'handshake', builtIn: true),
    FieldSection(id: interests, title: 'Сфера интересов', icon: 'interests', builtIn: true),
    FieldSection(id: notes, title: 'Заметки', icon: 'notes', builtIn: true),
  ];

  /// Встроенные поля: ключ подписи (см. `Strings.builtInFieldLabel`) и иконка.
  static const fixedFields = <String, List<(String, String)>>{
    main: [('name', 'person'), ('phones', 'phone'), ('telegram', 'send'), ('instagram', 'camera'), ('emails', 'email')],
    work: [('position', 'work'), ('company', 'business')],
    meet: [('whereMet', 'handshake'), ('metDate', 'date'), ('birthday', 'cake')],
    interests: [('interests', 'interests')],
    notes: [('notes', 'notes')],
  };
}
