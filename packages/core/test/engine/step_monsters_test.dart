import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const hall = '''
##########
#........#
#........#
#........#
##########''';

const corridor = '''
#####
#...#
###.#
#...#
#####''';

const pocket = '''
#####
#.#.#
#.###
#...#
#####''';

void main() {
  group('step, monster turns', () {
    test('a distant monster takes one step toward the hero', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(7, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, const Position(6, 2));
      expect(
        events,
        contains(
          const ActorMoved(
            actorId: 'ghoul-1',
            from: Position(7, 2),
            to: Position(6, 2),
          ),
        ),
      );
    });

    test('an adjacent monster claws the hero instead of moving', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters.single.position, const Position(3, 2));
      expect(
        events,
        contains(
          const AttackHit(attackerId: 'ghoul-1', targetId: 'hero', damage: 3),
        ),
      );
      expect(next.hero.hp, 17);
    });

    test('a blocked move still costs the turn: monsters act anyway', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [ghoul('ghoul-1', const Position(7, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(next.hero.position, const Position(1, 2));
      expect(next.monsters.single.position, const Position(6, 2));
      expect(
        events,
        contains(const MoveBlocked(actorId: 'hero', at: Position(0, 2))),
      );
    });

    test('on equal deltas the monster prefers the x axis', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(4, 3))],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, const Position(3, 3));
    });

    test('a monster blocked on its preferred axis tries the other one', () {
      // arrange
      final state = crawl(
        ascii: corridor,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(1, 3))],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters.single.position, const Position(2, 3));
    });

    test('a monster with no open step stands still and says nothing', () {
      // arrange
      final state = crawl(
        ascii: pocket,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.south));

      // assert
      expect(next.monsters.single.position, const Position(3, 1));
      expect(
        events.whereType<ActorMoved>().map((event) => event.actorId),
        isNot(contains('ghoul-1')),
      );
    });

    test('a monster does not step onto a monster that already moved', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [
          ghoul('ghoul-1', const Position(2, 2)),
          ghoul('ghoul-2', const Position(3, 2)),
        ],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters[0].position, const Position(2, 2));
      expect(next.monsters[1].position, const Position(3, 2));
    });

    test('a monster follows another into the tile it just vacated', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [
          ghoul('ghoul-1', const Position(4, 2)),
          ghoul('ghoul-2', const Position(5, 2)),
        ],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.west));

      // assert
      expect(next.monsters[0].position, const Position(3, 2));
      expect(next.monsters[1].position, const Position(4, 2));
    });

    test('two chasing monsters never share a tile', () {
      // arrange
      var state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [
          ghoul('ghoul-1', const Position(7, 3)),
          ghoul('ghoul-2', const Position(8, 3)),
        ],
      );

      // act
      for (var turn = 0; turn < 8; turn++) {
        final (next, _) = step(state, const MoveAction(Direction.west));
        state = next;
      }

      // assert
      final positions = state.monsters.map((m) => m.position).toList();
      expect(positions.toSet(), hasLength(positions.length));
    });

    test('a chasing monster closes the distance every turn', () {
      // arrange
      var state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(8, 3))],
      );
      final distances = <int>[];

      // act
      for (var turn = 0; turn < 6; turn++) {
        final monster = state.monsters.single.position;
        distances.add(
          (monster.x - state.hero.position.x).abs() +
              (monster.y - state.hero.position.y).abs(),
        );
        final (next, _) = step(state, const MoveAction(Direction.west));
        state = next;
      }

      // assert
      expect(distances, orderedEquals(<int>[9, 8, 7, 6, 5, 4]));
    });

    test('a monster never walks onto the hero', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(4, 2))],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, isNot(next.hero.position));
    });
  });

  group('step, the hero dies', () {
    test('a lethal claw reports the death and ends the game', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        heroHp: 3,
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.hero.isAlive, isFalse);
      expect(next.isGameOver, isTrue);
      expect(events, contains(const ActorDied(actorId: 'hero')));
      expect(events, contains(const GameOver()));
    });

    test('the game over event comes after the death', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        heroHp: 2,
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );

      // act
      final (_, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(
        events.indexOf(const ActorDied(actorId: 'hero')),
        lessThan(events.indexOf(const GameOver())),
      );
    });

    test('an action after game over changes nothing', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        heroHp: 2,
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );
      final (dead, _) = step(state, const MoveAction(Direction.east));

      // act
      final (after, events) = step(dead, const MoveAction(Direction.west));

      // assert
      expect(events, isEmpty);
      expect(after.hero.position, dead.hero.position);
      expect(after.hero.hp, dead.hero.hp);
      expect(after.monsters.length, dead.monsters.length);
      expect(after.isGameOver, isTrue);
    });

    test('monster damage is drawn from the seeded rng', () {
      // arrange
      GameState fresh() => crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [
          Actor(
            id: 'ghoul-1',
            glyph: 'g',
            position: const Position(3, 2),
            hp: 10,
            maxHp: 10,
            attackMin: 2,
            attackMax: 4,
          ),
        ],
        seed: 5,
      );

      // act
      final (_, first) = step(fresh(), const MoveAction(Direction.east));
      final (_, second) = step(fresh(), const MoveAction(Direction.east));
      final damage = first
          .whereType<AttackHit>()
          .where((event) => event.attackerId == 'ghoul-1')
          .map((event) => event.damage)
          .toList();

      // assert
      expect(first, second);
      expect(damage.single, inInclusiveRange(2, 4));
    });
  });
}
