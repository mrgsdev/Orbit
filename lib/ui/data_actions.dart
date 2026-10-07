import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../data/backup.dart';
import '../data/contact_store.dart';
import '../data/csv_export.dart';
import '../models/contact.dart';
import '../data/crypto.dart';
import '../data/importers.dart';
import 'lock_screen.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

/// Экспорт в CSV с уведомлением о результате.
Future<void> exportContacts(ContactStore store, List<Contact> contacts) async {
  if (contacts.isEmpty) {
    showToast(tr.nothingToExport);
    return;
  }
  try {
    if (await exportContactsCsv(contacts, store.allFields.toList())) {
      showToast(tr.savedContacts(contacts.length));
    }
  } catch (e) {
    showToast(tr.saveFileFailed(e));
  }
}

/// Импорт из CSV (в том числе экспорта Orbit, Google, Excel) и vCard.
Future<void> importContacts(BuildContext context, ContactStore store) async {
  final types = XTypeGroup(
    label: tr.contactsFileType,
    extensions: ['csv', 'vcf', 'vcard', 'txt'],
    uniformTypeIdentifiers: ['public.comma-separated-values-text', 'public.vcard', 'public.plain-text'],
  );
  final file = await openFile(acceptedTypeGroups: [types]);
  if (file == null || !context.mounted) return;

  final ParsedContacts parsed;
  try {
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    parsed = parseContactsFile(text, store.allFields.toList());
  } catch (e) {
    showToast(tr.readFileFailed(e));
    return;
  }
  if (!context.mounted) return;
  if (parsed.contacts.isEmpty) {
    showToast(tr.noContactsInFile);
    return;
  }

  final fresh = parsed.contacts.where((c) => !store.isDuplicate(c)).toList();
  final dupes = parsed.contacts.length - fresh.length;
  if (fresh.isEmpty) {
    showToast(tr.allAlreadyExist(dupes));
    return;
  }
  final ok = await confirmDialog(
    context,
    title: tr.importTitle(file.name),
    message: tr.importMessage(parsed.contacts.length, dupes),
    confirmLabel: tr.importConfirm(fresh.length),
  );
  if (!ok) return;

  final ids = await store.addImported(fresh, photos: parsed.photos);
  showUndoToast(tr.imported(ids.length), onUndo: () => store.purge(ids));
}

/// Зашифрованная резервная копия всей базы с фото.
Future<void> createBackup(BuildContext context, ContactStore store, Vault vault) async {
  final location = await getSaveLocation(
    suggestedName: 'orbit-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${Backup.extension}',
    acceptedTypeGroups: [XTypeGroup(label: tr.backupFileType, extensions: [Backup.extension])],
  );
  if (location == null) return;
  try {
    final bytes = await Backup.build(snapshot: await store.snapshot(), cipher: store.cipher, envelope: vault.envelope!);
    await File(location.path).writeAsBytes(bytes, flush: true);
    showToast(tr.backupSaved);
  } catch (e) {
    showToast(tr.backupSaveFailed(e));
  }
}

/// Восстановление из .orbit: копию с этого Mac открывает текущий ключ,
/// копию с другой установки — recovery code.
Future<void> restoreBackup(BuildContext context, ContactStore store) async {
  final file = await openFile(acceptedTypeGroups: [
    XTypeGroup(label: tr.backupFileType, extensions: [Backup.extension]),
  ]);
  if (file == null || !context.mounted) return;

  final Backup backup;
  try {
    backup = Backup.parse(await file.readAsBytes());
  } on FormatException catch (e) {
    showToast(e.message);
    return;
  }
  if (!context.mounted) return;

  Map<String, dynamic>? snapshot;
  try {
    snapshot = await backup.open(store.cipher);
  } on WrongSecretException {
    if (!context.mounted) return;
    snapshot = await showModal<Map<String, dynamic>>(context, builder: (_) => _RecoveryCodeSheet(backup: backup));
  }
  if (snapshot == null || !context.mounted) return;

  final created = backup.createdAt;
  final ok = await confirmDialog(
    context,
    title: tr.restoreTitle,
    message: tr.restoreMessage(
      backup.contactCount,
      created == null ? null : DateFormat('d MMMM y, HH:mm', tr.locale).format(created),
    ),
    confirmLabel: tr.restore,
  );
  if (!ok) return;

  final result = await store.mergeSnapshot(snapshot);
  showToast(result.added + result.updated == 0
      ? tr.restoreNothingNew
      : tr.restoreResult(result.added, result.updated));
}

class _RecoveryCodeSheet extends StatefulWidget {
  final Backup backup;
  const _RecoveryCodeSheet({required this.backup});

  @override
  State<_RecoveryCodeSheet> createState() => _RecoveryCodeSheetState();
}

class _RecoveryCodeSheetState extends State<_RecoveryCodeSheet> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_busy) return;
    if (!RecoveryCode.looksValid(_code.text)) {
      setState(() => _error = tr.codeLength(RecoveryCode.length));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final snapshot = await widget.backup.openWithRecovery(_code.text);
      if (mounted) Navigator.of(context).pop(snapshot);
    } on WrongSecretException {
      setState(() {
        _busy = false;
        _error = tr.codeNotForBackup;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ModalScaffold(
        title: tr.needRecoveryTitle,
        subtitle: tr.needRecoverySubtitle,
        width: 500,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: _open,
        actions: [
          Btn(label: tr.cancel, onPressed: () => Navigator.of(context).pop()),
          Btn.primary(label: _busy ? tr.checking : tr.open, onPressed: _busy ? null : _open),
        ],
        children: [
          Labeled(
            label: tr.recoveryFromOtherInstall,
            error: _error,
            child: Field(
              controller: _code,
              autofocus: true,
              placeholder: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
              icon: CupertinoIcons.lock_shield,
              error: _error != null,
              style: T.body.copyWith(fontFamily: 'Menlo', fontSize: 14),
              onSubmitted: (_) => _open(),
            ),
          ),
        ],
      );
}

/// Смена PIN: нужен текущий PIN, ключ данных и recovery code не меняются.
Future<void> changePin(BuildContext context, ContactStore store, Vault vault) async {
  final changed = await showModal<bool>(context, builder: (_) => _ChangePinSheet(store: store, vault: vault));
  if (changed == true) showToast(tr.pinChanged);
}

class _ChangePinSheet extends StatefulWidget {
  final ContactStore store;
  final Vault vault;

  const _ChangePinSheet({required this.store, required this.vault});

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _current = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _currentError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_current, _pin, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final error = validateNewPin(_pin.text, _confirm.text);
    setState(() {
      _error = error;
      _currentError = null;
    });
    if (error != null) return;
    setState(() => _busy = true);
    try {
      await widget.vault.unlock(_current.text);
    } on WrongSecretException {
      setState(() {
        _busy = false;
        _currentError = tr.wrongCurrentPin;
      });
      return;
    }
    await widget.vault.changePin(widget.store.cipher, _pin.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => ModalScaffold(
        title: tr.changePinTitle,
        subtitle: tr.changePinSubtitle,
        width: 460,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: _save,
        actions: [
          Btn(label: tr.cancel, onPressed: () => Navigator.of(context).pop()),
          Btn.primary(label: _busy ? tr.saving : tr.save, onPressed: _busy ? null : _save),
        ],
        children: [
          PinField(controller: _current, placeholder: tr.currentPin, autofocus: true, errorText: _currentError),
          const SizedBox(height: 14),
          PinField(controller: _pin, placeholder: tr.newPinOrPassword),
          const SizedBox(height: 10),
          PinField(controller: _confirm, placeholder: tr.repeat, errorText: _error, onSubmitted: (_) => _save()),
          const SizedBox(height: 10),
          Text('${tr.minLength(minPinLength)}.', style: T.small),
        ],
      );
}

/// Открывает папку с данными Orbit в Finder (или в Проводнике на Windows).
Future<void> openAppFolder(ContactStore store) async {
  final ok = await launchUrl(Uri.directory(store.rootDir.path));
  if (!ok) showToast(tr.openFolderFailed(store.rootDir.path));
}

/// Показ recovery code — только после ввода PIN.
Future<void> showRecoveryCode(BuildContext context, ContactStore store, Vault vault) =>
    showModal<void>(context, builder: (_) => _RevealCodeSheet(store: store, vault: vault));

class _RevealCodeSheet extends StatefulWidget {
  final ContactStore store;
  final Vault vault;
  const _RevealCodeSheet({required this.store, required this.vault});

  @override
  State<_RevealCodeSheet> createState() => _RevealCodeSheetState();
}

class _RevealCodeSheetState extends State<_RevealCodeSheet> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;

  /// Пусто — ещё не проверили PIN; null внутри — код в базе не сохранён.
  ({String? code})? _result;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _reveal() async {
    if (_busy || _pin.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await widget.vault.revealRecoveryCode(_pin.text);
      setState(() {
        _busy = false;
        _result = (code: code);
      });
    } on WrongSecretException {
      _pin.clear();
      setState(() {
        _busy = false;
        _error = tr.wrongPin;
      });
    }
  }

  Future<void> _regenerate() async {
    final ok = await confirmDialog(
      context,
      title: tr.regenerateTitle,
      message: tr.regenerateMessage,
      confirmLabel: tr.create,
    );
    if (!ok) return;
    setState(() => _busy = true);
    final code = await widget.vault.regenerateRecoveryCode(widget.store.cipher);
    setState(() {
      _busy = false;
      _result = (code: code);
    });
  }

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop();
    final result = _result;
    final List<Widget> children;
    final List<Widget> actions;
    if (result == null) {
      children = [
        Text(
          tr.revealIntro,
          style: T.body.copyWith(color: Pal.muted, height: 1.45),
        ),
        const SizedBox(height: 16),
        PinField(controller: _pin, placeholder: tr.pinOrPassword, autofocus: true, errorText: _error, onSubmitted: (_) => _reveal()),
      ];
      actions = [
        Btn(label: tr.cancel, onPressed: close),
        Btn.primary(label: _busy ? tr.checking : tr.show, onPressed: _busy ? null : _reveal),
      ];
    } else if (result.code != null) {
      children = [
        RecoveryCodeBox(code: result.code!),
        const SizedBox(height: 12),
        Text(
          tr.revealKeepSafe,
          style: T.small.copyWith(height: 1.45),
        ),
      ];
      actions = [Btn.primary(label: tr.done, onPressed: close)];
    } else {
      children = [
        Text(
          tr.revealLegacy,
          style: T.body.copyWith(color: Pal.muted, height: 1.45),
        ),
      ];
      actions = [
        Btn(label: tr.cancel, onPressed: close),
        Btn.primary(label: _busy ? tr.creating : tr.createNewCode, onPressed: _busy ? null : _regenerate),
      ];
    }
    return ModalScaffold(
      title: 'Recovery code',
      width: 500,
      onCancel: close,
      onSubmit: result == null ? _reveal : close,
      actions: actions,
      children: children,
    );
  }
}
