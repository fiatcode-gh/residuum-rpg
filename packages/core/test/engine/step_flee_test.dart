import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// Open ground with a walkable border, which is what a road fight is on.
const String _road = '''
.....
.....
..#..
.....
.....''';

/// A crawl floor, whose border is solid wall, which is why the flee rule cannot
/// be reached from one.
const String _crypt = '''
#####
#...#
#.#.#
#...#
#####''';

void main() {
  group('walking off the edge of a road fight', () {
    test('is fleeing, in every direction there is', () {
      // arrange
      final edges = {
        Direction.north: const Position(2, 0),
        Direction.south: const Position(2, 4),
        Direction.west: const Position(0, 2),
        Direction.east: const Position(4, 2),
      };

      // act
      final events = {
        for (final edge in edges.entries)
          edge.key: step(
            crawl(ascii: _road, heroAt: edge.value, isEncounter: true),
            MoveAction(edge.key),
          ).$2,
      };

      // assert
      for (final direction in Direction.values) {
        expect(events[direction], [const Fled()], reason: '$direction');
      }
    });

    test('costs no turn at all', () {
      // arrange
      final fight = crawl(
        ascii: _road,
        heroAt: const Position(2, 0),
        monsters: [ghoul('ghoul-1', const Position(2, 1))],
        isEncounter: true,
      );

      // act
      final (after, events) = step(fight, const MoveAction(Direction.north));

      // assert
      expect(events, [const Fled()]);
      expect(after.hero.energy, fight.hero.energy);
      expect(after.hero.hp, fight.hero.hp);
      expect(after.monsters.single.position, const Position(2, 1));
      expect(after, same(fight));
    });

    test('leaves the generators exactly where they were', () {
      // arrange
      final fight = crawl(
        ascii: _road,
        heroAt: const Position(2, 0),
        isEncounter: true,
      );
      final before = (fight.rng.state, fight.lootRng.state);

      // act
      step(fight, const MoveAction(Direction.north));

      // assert
      expect((fight.rng.state, fight.lootRng.state), before);
    });

    test('is not what walking into a rock is', () {
      // arrange
      final fight = crawl(
        ascii: _road,
        heroAt: const Position(2, 1),
        isEncounter: true,
      );

      // act
      final (_, events) = step(fight, const MoveAction(Direction.south));

      // assert
      expect(
        events,
        contains(const MoveBlocked(actorId: 'hero', at: Position(2, 2))),
      );
      expect(events, isNot(contains(const Fled())));
    });

    test('is not what walking across the ground is', () {
      // arrange
      final fight = crawl(
        ascii: _road,
        heroAt: const Position(2, 1),
        isEncounter: true,
      );

      // act
      final (after, events) = step(fight, const MoveAction(Direction.east));

      // assert
      expect(events, isNot(contains(const Fled())));
      expect(after.hero.position, const Position(3, 1));
    });

    test('is not something a dead hero does', () {
      // arrange
      final fight = crawl(
        ascii: _road,
        heroAt: const Position(2, 0),
        isEncounter: true,
      ).copyWith(isGameOver: true);

      // act
      final (_, events) = step(fight, const MoveAction(Direction.north));

      // assert
      expect(events, isEmpty);
    });

    test('is not something the stairs controls can do', () {
      // arrange
      final fight = crawl(
        ascii: _road,
        heroAt: const Position(2, 0),
        isEncounter: true,
      );

      // act
      final descending = step(fight, const DescendAction()).$2;
      final ascending = step(fight, const AscendAction()).$2;

      // assert
      expect(descending, isNot(contains(const Fled())));
      expect(ascending, isNot(contains(const Fled())));
    });
  });

  group('walking off the edge of a crawl', () {
    test('is not a thing the rules have an answer for', () {
      // arrange
      final crypt = crawl(ascii: _crypt, heroAt: const Position(1, 1));

      // act
      final (_, events) = step(crypt, const MoveAction(Direction.north));

      // assert
      expect(events, isNot(contains(const Fled())));
      expect(
        events,
        contains(const MoveBlocked(actorId: 'hero', at: Position(1, 0))),
      );
    });

    test('is unreachable anyway, because the border is wall', () {
      // arrange
      final crypt = crawl(ascii: _crypt, heroAt: const Position(1, 1));

      // act
      final onTheEdge = [
        for (var x = 0; x < 5; x++) const Position(0, 0),
      ].where((edge) => crypt.map.isWalkable(edge));

      // assert
      expect(onTheEdge, isEmpty);
    });

    test('stays unreachable even with the encounter field turned on', () {
      // arrange
      final crypt = crawl(
        ascii: _crypt,
        heroAt: const Position(1, 1),
        isEncounter: true,
      );

      // act
      final (_, events) = step(crypt, const MoveAction(Direction.north));

      // assert
      expect(events, isNot(contains(const Fled())));
    });
  });

  group('the encounter field', () {
    test('is off unless somebody says otherwise', () {
      // arrange
      final crypt = crawl(ascii: _crypt, heroAt: const Position(1, 1));

      // act
      final isEncounter = crypt.isEncounter;

      // assert
      expect(isEncounter, isFalse);
    });

    test('survives every turn of the fight it belongs to', () {
      // arrange
      final fight = crawl(
        ascii: _road,
        heroAt: const Position(2, 1),
        isEncounter: true,
      );

      // act
      final (after, _) = step(fight, const MoveAction(Direction.east));

      // assert
      expect(after.isEncounter, isTrue);
    });
  });
}
