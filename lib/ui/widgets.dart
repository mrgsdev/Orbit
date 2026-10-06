import 'package:flutter/material.dart';

import 'theme.dart';

/// Стиль подписи кнопок. Берём шрифт темы: свой textStyle у кнопки
/// полностью заменяет стандартный, и семейство шрифта иначе теряется.
TextStyle buttonTextStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .labelLarge!
    .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600);

BoxDecoration cardDecoration(AppColors c, {double radius = 14}) => BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: c.border),
    );

/// Кнопка панели инструментов: белая с рамкой либо чёрная главная.
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;
  final Widget? badge;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.primary = false,
    this.danger = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = primary ? c.onInk : (danger ? c.danger : c.text);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: primary ? c.ink : c.surface,
        foregroundColor: fg,
        disabledForegroundColor: c.textMuted,
        side: primary ? null : BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        minimumSize: const Size(0, 40),
        textStyle: buttonTextStyle(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 8)],
          Text(label),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, size: 16, color: c.textMuted),
          ],
        ],
      ),
    );
  }
}

/// Квадратная кнопка-иконка с рамкой, как в шапке.
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: c.surface,
            foregroundColor: color ?? c.text,
            side: BorderSide(color: c.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Icon(icon, size: 18, color: color ?? c.text),
        ),
      ),
    );
  }
}

/// Цветная плашка — интерес, статус или счётчик.
class Tag extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;
  final double fontSize;

  const Tag(
    this.label, {
    super.key,
    this.background,
    this.foreground,
    this.icon,
    this.fontSize = 12,
  });

  factory Tag.interest(BuildContext context, String label) {
    final (bg, fg) = TagColors.of(label, Theme.of(context).brightness);
    return Tag(label, background: bg, foreground: fg);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = foreground ?? c.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? c.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: fontSize + 1, color: fg), const SizedBox(width: 3)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: fg,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;

  const SectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: context.colors.textMuted,
          ),
        ),
      );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final c = context.colors;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 360,
        child: Text(message, style: TextStyle(color: c.textMuted, height: 1.4)),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        AppButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx, false)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            backgroundColor: destructive ? c.danger : c.ink,
            foregroundColor: destructive ? Colors.white : c.onInk,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 40),
            textStyle: buttonTextStyle(ctx),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      width: 320,
      duration: const Duration(seconds: 2),
    ));
}

/// Склонение по числу: plural(5, 'контакт', 'контакта', 'контактов').
String plural(int n, String one, String few, String many) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}
