/// Телефон или почта с подписью: «мобильный», «рабочий»…
class LabeledValue {
  final String label;
  final String value;

  const LabeledValue(this.label, this.value);

  static const phoneLabels = ['мобильный', 'рабочий', 'домашний', 'другой'];
  static const emailLabels = ['личный', 'рабочий', 'другой'];

  Map<String, dynamic> toJson() => {'label': label, 'value': value};

  factory LabeledValue.fromJson(Map<String, dynamic> j) =>
      LabeledValue(j['label'] as String? ?? '', j['value'] as String? ?? '');

  @override
  bool operator ==(Object other) =>
      other is LabeledValue && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => '$label: $value';
}

class Contact {
  final String id;
  final String name;

  /// Первый номер и первая почта — основные: их показывают таблица
  /// и карточки, по ним звонят и пишут из быстрых действий.
  final List<LabeledValue> phones;
  final String telegram;
  final String instagram;
  final List<LabeledValue> emails;
  final String position;
  final String company;
  final String whereMet;
  final DateTime? metDate;
  final DateTime? birthday;
  final List<String> interests;
  final String notes;

  /// Значения пользовательских полей: id поля → строка, а у «да/нет» — bool.
  final Map<String, Object?> custom;

  /// Имя файла фото внутри папки photos хранилища (не абсолютный путь,
  /// чтобы база переживала перенос папки приложения).
  final String? photoFile;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Когда контакт перенесён в корзину; null — контакт активен.
  final DateTime? deletedAt;

  const Contact({
    required this.id,
    required this.name,
    this.phones = const [],
    this.telegram = '',
    this.instagram = '',
    this.emails = const [],
    this.position = '',
    this.company = '',
    this.whereMet = '',
    this.metDate,
    this.birthday,
    this.interests = const [],
    this.notes = '',
    this.custom = const {},
    this.photoFile,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get phone => phones.isEmpty ? '' : phones.first.value;
  String get email => emails.isEmpty ? '' : emails.first.value;

  /// Ник без @, без адреса t.me / telegram.me / tg:// и хвоста ссылки.
  String get telegramHandle => telegram
      .trim()
      .replaceFirst(RegExp(r'^tg://resolve\?domain='), '')
      .replaceFirst(RegExp(r'^(https?://)?(www\.)?(t\.me|telegram\.me|telegram\.dog)/'), '')
      .replaceFirst('@', '')
      .split(RegExp(r'[/?#&]'))
      .first;

  /// Профиль открывается по t.me/ник, как бы ник ни был записан.
  String get telegramUrl => 'https://t.me/$telegramHandle';

  /// Ник без @, без адреса профиля и хвоста ссылки (?igsh=…, /).
  String get instagramHandle => instagram
      .trim()
      .replaceFirst(RegExp(r'^(https?://)?(www\.)?(instagram\.com|instagr\.am)/'), '')
      .replaceFirst('@', '')
      .split(RegExp(r'[/?#]'))
      .first;

  String get instagramUrl => 'https://instagram.com/$instagramHandle';

  /// Сколько дней до ближайшего дня рождения (0 — сегодня).
  int? daysUntilBirthday(DateTime now) {
    final b = birthday;
    if (b == null) return null;
    // UTC, чтобы переход на летнее время не сдвигал разницу на день.
    final today = DateTime.utc(now.year, now.month, now.day);
    var next = DateTime.utc(now.year, b.month, b.day);
    if (next.isBefore(today)) next = DateTime.utc(now.year + 1, b.month, b.day);
    return next.difference(today).inDays;
  }

  bool matches(String query) {
    final q = query.toLowerCase();
    return [
      name,
      ...phones.map((p) => p.value),
      telegram,
      instagram,
      ...emails.map((e) => e.value),
      position,
      company,
      whereMet,
      notes,
      ...interests,
      ...custom.values.whereType<String>(),
    ].any((f) => f.toLowerCase().contains(q));
  }

  Contact copyWith({
    String? name,
    List<LabeledValue>? phones,
    String? telegram,
    String? instagram,
    List<LabeledValue>? emails,
    String? position,
    String? company,
    String? whereMet,
    DateTime? Function()? metDate,
    DateTime? Function()? birthday,
    List<String>? interests,
    String? notes,
    Map<String, Object?>? custom,
    String? Function()? photoFile,
    bool? favorite,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      phones: phones ?? this.phones,
      telegram: telegram ?? this.telegram,
      instagram: instagram ?? this.instagram,
      emails: emails ?? this.emails,
      position: position ?? this.position,
      company: company ?? this.company,
      whereMet: whereMet ?? this.whereMet,
      metDate: metDate != null ? metDate() : this.metDate,
      birthday: birthday != null ? birthday() : this.birthday,
      interests: interests ?? this.interests,
      notes: notes ?? this.notes,
      custom: custom ?? this.custom,
      photoFile: photoFile != null ? photoFile() : this.photoFile,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phones': phones.map((p) => p.toJson()).toList(),
        'telegram': telegram,
        'instagram': instagram,
        'emails': emails.map((e) => e.toJson()).toList(),
        'position': position,
        'company': company,
        'whereMet': whereMet,
        'metDate': metDate?.toIso8601String(),
        'birthday': birthday?.toIso8601String(),
        'interests': interests,
        'notes': notes,
        'custom': custom,
        'photoFile': photoFile,
        'favorite': favorite,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> j) {
    DateTime? date(String key) =>
        j[key] == null ? null : DateTime.tryParse(j[key] as String);
    // До списков телефон и почта хранились одной строкой.
    List<LabeledValue> values(String listKey, String legacyKey, String legacyLabel) {
      final list = j[listKey] as List?;
      if (list != null) {
        return [for (final e in list) LabeledValue.fromJson(e as Map<String, dynamic>)];
      }
      final legacy = (j[legacyKey] as String? ?? '').trim();
      return legacy.isEmpty ? const [] : [LabeledValue(legacyLabel, legacy)];
    }

    return Contact(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      phones: values('phones', 'phone', LabeledValue.phoneLabels.first),
      telegram: j['telegram'] as String? ?? '',
      instagram: j['instagram'] as String? ?? '',
      emails: values('emails', 'email', LabeledValue.emailLabels.first),
      position: j['position'] as String? ?? '',
      company: j['company'] as String? ?? '',
      whereMet: j['whereMet'] as String? ?? '',
      metDate: date('metDate'),
      birthday: date('birthday'),
      interests: (j['interests'] as List?)?.cast<String>() ?? const [],
      notes: j['notes'] as String? ?? '',
      custom: (j['custom'] as Map?)?.cast<String, Object?>() ?? const {},
      photoFile: j['photoFile'] as String?,
      favorite: j['favorite'] as bool? ?? false,
      createdAt: date('createdAt') ?? DateTime.now(),
      updatedAt: date('updatedAt') ?? DateTime.now(),
      deletedAt: date('deletedAt'),
    );
  }
}
