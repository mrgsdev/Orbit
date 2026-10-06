import 'package:flutter/material.dart';

import '../data/contact_store.dart';
import '../models/field_schema.dart';
import 'contact_panel.dart';
import 'field_editors.dart';
import 'theme.dart';
import 'widgets.dart';

/// Панель настройки разделов и полей карточки контакта.
Future<void> showSchemaPanel(BuildContext context, {required ContactStore store}) =>
    showSidePanel(context, width: 540, child: _SchemaPanel(store: store));

class _SchemaPanel extends StatelessWidget {
  final ContactStore store;
  const _SchemaPanel({required this.store});

  Future<void> _addSection(BuildContext context) async {
    final section = await showSectionDialog(context, store: store);
    // Пустой раздел бесполезен — сразу предлагаем первое поле.
    if (section != null && context.mounted) {
      await showFieldDialog(context, store: store, sectionId: section.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Поля и разделы',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Перетаскивайте за ⠿, чтобы поменять порядок',
                        style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                  ],
                ),
              ),
              SquareIconButton(
                icon: Icons.close,
                tooltip: 'Закрыть',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final sections = store.sections;
              return ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                buildDefaultDragHandles: false,
                itemCount: sections.length,
                onReorderItem: store.reorderSections,
                proxyDecorator: (child, _, _) => Material(
                  color: Colors.transparent,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
                itemBuilder: (context, i) => Padding(
                  key: ValueKey(sections[i].id),
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _SectionCard(store: store, section: sections[i], index: i),
                ),
              );
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: AppButton(
            label: 'Новый раздел',
            icon: Icons.add_rounded,
            primary: true,
            onPressed: () => _addSection(context),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ContactStore store;
  final FieldSection section;
  final int index;

  const _SectionCard({required this.store, required this.section, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fixed = BuiltIn.fixedFields[section.id] ?? const [];
    return Container(
      decoration: cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.drag_indicator_rounded, size: 20, color: c.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _IconBox(icon: section.icon, accent: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          section.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (section.builtIn) ...[
                        const SizedBox(width: 8),
                        const Tag('Стандартный', fontSize: 11),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Настроить раздел',
                  icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
                  onPressed: () => showSectionDialog(context, store: store, section: section),
                ),
              ],
            ),
          ),
          const Divider(),
          for (final (label, icon) in fixed)
            _FieldRow(
              icon: icon,
              label: label,
              trailing: Tooltip(
                message: 'Встроенное поле',
                child: Icon(Icons.lock_outline_rounded, size: 16, color: c.textMuted),
              ),
              muted: true,
            ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: section.fields.length,
            onReorderItem: (a, b) => store.reorderFields(section.id, a, b),
            proxyDecorator: (child, _, _) => Material(
              color: c.surface,
              elevation: 6,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              child: child,
            ),
            itemBuilder: (context, i) {
              final f = section.fields[i];
              return _FieldRow(
                key: ValueKey(f.id),
                icon: f.icon,
                label: f.label,
                handle: ReorderableDragStartListener(
                  index: i,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(Icons.drag_indicator_rounded, size: 18, color: c.textMuted),
                  ),
                ),
                onTap: () => showFieldDialog(context, store: store, field: f),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (f.showInTable) ...[
                      Tooltip(
                        message: 'Показывается в таблице',
                        child: Icon(Icons.view_column_outlined, size: 16, color: c.textMuted),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Tag(f.type.label, fontSize: 11.5),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
                  ],
                ),
              );
            },
          ),
          if (fixed.isEmpty && section.fields.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text('В разделе пока нет полей',
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showFieldDialog(context, store: store, sectionId: section.id),
                style: TextButton.styleFrom(
                  foregroundColor: c.accent,
                  textStyle: buttonTextStyle(context),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Добавить поле'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String icon;
  final String label;
  final Widget trailing;
  final Widget? handle;
  final VoidCallback? onTap;
  final bool muted;

  const _FieldRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    this.handle,
    this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
        child: Row(
          children: [
            SizedBox(width: 24, child: handle),
            const SizedBox(width: 8),
            _IconBox(icon: icon, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: muted ? c.textMuted : c.text,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final String icon;
  final double size;
  final bool accent;

  const _IconBox({required this.icon, this.size = 34, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent ? c.accentSoft : c.surfaceMuted,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(iconFor(icon), size: size * 0.52, color: accent ? c.accent : c.textMuted),
    );
  }
}
