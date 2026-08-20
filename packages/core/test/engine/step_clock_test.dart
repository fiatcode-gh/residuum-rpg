import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const hall = '''
##########
#........#
#........#
#........#
##########''';

const longCorridor = '''
##################
#................#
##################''';

Actor beast(
  String id,
  Position at, {
  int speed = 10,
  int hp = 10,
  int attack = 3,
}) => Actor(
  id: id,
  name: 'the beast',
  glyph: 'b',
  position: at,
  hp: hp,
  maxHp: hp,
  attackMin: attack,
  attackMax: attack,
  speed: speed,
  energy: actThreshold,
);

List<Position> _walk(GameState start, int turns, {Direction? push}) {
  final positions = <Position>[];
  var state = start;
  for (var turn = 0; turn < turns; turn++) {
    final (next, _) = step(state, MoveAction(push ?? Direction.west));
    state = next;
    positions.add(state.monsters.single.position);
  }
  return positions;
}

void main() {
  group('step on the speed clock', () {
    test('a matching speed moves exactly once per hero turn', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [beast('beast-1', const Position(8, 3))],
      );

      // act
      final positions = _walk(state, 5);

      // assert
      expect(positions, const [
        Position(8, 2),
        Position(8, 1),
        Position(7, 1),
        Position(6, 1),
        Position(5, 1),
      ]);
    });

    test('a speed twenty monster covers two tiles per hero turn', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [beast('beast-1', const Position(8, 1), speed: 20)],
      );

      // act
      final positions = _walk(state, 3);

      // assert
      expect(positions, const [Position(6, 1), Position(4, 1), Position(2, 1)]);
    });

    test('a speed five monster moves on every second hero turn', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [beast('beast-1', const Position(8, 1), speed: 5)],
      );

      // act
      final positions = _walk(state, 4);

      // assert
      expect(positions, const [
        Position(7, 1),
        Position(7, 1),
        Position(6, 1),
        Position(6, 1),
      ]);
    });

    test('a fast monster lands two attacks in a single turn', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [
          beast('beast-1', const Position(2, 1), speed: 20, attack: 2),
        ],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(
        events.whereType<AttackHit>().where((e) => e.attackerId == 'beast-1'),
        hasLength(2),
      );
      expect(next.hero.hp, 16);
    });

    test('the hero dying mid-schedule stops the turns still owed', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        heroHp: 3,
        monsters: [
          beast('beast-1', const Position(2, 1), speed: 20, attack: 3),
        ],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(
        events.whereType<AttackHit>().where((e) => e.attackerId == 'beast-1'),
        hasLength(1),
      );
      expect(next.isGameOver, isTrue);
    });

    test('a slow monster still gets its turn when it comes due', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [beast('beast-1', const Position(8, 1), speed: 5)],
      );

      // act
      final positions = _walk(state, 10);

      // assert
      expect(positions.last, const Position(3, 1));
    });
  });

  group('step and being noticed', () {
    test('a monster walking into view is noticed exactly once', () {
      // arrange
      var state = crawl(
        ascii: longCorridor,
        heroAt: const Position(1, 1),
        monsters: [beast('beast-1', const Position(12, 1))],
      );
      final noticedPerTurn = <int>[];

      // act
      for (var turn = 0; turn < 5; turn++) {
        final (next, events) = step(state, const MoveAction(Direction.north));
        state = next;
        noticedPerTurn.add(events.whereType<ActorNoticed>().length);
      }

      // assert
      expect(noticedPerTurn, const [0, 0, 1, 0, 0]);
    });

    test('a monster already in view is not noticed again', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [beast('beast-1', const Position(8, 1))],
      );

      // act
      final (_, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(events.whereType<ActorNoticed>(), isEmpty);
    });

    test('the notice carries where the monster was seen', () {
      // arrange
      var state = crawl(
        ascii: longCorridor,
        heroAt: const Position(1, 1),
        monsters: [beast('beast-1', const Position(12, 1))],
      );

      // act
      var noticed = <ActorNoticed>[];
      for (var turn = 0; turn < 3; turn++) {
        final (next, events) = step(state, const MoveAction(Direction.north));
        state = next;
        noticed = events.whereType<ActorNoticed>().toList();
      }

      // assert
      expect(noticed.single.actorId, 'beast-1');
      expect(noticed.single.at, const Position(9, 1));
      expect(state.visible, contains(noticed.single.at));
    });
  });
}
