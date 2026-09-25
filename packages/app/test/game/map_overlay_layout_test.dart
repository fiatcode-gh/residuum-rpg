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

    test('pass 4 picks the candidate with the smallest hero overlap when '
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

  group('placeActionCard', () {
    test('sits at the bottom edge, full width, when the hero is clear', () {
      final hero = Offset(140, 140) & const Size(24, 30);
      final placed = placeActionCard(
        map: const Size(300, 300),
        height: 50,
        hero: hero,
      );
      expect(placed, const Rect.fromLTWH(8, 300 - 8 - 50, 300 - 16, 50));
    });

    test('falls back to the top edge when the bottom candidate hits the '
        'hero block', () {
      final hero = Offset(100, 260) & const Size(24, 30);
      final placed = placeActionCard(
        map: const Size(300, 300),
        height: 50,
        hero: hero,
      );
      expect(placed, const Rect.fromLTWH(8, 8, 300 - 16, 50));
    });

    test('sits below a top strip', () {
      final hero = Offset(100, 260) & const Size(24, 30);
      const strip = Rect.fromLTWH(0, 0, 300, 48);
      final placed = placeActionCard(
        map: const Size(300, 300),
        height: 50,
        hero: hero,
        strip: strip,
      );
      expect(placed.top, 56);
    });

    test('sits above a flipped, bottom-hugging strip', () {
      final hero = Offset(100, 20) & const Size(24, 30);
      const strip = Rect.fromLTWH(0, 300 - 48, 300, 48);
      final placed = placeActionCard(
        map: const Size(300, 300),
        height: 50,
        hero: hero,
        strip: strip,
      );
      expect(placed.bottom, strip.top - 8);
    });

    test('ties to the bottom when both edges overlap the block equally', () {
      const hero = Rect.fromLTWH(40, 52, 20, 16);
      final placed = placeActionCard(
        map: const Size(100, 120),
        height: 32,
        hero: hero,
      );
      expect(placed, const Rect.fromLTWH(8, 80, 84, 32));
    });

    test('never overlaps the padded hero block across the map, at either text '
        'scale, with or without the strip', () {
      void sweep(Size map, double height, bool withStrip) {
        for (var top = 0.0; top <= map.height - 30; top += 0.5) {
          final hero = Offset((map.width - 24) / 2, top) & const Size(24, 30);
          Rect? strip;
          if (withStrip) {
            const stripHeight = 48.0;
            final topStrip = Rect.fromLTWH(0, 0, map.width, stripHeight);
            final flipped = topStrip.overlaps(hero);
            final stripWidth = flipped ? map.width - 64 : map.width;
            strip = Rect.fromLTWH(
              0,
              flipped ? map.height - stripHeight : 0,
              stripWidth,
              stripHeight,
            );
          }
          final placed = placeActionCard(
            map: map,
            height: height,
            hero: hero,
            strip: strip,
          );
          expect(
            placed.overlaps(heroBlock(hero)),
            isFalse,
            reason: 'map $map, height $height, strip $withStrip, top $top',
          );
        }
      }

      for (final withStrip in [false, true]) {
        sweep(const Size(392.7, 561.9), 170, withStrip);
        sweep(const Size(392.7, 489.9), 110.4, withStrip);
      }
    });
  });

  group('actionCardLeader', () {
    const map = Size(300, 300);
    const card = Rect.fromLTWH(8, 200, 284, 60);

    test('runs from the hero\'s bottom edge to the card\'s top edge when the '
        'card sits below it', () {
      final hero = Offset(140, 60) & const Size(24, 30);
      final leader = actionCardLeader(map: map, card: card, hero: hero);
      expect(leader, (const Offset(152, 90), const Offset(152, 200)));
    });

    test('runs from the hero\'s top edge to the card\'s bottom edge when the '
        'card sits above it', () {
      final hero = Offset(140, 280) & const Size(24, 30);
      final leader = actionCardLeader(map: map, card: card, hero: hero);
      expect(leader, (const Offset(152, 280), const Offset(152, 260)));
    });

    test('clamps the card end 6 dp inside a side edge', () {
      final hero = Offset(2, 60) & const Size(24, 30);
      final leader = actionCardLeader(map: map, card: card, hero: hero);
      expect(leader!.$2.dx, card.left + 6);
    });

    test('is null when the hero cell is panned outside the map', () {
      final hero = Offset(-100, 60) & const Size(24, 30);
      expect(actionCardLeader(map: map, card: card, hero: hero), isNull);
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

    test('is unchanged when it does not overlap the action card', () {
      const map = Size(300, 400);
      const card = Rect.fromLTWH(8, 8, 284, 50);
      expect(recenterRect(map, actionCard: card), recenterRect(map));
    });

    test('lifts above the action card when it would overlap', () {
      const map = Size(300, 400);
      final base = recenterRect(map);
      final card = Rect.fromLTWH(8, base.top - 10, 284, 60);
      final lifted = recenterRect(map, actionCard: card);
      expect(lifted.bottom, card.top - 8);
      expect(lifted.left, base.left);
      expect(lifted.width, crawlTouchTarget);
      expect(lifted.height, crawlTouchTarget);
    });
  });

  group('target card vs the strip (D1)', () {
    test('on a real device layout, a melee target next to a hero panned low '
        'still lands the card clear of the turn-order strip', () {
      const map = Size(392.7, 557.9);
      const cellSize = Size(24, 30);
      const cardSize = Size(172, 95);
      const actionCardHeight = 68.0;
      const stripHeight = 48.0;

      // Hero centred horizontally, low enough that the padded hero block
      // still misses the bottom-pinned action card (it never flips) but
      // covers every other legal corner of the old, strip-blind area.
      final hero = const Offset(184.35, 384) & cellSize;
      final targetCell =
          Offset(hero.left + cellSize.width, hero.top) & cellSize;
      final strip = Rect.fromLTWH(0, 0, map.width, stripHeight);
      final card = placeActionCard(
        map: map,
        height: actionCardHeight,
        hero: hero,
        strip: strip,
      );
      expect(
        card.overlaps(heroBlock(hero)),
        isFalse,
        reason:
            'sanity: the action card must stay pinned to the bottom, '
            'matching the field report — a flipped card is a different '
            'scenario',
      );

      final area = targetCardArea(
        map: map,
        hero: hero,
        actionCard: card,
        strip: strip,
      );

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
        reason:
            'D1: the target card must never cover the turn-order '
            'strip',
      );
      expect(placed.overlaps(heroBlock(hero)), isFalse);
      expect(placed.overlaps(card), isFalse);
    });
  });

  group('targetCardArea', () {
    test('is the full map when there is no strip and no action card', () {
      const map = Size(300, 400);
      final hero = const Offset(140, 140) & const Size(24, 30);
      expect(
        targetCardArea(map: map, hero: hero),
        Rect.fromLTRB(0, 0, map.width, map.height),
      );
    });

    test('excludes the strip\'s rows from the top when it sits at the top', () {
      const map = Size(300, 400);
      final hero = const Offset(140, 300) & const Size(24, 30);
      const strip = Rect.fromLTWH(0, 0, 300, 48);
      expect(
        targetCardArea(map: map, hero: hero, strip: strip),
        const Rect.fromLTRB(0, 48, 300, 400),
      );
    });

    test('excludes the strip\'s rows from the bottom when it is flipped', () {
      const map = Size(300, 400);
      final hero = const Offset(140, 20) & const Size(24, 30);
      const strip = Rect.fromLTWH(0, 352, 300, 48);
      expect(
        targetCardArea(map: map, hero: hero, strip: strip),
        const Rect.fromLTRB(0, 0, 300, 352),
      );
    });

    test('excludes the action card\'s rows from the bottom when it sits below '
        'the hero', () {
      const map = Size(300, 400);
      final hero = const Offset(140, 140) & const Size(24, 30);
      const actionCard = Rect.fromLTWH(8, 300, 284, 50);
      expect(
        targetCardArea(map: map, hero: hero, actionCard: actionCard),
        const Rect.fromLTRB(0, 0, 300, 300),
      );
    });

    test('excludes the action card\'s rows from the top when it is flipped '
        'above the hero', () {
      const map = Size(300, 400);
      final hero = const Offset(140, 300) & const Size(24, 30);
      const actionCard = Rect.fromLTWH(8, 8, 284, 50);
      expect(
        targetCardArea(map: map, hero: hero, actionCard: actionCard),
        const Rect.fromLTRB(0, 58, 300, 400),
      );
    });

    test('excludes both the strip and the action card at once', () {
      const map = Size(300, 400);
      final hero = const Offset(140, 300) & const Size(24, 30);
      const strip = Rect.fromLTWH(0, 0, 300, 48);
      const actionCard = Rect.fromLTWH(8, 340, 284, 50);
      expect(
        targetCardArea(
          map: map,
          hero: hero,
          actionCard: actionCard,
          strip: strip,
        ),
        const Rect.fromLTRB(0, 48, 300, 340),
      );
    });
  });

  group('the target card never covers the strip, the hero block or the '
      'action card (D1 sweep)', () {
    test('across hero and target positions on both target map sizes, with '
        'the strip and action card present', () {
      const cellSize = Size(24, 30);
      const offsets = [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
        Offset(2, 2),
        Offset(-2, -2),
      ];

      void sweep(Size map, double scale, double actionHeight, Size card) {
        final stripHeight = crawlStripHeight * scale;
        final heroLefts = [
          0.0,
          (map.width - cellSize.width) / 2,
          map.width - cellSize.width,
        ];
        for (final heroLeft in heroLefts) {
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
            final actionCard = placeActionCard(
              map: map,
              height: actionHeight,
              hero: hero,
              strip: strip,
            );
            final area = targetCardArea(
              map: map,
              hero: hero,
              actionCard: actionCard,
              strip: strip,
            );

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
                    heroBlock(hero).bottom + crawlCalloutLeaderGap,
                  ),
                  Offset(
                    hero.center.dx - card.width / 2,
                    heroBlock(hero).top - crawlCalloutLeaderGap - card.height,
                  ),
                ],
                avoid: [targetCell],
              );
              final reason = 'map $map scale $scale hero $hero offset $offset';
              expect(placed.overlaps(strip), isFalse, reason: 'strip: $reason');
              expect(
                placed.overlaps(heroBlock(hero)),
                isFalse,
                reason: 'hero block: $reason',
              );
              expect(
                placed.overlaps(actionCard),
                isFalse,
                reason: 'action card: $reason',
              );
            }
          }
        }
      }

      // Whenever a target card can show, `game.monsters` is non-empty, so
      // `isRoadClear` (needs an empty floor) is always false and `moveOn`
      // never joins the verb list — the only verbs left to co-occur with
      // a target are pickUp, gather, ascend xor descend, flee and wait,
      // 4 at most, so the card never grows past one row of buttons. 3
      // fact lines (underfoot node, an item here, a full pack) is this
      // shape's own ceiling (`placeFacts`), and the bestiary never gives
      // a monster more than 1 resist and 1 vulnerability, so 4 lines is
      // the target card's own ceiling too. The map heights below are
      // `dungeonSceneSlotKey`'s measured size under `onTheTargetPhone` at
      // each text scale — taller than the plan's own planning figures,
      // which this sweep does not repin.
      sweep(const Size(392.7, 557.9), 1.0, 68, const Size(172, 95));
      sweep(const Size(392.7, 557.9), 1.0, 116, const Size(172, 123));
      sweep(const Size(392.7, 520.8), 1.3, 68, const Size(172, 112.4));
      sweep(const Size(392.7, 520.8), 1.3, 110.4, const Size(172, 112.4));
    });
  });
}
