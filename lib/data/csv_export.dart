import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

import '../models/contact.dart';
import '../models/field_schema.dart';
import '../l10n/strings.dart';

String contactsToCsv(List<Contact> contacts, List<CustomField> fields) {
  final date = DateFormat('yyyy-MM-dd');
  String cell(String v) =>
      RegExp(r'[",;\n\r]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;

  final rows = [
    [
      ...tr.csvHeaders,
      for (final f in fields) f.label,
    ],
    for (final c in contacts)
      [
        c.name,
        // Все номера и адреса в одной ячейке — импорт Orbit разберёт их обратно.
        c.phones.map((p) => p.value).join('; '),
        c.telegramHandle.isEmpty ? '' : '@${c.telegramHandle}',
        c.instagramHandle.isEmpty ? '' : '@${c.instagramHandle}',
        c.emails.map((e) => e.value).join('; '),
        c.position,
        c.company,
        c.whereMet,
        c.metDate == null ? '' : date.format(c.metDate!),
        c.birthday == null ? '' : date.format(c.birthday!),
        c.interests.join(', '),
        c.notes,
        c.favorite ? tr.csvYes : '',
        // Даты оставляем в ISO, чтобы таблица распознала их как даты.
        for (final f in fields)
          f.type == FieldType.date
              ? '${c.custom[f.id] ?? ''}'
              : f.format(c.custom[f.id]) ?? '',
      ],
  ];
  return rows.map((r) => r.map(cell).join(',')).join('\r\n');
}

/// Спрашивает, куда сохранить, и пишет CSV. Возвращает false при отмене.
Future<bool> exportContactsCsv(List<Contact> contacts, List<CustomField> fields) async {
  final location = await getSaveLocation(
    suggestedName: 'orbit-contacts-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
    acceptedTypeGroups: const [
      XTypeGroup(label: 'CSV', extensions: ['csv'], uniformTypeIdentifiers: ['public.comma-separated-values-text']),
    ],
  );
  if (location == null) return false;
  // BOM — чтобы Excel распознал UTF-8 и не испортил кириллицу.
  await File(location.path).writeAsString('\uFEFF${contactsToCsv(contacts, fields)}');
  return true;
}
