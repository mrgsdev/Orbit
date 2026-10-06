import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/contact_store.dart';
import '../models/contact.dart';
import 'theme.dart';

extension StorePhotos on ContactStore {
  ImageProvider? photoOf(Contact c) => photoFile(c.photoFile);

  ImageProvider? photoFile(String? name) => hasPhoto(name) ? EncryptedPhoto(this, name!) : null;
}

/// Фото из хранилища: файл на диске зашифрован, расшифровываем при загрузке.
class EncryptedPhoto extends ImageProvider<EncryptedPhoto> {
  final ContactStore store;
  final String name;

  const EncryptedPhoto(this.store, this.name);

  @override
  Future<EncryptedPhoto> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(EncryptedPhoto key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1, debugLabel: name);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await store.readPhoto(name);
    if (bytes == null) throw StateError('Фото $name не найдено');
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is EncryptedPhoto && other.name == name && identical(other.store, store);

  @override
  int get hashCode => Object.hash(name, store);
}

class ContactAvatar extends StatelessWidget {
  final String name;
  final ImageProvider? photo;
  final double radius;

  /// Обводка цветом поверхности — для аватаров, наложенных друг на друга.
  final bool ring;

  const ContactAvatar({
    super.key,
    required this.name,
    required this.photo,
    this.radius = 20,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photo = this.photo;
    final Widget avatar;
    if (photo != null) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: c.surfaceMuted,
        // Ключ по фото: после замены картинка не берётся из кэша.
        key: ValueKey(photo),
        // Декодируем с запасом по ширине: у ResizeImage нет режима cover,
        // а так альбомные фото до 2:1 не мылятся при обрезке в круг.
        backgroundImage: ResizeImage(
          photo,
          width: (radius * 4 * MediaQuery.devicePixelRatioOf(context)).round(),
          policy: ResizeImagePolicy.fit,
        ),
      );
    } else {
      final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
      final initials = parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
      final (bg, fg) = TagColors.of(name, Theme.of(context).brightness);
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: initials.isEmpty
            ? Icon(Icons.person_rounded, size: radius, color: fg)
            : Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.72,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
      );
    }
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
      child: avatar,
    );
  }
}
