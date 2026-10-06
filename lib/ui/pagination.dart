import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'widgets.dart';

class PaginationBar extends StatefulWidget {
  final int page; // с нуля
  final int pageCount;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  const PaginationBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.total,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  State<PaginationBar> createState() => _PaginationBarState();
}

class _PaginationBarState extends State<PaginationBar> {
  final _goTo = TextEditingController();

  @override
  void dispose() {
    _goTo.dispose();
    super.dispose();
  }

  void _go() {
    final n = int.tryParse(_goTo.text);
    if (n == null) return;
    widget.onPage((n - 1).clamp(0, widget.pageCount - 1));
    _goTo.clear();
  }

  /// Номера страниц с многоточиями: 1 … 4 5 6 … 20 (null — многоточие).
  List<int?> _pages() {
    final last = widget.pageCount - 1, cur = widget.page;
    final keep = <int>{0, last, cur - 1, cur, cur + 1}
        .where((p) => p >= 0 && p <= last)
        .toList()
      ..sort();
    final out = <int?>[];
    int? prev;
    for (final p in keep) {
      if (prev != null && p - prev > 1) {
        // Пропуск ровно одной страницы проще показать числом, чем «…».
        out.add(p - prev == 2 ? p - 1 : null);
      }
      out.add(p);
      prev = p;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = TextStyle(fontSize: 13, color: c.textMuted);
    final from = widget.total == 0 ? 0 : widget.page * widget.pageSize + 1;
    final to = ((widget.page + 1) * widget.pageSize).clamp(0, widget.total);
    final canBack = widget.page > 0;
    final canFwd = widget.page < widget.pageCount - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('Показывать по', style: muted),
          const SizedBox(width: 10),
          MenuAnchor(
            builder: (context, ctrl, _) => _Box(
              onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
              width: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.pageSize}',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  Icon(Icons.expand_more, size: 16, color: c.textMuted),
                ],
              ),
            ),
            menuChildren: [
              for (final n in const [10, 20, 50, 100])
                MenuItemButton(
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(90, 36))),
                  onPressed: () => widget.onPageSize(n),
                  child: Text('$n'),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Text('$from–$to из ${widget.total}', style: muted),
          const Spacer(),
          _Box(
            enabled: canBack,
            onTap: () => widget.onPage(0),
            child: const Icon(Icons.keyboard_double_arrow_left, size: 16),
          ),
          const SizedBox(width: 6),
          _Box(
            enabled: canBack,
            onTap: () => widget.onPage(widget.page - 1),
            child: const Icon(Icons.chevron_left, size: 18),
          ),
          for (final p in _pages()) ...[
            const SizedBox(width: 6),
            if (p == null)
              SizedBox(width: 24, child: Center(child: Text('…', style: muted)))
            else
              _Box(
                active: p == widget.page,
                onTap: () => widget.onPage(p),
                child: Text('${p + 1}'),
              ),
          ],
          const SizedBox(width: 6),
          _Box(
            enabled: canFwd,
            onTap: () => widget.onPage(widget.page + 1),
            child: const Icon(Icons.chevron_right, size: 18),
          ),
          const SizedBox(width: 6),
          _Box(
            enabled: canFwd,
            onTap: () => widget.onPage(widget.pageCount - 1),
            child: const Icon(Icons.keyboard_double_arrow_right, size: 16),
          ),
          const Spacer(),
          Text('Перейти к странице', style: muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            height: 34,
            child: TextField(
              controller: _goTo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _go(),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _go,
            style: TextButton.styleFrom(
              foregroundColor: c.text,
              textStyle: buttonTextStyle(context),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Перейти'), Icon(Icons.chevron_right, size: 18)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;
  final double width;

  const _Box({
    required this.child,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.width = 34,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = active ? Colors.white : (enabled ? c.text : c.textMuted.withValues(alpha: 0.5));
    return Material(
      color: active ? c.accent : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: active ? c.accent : c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled && !active ? onTap : null,
        child: SizedBox(
          width: width,
          height: 34,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width > 34 ? 10 : 0),
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: fg),
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
