import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/contact_store.dart';
import '../data/crypto.dart';
import 'home_page.dart';
import 'theme.dart';
import 'widgets.dart';

const minPinLength = 6;

/// Пускает в приложение только после ввода PIN. При первом запуске —
/// создание PIN и показ recovery code.
class AppGate extends StatefulWidget {
  final Directory root;
  final Vault vault;

  const AppGate({super.key, required this.root, required this.vault});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  ContactStore? _store;

  Future<void> _open(DataCipher cipher) async {
    final store = ContactStore();
    await store.load(root: widget.root, cipher: cipher);
    if (mounted) setState(() => _store = store);
  }

  void _lock() {
    final old = _store;
    setState(() => _store = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: store != null
          ? HomePage(key: ObjectKey(store), store: store, vault: widget.vault, onLock: _lock)
          : widget.vault.isSetUp
              ? _UnlockView(vault: widget.vault, onUnlocked: _open)
              : _SetupView(root: widget.root, vault: widget.vault, onDone: _open),
    );
  }
}

/// Общий каркас экранов блокировки: логотип и карточка по центру.
class _LockFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _LockFrame({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
            decoration: cardDecoration(c, radius: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset('assets/images/logo.png', width: 96, height: 96)),
                const SizedBox(height: 14),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: c.textMuted, height: 1.45)),
                const SizedBox(height: 22),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Поле PIN-кода с кнопкой «показать».
class PinField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.errorText,
    this.onSubmitted,
  });

  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
        suffixIcon: IconButton(
          tooltip: _visible ? 'Скрыть' : 'Показать',
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// Проверка нового PIN: длина и совпадение с подтверждением.
String? validateNewPin(String pin, String confirm) {
  if (pin.length < minPinLength) return 'Не короче $minPinLength символов';
  if (pin != confirm) return 'PIN-коды не совпадают';
  return null;
}

class _Busy extends StatelessWidget {
  final String label;
  const _Busy(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: context.colors.textMuted)),
          ],
        ),
      );
}

class _SetupView extends StatefulWidget {
  final Directory root;
  final Vault vault;
  final Future<void> Function(DataCipher) onDone;

  const _SetupView({required this.root, required this.vault, required this.onDone});

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  DataCipher? _cipher;
  String? _code;
  bool _saved = false;

  late final bool _hasData = File('${widget.root.path}/contacts.json').existsSync();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final error = validateNewPin(_pin.text, _confirm.text);
    setState(() => _error = error);
    if (error != null || _busy) return;
    setState(() => _busy = true);
    final (cipher, code) = await widget.vault.create(_pin.text);
    setState(() {
      _busy = false;
      _cipher = cipher;
      _code = code;
    });
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    await widget.onDone(_cipher!);
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    if (code != null) {
      return _LockFrame(
        title: 'Сохраните recovery code',
        subtitle: 'Он нужен, если вы забудете PIN, и чтобы восстановить резервную '
            'копию на другом Mac. Код показывается только сейчас — запишите его '
            'или сохраните в менеджер паролей.',
        children: [
          RecoveryCodeBox(code: code),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _saved = !_saved),
            child: Row(
              children: [
                Checkbox(value: _saved, onChanged: (v) => setState(() => _saved = v ?? false)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Я сохранил код в надёжном месте', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_busy)
            const _Busy('Шифруем базу…')
          else
            AppButton(
              label: 'Открыть Orbit',
              primary: true,
              onPressed: _saved ? _finish : null,
            ),
        ],
      );
    }
    return _LockFrame(
      title: 'Защитите базу',
      subtitle: _hasData
          ? 'Придумайте PIN-код или пароль. Все контакты и фото будут храниться '
              'на диске в зашифрованном виде.'
          : 'Придумайте PIN-код или пароль. Контакты и фото будут храниться '
              'на диске в зашифрованном виде.',
      children: [
        PinField(controller: _pin, label: 'PIN-код или пароль', autofocus: true),
        const SizedBox(height: 12),
        PinField(
          controller: _confirm,
          label: 'Повторите',
          errorText: _error,
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: 8),
        Text(
          'Не короче $minPinLength символов. Длинный пароль надёжнее короткого числового PIN.',
          style: TextStyle(fontSize: 12.5, color: context.colors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 18),
        if (_busy)
          const _Busy('Создаём ключи…')
        else
          AppButton(label: 'Продолжить', primary: true, onPressed: _create),
      ],
    );
  }
}

/// Recovery code крупно, моноширинным шрифтом, с кнопкой копирования.
class RecoveryCodeBox extends StatelessWidget {
  final String code;
  const RecoveryCodeBox({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: c.text,
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Скопировать',
            icon: Icon(Icons.copy_rounded, size: 18, color: c.accent),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              showToast(context, 'Recovery code скопирован');
            },
          ),
        ],
      ),
    );
  }
}

class _UnlockView extends StatefulWidget {
  final Vault vault;
  final Future<void> Function(DataCipher) onUnlocked;

  const _UnlockView({required this.vault, required this.onUnlocked});

  @override
  State<_UnlockView> createState() => _UnlockViewState();
}

enum _Mode { pin, recovery, newPin }

class _UnlockViewState extends State<_UnlockView> {
  final _pin = TextEditingController();
  final _code = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();
  _Mode _mode = _Mode.pin;
  String? _error;
  bool _busy = false;
  int _failures = 0;
  DateTime? _blockedUntil;
  Timer? _ticker;
  DataCipher? _recovered;

  @override
  void dispose() {
    for (final c in [_pin, _code, _newPin, _confirm]) {
      c.dispose();
    }
    _ticker?.cancel();
    super.dispose();
  }

  int get _secondsLeft {
    final until = _blockedUntil;
    if (until == null) return 0;
    return until.difference(DateTime.now()).inSeconds.clamp(0, 1 << 20) + 1;
  }

  bool get _blocked => _blockedUntil != null && DateTime.now().isBefore(_blockedUntil!);

  /// После каждых пяти ошибок — пауза, и с каждым разом длиннее.
  void _registerFailure() {
    _failures++;
    if (_failures % 5 == 0) {
      _blockedUntil = DateTime.now().add(Duration(seconds: 30 * (_failures ~/ 5)));
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!_blocked) t.cancel();
        setState(() {});
      });
    }
  }

  Future<void> _unlock() async {
    if (_busy || _blocked || _pin.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cipher = await widget.vault.unlock(_pin.text);
      await widget.onUnlocked(cipher);
    } on WrongSecretException {
      _registerFailure();
      _pin.clear();
      setState(() {
        _busy = false;
        _error = 'Неверный PIN-код';
      });
    }
  }

  Future<void> _recover() async {
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
      _recovered = await widget.vault.unlockWithRecovery(_code.text);
      setState(() {
        _busy = false;
        _mode = _Mode.newPin;
      });
    } on WrongSecretException {
      setState(() {
        _busy = false;
        _error = 'Код не подходит. Проверьте регистр букв';
      });
    }
  }

  Future<void> _setNewPin() async {
    final error = validateNewPin(_newPin.text, _confirm.text);
    setState(() => _error = error);
    if (error != null || _busy) return;
    setState(() => _busy = true);
    await widget.vault.changePin(_recovered!, _newPin.text);
    await widget.onUnlocked(_recovered!);
  }

  void _switch(_Mode mode) => setState(() {
        _mode = mode;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return switch (_mode) {
      _Mode.pin => _LockFrame(
          title: 'Orbit заблокирован',
          subtitle: 'Введите PIN-код, чтобы открыть базу',
          children: [
            PinField(
              controller: _pin,
              label: 'PIN-код или пароль',
              autofocus: true,
              errorText: _blocked ? 'Слишком много попыток. Подождите $_secondsLeft с' : _error,
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 18),
            if (_busy)
              const _Busy('Проверяем…')
            else
              AppButton(label: 'Открыть', primary: true, onPressed: _blocked ? null : _unlock),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _switch(_Mode.recovery),
              style: TextButton.styleFrom(foregroundColor: c.textMuted),
              child: const Text('Забыли PIN? Войти по recovery code'),
            ),
          ],
        ),
      _Mode.recovery => _LockFrame(
          title: 'Вход по recovery code',
          subtitle: 'Введите код, который Orbit показал при первой настройке. '
              'Потом нужно будет придумать новый PIN.',
          children: [
            TextField(
              controller: _code,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontFamily: 'Menlo', fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Recovery code',
                hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                errorText: _error,
                prefixIcon: const Icon(Icons.key_outlined, size: 19),
              ),
              onSubmitted: (_) => _recover(),
            ),
            const SizedBox(height: 18),
            if (_busy)
              const _Busy('Проверяем…')
            else
              AppButton(label: 'Продолжить', primary: true, onPressed: _recover),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _switch(_Mode.pin),
              style: TextButton.styleFrom(foregroundColor: c.textMuted),
              child: const Text('Назад к PIN-коду'),
            ),
          ],
        ),
      _Mode.newPin => _LockFrame(
          title: 'Новый PIN-код',
          subtitle: 'Код подошёл. Придумайте новый PIN — recovery code останется прежним.',
          children: [
            PinField(controller: _newPin, label: 'Новый PIN-код или пароль', autofocus: true),
            const SizedBox(height: 12),
            PinField(
              controller: _confirm,
              label: 'Повторите',
              errorText: _error,
              onSubmitted: (_) => _setNewPin(),
            ),
            const SizedBox(height: 18),
            if (_busy)
              const _Busy('Сохраняем…')
            else
              AppButton(label: 'Сохранить и открыть', primary: true, onPressed: _setNewPin),
          ],
        ),
    };
  }
}
