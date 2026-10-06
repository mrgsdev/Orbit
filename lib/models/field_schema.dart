import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum FieldType {
  text('Текст', 'text'),
  multiline('Длинный текст', 'notes'),
  number('Число', 'number'),
  phone('Телефон', 'phone'),
  email('Email', 'email'),
  url('Ссылка', 'link'),
  date('Дата', 'date'),
  select('Список', 'list'),
  checkbox('Да / нет', 'check');

  final String label;
  final String defaultIcon;
  const FieldType(this.label, this.defaultIcon);

  /// Значение вводится в обычное текстовое поле.
  bool get isTextual => switch (this) {
        FieldType.date || FieldType.select || FieldType.checkbox => false,
        _ => true,
      };
}

/// Иконки, из которых пользователь выбирает. Хранится ключ, а не codepoint:
/// константные IconData нужны, чтобы сборка не тянула весь шрифт иконок.
const fieldIcons = <String, IconData>{
  'text': Icons.short_text_rounded,
  'notes': Icons.notes_rounded,
  'number': Icons.tag_rounded,
  'phone': Icons.phone_outlined,
  'email': Icons.mail_outline_rounded,
  'link': Icons.link_rounded,
  'date': Icons.event_outlined,
  'list': Icons.list_alt_rounded,
  'check': Icons.check_box_outlined,
  'person': Icons.person_outline_rounded,
  'group': Icons.people_alt_outlined,
  'home': Icons.home_outlined,
  'place': Icons.place_outlined,
  'work': Icons.work_outline_rounded,
  'business': Icons.business_outlined,
  'school': Icons.school_outlined,
  'handshake': Icons.handshake_outlined,
  'cake': Icons.cake_outlined,
  'gift': Icons.card_giftcard_rounded,
  'heart': Icons.favorite_border_rounded,
  'star': Icons.star_outline_rounded,
  'chat': Icons.chat_bubble_outline_rounded,
  'send': Icons.send_outlined,
  'language': Icons.language_rounded,
  'code': Icons.code_rounded,
  'idea': Icons.lightbulb_outline_rounded,
  'money': Icons.payments_outlined,
  'flight': Icons.flight_outlined,
  'car': Icons.directions_car_outlined,
  'pet': Icons.pets_rounded,
  'music': Icons.music_note_outlined,
  'sport': Icons.sports_soccer_outlined,
  'game': Icons.sports_esports_outlined,
  'book': Icons.menu_book_outlined,
  'camera': Icons.photo_camera_outlined,
  'folder': Icons.folder_outlined,
  'interests': Icons.interests_outlined,
  'label': Icons.label_outline_rounded,
};

IconData iconFor(String key) => fieldIcons[key] ?? Icons.short_text_rounded;

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
      FieldType.checkbox => value == true ? 'Да' : 'Нет',
      FieldType.date => switch (DateTime.tryParse('$value')) {
          final d? => DateFormat('d MMMM y', 'ru').format(d),
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

  static const fixedFields = <String, List<(String, String)>>{
    main: [('Имя', 'person'), ('Телефон', 'phone'), ('Telegram', 'send'), ('Email', 'email')],
    work: [('Должность', 'work'), ('Компания', 'business')],
    meet: [('Где познакомились', 'handshake'), ('Дата знакомства', 'date'), ('День рождения', 'cake')],
    interests: [('Интересы', 'interests')],
    notes: [('Заметки', 'notes')],
  };
}
