import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_material.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
############
#..........#
#..........#
#..........#
############''';

Actor _heroAt(Position position) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: position,
  hp: 20,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

GameState _game({
  required Set<Position> visible,
  required Set<Position> explored,
}) {
  final map = FloorMap.parse(_arena);
  return GameState(
    map: map,
    hero: _heroAt(const Position(1, 1)),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: explored,
    buildFloor: (depth) => throw StateError('no descent in a material test'),
  );
}

/// The arena with one tile swapped, for worlds that differ only unseen.
FloorMap _arenaWith(Position position, Tile tile) {
  final rows = _arena.split('\n').where((row) => row.isNotEmpty).toList();
  final chars = rows[position.y].split('');
  chars[position.x] = switch (tile) {
    Tile.wall => '#',
    Tile.floor => '.',
    Tile.stairsDown => '>',
    Tile.stairsUp => '<',
  };
  rows[position.y] = chars.join();
  return FloorMap.parse(rows.join('\n'));
}

/// One material cell, reduced for comparison.
({
  Position position,
  MaterialTileKind kind,
  MaterialKnowledge knowledge,
  double light,
})
_cell(MaterialCell cell) => (
  position: cell.position,
  kind: cell.kind,
  knowledge: cell.knowledge,
  light: cell.light,
);

MaterialPlan _plan(GameState game) => materialPlan(game, DungeonPalette.crypt);

void main() {
  group('the material plan', () {
    test('carries every explored tile kind as explicit facts', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);

      // act
      final plan = _plan(game);

      // assert
      final floorCell = plan.cellAt(const Position(2, 1))!;
      expect(floorCell.kind, MaterialTileKind.floor);
      expect(floorCell.knowledge, MaterialKnowledge.visible);
      final wallCell = plan.cellAt(const Position(0, 0))!;
      expect(wallCell.kind, MaterialTileKind.wall);
      expect(wallCell.knowledge, MaterialKnowledge.visible);
    });

    test('marks explored-but-not-visible tiles as remembered', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      const remembered = Position(9, 2);
      final game = _game(visible: visible, explored: {...visible, remembered});

      // act
      final plan = _plan(game);

      // assert
      final cell = plan.cellAt(remembered)!;
      expect(cell.knowledge, MaterialKnowledge.remembered);
      expect(cell.kind, MaterialTileKind.floor);
    });

    test('is empty where the hero has never looked', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);

      // act
      final plan = _plan(game);

      // assert
      expect(plan.cellAt(const Position(10, 2)), isNull);
      expect(plan.cellAt(const Position(11, 1)), isNull);
    });

    test('keeps every cell inside the authoritative known set', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);

      // act
      final plan = _plan(game);

      // assert
      expect(plan.cells, isNotEmpty);
      for (final cell in plan.cells) {
        expect(
          visible.contains(cell.position),
          isTrue,
          reason: 'material cell ${cell.position} lies outside the known set',
        );
      }
      for (final position in visible) {
        expect(plan.cellAt(position), isNotNull);
      }
    });

    test('lights only visible geometry', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      const remembered = Position(9, 2);
      final game = _game(visible: visible, explored: {...visible, remembered});

      // act
      final plan = _plan(game);

      // assert
      for (final cell in plan.cells) {
        if (cell.knowledge == MaterialKnowledge.remembered) {
          expect(cell.light, 0.0, reason: 'remembered ${cell.position} unlit');
        } else {
          expect(cell.light, greaterThan(0.0));
        }
      }
      expect(plan.cellAt(remembered)!.light, 0.0);
    });

    test('is lit strongest at the hero and falls off with distance', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);
      final plan = _plan(game);

      // act
      final atHero = plan.cellAt(const Position(1, 1))!.light;
      final nearHero = plan.cellAt(const Position(2, 1))!.light;
      final farCell = plan.cellAt(const Position(1, 3))!.light;

      // assert
      expect(atHero, greaterThan(nearHero));
      expect(nearHero, greaterThan(farCell));
      expect(atHero, lessThanOrEqualTo(1.0));
    });

    test('falls off smoothly, holding a plateau near the hero', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);
      final plan = _plan(game);

      // act
      final lights = [
        for (var d = 0; d <= 8; d++)
          plan.cellAt(Position(1 + d, 1))?.light ?? -1,
      ];

      // assert — a smooth hero-local gradient: near-full at the hero, a
      // gentle plateau, then a slower tail than a straight line — never the
      // constant-slope wedge of a linear falloff
      expect(lights[0], greaterThan(0.95));
      expect(lights[1], greaterThan(0.94));
      expect(lights[1], greaterThan(lights[2]));
      final middleDrop = lights[3] - lights[5];
      final nearDrop = lights[1] - lights[2];
      expect(middleDrop, lessThan(nearDrop * 4));
      expect(lights[8], greaterThan(0.0));
      expect(lights[8], lessThan(0.15));
    });

    test('produces identical marks for identical inputs', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);

      // act
      final first = _plan(game);
      final second = _plan(game);

      // assert
      expect(first.cells.map(_cell), second.cells.map(_cell));
      expect(first.marks, second.marks);
      expect(first.marks, isNotEmpty);
    });

    test('marks depend only on position, kind, knowledge, and theme', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);
      final plan = _plan(game);

      // act
      final floorMarkA = plan.markAt(const Position(2, 1));
      final floorMarkB = plan.markAt(const Position(2, 1));
      final otherFloorMark = plan.markAt(const Position(3, 1));

      // assert
      expect(identical(floorMarkA, floorMarkB), isTrue);
      expect(floorMarkA, isNot(equals(otherFloorMark)));
    });

    test('does not consume gameplay randomness', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);
      final stateBefore = game.rng.state;

      // act
      _plan(game);

      // assert
      expect(game.rng.state, stateBefore);
    });

    test('gives a wall flanked by known walls a masonry mass treatment', () {
      // arrange
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final game = _game(visible: visible, explored: visible);

      // act
      final plan = _plan(game);

      // assert — the top row of the arena is one unbroken run of known walls,
      // so every interior wall of that run sits between known walls and must
      // read as one masonry mass, not four separate bordered cells
      final interiorWalls = [
        plan.cellAt(const Position(1, 0))!,
        plan.cellAt(const Position(2, 0))!,
        plan.cellAt(const Position(3, 0))!,
      ];
      for (final cell in interiorWalls) {
        expect(
          plan.masonryAt(cell.position),
          isTrue,
          reason: '${cell.position} sits between known walls',
        );
      }
    });

    test('treats unknown space generically, whatever it hides', () {
      // arrange — two worlds identical inside the hero's knowledge, different
      // beyond it: in one the unseen east of the last visible wall continues
      // as wall, in the other it opens into floor. Every material decision on
      // the known side must be identical, because a visible cue that differed
      // would disclose the unseen geometry.
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      const beyondTheBoundary = Position(9, 0);
      expect(visible.contains(beyondTheBoundary), isFalse);
      final hiddenAsWall = _game(visible: visible, explored: visible);
      final hiddenAsFloor = GameState(
        map: _arenaWith(beyondTheBoundary, Tile.floor),
        hero: _heroAt(const Position(1, 1)),
        monsters: const [],
        rng: Rng(1),
        lootRng: Rng(2),
        visible: visible,
        explored: visible,
        buildFloor: (depth) =>
            throw StateError('no descent in a material test'),
      );

      // act
      final wallPlan = _plan(hiddenAsWall);
      final floorPlan = _plan(hiddenAsFloor);

      // assert
      expect(wallPlan.cells, floorPlan.cells);
      expect(wallPlan.marks, floorPlan.marks);
      expect(wallPlan.masonry, floorPlan.masonry);
    });

    test('treats an unknown neighbour generically, like no known wall', () {
      // arrange — the hero stands at (1, 1), so the top wall run is visible
      // through (8, 0) and unknown from (9, 0) east; the last visible wall's
      // east neighbour is unknown and must count exactly like a neighbour
      // that is known but not a wall
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final lastKnownWall = const Position(8, 0);
      expect(visible.contains(lastKnownWall), isTrue);

      final game = _game(visible: visible, explored: visible);

      // act
      final plan = _plan(game);

      // assert — (8, 0) has one known wall west, a known floor south, an
      // assert — (8, 0) has one known wall west, a known floor south, an
      // unknown east; (8, 4) mirrors it from the bottom row with the same
      // known-wall count and its own unknown east. Same known facts, same
      // treatment — and the twin-worlds test above proves whatever the
      // unknown east hides cannot change either.
      final boundaryWall = plan.cellAt(lastKnownWall)!;
      expect(boundaryWall.kind, MaterialTileKind.wall);
      expect(plan.cellAt(const Position(8, 4))!.kind, MaterialTileKind.wall);
      expect(
        plan.masonryAt(boundaryWall.position),
        plan.masonryAt(const Position(8, 4)),
        reason: 'unknown adjacency must not leak into wall treatment',
      );
    });

    test('never varies a visible wall by a remembered neighbour it faces', () {
      // arrange — knowledge state of a neighbour is not geometry; a visible
      // wall beside a remembered one must equal the same wall beside a
      // visible one, so the fog line cannot be read off the masonry
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final withRemembered = _game(
        visible: visible,
        explored: {...visible, const Position(9, 2)},
      );
      final withoutRemembered = _game(visible: visible, explored: visible);

      // act
      final planWith = _plan(withRemembered);
      final planWithout = _plan(withoutRemembered);

      // assert — every mark on a shared visible cell is identical
      for (final cell in planWith.cells) {
        if (cell.knowledge != MaterialKnowledge.visible) continue;
        expect(
          planWith.markAt(cell.position),
          planWithout.markAt(cell.position),
          reason: 'visible ${cell.position} changed with neighbour knowledge',
        );
      }
    });
  });
}
