import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'crypto.dart';
import '../l10n/strings.dart';

/// Резервная копия — один файл .orbit:
/// «ORBK» + длина заголовка (4 байта) + заголовок JSON + зашифрованные данные.
///
/// Данные зашифрованы тем же ключом, что и база, а в заголовке лежит этот
/// ключ, запечатанный recovery code. Поэтому копия открывается и на этом Mac
/// без ввода кода, и на любом другом — по recovery code.
class Backup {
  static const extension = 'orbit';
  static const _magic = [0x4F, 0x52, 0x42, 0x4B]; // «ORBK»

  final Map<String, dynamic> header;
  final Uint8List _payload;

  Backup._(this.header, this._payload);

  int get contactCount => header['contacts'] as int? ?? 0;
  DateTime? get createdAt => DateTime.tryParse(header['created'] as String? ?? '');

  static Future<Uint8List> build({
    required Map<String, dynamic> snapshot,
    required DataCipher cipher,
    required KeyEnvelope envelope,
  }) async {
    final header = utf8.encode(jsonEncode({
      'app': 'Orbit',
      'version': 1,
      'created': DateTime.now().toIso8601String(),
      'contacts': (snapshot['contacts'] as List).length,
      'recovery': envelope.recoveryJson(),
    }));
    final payload = await cipher.encrypt(gzip.encode(utf8.encode(jsonEncode(snapshot))));
    return Uint8List.fromList([
      ..._magic,
      ...(ByteData(4)..setUint32(0, header.length)).buffer.asUint8List(),
      ...header,
      ...payload,
    ]);
  }

  /// Бросает [FormatException], если это не резервная копия Orbit.
  factory Backup.parse(Uint8List bytes) {
    for (var i = 0; i < 4; i++) {
      if (bytes.length < 8 || bytes[i] != _magic[i]) {
        throw FormatException(tr.notABackup);
      }
    }
    final len = ByteData.sublistView(bytes, 4, 8).getUint32(0);
    if (8 + len > bytes.length) throw FormatException(tr.fileCorrupted);
    final header = jsonDecode(utf8.decode(bytes.sublist(8, 8 + len))) as Map<String, dynamic>;
    return Backup._(header, bytes.sublist(8 + len));
  }

  /// Пробует открыть ключом текущей базы — подходит, если копия сделана
  /// на этой же установке. Иначе бросает [WrongSecretException].
  Future<Map<String, dynamic>> open(DataCipher cipher) async =>
      jsonDecode(utf8.decode(gzip.decode(await cipher.decrypt(_payload)))) as Map<String, dynamic>;

  Future<Map<String, dynamic>> openWithRecovery(String code) async => open(
      await KeyEnvelope.openRecoveryJson(header['recovery'] as Map<String, dynamic>, code));
}
