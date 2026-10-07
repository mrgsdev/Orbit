import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../data/contact_store.dart';
import '../data/crypto.dart';
import 'home_page.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

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

  /// Знакомство — один раз, сразу после первой настройки базы.
  bool _firstRun = false;

  Future<void> _open(DataCipher cipher) async {
    final store = ContactStore();
    await store.load(root: widget.root, cipher: cipher);
    if (mounted) setState(() => _store = store);
  }

  void _lock() {
    _firstRun = false;
    final old = _store;
    hideToast();
    setState(() => _store = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: store != null
          ? HomePage(key: ObjectKey(store), store: store, vault: widget.vault, onLock: _lock, onboarding: _firstRun)
          : widget.vault.isSetUp
              ? _UnlockView(vault: widget.vault, onUnlocked: _open)
              : _SetupView(
                  root: widget.root,
                  vault: widget.vault,
                  onDone: (cipher) {
                    _firstRun = true;
                    return _open(cipher);
                  },
                ),
    );
  }
}

/// Экран блокировки: тёмный фон, карточка по центру с логотипом.
class _LockFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _LockFrame({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Pal.canvas,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Panel(
            padding: const EdgeInsets.fromLTRB(36, 30, 36, 32),
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Image.asset('assets/images/logo.png', width: 120, height: 120)),
                  Center(child: Text('Orbit', style: T.script.copyWith(fontSize: 34))),
                  const SizedBox(height: 14),
                  Text(title, textAlign: TextAlign.center, style: T.title.copyWith(fontSize: 21)),
                  const SizedBox(height: 8),
                  Text(subtitle, textAlign: TextAlign.center, style: T.body.copyWith(color: Pal.muted, height: 1.45)),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Поле PIN-кода со значком замка и кнопкой «показать».
class PinField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  const PinField({
    super.key,
    required this.controller,
    required this.placeholder,
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Field(
            controller: widget.controller,
            autofocus: widget.autofocus,
            obscure: !_visible,
            placeholder: widget.placeholder,
            icon: CupertinoIcons.lock,
            error: widget.errorText != null,
            suffix: IconBtn(
              icon: _visible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              hint: _visible ? tr.hide : tr.show,
              size: 30,
              onPressed: () => setState(() => _visible = !_visible),
            ),
            onSubmitted: widget.onSubmitted,
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(widget.errorText!, style: T.small.copyWith(color: Pal.red)),
            ),
        ],
      );
}

/// Проверка нового PIN: длина и совпадение с подтверждением.
String? validateNewPin(String pin, String confirm) {
  if (pin.length < minPinLength) return tr.minLength(minPinLength);
  if (pin != confirm) return tr.pinsMismatch;
  return null;
}

class _Busy extends StatelessWidget {
  final String label;
  const _Busy(this.label);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(color: Pal.accent, radius: 9),
            const SizedBox(width: 12),
            Text(label, style: T.body.copyWith(color: Pal.muted)),
          ],
        ),
      );
}

Widget _primary(String label, VoidCallback? onPressed) => Btn.primary(label: label, expand: true, onPressed: onPressed);

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
        title: tr.saveRecoveryTitle,
        subtitle: tr.saveRecoverySubtitle,
        children: [
          RecoveryCodeBox(code: code),
          const SizedBox(height: 16),
          Pressable(
            onTap: () => setState(() => _saved = !_saved),
            pressScale: 1,
            builder: (context, _, _) => Row(
              children: [
                Check(value: _saved, onChanged: () => setState(() => _saved = !_saved)),
                const SizedBox(width: 6),
                Expanded(child: Text(tr.savedCodeCheck, style: T.body)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_busy) _Busy(tr.encrypting) else _primary(tr.openOrbit, _saved ? _finish : null),
        ],
      );
    }
    return _LockFrame(
      title: tr.protectTitle,
      subtitle: _hasData
          ? tr.protectExisting
          : tr.protectNew,
      children: [
        PinField(controller: _pin, placeholder: tr.pinOrPassword, autofocus: true),
        const SizedBox(height: 10),
        PinField(controller: _confirm, placeholder: tr.repeat, errorText: _error, onSubmitted: (_) => _create()),
        const SizedBox(height: 8),
        Text(
          tr.pinHint(minPinLength),
          style: T.small.copyWith(height: 1.45),
        ),
        const SizedBox(height: 18),
        if (_busy) _Busy(tr.creatingKeys) else _primary(tr.continueAction, _create),
      ],
    );
  }
}

/// Recovery code крупно, моноширинным шрифтом, с кнопкой копирования.
class RecoveryCodeBox extends StatelessWidget {
  final String code;
  const RecoveryCodeBox({super.key, required this.code});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: Pal.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Pal.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                code,
                key: const Key('recovery-code'),
                style: T.body.copyWith(fontFamily: 'Menlo', fontSize: 15, fontWeight: FontWeight.w600, height: 1.5, color: Pal.accentText),
              ),
            ),
            IconBtn(
              icon: CupertinoIcons.doc_on_doc,
              hint: tr.copy,
              color: Pal.accentText,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                showToast(tr.codeCopied);
              },
            ),
          ],
        ),
      );
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
        _error = tr.wrongPin;
      });
    }
  }

  Future<void> _recover() async {
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
      _recovered = await widget.vault.unlockWithRecovery(_code.text);
      setState(() {
        _busy = false;
        _mode = _Mode.newPin;
      });
    } on WrongSecretException {
      setState(() {
        _busy = false;
        _error = tr.codeWrongCase;
      });
    }
  }

  Future<void> _setNewPin() async {
    final error = validateNewPin(_newPin.text, _confirm.text);
    setState(() => _error = error);
    if (error != null || _busy) return;
    setState(() => _busy = true);
    await widget.vault.changePin(_recovered!, _newPin.text);
    // Код только что ввели — запомним, чтобы его можно было показать позже.
    await widget.vault.rememberRecoveryCode(_recovered!, _code.text);
    await widget.onUnlocked(_recovered!);
  }

  void _switch(_Mode mode) => setState(() {
        _mode = mode;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _Mode.pin => _LockFrame(
          title: tr.lockedTitle,
          subtitle: tr.lockedSubtitle,
          children: [
            PinField(
              controller: _pin,
              placeholder: tr.pinOrPassword,
              autofocus: true,
              errorText: _blocked ? tr.tooManyAttempts(_secondsLeft) : _error,
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 16),
            if (_busy) _Busy(tr.checking) else _primary(tr.open, _blocked ? null : _unlock),
            const SizedBox(height: 8),
            Center(child: LinkBtn(label: tr.forgotPin, color: Pal.muted, onPressed: () => _switch(_Mode.recovery))),
          ],
        ),
      _Mode.recovery => _LockFrame(
          title: tr.recoveryLoginTitle,
          subtitle: tr.recoveryLoginSubtitle,
          children: [
            Field(
              controller: _code,
              autofocus: true,
              placeholder: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
              icon: CupertinoIcons.lock_shield,
              error: _error != null,
              style: T.body.copyWith(fontFamily: 'Menlo', fontSize: 14),
              onSubmitted: (_) => _recover(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(_error!, style: T.small.copyWith(color: Pal.red)),
              ),
            const SizedBox(height: 16),
            if (_busy) _Busy(tr.checking) else _primary(tr.continueAction, _recover),
            const SizedBox(height: 8),
            Center(child: LinkBtn(label: tr.backToPin, color: Pal.muted, onPressed: () => _switch(_Mode.pin))),
          ],
        ),
      _Mode.newPin => _LockFrame(
          title: tr.newPinTitle,
          subtitle: tr.newPinSubtitle,
          children: [
            PinField(controller: _newPin, placeholder: tr.newPinOrPassword, autofocus: true),
            const SizedBox(height: 10),
            PinField(
              controller: _confirm,
              placeholder: tr.repeat,
              errorText: _error,
              onSubmitted: (_) => _setNewPin(),
            ),
            const SizedBox(height: 16),
            if (_busy) _Busy(tr.saving) else _primary(tr.saveAndOpen, _setNewPin),
          ],
        ),
    };
  }
}
