import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/contact_store.dart';
import '../models/contact.dart';
import '../models/field_schema.dart';
import 'avatar.dart';
import 'calendar.dart';
import 'field_editors.dart';
import 'interests_panel.dart';
import 'schema_panel.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';
import 'hotkeys.dart';

final _phoneFormatter = FilteringTextInputFormatter.allow(RegExp(r'[\d+\-() ]'));
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _isoDate = DateFormat('yyyy-MM-dd');

/// Окно нового контакта или правки. Возвращает сохранённый контакт.
Future<Contact?> showContactEditor(BuildContext context, {required ContactStore store, Contact? contact}) =>
    showModal<Contact>(
      context,
      dismissible: false,
      builder: (_) => ContactEditor(store: store, initial: contact ?? store.newDraft(), isNew: contact == null),
    );

/// Строка телефона или почты в форме: подпись и поле ввода.
class _ValueEntry {
  String label;
  final TextEditingController controller;

  _ValueEntry(this.label, [String value = '']) : controller = TextEditingController(text: value);

  /// Хотя бы одна строка есть всегда — пустая, если значений нет.
  static List<_ValueEntry> listFrom(List<LabeledValue> values, String defaultLabel) => values.isEmpty
      ? [_ValueEntry(defaultLabel)]
      : [for (final v in values) _ValueEntry(v.label, v.value)];
}

class ContactEditor extends StatefulWidget {
  final Contact initial;
  final ContactStore store;
  final bool isNew;

  const ContactEditor({super.key, required this.initial, required this.store, required this.isNew});

  @override
  State<ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<ContactEditor> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _phones = _ValueEntry.listFrom(widget.initial.phones, LabeledValue.phoneLabels.first);
  late final _telegram = TextEditingController(text: widget.initial.telegram);
  late final _instagram = TextEditingController(text: widget.initial.instagram);
  late final _emails = _ValueEntry.listFrom(widget.initial.emails, LabeledValue.emailLabels.first);
  late final _position = TextEditingController(text: widget.initial.position);
  late final _company = TextEditingController(text: widget.initial.company);
  late final _whereMet = TextEditingController(text: widget.initial.whereMet);
  late final _notes = TextEditingController(text: widget.initial.notes);

  late DateTime? _metDate = widget.initial.metDate;
  late DateTime? _birthday = widget.initial.birthday;
  late List<String> _interests = [...widget.initial.interests];
  late String? _photoFile = widget.initial.photoFile;
  bool _saving = false;

  /// Ошибки проверки: «name», «email-0», id своего поля.
  Map<String, String> _errors = {};

  /// Текстовые пользовательские поля — по контроллеру на поле.
  final Map<String, TextEditingController> _customText = {};

  /// Даты, списки и «да/нет» — значениями.
  late final Map<String, Object?> _customValues = {...widget.initial.custom};

  ContactStore get store => widget.store;

  @override
  void dispose() {
    for (final c in [
      _name, _telegram, _instagram, _position, _company, _whereMet, _notes,
      ..._customText.values,
      for (final e in [..._phones, ..._emails]) e.controller,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _textFor(CustomField f) => _customText.putIfAbsent(
      f.id, () => TextEditingController(text: _stringValue(widget.initial.custom[f.id])));

  static String _stringValue(Object? v) => v is String ? v : '';

  /// Фото, импортированное в этой сессии редактирования, а не исходное.
  bool get _photoIsFresh => _photoFile != null && _photoFile != widget.initial.photoFile;

  Future<void> _pickPhoto() async {
    final images = XTypeGroup(
      label: tr.imagesFileType,
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

  void _toggleInterest(String interest) => setState(() {
        _interests = _interests.contains(interest) ? ([..._interests]..remove(interest)) : [..._interests, interest];
      });

  /// Новый интерес сразу попадает в общий список — им можно пользоваться
  /// и у других контактов.
  Future<void> _createInterest(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    await store.addInterest(value);
    final existing = store.allInterests.firstWhere((i) => i.toLowerCase() == value.toLowerCase(), orElse: () => value);
    if (!_interests.contains(existing)) setState(() => _interests = [..._interests, existing]);
  }

  Future<void> _cancel() async {
    if (_photoIsFresh) await store.discardPhoto(_photoFile!);
    if (mounted) Navigator.of(context).pop();
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

  static List<LabeledValue> _collectValues(List<_ValueEntry> entries) => [
        for (final e in entries)
          if (e.controller.text.trim().isNotEmpty) LabeledValue(e.label, e.controller.text.trim()),
      ];

  static bool _badEmail(String v) => v.trim().isNotEmpty && !_emailPattern.hasMatch(v.trim());

  Map<String, String> _validate() => {
        if (_name.text.trim().isEmpty) 'name': tr.enterName,
        for (var i = 0; i < _emails.length; i++)
          if (_badEmail(_emails[i].controller.text)) 'email-$i': tr.badEmail,
        for (final f in store.allFields)
          if (f.type == FieldType.email && _badEmail(_customText[f.id]?.text ?? '')) f.id: tr.badEmail,
      };

  Future<void> _save() async {
    if (_saving) return;
    final errors = _validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    final contact = widget.initial.copyWith(
      name: _name.text.trim(),
      phones: _collectValues(_phones),
      telegram: _telegram.text.trim(),
      instagram: _instagram.text.trim(),
      emails: _collectValues(_emails),
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
    if (mounted) Navigator.of(context).pop(store.byId(contact.id) ?? contact);
  }

  Future<void> _addSection() async {
    final section = await showSectionDialog(context, store: store);
    if (section != null && mounted) {
      await showFieldDialog(context, store: store, sectionId: section.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => ModalScaffold(
        title: widget.isNew ? tr.newContact : tr.editContact,
        subtitle: tr.formShortcuts(Combo.primary(LogicalKeyboardKey.keyS).label),
        width: 680,
        onCancel: _cancel,
        onSubmit: _save,
        leadingActions: [
          LinkBtn(
            label: tr.fieldsAndSections,
            icon: CupertinoIcons.slider_horizontal_3,
            color: Pal.muted,
            onPressed: () => showSchemaPanel(context, store: store),
          ),
        ],
        actions: [
          Btn(label: tr.cancel, onPressed: _cancel),
          Btn.primary(
            label: widget.isNew ? tr.add : tr.save,
            icon: CupertinoIcons.checkmark_alt,
            onPressed: _saving ? null : _save,
          ),
        ],
        children: [
          _photoHeader(),
          for (final s in store.sections) _section(s),
          Align(
            alignment: Alignment.centerLeft,
            child: LinkBtn(label: tr.addOwnSection, icon: CupertinoIcons.plus, onPressed: _addSection),
          ),
        ],
      ),
    );
  }

  Widget _photoHeader() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Pressable(
              onTap: _pickPhoto,
              hint: tr.choosePhoto,
              builder: (context, hover, _) => Stack(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _name,
                    builder: (context, value, _) =>
                        ContactAvatar(name: value.text, photo: store.photoFile(_photoFile), radius: 38),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: hover ? Pal.accentHover : Pal.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Pal.card, width: 3),
                      ),
                      child: Icon(CupertinoIcons.camera_fill, size: 11, color: Pal.onAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr.photo, style: T.heading),
                const SizedBox(height: 2),
                Row(
                  children: [
                    LinkBtn(label: _photoFile == null ? tr.chooseEllipsis : tr.replaceEllipsis, onPressed: _pickPhoto),
                    if (_photoFile != null) ...[
                      const SizedBox(width: 14),
                      LinkBtn(label: tr.delete, color: Pal.red, onPressed: _removePhoto),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _section(FieldSection s) {
    final fields = [
      ..._builtIn(s.id),
      for (final f in s.fields) _custom(f),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(iconFor(s.icon), size: 16, color: Pal.accentText),
              const SizedBox(width: 10),
              Expanded(child: Text(tr.sectionTitle(s), style: T.heading)),
              LinkBtn(
                label: tr.fieldButton,
                icon: CupertinoIcons.plus,
                onPressed: () => showFieldDialog(context, store: store, sectionId: s.id),
              ),
              const SizedBox(width: 4),
              IconBtn(
                icon: CupertinoIcons.slider_horizontal_3,
                hint: tr.configureSection,
                size: 30,
                onPressed: () => showSectionDialog(context, store: store, section: s),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fields.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Pal.border),
              ),
              child: Text(tr.emptySectionHint, style: T.body.copyWith(color: Pal.muted)),
            ),
          ..._grid(fields),
        ],
      ),
    );
  }

  /// Поля по два в строке; широкие (`_Wide`) — на всю ширину.
  List<Widget> _grid(List<Widget> fields) {
    final out = <Widget>[];
    Widget? pending;
    void flush() {
      if (pending != null) {
        out.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: pending!), const SizedBox(width: 14), const Spacer()]));
        pending = null;
      }
    }

    for (final f in fields) {
      if (f is _Wide) {
        flush();
        out.add(f.child);
      } else if (pending == null) {
        pending = f;
      } else {
        out.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: pending!), const SizedBox(width: 14), Expanded(child: f)]));
        pending = null;
      }
    }
    flush();
    return [
      for (var i = 0; i < out.length; i++) ...[if (i > 0) const SizedBox(height: 14), out[i]],
    ];
  }

  List<Widget> _builtIn(String sectionId) => switch (sectionId) {
        BuiltIn.main => [
            _Wide(Labeled(
              label: tr.name,
              error: _errors['name'],
              child: Field(controller: _name, placeholder: tr.namePlaceholder, autofocus: widget.isNew, error: _errors.containsKey('name')),
            )),
            _Wide(_values(_phones, phone: true)),
            Labeled(label: 'Telegram', child: Field(controller: _telegram, placeholder: tr.handlePlaceholder, icon: CupertinoIcons.paperplane)),
            Labeled(label: 'Instagram', child: Field(controller: _instagram, placeholder: tr.handlePlaceholder, icon: CupertinoIcons.camera)),
            _Wide(_values(_emails, phone: false)),
          ],
        BuiltIn.work => [
            Labeled(label: tr.position, child: Field(controller: _position, placeholder: tr.positionPlaceholder)),
            Labeled(label: tr.company, child: Field(controller: _company, placeholder: tr.companyPlaceholder)),
          ],
        BuiltIn.meet => [
            _Wide(Labeled(
              label: tr.whereMet,
              child: Field(controller: _whereMet, placeholder: tr.whereMetPlaceholder, icon: CupertinoIcons.location),
            )),
            Labeled(label: tr.when, child: DateField(value: _metDate, onChanged: (d) => setState(() => _metDate = d))),
            Labeled(label: tr.birthday, child: DateField(value: _birthday, onChanged: (d) => setState(() => _birthday = d))),
          ],
        BuiltIn.interests => [_Wide(_interestsEditor())],
        BuiltIn.notes => [
            _Wide(Field(controller: _notes, placeholder: tr.notesPlaceholder, maxLines: 10, minLines: 3)),
          ],
        _ => const [],
      };

  /// Несколько телефонов или адресов: у каждого своя подпись, первый — основной.
  Widget _values(List<_ValueEntry> entries, {required bool phone}) {
    final presets = phone ? LabeledValue.phoneLabels : LabeledValue.emailLabels;
    return Labeled(
      label: phone ? tr.phones : tr.email,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              key: ObjectKey(entries[i]),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Dropdown<String>(
                    value: entries[i].label,
                    height: 44,
                    width: 200,
                    expand: true,
                    // Подпись из импорта, которой нет в списке, тоже показываем.
                    items: [for (final l in {...presets, entries[i].label}) (l, tr.valueLabel(l))],
                    onChanged: (v) => setState(() => entries[i].label = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: phone
                    ? Field(
                        controller: entries[i].controller,
                        placeholder: tr.phonePlaceholder,
                        icon: CupertinoIcons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_phoneFormatter],
                      )
                    : Field(
                        controller: entries[i].controller,
                        placeholder: 'name@example.com',
                        icon: CupertinoIcons.envelope,
                        keyboardType: TextInputType.emailAddress,
                        error: _errors.containsKey('email-$i'),
                      ),
                ),
                if (entries.length > 1) ...[
                  const SizedBox(width: 6),
                  IconBtn(
                    icon: CupertinoIcons.minus_circle,
                    hint: tr.remove,
                    size: 44,
                    onPressed: () => setState(() {
                      final removed = entries.removeAt(i);
                      WidgetsBinding.instance.addPostFrameCallback((_) => removed.controller.dispose());
                    }),
                  ),
                ],
              ],
            ),
            if (!phone && _errors['email-$i'] != null)
              Padding(
                padding: const EdgeInsets.only(left: 172, top: 6),
                child: Text(_errors['email-$i']!, style: T.small.copyWith(color: Pal.red)),
              ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: LinkBtn(
              label: phone ? tr.addPhone : tr.addEmail,
              icon: CupertinoIcons.plus_circle,
              onPressed: () => setState(() {
                // Новый — со следующей по списку подписью: второй номер обычно рабочий.
                final used = entries.map((e) => e.label).toSet();
                entries.add(_ValueEntry(presets.firstWhere((l) => !used.contains(l), orElse: () => presets.last)));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interestsEditor() => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: Pal.raised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Pal.border),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final i in _interests) Tag.interest(i, onRemove: () => _toggleInterest(i)),
            Popover(
              width: 300,
              estimatedHeight: 380,
              anchor: (context, toggle, open) => Pressable(
                onTap: toggle,
                builder: (context, hover, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: open || hover ? Pal.accent.withValues(alpha: 0.16) : null,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Pal.accent.withValues(alpha: open || hover ? 0.9 : 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.plus, size: 13, color: Pal.accentText),
                      const SizedBox(width: 6),
                      Text(
                        _interests.isEmpty ? tr.chooseOrCreate : tr.interest,
                        style: T.small.copyWith(color: Pal.accentText, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              content: (context, close) => _InterestMenu(
                all: (store.allInterests..addAll(_interests)).toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())),
                selected: _interests.toSet(),
                onToggle: _toggleInterest,
                onCreate: _createInterest,
                onManage: () {
                  close();
                  showInterestsPanel(context, store: store);
                },
              ),
            ),
          ],
        ),
      );

  Widget _custom(CustomField f) {
    final settings = IconBtn(
      icon: CupertinoIcons.slider_horizontal_3,
      hint: tr.configureField,
      size: 22,
      onPressed: () => showFieldDialog(context, store: store, field: f),
    );
    final icon = iconFor(f.icon);
    final Widget control = switch (f.type) {
      FieldType.date => DateField(
          value: DateTime.tryParse(_stringValue(_customValues[f.id])),
          onChanged: (d) => setState(() => _customValues[f.id] = d == null ? null : _isoDate.format(d)),
        ),
      FieldType.select => f.options.isEmpty
          ? Text(tr.noOptions, style: T.body.copyWith(color: Pal.muted))
          : Dropdown<String>(
              value: f.options.contains(_customValues[f.id]) ? _customValues[f.id] as String : '',
              expand: true,
              height: 44,
              items: [('', tr.notSelected), for (final o in f.options) (o, o)],
              onChanged: (v) => setState(() => _customValues[f.id] = v.isEmpty ? null : v),
            ),
      FieldType.checkbox => Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Pal.raised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Pal.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Pal.muted),
              const SizedBox(width: 10),
              Expanded(child: Text(_customValues[f.id] == true ? tr.yes : tr.no, style: T.body)),
              Toggle(value: _customValues[f.id] == true, onChanged: (v) => setState(() => _customValues[f.id] = v)),
            ],
          ),
        ),
      _ => Field(
          controller: _textFor(f),
          icon: f.type == FieldType.multiline ? null : icon,
          keyboardType: switch (f.type) {
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
          maxLines: f.type == FieldType.multiline ? 8 : 1,
          minLines: f.type == FieldType.multiline ? 2 : null,
          error: _errors.containsKey(f.id),
        ),
    };
    final labeled = Labeled(label: f.label, error: _errors[f.id], trailing: settings, child: control);
    return f.type == FieldType.multiline ? _Wide(labeled) : labeled;
  }
}

/// Поле на всю ширину строки в сетке формы.
class _Wide extends StatelessWidget {
  final Widget child;
  const _Wide(this.child);

  @override
  Widget build(BuildContext context) => child;
}

/// Список интересов с поиском: отметить существующие или создать новый.
class _InterestMenu extends StatefulWidget {
  final List<String> all;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onCreate;
  final VoidCallback onManage;

  const _InterestMenu({
    required this.all,
    required this.selected,
    required this.onToggle,
    required this.onCreate,
    required this.onManage,
  });

  @override
  State<_InterestMenu> createState() => _InterestMenuState();
}

class _InterestMenuState extends State<_InterestMenu> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _create() {
    widget.onCreate(_query.text);
    _query.clear();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final shown = widget.all.where((i) => i.toLowerCase().contains(q)).toList();
    final exact = widget.all.any((i) => i.toLowerCase() == q);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Field(
            controller: _query,
            autofocus: true,
            placeholder: tr.findOrCreate,
            icon: CupertinoIcons.search,
            // Enter: точное совпадение — отметить, иначе — создать новый.
            onSubmitted: (_) {
              if (q.isEmpty) return;
              if (exact) {
                widget.onToggle(widget.all.firstWhere((i) => i.toLowerCase() == q));
                _query.clear();
              } else {
                _create();
              }
            },
          ),
        ),
        Menu(
          maxHeight: 280,
          children: [
            if (q.isNotEmpty && !exact)
              MenuItem(
                label: tr.createNamed(_query.text.trim()),
                icon: CupertinoIcons.plus_circle,
                color: Pal.accentText,
                onTap: _create,
              ),
            for (final i in shown)
              MenuItem(
                label: i,
                leading: Check(value: widget.selected.contains(i), onChanged: () => widget.onToggle(i)),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: TagColors.hue(i), shape: BoxShape.circle),
                ),
                onTap: () => widget.onToggle(i),
              ),
            if (widget.all.isEmpty && q.isEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(tr.noInterestsCreate, style: T.small),
              ),
          ],
        ),
        Container(height: 1, color: Pal.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
          child: LinkBtn(label: tr.manageInterests, color: Pal.muted, onPressed: widget.onManage),
        ),
      ],
    );
  }
}
