import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Шифрование данных Orbit.
///
/// Все файлы базы шифруются одним случайным ключом данных (AES-256-GCM).
/// Сам ключ данных хранится в vault.json дважды — зашифрованным ключом из
/// PIN-кода и ключом из recovery code (оба выводятся через Argon2id).
/// Поэтому сменить PIN или восстановить доступ по коду можно без
/// перешифровки всей базы, а резервная копия открывается тем же кодом.

const _fileMagic = [0x4F, 0x52, 0x42, 0x31]; // «ORB1»
const _nonceLength = 12;
const _macLength = 16;

final _aes = AesGcm.with256bits();

/// Неверный PIN или recovery code, либо повреждённые данные.
class WrongSecretException implements Exception {
  const WrongSecretException();
}

/// Ключ данных: шифрует и расшифровывает содержимое файлов.
class DataCipher {
  final SecretKey _key;
  final List<int> _keyBytes;

  DataCipher._(List<int> keyBytes)
      : _keyBytes = List.unmodifiable(keyBytes),
        _key = SecretKey(keyBytes);

  static Future<DataCipher> generate() async =>
      DataCipher._(await (await _aes.newSecretKey()).extractBytes());

  /// Байты в формате: «ORB1» + nonce + шифротекст + MAC.
  Future<Uint8List> encrypt(List<int> plain) async {
    final box = await _aes.encrypt(plain, secretKey: _key);
    return Uint8List.fromList([..._fileMagic, ...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Бросает [WrongSecretException], если ключ не подходит или данные испорчены.
  Future<Uint8List> decrypt(List<int> data) async {
    if (!isEncrypted(data) || data.length < 4 + _nonceLength + _macLength) {
      throw const WrongSecretException();
    }
    final box = SecretBox(
      data.sublist(4 + _nonceLength, data.length - _macLength),
      nonce: data.sublist(4, 4 + _nonceLength),
      mac: Mac(data.sublist(data.length - _macLength)),
    );
    try {
      return Uint8List.fromList(await _aes.decrypt(box, secretKey: _key));
    } on SecretBoxAuthenticationError {
      throw const WrongSecretException();
    }
  }

  static bool isEncrypted(List<int> data) =>
      data.length >= 4 &&
      data[0] == _fileMagic[0] &&
      data[1] == _fileMagic[1] &&
      data[2] == _fileMagic[2] &&
      data[3] == _fileMagic[3];

  /// Ключ данных, зашифрованный другим ключом — для хранения в vault.
  Future<String> _wrapWith(DataCipher kek) async => base64.encode(await kek.encrypt(_keyBytes));

  static Future<DataCipher> _unwrap(String wrapped, DataCipher kek) async =>
      DataCipher._(await kek.decrypt(base64.decode(wrapped)));
}

/// Параметры Argon2id, с которыми выведен ключ. Хранятся рядом с солью,
/// чтобы их можно было усилить в будущих версиях, не ломая старые файлы.
class KdfParams {
  final List<int> salt;
  final int memory; // КиБ
  final int iterations;

  const KdfParams({required this.salt, this.memory = 47104, this.iterations = 2});

  factory KdfParams.random() => KdfParams(salt: _randomBytes(16));

  Map<String, dynamic> toJson() => {
        'alg': 'argon2id',
        'salt': base64.encode(salt),
        'memory': memory,
        'iterations': iterations,
      };

  factory KdfParams.fromJson(Map<String, dynamic> j) => KdfParams(
        salt: base64.decode(j['salt'] as String),
        memory: j['memory'] as int,
        iterations: j['iterations'] as int,
      );

  /// Argon2id — в отдельном изоляте: вычисление занимает до секунды.
  Future<DataCipher> derive(String secret) async {
    final salt = this.salt, memory = this.memory, iterations = this.iterations;
    final bytes = await Isolate.run(() async {
      final key = await DartArgon2id(
        parallelism: 1,
        memory: memory,
        iterations: iterations,
        hashLength: 32,
      ).deriveKeyFromPassword(password: secret, nonce: salt);
      return key.extractBytes();
    });
    return DataCipher._(bytes);
  }
}

/// Recovery code: 24 символа из букв и цифр без похожих (I/l/1, O/0),
/// показывается группами по 4 — «WJKj-skjf-…». Около 140 бит случайности.
abstract final class RecoveryCode {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  static const length = 24;

  static String generate() {
    final rnd = Random.secure();
    final raw = List.generate(length, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join();
    return format(raw);
  }

  static String format(String raw) {
    final s = normalize(raw);
    return [for (var i = 0; i < s.length; i += 4) s.substring(i, min(i + 4, s.length))].join('-');
  }

  /// Пробелы и дефисы при вводе не важны; регистр букв — важен.
  static String normalize(String input) => input.replaceAll(RegExp(r'[\s\-–—]'), '');

  static bool looksValid(String input) => normalize(input).length == length;
}

/// Запечатанный ключ данных: соль, параметры и обёртка для PIN и для кода.
class KeyEnvelope {
  final KdfParams pinKdf;
  final String pinWrap;
  final KdfParams recoveryKdf;
  final String recoveryWrap;

  const KeyEnvelope({
    required this.pinKdf,
    required this.pinWrap,
    required this.recoveryKdf,
    required this.recoveryWrap,
  });

  Map<String, dynamic> toJson() => {
        'pin': {...pinKdf.toJson(), 'wrap': pinWrap},
        'recovery': {...recoveryKdf.toJson(), 'wrap': recoveryWrap},
      };

  factory KeyEnvelope.fromJson(Map<String, dynamic> j) {
    final pin = j['pin'] as Map<String, dynamic>;
    final rec = j['recovery'] as Map<String, dynamic>;
    return KeyEnvelope(
      pinKdf: KdfParams.fromJson(pin),
      pinWrap: pin['wrap'] as String,
      recoveryKdf: KdfParams.fromJson(rec),
      recoveryWrap: rec['wrap'] as String,
    );
  }

  Future<DataCipher> openWithPin(String pin) async =>
      DataCipher._unwrap(pinWrap, await pinKdf.derive(pin));

  Future<DataCipher> openWithRecovery(String code) async =>
      DataCipher._unwrap(recoveryWrap, await recoveryKdf.derive(RecoveryCode.normalize(code)));

  /// Только часть для recovery code — её кладём в резервные копии.
  Map<String, dynamic> recoveryJson() => {...recoveryKdf.toJson(), 'wrap': recoveryWrap};

  static Future<DataCipher> openRecoveryJson(Map<String, dynamic> j, String code) async =>
      DataCipher._unwrap(
          j['wrap'] as String, await KdfParams.fromJson(j).derive(RecoveryCode.normalize(code)));
}

/// Файл vault.json в папке данных.
class Vault {
  final File file;
  KeyEnvelope? _envelope;

  Vault(Directory root) : file = File('${root.path}/vault.json');

  KeyEnvelope? get envelope => _envelope;
  bool get isSetUp => _envelope != null;

  Future<void> load() async {
    if (await file.exists()) {
      final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _envelope = KeyEnvelope.fromJson(j);
    }
  }

  /// Первая настройка: новый ключ данных и новый recovery code.
  Future<(DataCipher, String)> create(String pin) async {
    final data = await DataCipher.generate();
    final code = RecoveryCode.generate();
    final pinKdf = KdfParams.random(), recKdf = KdfParams.random();
    final (pinKek, recKek) = await (pinKdf.derive(pin), recKdf.derive(RecoveryCode.normalize(code))).wait;
    _envelope = KeyEnvelope(
      pinKdf: pinKdf,
      pinWrap: await data._wrapWith(pinKek),
      recoveryKdf: recKdf,
      recoveryWrap: await data._wrapWith(recKek),
    );
    await _save();
    return (data, code);
  }

  Future<DataCipher> unlock(String pin) => _envelope!.openWithPin(pin);

  Future<DataCipher> unlockWithRecovery(String code) => _envelope!.openWithRecovery(code);

  /// Новый PIN для того же ключа данных; recovery code не меняется.
  Future<void> changePin(DataCipher data, String newPin) async {
    final kdf = KdfParams.random();
    final env = _envelope!;
    _envelope = KeyEnvelope(
      pinKdf: kdf,
      pinWrap: await data._wrapWith(await kdf.derive(newPin)),
      recoveryKdf: env.recoveryKdf,
      recoveryWrap: env.recoveryWrap,
    );
    await _save();
  }

  Future<void> _save() async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert({'version': 1, ..._envelope!.toJson()}));
    await tmp.rename(file.path);
  }
}

List<int> _randomBytes(int n) {
  final rnd = Random.secure();
  return List.generate(n, (_) => rnd.nextInt(256));
}
