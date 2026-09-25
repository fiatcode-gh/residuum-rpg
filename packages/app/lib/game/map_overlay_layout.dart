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
  required Size map,
  required Size size,
  required Rect hero,
  required List<Offset> preferred,
  List<Rect> avoid = const [],
}) {
  final block = heroBlock(hero);
  final maxLeft = math.max(
    crawlOverlayMargin,
    map.width - crawlOverlayMargin - size.width,
  );
  final maxTop = math.max(
    crawlOverlayMargin,
    map.height - crawlOverlayMargin - size.height,
  );
  final candidates =
      [
            ...preferred,
            const Offset(crawlOverlayMargin, crawlOverlayMargin),
            Offset(
              map.width - crawlOverlayMargin - size.width,
              crawlOverlayMargin,
            ),
            Offset(
              crawlOverlayMargin,
              map.height - crawlOverlayMargin - size.height,
            ),
            Offset(
              map.width - crawlOverlayMargin - size.width,
              map.height - crawlOverlayMargin - size.height,
            ),
          ]
          .map((offset) {
            final left = offset.dx.clamp(crawlOverlayMargin, maxLeft);
            final top = offset.dy.clamp(crawlOverlayMargin, maxTop);
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

double _overlapArea(Rect rect, Rect hero) {
  final overlap = rect.intersect(hero);
  if (overlap.width <= 0 || overlap.height <= 0) return 0;
  return overlap.width * overlap.height;
}

Rect recenterRect(Size map) => Rect.fromLTWH(
  map.width - 8 - crawlTouchTarget,
  map.height - 8 - crawlTouchTarget,
  crawlTouchTarget,
  crawlTouchTarget,
);
