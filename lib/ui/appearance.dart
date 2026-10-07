import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

enum ThemeChoice {
  light,
  system,
  dark;

  String get label => switch (this) {
        ThemeChoice.light => tr.themeLight,
        ThemeChoice.system => tr.themeSystem,
        ThemeChoice.dark => tr.themeDark,
      };
}

/// Выбранная тема. Хранится открытым текстом рядом с базой: она нужна ещё
/// на экране блокировки, до расшифровки настроек, и ничего не раскрывает.
class Appearance extends ChangeNotifier {
  final File? _file;
  ThemeChoice _choice;

  Appearance._(this._file, this._choice);

  /// Для тестов: без файла.
  Appearance.memory([this._choice = ThemeChoice.dark]) : _file = null;

  static Future<Appearance> load(Directory root) async {
    final file = File('${root.path}/appearance');
    var choice = ThemeChoice.system;
    try {
      final saved = (await file.readAsString()).trim();
      choice = ThemeChoice.values.firstWhere(
        (c) => c.name == saved,
        orElse: () => choice,
      );
    } catch (_) {}
    return Appearance._(file, choice);
  }

  ThemeChoice get choice => _choice;

  set choice(ThemeChoice value) {
    if (value == _choice) return;
    _choice = value;
    notifyListeners();
    _file?.writeAsString(value.name).ignore();
  }

  Brightness resolve(Brightness platform) => switch (_choice) {
    ThemeChoice.light => Brightness.light,
    ThemeChoice.dark => Brightness.dark,
    ThemeChoice.system => platform,
  };
}

/// Доступ к [Appearance] из любого места дерева.
class AppearanceScope extends InheritedNotifier<Appearance> {
  const AppearanceScope({
    super.key,
    required Appearance appearance,
    required super.child,
  }) : super(notifier: appearance);

  static Appearance of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()!.notifier!;

  static Appearance? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}

/// Ставит палитру под тему и перестраивает всё дерево: цвета читаются
/// из [Pal] при сборке, поэтому достаточно пересобрать каждый элемент.
/// Состояние (разблокировка, открытые окна, выделение) не теряется.
void applyPalette(BuildContext context, Brightness brightness) {
  final next = brightness == Brightness.dark ? Palette.dark : Palette.light;
  if (identical(next, Pal.current)) return;
  Pal.current = next;
  rebuildAll(context);
}

/// Пересобирает каждый элемент дерева под [context]: так подхватываются
/// новые цвета [Pal] и строки `tr` даже в const-виджетах.
void rebuildAll(BuildContext context) {
  void rebuild(Element e) {
    e.markNeedsBuild();
    e.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}

/// Переключатель темы для меню: светлая, системная, тёмная.
class ThemeSwitch extends StatelessWidget {
  /// Подпись «Оформление» над переключателем — для меню; в настройках
  /// подпись стоит слева в строке.
  final bool showLabel;
  const ThemeSwitch({super.key, this.showLabel = true});

  static const _icons = {
    ThemeChoice.light: CupertinoIcons.sun_max,
    ThemeChoice.system: CupertinoIcons.circle_lefthalf_fill,
    ThemeChoice.dark: CupertinoIcons.moon,
  };

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) return const SizedBox.shrink();
    return Padding(
      padding: showLabel ? const EdgeInsets.fromLTRB(10, 6, 10, 8) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLabel) ...[Text(tr.appearance, style: T.small), const SizedBox(height: 8)],
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Pal.raised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Pal.border),
            ),
            child: Row(
              children: [
                for (final c in ThemeChoice.values)
                  Expanded(
                    child: Pressable(
                      key: ValueKey('theme-${c.name}'),
                      onTap: () => appearance.choice = c,
                      builder: (context, hover, _) {
                        final active = c == appearance.choice;
                        final fg = active ? Pal.onAccent : (hover ? Pal.text : Pal.muted);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: active ? Pal.accent : (hover ? Pal.hover : null),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_icons[c], size: 14, color: fg),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  c.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: T.small.copyWith(color: fg, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
