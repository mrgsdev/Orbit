import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import 'platform.dart';
import 'theme.dart';

/// Действия, у которых пользователь может поменять сочетание клавиш.
enum HotkeyAction {
  search,
  newContact,
  settings,
  lock,
  goDashboard,
  goContacts,
  goFavorites,
  goBirthdays,
  goRecent,
  goTrash,
}

/// Сочетание: клавиша и модификаторы.
@immutable
class Combo {
  final LogicalKeyboardKey key;
  final bool meta;
  final bool shift;
  final bool alt;
  final bool control;

  const Combo(this.key, {this.meta = false, this.shift = false, this.alt = false, this.control = false});

  /// Главный модификатор платформы (⌘ или Ctrl) и клавиша.
  factory Combo.primary(LogicalKeyboardKey key, {bool shift = false}) =>
      Combo(key, meta: Os.isMac, control: !Os.isMac, shift: shift);

  /// Из нажатия: модификаторы берутся из текущего состояния клавиатуры.
  factory Combo.fromEvent(KeyEvent e) {
    final k = HardwareKeyboard.instance;
    return Combo(
      e.logicalKey,
      meta: k.isMetaPressed,
      shift: k.isShiftPressed,
      alt: k.isAltPressed,
      control: k.isControlPressed,
    );
  }

  SingleActivator get activator => SingleActivator(key, meta: meta, shift: shift, alt: alt, control: control);

  /// На Windows клавиша Win — системная, сочетания с ней не считаем.
  bool get hasModifier => alt || control || (meta && Os.isMac);

  static final _fKeys = {
    LogicalKeyboardKey.f1, LogicalKeyboardKey.f2, LogicalKeyboardKey.f3, LogicalKeyboardKey.f4,
    LogicalKeyboardKey.f5, LogicalKeyboardKey.f6, LogicalKeyboardKey.f7, LogicalKeyboardKey.f8,
    LogicalKeyboardKey.f9, LogicalKeyboardKey.f10, LogicalKeyboardKey.f11, LogicalKeyboardKey.f12,
  };

  /// F1–F12 можно назначать и без модификаторов: они не мешают вводу текста.
  bool get isFunctionKey => _fKeys.contains(key);

  /// Клавиши-модификаторы сами по себе сочетанием не считаются.
  static bool isModifierKey(LogicalKeyboardKey k) => {
        LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight,
        LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight,
        LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight,
        LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight,
        LogicalKeyboardKey.capsLock, LogicalKeyboardKey.fn,
      }.contains(k);

  /// На Mac — как в меню macOS: ⌃⌥⇧⌘ и клавиша. На Windows — Ctrl+Shift+L.
  String get label {
    final mac = Os.isMac;
    final keyLabel = switch (key) {
      LogicalKeyboardKey.arrowUp => '↑',
      LogicalKeyboardKey.arrowDown => '↓',
      LogicalKeyboardKey.arrowLeft => '←',
      LogicalKeyboardKey.arrowRight => '→',
      LogicalKeyboardKey.enter => 'Enter',
      LogicalKeyboardKey.backspace => mac ? '⌫' : 'Backspace',
      LogicalKeyboardKey.delete => mac ? '⌦' : 'Delete',
      LogicalKeyboardKey.escape => 'Esc',
      LogicalKeyboardKey.tab => mac ? '⇥' : 'Tab',
      LogicalKeyboardKey.space => 'Space',
      _ => key.keyLabel.length == 1 ? key.keyLabel.toUpperCase() : key.keyLabel,
    };
    if (mac) return '${control ? '⌃' : ''}${alt ? '⌥' : ''}${shift ? '⇧' : ''}${meta ? '⌘' : ''}$keyLabel';
    return [if (control) 'Ctrl', if (alt) 'Alt', if (shift) 'Shift', if (meta) 'Win', keyLabel].join('+');
  }

  Map<String, Object> toJson() => {'key': key.keyId, 'meta': meta, 'shift': shift, 'alt': alt, 'control': control};

  static Combo? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['key'];
    if (id is! int) return null;
    return Combo(
      LogicalKeyboardKey.findKeyByKeyId(id) ?? LogicalKeyboardKey(id),
      meta: j['meta'] == true,
      shift: j['shift'] == true,
      alt: j['alt'] == true,
      control: j['control'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Combo &&
      other.key == key &&
      other.meta == meta &&
      other.shift == shift &&
      other.alt == alt &&
      other.control == control;

  @override
  int get hashCode => Object.hash(key, meta, shift, alt, control);
}

/// Сочетания по умолчанию: ⌘ на Mac, Ctrl на Windows и Linux.
Map<HotkeyAction, Combo> get defaultHotkeys => {
      HotkeyAction.search: Combo.primary(LogicalKeyboardKey.keyF),
      HotkeyAction.newContact: Combo.primary(LogicalKeyboardKey.keyN),
      HotkeyAction.settings: Combo.primary(LogicalKeyboardKey.comma),
      HotkeyAction.lock: Combo.primary(LogicalKeyboardKey.keyL, shift: true),
      HotkeyAction.goDashboard: Combo.primary(LogicalKeyboardKey.digit1),
      HotkeyAction.goContacts: Combo.primary(LogicalKeyboardKey.digit2),
      HotkeyAction.goFavorites: Combo.primary(LogicalKeyboardKey.digit3),
      HotkeyAction.goBirthdays: Combo.primary(LogicalKeyboardKey.digit4),
      HotkeyAction.goRecent: Combo.primary(LogicalKeyboardKey.digit5),
      HotkeyAction.goTrash: Combo.primary(LogicalKeyboardKey.digit6),
    };

/// Сочетания, которые занимает система или поля ввода — их не даём.
Set<Combo> get reservedCombos => Os.isMac ? _reservedMac : _reservedWindows;

final _reservedMac = {
  Combo(LogicalKeyboardKey.keyQ, meta: true),
  Combo(LogicalKeyboardKey.keyW, meta: true),
  Combo(LogicalKeyboardKey.keyH, meta: true),
  Combo(LogicalKeyboardKey.keyM, meta: true),
  Combo(LogicalKeyboardKey.keyC, meta: true),
  Combo(LogicalKeyboardKey.keyV, meta: true),
  Combo(LogicalKeyboardKey.keyX, meta: true),
  Combo(LogicalKeyboardKey.keyZ, meta: true),
  Combo(LogicalKeyboardKey.keyZ, meta: true, shift: true),
  Combo(LogicalKeyboardKey.keyA, meta: true),
  Combo(LogicalKeyboardKey.keyS, meta: true),
  Combo(LogicalKeyboardKey.tab, meta: true),
  Combo(LogicalKeyboardKey.space, meta: true),
  // Остальное системное меню macOS.
  Combo(LogicalKeyboardKey.keyH, meta: true, alt: true),
  Combo(LogicalKeyboardKey.keyV, meta: true, alt: true, shift: true),
  Combo(LogicalKeyboardKey.keyJ, meta: true),
  Combo(LogicalKeyboardKey.semicolon, meta: true),
  Combo(LogicalKeyboardKey.semicolon, meta: true, shift: true),
  Combo(LogicalKeyboardKey.keyF, meta: true, control: true),
};

final _reservedWindows = {
  Combo(LogicalKeyboardKey.keyC, control: true),
  Combo(LogicalKeyboardKey.keyV, control: true),
  Combo(LogicalKeyboardKey.keyX, control: true),
  Combo(LogicalKeyboardKey.keyZ, control: true),
  Combo(LogicalKeyboardKey.keyY, control: true),
  Combo(LogicalKeyboardKey.keyZ, control: true, shift: true),
  Combo(LogicalKeyboardKey.keyA, control: true),
  Combo(LogicalKeyboardKey.keyS, control: true),
  Combo(LogicalKeyboardKey.keyW, control: true),
  Combo(LogicalKeyboardKey.f4, alt: true),
  Combo(LogicalKeyboardKey.tab, control: true),
  Combo(LogicalKeyboardKey.tab, alt: true),
  Combo(LogicalKeyboardKey.space, alt: true),
  Combo(LogicalKeyboardKey.escape, control: true),
  Combo(LogicalKeyboardKey.escape, control: true, shift: true),
  Combo(LogicalKeyboardKey.delete, control: true, alt: true),
};

/// Сочетания пользователя. Хранятся открытым текстом рядом с базой:
/// в них нет личных данных.
class Hotkeys extends ChangeNotifier {
  /// Идёт запись нового сочетания — остальные сочетания молчат.
  static bool recording = false;

  final File? _file;
  final Map<HotkeyAction, Combo> _custom;

  Hotkeys._(this._file, this._custom);

  /// Без файла: для тестов и когда настроек ещё нет.
  Hotkeys.memory() : _file = null, _custom = {};

  static Future<Hotkeys> load(Directory root) async {
    final file = File('${root.path}/shortcuts.json');
    final custom = <HotkeyAction, Combo>{};
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is Map) {
        for (final a in HotkeyAction.values) {
          if (Combo.fromJson(raw[a.name]) case final c?) custom[a] = c;
        }
      }
    } catch (_) {}
    return Hotkeys._(file, custom);
  }

  Combo of(HotkeyAction a) => _custom[a] ?? defaultHotkeys[a]!;

  bool isCustom(HotkeyAction a) => _custom.containsKey(a) && _custom[a] != defaultHotkeys[a];

  bool get anyCustom => HotkeyAction.values.any(isCustom);

  /// Действие, у которого уже стоит это сочетание (кроме [except]).
  HotkeyAction? usedBy(Combo c, {HotkeyAction? except}) {
    for (final a in HotkeyAction.values) {
      if (a != except && of(a) == c) return a;
    }
    return null;
  }

  void set(HotkeyAction a, Combo c) {
    if (c == defaultHotkeys[a]) {
      _custom.remove(a);
    } else {
      _custom[a] = c;
    }
    _changed();
  }

  void reset(HotkeyAction a) {
    _custom.remove(a);
    _changed();
  }

  void resetAll() {
    _custom.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _file
        ?.writeAsString(jsonEncode({for (final e in _custom.entries) e.key.name: e.value.toJson()}))
        .ignore();
  }
}

class HotkeysScope extends InheritedNotifier<Hotkeys> {
  const HotkeysScope({super.key, required Hotkeys hotkeys, required super.child}) : super(notifier: hotkeys);

  static final _fallback = Hotkeys.memory();

  /// Сочетания из [HotkeysScope] или стандартные, если его нет (в тестах).
  static Hotkeys of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HotkeysScope>()?.notifier ?? _fallback;

  /// Без подписки на изменения — для обработчиков событий.
  static Hotkeys read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HotkeysScope>()?.notifier ?? _fallback;
}

/// Название действия в языке интерфейса.
String hotkeyLabel(HotkeyAction a) => switch (a) {
      HotkeyAction.search => tr.actQuickSearch,
      HotkeyAction.newContact => tr.newContact,
      HotkeyAction.settings => tr.settings,
      HotkeyAction.lock => tr.lock,
      HotkeyAction.goDashboard => tr.actOpen(tr.segDashboard),
      HotkeyAction.goContacts => tr.actOpen(tr.segAll),
      HotkeyAction.goFavorites => tr.actOpen(tr.segFavorites),
      HotkeyAction.goBirthdays => tr.actOpen(tr.segBirthdays),
      HotkeyAction.goRecent => tr.actOpen(tr.segRecent),
      HotkeyAction.goTrash => tr.actOpen(tr.segTrash),
    };

/// Встроенные сочетания, которые не меняются: пара «клавиши — что делают».
List<(String, String)> get fixedHotkeys => [
      ('↑ ↓', tr.actMoveSelection),
      ('${Os.mod}/${Os.shift} + ${tr.click}', tr.actMultiSelect),
      (Combo.primary(LogicalKeyboardKey.keyA).label, tr.actSelectAll),
      ('Enter', tr.actEditSelected),
      (const Combo(LogicalKeyboardKey.backspace).label, tr.actTrashSelected),
      (Combo.primary(LogicalKeyboardKey.keyS).label, tr.actSaveEditor),
      ('Esc', tr.actCloseWindow),
    ];

/// Сочетание клавиш «клавишами»: ⇧⌘L в рамке, как на клавиатуре.
class KeyCaps extends StatelessWidget {
  final String label;
  const KeyCaps(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        constraints: const BoxConstraints(minWidth: 30),
        decoration: BoxDecoration(
          color: Pal.card,
          borderRadius: BorderRadius.circular(7),
          border: Border(
            top: BorderSide(color: Pal.border),
            left: BorderSide(color: Pal.border),
            right: BorderSide(color: Pal.border),
            bottom: BorderSide(color: Pal.border, width: 2),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: T.small.copyWith(color: Pal.text, fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
      );
}
