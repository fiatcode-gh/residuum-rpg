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
        map: const Size(300, 300),
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
        map: map,
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
        map: const Size(200, 200),
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
        map: const Size(200, 200),
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
        map: const Size(100, 36),
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
        map: const Size(100, 36),
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
          map: map,
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
}
