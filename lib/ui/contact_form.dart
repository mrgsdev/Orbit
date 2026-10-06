import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import '../models/field_schema.dart';
import 'avatar.dart';
import 'field_editors.dart';
import 'schema_panel.dart';
import 'theme.dart';
import 'widgets.dart';

final _phoneFormatter = FilteringTextInputFormatter.allow(RegExp(r'[\d+\-() ]'));
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _isoDate = DateFormat('yyyy-MM-dd');

class ContactForm extends StatefulWidget {
  final Contact initial;
  final ContactStore store;
  final bool isNew;
  final ValueChanged<Contact> onSaved;
  final VoidCallback onCancel;

  const ContactForm({
    super.key,
    required this.initial,
    required this.store,
    required this.isNew,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _telegram = TextEditingController(text: widget.initial.telegram);
  late final _email = TextEditingController(text: widget.initial.email);
  late final _position = TextEditingController(text: widget.initial.position);
  late final _company = TextEditingController(text: widget.initial.company);
  late final _whereMet = TextEditingController(text: widget.initial.whereMet);
  late final _notes = TextEditingController(text: widget.initial.notes);
  final _interestInput = TextEditingController();
  final _interestFocus = FocusNode();

  late DateTime? _metDate = widget.initial.metDate;
  late DateTime? _birthday = widget.initial.birthday;
  late List<String> _interests = [...widget.initial.interests];
  late String? _photoFile = widget.initial.photoFile;
  bool _saving = false;

  /// Текстовые пользовательские поля — по контроллеру на поле.
  final Map<String, TextEditingController> _customText = {};

  /// Даты, списки и «да/нет» — значениями.
  late final Map<String, Object?> _customValues = {...widget.initial.custom};

  ContactStore get store => widget.store;

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _telegram, _email, _position, _company, _whereMet, _notes,
      _interestInput, ..._customText.values,
    ]) {
      c.dispose();
    }
    _interestFocus.dispose();
    super.dispose();
  }

  TextEditingController _textFor(CustomField f) => _customText.putIfAbsent(
      f.id, () => TextEditingController(text: _stringValue(widget.initial.custom[f.id])));

  static String _stringValue(Object? v) => v is String ? v : '';

  /// Фото, импортированное в этой сессии редактирования, а не исходное.
  bool get _photoIsFresh =>
      _photoFile != null && _photoFile != widget.initial.photoFile;

  Future<void> _pickPhoto() async {
    const images = XTypeGroup(
      label: 'Изображения',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'bmp'],
      uniformTypeIdentifiers: ['public.image'],
    );
    final file = await openFile(acceptedTypeGroups: [images]);
    if (file == null) return;
    final imported = await store.importPhoto(file.path);
    if (_photoIsFresh) await store.discardPhoto(_photoFile!);
    setState(() => _photoFile = imported);
  }

  Future<void> _removePhoto() async {
    if (_photoIsFresh) await store.discardPhoto(_photoFile!);
    setState(() => _photoFile = null);
  }

  void _addInterest(String raw) {
    final values = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !_interests.contains(s));
    setState(() => _interests = [..._interests, ...values]);
    _interestInput.clear();
    _interestFocus.requestFocus();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 50),
      locale: const Locale('ru'),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _cancel() async {
    if (_photoIsFresh) await store.discardPhoto(_photoFile!);
    widget.onCancel();
  }

  /// Значения пользовательских полей по текущей схеме. Значения, которые
  /// не подходят к типу поля (тип сменили), отбрасываем.
  Map<String, Object?> _collectCustom() {
    final out = <String, Object?>{};
    for (final f in store.allFields) {
      final Object? v;
      if (f.type.isTextual) {
        final text = (_customText[f.id]?.text ?? _stringValue(_customValues[f.id])).trim();
        v = text.isEmpty ? null : text;
      } else {
        final raw = _customValues[f.id];
        v = switch (f.type) {
          FieldType.checkbox => raw is bool ? raw : null,
          FieldType.date => raw is String && DateTime.tryParse(raw) != null ? raw : null,
          FieldType.select => f.options.contains(raw) ? raw : null,
          _ => null,
        };
      }
      if (v != null) out[f.id] = v;
    }
    return out;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    // Недописанный интерес в поле ввода тоже сохраняем.
    if (_interestInput.text.trim().isNotEmpty) _addInterest(_interestInput.text);

    setState(() => _saving = true);
    final contact = widget.initial.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      telegram: _telegram.text.trim(),
      email: _email.text.trim(),
      position: _position.text.trim(),
      company: _company.text.trim(),
      whereMet: _whereMet.text.trim(),
      metDate: () => _metDate,
      birthday: () => _birthday,
      interests: _interests,
      notes: _notes.text.trim(),
      custom: _collectCustom(),
      photoFile: () => _photoFile,
    );
    await store.save(contact);
    widget.onSaved(contact);
  }

  Future<void> _addSection() async {
    final section = await showSectionDialog(context, store: store);
    if (section != null && mounted) {
      await showFieldDialog(context, store: store, sectionId: section.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isNew ? 'Новый контакт' : 'Редактирование',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text('⌘S — сохранить, Esc — отменить',
                            style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                      ],
                    ),
                  ),
                  SquareIconButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Поля и разделы',
                    onPressed: () => showSchemaPanel(context, store: store),
                  ),
                  const SizedBox(width: 8),
                  SquareIconButton(icon: Icons.close, tooltip: 'Отмена', onPressed: _cancel),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  children: [
                    _photoPicker(),
                    const SizedBox(height: 24),
                    for (final s in store.sections) _section(s),
                    OutlinedButton.icon(
                      onPressed: _addSection,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textMuted,
                        side: BorderSide(color: c.border),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: buttonTextStyle(context),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Добавить свой раздел'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(label: 'Отмена', onPressed: _cancel),
                  const SizedBox(width: 10),
                  AppButton(
                    label: widget.isNew ? 'Добавить контакт' : 'Сохранить',
                    icon: Icons.check_rounded,
                    primary: true,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(FieldSection s) {
    final c = context.colors;
    final children = [
      ..._builtInFields(s.id),
      for (final f in s.fields) _customField(f),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(iconFor(s.icon), size: 15, color: c.textMuted),
              const SizedBox(width: 6),
              Expanded(child: SectionLabel(s.title)),
              _SmallAction(
                icon: Icons.add_rounded,
                label: 'Поле',
                onTap: () => showFieldDialog(context, store: store, sectionId: s.id),
              ),
              _SmallAction(
                icon: Icons.edit_outlined,
                tooltip: 'Настроить раздел',
                onTap: () => showSectionDialog(context, store: store, section: s),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (children.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Пустой раздел — нажмите «+ Поле», чтобы добавить',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }

  List<Widget> _builtInFields(String sectionId) {
    return switch (sectionId) {
      BuiltIn.main => [
          _field(_name, 'Имя', Icons.person_outline,
              autofocus: widget.isNew,
              validator: (v) => v == null || v.trim().isEmpty ? 'Укажите имя' : null),
          _row([
            _field(_phone, 'Телефон', Icons.phone_outlined,
                hint: '+7 900 000-00-00',
                keyboard: TextInputType.phone,
                inputFormatters: [_phoneFormatter]),
            _field(_telegram, 'Ник в Telegram', Icons.send_outlined, hint: '@nickname'),
          ]),
          _field(_email, 'Email', Icons.mail_outline,
              keyboard: TextInputType.emailAddress, validator: _validateEmail),
        ],
      BuiltIn.work => [
          _row([
            _field(_position, 'Должность', Icons.work_outline),
            _field(_company, 'Компания', Icons.business_outlined),
          ]),
        ],
      BuiltIn.meet => [
          _field(_whereMet, 'Где познакомились', Icons.handshake_outlined,
              hint: 'Конференция, через друзей, …'),
          _row([
            _dateField('Дата знакомства', Icons.event_outlined, _metDate,
                (d) => _metDate = d),
            _dateField('День рождения', Icons.cake_outlined, _birthday,
                (d) => _birthday = d),
          ]),
        ],
      BuiltIn.interests => _interestFields(),
      BuiltIn.notes => [
          TextFormField(
            controller: _notes,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(hintText: 'Всё, что стоит помнить о человеке'),
          ),
        ],
      _ => const [],
    };
  }

  List<Widget> _interestFields() {
    final suggestions = store.allInterests.difference(_interests.toSet()).toList()..sort();
    return [
      if (_interests.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in _interests)
              _RemovableTag(
                label: i,
                onRemove: () => setState(() => _interests = [..._interests]..remove(i)),
              ),
          ],
        ),
      TextField(
        controller: _interestInput,
        focusNode: _interestFocus,
        decoration: InputDecoration(
          labelText: 'Добавить интерес',
          hintText: 'Enter или запятая — добавить',
          prefixIcon: const Icon(Icons.interests_outlined, size: 19),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addInterest(_interestInput.text),
          ),
        ),
        onChanged: (v) {
          if (v.contains(',')) _addInterest(v);
        },
        onSubmitted: _addInterest,
      ),
      if (suggestions.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in suggestions.take(15))
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _addInterest(s),
                child: Tag(s, icon: Icons.add),
              ),
          ],
        ),
    ];
  }

  static String? _validateEmail(String? v) =>
      v != null && v.trim().isNotEmpty && !_emailPattern.hasMatch(v.trim())
          ? 'Некорректный email'
          : null;

  Widget _customField(CustomField f) {
    final c = context.colors;
    final icon = iconFor(f.icon);
    final Widget input = switch (f.type) {
      FieldType.date => _dateField(
          f.label,
          icon,
          DateTime.tryParse(_stringValue(_customValues[f.id])),
          (d) => _customValues[f.id] = d == null ? null : _isoDate.format(d),
        ),
      FieldType.select => DropdownButtonFormField<String>(
          initialValue: f.options.contains(_customValues[f.id]) ? _customValues[f.id] as String : null,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: c.surface,
          hint: Text(f.options.isEmpty ? 'Нет вариантов — добавьте в настройках поля' : 'Не выбрано',
              style: TextStyle(fontSize: 14, color: c.textMuted)),
          decoration: InputDecoration(labelText: f.label, prefixIcon: Icon(icon, size: 19)),
          items: [
            for (final o in f.options) DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) => setState(() => _customValues[f.id] = v),
        ),
      FieldType.checkbox => Container(
          height: 50,
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: cardDecoration(c, radius: 10),
          child: Row(
            children: [
              Icon(icon, size: 19, color: c.textMuted),
              const SizedBox(width: 12),
              Expanded(child: Text(f.label, style: const TextStyle(fontSize: 14))),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _customValues[f.id] == true,
                  onChanged: (v) => setState(() => _customValues[f.id] = v),
                ),
              ),
            ],
          ),
        ),
      _ => _field(
          _textFor(f),
          f.label,
          icon,
          keyboard: switch (f.type) {
            FieldType.number => const TextInputType.numberWithOptions(decimal: true, signed: true),
            FieldType.phone => TextInputType.phone,
            FieldType.email => TextInputType.emailAddress,
            FieldType.url => TextInputType.url,
            FieldType.multiline => TextInputType.multiline,
            _ => TextInputType.text,
          },
          inputFormatters: switch (f.type) {
            FieldType.number => [FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-+ ]'))],
            FieldType.phone => [_phoneFormatter],
            _ => null,
          },
          validator: f.type == FieldType.email ? _validateEmail : null,
          multiline: f.type == FieldType.multiline,
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: input),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: IconButton(
            tooltip: 'Настроить поле',
            icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textMuted),
            onPressed: () => showFieldDialog(context, store: store, field: f),
          ),
        ),
      ],
    );
  }

  Widget _photoPicker() {
    final c = context.colors;
    final photo = store.photoFile(_photoFile);
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ValueListenableBuilder(
                valueListenable: _name,
                builder: (context, value, _) => InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _pickPhoto,
                  child: ContactAvatar(name: value.text, photo: photo, radius: 48),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: c.accent,
                  shape: CircleBorder(side: BorderSide(color: c.surface, width: 3)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.photo_camera_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: _photoFile == null ? 'Загрузить фото' : 'Сменить фото',
                icon: Icons.upload_rounded,
                onPressed: _pickPhoto,
              ),
              if (_photoFile != null) ...[
                const SizedBox(width: 8),
                AppButton(label: 'Убрать', danger: true, onPressed: _removePhoto),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool autofocus = false,
    bool multiline = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      minLines: multiline ? 2 : 1,
      maxLines: multiline ? 8 : 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
      ),
    );
  }

  Widget _dateField(
    String label,
    IconData icon,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _pickDate(current: value, onPicked: onChanged),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 19),
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Очистить',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => onChanged(null)),
                ),
        ),
        isEmpty: value == null,
        child: Text(
          value == null ? '' : DateFormat('d MMM y', 'ru').format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  const _SmallAction({required this.icon, this.label, this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final child = InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: label == null ? c.textMuted : c.accent),
            if (label != null) ...[
              const SizedBox(width: 3),
              Text(label!,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.accent)),
            ],
          ],
        ),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip, child: child);
  }
}

class _RemovableTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = TagColors.of(label, Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg)),
          const SizedBox(width: 2),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 15, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
