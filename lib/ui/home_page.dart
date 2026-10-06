import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/contact_store.dart';
import '../data/crypto.dart';
import '../data/csv_export.dart';
import '../models/contact.dart';
import 'avatar.dart';
import 'contact_panel.dart';
import 'contacts_grid.dart';
import 'contacts_table.dart';
import 'data_actions.dart';
import 'field_editors.dart';
import 'pagination.dart';
import 'schema_panel.dart';
import 'sidebar.dart';
import 'theme.dart';
import 'widgets.dart';

enum SortMode {
  nameAsc('Имя: А → Я', Icons.sort_by_alpha),
  nameDesc('Имя: Я → А', Icons.sort_by_alpha),
  newest('Сначала новые', Icons.schedule),
  oldest('Сначала старые', Icons.history),
  metRecent('Недавние знакомства', Icons.handshake_outlined);

  final String label;
  final IconData icon;
  const SortMode(this.label, this.icon);
}

enum ViewMode {
  table('Таблица', Icons.table_rows_outlined),
  cards('Карточки', Icons.grid_view_rounded);

  final String label;
  final IconData icon;
  const ViewMode(this.label, this.icon);
}

class HomePage extends StatefulWidget {
  final ContactStore store;
  final Vault vault;
  final VoidCallback onLock;

  const HomePage({super.key, required this.store, required this.vault, required this.onLock});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  Segment _segment = Segment.all;
  final Set<String> _interests = {};
  SortMode _sort = SortMode.nameAsc;
  ViewMode _view = ViewMode.table;
  bool _showStats = true;
  int _page = 0;
  int _pageSize = 10;
  final Set<String> _selected = {};

  ContactStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _page = 0));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Contact> _filtered() {
    final now = DateTime.now();
    final q = _search.text.trim();
    final list = _source.where((c) {
      if (!_segment.test(c, now)) return false;
      if (_interests.isNotEmpty && !_interests.every(c.interests.contains)) return false;
      return q.isEmpty || c.matches(q);
    }).toList();

    // Корзина уже упорядочена: сначала недавно удалённые.
    if (_segment == Segment.trash) return list;

    // В разделе дней рождения важнее всего, чей праздник ближе.
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

  /// Контакты текущего раздела: корзина или активные.
  List<Contact> get _source => _segment == Segment.trash ? store.trash : store.contacts;

  void _resetFilters() => setState(() {
        _segment = Segment.all;
        _interests.clear();
        _search.clear();
        _page = 0;
      });

  Future<void> _open(Contact c) => showContactPanel(context, store: store, contact: c);

  Future<void> _create() => showContactPanel(context, store: store);

  Future<void> _export(List<Contact> contacts) async {
    if (contacts.isEmpty) {
      showToast(context, 'Нечего экспортировать');
      return;
    }
    try {
      if (await exportContactsCsv(contacts, store.allFields.toList()) && mounted) {
        showToast(context,
            'Сохранено: ${contacts.length} ${plural(contacts.length, 'контакт', 'контакта', 'контактов')}');
      }
    } catch (e) {
      if (mounted) showToast(context, 'Не удалось сохранить файл: $e');
    }
  }

  /// Из списка — в корзину, с возможностью сразу отменить.
  Future<void> _deleteSelected() async {
    final ids = {..._selected};
    await store.deleteMany(ids);
    setState(_selected.clear);
    showUndoToast(
      'В корзине: ${ids.length} ${plural(ids.length, 'контакт', 'контакта', 'контактов')}',
      onUndo: () => store.restore(ids),
    );
  }

  Future<void> _restoreSelected() async {
    final ids = {..._selected};
    await store.restore(ids);
    setState(_selected.clear);
    showUndoToast(
      'Восстановлено: ${ids.length} ${plural(ids.length, 'контакт', 'контакта', 'контактов')}',
      onUndo: () => store.deleteMany(ids),
    );
  }

  Future<void> _purge(Set<String> ids) async {
    final n = ids.length;
    final ok = await confirmDialog(
      context,
      title: 'Удалить навсегда $n ${plural(n, 'контакт', 'контакта', 'контактов')}?',
      message: 'Контакты и их фото будут удалены без возможности восстановления.',
      confirmLabel: 'Удалить навсегда',
      destructive: true,
    );
    if (!ok) return;
    await store.purge(ids);
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _create,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _create,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _searchFocus.requestFocus,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              // В выделении — только контакты текущего раздела.
              final visible = {for (final c in _source) c.id};
              _selected.removeWhere((id) => !visible.contains(id));
              _interests.removeWhere((i) => !store.allInterests.contains(i));
              return Row(
                children: [
                  SizedBox(
                    width: 268,
                    child: Sidebar(
                      store: store,
                      segment: _segment,
                      onSegment: (s) => setState(() {
                        _segment = s;
                        _page = 0;
                      }),
                      interests: _interests,
                      onToggleInterest: (i) => setState(() {
                        _interests.contains(i) ? _interests.remove(i) : _interests.add(i);
                        _page = 0;
                      }),
                      search: _search,
                      searchFocus: _searchFocus,
                      onExport: () => _export(store.contacts),
                      onEditFields: () => showSchemaPanel(context, store: store),
                      onImport: () => importContacts(context, store),
                      onBackup: () => createBackup(context, store, widget.vault),
                      onRestore: () => restoreBackup(context, store),
                      onChangePin: () => changePin(context, store, widget.vault),
                      onLock: widget.onLock,
                    ),
                  ),
                  Expanded(child: _main()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _main() {
    final c = context.colors;
    final filtered = _filtered();
    final pageCount = (filtered.length / _pageSize).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(0, pageCount - 1);
    final pageItems = filtered.skip(page * _pageSize).take(_pageSize).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Container(
        decoration: cardDecoration(c, radius: 18).copyWith(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(filtered.length),
            const Divider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _toolbar(filtered),
                    _activeFilters(),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _showStats && _segment != Segment.trash
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: _StatsRow(store: store),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: _listCard(filtered, pageItems, page, pageCount)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(int shown) {
    final c = context.colors;
    final favorites = store.contacts.where((x) => x.favorite).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
      child: Row(
        children: [
          Text(_segment.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Tag('$shown', fontSize: 13),
          if (_segment == Segment.trash) ...[
            const SizedBox(width: 14),
            Text(
              'Удаляются навсегда через ${ContactStore.trashDays} дней',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
          ],
          const Spacer(),
          if (_segment == Segment.trash && store.trash.isNotEmpty) ...[
            AppButton(
              label: 'Очистить корзину',
              icon: Icons.delete_forever_outlined,
              danger: true,
              onPressed: () => _purge({for (final x in store.trash) x.id}),
            ),
            const SizedBox(width: 12),
          ],
          if (favorites.isNotEmpty) ...[
            Tooltip(
              message: 'Избранные',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() {
                  _segment = Segment.favorites;
                  _page = 0;
                }),
                child: SizedBox(
                  height: 38,
                  width: 30.0 * favorites.take(4).length + (favorites.length > 4 ? 30 : 0) + 8,
                  child: Stack(
                    children: [
                      for (var i = 0; i < favorites.take(4).length; i++)
                        Positioned(
                          left: i * 30.0,
                          child: ContactAvatar(
                            name: favorites[i].name,
                            photo: store.photoOf(favorites[i]),
                            radius: 17,
                            ring: true,
                          ),
                        ),
                      if (favorites.length > 4)
                        Positioned(
                          left: 4 * 30.0,
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accentSoft,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.surface, width: 2),
                            ),
                            child: Text(
                              '+${favorites.length - 4}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: c.accent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(height: 24, child: VerticalDivider(color: c.border)),
            const SizedBox(width: 12),
          ],
          SquareIconButton(
            icon: Icons.search,
            tooltip: 'Поиск (⌘K)',
            onPressed: _searchFocus.requestFocus,
          ),
        ],
      ),
    );
  }

  Widget _toolbar(List<Contact> filtered) {
    final c = context.colors;
    final interests = store.interestCounts;
    return Row(
      children: [
        MenuAnchor(
          builder: (context, ctrl, _) => AppButton(
            label: _view.label,
            icon: _view.icon,
            trailingIcon: Icons.expand_more,
            onPressed: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
          ),
          menuChildren: [
            for (final v in ViewMode.values)
              MenuItemButton(
                leadingIcon: Icon(v.icon, size: 18),
                trailingIcon: v == _view ? Icon(Icons.check, size: 16, color: c.accent) : null,
                onPressed: () => setState(() => _view = v),
                child: Text(v.label),
              ),
          ],
        ),
        const SizedBox(width: 10),
        SizedBox(height: 24, child: VerticalDivider(color: c.border)),
        const SizedBox(width: 10),
        MenuAnchor(
          builder: (context, ctrl, _) => AppButton(
            label: 'Фильтр',
            icon: Icons.filter_list_rounded,
            badge: _interests.isEmpty
                ? null
                : Tag('${_interests.length}', background: c.accent, foreground: Colors.white, fontSize: 11),
            onPressed: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
          ),
          menuChildren: [
            if (interests.isEmpty)
              const MenuItemButton(child: Text('Интересов пока нет')),
            for (final e in interests)
              CheckboxMenuButton(
                value: _interests.contains(e.key),
                closeOnActivate: false,
                onChanged: (v) => setState(() {
                  v == true ? _interests.add(e.key) : _interests.remove(e.key);
                  _page = 0;
                }),
                trailingIcon: Text('${e.value}', style: TextStyle(color: c.textMuted, fontSize: 12.5)),
                child: Text(e.key),
              ),
            if (_interests.isNotEmpty) ...[
              const Divider(),
              MenuItemButton(
                leadingIcon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(_interests.clear),
                child: const Text('Сбросить'),
              ),
            ],
          ],
        ),
        const SizedBox(width: 8),
        MenuAnchor(
          builder: (context, ctrl, _) => AppButton(
            label: _segment == Segment.birthdays ? 'По дате праздника' : _sort.label,
            icon: Icons.swap_vert_rounded,
            onPressed: _segment == Segment.birthdays
                ? null
                : () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
          ),
          menuChildren: [
            for (final s in SortMode.values)
              MenuItemButton(
                leadingIcon: Icon(s.icon, size: 18),
                trailingIcon: s == _sort ? Icon(Icons.check, size: 16, color: c.accent) : null,
                onPressed: () => setState(() => _sort = s),
                child: Text(s.label),
              ),
          ],
        ),
        const SizedBox(width: 18),
        Text('Статистика', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _showStats,
            onChanged: (v) => setState(() => _showStats = v),
          ),
        ),
        const Spacer(),
        SquareIconButton(
          icon: Icons.file_upload_outlined,
          tooltip: 'Импорт из CSV или vCard',
          onPressed: () => importContacts(context, store),
        ),
        const SizedBox(width: 8),
        SquareIconButton(
          icon: Icons.file_download_outlined,
          tooltip: 'Экспорт в CSV',
          onPressed: () => _export(filtered),
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'Новый контакт',
          icon: Icons.add_rounded,
          primary: true,
          onPressed: _create,
        ),
      ],
    );
  }

  Widget _activeFilters() {
    final c = context.colors;
    final chips = <Widget>[
      if (_search.text.trim().isNotEmpty)
        _FilterChip(label: '«${_search.text.trim()}»', onRemove: _search.clear),
      for (final i in _interests)
        _FilterChip(
          label: i,
          dot: TagColors.hue(i),
          onRemove: () => setState(() => _interests.remove(i)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Фильтры:', style: TextStyle(fontSize: 13, color: c.textMuted)),
          ...chips,
          TextButton(
            onPressed: _resetFilters,
            style: TextButton.styleFrom(foregroundColor: c.accent),
            child: const Text('Сбросить всё'),
          ),
        ],
      ),
    );
  }

  Widget _listCard(List<Contact> filtered, List<Contact> pageItems, int page, int pageCount) {
    final c = context.colors;
    final Widget body;
    if (_segment == Segment.trash && filtered.isEmpty && _search.text.trim().isEmpty) {
      body = _EmptyState(
        icon: Icons.delete_outline_rounded,
        title: 'Корзина пуста',
        subtitle: 'Удалённые контакты хранятся здесь ${ContactStore.trashDays} дней — '
            'их можно восстановить',
        action: AppButton(label: 'К контактам', onPressed: () => setState(() => _segment = Segment.all)),
      );
    } else if (store.contacts.isEmpty && _segment != Segment.trash) {
      body = _EmptyState(
        icon: Icons.contacts_outlined,
        showLogo: true,
        title: 'Контактов пока нет',
        subtitle: 'Добавьте первого человека — имя, телефон, Telegram и где познакомились',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'Импорт',
              icon: Icons.file_upload_outlined,
              onPressed: () => importContacts(context, store),
            ),
            const SizedBox(width: 10),
            AppButton(label: 'Новый контакт', icon: Icons.add_rounded, primary: true, onPressed: _create),
          ],
        ),
      );
    } else if (filtered.isEmpty) {
      body = _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Ничего не найдено',
        subtitle: 'Попробуйте изменить запрос или сбросить фильтры',
        action: AppButton(label: 'Сбросить фильтры', onPressed: _resetFilters),
      );
    } else if (_view == ViewMode.table) {
      body = ContactsTable(
        contacts: pageItems,
        store: store,
        selected: _selected,
        onOpen: _open,
        onToggle: _toggle,
        onToggleAll: (v) => setState(() {
          final ids = pageItems.map((x) => x.id);
          v ? _selected.addAll(ids) : _selected.removeAll(ids);
          if (v) messengerKey.currentState?.hideCurrentSnackBar();
        }),
        onAddColumn: () => showFieldDialog(context, store: store, showInTable: true),
        onEditColumn: (f) => showFieldDialog(context, store: store, field: f),
      );
    } else {
      body = ContactsGrid(
        contacts: pageItems,
        store: store,
        selected: _selected,
        onOpen: _open,
        onToggle: _toggle,
      );
    }

    return Container(
      decoration: cardDecoration(c),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: body),
              if (filtered.isNotEmpty) ...[
                const Divider(),
                PaginationBar(
                  page: page,
                  pageCount: pageCount,
                  pageSize: _pageSize,
                  total: filtered.length,
                  onPage: (p) => setState(() => _page = p),
                  onPageSize: (n) => setState(() {
                    _pageSize = n;
                    _page = 0;
                  }),
                ),
              ],
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 74,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: _selected.isEmpty ? const SizedBox.shrink() : _bulkBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String id) => setState(() {
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
        // Панель действий с выделенным встаёт на место тоста.
        if (_selected.isNotEmpty) messengerKey.currentState?.hideCurrentSnackBar();
      });

  Widget _bulkBar() {
    final c = context.colors;
    if (_segment == Segment.trash) return _trashBar();
    final selected = store.contacts.where((x) => _selected.contains(x.id)).toList();
    final allFavorite = selected.every((x) => x.favorite);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: cardDecoration(c).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_selected.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          Text(plural(_selected.length, 'выбран', 'выбрано', 'выбрано'),
              style: TextStyle(color: c.textMuted)),
          const SizedBox(width: 14),
          AppButton(
            label: allFavorite ? 'Из избранного' : 'В избранное',
            icon: allFavorite ? Icons.star_outline_rounded : Icons.star_rounded,
            onPressed: () => store.setFavorite({..._selected}, !allFavorite),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Экспорт',
            icon: Icons.file_download_outlined,
            onPressed: () => _export(selected),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Удалить',
            icon: Icons.delete_outline_rounded,
            danger: true,
            onPressed: _deleteSelected,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Снять выделение',
            icon: Icon(Icons.close, size: 18, color: c.textMuted),
            onPressed: () => setState(_selected.clear),
          ),
        ],
      ),
    );
  }

  Widget _trashBar() {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: cardDecoration(c).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_selected.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          Text(plural(_selected.length, 'выбран', 'выбрано', 'выбрано'),
              style: TextStyle(color: c.textMuted)),
          const SizedBox(width: 14),
          AppButton(
            label: 'Восстановить',
            icon: Icons.restore_rounded,
            onPressed: _restoreSelected,
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Удалить навсегда',
            icon: Icons.delete_forever_outlined,
            danger: true,
            onPressed: () => _purge({..._selected}),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Снять выделение',
            icon: Icon(Icons.close, size: 18, color: c.textMuted),
            onPressed: () => setState(_selected.clear),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ContactStore store;
  const _StatsRow({required this.store});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final all = store.contacts;
    int age(Contact x) => now.difference(x.createdAt).inDays;
    final last30 = all.where((x) => age(x) < 30).length;
    final prev30 = all.where((x) => age(x) >= 30 && age(x) < 60).length;
    final favorites = all.where((x) => x.favorite).length;
    final upcoming = all
        .where((x) => (x.daysUntilBirthday(now) ?? 999) <= 30)
        .toList()
      ..sort((a, b) => a.daysUntilBirthday(now)!.compareTo(b.daysUntilBirthday(now)!));
    final interests = store.interestCounts;

    String nextBirthday() {
      if (upcoming.isEmpty) return 'в ближайшие 30 дней';
      final d = upcoming.first.daysUntilBirthday(now)!;
      final name = upcoming.first.name.split(' ').first;
      return d == 0 ? 'сегодня у $name' : 'ближайший — $name, через $d дн.';
    }

    final cards = [
      _Stat(
        title: 'Всего контактов',
        value: '${all.length}',
        note: last30 > 0 ? 'за 30 дней' : 'новых за месяц нет',
        pill: last30 > 0 ? '+$last30' : null,
      ),
      _Stat(
        title: 'Новые за месяц',
        value: '$last30',
        note: 'было $prev30',
        pill: prev30 == 0
            ? (last30 > 0 ? 'новые' : null)
            : '${((last30 - prev30) / prev30 * 100).round().abs()}%',
        pillUp: last30 >= prev30,
      ),
      _Stat(
        title: 'Избранные',
        value: '$favorites',
        note: 'от всей базы',
        pill: all.isEmpty ? null : '${(favorites / all.length * 100).round()}%',
        neutral: true,
      ),
      _Stat(
        title: 'Дни рождения',
        value: '${upcoming.length}',
        note: nextBirthday(),
      ),
      _Stat(
        title: 'Сфер интересов',
        value: '${interests.length}',
        note: interests.isEmpty ? 'пока не указаны' : 'популярная — ${interests.first.key}',
      ),
    ];

    return Container(
      decoration: cardDecoration(c),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) VerticalDivider(color: c.border, width: 1),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final String? pill;
  final bool pillUp;
  final bool neutral;

  const _Stat({
    required this.title,
    required this.value,
    required this.note,
    this.pill,
    this.pillUp = true,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color pillBg, pillFg;
    if (neutral) {
      (pillBg, pillFg) = (c.accentSoft, c.accent);
    } else if (pillUp) {
      (pillBg, pillFg) = (c.successSoft, c.success);
    } else {
      (pillBg, pillFg) = (c.danger.withValues(alpha: 0.1), c.danger);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.1)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (pill != null) ...[
                Tag(
                  pill!,
                  icon: neutral ? null : (pillUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                  background: pillBg,
                  foreground: pillFg,
                  fontSize: 11.5,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? dot;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, this.dot, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 2),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 15, color: c.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  /// Вместо значка — логотип приложения (для самого первого запуска).
  final bool showLogo;

  const _EmptyState({
    required this.icon,
    this.showLogo = false,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLogo)
              Image.asset('assets/images/logo.png', width: 128, height: 128)
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: c.accent),
              ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: c.textMuted, height: 1.45),
            ),
            const SizedBox(height: 18),
            action,
          ],
        ),
      ),
    );
  }
}
