import 'package:flutter/widgets.dart';

/// Набор цветов одной темы.
class Palette {
  final Brightness brightness;

  final Color canvas;
  final Color rail;
  final Color railActive;
  final Color railActiveIcon;
  final Color card;
  final Color cardBorder;
  final Color gridCard;
  final Color raised;
  final Color hover;
  final Color border;
  final Color borderHover;
  final Color divider;
  final Color searchFill;
  final Color selectedRow;

  final Color text;
  final Color muted;
  final Color dim;

  /// Цвет действий: кнопки, выбор, фокус.
  final Color accent;
  final Color accentHover;

  /// Текст и иконки поверх [accent] и ярких карточек.
  final Color onAccent;

  /// Акцент для текста и тонких иконок: на белом жёлтый не читается.
  final Color accentText;

  final Color red;
  final Color dangerFill;
  final Color dangerHover;

  final Color tooltip;
  final Color popover;
  final Color toast;
  final Color spotlight;
  final Color thumb;
  final Color scrim;
  final Color shadow;

  const Palette({
    required this.brightness,
    required this.canvas,
    required this.rail,
    required this.railActive,
    required this.railActiveIcon,
    required this.card,
    required this.cardBorder,
    required this.gridCard,
    required this.raised,
    required this.hover,
    required this.border,
    required this.borderHover,
    required this.divider,
    required this.searchFill,
    required this.selectedRow,
    required this.text,
    required this.muted,
    required this.dim,
    required this.accent,
    required this.accentHover,
    required this.onAccent,
    required this.accentText,
    required this.red,
    required this.dangerFill,
    required this.dangerHover,
    required this.tooltip,
    required this.popover,
    required this.toast,
    required this.spotlight,
    required this.thumb,
    required this.scrim,
    required this.shadow,
  });

  /// Тёмная: почти чёрные карточки на графитовом фоне, жёлтый акцент
  /// и яркие «билеты» для главных цифр.
  static const dark = Palette(
    brightness: Brightness.dark,
    canvas: Color(0xFF1B1B1D),
    rail: Color(0xFF111112),
    railActive: Color(0xFF050505),
    railActiveIcon: Color(0xFFFFFFFF),
    card: Color(0xFF111113),
    cardBorder: Color(0xFF1E1E22),
    gridCard: Color(0xFF17171A),
    raised: Color(0xFF1F1F22),
    hover: Color(0xFF26262A),
    border: Color(0xFF2B2B30),
    borderHover: Color(0xFF3C3C42),
    divider: Color(0xFF232327),
    searchFill: Color(0xFF232326),
    selectedRow: Color(0xFF1E1D17),
    text: Color(0xFFFFFFFF),
    muted: Color(0xFF8E8E96),
    dim: Color(0xFF55555C),
    accent: Color(0xFFF9D54A),
    accentHover: Color(0xFFFFE070),
    onAccent: Color(0xFF111113),
    accentText: Color(0xFFF9D54A),
    red: Color(0xFFFF5A5F),
    dangerFill: Color(0xFF2A1618),
    dangerHover: Color(0xFF3A1D20),
    tooltip: Color(0xFF2C2C30),
    popover: Color(0xFF1A1A1D),
    toast: Color(0xFF26262A),
    spotlight: Color(0xF2161618),
    thumb: Color(0xFF3A3A40),
    scrim: Color(0x99000000),
    shadow: Color(0x80000000),
  );

  /// Светлая: белые фоны и чёрный текст, а акценты — как в тёмной:
  /// жёлтые кнопки, яркие карточки и интересы.
  static const light = Palette(
    brightness: Brightness.light,
    canvas: Color(0xFFFFFFFF),
    rail: Color(0xFFFFFFFF),
    railActive: Color(0xFF111113),
    railActiveIcon: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE6E6E6),
    gridCard: Color(0xFFFFFFFF),
    raised: Color(0xFFF4F4F4),
    hover: Color(0xFFEDEDED),
    border: Color(0xFFE0E0E0),
    borderHover: Color(0xFFBDBDBD),
    divider: Color(0xFFEEEEEE),
    searchFill: Color(0xFFF4F4F4),
    selectedRow: Color(0xFFFFF8DC),
    text: Color(0xFF000000),
    muted: Color(0xFF6B6B6B),
    dim: Color(0xFFA6A6A6),
    accent: Color(0xFFF9D54A),
    accentHover: Color(0xFFFFE070),
    onAccent: Color(0xFF111113),
    accentText: Color(0xFFB08500),
    red: Color(0xFFD93025),
    dangerFill: Color(0xFFFDEEEE),
    dangerHover: Color(0xFFFADADA),
    tooltip: Color(0xFF2C2C30),
    popover: Color(0xFFFFFFFF),
    toast: Color(0xFFFFFFFF),
    spotlight: Color(0xF7FFFFFF),
    thumb: Color(0xFFC4C4C4),
    scrim: Color(0x40000000),
    shadow: Color(0x24000000),
  );
}

/// Цвета текущей темы. Меняются вместе с темой, поэтому это геттеры,
/// а не константы.
abstract final class Pal {
  static Palette current = Palette.dark;

  static bool get isDark => current.brightness == Brightness.dark;

  static Color get canvas => current.canvas;
  static Color get rail => current.rail;
  static Color get railActive => current.railActive;
  static Color get railActiveIcon => current.railActiveIcon;
  static Color get card => current.card;
  static Color get cardBorder => current.cardBorder;
  static Color get gridCard => current.gridCard;
  static Color get raised => current.raised;
  static Color get hover => current.hover;
  static Color get border => current.border;
  static Color get borderHover => current.borderHover;
  static Color get divider => current.divider;
  static Color get searchFill => current.searchFill;
  static Color get selectedRow => current.selectedRow;

  static Color get text => current.text;
  static Color get muted => current.muted;
  static Color get dim => current.dim;

  static Color get accent => current.accent;
  static Color get accentHover => current.accentHover;
  static Color get onAccent => current.onAccent;
  static Color get accentText => current.accentText;

  static Color get red => current.red;
  static Color get dangerFill => current.dangerFill;
  static Color get dangerHover => current.dangerHover;

  static Color get tooltip => current.tooltip;

  /// Подсказка тёмная в обеих темах, текст на ней белый.
  static Color get tooltipText => const Color(0xFFFFFFFF);
  static Color get popover => current.popover;
  static Color get toast => current.toast;
  static Color get spotlight => current.spotlight;
  static Color get thumb => current.thumb;
  static Color get scrim => current.scrim;
  static Color get shadow => current.shadow;

  // Яркие цвета тёмной темы: карточки, интересы, монограммы.
  static const yellow = Color(0xFFF9D54A);
  static const teal = Color(0xFF1FE5C4);
  static const pink = Color(0xFFF08CF4);
  static const purple = Color(0xFF7D6BF5);
  static const orange = Color(0xFFFF8A3D);
  static const green = Color(0xFF3FD97F);
  static const blue = Color(0xFF5B8CFF);
}

abstract final class Fonts {
  static const sans = 'Montserrat';
  static const script = 'MarckScript';
}

/// Типографика на Montserrat. Геттеры — цвет текста зависит от темы.
abstract final class T {
  static TextStyle get _base => TextStyle(fontFamily: Fonts.sans, color: Pal.text, height: 1.3, letterSpacing: 0);

  static TextStyle get display => _base.copyWith(fontSize: 34, fontWeight: FontWeight.w500, letterSpacing: -0.5);
  static TextStyle get number => _base.copyWith(fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1);
  static TextStyle get title => _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle get heading => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600);
  static TextStyle get body => _base.copyWith(fontSize: 13.5, fontWeight: FontWeight.w500);
  static TextStyle get small => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: Pal.muted);
  static TextStyle get tiny => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: Pal.muted);
  static TextStyle get script => TextStyle(fontFamily: Fonts.script, fontSize: 30, color: Pal.text);
}

/// Стабильный яркий цвет по тексту — для интересов и монограмм.
abstract final class TagColors {
  static const _hues = [Pal.teal, Pal.yellow, Pal.pink, Pal.purple, Pal.orange, Pal.green, Pal.blue, Color(0xFFFF5A5F)];

  static Color hue(String key) => _hues[key.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x3fffffff) % _hues.length];
}
