import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String monthTitle(DateTime m) {
  final s = DateFormat('LLLL y', tr.locale).format(m);
  return s[0].toUpperCase() + s.substring(1);
}

/// Месяц сеткой: выбранный день — жёлтый, сегодня — в рамке.
class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  const MonthGrid({super.key, required this.month, this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lead = (DateTime(month.year, month.month, 1).weekday + 6) % 7;
    final start = DateTime(month.year, month.month, 1 - lead);
    // Только недели этого месяца: четыре, пять или шесть строк.
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weeks = ((lead + daysInMonth) / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            for (final w in tr.weekdaysShort)
              Expanded(child: Center(child: Text(w, style: T.tiny.copyWith(color: Pal.dim)))),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < weeks; row++)
          _week(DateTime(start.year, start.month, start.day + row * 7), now),
      ],
    );
  }

  Widget _week(DateTime first, DateTime now) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(child: _day(DateTime(first.year, first.month, first.day + i), now)),
            ],
          ),
        ),
      );

  Widget _day(DateTime d, DateTime now) {
    final inMonth = d.month == month.month;
    final isSelected = selected != null && sameDay(d, selected!);
    final isToday = sameDay(d, now);
    return Pressable(
      onTap: () => onPick(d),
      pressScale: 0.9,
      builder: (context, hover, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Pal.accent : (hover ? Pal.hover : null),
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected ? Border.all(color: Pal.accent) : null,
        ),
        child: Text(
          '${d.day}',
          style: T.body.copyWith(
            fontSize: 13,
            color: isSelected ? Pal.onAccent : (inMonth ? Pal.text : Pal.dim.withValues(alpha: 0.6)),
            fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Выбор даты во всплывающем календаре с быстрым переходом по годам.
class DateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? placeholder;

  const DateField({super.key, required this.value, required this.onChanged, this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Popover(
      width: 320,
      estimatedHeight: 380,
      anchor: (context, toggle, open) => Pressable(
        onTap: toggle,
        pressScale: 1,
        builder: (context, hover, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            color: hover ? Pal.hover : Pal.raised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: open ? Pal.accent.withValues(alpha: 0.8) : Pal.border),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.calendar, size: 16, color: open ? Pal.accentText : Pal.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value == null ? (placeholder ?? tr.dateNotSet) : DateFormat('d MMMM y', tr.locale).format(value!),
                  style: T.body.copyWith(color: value == null ? Pal.dim : Pal.text),
                ),
              ),
              if (value != null) IconBtn(icon: CupertinoIcons.xmark, hint: tr.clear, size: 30, onPressed: () => onChanged(null)),
            ],
          ),
        ),
      ),
      content: (context, close) => _CalendarPicker(
        value: value,
        onPick: (d) {
          onChanged(d);
          close();
        },
      ),
    );
  }
}

class _CalendarPicker extends StatefulWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  const _CalendarPicker({required this.value, required this.onPick});

  @override
  State<_CalendarPicker> createState() => _CalendarPickerState();
}

class _CalendarPickerState extends State<_CalendarPicker> {
  late DateTime _month = DateTime((widget.value ?? DateTime.now()).year, (widget.value ?? DateTime.now()).month);
  bool _years = false;

  @override
  Widget build(BuildContext context) {
    final lastYear = DateTime.now().year + 10;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Pressable(
                onTap: () => setState(() => _years = !_years),
                builder: (context, hover, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(monthTitle(_month), style: T.heading.copyWith(color: hover ? Pal.accentText : Pal.text)),
                    const SizedBox(width: 6),
                    Icon(_years ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 12, color: Pal.muted),
                  ],
                ),
              ),
              const Spacer(),
              if (!_years) ...[
                IconBtn(
                  icon: CupertinoIcons.chevron_left,
                  hint: tr.prevMonth,
                  size: 30,
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                ),
                IconBtn(
                  icon: CupertinoIcons.chevron_right,
                  hint: tr.nextMonth,
                  size: 30,
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_years)
            SizedBox(height: 248, child: _yearGrid(lastYear))
          else
            MonthGrid(month: _month, selected: widget.value, onPick: widget.onPick),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: LinkBtn(
              label: tr.today,
              onPressed: () {
                final n = DateTime.now();
                widget.onPick(DateTime(n.year, n.month, n.day));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearGrid(int lastYear) {
    final years = [for (var y = lastYear; y >= 1900; y--) y];
    final index = years.indexOf(_month.year).clamp(0, years.length - 1);
    return GridView.builder(
      controller: ScrollController(initialScrollOffset: ((index ~/ 4) * 42.0 - 90).clamp(0, double.infinity)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 38,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: years.length,
      itemBuilder: (context, i) {
        final y = years[i];
        final active = y == _month.year;
        return Pressable(
          onTap: () => setState(() {
            _month = DateTime(y, _month.month);
            _years = false;
          }),
          builder: (context, hover, _) => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Pal.accent : (hover ? Pal.hover : null),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$y', style: T.body.copyWith(color: active ? Pal.onAccent : Pal.text)),
          ),
        );
      },
    );
  }
}
