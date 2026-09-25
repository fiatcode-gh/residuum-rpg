import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'crawl_style.dart';

Rect heroBlock(Rect hero) => Rect.fromLTRB(
  hero.left - hero.width - 4,
  hero.top - hero.height - 4,
  hero.right + hero.width + 4,
  hero.bottom + hero.height + 4,
);

Rect placeMapOverlay({
  required Rect area,
  required Size size,
  required Rect hero,
  required List<Offset> preferred,
  List<Rect> avoid = const [],
}) {
  final block = heroBlock(hero);
  final maxLeft = math.max(
    area.left + crawlOverlayMargin,
    area.right - crawlOverlayMargin - size.width,
  );
  final maxTop = math.max(
    area.top + crawlOverlayMargin,
    area.bottom - crawlOverlayMargin - size.height,
  );
  final candidates =
      [
            ...preferred,
            Offset(
              area.left + crawlOverlayMargin,
              area.top + crawlOverlayMargin,
            ),
            Offset(
              area.right - crawlOverlayMargin - size.width,
              area.top + crawlOverlayMargin,
            ),
            Offset(
              area.left + crawlOverlayMargin,
              area.bottom - crawlOverlayMargin - size.height,
            ),
            Offset(
              area.right - crawlOverlayMargin - size.width,
              area.bottom - crawlOverlayMargin - size.height,
            ),
          ]
          .map((offset) {
            final left = offset.dx.clamp(
              area.left + crawlOverlayMargin,
              maxLeft,
            );
            final top = offset.dy.clamp(area.top + crawlOverlayMargin, maxTop);
            return Offset(left, top) & size;
          })
          .toList(growable: false);

  for (final candidate in candidates) {
    if (!candidate.overlaps(block) &&
        !avoid.any((rect) => candidate.overlaps(rect))) {
      return candidate;
    }
  }
  for (final candidate in candidates) {
    if (!candidate.overlaps(block)) return candidate;
  }
  for (final candidate in candidates) {
    if (!candidate.overlaps(hero)) return candidate;
  }
  return candidates.reduce(
    (best, candidate) =>
        _overlapArea(candidate, hero) < _overlapArea(best, hero)
        ? candidate
        : best,
  );
}

double _overlapArea(Rect rect, Rect other) {
  final overlap = rect.intersect(other);
  if (overlap.width <= 0 || overlap.height <= 0) return 0;
  return overlap.width * overlap.height;
}

Rect placeActionCard({
  required Size map,
  required double height,
  required Rect hero,
  Rect? strip,
}) {
  const m = crawlOverlayMargin;
  final w = map.width - 2 * m;
  final stripAtTop = strip != null && strip.center.dy < map.height / 2;
  final topLimit = stripAtTop ? strip.bottom : 0.0;
  final bottomLimit = strip != null && !stripAtTop ? strip.top : map.height;
  final bottom = Rect.fromLTWH(m, bottomLimit - m - height, w, height);
  final top = Rect.fromLTWH(m, topLimit + m, w, height);
  final block = heroBlock(hero);
  if (!bottom.overlaps(block)) return bottom;
  if (!top.overlaps(block)) return top;
  return _overlapArea(bottom, block) <= _overlapArea(top, block) ? bottom : top;
}

(Offset, Offset)? actionCardLeader({
  required Size map,
  required Rect card,
  required Rect hero,
}) {
  if (!(Offset.zero & map).overlaps(hero)) return null;
  final x = hero.center.dx;
  final tx = x.clamp(card.left + 6, card.right - 6);
  if (card.center.dy >= hero.center.dy) {
    return (Offset(x, hero.bottom), Offset(tx, card.top));
  }
  return (Offset(x, hero.top), Offset(tx, card.bottom));
}

Rect recenterRect(Size map, {Rect? actionCard}) {
  final base = Rect.fromLTWH(
    map.width - 8 - crawlTouchTarget,
    map.height - 8 - crawlTouchTarget,
    crawlTouchTarget,
    crawlTouchTarget,
  );
  if (actionCard == null || !base.overlaps(actionCard)) return base;
  return Rect.fromLTWH(
    base.left,
    actionCard.top - 8 - crawlTouchTarget,
    crawlTouchTarget,
    crawlTouchTarget,
  );
}
