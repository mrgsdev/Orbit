import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import '../models/field_schema.dart';
import 'avatar.dart';
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

/// Карточка контакта справа: аватар, кнопки связи и строки «подпись — значение».
class ContactDetail extends StatelessWidget {
  final Contact contact;
  final ContactStore store;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Для контакта из корзины — вместо правки и удаления.
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  /// Если задан — слева крестик: карточка открыта отдельным окном.
  final VoidCallback? onClose;

  const ContactDetail({
    super.key,
    required this.contact,
    required this.store,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onPurge,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final x = contact;
    final dateFmt = DateFormat('d MMMM y', tr.locale);
    final stamp = DateFormat('d MMM y, HH:mm', tr.locale);
    final subtitle = [x.position, x.company].where((s) => s.isNotEmpty).join(' · ');
    final days = x.daysUntilBirthday(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Row(
            children: [
              if (onClose != null) ...[
                IconBtn(icon: CupertinoIcons.xmark, hint: tr.closeEsc, filled: true, onPressed: onClose),
                const SizedBox(width: 8),
              ],
              if (!x.isDeleted)
                IconBtn(
                  icon: x.favorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: x.favorite ? Pal.accentText : null,
                  hint: x.favorite ? tr.removeFromFavorites : tr.toFavorites,
                  filled: true,
                  onPressed: () => store.toggleFavorite(x),
                ),
              const Spacer(),
              if (x.isDeleted) ...[
                Btn(label: tr.delete, kind: BtnKind.danger, small: true, onPressed: onPurge),
                const SizedBox(width: 8),
                Btn.primary(label: tr.restore, small: true, onPressed: onRestore),
              ] else ...[
                IconBtn(icon: CupertinoIcons.trash, hint: tr.toTrashKey, filled: true, onPressed: onDelete),
                const SizedBox(width: 8),
                Btn.primary(label: tr.edit, icon: CupertinoIcons.pencil, small: true, onPressed: onEdit),
              ],
            ],
          ),
        ),
        Expanded(
          child: ScrollArea(
            builder: (controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(26, 10, 26, 28),
              children: [
                Center(child: ContactAvatar(name: x.name, photo: store.photoOf(x), radius: 50)),
                const SizedBox(height: 16),
                Text(x.name, textAlign: TextAlign.center, style: T.title.copyWith(fontSize: 22)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, textAlign: TextAlign.center, style: T.body.copyWith(color: Pal.muted)),
                ],
                if (x.isDeleted) ...[
                  const SizedBox(height: 12),
                  Center(child: Tag(_trashNote(x.deletedAt!), color: Pal.red)),
                ] else if (days != null && days <= 30) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Tag(
                      days == 0 ? tr.birthdayToday : tr.birthdayIn(days),
                      color: Pal.pink,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Action(
                      icon: CupertinoIcons.paperplane_fill,
                      label: 'Telegram',
                      color: Pal.teal,
                      onTap: x.telegramHandle.isEmpty ? null : () => launchUrl(Uri.parse(x.telegramUrl)),
                    ),
                    _Action(
                      icon: CupertinoIcons.camera_fill,
                      label: 'Instagram',
                      color: Pal.pink,
                      onTap: x.instagramHandle.isEmpty ? null : () => launchUrl(Uri.parse(x.instagramUrl)),
                    ),
                    _Action(
                      icon: CupertinoIcons.envelope_fill,
                      label: tr.mail,
                      color: Pal.yellow,
                      onTap: x.email.isEmpty ? null : () => launchUrl(Uri(scheme: 'mailto', path: x.email)),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(height: 1, color: Pal.divider),
                const SizedBox(height: 10),
                for (final section in store.sections) ..._section(section, dateFmt),
                const SizedBox(height: 10),
                Text(
                  tr.addedChanged(stamp.format(x.createdAt), stamp.format(x.updatedAt)),
                  textAlign: TextAlign.center,
                  style: T.tiny.copyWith(color: Pal.dim, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _section(FieldSection section, DateFormat dateFmt) {
    final x = contact;
    final rows = <Widget>[
      ...switch (section.id) {
        BuiltIn.main => [
            for (final p in x.phones) _InfoRow(label: '${tr.phone} · ${tr.valueLabel(p.label)}', value: p.value),
            if (x.telegramHandle.isNotEmpty)
              _InfoRow(label: 'Telegram', value: '@${x.telegramHandle}', onOpen: () => launchUrl(Uri.parse(x.telegramUrl))),
            if (x.instagramHandle.isNotEmpty)
              _InfoRow(label: 'Instagram', value: '@${x.instagramHandle}', onOpen: () => launchUrl(Uri.parse(x.instagramUrl))),
            for (final e in x.emails)
              _InfoRow(
                label: '${tr.email} · ${tr.valueLabel(e.label)}',
                value: e.value,
                onOpen: () => launchUrl(Uri(scheme: 'mailto', path: e.value)),
              ),
          ],
        BuiltIn.work => [
            if (x.position.isNotEmpty) _InfoRow(label: tr.position, value: x.position),
            if (x.company.isNotEmpty) _InfoRow(label: tr.company, value: x.company),
          ],
        BuiltIn.meet => [
            if (x.whereMet.isNotEmpty) _InfoRow(label: tr.where, value: x.whereMet),
            if (x.metDate != null) _InfoRow(label: tr.when, value: dateFmt.format(x.metDate!)),
            if (x.birthday != null) _InfoRow(label: tr.birthday, value: dateFmt.format(x.birthday!)),
          ],
        _ => <Widget>[],
      },
      for (final f in section.fields)
        if (f.format(x.custom[f.id]) case final value?) _InfoRow(label: f.label, value: value, onOpen: _opener(f, value)),
    ];

    final Widget? extra = switch (section.id) {
      BuiltIn.interests when x.interests.isNotEmpty =>
        Wrap(spacing: 6, runSpacing: 6, children: [for (final i in x.interests) Tag.interest(i)]),
      BuiltIn.notes when x.notes.isNotEmpty => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Pal.raised, borderRadius: BorderRadius.circular(14)),
          child: Text(x.notes, style: T.body.copyWith(height: 1.5)),
        ),
      _ => null,
    };

    if (rows.isEmpty && extra == null) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(tr.sectionTitle(section).toUpperCase(), style: T.tiny.copyWith(letterSpacing: 0.8, color: Pal.dim)),
      ),
      ...rows,
      if (extra != null) Padding(padding: const EdgeInsets.only(top: 6), child: extra),
    ];
  }

  static String _trashNote(DateTime deletedAt) {
    final left = ContactStore.trashDays - DateTime.now().difference(deletedAt).inDays;
    return left <= 1
        ? tr.trashTomorrow
        : tr.trashIn(left);
  }

  /// Ссылки и почту из своих полей можно открыть одним кликом;
  /// телефоны только показываем — звонить с Mac не нужно.
  static VoidCallback? _opener(CustomField f, String value) {
    final Uri? uri = switch (f.type) {
      FieldType.url => Uri.tryParse(value.contains('://') ? value : 'https://$value'),
      FieldType.email => Uri(scheme: 'mailto', path: value),
      _ => null,
    };
    return uri == null ? null : () => launchUrl(uri);
  }
}

/// Круглая цветная кнопка связи с подписью.
class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _Action({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Pressable(
        onTap: onTap,
        hint: enabled ? label : tr.notSpecified(label),
        builder: (context, hover, _) => Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? (hover ? Color.lerp(color, const Color(0xFFFFFFFF), 0.2) : color) : Pal.raised,
              ),
              child: Icon(icon, size: 19, color: enabled ? Pal.onAccent : Pal.dim),
            ),
            const SizedBox(height: 7),
            Text(label, style: T.tiny.copyWith(color: enabled ? Pal.text : Pal.dim)),
          ],
        ),
      ),
    );
  }
}

/// «Подпись — значение», как сводка в правой колонке дашборда.
/// По наведению — «скопировать».
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onOpen;

  const _InfoRow({required this.label, required this.value, this.onOpen});

  @override
  Widget build(BuildContext context) => Hover(
        builder: (context, hover) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 146, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small)),
              Expanded(
                child: Pressable(
                  onTap: onOpen,
                  pressScale: 1,
                  builder: (context, linkHover, _) => Text(
                    value,
                    textAlign: TextAlign.right,
                    style: T.body.copyWith(
                      color: onOpen != null ? (linkHover ? Pal.text : Pal.accentText) : Pal.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: Visibility(
                  visible: hover,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconBtn(
                      icon: CupertinoIcons.doc_on_doc,
                      hint: tr.copy,
                      size: 22,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                        showToast(tr.copied(value));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Карточка человека отдельным окном — например, из быстрого поиска (⌘F).
Future<void> showContactCard(
  BuildContext context, {
  required ContactStore store,
  required Contact contact,
  required ValueChanged<Contact> onEdit,
  required ValueChanged<Contact> onDelete,
}) =>
    showModal<void>(
      context,
      builder: (ctx) {
        void close() => Navigator.of(ctx).pop();
        return CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
          child: FocusScope(
            autofocus: true,
            child: Container(
              width: 440,
              height: (MediaQuery.sizeOf(ctx).height - 80).clamp(360.0, 780.0),
              decoration: BoxDecoration(
                color: Pal.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Pal.border),
                boxShadow: [BoxShadow(color: Pal.shadow, blurRadius: 60, offset: const Offset(0, 24))],
              ),
              clipBehavior: Clip.antiAlias,
              // Карточка следит за базой: звёздочка, правки и удаление видны сразу.
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final current = store.byId(contact.id);
                  if (current == null || current.isDeleted) return const SizedBox.shrink();
                  return ContactDetail(
                    contact: current,
                    store: store,
                    onClose: close,
                    onEdit: () => onEdit(current),
                    onDelete: () {
                      close();
                      onDelete(current);
                    },
                    onRestore: () {},
                    onPurge: () {},
                  );
                },
              ),
            ),
          ),
        );
      },
    );
