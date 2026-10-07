import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/contact_store.dart';
import '../models/contact.dart';
import '../models/field_schema.dart';
import 'avatar.dart';
import 'field_editors.dart';
import 'home_page.dart' show SortMode;
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

/// Колонка: доля ширины, сортировка по клику на заголовок.
class _Col {
  final String key;
  final int flex;
  final double? fixed;
  final CustomField? field;
  final (SortMode, SortMode)? sorts;
  const _Col(this.key, {this.flex = 0, this.fixed, this.field, this.sorts});

  /// Заголовок в языке интерфейса; у служебных столбцов — пусто.
  String get title => field?.label ?? (const {'check', 'favorite', 'add'}.contains(key) ? '' : tr.columnTitle(key));
}

/// Встроенные столбцы, которые можно скрыть. Имя и дата добавления — всегда.
const hideableColumns = ['phone', 'work', 'met', 'interests', 'birthday', 'favorite'];

/// Ширина столбцов с датой: дд.мм.гггг целиком плюс отступ.
const _dateWidth = 116.0;

const _rowHeight = 58.0;
// Ниже этой ширины таблица прокручивается вбок, чтобы имя не обрезалось.
const _minWidth = 1040.0;
const _customWidth = 140.0;

/// Встроенные столбцы между «Имя» и служебными, в порядке по умолчанию.
const _builtin = [
  _Col('phone', flex: 20),
  _Col('work', flex: 22),
  _Col('met', flex: 20, sorts: (SortMode.metRecent, SortMode.metRecent)),
  _Col('interests', flex: 22),
  _Col('birthday', fixed: _dateWidth + 10),
  _Col('created', fixed: _dateWidth, sorts: (SortMode.newest, SortMode.oldest)),
  _Col('favorite', fixed: 40),
];

String _fieldKey(CustomField f) => 'field:${f.id}';

/// Порядок переставляемых столбцов: как расставил пользователь, а новые
/// (например, только что созданное поле) встают на своё место по умолчанию.
List<String> orderedColumnKeys(ContactStore store) {
  final defaults = [
    for (final c in _builtin.take(4)) c.key,
    for (final f in store.allFields) _fieldKey(f),
    for (final c in _builtin.skip(4)) c.key,
  ];
  final order = store.columnOrder.where(defaults.contains).toList();
  for (var i = 0; i < defaults.length; i++) {
    if (order.contains(defaults[i])) continue;
    var at = 0;
    for (var j = i - 1; j >= 0; j--) {
      final prev = order.indexOf(defaults[j]);
      if (prev >= 0) {
        at = prev + 1;
        break;
      }
    }
    order.insert(at, defaults[i]);
  }
  return order;
}

List<_Col> _columns(ContactStore store) {
  final hidden = store.hiddenColumns;
  final byKey = {
    for (final c in _builtin) c.key: c,
    for (final f in store.tableFields) _fieldKey(f): _Col(_fieldKey(f), flex: 16, field: f),
  };
  return [
    const _Col('check', fixed: 40),
    const _Col('name', flex: 32, sorts: (SortMode.nameAsc, SortMode.nameDesc)),
    for (final key in orderedColumnKeys(store))
      if (byKey[key] case final col? when !hidden.contains(key)) col,
    const _Col('add', fixed: 40),
  ];
}

class ContactsTable extends StatefulWidget {
  final List<Contact> contacts;
  final ContactStore store;
  final Set<String> selected;

  /// null — порядок задан разделом (дни рождения, корзина).
  final SortMode? sort;
  final ValueChanged<SortMode> onSort;
  final ValueChanged<Contact> onTap;
  final ValueChanged<Contact> onToggle;
  final ValueChanged<bool> onToggleAll;
  final VoidCallback onAddColumn;
  final ValueChanged<CustomField> onEditColumn;

  const ContactsTable({
    super.key,
    required this.contacts,
    required this.store,
    required this.selected,
    required this.sort,
    required this.onSort,
    required this.onTap,
    required this.onToggle,
    required this.onToggleAll,
    required this.onAddColumn,
    required this.onEditColumn,
  });

  @override
  State<ContactsTable> createState() => _ContactsTableState();
}

class _ContactsTableState extends State<ContactsTable> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = widget.store.tableFields;
    final hiddenCount = widget.store.hiddenColumns.length;
    final cols = _columns(widget.store);
    final picked = widget.contacts.where((c) => widget.selected.contains(c.id)).length;
    final allState = picked == 0 ? false : (picked == widget.contacts.length ? true : null);
    return LayoutBuilder(builder: (context, constraints) {
      final min = _minWidth - hiddenCount * 110 + extra.length * _customWidth;
      final width = constraints.maxWidth < min ? min : constraints.maxWidth;
      return RawScrollbar(
        controller: _horizontal,
        thumbColor: Pal.thumb,
        radius: const Radius.circular(8),
        thickness: 6,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _Header(
                  cols: cols,
                  sort: widget.sort,
                  allState: allState,
                  onToggleAll: () => widget.onToggleAll(allState != true),
                  onSort: widget.onSort,
                  onAddColumn: widget.onAddColumn,
                  onEditColumn: widget.onEditColumn,
                ),
                Expanded(
                  child: ScrollArea(
                    builder: (controller) => ListView.builder(
                      controller: controller,
                      itemExtent: _rowHeight,
                      itemCount: widget.contacts.length,
                      itemBuilder: (context, i) {
                        final c = widget.contacts[i];
                        return _Row(
                          key: ValueKey(c.id),
                          cols: cols,
                          contact: c,
                          store: widget.store,
                          selected: widget.selected.contains(c.id),
                          onTap: () => widget.onTap(c),
                          onToggle: () => widget.onToggle(c),
                        );
                      },
                    ),
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

/// Служебные столбцы без текста — без правого отступа.
const _bare = {'check', 'favorite', 'add'};

Widget _cells(List<_Col> cols, List<Widget> children) => Row(
      children: [
        for (var i = 0; i < cols.length; i++)
          cols[i].fixed != null
              ? SizedBox(
                  width: cols[i].fixed,
                  child: _bare.contains(cols[i].key)
                      ? children[i]
                      : Padding(padding: const EdgeInsets.only(right: 14), child: children[i]),
                )
              : Expanded(
                  flex: cols[i].flex,
                  child: Padding(padding: const EdgeInsets.only(right: 14), child: children[i]),
                ),
      ],
    );

class _Header extends StatelessWidget {
  final List<_Col> cols;
  final SortMode? sort;
  final bool? allState;
  final VoidCallback onToggleAll;
  final ValueChanged<SortMode> onSort;
  final VoidCallback onAddColumn;
  final ValueChanged<CustomField> onEditColumn;

  const _Header({
    required this.cols,
    required this.sort,
    required this.allState,
    required this.onToggleAll,
    required this.onSort,
    required this.onAddColumn,
    required this.onEditColumn,
  });

  @override
  Widget build(BuildContext context) {
    Widget title(_Col col) {
      final sorts = col.sorts;
      final active = sorts != null && sort != null && (sort == sorts.$1 || sort == sorts.$2);
      final text = Row(
        children: [
          if (col.field case final f?) ...[Icon(iconFor(f.icon), size: 13, color: Pal.muted), const SizedBox(width: 6)],
          Flexible(
            child: Text(col.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: T.small.copyWith(color: active ? Pal.accentText : Pal.muted)),
          ),
          if (active) ...[
            const SizedBox(width: 4),
            Icon(
              sort == sorts.$2 && sorts.$1 != sorts.$2 ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
              size: 11,
              color: Pal.accentText,
            ),
          ],
        ],
      );
      final VoidCallback? onTap = col.field != null
          ? () => onEditColumn(col.field!)
          : sorts == null || sort == null
              ? null
              : () => onSort(sort == sorts.$1 ? sorts.$2 : sorts.$1);
      return onTap == null
          ? text
          : Pressable(
              onTap: onTap,
              hint: col.field != null ? tr.configureColumn : tr.sort,
              builder: (context, _, _) => text,
            );
    }

    return SizedBox(
      height: 40,
      child: _cells(cols, [
        for (final col in cols)
          switch (col.key) {
            'check' => Center(child: Check(value: allState, onChanged: onToggleAll)),
            'favorite' => const SizedBox.shrink(),
            'add' => Center(child: IconBtn(icon: CupertinoIcons.plus, hint: tr.addColumn, size: 28, onPressed: onAddColumn)),
            _ => title(col),
          },
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final List<_Col> cols;
  final Contact contact;
  final ContactStore store;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _Row({
    super.key,
    required this.cols,
    required this.contact,
    required this.store,
    required this.selected,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final x = contact;
    final date = DateFormat('d MMM y', tr.locale);
    final dim = T.body.copyWith(color: Pal.muted);
    final dash = Text('—', style: T.body.copyWith(color: Pal.dim));

    Widget text(String v, {bool muted = false}) =>
        v.isEmpty ? dash : Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted ? dim : T.body);

    Widget custom(CustomField f) {
      final raw = x.custom[f.id];
      final value = f.format(raw);
      if (value == null) return dash;
      return switch (f.type) {
        FieldType.checkbox => Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              raw == true ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.minus_circle,
              size: 16,
              color: raw == true ? Pal.green : Pal.dim,
            ),
          ),
        FieldType.date => text(date.format(DateTime.parse('$raw')), muted: true),
        FieldType.select => Align(alignment: Alignment.centerLeft, child: Tag.interest(value, small: true)),
        _ => text(value),
      };
    }

    final job = [x.position, x.company].where((s) => s.isNotEmpty).join(' · ');
    final met = [x.whereMet, if (x.metDate != null) date.format(x.metDate!)].where((s) => s.isNotEmpty).join(', ');

    return Pressable(
      onTap: onTap,
      pressScale: 0.997,
      builder: (context, hover, _) => Container(
        decoration: BoxDecoration(
          color: selected ? Pal.selectedRow : (hover ? Pal.raised : null),
          border: Border(
            top: BorderSide(color: Pal.divider),
            left: BorderSide(color: selected ? Pal.accent : const Color(0x00000000), width: 3),
          ),
        ),
        child: _cells(cols, [
          for (final col in cols)
            switch (col.key) {
              'check' => Center(child: Check(value: selected, onChanged: onToggle)),
              'name' => Row(
                  children: [
                    ContactAvatar(name: x.name, photo: store.photoOf(x), radius: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(x.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: T.body.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              'phone' => Row(
                  children: [
                    Flexible(child: text(x.phone)),
                    if (x.phones.length > 1) ...[
                      const SizedBox(width: 6),
                      Hint(
                        message: x.phones.skip(1).map((p) => '${p.value} · ${tr.valueLabel(p.label)}').join('\n'),
                        child: Text('+${x.phones.length - 1}', style: T.small.copyWith(color: Pal.accentText)),
                      ),
                    ],
                  ],
                ),
              'work' => text(job, muted: true),
              'met' => text(met, muted: true),
              'interests' => x.interests.isEmpty
                  ? dash
                  : Row(
                      children: [
                        for (final i in x.interests.take(2)) ...[Flexible(child: Tag.interest(i, small: true)), const SizedBox(width: 5)],
                        if (x.interests.length > 2) Text('+${x.interests.length - 2}', style: T.small),
                      ],
                    ),
              'created' => text(DateFormat.yMd(tr.locale).format(x.createdAt), muted: true),
              'birthday' => x.birthday == null
                  ? dash
                  : Row(
                      children: [
                        Flexible(child: text(DateFormat.yMd(tr.locale).format(x.birthday!))),
                        // Скоро день рождения — розовая точка.
                        if ((x.daysUntilBirthday(DateTime.now()) ?? 999) <= 7) ...[
                          const SizedBox(width: 6),
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: Pal.pink, shape: BoxShape.circle)),
                        ],
                      ],
                    ),
              'favorite' => Center(
                  child: IconBtn(
                    icon: x.favorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    hint: x.favorite ? tr.removeFromFavorites : tr.toFavorites,
                    size: 30,
                    color: x.favorite ? Pal.accentText : (hover ? Pal.muted : Pal.dim),
                    onPressed: () => store.toggleFavorite(x),
                  ),
                ),
              'add' => const SizedBox.shrink(),
              _ => custom(col.field!),
            },
        ]),
      ),
    );
  }
}

/// Кнопка «Столбцы»: что показывать в таблице, а что скрыть.
class ColumnsButton extends StatelessWidget {
  final ContactStore store;
  const ColumnsButton({super.key, required this.store});

  @override
  Widget build(BuildContext context) => Popover(
        width: 300,
        anchor: (context, toggle, open) => Pill(
          label: tr.columns,
          icon: CupertinoIcons.table,
          height: 38,
          open: open,
          onTap: toggle,
        ),
        content: (context, close) => ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final hidden = store.hiddenColumns;
            final keys = orderedColumnKeys(store);
            final fields = {for (final f in store.allFields) _fieldKey(f): f};
            
            Widget lock() => Hint(
                  message: tr.cannotHideColumn,
                  child: Icon(CupertinoIcons.lock, size: 13, color: Pal.dim),
                );

            Widget row(int index, String key) {
              final field = fields[key];
              final VoidCallback? toggle = switch (key) {
                'created' => null,
                _ when field != null => () => _toggleField(field),
                _ => () => store.setColumnHidden(key, !hidden.contains(key)),
              };
              final shown = field?.showInTable ?? !hidden.contains(key);
              return MenuItem(
                key: ValueKey(key),
                label: field?.label ?? tr.columnTitle(key),
                leading: Check(value: shown, onChanged: toggle),
                onTap: toggle,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (field != null) Icon(iconFor(field.icon), size: 13, color: Pal.dim),
                    if (toggle == null) lock(),
                    const SizedBox(width: 6),
                    _DragHandle(index: index),
                  ],
                ),
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MenuItem(
                      label: tr.name,
                      leading: const Check(value: true, onChanged: null),
                      trailing: Hint(message: tr.nameAlwaysFirst, child: Icon(CupertinoIcons.lock, size: 13, color: Pal.dim)),
                    ),
                    ReorderableList(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: keys.length,
                      onReorderItem: (from, to) => store.setColumnOrder([...keys]..removeAt(from)..insert(to, keys[from])),
                      proxyDecorator: (child, _, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: Pal.popover,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Pal.border),
                          boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: child,
                      ),
                      itemBuilder: (context, i) => row(i, keys[i]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                      child: Row(
                        children: [
                          Flexible(child: Text(tr.reorderHint, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.tiny)),
                          Icon(CupertinoIcons.line_horizontal_3, size: 12, color: Pal.muted),
                        ],
                      ),
                    ),
                    const MenuDivider(),
                    MenuItem(
                      label: tr.newFieldEllipsis,
                      icon: CupertinoIcons.plus,
                      onTap: () {
                        close();
                        showFieldDialog(context, store: store, showInTable: true);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  void _toggleField(CustomField f) =>
      store.saveField(store.sectionOfField(f.id)!.id, f.copyWith(showInTable: !f.showInTable));
}

/// Ручка для перетаскивания строки в списке столбцов.
class _DragHandle extends StatelessWidget {
  final int index;
  const _DragHandle({required this.index});

  @override
  Widget build(BuildContext context) => ReorderableDragStartListener(
        index: index,
        child: MouseRegion(
          key: const ValueKey('drag-handle'),
          cursor: SystemMouseCursors.grab,
          child: SizedBox(
            width: 20,
            height: 30,
            child: Center(child: Icon(CupertinoIcons.line_horizontal_3, size: 15, color: Pal.dim)),
          ),
        ),
      );
}
