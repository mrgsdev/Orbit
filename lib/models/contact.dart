class Contact {
  final String id;
  final String name;
  final String phone;
  final String telegram;
  final String email;
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
    this.phone = '',
    this.telegram = '',
    this.email = '',
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

  /// Ник без ведущего @ и без префикса ссылки t.me.
  String get telegramHandle => telegram
      .trim()
      .replaceFirst(RegExp(r'^(https?://)?(t\.me|telegram\.me)/'), '')
      .replaceFirst('@', '');

  String get telegramUrl => 'https://t.me/@$telegramHandle';

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
      phone,
      telegram,
      email,
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
    String? phone,
    String? telegram,
    String? email,
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
      phone: phone ?? this.phone,
      telegram: telegram ?? this.telegram,
      email: email ?? this.email,
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
        'phone': phone,
        'telegram': telegram,
        'email': email,
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
    return Contact(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      telegram: j['telegram'] as String? ?? '',
      email: j['email'] as String? ?? '',
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
