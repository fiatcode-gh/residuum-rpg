import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
#####
#...#
#####''';

const _twoFloors = '''
######
#....#
######''';

/// A crawl with a monster standing next to the hero, holding still or not.
GameState _besieged({Map<String, int> bound = const {}, int monsterHp = 10}) =>
    crawl(
      ascii: _room,
      heroAt: const Position(1, 1),
      monsters: [ghoul('ghoul-1', const Position(2, 1), hp: monsterHp)],
      bound: bound,
    );

void main() {
  group('a bound monster', () {
    test('sits out the turn it was due, and swings at nobody', () {
      // arrange
      final game = _besieged(bound: const {'ghoul-1': 2});

      // act
      final (after, events) = step(game, const DescendAction());

      // assert
      expect(after.hero.hp, 20);
      expect(events.whereType<AttackHit>(), isEmpty);
      expect(after.bound, {'ghoul-1': 1});
    });

    test('goes free on the turn its count runs out', () {
      // arrange
      final game = _besieged(bound: const {'ghoul-1': 1});

      // act
      final (after, _) = step(game, const DescendAction());

      // assert - the last held turn is still held, and the entry is gone
      expect(after.hero.hp, 20);
      expect(after.bound, isEmpty);
    });

    test('swings again the turn after that', () {
      // arrange
      final game = _besieged(bound: const {'ghoul-1': 1});

      // act
      final (held, _) = step(game, const DescendAction());
      final (freed, _) = step(held, const DescendAction());

      // assert
      expect(freed.hero.hp, lessThan(held.hero.hp));
    });

    test('does not move either, so it cannot follow the hero', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1))],
        bound: const {'ghoul-1': 3},
      );

      // act
      final (after, _) = step(game, const DescendAction());

      // assert
      expect(after.monsters.single.position, const Position(3, 1));
    });

    test('still takes damage and still dies', () {
      // arrange
      final game = _besieged(bound: const {'ghoul-1': 3}, monsterHp: 2);

      // act
      final (after, events) = step(game, const MoveAction(Direction.east));

      // assert - being held is not being safe
      expect(events, contains(const ActorDied(actorId: 'ghoul-1')));
      expect(after.monsters, isEmpty);
    });

    test('takes its counter with it when it dies', () {
      // arrange
      final game = _besieged(bound: const {'ghoul-1': 3}, monsterHp: 2);

      // act
      final (after, _) = step(game, const MoveAction(Direction.east));

      // assert - a counter for the dead would ride every save file from here on
      expect(after.bound, isEmpty);
    });

    test('does not hold a different monster of the same name downstairs', () {
      // arrange - monster ids are unique to a floor, not to a run, so the
      // crypt's first ghoul is `ghoul-1` on every depth that has one
      final game = crawl(
        ascii: _twoFloors,
        heroAt: const Position(1, 1),
        stairsDown: const Position(1, 1),
        bound: const {'ghoul-1': 3},
        buildFloor: (depth) => Floor(
          map: FloorMap.parse(_twoFloors),
          heroSpawn: const Position(1, 1),
          monsters: [ghoul('ghoul-1', const Position(2, 1))],
          stairsUp: const Position(1, 1),
          stairsDown: const Position(4, 1),
        ),
      );

      // act
      final (below, _) = step(game, const DescendAction());
      final (fought, _) = step(below, const DescendAction());

      // assert - a bind does not survive a stairway, so the ghoul waiting
      // downstairs swings the moment the hero arrives
      expect(below.bound, isEmpty);
      expect(fought.hero.hp, lessThan(below.hero.hp));
    });
  });
}
