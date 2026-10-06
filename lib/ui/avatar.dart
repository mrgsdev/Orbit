import 'dart:io';

import 'package:flutter/material.dart';

import 'theme.dart';

class ContactAvatar extends StatelessWidget {
  final String name;
  final File? photo;
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
    if (photo != null && photo.existsSync()) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: c.surfaceMuted,
        // Ключ по пути: после замены фото картинка не берётся из кэша.
        key: ValueKey(photo.path),
        // Декодируем с запасом по ширине: у ResizeImage нет режима cover,
        // а так альбомные фото до 2:1 не мылятся при обрезке в круг.
        backgroundImage: ResizeImage(
          FileImage(photo),
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
