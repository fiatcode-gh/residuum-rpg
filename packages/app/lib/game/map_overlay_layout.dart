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
    if (!candidate.overlaps(hero) &&
        !avoid.any((rect) => candidate.overlaps(rect))) {
      return candidate;
    }
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

Rect eventsStripRect(Size map, double scale) {
  final h =
      crawlEventsStripTop +
      crawlEventsLines * crawlLogLine * scale +
      crawlEventsStripBottom;
  return Rect.fromLTWH(0, map.height - h, map.width, h);
}

Rect targetCardArea({required Size map, required Rect events, Rect? strip}) {
  final stripAtTop = strip != null && strip.center.dy < map.height / 2;
  final top = stripAtTop ? strip.bottom : 0.0;
  final bottom = strip != null && !stripAtTop ? strip.top : events.top;
  return Rect.fromLTRB(0, top, map.width, bottom);
}

Rect recenterRect(Size map, {required Rect events}) => Rect.fromLTWH(
  map.width - 8 - crawlTouchTarget,
  events.top - 8 - crawlTouchTarget,
  crawlTouchTarget,
  crawlTouchTarget,
);

({Rect rect, bool flipped}) turnOrderStripRect({
  required Size map,
  required double height,
  required Rect hero,
  required Rect events,
}) {
  final top = Rect.fromLTWH(0, 0, map.width, height);
  final flipped = top.overlaps(hero);
  final rect = flipped
      ? Rect.fromLTWH(0, events.top - height, map.width - 64, height)
      : top;
  return (rect: rect, flipped: flipped);
}
