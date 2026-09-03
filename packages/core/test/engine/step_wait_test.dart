import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// The wait verb: the hero holds ground and the world ticks.
///
/// The verb's guarantee is that waiting is a real turn — the monster phase
/// runs exactly as it does after any other action, so a shooter keeps shooting
/// a hero who stands still. Everything else about the state is untouched.

const _room = '''
###########
#.........#
#.........#
#.........#
#.........#
#.........#
###########''';

/// A speed-5 spitter holding no stored energy: the clock owes it nothing.
Actor spitter(String id, Position at, {int energy = 0}) => Actor(
  id: id,
  name: 'the spitter',
  glyph: 'p',
  position: at,
  hp: 7,
  maxHp: 7,
  attackMin: 2,
  attackMax: 3,
  speed: 5,
  energy: energy,
  reach: 3,
);

GameState _arena({
  required Position heroAt,
  List<Actor> monsters = const [],
  Map<String, int> bound = const {},
  bool isEncounter = false,
}) => crawl(
  ascii: _room,
  heroAt: heroAt,
  monsters: monsters,
  bound: bound,
  isEncounter: isEncounter,
);

void main() {
  group('the wait verb', () {
    test('a wait emits HeroWaited and nothing else in an empty arena', () {
      // arrange
      final game = _arena(heroAt: const Position(2, 1));

      // act
      final (_, events) = step(game, const WaitAction());

      // assert - one event, the wait itself; nothing moved
      expect(events, [const HeroWaited()]);
    });

    test('a wait leaves the hero standing and costs the turn', () {
      // arrange
      final game = _arena(
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(8, 1))],
      );

      // act
      final (after, _) = step(game, const WaitAction());

      // assert - the hero stood still, and the world ticked: the ghoul closed
      expect(after.hero.position, const Position(2, 1));
      expect(after.monsters.single.position, const Position(7, 1));
    });

    test('a reach-holder shoots a waiting hero — waiting is a real turn', () {
      // arrange - the spitter stands three tiles out, owed its turn
      final game = _arena(
        heroAt: const Position(2, 1),
        monsters: [spitter('spitter-1', const Position(5, 1), energy: 100)],
      );

      // act
      final (after, events) = step(game, const WaitAction());

      // assert - the monster phase ran: the hero bled for standing still
      expect(events.whereType<HeroWaited>(), isNotEmpty);
      expect(events.whereType<AttackHit>(), isNotEmpty);
      expect(after.hero.hp, lessThan(20));
    });

    test('a bound monster sits out a waited turn', () {
      // arrange - the ghoul is adjacent but bound for two turns
      final game = _arena(
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 2))],
        bound: {'ghoul-1': 2},
      );

      // act
      final (after, events) = step(game, const WaitAction());

      // assert - no swing, and the hold spent one of its turns
      expect(events.whereType<AttackHit>(), isEmpty);
      expect(after.hero.hp, 20);
      expect(after.bound['ghoul-1'], 1);
    });

    test('a wait is legal in an encounter state', () {
      // arrange - the same floor flagged as a road fight
      final game = _arena(
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 2))],
        isEncounter: true,
      );

      // act
      final (after, events) = step(game, const WaitAction());

      // assert - the turn spent exactly as in a crawl: the world ticked and
      // the adjacent ghoul swung
      expect(events.whereType<HeroWaited>(), isNotEmpty);
      expect(events.whereType<AttackHit>(), isNotEmpty);
    });

    test('a wait is never refused', () {
      // arrange - an arena with nothing underfoot and an empty pack
      final game = _arena(heroAt: const Position(2, 1));

      // act
      final (after, events) = step(game, const WaitAction());

      // assert - no refusal-shaped event came back
      expect(events.whereType<ActionRefused>(), isEmpty);
      expect(events.whereType<InventoryFull>(), isEmpty);
      expect(events.whereType<HeroWaited>(), isNotEmpty);
    });

    test('the same seed and the same waits replay identically', () {
      // arrange
      GameState seeded() => _arena(
        heroAt: const Position(2, 1),
        monsters: [
          ghoul('ghoul-1', const Position(2, 2)),
          ghoul('ghoul-2', const Position(8, 3)),
        ],
      );
      final first = seeded();
      final second = seeded();

      // act - three waits each
      var a = first;
      var b = second;
      for (var i = 0; i < 3; i++) {
        a = step(a, const WaitAction()).$1;
        b = step(b, const WaitAction()).$1;
      }

      // assert
      expect(a.hero.energy, b.hero.energy);
      expect(a.hero.position, b.hero.position);
      expect(
        [for (final m in a.monsters) (m.id, m.position, m.energy)],
        [for (final m in b.monsters) (m.id, m.position, m.energy)],
      );
    });
  });
}
