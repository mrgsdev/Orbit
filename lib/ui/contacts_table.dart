import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import '../models/field_schema.dart';
import 'avatar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Колонка: ширина либо фиксированная, либо доля свободного места.
/// [field] задан у колонок из пользовательских полей.
class _Col {
  final String title;
  final double? fixed;
  final int flex;
  final CustomField? field;
  const _Col(this.title, {this.fixed, this.flex = 0, this.field});
}

const _baseMinWidth = 1040.0;
const _customColWidth = 160.0;
const _rowHeight = 62.0;

List<_Col> _columns(List<CustomField> extra) => [
      const _Col('', fixed: 52),
      const _Col('Контакт', flex: 30),
      const _Col('Телефон', flex: 18),
      const _Col('Должность', flex: 22),
      const _Col('Где познакомились', flex: 22),
      const _Col('Интересы', flex: 26),
      for (final f in extra) _Col(f.label, flex: 18, field: f),
      const _Col('Добавлен', flex: 13),
      const _Col('', fixed: 56),
    ];

class ContactsTable extends StatefulWidget {
  final List<Contact> contacts;
  final ContactStore store;
  final Set<String> selected;
  final ValueChanged<Contact> onOpen;
  final ValueChanged<String> onToggle;
  final ValueChanged<bool> onToggleAll;
  final VoidCallback onAddColumn;
  final ValueChanged<CustomField> onEditColumn;

  const ContactsTable({
    super.key,
    required this.contacts,
    required this.store,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
    required this.onToggleAll,
    required this.onAddColumn,
    required this.onEditColumn,
  });

  @override
  State<ContactsTable> createState() => _ContactsTableState();
}

class _ContactsTableState extends State<ContactsTable> {
  // Свой контроллер: полоса прокрутки с thumbVisibility требует ровно одну
  // позицию, а PrimaryScrollController достался бы и вертикальному списку.
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ContactsTable(
      :contacts, :store, :selected, :onOpen, :onToggle, :onToggleAll,
      :onAddColumn, :onEditColumn,
    ) = widget;
    final extra = store.tableFields;
    final cols = _columns(extra);
    final pageSelected = contacts.where((c) => selected.contains(c.id)).length;
    final allState = pageSelected == 0
        ? false
        : pageSelected == contacts.length
            ? true
            : null;

    return LayoutBuilder(builder: (context, constraints) {
      final minWidth = _baseMinWidth + extra.length * _customColWidth;
      final width = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;
      return Scrollbar(
        controller: _horizontal,
        thumbVisibility: width > constraints.maxWidth,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _HeaderRow(
                  cols: cols,
                  allState: allState,
                  onToggleAll: () => onToggleAll(allState != true),
                  onAddColumn: onAddColumn,
                  onEditColumn: onEditColumn,
                ),
                Expanded(
                  child: ListView.builder(
                    primary: false,
                    itemCount: contacts.length,
                    itemExtent: _rowHeight,
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      return _Row(
                        cols: cols,
                        contact: c,
                        store: store,
                        selected: selected.contains(c.id),
                        onOpen: () => onOpen(c),
                        onToggle: () => onToggle(c.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

Widget _cells(List<_Col> cols, List<Widget> children) {
  assert(children.length == cols.length);
  return Row(
    children: [
      for (var i = 0; i < cols.length; i++)
        cols[i].fixed != null
            ? SizedBox(width: cols[i].fixed, child: children[i])
            : Expanded(
                flex: cols[i].flex,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: children[i],
                ),
              ),
    ],
  );
}

class _HeaderRow extends StatelessWidget {
  final List<_Col> cols;
  final bool? allState;
  final VoidCallback onToggleAll;
  final VoidCallback onAddColumn;
  final ValueChanged<CustomField> onEditColumn;

  const _HeaderRow({
    required this.cols,
    required this.allState,
    required this.onToggleAll,
    required this.onAddColumn,
    required this.onEditColumn,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textMuted);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: _cells(cols, [
        Center(
          child: Checkbox(value: allState, tristate: true, onChanged: (_) => onToggleAll()),
        ),
        for (final col in cols.skip(1).take(cols.length - 2))
          if (col.field case final f?)
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: 'Настроить колонку',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onEditColumn(f),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconFor(f.icon), size: 14, color: c.textMuted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(col.title, style: style, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Text(col.title, style: style, overflow: TextOverflow.ellipsis),
        Center(
          child: IconButton(
            tooltip: 'Добавить колонку',
            icon: Icon(Icons.add_rounded, size: 19, color: c.textMuted),
            onPressed: onAddColumn,
          ),
        ),
      ]),
    );
  }
}

class _Row extends StatefulWidget {
  final List<_Col> cols;
  final Contact contact;
  final ContactStore store;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const _Row({
    required this.cols,
    required this.contact,
    required this.store,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final x = widget.contact;
    final muted = TextStyle(fontSize: 12.5, color: c.textMuted);
    const main = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final dash = Text('—', style: muted);
    final date = DateFormat('d MMM y', 'ru');

    Widget twoLines(String top, String bottom) {
      if (top.isEmpty && bottom.isEmpty) return dash;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (top.isNotEmpty)
            Text(top, style: main, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (bottom.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(bottom, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      );
    }

    Widget customCell(CustomField f) {
      final raw = x.custom[f.id];
      final value = f.format(raw);
      if (value == null) return dash;
      return Align(
        alignment: Alignment.centerLeft,
        child: switch (f.type) {
          FieldType.checkbox => Icon(
              raw == true ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
              size: 18,
              color: raw == true ? c.success : c.textMuted,
            ),
          FieldType.select => Tag.interest(context, value),
          FieldType.date => Text(date.format(DateTime.parse('$raw')), style: muted),
          _ => Text(value, style: main, maxLines: 1, overflow: TextOverflow.ellipsis),
        },
      );
    }

    final bg = widget.selected
        ? c.accentSoft
        : _hover
            ? c.surfaceMuted
            : c.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(color: c.border),
              left: BorderSide(
                color: widget.selected ? c.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: _cells(widget.cols, [
            Center(
              child: Checkbox(value: widget.selected, onChanged: (_) => widget.onToggle()),
            ),
            Row(
              children: [
                ContactAvatar(name: x.name, photo: widget.store.photoOf(x), radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: twoLines(
                    x.name,
                    x.telegramHandle.isNotEmpty ? '@${x.telegramHandle}' : x.email,
                  ),
                ),
              ],
            ),
            x.phone.isEmpty
                ? dash
                : Text(x.phone,
                    style: main.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            twoLines(x.position, x.company),
            twoLines(x.whereMet, x.metDate == null ? '' : date.format(x.metDate!)),
            _InterestTags(x.interests),
            for (final col in widget.cols)
              if (col.field case final f?) customCell(f),
            Text(date.format(x.createdAt), style: muted),
            Center(
              child: IconButton(
                tooltip: x.favorite ? 'Убрать из избранного' : 'В избранное',
                onPressed: () => widget.store.toggleFavorite(x),
                icon: Icon(
                  x.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: x.favorite
                      ? c.star
                      : c.textMuted.withValues(alpha: _hover ? 1 : 0.4),
                  size: 21,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InterestTags extends StatelessWidget {
  final List<String> interests;
  const _InterestTags(this.interests);

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) {
      return Text('—', style: TextStyle(fontSize: 12.5, color: context.colors.textMuted));
    }
    final rest = interests.length - 2;
    return Row(
      children: [
        for (final i in interests.take(2)) ...[
          Flexible(child: Tag.interest(context, i)),
          const SizedBox(width: 6),
        ],
        if (rest > 0) Tag('+$rest'),
      ],
    );
  }
}
