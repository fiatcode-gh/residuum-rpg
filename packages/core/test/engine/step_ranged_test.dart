import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
###########
#.........#
#.........#
#.........#
#.........#
#.........#
#.........#
###########''';

const _pillarRoom = '''
###########
#....#....#
#....#....#
#.........#
#.........#
###########''';

/// A speed-5 spitter holding no stored energy: the clock owes it nothing.
Actor spitter(String id, Position at, {int energy = 0, int speed = 5}) => Actor(
  id: id,
  name: 'the spitter',
  glyph: 'p',
  position: at,
  hp: 7,
  maxHp: 7,
  attackMin: 2,
  attackMax: 3,
  speed: speed,
  energy: energy,
  reach: 3,
);

List<AttackHit> _hitsBy(List<GameEvent> events, String attackerId) => events
    .whereType<AttackHit>()
    .where((hit) => hit.attackerId == attackerId)
    .toList();

GameState _arena({
  required Position heroAt,
  required List<Actor> monsters,
  String ascii = _room,
  int warded = 0,
}) => crawl(ascii: ascii, heroAt: heroAt, monsters: monsters, warded: warded);

void main() {
  group('a monster with reach shoots along a line of sight', () {
    test('shoots from exactly three tiles away, standing where it stood', () {
      // arrange — the spitter is owed a turn and the hero stands three tiles
      // east; the hero bumps the wall so the distance does not change
      final state = _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(5, 1), energy: 100)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, const Position(5, 1));
      expect(_hitsBy(events, 'spitter-1'), hasLength(1));
    });

    test('measures by Chebyshev: a diagonal at three is a shot', () {
      // arrange
      final state = _arena(
        heroAt: const Position(2, 2),
        monsters: [spitter('spitter-1', const Position(4, 4), energy: 100)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert — the hero steps to (2,1); Chebyshev((4,4),(2,1)) is 3
      expect(next.monsters.single.position, const Position(4, 4));
      expect(_hitsBy(events, 'spitter-1'), hasLength(1));
    });

    test('a second tile closer is also a shot, and stays one', () {
      // arrange — distance two: inside the band the floor of the mutation
      // table guards, so the pin reads the shot, not the boundary
      final state = _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(4, 1), energy: 100)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, const Position(4, 1));
      expect(_hitsBy(events, 'spitter-1'), hasLength(1));
    });

    test('melees from adjacency, like anything else', () {
      // arrange — distance one is the adjacency branch, not the shot; the
      // hero bumps the wall so the distance does not change
      final state = _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(3, 1), energy: 100)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, const Position(3, 1));
      expect(_hitsBy(events, 'spitter-1'), hasLength(1));
    });

    test('walks when the target is out of reach', () {
      // arrange — five tiles away, two past its reach; the hero steps east so
      // the spitter's own step cannot land a lunge either
      final state = _arena(
        heroAt: const Position(1, 1),
        monsters: [spitter('spitter-1', const Position(1, 6), energy: 100)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters.single.position, const Position(1, 5));
      expect(
        events.whereType<ActorMoved>().map((event) => event.actorId),
        contains('spitter-1'),
      );
      expect(_hitsBy(events, 'spitter-1'), isEmpty);
    });

    test('cannot shoot without line of sight', () {
      // arrange — the pillar hides the spitter's tile from the hero's
      // turn-start sight, though Chebyshev would call it exactly in reach;
      // the hero bumps the wall so the distance does not change
      final state = _arena(
        ascii: _pillarRoom,
        heroAt: const Position(3, 3),
        monsters: [spitter('spitter-1', const Position(6, 1), energy: 100)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert — within reach, but unseen: it walks instead of standing and
      // shooting. The tile it lands on sits in the hero's sight, so the
      // lunge fires from there — that is the ambush rule earning its shot,
      // not this branch's; what this pin holds is that nothing was shot
      // from the tile the hero could not see.
      expect(next.monsters.single.position, const Position(6, 2));
      expect(
        events.whereType<ActorMoved>().map((event) => event.actorId),
        contains('spitter-1'),
      );
    });
  });

  group('the shot behaves exactly as _defend', () {
    test('a ward soaks a shot exactly as it soaks a claw', () {
      // arrange
      final state = _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(5, 1), energy: 100)],
        warded: 5,
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert — the ward takes what lands whole: a 2-3 shot against a pool
      // of five is eaten to the last point, and the floor of one never
      // applies, because the ward soaks after the armour and the roll was
      // never armour's to stop
      expect(events.whereType<WardStruck>(), isNotEmpty);
      expect(next.warded, inInclusiveRange(2, 3));
      expect(next.hero.hp, 20);
    });

    test('a warded hero and a bare one draw from the stream identically', () {
      // arrange — the ward is arithmetic over a number already on the state,
      // so it adds no roll, on a shot any more than on a claw
      GameState bare() => _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(5, 1), energy: 100)],
      );
      GameState warded() => _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(5, 1), energy: 100)],
        warded: 5,
      );

      // act
      final (bareAfter, _) = step(bare(), const MoveAction(Direction.north));
      final (wardedAfter, _) = step(
        warded(),
        const MoveAction(Direction.north),
      );

      // assert
      expect(bareAfter.rng.state, wardedAfter.rng.state);
    });

    test('the shot draws exactly one number from the combat stream', () {
      // arrange — a bare hero has no dodge chance, so "no dodge chance does
      // not roll at all" holds and the only draw is the damage roll
      GameState fresh() => _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(5, 1), energy: 100)],
      );
      final expected = Rng(1)..rollRange(2, 3);

      // act
      final (after, _) = step(fresh(), const MoveAction(Direction.north));

      // assert
      expect(after.rng.state, expected.state);
    });

    test('a spitter the clock owes nothing stands still and says nothing', () {
      // arrange — in reach and in sight, but unowed
      final state = _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(5, 1))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert — the ambush does not lend an unowed monster a shot, and a
      // spitter that could shoot but may not act stands its ground
      expect(_hitsBy(events, 'spitter-1'), isEmpty);
      expect(next.monsters.single.position, const Position(5, 1));
      expect(next.monsters.single.energy, 50);
    });
  });

  group('the spitter walks the ambush as the rules allow', () {
    test('a spitter that steps into a seen line lunges its shot', () {
      // arrange — four tiles out, owed a turn: it walks toward the hero, and
      // the step that lands the line also fires the shot
      final state = _arena(
        heroAt: const Position(1, 1),
        monsters: [spitter('spitter-1', const Position(1, 5), energy: 100)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters.single.position, const Position(1, 4));
      expect(_hitsBy(events, 'spitter-1'), hasLength(1));
    });

    test('a lunged shot is paid for with the turn it would have been owed', () {
      // arrange — same fight as the lunge above
      final state = _arena(
        heroAt: const Position(1, 1),
        monsters: [spitter('spitter-1', const Position(1, 5), energy: 100)],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert — the speed-5 spitter spent its turn moving and the ambush
      // spends the turn that would have been owed next: fifty accrued,
      // one hundred charged
      expect(next.monsters.single.energy, 50 - 100);
    });
  });
}
