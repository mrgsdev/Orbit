import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import '../l10n/strings.dart';
import 'platform.dart';

const _fast = Duration(milliseconds: 140);

// ── Основа нажимаемых элементов ──

/// Наведение, нажатие и фокус с клавиатуры — без «ряби», только цвет и
/// лёгкое уменьшение.
class Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hover, bool pressed) builder;
  final double pressScale;
  final String? hint;
  final HintSide hintSide;
  final MouseCursor? cursor;

  const Pressable({
    super.key,
    required this.onTap,
    required this.builder,
    this.pressScale = 0.97,
    this.hint,
    this.hintSide = HintSide.below,
    this.cursor,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hover = false, _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    Widget child = MouseRegion(
      cursor: widget.cursor ?? (enabled ? SystemMouseCursors.click : MouseCursor.defer),
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? widget.pressScale : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.builder(context, enabled && _hover, _pressed),
        ),
      ),
    );
    if (widget.hint != null) child = Hint(message: widget.hint!, side: widget.hintSide, child: child);
    return Semantics(button: true, enabled: enabled, label: widget.hint, child: child);
  }
}

class Hover extends StatefulWidget {
  final Widget Function(BuildContext context, bool hover) builder;
  final MouseCursor cursor;
  const Hover({super.key, required this.builder, this.cursor = MouseCursor.defer});

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: widget.cursor,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: widget.builder(context, _hover),
      );
}

/// Где показать подсказку относительно элемента.
enum HintSide { below, right }

/// Всплывающая подсказка по наведению. Всегда остаётся в пределах окна:
/// у края сдвигается, а если снизу места нет — встаёт сверху.
class Hint extends StatefulWidget {
  final String message;
  final Widget child;
  final HintSide side;
  const Hint({super.key, required this.message, required this.child, this.side = HintSide.below});

  @override
  State<Hint> createState() => _HintState();
}

class _HintState extends State<Hint> {
  final _ctrl = OverlayPortalController();
  Timer? _timer;
  Rect _anchor = Rect.zero;

  void _enter() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      final box = context.findRenderObject() as RenderBox?;
      if (!mounted || box == null || !box.attached) return;
      _anchor = box.localToGlobal(Offset.zero) & box.size;
      setState(_ctrl.show);
    });
  }

  void _exit() {
    _timer?.cancel();
    if (_ctrl.isShowing) setState(_ctrl.hide);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _ctrl,
        overlayChildBuilder: (context) => Positioned.fill(
          child: IgnorePointer(
            child: CustomSingleChildLayout(
              delegate: _HintLayout(_anchor, widget.side),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Pal.tooltip,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Pal.border),
                  boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Text(widget.message, style: T.small.copyWith(color: Pal.tooltipText)),
              ),
            ),
          ),
        ),
        child: MouseRegion(onEnter: (_) => _enter(), onExit: (_) => _exit(), child: widget.child),
      );
}

class _HintLayout extends SingleChildLayoutDelegate {
  final Rect anchor;
  final HintSide side;
  const _HintLayout(this.anchor, this.side);

  static const _gap = 8.0, _margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    double x, y;
    if (side == HintSide.right) {
      x = anchor.right + _gap;
      y = anchor.center.dy - child.height / 2;
    } else {
      x = anchor.center.dx - child.width / 2;
      y = anchor.bottom + _gap;
      if (y + child.height > size.height - _margin) y = anchor.top - _gap - child.height;
    }
    return Offset(
      x.clamp(_margin, (size.width - child.width - _margin).clamp(_margin, double.infinity)),
      y.clamp(_margin, (size.height - child.height - _margin).clamp(_margin, double.infinity)),
    );
  }

  @override
  bool shouldRelayout(_HintLayout old) => old.anchor != anchor || old.side != side;
}

// ── Кнопки ──

enum BtnKind { primary, outline, ghost, danger }

/// Кнопка: жёлтая главная, с рамкой, «призрачная» или опасная.
class Btn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final bool small;
  final bool expand;

  const Btn({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.kind = BtnKind.outline,
    this.small = false,
    this.expand = false,
  });

  const Btn.primary({super.key, required this.label, this.icon, this.onPressed, this.small = false, this.expand = false})
      : kind = BtnKind.primary,
        trailingIcon = null;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      builder: (context, hover, _) {
        final (Color bg, Color fg, Color? border) = switch (kind) {
          BtnKind.primary => (hover ? Pal.accentHover : Pal.accent, Pal.onAccent, null),
          BtnKind.outline => (hover ? Pal.hover : Pal.card, Pal.text, hover ? Pal.borderHover : Pal.border),
          BtnKind.ghost => (hover ? Pal.hover : const Color(0x00000000), Pal.text, null),
          BtnKind.danger => (hover ? Pal.dangerHover : Pal.dangerFill, Pal.red, null),
        };
        return AnimatedOpacity(
          duration: _fast,
          opacity: onPressed == null ? 0.4 : 1,
          child: AnimatedContainer(
            duration: _fast,
            height: small ? 34 : 42,
            padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(small ? 10 : 12),
              border: border == null ? null : Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: small ? 15 : 17, color: fg), const SizedBox(width: 8)],
                Text(label, style: T.body.copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: small ? 12.5 : 13.5)),
                if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 13, color: Pal.muted)],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Квадратная кнопка-иконка.
class IconBtn extends StatelessWidget {
  final IconData icon;
  final String hint;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final bool filled;
  final bool active;

  const IconBtn({
    super.key,
    required this.icon,
    required this.hint,
    this.onPressed,
    this.color,
    this.size = 36,
    this.filled = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onPressed,
        hint: hint,
        pressScale: 0.9,
        builder: (context, hover, _) => AnimatedContainer(
          duration: _fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: active ? Pal.accent : (hover ? Pal.hover : (filled ? Pal.raised : const Color(0x00000000))),
            borderRadius: BorderRadius.circular(size * 0.32),
            border: filled && !active ? Border.all(color: Pal.border) : null,
          ),
          child: Icon(
            icon,
            size: size * 0.46,
            color: active ? Pal.onAccent : (color ?? (hover ? Pal.text : Pal.muted)),
          ),
        ),
      );
}

/// Текстовая ссылка цвета акцента.
class LinkBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool underline;

  const LinkBtn({super.key, required this.label, this.icon, this.onPressed, this.color, this.underline = false});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onPressed,
        builder: (context, hover, _) {
          final color = this.color ?? Pal.accentText;
          final c = onPressed == null ? Pal.dim : (hover ? Color.lerp(color, Pal.isDark ? Pal.text : Pal.muted, 0.35)! : color);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 14, color: c), const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    label,
                    style: T.body.copyWith(
                      color: c,
                      fontWeight: FontWeight.w600,
                      decoration: underline ? TextDecoration.underline : null,
                      decorationColor: c,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

// ── Поля ввода ──

/// Тёмное поле ввода: подсвечивается жёлтой рамкой в фокусе.
class Field extends StatefulWidget {
  final TextEditingController controller;
  final String? placeholder;
  final IconData? icon;
  final Widget? suffix;
  final bool autofocus;
  final bool obscure;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool error;
  final double radius;
  final Color? fill;
  final TextStyle? style;
  final TextAlign textAlign;

  const Field({
    super.key,
    required this.controller,
    this.placeholder,
    this.icon,
    this.suffix,
    this.autofocus = false,
    this.obscure = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.error = false,
    this.radius = 12,
    this.fill,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: _fast,
      decoration: BoxDecoration(
        color: widget.fill ?? Pal.raised,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.error ? Pal.red : (focused ? Pal.accent.withValues(alpha: 0.8) : Pal.border),
        ),
      ),
      child: CupertinoTextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        obscureText: widget.obscure,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        minLines: widget.minLines,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textAlign: widget.textAlign,
        placeholder: widget.placeholder,
        placeholderStyle: T.body.copyWith(color: Pal.dim),
        style: widget.style ?? T.body,
        cursorColor: Pal.accent,
        decoration: null,
        padding: EdgeInsets.symmetric(horizontal: widget.icon == null ? 14 : 8, vertical: 11),
        prefix: widget.icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(widget.icon, size: 16, color: focused ? Pal.accentText : Pal.muted),
              ),
        suffix: widget.suffix == null ? null : Padding(padding: const EdgeInsets.only(right: 6), child: widget.suffix),
      ),
    );
  }
}

/// Подпись над полем и ошибка под ним.
class Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  final String? error;
  final Widget? trailing;

  const Labeled({super.key, required this.label, required this.child, this.error, this.trailing});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Row(
              children: [
                Expanded(child: Text(label, style: T.small)),
                ?trailing,
              ],
            ),
          ),
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 6),
              child: Text(error!, style: T.small.copyWith(color: Pal.red)),
            ),
        ],
      );
}

// ── Всплывающие окна и меню ──

/// Окно у элемента-якоря: меню, список, календарь. Закрывается кликом мимо и Esc.
class Popover extends StatefulWidget {
  final Widget Function(BuildContext context, VoidCallback toggle, bool open) anchor;
  final Widget Function(BuildContext context, VoidCallback close) content;
  final double? width;
  final double estimatedHeight;
  final bool alignRight;

  const Popover({
    super.key,
    required this.anchor,
    required this.content,
    this.width,
    this.estimatedHeight = 320,
    this.alignRight = false,
  });

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  final _ctrl = OverlayPortalController();
  final _link = LayerLink();
  final _anchorKey = GlobalKey();
  bool _above = false;
  double _anchorWidth = 0;

  void _toggle() => _ctrl.isShowing ? _close() : _open();

  void _open() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final top = box.localToGlobal(Offset.zero).dy;
      final below = MediaQuery.sizeOf(context).height - top - box.size.height;
      _above = below < widget.estimatedHeight + 16 && top > below;
      _anchorWidth = box.size.width;
    }
    setState(_ctrl.show);
  }

  void _close() {
    if (_ctrl.isShowing) setState(_ctrl.hide);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.alignRight ? 1.0 : -1.0;
    return TapRegion(
      groupId: this,
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _ctrl,
          overlayChildBuilder: (context) => Positioned(
            width: widget.width ?? _anchorWidth,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment(h, _above ? -1 : 1),
              followerAnchor: Alignment(h, _above ? 1 : -1),
              offset: Offset(0, _above ? -8 : 8),
              child: TapRegion(
                groupId: this,
                onTapOutside: (_) => _close(),
                child: CallbackShortcuts(
                  bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
                  child: FocusScope(
                    autofocus: true,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(offset: Offset(0, (1 - t) * (_above ? 6 : -6)), child: child),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Pal.popover,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Pal.border),
                          boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 30, offset: const Offset(0, 12))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.content(context, _close),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: KeyedSubtree(key: _anchorKey, child: widget.anchor(context, _toggle, _ctrl.isShowing)),
        ),
      ),
    );
  }
}

class Menu extends StatelessWidget {
  final List<Widget> children;
  final double maxHeight;
  const Menu({super.key, required this.children, this.maxHeight = 380});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(6),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      );
}

class MenuItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final Color? color;
  final VoidCallback? onTap;

  const MenuItem({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.selected = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        pressScale: 0.99,
        builder: (context, hover, _) => AnimatedContainer(
          duration: _fast,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: hover ? Pal.hover : null, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              if (icon != null) ...[Icon(icon, size: 16, color: color ?? (selected ? Pal.accentText : Pal.muted)), const SizedBox(width: 10)],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.body.copyWith(color: color ?? (onTap == null ? Pal.dim : Pal.text)),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (selected) ...[const SizedBox(width: 8), Icon(CupertinoIcons.checkmark_alt, size: 15, color: Pal.accentText)],
            ],
          ),
        ),
      );
}

class MenuDivider extends StatelessWidget {
  const MenuDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: Pal.divider);
}

/// Кнопка-список в форме «пилюли» с рамкой: ▢ 2026 ⌄
class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool open;
  final double height;

  /// Растянуть на всю доступную ширину.
  final bool expand;

  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.open = false,
    this.height = 42,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        pressScale: 0.98,
        builder: (context, hover, _) => AnimatedContainer(
          duration: _fast,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: hover || open ? Pal.hover : Pal.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: open ? Pal.accent.withValues(alpha: 0.7) : Pal.border),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: Pal.muted), const SizedBox(width: 9)],
              (expand ? Expanded.new : Flexible.new)(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body),
              ),
              const SizedBox(width: 10),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: _fast,
                child: Icon(CupertinoIcons.chevron_down, size: 12, color: Pal.muted),
              ),
            ],
          ),
        ),
      );
}

/// Выпадающий список значений.
class Dropdown<V> extends StatelessWidget {
  final V value;
  final List<(V, String)> items;
  final ValueChanged<V> onChanged;
  final IconData? icon;
  final double? width;
  final double height;
  final bool expand;

  const Dropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.width,
    this.height = 42,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final current = items.where((e) => e.$1 == value).firstOrNull?.$2 ?? '—';
    return Popover(
      width: width,
      estimatedHeight: (items.length * 38 + 12).clamp(50, 380).toDouble(),
      anchor: (context, toggle, open) =>
          Pill(label: current, icon: icon, onTap: toggle, open: open, height: height, expand: expand),
      content: (context, close) => Menu(
        children: [
          for (final (v, label) in items)
            MenuItem(
              label: label,
              selected: v == value,
              onTap: () {
                onChanged(v);
                close();
              },
            ),
        ],
      ),
    );
  }
}

// ── Переключатели ──

class Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const Toggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => onChanged(!value),
        pressScale: 0.94,
        builder: (context, hover, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 24,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? Pal.accent : (hover ? Pal.hover : Pal.raised),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: value ? Pal.accent : Pal.border),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: value ? Pal.onAccent : Pal.muted, shape: BoxShape.circle),
            ),
          ),
        ),
      );
}

class Check extends StatelessWidget {
  /// null — выбрано частично.
  final bool? value;
  final VoidCallback? onChanged;
  const Check({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final on = value != false;
    return Pressable(
      onTap: onChanged,
      pressScale: 0.88,
      builder: (context, hover, _) => Padding(
        padding: const EdgeInsets.all(5),
        child: AnimatedContainer(
          duration: _fast,
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: on ? Pal.accent : (hover ? Pal.hover : const Color(0x00000000)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: on ? Pal.accent : (hover ? Pal.muted : Pal.dim), width: 1.5),
          ),
          child: on
              ? Icon(value == null ? CupertinoIcons.minus : CupertinoIcons.checkmark_alt, size: 13, color: Pal.onAccent)
              : null,
        ),
      ),
    );
  }
}

/// Сегменты-«пилюли»: активный — жёлтый.
class Segments<V> extends StatelessWidget {
  final V value;
  final List<(V, String)> items;
  final ValueChanged<V> onChanged;
  const Segments({super.key, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Pal.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Pal.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (v, label) in items)
              Pressable(
                onTap: () => onChanged(v),
                builder: (context, hover, _) {
                  final active = v == value;
                  return AnimatedContainer(
                    duration: _fast,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? Pal.accent : (hover ? Pal.hover : null),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: T.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: active ? Pal.onAccent : (hover ? Pal.text : Pal.muted),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
}

// ── Карточки и метки ──

/// Тёмная панель со скруглением, как блоки на дашборде.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(26),
    this.radius = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Pal.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Pal.cardBorder),
        ),
        child: child,
      );
}

/// Заголовок блока с действиями справа.
class PanelHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const PanelHeader(this.title, {super.key, this.actions = const []});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: T.title)),
          for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 10), actions[i]],
        ],
      );
}

class Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool small;
  final VoidCallback? onRemove;

  const Tag(this.label, {super.key, this.color, this.small = false, this.onRemove});

  factory Tag.interest(String label, {bool small = false, VoidCallback? onRemove}) =>
      Tag(label, color: TagColors.hue(label), small: small, onRemove: onRemove);

  @override
  Widget build(BuildContext context) {
    final tint = this.color ?? Pal.muted;
    // На белом яркий цвет текста темнее, иначе не читается.
    final color = Pal.isDark ? tint : Color.lerp(tint, Pal.text, 0.5)!;
    return Container(
        padding: EdgeInsets.fromLTRB(small ? 8 : 10, small ? 3 : 4, onRemove == null ? (small ? 8 : 10) : 4, small ? 3 : 4),
        decoration: BoxDecoration(color: tint.withValues(alpha: Pal.isDark ? 0.16 : 0.2), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.small.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: small ? 11 : 12),
              ),
            ),
            if (onRemove != null)
              Pressable(
                onTap: onRemove,
                builder: (context, hover, _) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: color.withValues(alpha: hover ? 1 : 0.6)),
                ),
              ),
          ],
        ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? image;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({super.key, this.icon, this.image, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                image ??
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: Pal.raised, borderRadius: BorderRadius.circular(20)),
                      child: Icon(icon, size: 28, color: Pal.accentText),
                    ),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center, style: T.title),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: T.body.copyWith(color: Pal.muted, height: 1.45)),
                if (action != null) ...[const SizedBox(height: 18), action!],
              ],
            ),
          ),
        ),
      );
}

/// Не даёт содержимому сжаться меньше [minWidth]×[minHeight]: если окно
/// на мгновение стало меньше (например, его резко тянут), появляется
/// прокрутка вместо полос переполнения.
class MinSize extends StatelessWidget {
  final double minWidth;
  final double minHeight;
  final Widget child;

  const MinSize({super.key, required this.minWidth, required this.minHeight, required this.child});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= minWidth && c.maxHeight >= minHeight) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: c.maxWidth < minWidth ? minWidth : c.maxWidth,
              height: c.maxHeight < minHeight ? minHeight : c.maxHeight,
              child: child,
            ),
          ),
        );
      });
}

/// Прокрутка со своей тонкой полосой.
class ScrollArea extends StatefulWidget {
  final Widget Function(ScrollController controller) builder;
  const ScrollArea({super.key, required this.builder});

  @override
  State<ScrollArea> createState() => _ScrollAreaState();
}

class _ScrollAreaState extends State<ScrollArea> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawScrollbar(
        controller: _controller,
        thumbColor: Pal.thumb,
        radius: const Radius.circular(8),
        thickness: 6,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: widget.builder(_controller),
        ),
      );
}

// ── Модальные окна ──

/// Окно по центру поверх размытого фона.
Future<R?> showModal<R>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) =>
    showGeneralDialog<R>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: tr.close,
      barrierColor: const Color(0x00000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, animation, _) => Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: animation,
              child: GestureDetector(
                onTap: dismissible ? () => Navigator.of(ctx).maybePop() : null,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ColoredBox(color: Pal.scrim),
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ],
      ),
    );

/// Каркас модального окна: заголовок, прокручиваемое тело, кнопки снизу.
/// Esc — отмена, ⌘S и ⌘↩ — основное действие.
class ModalScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> leadingActions;
  final List<Widget> actions;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;
  final double width;
  final double maxHeight;

  const ModalScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.leadingActions = const [],
    required this.actions,
    required this.onCancel,
    this.onSubmit,
    this.width = 560,
    this.maxHeight = 820,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): onCancel,
        Os.primary(LogicalKeyboardKey.enter): ?onSubmit,
        Os.primary(LogicalKeyboardKey.keyS): ?onSubmit,
      },
      child: FocusScope(
        autofocus: true,
        child: Container(
          width: width,
          constraints: BoxConstraints(maxHeight: (size.height - 64).clamp(200, maxHeight)),
          decoration: BoxDecoration(
            color: Pal.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Pal.border),
            boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 60, offset: const Offset(0, 24))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 18, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: T.title.copyWith(fontSize: 20)),
                          if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: T.small)],
                        ],
                      ),
                    ),
                    IconBtn(icon: CupertinoIcons.xmark, hint: tr.closeEsc, onPressed: onCancel, size: 34),
                  ],
                ),
              ),
              Flexible(
                child: ScrollArea(
                  builder: (controller) => ListView(
                    controller: controller,
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    children: children,
                  ),
                ),
              ),
              Container(height: 1, color: Pal.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
                child: Row(
                  children: [
                    ...leadingActions,
                    const Spacer(),
                    for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 10), actions[i]],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showModal<bool>(
    context,
    builder: (ctx) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () => Navigator.of(ctx).pop(true),
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(ctx).pop(false),
      },
      child: Focus(
        autofocus: true,
        child: Container(
          width: 420,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
          decoration: BoxDecoration(
            color: Pal.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Pal.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (destructive ? Pal.red : Pal.accent).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  destructive ? CupertinoIcons.trash : CupertinoIcons.sparkles,
                  size: 22,
                  color: destructive ? Pal.red : Pal.accentText,
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: T.title),
              const SizedBox(height: 8),
              Text(message, style: T.body.copyWith(color: Pal.muted, height: 1.45)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Btn(label: tr.cancel, expand: true, onPressed: () => Navigator.of(ctx).pop(false))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Btn(
                      label: confirmLabel,
                      expand: true,
                      kind: destructive ? BtnKind.danger : BtnKind.primary,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok == true;
}

// ── Уведомления внизу окна ──

final _toastKey = GlobalKey<_ToastLayerState>();

class ToastHost extends StatelessWidget {
  final Widget child;
  const ToastHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) => _ToastLayer(key: _toastKey, child: child);
}

class _ToastLayer extends StatefulWidget {
  final Widget child;
  const _ToastLayer({super.key, required this.child});

  @override
  State<_ToastLayer> createState() => _ToastLayerState();
}

class _Toast {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _Toast(this.text, [this.actionLabel, this.onAction]);
}

class _ToastLayerState extends State<_ToastLayer> {
  _Toast? _toast;
  Timer? _timer;
  int _generation = 0;

  void show(_Toast toast, Duration duration) {
    _timer?.cancel();
    setState(() {
      _toast = toast;
      _generation++;
    });
    _timer = Timer(duration, hide);
  }

  void hide() {
    _timer?.cancel();
    if (mounted && _toast != null) setState(() => _toast = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toast = _toast;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a), child: child),
              ),
              child: toast == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_generation),
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: EdgeInsets.fromLTRB(18, 12, toast.actionLabel == null ? 18 : 8, 12),
                      decoration: BoxDecoration(
                        color: Pal.toast,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Pal.border),
                        boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.checkmark_circle_fill, size: 17, color: Pal.accentText),
                          const SizedBox(width: 10),
                          Flexible(child: Text(toast.text, style: T.body)),
                          if (toast.actionLabel != null) ...[
                            const SizedBox(width: 12),
                            Btn(
                              label: toast.actionLabel!,
                              small: true,
                              kind: BtnKind.primary,
                              onPressed: () {
                                hide();
                                toast.onAction?.call();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

void showToast(String text) => _toastKey.currentState?.show(_Toast(text), const Duration(seconds: 3));

/// Уведомление с кнопкой «Отменить».
void showUndoToast(String text, {required VoidCallback onUndo}) =>
    _toastKey.currentState?.show(_Toast(text, tr.undo, onUndo), const Duration(seconds: 6));

void hideToast() => _toastKey.currentState?.hide();

