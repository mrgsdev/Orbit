import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../data/contact_store.dart';
import 'home_page.dart' show Segment;
import 'theme.dart';
import 'widgets.dart';
import '../l10n/strings.dart';

/// Главная: приветствие и три крупные цифры.
class Dashboard extends StatefulWidget {
  final ContactStore store;
  final ValueChanged<Segment> onSegment;

  const Dashboard({super.key, required this.store, required this.onSegment});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  ContactStore get store => widget.store;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return tr.goodNight;
    if (h < 12) return tr.goodMorning;
    if (h < 18) return tr.goodAfternoon;
    return tr.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = store.contacts;
    final newMonth = all.where((c) => now.difference(c.createdAt).inDays < 30).length;
    final birthdays = all.where((c) => (c.daysUntilBirthday(now) ?? 999) <= 30).length;

    return ScrollArea(
      builder: (controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // В узком окне карточки встают друг под другом.
            final narrow = constraints.maxWidth < 860;
            // Высота карточки следует за шириной: тогда картинка всегда
            // в 1,3 раза выше карточки и выходит за край при любом окне,
            // а текст рядом с ней помещается.
            final cardWidth = narrow ? constraints.maxWidth : (constraints.maxWidth - 28) / 3;
            final cardHeight = (cardWidth * 0.46).clamp(130.0, 200.0);
            final overflow = cardHeight * 0.3;
            final cards = [
              _TicketCard(
                color: Pal.teal,
                title: tr.totalContacts,
                value: '${all.length}',
                art: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                notchRight: !narrow,
                onTap: () => widget.onSegment(Segment.all),
              ),
              _TicketCard(
                color: Pal.yellow,
                title: tr.segRecent,
                value: '$newMonth',
                art: const _Art('assets/images/card_new.png', fallback: '🤝'),
                notchLeft: !narrow,
                notchRight: !narrow,
                onTap: () => widget.onSegment(Segment.recent),
              ),
              _TicketCard(
                color: Pal.pink,
                title: tr.segBirthdays,
                value: '$birthdays',
                art: const _Art('assets/images/card_birthdays.png', fallback: '🎂'),
                notchLeft: !narrow,
                onTap: () => widget.onSegment(Segment.birthdays),
              ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_greeting(), style: T.display),
                // Место сверху: картинки карточек выходят за их край.
                SizedBox(height: overflow + 12),
                if (narrow)
                  for (final c in cards)
                    Padding(
                      padding: EdgeInsets.only(bottom: overflow + 14),
                      child: SizedBox(height: cardHeight, child: c),
                    )
                else
                  SizedBox(
                    height: cardHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 14),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Иллюстрация карточки; пока картинки нет в assets — эмодзи.
class _Art extends StatelessWidget {
  final String asset;
  final String fallback;
  const _Art(this.asset, {required this.fallback});

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: BoxFit.contain,
        // Исходники крупные, а на карточке нужно ~150 точек.
        cacheWidth: (300 * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => Transform.rotate(
          angle: -0.12,
          child: Text(fallback, style: const TextStyle(fontSize: 96, height: 1.1)),
        ),
      );
}

/// Яркая карточка-«билет» с вырезами по краям.
class _TicketCard extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final Widget art;
  final bool notchLeft;
  final bool notchRight;
  final VoidCallback onTap;

  const _TicketCard({
    required this.color,
    required this.title,
    required this.value,
    required this.art,
    this.notchLeft = false,
    this.notchRight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        pressScale: 0.985,
        builder: (context, hover, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: ShapeDecoration(
            color: hover ? Color.lerp(color, const Color(0xFFFFFFFF), 0.08) : color,
            shape: _TicketBorder(left: notchLeft, right: notchRight),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              // Картинка крупнее карточки и выходит за верхний край, как
              // фигура на макете; текст при этом не заходит под неё.
              // На узкой карточке чуть меньше, чтобы не наезжать на заголовок,
              // но всегда выше карточки.
              final h = c.maxHeight;
              final art = math.max(h * 1.12, math.min(h * 1.3, c.maxWidth * 0.56));
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(right: 0, bottom: 2, width: art, height: art, child: FittedBox(child: this.art)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, c.maxHeight * 0.12, art * 0.55, c.maxHeight * 0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(title, style: T.heading.copyWith(color: Pal.onAccent, fontSize: 16)),
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(value, style: T.number.copyWith(color: Pal.onAccent, fontSize: 42)),
                        ),
                        const Spacer(),
                        Text(
                          tr.viewList,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.body.copyWith(color: Pal.onAccent.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

/// Скруглённый прямоугольник с полукруглыми вырезами по бокам — «билет».
class _TicketBorder extends ShapeBorder {
  final bool left;
  final bool right;
  const _TicketBorder({this.left = false, this.right = false});

  static const _radius = 30.0;
  static const _notch = 9.0;
  static const _positions = [0.24, 0.76];

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    var path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(_radius)));
    for (final f in _positions) {
      final y = rect.top + rect.height * f;
      if (left) {
        path = Path.combine(PathOperation.difference, path, Path()..addOval(Rect.fromCircle(center: Offset(rect.left, y), radius: _notch)));
      }
      if (right) {
        path = Path.combine(PathOperation.difference, path, Path()..addOval(Rect.fromCircle(center: Offset(rect.right, y), radius: _notch)));
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
