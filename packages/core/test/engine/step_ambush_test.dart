import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const hall = '''
##########
#........#
#........#
#........#
##########''';

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

Floor adjacentFloor(int depth) => Floor(
  map: FloorMap.parse(downstairs),
  heroSpawn: const Position(1, 1),
  monsters: [ghoul('ghoul-9', const Position(1, 2))],
  stairsDown: const Position(8, 1),
  stairsUp: const Position(1, 1),
);

/// A monster at [at] holding no stored energy: the clock owes it nothing.
Actor drifter(String id, Position at, {int speed = 5}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: 2,
  attackMax: 2,
  speed: speed,
  energy: 0,
);

List<AttackHit> _hitsBy(List<GameEvent> events, String attackerId) => events
    .whereType<AttackHit>()
    .where((hit) => hit.attackerId == attackerId)
    .toList();

void main() {
  group('the ambush opening', () {
    test('a hero who walks to adjacency eats the opening swing', () {
      // arrange — the ghoul holds no stored energy, so the clock owes it
      // nothing this turn; the hero closes the gap anyway
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [drifter('ghoul-1', const Position(3, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.hero.position, const Position(2, 2));
      expect(_hitsBy(events, 'ghoul-1'), hasLength(1));
    });

    test("the opening spends the opener's energy, not just the moment", () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [drifter('ghoul-1', const Position(3, 2))],
      );

      // act — a speed-5 ghoul accrues fifty energy while the speed-10 hero
      // earns its next turn; the opening charges the other hundred
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(_hitsBy(events, 'ghoul-1'), hasLength(1));
      expect(next.monsters.single.energy, -50);
      expect(next.hero.hp, lessThan(20));
    });

    test('a monster already in reach at turn start gets no second swing', () {
      // arrange — adjacent at turn start, and unowed: only the ambush could
      // hand this monster a swing, and it was in reach before the hero moved
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [drifter('ghoul-1', const Position(3, 2))],
      );

      // act — the hero bumps the wall: the monster stays in reach, still owed
      // nothing
      final (next, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(_hitsBy(events, 'ghoul-1'), isEmpty);
      expect(next.monsters.single.energy, 50);
    });

    test('an owed opener swings once, and its owed turn is the opening', () {
      // arrange — the monster is owed a turn this phase and the hero's move
      // hands it the opening besides
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [ghoul('ghoul-1', const Position(3, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert — one swing, not two: the opening consumed the owed turn, and
      // the schedule's spend-plus-accrual is the energy it ends the turn on
      expect(_hitsBy(events, 'ghoul-1'), hasLength(1));
      expect(next.monsters.single.energy, 100);
    });

    test(
      'a monster whose move creates adjacency attacks in the same phase',
      () {
        // arrange — two tiles away and owed a turn: it steps adjacent and
        // swings before the hero may answer
        final state = crawl(
          ascii: hall,
          heroAt: const Position(1, 2),
          monsters: [ghoul('ghoul-1', const Position(3, 2))],
        );

        // act
        final (next, events) = step(state, const MoveAction(Direction.west));

        // assert
        expect(
          events,
          contains(
            const ActorMoved(
              actorId: 'ghoul-1',
              from: Position(3, 2),
              to: Position(2, 2),
            ),
          ),
        );
        expect(_hitsBy(events, 'ghoul-1'), hasLength(1));
        expect(next.hero.hp, lessThan(20));

        // assert — and the swing is paid for: the owed turn bought the step,
        // the ambush spends the turn that would have been owed next, so the
        // speed-10 ghoul ends the phase on a drained clock, not a free one
        expect(next.monsters.single.energy, 0);
      },
    );

    test(
      'a chaser that held reach at turn start catches up without swinging',
      () {
        // arrange — adjacent at turn start; the hero slips away and the ghoul
        // closes the gap in the same phase. Its reach was never newly created:
        // it had it when the turn began.
        final state = crawl(
          ascii: hall,
          heroAt: const Position(2, 2),
          monsters: [ghoul('ghoul-1', const Position(3, 2))],
        );

        // act
        final (next, events) = step(state, const MoveAction(Direction.north));

        // assert — it steps adjacent (the flow field chooses (3,1)) and waits
        // for the swing the clock owes it
        expect(next.monsters.single.position, const Position(3, 1));
        expect(_hitsBy(events, 'ghoul-1'), isEmpty);
      },
    );

    test('a bound monster never ambushes', () {
      // arrange — the hero closes with a monster the clock is holding still
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [drifter('ghoul-1', const Position(3, 2))],
        bound: const {'ghoul-1': 3},
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert — held monsters get no openings, and an unowed held monster
      // spends none of its own counter either
      expect(_hitsBy(events, 'ghoul-1'), isEmpty);
      expect(next.bound, const {'ghoul-1': 3});
    });
  });

  group('arrival is still safe', () {
    test('a fresh floor ambushes nobody', () {
      // arrange — the generated monster stands right beside the arrival tile,
      // ready to act
      final state = crawl(
        ascii: upstairs,
        heroAt: const Position(3, 1),
        monsters: [ghoul('ghoul-1', const Position(1, 2))],
        depth: 1,
        stairsDown: const Position(3, 1),
        buildFloor: adjacentFloor,
      );

      // act
      final (arrived, arrivalEvents) = step(state, const DescendAction());

      // assert
      expect(arrivalEvents.whereType<AttackHit>(), isEmpty);
      expect(arrived.hero.hp, 20);

      // act — the first turn on the floor: the adjacent monster is owed a
      // swing and takes it, and nothing ambushes besides
      final (next, events) = step(arrived, const MoveAction(Direction.north));

      // assert
      expect(_hitsBy(events, 'ghoul-9'), hasLength(1));
      expect(next.hero.position, const Position(1, 1));
      expect(next.hero.hp, lessThan(20));
    });

    test(
      'a restored monster left weak beside the stairs still waits its turn',
      () {
        // arrange — a remembered floor holds the energy the hero left it with
        final remembered = FloorMemory(
          map: FloorMap.parse(downstairs),
          monsters: [
            ghoul(
              'ghoul-9',
              const Position(1, 2),
              speed: 5,
            ).copyWith(energy: 0),
          ],
          groundItems: const {},
          explored: const {},
          stairsDown: const Position(8, 1),
          stairsUp: const Position(1, 1),
        );
        final state = crawl(
          ascii: upstairs,
          heroAt: const Position(3, 1),
          monsters: [ghoul('ghoul-1', const Position(1, 2))],
          depth: 1,
          stairsDown: const Position(3, 1),
          floors: {2: remembered},
        );

        // act
        final (arrived, _) = step(state, const DescendAction());
        final (next, events) = step(arrived, const MoveAction(Direction.north));

        // assert — a speed-5 ghoul owed nothing by the clock, and the ambush
        // must not lend it one: it was in reach at turn start
        expect(_hitsBy(events, 'ghoul-9'), isEmpty);
        expect(next.monsters.single.energy, 50);
      },
    );
  });
}
