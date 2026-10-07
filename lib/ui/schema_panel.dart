import 'package:flutter/cupertino.dart';

import '../data/contact_store.dart';
import '../models/field_schema.dart';
import 'field_editors.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

/// Окно настройки разделов и полей карточки контакта.
Future<void> showSchemaPanel(BuildContext context, {required ContactStore store}) =>
    showModal<void>(context, builder: (_) => _SchemaPanel(store: store));

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
    void close() => Navigator.of(context).pop();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final sections = store.sections;
        return ModalScaffold(
          title: tr.fieldsAndSections,
          subtitle: tr.dragToReorder,
          width: 600,
          onCancel: close,
          onSubmit: close,
          leadingActions: [LinkBtn(label: tr.newSection, icon: CupertinoIcons.plus, onPressed: () => _addSection(context))],
          actions: [Btn.primary(label: tr.done, onPressed: close)],
          children: [
            ReorderableList(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              onReorderItem: store.reorderSections,
              proxyDecorator: (child, _, _) => child,
              itemBuilder: (context, i) => _SectionCard(key: ValueKey(sections[i].id), store: store, section: sections[i], index: i),
            ),
          ],
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  final int index;
  const _Handle(this.index);

  @override
  Widget build(BuildContext context) => ReorderableDragStartListener(
        index: index,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: SizedBox(
            width: 24,
            child: Text('⠿', textAlign: TextAlign.center, style: T.body.copyWith(color: Pal.dim, fontSize: 16)),
          ),
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final ContactStore store;
  final FieldSection section;
  final int index;

  const _SectionCard({super.key, required this.store, required this.section, required this.index});

  @override
  Widget build(BuildContext context) {
    final fixed = BuiltIn.fixedFields[section.id] ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Pal.raised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Pal.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
              child: Row(
                children: [
                  _Handle(index),
                  const SizedBox(width: 6),
                  Icon(iconFor(section.icon), size: 17, color: Pal.accentText),
                  const SizedBox(width: 10),
                  Flexible(child: Text(tr.sectionTitle(section), overflow: TextOverflow.ellipsis, style: T.heading)),
                  if (section.builtIn) ...[const SizedBox(width: 8), Tag(tr.standardTag, small: true)],
                  const Spacer(),
                  IconBtn(
                    icon: CupertinoIcons.slider_horizontal_3,
                    hint: tr.configureSection,
                    size: 32,
                    onPressed: () => showSectionDialog(context, store: store, section: section),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Pal.border),
            for (final (key, icon) in fixed)
              _FieldRow(
                icon: icon,
                label: tr.builtInFieldLabel(key),
                trailing: Hint(message: tr.builtInField, child: Icon(CupertinoIcons.lock, size: 14, color: Pal.dim)),
                muted: true,
              ),
            ReorderableList(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.fields.length,
              onReorderItem: (a, b) => store.reorderFields(section.id, a, b),
              proxyDecorator: (child, _, _) => ColoredBox(color: Pal.hover, child: child),
              itemBuilder: (context, i) {
                final f = section.fields[i];
                return _FieldRow(
                  key: ValueKey(f.id),
                  icon: f.icon,
                  label: f.label,
                  handle: _Handle(i),
                  onTap: () => showFieldDialog(context, store: store, field: f),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (f.showInTable) ...[
                        Hint(message: tr.shownInTable, child: Icon(CupertinoIcons.table, size: 14, color: Pal.muted)),
                        const SizedBox(width: 10),
                      ],
                      Tag(f.type.label, small: true),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.chevron_right, size: 12, color: Pal.dim),
                    ],
                  ),
                );
              },
            ),
            if (fixed.isEmpty && section.fields.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 12, 12, 0),
                child: Text(tr.noFieldsInSection, style: T.body.copyWith(color: Pal.muted)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 4, 8, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LinkBtn(
                  label: tr.addField,
                  icon: CupertinoIcons.plus,
                  onPressed: () => showFieldDialog(context, store: store, sectionId: section.id),
                ),
              ),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        pressScale: 0.995,
        builder: (context, hover, _) => Container(
          color: hover ? Pal.hover : null,
          padding: const EdgeInsets.fromLTRB(8, 9, 14, 9),
          child: Row(
            children: [
              SizedBox(width: 24, child: handle),
              const SizedBox(width: 6),
              Icon(iconFor(icon), size: 15, color: Pal.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, overflow: TextOverflow.ellipsis, style: T.body.copyWith(color: muted ? Pal.muted : Pal.text)),
              ),
              trailing,
            ],
          ),
        ),
      );
}
