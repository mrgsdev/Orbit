import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import 'appearance.dart';
import 'hotkeys.dart';
import 'language.dart';
import 'platform.dart';
import 'theme.dart';
import 'widgets.dart';

/// Чем закончилось знакомство.
enum OnboardingResult { done, openShortcuts }

/// Знакомство с приложением: пять коротких шагов. Само показывается один раз,
/// при первом запуске; потом — из настроек. Закрыть можно в любой момент.
Future<OnboardingResult> showOnboarding(BuildContext context) async {
  final result = await showModal<OnboardingResult>(context, dismissible: false, builder: (_) => const _Onboarding());
  return result ?? OnboardingResult.done;
}

class _Onboarding extends StatefulWidget {
  const _Onboarding();

  @override
  State<_Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<_Onboarding> {
  static const _pages = 5;
  int _page = 0;
  bool _forward = true;

  bool get _last => _page == _pages - 1;

  void _close([OnboardingResult r = OnboardingResult.done]) => Navigator.of(context).pop(r);

  void _next() {
    if (_last) return _close();
    setState(() {
      _forward = true;
      _page++;
    });
  }

  void _back() {
    if (_page == 0) return;
    setState(() {
      _forward = false;
      _page--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
        const SingleActivator(LogicalKeyboardKey.enter): _next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _back,
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: FocusScope(
        autofocus: true,
        child: Container(
          width: 680,
          height: (size.height - 64).clamp(420.0, 600.0),
          decoration: BoxDecoration(
            color: Pal.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Pal.border),
            boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 60, offset: const Offset(0, 24))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: Offset(_forward ? 0.06 : -0.06, 0), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(_page), child: _content()),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() => switch (_page) {
        0 => _Page(
            art: Image.asset('assets/images/logo.png', height: 170),
            title: tr.onbWelcomeTitle,
            text: tr.onbWelcomeText,
            extra: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [LanguageDropdown(width: 200), SizedBox(width: 320, child: ThemeSwitch(showLabel: false))],
            ),
          ),
        1 => _Page(art: _art('assets/images/card_new.png'), title: tr.onbPeopleTitle, text: tr.onbPeopleText),
        2 => _Page(art: _art('assets/images/card_birthdays.png'), title: tr.onbDatesTitle, text: tr.onbDatesText),
        3 => _Page(art: const _IconArt(CupertinoIcons.lock_shield_fill), title: tr.onbPrivacyTitle, text: tr.onbPrivacyText),
        _ => _Page(
            title: tr.settingsShortcuts,
            text: tr.onbKeysText,
            extra: Column(
              children: [
                _ShortcutsGrid(),
                const SizedBox(height: 14),
                LinkBtn(
                  label: tr.onbChangeShortcuts,
                  icon: CupertinoIcons.keyboard,
                  onPressed: () => _close(OnboardingResult.openShortcuts),
                ),
              ],
            ),
          ),
      };

  Widget _art(String asset) => Image.asset(
        asset,
        height: 190,
        cacheHeight: (190 * MediaQuery.devicePixelRatioOf(context)).round(),
      );

  Widget _footer() => Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Pal.divider))),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _last ? const SizedBox.shrink() : LinkBtn(label: tr.onbSkip, color: Pal.muted, onPressed: _close),
              ),
            ),
            for (var i = 0; i < _pages; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _page ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? Pal.accent : Pal.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_page > 0) ...[Btn(label: tr.onbBack, onPressed: _back), const SizedBox(width: 10)],
                  Btn.primary(label: _last ? tr.onbStart : tr.onbNext, onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Page extends StatelessWidget {
  final Widget? art;
  final String title;
  final String text;
  final Widget? extra;

  const _Page({this.art, required this.title, required this.text, this.extra});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 34, 40, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 58),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (art != null) ...[art!, const SizedBox(height: 22)],
                Text(title, textAlign: TextAlign.center, style: T.title.copyWith(fontSize: 26)),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Text(text, textAlign: TextAlign.center, style: T.body.copyWith(color: Pal.muted, height: 1.5)),
                ),
                if (extra != null) ...[const SizedBox(height: 22), extra!],
              ],
            ),
          ),
        ),
      );
}

/// Крупная иконка в цветном круге — там, где нет картинки.
class _IconArt extends StatelessWidget {
  final IconData icon;
  const _IconArt(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        height: 150,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Pal.purple, Pal.pink, Pal.yellow],
          ),
        ),
        child: Icon(icon, size: 68, color: const Color(0xFFFFFFFF)),
      );
}

/// Главные сочетания в две колонки: текущие пользовательские и встроенные.
class _ShortcutsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hotkeys = HotkeysScope.of(context);
    final fixed = fixedHotkeys;
    final rows = <(String, String)>[
      for (final a in const [HotkeyAction.search, HotkeyAction.newContact, HotkeyAction.settings, HotkeyAction.lock])
        (hotkeys.of(a).label, hotkeyLabel(a)),
      fixed[0],
      fixed[3],
      fixed[4],
      fixed[6],
    ];
    Widget row((String, String) r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(width: Os.isMac ? 70 : 120, child: Align(alignment: Alignment.centerLeft, child: KeyCaps(r.$1))),
              const SizedBox(width: 10),
              Expanded(child: Text(r.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.body)),
            ],
          ),
        );
    final half = (rows.length / 2).ceil();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        color: Pal.raised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Pal.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: [for (final r in rows.take(half)) row(r)])),
          const SizedBox(width: 20),
          Expanded(child: Column(children: [for (final r in rows.skip(half)) row(r)])),
        ],
      ),
    );
  }
}
