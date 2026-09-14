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

const _crackArena = '''
.........
....#....
.........
.........
.........''';

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
  Position heroPosition = const Position(1, 1),
  FloorMap? map,
}) {
  final floorMap = map ?? FloorMap.parse(_arena);
  return GameState(
    map: floorMap,
    hero: _heroAt(heroPosition),
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
({Position position, MaterialTileKind kind, MaterialKnowledge knowledge}) _cell(
  MaterialCell cell,
) => (position: cell.position, kind: cell.kind, knowledge: cell.knowledge);

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

    test(
      'keeps material cells independent of the presentation light source',
      () {
        // arrange — visibility is authoritative and held fixed; moving the
        // presentation source must not create a second light-derived material
        // data model beneath the renderer.
        final visible = computeFov(
          FloorMap.parse(_arena),
          const Position(1, 1),
          fovRadius,
        );
        final atFirstSource = _game(visible: visible, explored: visible);
        final atSecondSource = _game(
          visible: visible,
          explored: visible,
          heroPosition: const Position(2, 1),
        );

        // act
        final first = _plan(atFirstSource);
        final second = _plan(atSecondSource);

        // assert — local light belongs to the renderer's single clipped
        // gradient, not to each material cell.
        expect(first.cells, second.cells);
        expect(first.marks, second.marks);
      },
    );

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

    test('defensively owns the renderer plan collections', () {
      const position = Position(2, 1);
      const cell = MaterialCell(
        position: position,
        kind: MaterialTileKind.floor,
        knowledge: MaterialKnowledge.visible,
      );
      const mark = MaterialMark(grit: 0.3, speck: false, crack: 0, edge: 0);
      final cells = [cell];
      final marks = {position: mark};
      final masonry = {position};
      final plan = MaterialPlan(
        cells: cells,
        marks: marks,
        masonry: masonry,
        heroPosition: position,
      );

      expect(() => plan.cells.add(cell), throwsUnsupportedError);
      expect(() => plan.marks[position] = mark, throwsUnsupportedError);
      expect(() => plan.masonry.add(position), throwsUnsupportedError);

      cells.clear();
      marks.clear();
      masonry.clear();
      expect(plan.cells, [cell]);
      expect(plan.marks, {position: mark});
      expect(plan.masonry, {position});
    });

    test('omits decoration hashes the renderer cannot use', () {
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final plan = _plan(
        _game(visible: visible, explored: {...visible, const Position(9, 2)}),
      );

      for (final cell in plan.cells) {
        final mark = plan.markAt(cell.position)!;
        final visibleFloor =
            cell.knowledge == MaterialKnowledge.visible &&
            cell.kind == MaterialTileKind.floor;
        if (!visibleFloor) {
          expect(mark.speck, isFalse, reason: '${cell.position} has no speck');
        }

        final visibleExposedWall =
            cell.knowledge == MaterialKnowledge.visible &&
            cell.kind == MaterialTileKind.wall &&
            !plan.masonryAt(cell.position);
        if (!visibleExposedWall) {
          expect(mark.crack, 0.0, reason: '${cell.position} has no crack');
          expect(mark.edge, 0.0, reason: '${cell.position} has no edge hash');
        }
      }
    });

    test('keeps applicable decoration hashes stable', () {
      final visible = computeFov(
        FloorMap.parse(_arena),
        const Position(1, 1),
        fovRadius,
      );
      final plan = _plan(_game(visible: visible, explored: visible));
      final floor = plan.markAt(const Position(2, 1))!;
      final speckedFloor = plan.markAt(const Position(2, 3))!;

      const crackPosition = Position(4, 1);
      final crackMap = FloorMap.parse(_crackArena);
      final crackVisible = computeFov(
        crackMap,
        const Position(1, 1),
        fovRadius,
      );
      expect(crackVisible, contains(crackPosition));
      final crackPlan = _plan(
        _game(map: crackMap, visible: crackVisible, explored: crackVisible),
      );
      expect(crackPlan.masonryAt(crackPosition), isFalse);
      final crackedWall = crackPlan.markAt(crackPosition)!;
      final exposedWall = plan.markAt(const Position(8, 0))!;

      expect(
        [
          floor.grit,
          floor.speck,
          speckedFloor.grit,
          speckedFloor.speck,
          exposedWall.grit,
          exposedWall.crack,
          exposedWall.edge,
          crackedWall.grit,
          crackedWall.crack,
          crackedWall.edge,
        ],
        const [
          0.10746535102544943,
          false,
          0.1745148270797252,
          true,
          0.6811134932285904,
          0.0,
          0.03287066006634167,
          0.021708223042476042,
          0.17513918256739602,
          0.7281350945071632,
        ],
      );
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
