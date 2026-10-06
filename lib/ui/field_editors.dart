import 'package:flutter/material.dart';

import '../data/contact_store.dart';
import '../models/field_schema.dart';
import 'theme.dart';
import 'widgets.dart';

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
  return showDialog<CustomField>(
    context: context,
    builder: (_) => _FieldDialog(
      store: store,
      field: field,
      sectionId: initialSection,
      showInTable: showInTable,
    ),
  );
}

/// Создание или правка раздела. Возвращает сохранённый раздел.
Future<FieldSection?> showSectionDialog(
  BuildContext context, {
  required ContactStore store,
  FieldSection? section,
}) {
  return showDialog<FieldSection>(
    context: context,
    builder: (_) => _SectionDialog(store: store, section: section),
  );
}

class _FieldDialog extends StatefulWidget {
  final ContactStore store;
  final CustomField? field;
  final String sectionId;
  final bool showInTable;

  const _FieldDialog({
    required this.store,
    required this.field,
    required this.sectionId,
    required this.showInTable,
  });

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
    final values = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !_options.contains(s));
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
    if (mounted) Navigator.pop(context, field);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить поле «${widget.field!.label}»?',
      message: 'Значения этого поля будут удалены у всех контактов.',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!ok) return;
    await widget.store.deleteField(widget.field!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _EditorDialog(
      title: _isNew ? 'Новое поле' : 'Настройка поля',
      onDelete: _isNew ? null : _delete,
      onSave: _save,
      saveEnabled: _label,
      children: [
        TextField(
          controller: _label,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название',
            hintText: 'Например: Instagram, Город, Любимый кофе',
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 22),
        const SectionLabel('Тип поля'),
        const SizedBox(height: 10),
        Wrap(
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
                    Icon(iconFor(t.defaultIcon), size: 16,
                        color: t == _type ? c.accent : c.textMuted),
                    const SizedBox(width: 6),
                    Text(t.label, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
        if (_type == FieldType.select) ...[
          const SizedBox(height: 22),
          const SectionLabel('Варианты'),
          const SizedBox(height: 10),
          if (_options.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in _options)
                  InputChip(
                    label: Text(o),
                    onDeleted: () => setState(() => _options = [..._options]..remove(o)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _optionInput,
            decoration: const InputDecoration(
              hintText: 'Вариант — Enter или запятая',
              prefixIcon: Icon(Icons.add, size: 18),
            ),
            onChanged: (v) {
              if (v.contains(',')) _addOption(v);
            },
            onSubmitted: _addOption,
          ),
        ],
        const SizedBox(height: 22),
        const SectionLabel('Раздел'),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _sectionId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: c.surface,
          items: [
            for (final s in widget.store.sections)
              DropdownMenuItem(
                value: s.id,
                child: Row(
                  children: [
                    Icon(iconFor(s.icon), size: 18, color: c.textMuted),
                    const SizedBox(width: 10),
                    Text(s.title),
                  ],
                ),
              ),
          ],
          onChanged: (v) => setState(() => _sectionId = v!),
        ),
        const SizedBox(height: 22),
        const SectionLabel('Иконка'),
        const SizedBox(height: 10),
        IconPicker(value: _icon, onChanged: (v) => setState(() => _icon = v)),
        const SizedBox(height: 16),
        Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile(
            value: _showInTable,
            onChanged: (v) => setState(() => _showInTable = v),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            secondary: Icon(Icons.view_column_outlined, color: c.textMuted),
            title: const Text('Колонка в таблице',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text('Показывать это поле в списке контактов',
                style: TextStyle(fontSize: 12.5, color: c.textMuted)),
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
  late final _title = TextEditingController(text: widget.section?.title ?? '');
  late String _icon = widget.section?.icon ?? 'folder';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    final base = widget.section ?? FieldSection(id: widget.store.newId(), title: '');
    final section = base.copyWith(title: _title.text.trim(), icon: _icon);
    await widget.store.saveSection(section);
    if (mounted) Navigator.pop(context, section);
  }

  Future<void> _delete() async {
    final s = widget.section!;
    final ok = await confirmDialog(
      context,
      title: 'Удалить раздел «${s.title}»?',
      message: s.fields.isEmpty
          ? 'Раздел пустой, ничего не потеряется.'
          : 'Вместе с разделом удалятся ${s.fields.length} '
              '${plural(s.fields.length, 'поле', 'поля', 'полей')} '
              'и их значения у всех контактов.',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!ok) return;
    await widget.store.deleteSection(s.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return _EditorDialog(
      title: s == null ? 'Новый раздел' : 'Настройка раздела',
      onDelete: s == null || s.builtIn ? null : _delete,
      onSave: _save,
      saveEnabled: _title,
      children: [
        TextField(
          controller: _title,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название раздела',
            hintText: 'Например: Соцсети, Семья, Проекты',
          ),
          onSubmitted: (_) => _save(),
        ),
        if (s?.builtIn ?? false) ...[
          const SizedBox(height: 8),
          Text(
            'Стандартный раздел можно переименовать и дополнить своими полями, '
            'но не удалить.',
            style: TextStyle(fontSize: 12.5, color: context.colors.textMuted, height: 1.4),
          ),
        ],
        const SizedBox(height: 22),
        const SectionLabel('Иконка'),
        const SizedBox(height: 10),
        IconPicker(value: _icon, onChanged: (v) => setState(() => _icon = v)),
      ],
    );
  }
}

/// Общий каркас диалогов-редакторов: заголовок, прокручиваемое тело,
/// «Удалить» слева и «Отмена / Сохранить» справа.
class _EditorDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onDelete;
  final VoidCallback onSave;
  final TextEditingController saveEnabled;

  const _EditorDialog({
    required this.title,
    required this.children,
    required this.onDelete,
    required this.onSave,
    required this.saveEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  SquareIconButton(
                    icon: Icons.close,
                    tooltip: 'Закрыть',
                    size: 34,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 24, 16),
              child: Row(
                children: [
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.danger,
                        textStyle: buttonTextStyle(context),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Удалить'),
                    ),
                  const Spacer(),
                  AppButton(label: 'Отмена', onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  ListenableBuilder(
                    listenable: saveEnabled,
                    builder: (context, _) => AppButton(
                      label: 'Сохранить',
                      icon: Icons.check_rounded,
                      primary: true,
                      onPressed: saveEnabled.text.trim().isEmpty ? null : onSave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IconPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const IconPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in fieldIcons.entries)
          _Choice(
            selected: e.key == value,
            onTap: () => onChanged(e.key),
            square: true,
            child: Icon(e.value, size: 18, color: e.key == value ? c.accent : c.text),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final bool square;

  const _Choice({
    required this.selected,
    required this.onTap,
    required this.child,
    this.square = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.accentSoft : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? c.accent : c.border, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: square ? 38 : null,
          height: 38,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: square ? 0 : 12),
            child: Center(widthFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}
