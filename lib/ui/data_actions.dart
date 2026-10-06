import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/backup.dart';
import '../data/contact_store.dart';
import '../data/crypto.dart';
import '../data/importers.dart';
import 'lock_screen.dart';
import 'theme.dart';
import 'widgets.dart';

String _contactsWord(int n) => '$n ${plural(n, 'контакт', 'контакта', 'контактов')}';

/// Импорт из CSV (в том числе экспорта Orbit, Google, Excel) и vCard.
Future<void> importContacts(BuildContext context, ContactStore store) async {
  const types = XTypeGroup(
    label: 'Контакты',
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
    if (context.mounted) showToast(context, 'Не удалось прочитать файл: $e');
    return;
  }
  if (!context.mounted) return;
  if (parsed.contacts.isEmpty) {
    showToast(context, 'В файле не нашлось контактов');
    return;
  }

  final fresh = parsed.contacts.where((c) => !store.isDuplicate(c)).toList();
  final dupes = parsed.contacts.length - fresh.length;
  if (fresh.isEmpty) {
    showToast(context, 'Все ${_contactsWord(dupes)} из файла уже есть в базе');
    return;
  }
  final ok = await confirmDialog(
    context,
    title: 'Импорт из «${file.name}»',
    message: 'Найдено ${_contactsWord(parsed.contacts.length)}.'
        '${dupes > 0 ? ' ${_contactsWord(dupes)} уже есть в базе — их пропустим.' : ''}',
    confirmLabel: 'Импортировать ${fresh.length}',
  );
  if (!ok) return;

  final ids = await store.addImported(fresh, photos: parsed.photos);
  showUndoToast('Импортировано: ${_contactsWord(ids.length)}', onUndo: () => store.purge(ids));
}

/// Зашифрованная резервная копия всей базы с фото.
Future<void> createBackup(BuildContext context, ContactStore store, Vault vault) async {
  final location = await getSaveLocation(
    suggestedName: 'orbit-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${Backup.extension}',
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Резервная копия Orbit', extensions: [Backup.extension]),
    ],
  );
  if (location == null) return;
  try {
    final bytes = await Backup.build(
      snapshot: await store.snapshot(),
      cipher: store.cipher,
      envelope: vault.envelope!,
    );
    await File(location.path).writeAsBytes(bytes, flush: true);
    if (context.mounted) {
      showToast(context, 'Резервная копия сохранена. Для восстановления на другом Mac нужен recovery code');
    }
  } catch (e) {
    if (context.mounted) showToast(context, 'Не удалось сохранить копию: $e');
  }
}

/// Восстановление из .orbit: копию с этого Mac открывает текущий ключ,
/// копию с другой установки — recovery code.
Future<void> restoreBackup(BuildContext context, ContactStore store) async {
  final file = await openFile(acceptedTypeGroups: const [
    XTypeGroup(label: 'Резервная копия Orbit', extensions: [Backup.extension]),
  ]);
  if (file == null || !context.mounted) return;

  final Backup backup;
  try {
    backup = Backup.parse(await file.readAsBytes());
  } on FormatException catch (e) {
    if (context.mounted) showToast(context, e.message);
    return;
  }
  if (!context.mounted) return;

  Map<String, dynamic>? snapshot;
  try {
    snapshot = await backup.open(store.cipher);
  } on WrongSecretException {
    if (!context.mounted) return;
    snapshot = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RecoveryCodeDialog(backup: backup),
    );
  }
  if (snapshot == null || !context.mounted) return;

  final created = backup.createdAt;
  final ok = await confirmDialog(
    context,
    title: 'Восстановить из копии?',
    message: 'В копии ${_contactsWord(backup.contactCount)}'
        '${created == null ? '' : ' от ${DateFormat('d MMMM y, HH:mm', 'ru').format(created)}'}. '
        'Новые люди добавятся, а у тех, кто уже есть, останется более свежая версия.',
    confirmLabel: 'Восстановить',
  );
  if (!ok) return;

  final result = await store.mergeSnapshot(snapshot);
  if (context.mounted) {
    showToast(
      context,
      result.added + result.updated == 0
          ? 'Всё из копии уже есть в базе'
          : 'Добавлено: ${result.added}, обновлено: ${result.updated}',
    );
  }
}

class _RecoveryCodeDialog extends StatefulWidget {
  final Backup backup;
  const _RecoveryCodeDialog({required this.backup});

  @override
  State<_RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<_RecoveryCodeDialog> {
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
      setState(() => _error = 'В коде ${RecoveryCode.length} символов');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final snapshot = await widget.backup.openWithRecovery(_code.text);
      if (mounted) Navigator.pop(context, snapshot);
    } on WrongSecretException {
      setState(() {
        _busy = false;
        _error = 'Код не подходит к этой копии';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Нужен recovery code',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Копия сделана на другой установке Orbit. Введите recovery code, '
              'который показала та установка при настройке.',
              style: TextStyle(color: context.colors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontFamily: 'Menlo', fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Recovery code',
                errorText: _error,
                prefixIcon: const Icon(Icons.key_outlined, size: 19),
              ),
              onSubmitted: (_) => _open(),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        AppButton(label: 'Отмена', onPressed: () => Navigator.pop(context)),
        AppButton(label: _busy ? 'Проверяем…' : 'Открыть', primary: true, onPressed: _busy ? null : _open),
      ],
    );
  }
}

/// Смена PIN: нужен текущий PIN, ключ данных и recovery code не меняются.
Future<void> changePin(BuildContext context, ContactStore store, Vault vault) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => _ChangePinDialog(store: store, vault: vault),
  );
  if (changed == true && context.mounted) showToast(context, 'PIN-код изменён');
}

class _ChangePinDialog extends StatefulWidget {
  final ContactStore store;
  final Vault vault;

  const _ChangePinDialog({required this.store, required this.vault});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
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
        _currentError = 'Неверный текущий PIN';
      });
      return;
    }
    await widget.vault.changePin(widget.store.cipher, _pin.text);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сменить PIN-код', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PinField(controller: _current, label: 'Текущий PIN', autofocus: true, errorText: _currentError),
            const SizedBox(height: 12),
            PinField(controller: _pin, label: 'Новый PIN-код или пароль'),
            const SizedBox(height: 12),
            PinField(controller: _confirm, label: 'Повторите', errorText: _error, onSubmitted: (_) => _save()),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        AppButton(label: 'Отмена', onPressed: () => Navigator.pop(context)),
        AppButton(label: _busy ? 'Сохраняем…' : 'Сохранить', primary: true, onPressed: _busy ? null : _save),
      ],
    );
  }
}
