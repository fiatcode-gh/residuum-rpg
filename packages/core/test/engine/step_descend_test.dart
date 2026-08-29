import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const upstairs = '''
#######
#..>..#
#.....#
#######''';

const downstairs = '''
##########
#........#
#........#
##########''';

Floor nextFloor(int depth) => Floor(
  map: FloorMap.parse(downstairs),
  heroSpawn: const Position(1, 1),
  monsters: [ghoul('ghoul-9', const Position(8, 2))],
  stairsDown: depth >= deepestDepth ? null : const Position(8, 1),
  stairsUp: const Position(1, 1),
  nodes: {const Position(4, 2): GatherKind.oreVein},
);

GameState onTheStairs({int heroHp = 20, int depth = 1}) => crawl(
  ascii: upstairs,
  heroAt: const Position(3, 1),
  heroHp: heroHp,
  monsters: [ghoul('ghoul-1', const Position(1, 2))],
  depth: depth,
  stairsDown: const Position(3, 1),
  buildFloor: nextFloor,
);

void main() {
  group('DescendAction on the stairs', () {
    test('swaps the floor and puts the hero where it arrives', () {
      // arrange
      final state = onTheStairs();

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.depth, 2);
      expect(next.map.toAscii(), FloorMap.parse(downstairs).toAscii());
      expect(next.hero.position, const Position(1, 1));
      expect(next.stairsDown, const Position(8, 1));
    });

    test('replaces the monsters with the new floor\'s', () {
      // arrange
      final state = onTheStairs();

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.monsters.map((m) => m.id), ['ghoul-9']);
    });

    test('the hero carries its wounds down the stairs', () {
      // arrange
      final state = onTheStairs(heroHp: 7);

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.hero.hp, 7);
      expect(next.hero.maxHp, 20);
    });

    test('the new floor is dark apart from what the hero can see', () {
      // arrange
      final state = onTheStairs();

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.explored, next.visible);
      expect(next.visible, computeFov(next.map, next.hero.position, fovRadius));
    });

    test('leaves the floor it came from behind as a snapshot', () {
      // arrange
      final state = onTheStairs();

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.floors.keys, [1]);
      expect(next.floors[1]!.monsters.map((m) => m.id), ['ghoul-1']);
      expect(next.floors[1]!.stairsDown, const Position(3, 1));
    });

    test('arrives on the new floor\'s stairs up', () {
      // arrange
      final state = onTheStairs();

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.stairsUp, const Position(1, 1));
      expect(next.hero.position, next.stairsUp);
    });

    test('announces the new depth', () {
      // arrange
      final state = onTheStairs();

      // act
      final (_, events) = step(state, const DescendAction());

      // assert
      expect(events, contains(const Descended(newDepth: 2)));
    });

    test('the clock restarts so the hero moves first on the new floor', () {
      // arrange
      final state = onTheStairs();

      // act
      final (next, events) = step(state, const DescendAction());

      // assert
      expect(next.hero.energy, actThreshold);
      expect(next.monsters.map((m) => m.energy), everyElement(actThreshold));
      expect(events.whereType<ActorMoved>(), isEmpty);
    });

    test('arriving on the deepest floor leaves no way further down', () {
      // arrange
      final state = onTheStairs(depth: deepestDepth - 1);

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.depth, deepestDepth);
      expect(next.stairsDown, isNull);
    });
  });

  group('DescendAction anywhere else', () {
    test('is blocked where there are no stairs underfoot', () {
      // arrange
      final state = crawl(
        ascii: upstairs,
        heroAt: const Position(1, 1),
        depth: 1,
        stairsDown: const Position(3, 1),
        buildFloor: nextFloor,
      );

      // act
      final (next, events) = step(state, const DescendAction());

      // assert
      expect(next.depth, 1);
      expect(
        events,
        contains(const MoveBlocked(actorId: 'hero', at: Position(1, 1))),
      );
    });

    test('still costs the turn, so the monsters get theirs', () {
      // arrange
      final state = crawl(
        ascii: downstairs,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(8, 1))],
        depth: 1,
        buildFloor: nextFloor,
      );

      // act
      final (next, _) = step(state, const DescendAction());

      // assert
      expect(next.monsters.single.position, const Position(7, 1));
    });

    test('the deepest floor never descends, because it has no stairs', () {
      // arrange
      final state = crawl(
        ascii: downstairs,
        heroAt: const Position(1, 1),
        depth: deepestDepth,
        buildFloor: nextFloor,
      );

      // act
      final (next, events) = step(state, const DescendAction());

      // assert
      expect(next.depth, deepestDepth);
      expect(events.whereType<Descended>(), isEmpty);
    });
  });

  group('the nodes a floor keeps while the hero is elsewhere', () {
    test('a floor built for the first time arrives with its own nodes', () {
      // arrange
      final state = onTheStairs();

      // act
      final (below, _) = step(state, const DescendAction());

      // assert
      expect(below.nodes, {const Position(4, 2): GatherKind.oreVein});
    });

    test('the floor left behind keeps the nodes it was left holding', () {
      // arrange
      final state = onTheStairs().copyWith(
        nodes: {const Position(5, 2): GatherKind.herbPatch},
      );

      // act
      final (below, _) = step(state, const DescendAction());

      // assert - frozen with the litter and the fog, for FloorMemory's reason:
      // what you left is what is waiting
      expect(below.floors[1]!.nodes, {
        const Position(5, 2): GatherKind.herbPatch,
      });
    });

    test('climbing back up restores them, unworked', () {
      // arrange
      final state = onTheStairs().copyWith(
        nodes: {const Position(5, 2): GatherKind.herbPatch},
      );

      // act
      final (below, _) = step(state, const DescendAction());
      final (again, _) = step(below, const AscendAction());

      // assert
      expect(again.nodes, {const Position(5, 2): GatherKind.herbPatch});
    });

    test('a floor stripped of its nodes comes back stripped', () {
      // arrange
      final state = onTheStairs().copyWith(nodes: const {});

      // act
      final (below, _) = step(state, const DescendAction());
      final (again, _) = step(below, const AscendAction());

      // assert - a worked vein does not grow back inside one delve; the visit
      // bump is what regrows a dungeon, and only entering bumps it
      expect(again.nodes, isEmpty);
      expect(below.floors[1]!.nodes, isEmpty);
    });
  });
}
