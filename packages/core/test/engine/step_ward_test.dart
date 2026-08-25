import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
#####
#...#
#####''';

/// A crawl with a monster standing next to the hero, ready to swing.
GameState _besieged({
  int warded = 0,
  int heroHp = 20,
  int attack = 4,
  Map<SkillId, SkillState> skills = untrainedSkills,
  Equipment equipment = const {},
}) => crawl(
  ascii: _room,
  heroAt: const Position(1, 1),
  monsters: [ghoul('ghoul-1', const Position(2, 1), attack: attack)],
  heroHp: heroHp,
  warded: warded,
  skills: skills,
  equipment: equipment,
);

void main() {
  group('a ward standing when a blow lands', () {
    test('takes the blow instead of the hero, up to what it holds', () {
      // arrange
      final game = _besieged(warded: 6, attack: 4);

      // act
      final (after, events) = step(game, const DescendAction());

      // assert
      expect(after.hero.hp, 20);
      expect(after.warded, 2);
      expect(events, contains(const WardStruck(absorbed: 4, remaining: 2)));
    });

    test('says nothing about a hit that never reached the hero', () {
      // arrange
      final game = _besieged(warded: 6, attack: 4);

      // act
      final (_, events) = step(game, const DescendAction());

      // assert - AttackHit is what the log says when hit points drop, and none
      // did: a ward that reported a hit would have the player reading a wound
      // they did not take
      expect(events.whereType<AttackHit>(), isEmpty);
    });

    test('lets the remainder through once it is spent', () {
      // arrange
      final game = _besieged(warded: 1, attack: 4);

      // act
      final (after, events) = step(game, const DescendAction());

      // assert
      expect(after.warded, 0);
      expect(after.hero.hp, 17);
      expect(events, contains(const WardStruck(absorbed: 1, remaining: 0)));
      expect(
        events,
        contains(
          const AttackHit(attackerId: 'ghoul-1', targetId: 'hero', damage: 3),
        ),
      );
    });

    test('sits after the floor of one, never before it', () {
      // arrange - armour heavier than the blow, so the hit is floored to one
      final game = _besieged(
        warded: 6,
        attack: 2,
        equipment: {
          EquipSlot.chest: const Item(
            id: 'kit-9',
            base: BaseItem(
              id: 'mail-hauberk',
              name: 'Mail Hauberk',
              glyph: '[',
              slot: EquipSlot.chest,
              armor: 8,
            ),
            rarity: Rarity.common,
          ),
        },
      );

      // act
      final (after, _) = step(game, const DescendAction());

      // assert - the ward soaks the one point armour could not stop, so it
      // spends one rather than the two the monster swung
      expect(after.warded, 5);
      expect(after.hero.hp, 20);
    });

    test('says nothing at all when there is no ward to strike', () {
      // arrange
      final game = _besieged(attack: 4);

      // act
      final (_, events) = step(game, const DescendAction());

      // assert
      expect(events.whereType<WardStruck>(), isEmpty);
    });

    test('adds no roll to the combat stream', () {
      // arrange
      final bare = _besieged(attack: 4);
      final shielded = _besieged(warded: 6, attack: 4);
      final before = bare.rng.state;

      // act
      final (afterBare, _) = step(bare, const DescendAction());
      final (afterShielded, _) = step(shielded, const DescendAction());

      // assert - a ward is arithmetic, not a decision the dungeon rolls for,
      // and a roll here would move every fight a warded hero ever had
      expect(afterShielded.rng.state, afterBare.rng.state);
      expect(afterBare.rng.state, isNot(before));
    });

    test('still trains the defence the hero is dressed for', () {
      // arrange
      final game = _besieged(warded: 6, attack: 4);

      // act
      final (after, _) = step(game, const DescendAction());

      // assert - the hero was swung at, and being swung at is the trigger
      expect(after.skills[SkillId.fleetfoot], const SkillState(xp: 1));
    });

    test('carries across a stairway, because it is on the hero', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: const Position(1, 1),
        stairsDown: const Position(1, 1),
        warded: 5,
        buildFloor: (depth) => Floor(
          map: FloorMap.parse(_room),
          heroSpawn: const Position(1, 1),
          monsters: const [],
          stairsUp: const Position(1, 1),
          stairsDown: const Position(3, 1),
        ),
      );

      // act
      final (after, _) = step(game, const DescendAction());

      // assert
      expect(after.warded, 5);
    });
  });
}
