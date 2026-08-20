import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _upper = '''
##########
#........#
#........#
##########''';

/// Long enough that a hero standing at one end cannot see the other, which is
/// what makes a restored explored map distinguishable from a fresh one.
const _corridor = '''
######################
#....................#
######################''';

const _lower = '''
##########
#........#
#........#
##########''';

const _cap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

Floor lowerFloor(int depth) => Floor(
  map: FloorMap.parse(_lower),
  heroSpawn: const Position(1, 1),
  monsters: [ghoul('ghoul-$depth-9', const Position(8, 2))],
  stairsDown: depth >= deepestDepth ? null : const Position(8, 1),
  stairsUp: const Position(1, 1),
);

/// A hero on depth one, standing on the stairs down, with a wounded monster
/// behind it, an item lying on the floor and part of the floor explored.
GameState onDepthOne() => crawl(
  ascii: _upper,
  heroAt: const Position(4, 1),
  monsters: [ghoul('ghoul-1', const Position(2, 2), hp: 3)],
  depth: 1,
  stairsDown: const Position(4, 1),
  buildFloor: lowerFloor,
  groundItems: {
    const Position(6, 2): const [
      Item(id: 'floor-1-1', base: _cap, rarity: Rarity.common),
    ],
  },
);

void main() {
  group('AscendAction', () {
    test('is refused on depth one and costs nothing', () {
      // arrange
      final state = onDepthOne();

      // act
      final (next, events) = step(state, const AscendAction());

      // assert
      expect(identical(next, state), isTrue);
      expect(events, [
        const ActionRefused(reason: 'there are no stairs up from here'),
      ]);
    });

    test('is refused off the stairs-up tile and costs nothing', () {
      // arrange
      final state = crawl(
        ascii: _lower,
        heroAt: const Position(5, 2),
        depth: 2,
        stairsUp: const Position(1, 1),
        buildFloor: lowerFloor,
      );

      // act
      final (next, events) = step(state, const AscendAction());

      // assert
      expect(identical(next, state), isTrue);
      expect(events, [
        const ActionRefused(reason: 'the stairs up are not here'),
      ]);
    });

    test('a refusal never lets a waiting monster act', () {
      // arrange
      final state = crawl(
        ascii: _lower,
        heroAt: const Position(5, 2),
        monsters: [ghoul('ghoul-1', const Position(8, 2))],
        depth: 2,
        stairsUp: const Position(1, 1),
        buildFloor: lowerFloor,
      );

      // act
      final (next, _) = step(state, const AscendAction());

      // assert
      expect(next.monsters.single.position, const Position(8, 2));
    });

    test('announces the new depth and lands on the stairs down', () {
      // arrange
      final (below, _) = step(onDepthOne(), const DescendAction());

      // act
      final (back, events) = step(below, const AscendAction());

      // assert
      expect(back.depth, 1);
      expect(back.hero.position, const Position(4, 1));
      expect(events, contains(const Ascended(newDepth: 1)));
    });

    test('the clock restarts, so the hero moves first on arrival', () {
      // arrange
      final (below, _) = step(onDepthOne(), const DescendAction());

      // act
      final (back, events) = step(below, const AscendAction());

      // assert
      expect(back.hero.energy, actThreshold);
      expect(events.whereType<ActorMoved>(), isEmpty);
    });
  });

  group('floor persistence', () {
    test('a floor comes back exactly as it was left', () {
      // arrange
      final start = onDepthOne();

      // act
      final (below, _) = step(start, const DescendAction());
      final (back, _) = step(below, const AscendAction());

      // assert
      expect(back.map.toAscii(), start.map.toAscii());
      expect(back.monsters.map((monster) => (monster.id, monster.hp)), [
        ('ghoul-1', 3),
      ]);
      expect(back.groundItems[const Position(6, 2)]!.single.id, 'floor-1-1');
      expect(back.explored, containsAll(start.explored));
      expect(back.stairsDown, const Position(4, 1));
      expect(back.stairsUp, isNull);
    });

    test('a monster wounded before the hero left is still wounded', () {
      // arrange
      final start = crawl(
        ascii: _upper,
        heroAt: const Position(3, 1),
        monsters: [ghoul('ghoul-1', const Position(4, 1), hp: 10)],
        depth: 1,
        stairsDown: const Position(3, 1),
        buildFloor: lowerFloor,
        heroAttack: 4,
      );

      // act
      final (fought, _) = step(start, const MoveAction(Direction.east));
      final (below, _) = step(fought, const DescendAction());
      final (back, _) = step(below, const AscendAction());

      // assert
      expect(back.monsters.single.hp, fought.monsters.single.hp);
      expect(back.monsters.single.hp, lessThan(10));
    });

    test('an item dropped before leaving is still where it fell', () {
      // arrange
      final start = crawl(
        ascii: _upper,
        heroAt: const Position(4, 1),
        depth: 1,
        stairsDown: const Position(4, 1),
        buildFloor: lowerFloor,
        inventory: const [
          Item(id: 'held-1', base: _cap, rarity: Rarity.common),
        ],
      );

      // act
      final (dropped, _) = step(start, const DropAction('held-1'));
      final (below, _) = step(dropped, const DescendAction());
      final (back, _) = step(below, const AscendAction());

      // assert
      expect(back.groundItems[const Position(4, 1)]!.single.id, 'held-1');
    });

    test('frozen monsters bank no energy while the hero is away', () {
      // arrange — a half-speed monster, stepped once so that the energy it is
      // holding is a number of its own rather than the threshold everything
      // starts on. A snapshot that quietly re-readied its monsters would be
      // invisible against a fixture that was already ready.
      final start = crawl(
        ascii: _upper,
        heroAt: const Position(3, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 2), speed: 5)],
        depth: 1,
        stairsDown: const Position(4, 1),
        buildFloor: lowerFloor,
      );
      final (onTheStairs, _) = step(start, const MoveAction(Direction.east));
      final banked = onTheStairs.monsters.single.energy;

      // act
      final (below, _) = step(onTheStairs, const DescendAction());
      final (east, _) = step(below, const MoveAction(Direction.east));
      final (west, _) = step(east, const MoveAction(Direction.west));
      final (back, events) = step(west, const AscendAction());

      // assert
      expect(banked, isNot(actThreshold));
      expect(back.monsters.single.energy, banked);
      expect(events.whereType<ActorMoved>(), isEmpty);
    });

    test('a restored floor gives its monsters no free turn on arrival', () {
      // arrange
      final start = crawl(
        ascii: _upper,
        heroAt: const Position(4, 1),
        monsters: [ghoul('ghoul-1', const Position(6, 1), speed: 5)],
        depth: 1,
        stairsDown: const Position(4, 1),
        buildFloor: lowerFloor,
      );

      // act
      final (below, _) = step(start, const DescendAction());
      final (back, _) = step(below, const AscendAction());
      final (next, events) = step(back, const MoveAction(Direction.south));
      final (straight, direct) = step(start, const MoveAction(Direction.south));

      // assert
      expect(
        events.whereType<ActorMoved>().length,
        direct.whereType<ActorMoved>().length,
      );
      expect(next.monsters.single.energy, straight.monsters.single.energy);
    });

    test('explored is per floor, so a fresh floor arrives dark', () {
      // arrange
      final start = onDepthOne();

      // act
      final (below, _) = step(start, const DescendAction());

      // assert
      expect(below.explored, below.visible);
      expect(below.explored, isNot(containsAll(start.explored)));
    });

    test('going back down restores rather than regenerating', () {
      // arrange
      final (below, _) = step(onDepthOne(), const DescendAction());
      final (east, _) = step(below, const MoveAction(Direction.east));
      final (walked, _) = step(east, const MoveAction(Direction.west));

      // act
      final (back, _) = step(walked, const AscendAction());
      final (again, _) = step(back, const DescendAction());

      // assert
      expect(again.explored, walked.explored);
      expect(
        again.monsters.map((monster) => (monster.id, monster.position)),
        walked.monsters.map((monster) => (monster.id, monster.position)),
      );
    });

    test('the floor the hero stands on is never also a snapshot', () {
      // arrange
      final start = onDepthOne();

      // act
      final (below, _) = step(start, const DescendAction());
      final (back, _) = step(below, const AscendAction());

      // assert
      expect(below.floors.keys, [1]);
      expect(back.floors.keys, [2]);
    });

    test('a floor is remembered wider than the arrival tile can see', () {
      // arrange
      final start = crawl(
        ascii: _corridor,
        heroAt: const Position(1, 1),
        depth: 1,
        stairsDown: const Position(20, 1),
        buildFloor: lowerFloor,
      );

      // act
      var walked = start;
      while (walked.hero.position != const Position(20, 1)) {
        final (next, _) = step(walked, const MoveAction(Direction.east));
        walked = next;
      }
      final (below, _) = step(walked, const DescendAction());
      final (back, _) = step(below, const AscendAction());

      // assert
      expect(back.explored, walked.explored);
      expect(
        back.explored.length,
        greaterThan(
          computeFov(back.map, const Position(20, 1), fovRadius).length,
        ),
      );
      expect(back.explored, contains(const Position(1, 1)));
    });

    test('the deepest floor still has a way up', () {
      // arrange
      final state = crawl(
        ascii: _lower,
        heroAt: const Position(1, 1),
        depth: deepestDepth,
        stairsUp: const Position(1, 1),
        floors: {
          deepestDepth - 1: FloorMemory(
            map: FloorMap.parse(_upper),
            monsters: const [],
            groundItems: const {},
            explored: const {},
            stairsDown: const Position(4, 1),
            stairsUp: const Position(1, 1),
          ),
        },
        buildFloor: lowerFloor,
      );

      // act
      final (back, _) = step(state, const AscendAction());

      // assert
      expect(back.depth, deepestDepth - 1);
      expect(back.hero.position, const Position(4, 1));
    });

    test('the hero carries its wounds and its pack up the stairs', () {
      // arrange
      final start = crawl(
        ascii: _upper,
        heroAt: const Position(4, 1),
        heroHp: 7,
        depth: 1,
        stairsDown: const Position(4, 1),
        buildFloor: lowerFloor,
        inventory: const [
          Item(id: 'held-1', base: _cap, rarity: Rarity.common),
        ],
        gold: 33,
      );

      // act
      final (below, _) = step(start, const DescendAction());
      final (back, _) = step(below, const AscendAction());

      // assert
      expect(back.hero.hp, 7);
      expect(back.inventory.single.id, 'held-1');
      expect(back.gold, 33);
    });
  });
}
