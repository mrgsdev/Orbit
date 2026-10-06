import 'package:flutter/material.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import 'theme.dart';
import 'widgets.dart';

enum Segment {
  all('Все контакты', Icons.people_alt_outlined),
  favorites('Избранные', Icons.star_outline_rounded),
  recent('Новые за месяц', Icons.auto_awesome_outlined),
  birthdays('Дни рождения', Icons.cake_outlined);

  final String label;
  final IconData icon;
  const Segment(this.label, this.icon);

  bool test(Contact c, DateTime now) => switch (this) {
        Segment.all => true,
        Segment.favorites => c.favorite,
        Segment.recent => now.difference(c.createdAt).inDays < 30,
        Segment.birthdays => (c.daysUntilBirthday(now) ?? 999) <= 30,
      };
}

class Sidebar extends StatefulWidget {
  final ContactStore store;
  final Segment segment;
  final ValueChanged<Segment> onSegment;
  final Set<String> interests;
  final ValueChanged<String> onToggleInterest;
  final TextEditingController search;
  final FocusNode searchFocus;
  final VoidCallback onExport;
  final VoidCallback onEditFields;

  const Sidebar({
    super.key,
    required this.store,
    required this.segment,
    required this.onSegment,
    required this.interests,
    required this.onToggleInterest,
    required this.search,
    required this.searchFocus,
    required this.onExport,
    required this.onEditFields,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _interestsOpen = true;
  bool _showAllInterests = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final contacts = widget.store.contacts;
    final interestCounts = widget.store.interestCounts;
    final shownInterests =
        _showAllInterests ? interestCounts : interestCounts.take(7).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _brand(c, contacts.length),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _searchField(c),
          ),
          Expanded(
            // Горизонтальный отступ внутри списка, а не снаружи: иначе
            // метка активного пункта у края окна обрезалась бы.
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              children: [
                const SectionLabel('Меню', padding: EdgeInsets.fromLTRB(12, 0, 0, 8)),
                for (final s in Segment.values)
                  _NavItem(
                    icon: s.icon,
                    label: s.label,
                    count: contacts.where((x) => s.test(x, now)).length,
                    selected: widget.segment == s,
                    onTap: () => widget.onSegment(s),
                  ),
                const SizedBox(height: 12),
                Divider(color: c.border, indent: 8, endIndent: 8),
                const SizedBox(height: 12),
                const SectionLabel('Настройка', padding: EdgeInsets.fromLTRB(12, 0, 0, 8)),
                _NavItem(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'Поля и разделы',
                  count: widget.store.allFields.length,
                  selected: false,
                  onTap: widget.onEditFields,
                ),
                const SizedBox(height: 12),
                Divider(color: c.border, indent: 8, endIndent: 8),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _interestsOpen = !_interestsOpen),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: _interestsOpen ? 0 : -0.25,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(Icons.expand_more, size: 16, color: c.textMuted),
                        ),
                        const SizedBox(width: 6),
                        const SectionLabel('Интересы'),
                      ],
                    ),
                  ),
                ),
                if (_interestsOpen) ...[
                  if (interestCounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: Text(
                        'Появятся, когда добавите интересы контактам',
                        style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.4),
                      ),
                    ),
                  for (final e in shownInterests)
                    _NavItem(
                      dot: TagColors.hue(e.key),
                      label: e.key,
                      count: e.value,
                      selected: widget.interests.contains(e.key),
                      onTap: () => widget.onToggleInterest(e.key),
                    ),
                  if (interestCounts.length > 7)
                    TextButton(
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        foregroundColor: c.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () =>
                          setState(() => _showAllInterests = !_showAllInterests),
                      child: Text(_showAllInterests
                          ? 'Свернуть'
                          : 'Ещё ${interestCounts.length - 7}'),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _exportCard(c),
          ),
        ],
      ),
    );
  }

  Widget _brand(AppColors c, int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(c),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 40,
              height: 40,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Orbit',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '$total ${plural(total, 'человек', 'человека', 'человек')} в базе',
                  style: TextStyle(fontSize: 12.5, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(AppColors c) {
    return ListenableBuilder(
      listenable: widget.search,
      builder: (context, _) => TextField(
        controller: widget.search,
        focusNode: widget.searchFocus,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Поиск',
          fillColor: c.surfaceMuted,
          prefixIcon: const Icon(Icons.search, size: 19),
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.surfaceMuted),
          ),
          suffixIcon: widget.search.text.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [_Kbd('⌘'), const SizedBox(width: 3), _Kbd('K')],
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: widget.search.clear,
                ),
        ),
      ),
    );
  }

  Widget _exportCard(AppColors c) {
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onExport,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Экспорт базы\nв CSV-таблицу',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),
              Icon(Icons.chevron_right, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kbd extends StatelessWidget {
  final String text;
  const _Kbd(this.text);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.border),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: c.textMuted)),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final Color? dot;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    this.icon,
    this.dot,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? c.border : Colors.transparent),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      if (icon != null)
                        Icon(icon, size: 19, color: selected ? c.text : c.textMuted)
                      else
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: dot,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? c.text : c.text.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: selected ? c.accentSoft : c.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: selected ? c.accentSoft : c.border),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: selected ? c.accent : c.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Оранжевая метка активного пункта у левого края, как в макете.
          if (selected && icon != null)
            Positioned(
              left: -12,
              top: 10,
              bottom: 10,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
