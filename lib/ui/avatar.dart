import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

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

/// Аватар: фото или яркая монограмма в цветах дашборда.
class ContactAvatar extends StatelessWidget {
  final String name;
  final ImageProvider? photo;
  final double radius;

  /// Обводка цветом фона — для аватаров внахлёст.
  final Color? ring;

  const ContactAvatar({super.key, required this.name, required this.photo, this.radius = 20, this.ring});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final photo = this.photo;
    final Widget avatar;
    if (photo != null) {
      avatar = ClipOval(
        // Ключ по фото: после замены картинка не берётся из кэша.
        key: ValueKey(photo),
        child: Image(
          // Декодируем с запасом: у ResizeImage нет режима cover,
          // а так альбомные фото до 2:1 не мылятся при обрезке в круг.
          image: ResizeImage(
            photo,
            width: (radius * 4 * MediaQuery.devicePixelRatioOf(context)).round(),
            policy: ResizeImagePolicy.fit,
          ),
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      );
    } else {
      final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
      final initials = parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
      final color = initials.isEmpty ? Pal.raised : TagColors.hue(name);
      avatar = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, const Color(0xFFFFFFFF), 0.25)!, color],
          ),
        ),
        child: initials.isEmpty
            ? Icon(CupertinoIcons.person_fill, size: radius, color: Pal.muted)
            : Text(
                initials,
                style: T.body.copyWith(
                  fontSize: radius * 0.72,
                  fontWeight: FontWeight.w700,
                  color: Pal.onAccent,
                ),
              ),
      );
    }
    if (ring == null) return avatar;
    return Container(
      padding: EdgeInsets.all(radius > 30 ? 4 : 2),
      decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
      child: avatar,
    );
  }
}
