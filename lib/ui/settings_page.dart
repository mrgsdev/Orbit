import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../data/contact_store.dart';
import '../data/crypto.dart';
import '../l10n/strings.dart';
import 'about.dart';
import 'appearance.dart';
import 'data_actions.dart';
import 'hotkeys.dart';
import 'interests_panel.dart';
import 'language.dart';
import 'schema_panel.dart';
import 'theme.dart';
import 'widgets.dart';
import 'platform.dart';

enum SettingsSection {
  general(CupertinoIcons.gear),
  shortcuts(CupertinoIcons.keyboard),
  contacts(CupertinoIcons.person_2),
  security(CupertinoIcons.lock_shield),
  data(CupertinoIcons.tray_2),
  about(CupertinoIcons.info_circle);

  final IconData icon;
  const SettingsSection(this.icon);

  String get label => switch (this) {
        SettingsSection.general => tr.settingsGeneral,
        SettingsSection.shortcuts => tr.settingsShortcuts,
        SettingsSection.contacts => tr.segAll,
        SettingsSection.security => tr.settingsSecurity,
        SettingsSection.data => tr.settingsData,
        SettingsSection.about => tr.about,
      };
}

/// Вкладка «Настройки»: разделы слева, строки с действиями справа —
/// как в «Системных настройках» macOS.
class SettingsPage extends StatefulWidget {
  final ContactStore store;
  final Vault vault;
  final VoidCallback onLock;
  final SettingsSection initialSection;

  /// Показать знакомство с приложением ещё раз.
  final VoidCallback onOnboarding;

  const SettingsPage({
    super.key,
    required this.store,
    required this.vault,
    required this.onLock,
    required this.onOnboarding,
    this.initialSection = SettingsSection.general,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsSection _section = widget.initialSection;

  ContactStore get store => widget.store;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 240,
              child: Panel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in SettingsSection.values)
                      _NavItem(section: s, active: s == _section, onTap: () => setState(() => _section = s)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Panel(
                padding: EdgeInsets.zero,
                child: ScrollArea(
                  builder: (controller) => SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                    child: ListenableBuilder(
                      listenable: store,
                      builder: (context, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_section.label, style: T.title.copyWith(fontSize: 22)),
                          const SizedBox(height: 18),
                          ..._content(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  List<Widget> _content(BuildContext context) => switch (_section) {
        SettingsSection.general => [
            _Group([
              _Row(
                icon: CupertinoIcons.globe,
                title: tr.language,
                hint: tr.languageHint,
                trailing: const LanguageDropdown(),
              ),
              _Row(
                icon: CupertinoIcons.circle_lefthalf_fill,
                title: tr.appearance,
                hint: tr.appearanceHint,
                trailing: const SizedBox(width: 320, child: ThemeSwitch(showLabel: false)),
              ),
            ]),
            const SizedBox(height: 16),
            _Group([
              _Row(
                icon: CupertinoIcons.sparkles,
                title: tr.onbRow,
                hint: tr.onbRowHint,
                trailing: Btn(label: tr.showEllipsis, small: true, onPressed: widget.onOnboarding),
              ),
            ]),
          ],
        SettingsSection.shortcuts => _shortcuts(context),
        SettingsSection.contacts => [
            _Group([
              _Row(
                icon: CupertinoIcons.tag,
                title: tr.interests,
                hint: '${tr.interestsCount(store.allInterests.length)} · ${tr.interestsRowHint}',
                trailing: Btn(label: tr.configureEllipsis, small: true, onPressed: () => showInterestsPanel(context, store: store)),
              ),
              _Row(
                icon: CupertinoIcons.slider_horizontal_3,
                title: tr.fieldsAndSections,
                hint: tr.fieldsRowHint,
                trailing: Btn(label: tr.configureEllipsis, small: true, onPressed: () => showSchemaPanel(context, store: store)),
              ),
            ]),
            const SizedBox(height: 16),
            _Group([
              _Row(
                icon: CupertinoIcons.trash,
                title: tr.segTrash,
                hint: tr.trashRowHint(ContactStore.trashDays),
                trailing: store.trash.isEmpty
                    ? Text(tr.trashEmpty, style: T.small)
                    : Btn(label: tr.emptyTrash, kind: BtnKind.danger, small: true, onPressed: () => _emptyTrash(context)),
              ),
            ]),
          ],
        SettingsSection.security => [
            _Group([
              _Row(
                icon: CupertinoIcons.lock_rotation,
                title: tr.pinRow,
                hint: tr.pinRowHint,
                trailing: Btn(label: tr.changeEllipsis, small: true, onPressed: () => changePin(context, store, widget.vault)),
              ),
              _Row(
                icon: CupertinoIcons.eye,
                title: tr.recoveryRow,
                hint: tr.recoveryRowHint,
                trailing: Btn(label: tr.showEllipsis, small: true, onPressed: () => showRecoveryCode(context, store, widget.vault)),
              ),
              _Row(
                icon: CupertinoIcons.lock,
                title: tr.lockNow,
                hint: tr.lockRowHint(HotkeysScope.of(context).of(HotkeyAction.lock).label),
                trailing: Btn(label: tr.lock, small: true, onPressed: widget.onLock),
              ),
            ]),
          ],
        SettingsSection.data => [
            _Group([
              _Row(
                icon: CupertinoIcons.tray_arrow_down,
                title: tr.menuImport.replaceAll('…', ''),
                hint: tr.importRowHint,
                trailing: Btn(label: tr.importShort, small: true, onPressed: () => importContacts(context, store)),
              ),
              _Row(
                icon: CupertinoIcons.tray_arrow_up,
                title: tr.exportCsv.replaceAll('…', ''),
                hint: tr.exportRowHint,
                trailing: Btn(label: tr.exportEllipsis, small: true, onPressed: () => exportContacts(store, store.contacts)),
              ),
            ]),
            const SizedBox(height: 16),
            _Group([
              _Row(
                icon: CupertinoIcons.lock_shield,
                title: tr.backupRow,
                hint: tr.backupRowHint,
                trailing: Btn(label: tr.createEllipsis, small: true, onPressed: () => createBackup(context, store, widget.vault)),
              ),
              _Row(
                icon: CupertinoIcons.arrow_counterclockwise,
                title: tr.restoreRow,
                hint: tr.restoreRowHint,
                trailing: Btn(label: tr.restoreEllipsis, small: true, onPressed: () => restoreBackup(context, store)),
              ),
            ]),
            const SizedBox(height: 16),
            _Group([
              _Row(
                icon: CupertinoIcons.folder,
                title: tr.appFolder,
                hint: store.rootDir.path,
                trailing: Btn(label: Os.showFolderLabel, small: true, onPressed: () => openAppFolder(store)),
              ),
            ]),
          ],
        SettingsSection.about => [const AboutContent()],
      };

  List<Widget> _shortcuts(BuildContext context) {
    final hotkeys = HotkeysScope.of(context);
    IconData icon(HotkeyAction a) => switch (a) {
          HotkeyAction.search => CupertinoIcons.search,
          HotkeyAction.newContact => CupertinoIcons.person_add,
          HotkeyAction.settings => CupertinoIcons.gear,
          HotkeyAction.lock => CupertinoIcons.lock,
          HotkeyAction.goDashboard => CupertinoIcons.house,
          HotkeyAction.goContacts => CupertinoIcons.person_2,
          HotkeyAction.goFavorites => CupertinoIcons.star,
          HotkeyAction.goBirthdays => CupertinoIcons.gift,
          HotkeyAction.goRecent => CupertinoIcons.sparkles,
          HotkeyAction.goTrash => CupertinoIcons.trash,
        };
    return [
      Text(tr.shortcutsIntro, style: T.small),
      const SizedBox(height: 14),
      _Group([
        for (final a in HotkeyAction.values)
          _Row(icon: icon(a), title: hotkeyLabel(a), trailing: _HotkeyEditor(action: a, hotkeys: hotkeys)),
      ]),
      if (hotkeys.anyCustom) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: LinkBtn(label: tr.resetAll, icon: CupertinoIcons.arrow_counterclockwise, onPressed: hotkeys.resetAll),
        ),
      ],
      const SizedBox(height: 22),
      Text(tr.shortcutsFixed.toUpperCase(), style: T.tiny.copyWith(letterSpacing: 0.8)),
      const SizedBox(height: 10),
      _Group([
        for (final (keys, label) in fixedHotkeys)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text(label, style: T.body)),
                KeyCaps(keys),
              ],
            ),
          ),
      ]),
    ];
  }

  Future<void> _emptyTrash(BuildContext context) async {
    final ids = {for (final c in store.trash) c.id};
    final ok = await confirmDialog(
      context,
      title: tr.purgeTitle(ids.length),
      message: tr.purgeMessage,
      confirmLabel: tr.delete,
      destructive: true,
    );
    if (ok) await store.purge(ids);
  }
}

class _NavItem extends StatelessWidget {
  final SettingsSection section;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.section, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        pressScale: 0.99,
        builder: (context, hover, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 42,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? Pal.accent : (hover ? Pal.hover : null),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(section.icon, size: 17, color: active ? Pal.onAccent : Pal.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.body.copyWith(color: active ? Pal.onAccent : Pal.text, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Блок строк с разделителями, как группа в «Системных настройках».
class _Group extends StatelessWidget {
  final List<Widget> rows;
  const _Group(this.rows);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Pal.raised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Pal.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Container(height: 1, margin: const EdgeInsets.only(left: 66), color: Pal.border),
              rows[i],
            ],
          ],
        ),
      );
}

/// Строка настройки: иконка, название с пояснением и действие справа.
class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Widget trailing;

  const _Row({required this.icon, required this.title, this.hint, required this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: Pal.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: Pal.accentText),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: T.body.copyWith(fontWeight: FontWeight.w600)),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(hint!, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.small),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            trailing,
          ],
        ),
      );
}

/// Текущее сочетание и запись нового: «Изменить» → нажать клавиши.
class _HotkeyEditor extends StatefulWidget {
  final HotkeyAction action;
  final Hotkeys hotkeys;
  const _HotkeyEditor({required this.action, required this.hotkeys});

  @override
  State<_HotkeyEditor> createState() => _HotkeyEditorState();
}

class _HotkeyEditorState extends State<_HotkeyEditor> {
  final _focus = FocusNode(debugLabel: 'hotkey-recorder');
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    // Ушёл фокус (клик мимо) — запись отменяется.
    _focus.addListener(() {
      if (!_focus.hasFocus && _recording) {
        Hotkeys.recording = false;
        setState(() => _recording = false);
      }
    });
  }

  @override
  void dispose() {
    if (_recording) Hotkeys.recording = false;
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    Hotkeys.recording = true;
    setState(() => _recording = true);
    _focus.requestFocus();
  }

  void _stop() {
    Hotkeys.recording = false;
    setState(() => _recording = false);
    // Фокус возвращается туда, где был, — к главному окну.
    _focus.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (!_recording) return KeyEventResult.ignored;
    if (e is! KeyDownEvent) return KeyEventResult.handled;
    if (Combo.isModifierKey(e.logicalKey)) return KeyEventResult.handled;
    final combo = Combo.fromEvent(e);
    if (e.logicalKey == LogicalKeyboardKey.escape && !combo.hasModifier) {
      _stop();
      return KeyEventResult.handled;
    }
    if (!combo.hasModifier && !combo.isFunctionKey) {
      showToast(Os.isMac ? tr.needModifier('⌘, ⌃', '⌥') : tr.needModifier('Ctrl', 'Alt'));
    } else if (reservedCombos.contains(combo)) {
      showToast(tr.reservedCombo(combo.label));
    } else if (widget.hotkeys.usedBy(combo, except: widget.action) case final other?) {
      showToast(tr.comboInUse(combo.label, hotkeyLabel(other)));
    } else {
      widget.hotkeys.set(widget.action, combo);
      _stop();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.hotkeys.of(widget.action);
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.hotkeys.isCustom(widget.action) && !_recording) ...[
            IconBtn(
              icon: CupertinoIcons.arrow_counterclockwise,
              hint: tr.resetDefault,
              size: 30,
              onPressed: () => widget.hotkeys.reset(widget.action),
            ),
            const SizedBox(width: 8),
          ],
          if (_recording)
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Pal.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Pal.accent),
              ),
              child: Text(tr.pressKeys, style: T.small.copyWith(color: Pal.accentText, fontWeight: FontWeight.w600)),
            )
          else
            KeyCaps(combo.label),
          const SizedBox(width: 10),
          Btn(
            label: _recording ? tr.cancel : tr.changeShort,
            small: true,
            onPressed: _recording ? _stop : _start,
          ),
        ],
      ),
    );
  }
}
