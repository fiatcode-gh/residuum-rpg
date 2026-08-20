import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const room = '''
#######
#.....#
#.....#
#.....#
#######''';

void main() {
  group('step, hero movement', () {
    test('walks into open floor', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(3, 2));

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.hero.position, const Position(4, 2));
      expect(
        events,
        contains(
          const ActorMoved(
            actorId: 'hero',
            from: Position(3, 2),
            to: Position(4, 2),
          ),
        ),
      );
    });

    test('is blocked by a wall and does not move', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(1, 2));

      // act
      final (next, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(next.hero.position, const Position(1, 2));
      expect(
        events,
        contains(const MoveBlocked(actorId: 'hero', at: Position(0, 2))),
      );
    });

    test('leaves the input state untouched', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(3, 2));

      // act
      step(state, const MoveAction(Direction.east));

      // assert
      expect(state.hero.position, const Position(3, 2));
    });

    test('grows the explored set and never shrinks it', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(1, 1));
      final before = state.explored;

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.explored, containsAll(before));
      expect(next.explored, containsAll(next.visible));
    });

    test('recomputes what is visible from where the hero lands', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(1, 1));

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(
        next.visible,
        computeFov(next.map, const Position(2, 1), fovRadius),
      );
    });
  });

  group('step, hero attacks', () {
    test('bumping a monster attacks it instead of moving', () {
      // arrange
      final state = crawl(
        ascii: room,
        heroAt: const Position(3, 2),
        heroAttack: 4,
        monsters: [ghoul('ghoul-1', const Position(4, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.hero.position, const Position(3, 2));
      expect(
        events,
        contains(
          const AttackHit(attackerId: 'hero', targetId: 'ghoul-1', damage: 4),
        ),
      );
      expect(next.monsters.single.hp, 6);
    });

    test('a killing blow removes the monster and reports the death', () {
      // arrange
      final state = crawl(
        ascii: room,
        heroAt: const Position(3, 2),
        heroAttack: 4,
        monsters: [ghoul('ghoul-1', const Position(4, 2), hp: 3)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters, isEmpty);
      expect(events, contains(const ActorDied(actorId: 'ghoul-1')));
    });

    test('damage comes from the seeded rng, so a seed replays exactly', () {
      // arrange
      GameState fresh() => crawl(
        ascii: room,
        heroAt: const Position(3, 2),
        heroAttack: 3,
        heroAttackMax: 5,
        monsters: [ghoul('ghoul-1', const Position(4, 2), hp: 200)],
        seed: 99,
      );

      // act
      final first = _damageSequence(fresh());
      final second = _damageSequence(fresh());

      // assert
      expect(first, second);
      expect(first, everyElement(inInclusiveRange(3, 5)));
      expect(first.toSet().length, greaterThan(1));
    });
  });
}

List<int> _damageSequence(GameState state) {
  final damage = <int>[];
  var current = state;
  for (var turn = 0; turn < 5; turn++) {
    final (next, events) = step(current, const MoveAction(Direction.east));
    damage.addAll(
      events
          .whereType<AttackHit>()
          .where((event) => event.attackerId == 'hero')
          .map((event) => event.damage),
    );
    current = next;
  }
  return damage;
}
