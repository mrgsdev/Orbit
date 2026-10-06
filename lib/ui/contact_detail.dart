import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import '../models/field_schema.dart';
import 'avatar.dart';
import 'theme.dart';
import 'widgets.dart';

class ContactDetail extends StatelessWidget {
  final Contact contact;
  final ContactStore store;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const ContactDetail({
    super.key,
    required this.contact,
    required this.store,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final x = contact;
    final dateFmt = DateFormat('d MMMM y', 'ru');
    final stamp = DateFormat('d MMM y, HH:mm', 'ru');
    final subtitle = [x.position, x.company].where((s) => s.isNotEmpty).join(' · ');
    final met = [
      x.whereMet,
      if (x.metDate != null) dateFmt.format(x.metDate!),
    ].where((s) => s.isNotEmpty).join(', ');
    final days = x.daysUntilBirthday(DateTime.now());

    final telUri = Uri(scheme: 'tel', path: x.phone.replaceAll(RegExp(r'[^\d+]'), ''));
    final tgUri = Uri.parse(x.telegramUrl);
    final mailUri = Uri(scheme: 'mailto', path: x.email);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Row(
            children: [
              SquareIconButton(icon: Icons.close, tooltip: 'Закрыть', onPressed: onClose),
              const Spacer(),
              SquareIconButton(
                icon: x.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: x.favorite ? c.star : null,
                tooltip: x.favorite ? 'Убрать из избранного' : 'В избранное',
                onPressed: () => store.toggleFavorite(x),
              ),
              const SizedBox(width: 8),
              SquareIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Удалить',
                color: c.danger,
                onPressed: onDelete,
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Изменить',
                icon: Icons.edit_outlined,
                primary: true,
                onPressed: onEdit,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border),
                  ),
                  child: ContactAvatar(name: x.name, photo: store.photoOf(x), radius: 48),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                x.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textMuted),
                ),
              ],
              if (days != null && days <= 30) ...[
                const SizedBox(height: 10),
                Center(
                  child: Tag(
                    days == 0
                        ? 'День рождения сегодня'
                        : 'День рождения через $days ${plural(days, 'день', 'дня', 'дней')}',
                    icon: Icons.cake_outlined,
                    background: c.accentSoft,
                    foreground: c.accent,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.phone_outlined,
                    label: 'Позвонить',
                    onTap: x.phone.isEmpty ? null : () => launchUrl(telUri),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.send_outlined,
                    label: 'Telegram',
                    onTap: x.telegramHandle.isEmpty ? null : () => launchUrl(tgUri),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.mail_outline,
                    label: 'Почта',
                    onTap: x.email.isEmpty ? null : () => launchUrl(mailUri),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (final section in store.sections)
                ..._section(context, section, dateFmt, met),
              Text(
                'Добавлен ${stamp.format(x.createdAt)} · изменён ${stamp.format(x.updatedAt)}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    FieldSection section,
    DateFormat dateFmt,
    String met,
  ) {
    final c = context.colors;
    final x = contact;
    final rows = <Widget>[
      ...switch (section.id) {
        BuiltIn.main => [
            if (x.phone.isNotEmpty)
              _InfoRow(icon: Icons.phone_outlined, label: 'Телефон', value: x.phone),
            if (x.telegramHandle.isNotEmpty)
              _InfoRow(
                icon: Icons.send_outlined,
                label: 'Telegram',
                value: '@${x.telegramHandle}',
                onOpen: () => launchUrl(Uri.parse(x.telegramUrl)),
              ),
            if (x.email.isNotEmpty)
              _InfoRow(icon: Icons.mail_outline, label: 'Email', value: x.email),
          ],
        BuiltIn.work => [
            if (x.position.isNotEmpty)
              _InfoRow(icon: Icons.work_outline, label: 'Должность', value: x.position),
            if (x.company.isNotEmpty)
              _InfoRow(icon: Icons.business_outlined, label: 'Компания', value: x.company),
          ],
        BuiltIn.meet => [
            if (met.isNotEmpty)
              _InfoRow(icon: Icons.handshake_outlined, label: 'Где познакомились', value: met),
            if (x.birthday != null)
              _InfoRow(
                icon: Icons.cake_outlined,
                label: 'День рождения',
                value: dateFmt.format(x.birthday!),
              ),
          ],
        _ => <Widget>[],
      },
      for (final f in section.fields)
        if (f.format(x.custom[f.id]) case final value?)
          _InfoRow(
            icon: iconFor(f.icon),
            label: f.label,
            value: value,
            onOpen: _opener(f, value),
          ),
    ];

    final Widget? extra = switch (section.id) {
      BuiltIn.interests when x.interests.isNotEmpty => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final i in x.interests) Tag.interest(context, i)],
        ),
      BuiltIn.notes when x.notes.isNotEmpty => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(x.notes, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
      _ => null,
    };

    if (rows.isEmpty && extra == null) return const [];
    return [
      Row(
        children: [
          Icon(iconFor(section.icon), size: 15, color: c.textMuted),
          const SizedBox(width: 6),
          SectionLabel(section.title),
        ],
      ),
      const SizedBox(height: 10),
      if (extra != null) ...[extra, if (rows.isNotEmpty) const SizedBox(height: 10)],
      if (rows.isNotEmpty)
        DecoratedBox(
          decoration: cardDecoration(c, radius: 12),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(indent: 60),
                rows[i],
              ],
            ],
          ),
        ),
      const SizedBox(height: 24),
    ];
  }

  /// Ссылки, телефоны и почту из своих полей можно открыть одним кликом.
  static VoidCallback? _opener(CustomField f, String value) {
    final Uri? uri = switch (f.type) {
      FieldType.url => Uri.tryParse(value.contains('://') ? value : 'https://$value'),
      FieldType.phone => Uri(scheme: 'tel', path: value.replaceAll(RegExp(r'[^\d+]'), '')),
      FieldType.email => Uri(scheme: 'mailto', path: value),
      _ => null,
    };
    return uri == null ? null : () => launchUrl(uri);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    final fg = enabled ? c.text : c.textMuted.withValues(alpha: 0.45);
    return Expanded(
      child: Material(
        color: enabled ? c.surfaceMuted : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 20, color: enabled ? c.accent : fg),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onOpen;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: c.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: c.textMuted)),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              tooltip: 'Открыть',
              icon: Icon(Icons.open_in_new_rounded, size: 16, color: c.textMuted),
              onPressed: onOpen,
            ),
          IconButton(
            tooltip: 'Скопировать',
            icon: Icon(Icons.copy_rounded, size: 16, color: c.textMuted),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              showToast(context, '$label скопирован');
            },
          ),
        ],
      ),
    );
  }
}
