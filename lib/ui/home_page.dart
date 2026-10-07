import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../data/contact_store.dart';
import '../data/crypto.dart';
import '../models/contact.dart';
import 'avatar.dart';
import 'contact_detail.dart';
import 'contact_form.dart';
import 'contacts_grid.dart';
import 'contacts_table.dart';
import 'about.dart';
import 'dashboard.dart';
import 'data_actions.dart';
import 'field_editors.dart';
import 'hotkeys.dart';
import 'interests_panel.dart';
import 'onboarding.dart';
import 'schema_panel.dart';
import 'settings_page.dart';
import 'spotlight.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';
import 'platform.dart';

enum SortMode {
  nameAsc,
  nameDesc,
  newest,
  oldest,
  metRecent;

  String get label => switch (this) {
    SortMode.nameAsc => tr.sortNameAsc,
    SortMode.nameDesc => tr.sortNameDesc,
    SortMode.newest => tr.sortNewest,
    SortMode.oldest => tr.sortOldest,
    SortMode.metRecent => tr.sortMetRecent,
  };
}

enum ViewMode { list, grid }

/// Раздел приложения: главная или один из списков контактов.
enum Segment {
  dashboard(CupertinoIcons.house),
  all(CupertinoIcons.person_2),
  favorites(CupertinoIcons.star),
  birthdays(CupertinoIcons.gift),
  recent(CupertinoIcons.sparkles),
  trash(CupertinoIcons.trash),
  settings(CupertinoIcons.gear);

  final IconData icon;
  const Segment(this.icon);

  String get label => switch (this) {
    Segment.dashboard => tr.segDashboard,
    Segment.all => tr.segAll,
    Segment.favorites => tr.segFavorites,
    Segment.birthdays => tr.segBirthdays,
    Segment.recent => tr.segRecent,
    Segment.trash => tr.segTrash,
    Segment.settings => tr.settings,
  };

  /// Сочетание для перехода в раздел.
  HotkeyAction? get hotkey => switch (this) {
    Segment.dashboard => HotkeyAction.goDashboard,
    Segment.all => HotkeyAction.goContacts,
    Segment.favorites => HotkeyAction.goFavorites,
    Segment.birthdays => HotkeyAction.goBirthdays,
    Segment.recent => HotkeyAction.goRecent,
    Segment.trash => HotkeyAction.goTrash,
    Segment.settings => null,
  };

  bool test(Contact c, DateTime now) => switch (this) {
    Segment.favorites => c.favorite,
    Segment.recent => now.difference(c.createdAt).inDays < 30,
    Segment.birthdays => (c.daysUntilBirthday(now) ?? 999) <= 30,
    _ => true,
  };
}

class HomePage extends StatefulWidget {
  final ContactStore store;
  final Vault vault;
  final VoidCallback onLock;

  /// Показать знакомство: первый запуск, база только что создана.
  final bool onboarding;

  const HomePage({super.key, required this.store, required this.vault, required this.onLock, this.onboarding = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _listFocus = FocusNode(debugLabel: 'contacts');

  Segment _segment = Segment.dashboard;

  /// Фильтр по интересу; пустая строка — все.
  String _interest = '';
  SortMode _sort = SortMode.nameAsc;
  ViewMode _view = ViewMode.list;

  /// Выделение в порядке добавления; [_anchor] — опора для ⇧-клика.
  final LinkedHashSet<String> _selected = LinkedHashSet();
  String? _anchor;
  String? _lastTapId;
  DateTime _lastTapAt = DateTime(0);

  ContactStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      // Поиск всегда показывает список, даже если открыта главная.
      if (_search.text.isNotEmpty && {Segment.dashboard, Segment.settings}.contains(_segment)) _segment = Segment.all;
      setState(() {});
    });
    _listFocus.addListener(() => setState(() {}));
    // Горячие клавиши ловим на уровне клавиатуры, а не фокуса: так они
    // работают, где бы ни был фокус (например, после записи нового сочетания).
    HardwareKeyboard.instance.addHandler(_onHotkey);
    if (widget.onboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onboarding();
      });
    }
  }

  bool _onHotkey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted || Hotkeys.recording) return false;
    // Пока поверх открыто окно (редактор, поиск, знакомство), сочетания
    // главного окна не срабатывают.
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final hotkeys = HotkeysScope.read(context);
    final combo = Combo.fromEvent(e);
    for (final a in HotkeyAction.values) {
      if (hotkeys.of(a) != combo) continue;
      switch (a) {
        case HotkeyAction.search:
          _spotlight();
        case HotkeyAction.newContact:
          _create();
        case HotkeyAction.settings:
          _openSettings();
        case HotkeyAction.lock:
          widget.onLock();
        case HotkeyAction.goDashboard:
          _go(Segment.dashboard);
        case HotkeyAction.goContacts:
          _go(Segment.all);
        case HotkeyAction.goFavorites:
          _go(Segment.favorites);
        case HotkeyAction.goBirthdays:
          _go(Segment.birthdays);
        case HotkeyAction.goRecent:
          _go(Segment.recent);
        case HotkeyAction.goTrash:
          _go(Segment.trash);
      }
      return true;
    }
    return false;
  }

  SettingsSection _settingsSection = SettingsSection.general;

  void _openSettings([SettingsSection section = SettingsSection.general]) {
    _settingsSection = section;
    _go(Segment.settings);
  }

  Future<void> _onboarding() async {
    final result = await showOnboarding(context);
    if (mounted && result == OnboardingResult.openShortcuts) _openSettings(SettingsSection.shortcuts);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHotkey);
    _search.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    super.dispose();
  }

  // ── Данные ──

  List<Contact> get _source => _segment == Segment.trash ? store.trash : store.contacts;

  List<Contact> _filtered() {
    final now = DateTime.now();
    final q = _search.text.trim();
    final list = _source.where((c) {
      if (!_segment.test(c, now)) return false;
      if (_interest.isNotEmpty && !c.interests.contains(_interest)) return false;
      return q.isEmpty || c.matches(q);
    }).toList();

    if (_segment == Segment.trash) return list;
    if (_segment == Segment.birthdays) {
      list.sort((a, b) => a.daysUntilBirthday(now)!.compareTo(b.daysUntilBirthday(now)!));
      return list;
    }
    int byName(Contact a, Contact b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
    list.sort(switch (_sort) {
      SortMode.nameAsc => byName,
      SortMode.nameDesc => (a, b) => byName(b, a),
      SortMode.newest => (a, b) => b.createdAt.compareTo(a.createdAt),
      SortMode.oldest => (a, b) => a.createdAt.compareTo(b.createdAt),
      SortMode.metRecent => (a, b) {
        if (a.metDate == null) return b.metDate == null ? byName(a, b) : 1;
        if (b.metDate == null) return -1;
        return b.metDate!.compareTo(a.metDate!);
      },
    });
    return list;
  }

  // ── Навигация и выделение ──

  void _go(Segment s) => setState(() {
    _segment = s;
    _selected.clear();
    _anchor = null;
    _lastTapId = null;
    if (s == Segment.dashboard) _search.clear();
  });

  /// Открыть человека в общем списке — с дашборда.
  void _openContact(Contact c) => setState(() {
    _segment = Segment.all;
    _interest = '';
    _search.clear();
    _selected
      ..clear()
      ..add(c.id);
    _anchor = c.id;
  });

  /// Клик: обычный — один, ⌘ — добавить/убрать, ⇧ — диапазон, двойной — правка.
  void _tap(Contact c, List<Contact> visible, {bool toggle = false}) {
    _listFocus.requestFocus();
    final keys = HardwareKeyboard.instance;
    final now = DateTime.now();
    final isDouble = !toggle && _lastTapId == c.id && now.difference(_lastTapAt) < const Duration(milliseconds: 400);
    _lastTapId = c.id;
    _lastTapAt = now;
    if (isDouble && !Os.primaryPressed && !keys.isShiftPressed) {
      _lastTapId = null;
      _edit(c);
      return;
    }
    setState(() {
      if (toggle || Os.primaryPressed) {
        _selected.contains(c.id) ? _selected.remove(c.id) : _selected.add(c.id);
        _anchor = c.id;
      } else if (keys.isShiftPressed && _anchor != null) {
        final a = visible.indexWhere((x) => x.id == _anchor);
        final b = visible.indexWhere((x) => x.id == c.id);
        if (a != -1 && b != -1) {
          _selected
            ..clear()
            ..addAll([for (var i = a < b ? a : b; i <= (a < b ? b : a); i++) visible[i].id]);
        }
      } else {
        _selected
          ..clear()
          ..add(c.id);
        _anchor = c.id;
      }
    });
  }

  void _move(int delta, List<Contact> visible) {
    if (visible.isEmpty) return;
    final current = _anchor == null ? -1 : visible.indexWhere((x) => x.id == _anchor);
    final next = (current + delta).clamp(0, visible.length - 1);
    setState(() {
      _selected
        ..clear()
        ..add(visible[next].id);
      _anchor = visible[next].id;
    });
  }

  // ── Действия ──

  /// ⌘F — быстрый поиск; выбранный человек открывается отдельной
  /// карточкой поверх текущего экрана, вкладка при этом не меняется.
  Future<void> _spotlight() async {
    final c = await showSpotlight(context, store: store);
    if (c == null || !mounted) return;
    await showContactCard(context, store: store, contact: c, onEdit: _edit, onDelete: (c) => _trash({c.id}));
  }

  Future<void> _create() async {
    final c = await showContactEditor(context, store: store);
    if (c != null && mounted) _openContact(c);
  }

  Future<void> _edit(Contact c) async {
    if (!c.isDeleted) await showContactEditor(context, store: store, contact: c);
  }

  /// В корзину — без вопросов, зато с «Отменить».
  Future<void> _trash(Set<String> ids) async {
    if (ids.isEmpty) return;
    final single = ids.length == 1 ? store.byId(ids.first)?.name : null;
    await store.deleteMany(ids);
    setState(_selected.clear);
    showUndoToast(
      single != null ? tr.movedToTrashOne(single) : tr.movedToTrashMany(ids.length),
      onUndo: () => store.restore(ids),
    );
  }

  Future<void> _restore(Set<String> ids) async {
    await store.restore(ids);
    setState(_selected.clear);
    showUndoToast(tr.restoredMany(ids.length), onUndo: () => store.deleteMany(ids));
  }

  Future<void> _purge(Set<String> ids) async {
    if (ids.isEmpty) return;
    final ok = await confirmDialog(
      context,
      title: tr.purgeTitle(ids.length),
      message: tr.purgeMessage,
      confirmLabel: tr.delete,
      destructive: true,
    );
    if (!ok) return;
    await store.purge(ids);
    setState(_selected.clear);
  }

  Future<void> _export(List<Contact> contacts) => exportContacts(store, contacts);

  // ── Интерфейс ──

  @override
  Widget build(BuildContext context) {
    // Перестраиваемся, когда меняются сочетания: подсказки показывают их.
    HotkeysScope.of(context);
    return KeyedSubtree(
      // Фокус по умолчанию — для клавиш списка (стрелки, ⌫, Enter).
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final visibleIds = {for (final c in _source) c.id};
            _selected.removeWhere((id) => !visibleIds.contains(id));
            if (_interest.isNotEmpty && !store.allInterests.contains(_interest)) _interest = '';
            return ColoredBox(
              color: Pal.canvas,
              // Меньше этого интерфейс не сжимается — см. MainFlutterWindow.swift.
              child: MinSize(
                minWidth: 1080,
                minHeight: 480,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Rail(
                      segment: _segment,
                      trashCount: store.trash.length,
                      onSelect: _go,
                      onFields: () => showSchemaPanel(context, store: store),
                      onInterests: () => showInterestsPanel(context, store: store),
                      onSettings: _openSettings,
                      onLock: widget.onLock,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _topBar(),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              // Страницы занимают всю область, а не встают по центру.
                              layoutBuilder: (current, previous) =>
                                  Stack(fit: StackFit.expand, children: [...previous, ?current]),
                              child: switch (_segment) {
                                Segment.dashboard => Dashboard(
                                  key: const ValueKey('dashboard'),
                                  store: store,
                                  onSegment: _go,
                                ),
                                Segment.settings => SettingsPage(
                                  // Ключ по разделу: «Изменить сочетания» из знакомства
                                  // открывает нужный раздел, даже если настройки уже открыты.
                                  key: ValueKey('settings-${_settingsSection.name}'),
                                  store: store,
                                  vault: widget.vault,
                                  onLock: widget.onLock,
                                  onOnboarding: _onboarding,
                                  initialSection: _settingsSection,
                                ),
                                _ => KeyedSubtree(key: const ValueKey('contacts'), child: _contactsPage()),
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    final total = store.contacts.length;
    return SizedBox(
      height: 84,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 360,
                child: Field(
                  controller: _search,
                  focusNode: _searchFocus,
                  placeholder: tr.searchPlaceholder,
                  icon: CupertinoIcons.search,
                  radius: 22,
                  fill: Pal.searchFill,
                  suffix: _search.text.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            HotkeysScope.of(context).of(HotkeyAction.search).label,
                            style: T.tiny.copyWith(color: Pal.dim),
                          ),
                        )
                      : IconBtn(icon: CupertinoIcons.xmark, hint: tr.clear, size: 28, onPressed: _search.clear),
                ),
              ),
            ),
            Text(_segment == Segment.dashboard ? 'Orbit' : _segment.label, style: T.script),
            Align(
              alignment: Alignment.centerRight,
              child: Popover(
                width: 300,
                estimatedHeight: 360,
                alignRight: true,
                anchor: (context, toggle, open) => Pressable(
                  onTap: toggle,
                  builder: (context, hover, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(tr.personalBase, style: T.body.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(tr.people(total), style: T.small),
                        ],
                      ),
                      const SizedBox(width: 12),
                      ClipOval(child: Image.asset('assets/images/app_icon.png', width: 42, height: 42)),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 140),
                        child: Icon(CupertinoIcons.chevron_down, size: 16, color: hover ? Pal.text : Pal.muted),
                      ),
                    ],
                  ),
                ),
                content: (context, close) {
                  void run(VoidCallback action) {
                    close();
                    action();
                  }

                  return Menu(
                    maxHeight: 640,
                    children: [
                      MenuItem(
                        label: tr.menuImport,
                        icon: CupertinoIcons.tray_arrow_down,
                        onTap: () => run(() => importContacts(context, store)),
                      ),
                      MenuItem(
                        label: tr.exportCsv,
                        icon: CupertinoIcons.tray_arrow_up,
                        onTap: () => run(() => _export(store.contacts)),
                      ),
                      const MenuDivider(),
                      MenuItem(
                        label: tr.menuBackup,
                        icon: CupertinoIcons.lock_shield,
                        onTap: () => run(() => createBackup(context, store, widget.vault)),
                      ),
                      MenuItem(
                        label: tr.menuRestore,
                        icon: CupertinoIcons.arrow_counterclockwise,
                        onTap: () => run(() => restoreBackup(context, store)),
                      ),
                      const MenuDivider(),
                      MenuItem(
                        label: tr.menuSettings,
                        icon: CupertinoIcons.gear,
                        trailing: Text(HotkeysScope.of(context).of(HotkeyAction.settings).label, style: T.small),
                        onTap: () => run(_openSettings),
                      ),
                      MenuItem(
                        label: tr.lock,
                        icon: CupertinoIcons.lock,
                        trailing: Text(HotkeysScope.of(context).of(HotkeyAction.lock).label, style: T.small),
                        onTap: () => run(widget.onLock),
                      ),
                      const MenuDivider(),
                      MenuItem(
                        label: tr.about,
                        icon: CupertinoIcons.info_circle,
                        onTap: () => run(() => showAbout(context)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Список контактов ──

  Widget _contactsPage() {
    final filtered = _filtered();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Panel(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _listHeader(filtered),
                  const SizedBox(height: 18),
                  Expanded(child: _listBody(filtered)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 380,
            child: Panel(padding: EdgeInsets.zero, child: _detail()),
          ),
        ],
      ),
    );
  }

  Widget _listHeader(List<Contact> filtered) {
    final interests = store.interestCounts;
    final filters = [
      if (_segment != Segment.trash && interests.isNotEmpty)
        Dropdown<String>(
          value: _interest,
          icon: CupertinoIcons.line_horizontal_3_decrease,
          width: 240,
          height: 38,
          items: [('', tr.allInterests), for (final e in interests) (e.key, '${e.key} · ${e.value}')],
          onChanged: (v) => setState(() => _interest = v),
        ),
      if (_segment != Segment.birthdays && _segment != Segment.trash)
        Dropdown<SortMode>(
          value: _sort,
          icon: CupertinoIcons.arrow_up_arrow_down,
          width: 240,
          height: 38,
          items: [for (final s in SortMode.values) (s, s.label)],
          onChanged: (v) => setState(() => _sort = v),
        ),
      if (_segment != Segment.trash)
        IconBtn(
          icon: CupertinoIcons.tag,
          hint: tr.interestsHint,
          filled: true,
          size: 38,
          onPressed: () => showInterestsPanel(context, store: store),
        ),
      if (_view == ViewMode.list) ColumnsButton(store: store),
      if (_segment == Segment.trash && store.trash.isNotEmpty)
        Btn(
          label: tr.emptyTrash,
          icon: CupertinoIcons.trash,
          kind: BtnKind.danger,
          small: true,
          onPressed: () => _purge({for (final c in store.trash) c.id}),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titleRow(filtered),
        if (filters.isNotEmpty) ...[
          const SizedBox(height: 14),
          // Переносится на вторую строку, если окно узкое.
          Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: filters),
        ],
      ],
    );
  }

  Widget _titleRow(List<Contact> filtered) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(_segment.label, overflow: TextOverflow.ellipsis, style: T.title.copyWith(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Tag('${filtered.length}', color: Pal.accent),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconBtn(
          icon: CupertinoIcons.list_bullet,
          hint: tr.viewTable,
          filled: true,
          size: 42,
          active: _view == ViewMode.list,
          onPressed: () => setState(() => _view = ViewMode.list),
        ),
        const SizedBox(width: 6),
        IconBtn(
          icon: CupertinoIcons.square_grid_2x2,
          hint: tr.viewCards,
          filled: true,
          size: 42,
          active: _view == ViewMode.grid,
          onPressed: () => setState(() => _view = ViewMode.grid),
        ),
        // В избранных и в корзине новый контакт не создают.
        if (_segment != Segment.favorites && _segment != Segment.trash) ...[
          const SizedBox(width: 10),
          Btn.primary(label: tr.newShort, icon: CupertinoIcons.plus, onPressed: _create),
        ],
      ],
    );
  }

  Widget _emptyArt(String asset, {double width = 150}) => Image.asset(
    asset,
    width: width,
    height: 150,
    cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
  );

  Widget _listBody(List<Contact> filtered) {
    final Widget body;
    // У корзины и разделов с карточек свои картинки, даже когда база пуста.
    if (store.contacts.isEmpty &&
        !{Segment.trash, Segment.favorites, Segment.recent, Segment.birthdays}.contains(_segment)) {
      body = EmptyState(
        image: Image.asset('assets/images/logo.png', width: 120, height: 120),
        title: tr.noContactsTitle,
        subtitle: tr.noContactsSubtitle,
        action: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            Btn(
              label: tr.importShort,
              icon: CupertinoIcons.tray_arrow_down,
              onPressed: () => importContacts(context, store),
            ),
            Btn.primary(label: tr.newContact, icon: CupertinoIcons.plus, onPressed: _create),
          ],
        ),
      );
    } else if (filtered.isEmpty) {
      final q = _search.text.trim();
      body = q.isNotEmpty
          ? EmptyState(icon: CupertinoIcons.search, title: tr.nothingFound, subtitle: tr.nothingFoundFor(q))
          : _segment == Segment.trash
          ? EmptyState(
              image: _emptyArt('assets/images/empty_trash.png'),
              title: tr.trashEmpty,
              subtitle: tr.trashEmptySubtitle(ContactStore.trashDays),
            )
          : _segment == Segment.favorites
          ? EmptyState(
              image: _emptyArt('assets/images/empty_favorites.png'),
              title: tr.favoritesEmpty,
              subtitle: tr.favoritesEmptySubtitle,
            )
          : _segment == Segment.recent
          ? EmptyState(
              image: _emptyArt('assets/images/card_new.png'),
              title: tr.recentEmpty,
              subtitle: tr.recentEmptySubtitle,
            )
          : _segment == Segment.birthdays
          ? EmptyState(
              image: _emptyArt('assets/images/card_birthdays.png', width: 220),
              title: tr.birthdaysEmpty,
              subtitle: tr.birthdaysEmptySubtitle,
            )
          : EmptyState(icon: _segment.icon, title: tr.segmentEmpty, subtitle: tr.segmentEmptySubtitle);
    } else if (_view == ViewMode.list) {
      body = ContactsTable(
        contacts: filtered,
        store: store,
        selected: _selected,
        sort: _segment == Segment.birthdays || _segment == Segment.trash ? null : _sort,
        onSort: (s) => setState(() => _sort = s),
        onTap: (c) => _tap(c, filtered),
        onToggle: (c) => _tap(c, filtered, toggle: true),
        onToggleAll: (all) => setState(() {
          all ? _selected.addAll(filtered.map((c) => c.id)) : _selected.clear();
        }),
        onAddColumn: () => showFieldDialog(context, store: store, showInTable: true),
        onEditColumn: (f) => showFieldDialog(context, store: store, field: f),
      );
    } else {
      body = ContactsGrid(contacts: filtered, store: store, selected: _selected, onTap: (c) => _tap(c, filtered));
    }
    return Focus(focusNode: _listFocus, onKeyEvent: (node, e) => _onListKey(e, filtered), child: body);
  }

  KeyEventResult _onListKey(KeyEvent e, List<Contact> visible) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowRight) {
      _move(1, visible);
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowLeft) {
      _move(-1, visible);
    } else if (key == LogicalKeyboardKey.keyA && Os.primaryPressed) {
      setState(() => _selected.addAll(visible.map((c) => c.id)));
    } else if (key == LogicalKeyboardKey.escape) {
      setState(_selected.clear);
    } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      if (e is KeyDownEvent) _segment == Segment.trash ? _purge({..._selected}) : _trash({..._selected});
    } else if (key == LogicalKeyboardKey.enter && _selected.length == 1) {
      if (store.byId(_selected.first) case final c?) _edit(c);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _detail() {
    final selected = [for (final id in _selected) ?store.byId(id)];
    if (selected.isEmpty) {
      return EmptyState(
        icon: CupertinoIcons.person_crop_circle,
        title: tr.noSelectionTitle,
        subtitle: tr.noSelectionSubtitle(Os.mod, Os.shift),
      );
    }
    if (selected.length == 1) {
      final c = selected.single;
      return ContactDetail(
        key: ValueKey(c.id),
        contact: c,
        store: store,
        onEdit: () => _edit(c),
        onDelete: () => _trash({c.id}),
        onRestore: () => _restore({c.id}),
        onPurge: () => _purge({c.id}),
      );
    }
    return _BulkPane(
      contacts: selected,
      store: store,
      inTrash: _segment == Segment.trash,
      onFavorite: (v) => store.setFavorite({..._selected}, v),
      onExport: () => _export(selected),
      onTrash: () => _trash({..._selected}),
      onRestore: () => _restore({..._selected}),
      onPurge: () => _purge({..._selected}),
    );
  }
}

/// Узкая панель слева: логотип и разделы иконками.
class _Rail extends StatelessWidget {
  final Segment segment;
  final int trashCount;
  final ValueChanged<Segment> onSelect;
  final VoidCallback onFields;
  final VoidCallback onInterests;
  final VoidCallback onSettings;
  final VoidCallback onLock;

  const _Rail({
    required this.segment,
    required this.trashCount,
    required this.onSelect,
    required this.onFields,
    required this.onInterests,
    required this.onSettings,
    required this.onLock,
  });

  /// Пункты сверху (разделы) и снизу (интересы, поля, настройки, замок).
  static const _items = 10;

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    decoration: BoxDecoration(
      color: Pal.rail,
      // В светлой теме панель и фон белые — отделяем линией.
      border: Pal.isDark ? null : Border(right: BorderSide(color: Pal.divider)),
    ),
    child: LayoutBuilder(
      builder: (context, c) {
        // Пункты сжимаются вместе с окном. А если места не хватает даже
        // на сжатые (окно резко тянут), панель прокручивается — так
        // переполнения нет при любом размере, без точных подсчётов.
        const fixed = 40 + 50 + 16 + 16 + 24;
        final itemHeight = ((c.maxHeight - fixed) / _items).clamp(40.0, 64.0);
        return CustomScrollView(
          slivers: [SliverFillRemaining(hasScrollBody: false, child: _column(context, itemHeight))],
        );
      },
    ),
  );

  Widget _column(BuildContext context, double itemHeight) {
    Widget item(IconData icon, String hint, {required bool active, required VoidCallback onTap, int badge = 0}) =>
        Pressable(
          onTap: onTap,
          hint: hint,
          // Панель у края окна — подсказка справа, а не снизу.
          hintSide: HintSide.right,
          builder: (context, hover, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 84,
            height: itemHeight,
            decoration: BoxDecoration(
              color: active ? Pal.railActive : null,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: itemHeight < 52 ? 21 : 24,
                  color: active ? Pal.railActiveIcon : (hover ? Pal.text : Pal.muted),
                ),
                if (badge > 0)
                  Positioned(
                    top: itemHeight / 2 - 14,
                    right: 26,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: Pal.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        );

    return Column(
      children: [
        // На Mac — место под кнопки окна: они поверх содержимого.
        SizedBox(height: Os.isMac ? 40 : 16),
        Pressable(
          onTap: () => showAbout(context),
          hint: tr.about,
          hintSide: HintSide.right,
          builder: (context, _, _) => Image.asset('assets/images/logo.png', width: 50, height: 50),
        ),
        const SizedBox(height: 16),
        for (final s in Segment.values)
          if (s != Segment.settings)
            item(
              s.icon,
              '${s.label} (${HotkeysScope.of(context).of(s.hotkey!).label})',
              active: segment == s,
              onTap: () => onSelect(s),
              badge: s == Segment.trash ? trashCount : 0,
            ),
        // Spacer прижимает нижние пункты вниз, но не меньше 24 точек.
        const SizedBox(height: 24),
        const Spacer(),
        item(CupertinoIcons.tag, tr.interests, active: false, onTap: onInterests),
        item(CupertinoIcons.slider_horizontal_3, tr.fieldsAndSections, active: false, onTap: onFields),
        item(
          CupertinoIcons.gear,
          '${tr.settings} (${HotkeysScope.of(context).of(HotkeyAction.settings).label})',
          active: segment == Segment.settings,
          onTap: onSettings,
        ),
        item(
          CupertinoIcons.lock,
          '${tr.lock} (${HotkeysScope.of(context).of(HotkeyAction.lock).label})',
          active: false,
          onTap: onLock,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Несколько выбранных контактов: общие действия.
class _BulkPane extends StatelessWidget {
  final List<Contact> contacts;
  final ContactStore store;
  final bool inTrash;
  final ValueChanged<bool> onFavorite;
  final VoidCallback onExport;
  final VoidCallback onTrash;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  const _BulkPane({
    required this.contacts,
    required this.store,
    required this.inTrash,
    required this.onFavorite,
    required this.onExport,
    required this.onTrash,
    required this.onRestore,
    required this.onPurge,
  });

  @override
  Widget build(BuildContext context) {
    final allFavorite = contacts.every((c) => c.favorite);
    final shown = contacts.take(5).toList();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52.0 + (shown.length - 1) * 32,
              height: 52,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * 32.0,
                      child: ContactAvatar(
                        name: shown[i].name,
                        photo: store.photoOf(shown[i]),
                        radius: 24,
                        ring: Pal.card,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(tr.selectedCount(contacts.length), style: T.title),
            const SizedBox(height: 22),
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: inTrash
                    ? [
                        Btn.primary(
                          label: tr.restore,
                          icon: CupertinoIcons.arrow_counterclockwise,
                          onPressed: onRestore,
                        ),
                        const SizedBox(height: 10),
                        Btn(
                          label: tr.deleteForever,
                          icon: CupertinoIcons.trash,
                          kind: BtnKind.danger,
                          onPressed: onPurge,
                        ),
                      ]
                    : [
                        Btn(
                          label: allFavorite ? tr.removeFromFavorites : tr.toFavorites,
                          icon: allFavorite ? CupertinoIcons.star_slash : CupertinoIcons.star,
                          onPressed: () => onFavorite(!allFavorite),
                        ),
                        const SizedBox(height: 10),
                        Btn(label: tr.exportCsv, icon: CupertinoIcons.tray_arrow_up, onPressed: onExport),
                        const SizedBox(height: 10),
                        Btn(label: tr.toTrash, icon: CupertinoIcons.trash, kind: BtnKind.danger, onPressed: onTrash),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
