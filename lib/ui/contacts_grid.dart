import 'package:flutter/material.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import 'avatar.dart';
import 'theme.dart';
import 'widgets.dart';

class ContactsGrid extends StatelessWidget {
  final List<Contact> contacts;
  final ContactStore store;
  final Set<String> selected;
  final ValueChanged<Contact> onOpen;
  final ValueChanged<String> onToggle;

  const ContactsGrid({
    super.key,
    required this.contacts,
    required this.store,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 290,
        mainAxisExtent: 236,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: contacts.length,
      itemBuilder: (context, i) {
        final c = contacts[i];
        return _Card(
          contact: c,
          store: store,
          selected: selected.contains(c.id),
          onOpen: () => onOpen(c),
          onToggle: () => onToggle(c.id),
        );
      },
    );
  }
}

class _Card extends StatefulWidget {
  final Contact contact;
  final ContactStore store;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const _Card({
    required this.contact,
    required this.store,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final x = widget.contact;
    final job = [x.position, x.company].where((s) => s.isNotEmpty).join(' · ');
    final handle = x.telegramHandle.isNotEmpty ? '@${x.telegramHandle}' : x.phone;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.selected ? c.accentSoft : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? c.accent
                  : _hover
                      ? c.textMuted.withValues(alpha: 0.4)
                      : c.border,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
                child: Column(
                  children: [
                    ContactAvatar(name: x.name, photo: widget.store.photoOf(x), radius: 32),
                    const SizedBox(height: 12),
                    Text(
                      x.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.isEmpty ? ' ' : job,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.textMuted),
                    ),
                    const Spacer(),
                    if (x.interests.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final i in x.interests.take(2)) ...[
                            Flexible(child: Tag.interest(context, i)),
                            const SizedBox(width: 6),
                          ],
                          if (x.interests.length > 2) Tag('+${x.interests.length - 2}'),
                        ],
                      ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          x.telegramHandle.isNotEmpty
                              ? Icons.send_outlined
                              : Icons.phone_outlined,
                          size: 15,
                          color: c.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            handle.isEmpty ? 'Нет контактов' : handle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: c.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: AnimatedOpacity(
                  opacity: _hover || widget.selected ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: Checkbox(
                    value: widget.selected,
                    onChanged: (_) => widget.onToggle(),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton(
                  tooltip: x.favorite ? 'Убрать из избранного' : 'В избранное',
                  onPressed: () => widget.store.toggleFavorite(x),
                  icon: Icon(
                    x.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: x.favorite
                        ? c.star
                        : c.textMuted.withValues(alpha: _hover ? 1 : 0.35),
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
