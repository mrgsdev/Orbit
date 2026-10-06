import 'package:flutter/material.dart';

/// Палитра приложения: нейтральные поверхности, чёрный для главной кнопки
/// и оранжевый акцент для выделения.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color ink;
  final Color onInk;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color star;

  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.ink,
    required this.onInk,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.star,
  });

  static const light = AppColors(
    canvas: Color(0xFFF2F2F4),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF7F7F8),
    border: Color(0xFFE8E8EC),
    text: Color(0xFF18181B),
    textMuted: Color(0xFF7C7C86),
    accent: Color(0xFFF25C2A),
    accentSoft: Color(0xFFFFF3EE),
    ink: Color(0xFF18181B),
    onInk: Color(0xFFFFFFFF),
    success: Color(0xFF1F9D55),
    successSoft: Color(0xFFE7F8EE),
    danger: Color(0xFFE5484D),
    star: Color(0xFFF5A524),
  );

  static const dark = AppColors(
    canvas: Color(0xFF0E0E10),
    surface: Color(0xFF17171A),
    surfaceMuted: Color(0xFF1E1E22),
    border: Color(0xFF2A2A30),
    text: Color(0xFFF4F4F5),
    textMuted: Color(0xFF9A9AA4),
    accent: Color(0xFFF46A3D),
    accentSoft: Color(0xFF2E1D17),
    ink: Color(0xFFF4F4F5),
    onInk: Color(0xFF17171A),
    success: Color(0xFF4CC38A),
    successSoft: Color(0xFF15291F),
    danger: Color(0xFFFF6369),
    star: Color(0xFFF5B947),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Стабильный цвет тега по его тексту: один интерес везде одного цвета.
class TagColors {
  static const _hues = [
    Color(0xFF4F5BD5),
    Color(0xFFE2541B),
    Color(0xFF1F9D55),
    Color(0xFF7C4DDB),
    Color(0xFFD6336C),
    Color(0xFFB7791F),
    Color(0xFF0F8A8A),
    Color(0xFF2B7BD6),
  ];

  static Color hue(String key) =>
      _hues[key.codeUnits.fold(0, (a, b) => a * 31 + b) % _hues.length];

  static (Color bg, Color fg) of(String key, Brightness brightness) {
    final h = hue(key);
    return brightness == Brightness.light
        ? (Color.alphaBlend(h.withValues(alpha: 0.10), Colors.white), h)
        : (h.withValues(alpha: 0.20), Color.lerp(h, Colors.white, 0.4)!);
  }
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.accent,
    brightness: brightness,
  ).copyWith(
    primary: c.accent,
    onPrimary: Colors.white,
    surface: c.surface,
    onSurface: c.text,
    onSurfaceVariant: c.textMuted,
    outline: c.border,
    outlineVariant: c.border,
    error: c.danger,
    surfaceContainerHighest: c.surfaceMuted,
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c.border),
  );
  final menuShape = WidgetStatePropertyAll(RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: c.border),
  ));

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: c.canvas,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
    iconTheme: IconThemeData(color: c.text, size: 20),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.accent, width: 1.5)),
      errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.danger)),
      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
      labelStyle: TextStyle(color: c.textMuted, fontSize: 14),
      prefixIconColor: c.textMuted,
      suffixIconColor: c.textMuted,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: BorderSide(color: c.textMuted.withValues(alpha: 0.5), width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.border),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: menuShape,
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.25)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        minimumSize: const WidgetStatePropertyAll(Size(200, 38)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 14)),
        foregroundColor: WidgetStatePropertyAll(c.text),
        iconColor: WidgetStatePropertyAll(c.textMuted),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      todayForegroundColor: WidgetStatePropertyAll(c.accent),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(color: c.onInk, fontSize: 12),
      waitDuration: const Duration(milliseconds: 400),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.onInk),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.25),
    ),
  );
}
