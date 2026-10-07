import 'package:flutter/cupertino.dart';

import '../data/contact_store.dart';
import '../models/field_schema.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

/// Создание или правка поля. Без [field] создаёт новое в [sectionId]
/// (по умолчанию — первый собственный раздел или «Основное»).
Future<CustomField?> showFieldDialog(
  BuildContext context, {
  required ContactStore store,
  CustomField? field,
  String? sectionId,
  bool showInTable = false,
}) {
  final initialSection = sectionId ??
      (field == null ? null : store.sectionOfField(field.id)?.id) ??
      store.sections.where((s) => !s.builtIn).firstOrNull?.id ??
      BuiltIn.main;
  return showModal<CustomField>(
    context,
    builder: (_) => _FieldDialog(store: store, field: field, sectionId: initialSection, showInTable: showInTable),
  );
}

/// Создание или правка раздела. Возвращает сохранённый раздел.
Future<FieldSection?> showSectionDialog(BuildContext context, {required ContactStore store, FieldSection? section}) =>
    showModal<FieldSection>(context, builder: (_) => _SectionDialog(store: store, section: section));

class _FieldDialog extends StatefulWidget {
  final ContactStore store;
  final CustomField? field;
  final String sectionId;
  final bool showInTable;

  const _FieldDialog({required this.store, required this.field, required this.sectionId, required this.showInTable});

  @override
  State<_FieldDialog> createState() => _FieldDialogState();
}

class _FieldDialogState extends State<_FieldDialog> {
  late final _label = TextEditingController(text: widget.field?.label ?? '');
  final _optionInput = TextEditingController();
  late FieldType _type = widget.field?.type ?? FieldType.text;
  late String _icon = widget.field?.icon ?? _type.defaultIcon;
  late List<String> _options = [...?widget.field?.options];
  late String _sectionId = widget.sectionId;
  late bool _showInTable = widget.field?.showInTable ?? widget.showInTable;

  bool get _isNew => widget.field == null;

  @override
  void initState() {
    super.initState();
    _label.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _label.dispose();
    _optionInput.dispose();
    super.dispose();
  }

  void _setType(FieldType t) => setState(() {
        // Иконку, которую пользователь не трогал, меняем вслед за типом.
        if (_icon == _type.defaultIcon) _icon = t.defaultIcon;
        _type = t;
      });

  void _addOption(String raw) {
    final values = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && !_options.contains(s));
    setState(() => _options = [..._options, ...values]);
    _optionInput.clear();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) return;
    if (_optionInput.text.trim().isNotEmpty) _addOption(_optionInput.text);
    final base = widget.field ?? CustomField(id: widget.store.newId(), label: '');
    final field = base.copyWith(
      label: _label.text.trim(),
      type: _type,
      icon: _icon,
      options: _type == FieldType.select ? _options : const [],
      showInTable: _showInTable,
    );
    await widget.store.saveField(_sectionId, field);
    if (mounted) Navigator.of(context).pop(field);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: tr.deleteFieldTitle(widget.field!.label),
      message: tr.deleteFieldMessage,
      confirmLabel: tr.delete,
      destructive: true,
    );
    if (!ok) return;
    await widget.store.deleteField(widget.field!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _label.text.trim().isNotEmpty;
    return ModalScaffold(
      title: _isNew ? tr.newField : tr.fieldSettings,
      width: 540,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: canSave ? _save : null,
      leadingActions: [if (!_isNew) LinkBtn(label: tr.deleteField, color: Pal.red, onPressed: _delete)],
      actions: [
        Btn(label: tr.cancel, onPressed: () => Navigator.of(context).pop()),
        Btn.primary(label: tr.save, onPressed: canSave ? _save : null),
      ],
      children: [
        Labeled(
          label: tr.title,
          child: Field(
            controller: _label,
            autofocus: true,
            placeholder: tr.fieldNamePlaceholder,
            onSubmitted: (_) => _save(),
          ),
        ),
        const SizedBox(height: 18),
        Labeled(
          label: tr.fieldType,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in FieldType.values)
                _Choice(
                  selected: t == _type,
                  onTap: () => _setType(t),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconFor(t.defaultIcon), size: 15, color: t == _type ? Pal.onAccent : Pal.muted),
                      const SizedBox(width: 7),
                      Text(t.label, style: T.body.copyWith(fontSize: 12.5, color: t == _type ? Pal.onAccent : Pal.text)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_type == FieldType.select) ...[
          const SizedBox(height: 18),
          Labeled(
            label: tr.optionsLabel,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final o in _options) Tag(o, color: Pal.accent, onRemove: () => setState(() => _options = [..._options]..remove(o))),
                SizedBox(
                  width: 220,
                  child: Field(
                    controller: _optionInput,
                    placeholder: tr.newOption,
                    onChanged: (v) {
                      if (v.contains(',')) _addOption(v);
                    },
                    onSubmitted: _addOption,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Labeled(
          label: tr.section,
          child: Dropdown<String>(
            value: _sectionId,
            expand: true,
            width: 300,
            items: [for (final s in widget.store.sections) (s.id, tr.sectionTitle(s))],
            onChanged: (v) => setState(() => _sectionId = v),
          ),
        ),
        const SizedBox(height: 18),
        Labeled(label: tr.icon, child: IconPicker(value: _icon, onChanged: (v) => setState(() => _icon = v))),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          decoration: BoxDecoration(
            color: Pal.raised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Pal.border),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.table, size: 18, color: Pal.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.tableColumn, style: T.body),
                    const SizedBox(height: 2),
                    Text(tr.tableColumnHint, style: T.small),
                  ],
                ),
              ),
              Toggle(value: _showInTable, onChanged: (v) => setState(() => _showInTable = v)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionDialog extends StatefulWidget {
  final ContactStore store;
  final FieldSection? section;
  const _SectionDialog({required this.store, required this.section});

  @override
  State<_SectionDialog> createState() => _SectionDialogState();
}

class _SectionDialogState extends State<_SectionDialog> {
  late final _title = TextEditingController(text: switch (widget.section) {
    final s? => tr.sectionTitle(s),
    null => '',
  });
  late String _icon = widget.section?.icon ?? 'folder';

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    final base = widget.section ?? FieldSection(id: widget.store.newId(), title: '');
    var title = _title.text.trim();
    // Стандартное название на языке интерфейса храним исходным: тогда раздел
    // и дальше переводится вместе с языком.
    if (base.builtIn && title == tr.builtInSectionTitle(base.id)) {
      title = BuiltIn.sections.firstWhere((s) => s.id == base.id).title;
    }
    final section = base.copyWith(title: title, icon: _icon);
    await widget.store.saveSection(section);
    if (mounted) Navigator.of(context).pop(section);
  }

  Future<void> _delete() async {
    final s = widget.section!;
    final ok = await confirmDialog(
      context,
      title: tr.deleteSectionTitle(tr.sectionTitle(s)),
      message: s.fields.isEmpty
          ? tr.sectionEmptyNoLoss
          : tr.deleteSectionFields(s.fields.length),
      confirmLabel: tr.delete,
      destructive: true,
    );
    if (!ok) return;
    await widget.store.deleteSection(s.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final canSave = _title.text.trim().isNotEmpty;
    return ModalScaffold(
      title: s == null ? tr.newSection : tr.sectionSettings,
      subtitle: s?.builtIn ?? false ? tr.builtInSectionNote : null,
      width: 500,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: canSave ? _save : null,
      leadingActions: [if (s != null && !s.builtIn) LinkBtn(label: tr.deleteSection, color: Pal.red, onPressed: _delete)],
      actions: [
        Btn(label: tr.cancel, onPressed: () => Navigator.of(context).pop()),
        Btn.primary(label: tr.save, onPressed: canSave ? _save : null),
      ],
      children: [
        Labeled(
          label: tr.sectionName,
          child: Field(
            controller: _title,
            autofocus: true,
            placeholder: tr.sectionNamePlaceholder,
            onSubmitted: (_) => _save(),
          ),
        ),
        const SizedBox(height: 18),
        Labeled(label: tr.icon, child: IconPicker(value: _icon, onChanged: (v) => setState(() => _icon = v))),
      ],
    );
  }
}

class IconPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const IconPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in fieldIcons.entries)
            _Choice(
              selected: e.key == value,
              square: true,
              onTap: () => onChanged(e.key),
              child: Icon(e.value, size: 17, color: e.key == value ? Pal.onAccent : Pal.text),
            ),
        ],
      );
}

class _Choice extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final bool square;

  const _Choice({required this.selected, required this.onTap, required this.child, this.square = false});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        pressScale: 0.94,
        builder: (context, hover, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: square ? 40 : null,
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: square ? 0 : 14),
          decoration: BoxDecoration(
            color: selected ? Pal.accent : (hover ? Pal.hover : Pal.raised),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Pal.accent : Pal.border),
          ),
          child: Center(widthFactor: 1, child: child),
        ),
      );
}
