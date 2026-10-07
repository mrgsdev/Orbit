import 'package:flutter/cupertino.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import 'avatar.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

class ContactsGrid extends StatelessWidget {
  final List<Contact> contacts;
  final ContactStore store;
  final Set<String> selected;
  final ValueChanged<Contact> onTap;

  const ContactsGrid({super.key, required this.contacts, required this.store, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ScrollArea(
        builder: (controller) => GridView.builder(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisExtent: 232,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: contacts.length,
          itemBuilder: (context, i) {
            final c = contacts[i];
            return _Card(
              key: ValueKey(c.id),
              contact: c,
              store: store,
              selected: selected.contains(c.id),
              onTap: () => onTap(c),
            );
          },
        ),
      );
}

class _Card extends StatelessWidget {
  final Contact contact;
  final ContactStore store;
  final bool selected;
  final VoidCallback onTap;

  const _Card({super.key, required this.contact, required this.store, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final x = contact;
    final job = [x.position, x.company].where((s) => s.isNotEmpty).join(' · ');
    final hue = TagColors.hue(x.name);
    return Pressable(
      onTap: onTap,
      pressScale: 0.98,
      builder: (context, hover, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: hover || selected ? Pal.raised : Pal.gridCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Pal.accent : Pal.border, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Цветное свечение сверху — цвет человека.
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [hue.withValues(alpha: 0.28), hue.withValues(alpha: 0)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 22, 14, 16),
              child: Column(
                children: [
                  ContactAvatar(name: x.name, photo: store.photoOf(x), radius: 34),
                  const SizedBox(height: 14),
                  Text(
                    x.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: T.heading,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.isEmpty ? ' ' : job,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: T.small,
                  ),
                  const Spacer(),
                  if (x.interests.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final i in x.interests.take(2)) ...[Flexible(child: Tag.interest(i, small: true)), const SizedBox(width: 5)],
                        if (x.interests.length > 2) Text('+${x.interests.length - 2}', style: T.tiny),
                      ],
                    ),
                ],
              ),
            ),
            if (x.favorite || hover)
              Positioned(
                top: 8,
                right: 8,
                child: IconBtn(
                  icon: x.favorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  hint: x.favorite ? tr.removeFromFavorites : tr.toFavorites,
                  size: 30,
                  color: x.favorite ? Pal.accentText : Pal.muted,
                  onPressed: () => store.toggleFavorite(x),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
