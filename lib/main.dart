import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:path_provider/path_provider.dart';

import 'data/crypto.dart';
import 'l10n/strings.dart';
import 'ui/appearance.dart';
import 'ui/hotkeys.dart';
import 'ui/language.dart';
import 'ui/lock_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) await _configureWindow();
  // Даты на всех языках интерфейса.
  await initializeDateFormatting();
  final root = await getApplicationSupportDirectory();
  final vault = Vault(root);
  await vault.load();
  final appearance = await Appearance.load(root);
  final language = await LanguageSetting.load(root);
  final hotkeys = await Hotkeys.load(root);
  runApp(
    ContactsApp(
      root: root,
      vault: vault,
      appearance: appearance,
      language: language,
      hotkeys: hotkeys,
    ),
  );
}

/// Окно без заголовка: содержимое под кнопками окна. Светлое или тёмное
/// оформление окна ставит [ContactsApp] по выбранной теме.
Future<void> _configureWindow() async {
  await WindowManipulator.initialize();
  await WindowManipulator.makeTitlebarTransparent();
  await WindowManipulator.enableFullSizeContentView();
  await WindowManipulator.hideTitle();
  _windowReady = true;
}

var _windowReady = false;

class ContactsApp extends StatefulWidget {
  final Directory root;
  final Vault vault;
  final Appearance appearance;

  /// null — русский без сохранения выбора (для тестов).
  final LanguageSetting? language;

  /// null — стандартные сочетания без сохранения (для тестов).
  final Hotkeys? hotkeys;

  const ContactsApp({
    super.key,
    required this.root,
    required this.vault,
    required this.appearance,
    this.language,
    this.hotkeys,
  });

  @override
  State<ContactsApp> createState() => _ContactsAppState();
}

class _ContactsAppState extends State<ContactsApp> with WidgetsBindingObserver {
  Appearance get appearance => widget.appearance;
  late final _defaultHotkeys = Hotkeys.memory();
  late final LanguageSetting language =
      widget.language ?? LanguageSetting.memory('ru');

  Strings get _strings =>
      language.resolve(WidgetsBinding.instance.platformDispatcher.locales);

  Brightness get _brightness => appearance.resolve(
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appearance.addListener(_apply);
    language.addListener(_applyLanguage);
    Pal.current = _brightness == Brightness.dark ? Palette.dark : Palette.light;
    tr = _strings;
    _syncWindow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appearance.removeListener(_apply);
    language.removeListener(_applyLanguage);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) => _applyLanguage();

  /// Новый язык — сразу во всём окне, без перезапуска и потери состояния.
  void _applyLanguage() {
    if (!mounted) return;
    final next = _strings;
    if (identical(next, tr)) return;
    tr = next;
    rebuildAll(context);
    setState(() {});
  }

  @override
  void didChangePlatformBrightness() => _apply();

  void _apply() {
    if (!mounted) return;
    applyPalette(context, _brightness);
    _syncWindow();
    setState(() {});
  }

  /// Кнопки окна и системные панели — в тон теме.
  void _syncWindow() {
    if (!_windowReady) return;
    WindowManipulator.overrideMacOSBrightness(
      dark: _brightness == Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final root = widget.root;
    final vault = widget.vault;
    return LanguageScope(
      language: language,
      child: HotkeysScope(
        hotkeys: widget.hotkeys ?? _defaultHotkeys,
        child: AppearanceScope(
          appearance: appearance,
          child: CupertinoApp(
            title: 'Orbit',
            debugShowCheckedModeBanner: false,
            theme: CupertinoThemeData(
              brightness: Pal.current.brightness,
              primaryColor: Pal.accent,
              scaffoldBackgroundColor: Pal.canvas,
              textTheme: CupertinoTextThemeData(
                textStyle: T.body,
                primaryColor: Pal.accent,
              ),
            ),
            locale: Locale(tr.locale),
            supportedLocales: [for (final l in languages) Locale(l.locale)],
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            builder: (context, child) => ToastHost(
              child: DefaultTextStyle(style: T.body, child: child!),
            ),
            home: AppGate(root: root, vault: vault),
          ),
        ),
      ),
    );
  }
}
