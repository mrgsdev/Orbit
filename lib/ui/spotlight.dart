import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import 'avatar.dart';
import 'theme.dart';
import '../l10n/strings.dart';

/// Быстрый поиск в духе Spotlight (⌘F): имя — и сразу человек с фото.
/// Возвращает выбранный контакт.
Future<Contact?> showSpotlight(BuildContext context, {required ContactStore store}) => showGeneralDialog<Contact>(
      context: context,
      barrierDismissible: true,
      barrierLabel: tr.close,
      barrierColor: const Color(0x00000000),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (ctx, animation, _) => Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: animation,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ColoredBox(color: Pal.scrim),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.55),
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: _Spotlight(store: store),
              ),
            ),
          ),
        ],
      ),
    );

class _Spotlight extends StatefulWidget {
  final ContactStore store;
  const _Spotlight({required this.store});

  @override
  State<_Spotlight> createState() => _SpotlightState();
}

class _SpotlightState extends State<_Spotlight> {
  static const _maxResults = 7;

  final _query = TextEditingController();
  int _index = 0;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() => _index = 0));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Сначала те, чьё имя (или фамилия) начинается с запроса, потом —
  /// совпадение где угодно в имени, потом — в остальных полях.
  List<Contact> _results() {
    final q = _query.text.trim().toLowerCase();
    final all = widget.store.contacts;
    if (q.isEmpty) {
      return ([...all]..sort((a, b) {
              if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
              return b.updatedAt.compareTo(a.updatedAt);
            }))
          .take(_maxResults)
          .toList();
    }
    int rank(Contact c) {
      final name = c.name.toLowerCase();
      if (name.startsWith(q) || name.split(RegExp(r'\s+')).any((w) => w.startsWith(q))) return 0;
      if (name.contains(q)) return 1;
      return c.matches(q) ? 2 : 3;
    }

    final found = [for (final c in all) if (rank(c) < 3) c]
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return found.take(_maxResults).toList();
  }

  /// Закрыть окно с результатом — один раз, даже если Enter пришёл и
  /// клавишей, и от поля ввода.
  void _close([Contact? result]) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  void _open(List<Contact> results) {
    if (results.isNotEmpty) _close(results[_index.clamp(0, results.length - 1)]);
  }

  KeyEventResult _onKey(KeyEvent e, List<Contact> results) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown && results.isNotEmpty) {
      setState(() => _index = (_index + 1) % results.length);
    } else if (key == LogicalKeyboardKey.arrowUp && results.isNotEmpty) {
      setState(() => _index = (_index - 1 + results.length) % results.length);
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _open(results);
    } else if (key == LogicalKeyboardKey.escape) {
      _close();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();
    final q = _query.text.trim();
    return Focus(
      onKeyEvent: (_, e) => _onKey(e, results),
      child: Container(
        width: 640,
        decoration: BoxDecoration(
          color: Pal.spotlight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Pal.border),
          boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 60, offset: const Offset(0, 24))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Row(
                children: [
                  Icon(CupertinoIcons.search, size: 22, color: Pal.accentText),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _query,
                      autofocus: true,
                      placeholder: tr.spotlightPlaceholder,
                      placeholderStyle: T.title.copyWith(fontSize: 20, fontWeight: FontWeight.w500, color: Pal.dim),
                      style: T.title.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
                      cursorColor: Pal.accent,
                      decoration: null,
                      padding: EdgeInsets.zero,
                      onSubmitted: (_) => _open(results),
                    ),
                  ),
                  Text('esc', style: T.tiny.copyWith(color: Pal.dim)),
                ],
              ),
            ),
            Container(height: 1, color: Pal.divider),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  q.isEmpty ? tr.noContactsTitle : tr.noneFoundFor(q),
                  textAlign: TextAlign.center,
                  style: T.body.copyWith(color: Pal.muted),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
                child: Text(q.isEmpty ? tr.favoritesAndRecentCaps : tr.contactsCaps, style: T.tiny.copyWith(letterSpacing: 0.8, color: Pal.dim)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  children: [
                    for (final (i, c) in results.indexed)
                      _Result(
                        contact: c,
                        store: widget.store,
                        query: q,
                        selected: i == _index,
                        onHover: () => setState(() => _index = i),
                        onTap: () => _close(c),
                      ),
                  ],
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Pal.divider))),
              child: Row(
                children: [
                  const Spacer(),
                  Text(tr.contacts(widget.store.contacts.length), style: T.tiny),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final Contact contact;
  final ContactStore store;
  final String query;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _Result({
    required this.contact,
    required this.store,
    required this.query,
    required this.selected,
    required this.onHover,
    required this.onTap,
  });

  /// Имя с подсвеченным совпадением.
  TextSpan _name() {
    final name = contact.name;
    final lower = name.toLowerCase(), q = query.toLowerCase();
    // Сначала — совпадение с началом слова: по нему человек и найден.
    final wordStart = q.isEmpty ? null : RegExp('(^|\\s)${RegExp.escape(q)}').firstMatch(lower);
    final at = q.isEmpty
        ? -1
        : wordStart != null
            ? wordStart.start + (wordStart[1]!.length)
            : lower.indexOf(q);
    final base = T.heading.copyWith(fontSize: 16);
    if (at == -1) return TextSpan(text: name, style: base);
    return TextSpan(style: base, children: [
      TextSpan(text: name.substring(0, at)),
      TextSpan(text: name.substring(at, at + query.length), style: base.copyWith(color: Pal.accentText)),
      TextSpan(text: name.substring(at + query.length)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final x = contact;
    final details = [
      [x.position, x.company].where((s) => s.isNotEmpty).join(' · '),
      if (x.telegramHandle.isNotEmpty) '@${x.telegramHandle}',
      x.phone,
    ].where((s) => s.isNotEmpty).join('   ');
    return MouseRegion(
      onHover: (_) {
        if (!selected) onHover();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? Pal.raised : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? Pal.accent.withValues(alpha: 0.5) : const Color(0x00000000)),
          ),
          child: Row(
            children: [
              ContactAvatar(name: x.name, photo: store.photoOf(x), radius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(_name(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                    ],
                  ],
                ),
              ),
              if (x.favorite) Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.star_fill, size: 14, color: Pal.accentText),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Icon(CupertinoIcons.return_icon, size: 16, color: Pal.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
