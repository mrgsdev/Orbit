import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

import '../l10n/strings.dart';

/// Различия macOS и Windows/Linux: главная клавиша (⌘ или Ctrl), подписи
/// клавиш и названия системных программ.
abstract final class Os {
  /// В стиле macOS. Тесты могут переключить, чтобы проверить Windows.
  static bool isMac = Platform.isMacOS;

  /// Главный модификатор: ⌘ на Mac, Ctrl на Windows и Linux.
  static String get mod => isMac ? '⌘' : 'Ctrl';
  static String get shift => isMac ? '⇧' : 'Shift';

  /// Зажат ли главный модификатор — для ⌘-клика и ⌘A.
  static bool get primaryPressed =>
      isMac ? HardwareKeyboard.instance.isMetaPressed : HardwareKeyboard.instance.isControlPressed;

  /// Сочетание «главный модификатор + клавиша».
  static SingleActivator primary(LogicalKeyboardKey key) => SingleActivator(key, meta: isMac, control: !isMac);

  /// Кнопка «показать папку»: Finder, Проводник или просто папка.
  static String get showFolderLabel =>
      isMac ? tr.showInFinder : (Platform.isWindows ? tr.showInExplorer : tr.openFolderAction);
}
