import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/map_overlay_layout.dart';

void main() {
  group('heroBlock', () {
    test('pads the hero cell by its own extent on every side, plus 4', () {
      final hero = Offset(150, 150) & Size(24, 30);
      expect(heroBlock(hero), const Rect.fromLTRB(122, 116, 202, 214));
    });
  });

  group('placeMapOverlay', () {
    test('a clear preferred candidate wins outright', () {
      final hero = Offset(140, 140) & Size(24, 30);
      final placed = placeMapOverlay(
        area: Offset.zero & const Size(300, 300),
        size: const Size(50, 50),
        hero: hero,
        preferred: const [Offset(10, 10)],
      );
      expect(placed, const Rect.fromLTWH(10, 10, 50, 50));
    });

    test('every candidate clamps into the map at each edge', () {
      final hero = Offset(140, 140) & Size(24, 30);
      const map = Size(300, 300);
      const size = Size(50, 50);
      Rect place(Offset preferred) => placeMapOverlay(
        area: Offset.zero & map,
        size: size,
        hero: hero,
        preferred: [preferred],
      );

      expect(
        place(const Offset(-1000, -1000)),
        const Rect.fromLTWH(8, 8, 50, 50),
      );
      expect(
        place(const Offset(9999, 9999)),
        const Rect.fromLTWH(242, 242, 50, 50),
      );
      expect(
        place(const Offset(-1000, 9999)),
        const Rect.fromLTWH(8, 242, 50, 50),
      );
      expect(
        place(const Offset(9999, -1000)),
        const Rect.fromLTWH(242, 8, 50, 50),
      );
    });

    test('pass 1 skips a preferred candidate that hits an avoid rect', () {
      // The hero sits far from every candidate, so only the avoid rect
      // decides: it covers the preferred spot but misses the top-left
      // corner, so the corner is what pass 1 returns.
      final hero = Offset(190, 190) & Size(8, 8);
      final placed = placeMapOverlay(
        area: Offset.zero & const Size(200, 200),
        size: const Size(40, 20),
        hero: hero,
        preferred: const [Offset(50, 50)],
        avoid: const [Rect.fromLTWH(40, 40, 60, 60)],
      );
      expect(placed, const Rect.fromLTWH(8, 8, 40, 20));
    });

    test('pass 2 lands on the preferred spot when every candidate hits the '
        'avoid rect', () {
      final hero = Offset(190, 190) & Size(8, 8);
      final placed = placeMapOverlay(
        area: Offset.zero & const Size(200, 200),
        size: const Size(40, 20),
        hero: hero,
        preferred: const [Offset(50, 50)],
        avoid: const [Rect.fromLTWH(0, 0, 200, 200)],
      );
      expect(placed, const Rect.fromLTWH(50, 50, 40, 20));
    });

    test('pass 3 clears the hero cell even though the padded block cannot '
        'be avoided', () {
      // A floor barely wider than two side-by-side candidates: the map's
      // own height collapses the vertical clamp to one value, so only the
      // left and right corners differ. The hero sits under the right
      // candidate but not the left one, and its padded block still reaches
      // the left candidate by 2 dp — pass 1 and 2 both fail for both, and
      // pass 3 picks the left candidate because it alone misses the hero.
      final hero = Offset(60, 8) & Size(20, 20);
      final placed = placeMapOverlay(
        area: Offset.zero & const Size(100, 36),
        size: const Size(30, 20),
        hero: hero,
        preferred: const [],
      );
      expect(placed, const Rect.fromLTWH(8, 8, 30, 20));
    });

    test('pass 3 keeps the avoid list clear even after giving up the padded '
        'block, before falling back to the hero cell alone (F1)', () {
      // Two candidates each miss the hero cell but sit inside its padded
      // block, like a melee target's own cell always does. `avoid`
      // covers the first one (standing in for the target's own cell) —
      // the second, later candidate must win instead of the first.
      final hero = Offset(100, 100) & const Size(20, 20);
      final placed = placeMapOverlay(
        area: const Rect.fromLTWH(60, 60, 100, 100),
        size: const Size(20, 20),
        hero: hero,
        preferred: const [Offset(76, 100), Offset(120, 100)],
        avoid: const [Rect.fromLTWH(76, 100, 20, 20)],
      );
      expect(placed, const Rect.fromLTWH(120, 100, 20, 20));
    });

    test('pass 5 picks the candidate with the smallest hero overlap when '
        'none can miss it', () {
      // Both candidates sit inside the hero's own padded block, and both
      // the hero cell itself, but the hero's rectangle overlaps the right
      // candidate by far less than the left one.
      final hero = Offset(20, 8) & Size(50, 20);
      final placed = placeMapOverlay(
        area: Offset.zero & const Size(100, 36),
        size: const Size(30, 20),
        hero: hero,
        preferred: const [Offset(8, 8), Offset(62, 8)],
      );
      expect(placed, const Rect.fromLTWH(62, 8, 30, 20));
    });

    test('never overlaps the padded hero block on the target map, hero '
        'centred, at each corner and each edge midpoint', () {
      const map = Size(392.7, 568.8);
      const cell = Size(24, 30);
      const popup = Size(300, 170);
      final rightEdge = map.width - cell.width;
      final bottomEdge = map.height - cell.height;
      final positions = [
        Offset(rightEdge / 2, bottomEdge / 2), // centre
        const Offset(0, 0), // top-left corner
        Offset(rightEdge, 0), // top-right corner
        Offset(0, bottomEdge), // bottom-left corner
        Offset(rightEdge, bottomEdge), // bottom-right corner
        Offset(rightEdge / 2, 0), // top edge midpoint
        Offset(rightEdge / 2, bottomEdge), // bottom edge midpoint
        Offset(0, bottomEdge / 2), // left edge midpoint
        Offset(rightEdge, bottomEdge / 2), // right edge midpoint
      ];

      for (final topLeft in positions) {
        final hero = topLeft & cell;
        final hc = hero.center;
        final block = heroBlock(hero);
        final placed = placeMapOverlay(
          area: Offset.zero & map,
          size: popup,
          hero: hero,
          preferred: [
            Offset(hc.dx - popup.width / 2, block.bottom + 6),
            Offset(hc.dx - popup.width / 2, block.top - 6 - popup.height),
          ],
        );
        expect(
          placed.overlaps(heroBlock(hero)),
          isFalse,
          reason: 'hero at $topLeft',
        );
      }
    });

    test('when an avoid rect covers the whole area, pass 1 fails and the '
        'result still lies inside the area minus the 8 dp margin', () {
      const area = Rect.fromLTRB(0, 100, 300, 220);
      final hero = Offset(1000, 1000) & const Size(24, 30);
      final placed = placeMapOverlay(
        area: area,
        size: const Size(50, 20),
        hero: hero,
        preferred: const [],
        avoid: const [area],
      );
      expect(placed.left, greaterThanOrEqualTo(area.left + 8));
      expect(placed.top, greaterThanOrEqualTo(area.top + 8));
      expect(placed.right, lessThanOrEqualTo(area.right - 8));
      expect(placed.bottom, lessThanOrEqualTo(area.bottom - 8));
    });
  });

  group('recenterRect', () {
    test('is a 48 dp square in the map\'s bottom-right corner', () {
      expect(
        recenterRect(const Size(300, 400)),
        Rect.fromLTWH(
          300 - 8 - crawlTouchTarget,
          400 - 8 - crawlTouchTarget,
          crawlTouchTarget,
          crawlTouchTarget,
        ),
      );
    });
  });

  group('target card vs the strip (D1)', () {
    test('on the Task 13 widget map, a melee target next to a hero panned '
        'low still lands the card clear of the turn-order strip', () {
      // 423.9 is the Task 13 widget map height at s 1.0, measured by the
      // untracked probe (PLAN.md §10.1): the bar replaces the action card,
      // so this area is bounded only by the strip now.
      const map = Size(392.7, 423.9);
      const cellSize = Size(24, 30);
      const cardSize = Size(172, 95);
      const stripHeight = 48.0;

      final hero = const Offset(184.35, 385.9) & cellSize;
      final targetCell =
          Offset(hero.left + cellSize.width, hero.top) & cellSize;
      final strip = Rect.fromLTWH(0, 0, map.width, stripHeight);

      final area = targetCardArea(map: map, strip: strip);

      final placed = placeMapOverlay(
        area: area,
        size: cardSize,
        hero: hero,
        preferred: [
          Offset(
            targetCell.right + crawlCalloutMargin,
            targetCell.top - crawlCalloutLeaderGap - cardSize.height,
          ),
          Offset(
            targetCell.left - crawlCalloutMargin - cardSize.width,
            targetCell.top - crawlCalloutLeaderGap - cardSize.height,
          ),
          Offset(
            targetCell.right + crawlCalloutMargin,
            targetCell.bottom + crawlCalloutLeaderGap,
          ),
          Offset(
            targetCell.left - crawlCalloutMargin - cardSize.width,
            targetCell.bottom + crawlCalloutLeaderGap,
          ),
        ],
        avoid: [targetCell],
      );

      expect(
        placed.overlaps(strip),
        isFalse,
        reason: 'D1: the target card must never cover the turn-order strip',
      );
      expect(placed.overlaps(heroBlock(hero)), isFalse);
    });
  });

  group('targetCardArea', () {
    test('is the full map when there is no strip', () {
      const map = Size(300, 400);
      expect(
        targetCardArea(map: map),
        Rect.fromLTRB(0, 0, map.width, map.height),
      );
    });

    test('excludes the strip\'s rows from the top when it sits at the top', () {
      const map = Size(300, 400);
      const strip = Rect.fromLTWH(0, 0, 300, 48);
      expect(
        targetCardArea(map: map, strip: strip),
        const Rect.fromLTRB(0, 48, 300, 400),
      );
    });

    test('excludes the strip\'s rows from the bottom when it is flipped', () {
      const map = Size(300, 400);
      const strip = Rect.fromLTWH(0, 352, 300, 48);
      expect(
        targetCardArea(map: map, strip: strip),
        const Rect.fromLTRB(0, 0, 300, 352),
      );
    });
  });

  group('the target card never covers the strip or the hero cell, and (at '
      's 1.0) never the target cell either (D1/F1 sweep)', () {
    test('across the full content grid, on both Task 13 widget map sizes', () {
      const cellSize = Size(24, 30);
      const cardWidth = 172.0;
      const offsets = [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
        Offset(1, 1),
        Offset(1, -1),
        Offset(-1, 1),
        Offset(-1, -1),
      ];

      double targetHeightFor(int lines, double scale) =>
          crawlCalloutPadding * 2 +
          crawlCalloutNameRow * scale +
          crawlCalloutGap +
          crawlCalloutHpRow * scale +
          crawlCalloutBarRow +
          crawlCalloutLineHeight * scale * lines;

      void sweep(
        Size map,
        double scale,
        int lines, {
        required bool expectTargetCellClear,
      }) {
        final card = Size(cardWidth, targetHeightFor(lines, scale));
        final stripHeight = crawlStripHeight * scale;
        for (
          var heroLeft = 0.0;
          heroLeft <= map.width - cellSize.width;
          heroLeft += 12
        ) {
          for (
            var heroTop = 0.0;
            heroTop <= map.height - cellSize.height;
            heroTop += 8
          ) {
            final hero = Offset(heroLeft, heroTop) & cellSize;
            final topBand = Rect.fromLTWH(0, 0, map.width, stripHeight);
            final flipped = topBand.overlaps(hero);
            final stripWidth = flipped ? map.width - 64 : map.width;
            final strip = Rect.fromLTWH(
              0,
              flipped ? map.height - stripHeight : 0,
              stripWidth,
              stripHeight,
            );
            final area = targetCardArea(map: map, strip: strip);
            final block = heroBlock(hero);

            for (final offset in offsets) {
              final targetCell =
                  Offset(
                    hero.left + offset.dx * cellSize.width,
                    hero.top + offset.dy * cellSize.height,
                  ) &
                  cellSize;
              final placed = placeMapOverlay(
                area: area,
                size: card,
                hero: hero,
                preferred: [
                  Offset(
                    targetCell.right + crawlCalloutMargin,
                    targetCell.top - crawlCalloutLeaderGap - card.height,
                  ),
                  Offset(
                    targetCell.left - crawlCalloutMargin - card.width,
                    targetCell.top - crawlCalloutLeaderGap - card.height,
                  ),
                  Offset(
                    targetCell.right + crawlCalloutMargin,
                    targetCell.bottom + crawlCalloutLeaderGap,
                  ),
                  Offset(
                    targetCell.left - crawlCalloutMargin - card.width,
                    targetCell.bottom + crawlCalloutLeaderGap,
                  ),
                  Offset(
                    hero.center.dx - card.width / 2,
                    block.bottom + crawlCalloutLeaderGap,
                  ),
                  Offset(
                    hero.center.dx - card.width / 2,
                    block.top - crawlCalloutLeaderGap - card.height,
                  ),
                ],
                avoid: [targetCell],
              );
              final reason =
                  'map $map scale $scale lines $lines hero $hero '
                  'offset $offset';
              expect(placed.overlaps(strip), isFalse, reason: 'strip: $reason');
              expect(
                placed.overlaps(hero),
                isFalse,
                reason: 'hero cell: $reason',
              );
              if (expectTargetCellClear) {
                expect(
                  placed.overlaps(targetCell),
                  isFalse,
                  reason: 'target cell: $reason',
                );
              }
            }
          }
        }
      }

      // `placeFacts` and `cardVerbsFor` no longer shape this area (the bar
      // owns them off the map now); only the target card's own height
      // varies, 2–4 lines being `targetFactLines`'s own ceiling (no
      // bestiary entry carries more than 1 resist and 1 vulnerability).
      // Both Task 13 widget map sizes are proven clear of the strip and the
      // hero's own cell; the target cell is proven clear too at s 1.0. At
      // s 1.3 the target cell is not asserted here — this is an
      // intermediate map (the log row still stands), and Task 14 re-runs
      // this sweep on the final map.
      for (final lines in [2, 3, 4]) {
        sweep(
          const Size(392.7, 423.9),
          1.0,
          lines,
          expectTargetCellClear: true,
        );
        sweep(
          const Size(392.7, 369.4),
          1.3,
          lines,
          expectTargetCellClear: false,
        );
      }
    });
  });
}
