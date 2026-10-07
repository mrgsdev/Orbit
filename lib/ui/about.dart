import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

const developerGithub = 'https://github.com/mrgsdev';

/// На случай, если версию не удалось прочитать из сборки. Держать в
/// согласии с `version` в pubspec.yaml.
const _fallbackVersion = '1.0.0';

/// Версия вида «v1.0.0» — из собранного приложения.
Future<String> appVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version}';
  } catch (_) {
    return 'v$_fallbackVersion';
  }
}

/// Макет, которым вдохновлён интерфейс, — указываем по условиям CC BY 4.0.
const designTitle = 'Sales Dashboard';
const designAuthor = 'Nickelfox Design';
const designUrl = 'https://www.figma.com/community/file/1205079775966639114';
const designLicense = 'CC BY 4.0';
const designLicenseUrl = 'https://creativecommons.org/licenses/by/4.0/';

/// Окно «О приложении»: версия, разработчик и благодарности.
Future<void> showAbout(BuildContext context) => showModal<void>(context, builder: (_) => const _About());

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop();
    return ModalScaffold(
      title: tr.about,
      width: 500,
      onCancel: close,
      onSubmit: close,
      actions: [Btn.primary(label: tr.done, onPressed: close)],
      children: [
        const AboutContent(),
      ],
    );
  }
}

/// Логотип, версия, разработчик и благодарности — в окне «О приложении»
/// и в настройках.
class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Image.asset('assets/images/logo.png', width: 110, height: 110)),
          Center(child: Text('Orbit', style: T.script.copyWith(fontSize: 36))),
          const SizedBox(height: 4),
          Center(
            child: FutureBuilder(
              future: appVersion(),
              builder: (context, snap) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Pal.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                child: Text(snap.data ?? 'v$_fallbackVersion', style: T.body.copyWith(color: Pal.accentText, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text(tr.tagline, style: T.small)),
          const SizedBox(height: 24),
          _Block(
            icon: CupertinoIcons.chevron_left_slash_chevron_right,
            title: tr.developer,
            children: [
              Text('mrgsdev', style: T.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              LinkBtn(label: 'github.com/mrgsdev', icon: CupertinoIcons.arrow_up_right_square, onPressed: () => launchUrl(Uri.parse(developerGithub))),
            ],
          ),
          const SizedBox(height: 12),
          _Block(
            icon: CupertinoIcons.paintbrush,
            title: tr.design,
            children: [
              Text(
                tr.designCredit(designTitle, designAuthor),
                style: T.body.copyWith(height: 1.45),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                children: [
                  LinkBtn(label: tr.figmaLayout, icon: CupertinoIcons.arrow_up_right_square, onPressed: () => launchUrl(Uri.parse(designUrl))),
                  LinkBtn(label: tr.license(designLicense), icon: CupertinoIcons.doc_text, onPressed: () => launchUrl(Uri.parse(designLicenseUrl))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Block(
            icon: CupertinoIcons.textformat,
            title: tr.fonts,
            children: [
              Text(tr.fontsLicense, style: T.body.copyWith(height: 1.45)),
            ],
          ),
        ],
      );
}

class _Block extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Block({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: Pal.raised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Pal.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: Pal.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: Pal.accentText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: T.tiny.copyWith(letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      );
}
