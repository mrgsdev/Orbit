import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../l10n/strings.dart';
import 'widgets.dart';

/// Выбранный язык. Хранится открытым текстом рядом с базой, как и тема:
/// он нужен уже на экране блокировки.
class LanguageSetting extends ChangeNotifier {
  final File? _file;
  String? _code;

  LanguageSetting._(this._file, this._code);

  /// Для тестов: без файла. null — как в системе.
  LanguageSetting.memory([this._code]) : _file = null;

  static Future<LanguageSetting> load(Directory root) async {
    final file = File('${root.path}/language');
    String? code;
    try {
      final saved = (await file.readAsString()).trim();
      if (languageByCode(saved) != null) code = saved;
    } catch (_) {}
    return LanguageSetting._(file, code);
  }

  /// Код языка (`ru`, `en`…); null — как в системе.
  String? get code => _code;

  set code(String? value) {
    if (value == _code) return;
    _code = value;
    notifyListeners();
    _file?.writeAsString(value ?? '').ignore();
  }

  /// Строки для выбранного языка; «как в системе» — первый подходящий
  /// из языков macOS, иначе английский.
  Strings resolve(List<Locale> system) {
    if (_code case final code?) return languageByCode(code) ?? languages.first;
    for (final l in system) {
      if (languageByCode(l.languageCode) case final s?) return s;
    }
    return languageByCode('en')!;
  }
}

class LanguageScope extends InheritedNotifier<LanguageSetting> {
  const LanguageScope({super.key, required LanguageSetting language, required super.child}) : super(notifier: language);

  static LanguageSetting? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}

/// Выбор языка: «Системный» и шесть языков, каждый — на нём самом.
class LanguageDropdown extends StatelessWidget {
  final double width;
  const LanguageDropdown({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    final setting = LanguageScope.maybeOf(context);
    return Dropdown<String>(
      value: setting?.code ?? '',
      width: width,
      height: 38,
      items: [('', tr.systemLanguage), for (final l in languages) (l.locale, l.languageName)],
      onChanged: (v) => setting?.code = v.isEmpty ? null : v,
    );
  }
}
