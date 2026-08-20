import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _hall = '''
#######
#.....#
#.....#
#######''';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _maul = BaseItem(
  id: 'maul',
  name: 'Maul',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.two,
  attackMin: 7,
  attackMax: 11,
);

const _hauberk = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 3,
  heavy: true,
);

const _jerkin = BaseItem(
  id: 'leather-jerkin',
  name: 'Leather Jerkin',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 1,
);

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 4,
);

Item _worn(BaseItem base, {List<Affix> affixes = const []}) => Item(
  id: 'worn-${base.id}',
  base: base,
  rarity: Rarity.values[affixes.length],
  affixes: affixes,
);

int _damageTaken(List<GameEvent> events) => events
    .whereType<AttackHit>()
    .where((event) => event.targetId == 'hero')
    .single
    .damage;

void main() {
  group('armour reduces monster damage', () {
    test('subtracts armour from the roll', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 1), attack: 4)],
        equipment: {EquipSlot.chest: _worn(_hauberk)},
      );

      // act
      final (_, events) = step(game, const MoveAction(Direction.north));

      // assert
      expect(_damageTaken(events), 1);
    });

    test('a lightly armoured hero takes one less than a bare one', () {
      // arrange
      GameState fresh({required Equipment worn}) => crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 1), attack: 4)],
        equipment: worn,
      );

      // act
      final (_, bare) = step(
        fresh(worn: const {}),
        const MoveAction(Direction.north),
      );
      final (_, light) = step(
        fresh(worn: {EquipSlot.chest: _worn(_jerkin)}),
        const MoveAction(Direction.north),
      );

      // assert
      expect(_damageTaken(bare), 4);
      expect(_damageTaken(light), 3);
    });

    test('never reduces a hit below one', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 1), attack: 2)],
        equipment: {EquipSlot.chest: _worn(_hauberk)},
        skills: const {SkillId.bulwark: SkillState(level: 40)},
      );

      // act
      final (after, events) = step(game, const MoveAction(Direction.north));

      // assert
      expect(_damageTaken(events), 1);
      expect(after.hero.hp, 19);
    });
  });

  group('the hero swing', () {
    test('comes from the derived attack, not the bare actor', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        heroAttack: 1,
        heroAttackMax: 2,
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 200)],
        equipment: {EquipSlot.mainHand: _worn(_sword)},
      );

      // act
      final (_, events) = step(game, const MoveAction(Direction.east));

      // assert
      final dealt = events
          .whereType<AttackHit>()
          .where((event) => event.attackerId == 'hero')
          .single
          .damage;
      expect(dealt, inInclusiveRange(4, 7));
    });
  });

  group('dodge', () {
    test('a hero with no dodge chance never draws from the combat stream', () {
      // arrange
      GameState fresh({required Equipment worn}) => crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [
          Actor(
            id: 'ghoul-1',
            name: 'the ghoul',
            glyph: 'g',
            position: const Position(2, 1),
            hp: 10,
            maxHp: 10,
            attackMin: 2,
            attackMax: 4,
            speed: 10,
            energy: actThreshold,
          ),
        ],
        seed: 5,
        equipment: worn,
      );

      // act
      final (_, bare) = step(
        fresh(worn: const {}),
        const MoveAction(Direction.north),
      );
      final (_, dressed) = step(
        fresh(worn: {EquipSlot.chest: _worn(_jerkin)}),
        const MoveAction(Direction.north),
      );

      // assert — one point of armour and nothing else, so the same seed must
      // have produced the same roll
      expect(_damageTaken(dressed), _damageTaken(bare) - 1);
    });

    test('a trained hero sometimes takes no damage at all', () {
      // arrange
      var game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        heroHp: 100000,
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 100000)],
        skills: const {SkillId.fleetfoot: SkillState(level: maxSkillLevel)},
        seed: 3,
      );

      // act
      final dodged = <AttackDodged>[];
      for (var turn = 0; turn < 60; turn++) {
        final (next, events) = step(game, const MoveAction(Direction.east));
        dodged.addAll(events.whereType<AttackDodged>());
        game = next;
      }

      // assert
      expect(dodged, isNotEmpty);
      expect(dodged.first.attackerId, 'ghoul-1');
    });

    test('a dodged swing does no damage and still trains the dodge', () {
      // arrange
      var game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        heroHp: 100000,
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 100000)],
        skills: const {SkillId.fleetfoot: SkillState(level: maxSkillLevel)},
        seed: 3,
      );

      // act
      var turnsWithADodge = 0;
      var hitsOnADodgeTurn = 0;
      for (var turn = 0; turn < 60; turn++) {
        final (next, events) = step(game, const MoveAction(Direction.east));
        if (events.whereType<AttackDodged>().isNotEmpty) {
          turnsWithADodge++;
          hitsOnADodgeTurn += events
              .whereType<AttackHit>()
              .where((event) => event.targetId == 'hero')
              .length;
        }
        game = next;
      }

      // assert
      expect(turnsWithADodge, greaterThan(0));
      expect(hitsOnADodgeTurn, 0);
    });
  });

  group('skill training', () {
    test('Arms trains on a hit landed with one hand', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 200)],
        equipment: {EquipSlot.mainHand: _worn(_sword)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.east));

      // assert
      expect(after.skills[SkillId.arms], const SkillState(xp: 1));
      expect(after.skills[SkillId.might], const SkillState());
    });

    test('fists train Arms too', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 200)],
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.east));

      // assert
      expect(after.skills[SkillId.arms], const SkillState(xp: 1));
    });

    test('Might trains on a hit landed with two hands', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 200)],
        equipment: {EquipSlot.mainHand: _worn(_maul)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.east));

      // assert
      expect(after.skills[SkillId.might], const SkillState(xp: 1));
      expect(after.skills[SkillId.arms], const SkillState());
    });

    test('a missed swing at a wall trains nothing', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        equipment: {EquipSlot.mainHand: _worn(_sword)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.north));

      // assert
      expect(after.skills, untrainedSkills);
    });

    test('Bulwark trains on a hit taken in heavy armour', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 1), attack: 1)],
        equipment: {EquipSlot.chest: _worn(_hauberk)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.north));

      // assert
      expect(after.skills[SkillId.bulwark], const SkillState(xp: 1));
      expect(after.skills[SkillId.fleetfoot], const SkillState());
    });

    test('Fleetfoot trains on a hit taken in light armour', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 1), attack: 1)],
        equipment: {EquipSlot.chest: _worn(_jerkin)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.north));

      // assert
      expect(after.skills[SkillId.fleetfoot], const SkillState(xp: 1));
      expect(after.skills[SkillId.bulwark], const SkillState());
    });

    test('Fleetfoot trains on a hit taken wearing nothing at all', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 1), attack: 1)],
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.north));

      // assert
      expect(after.skills[SkillId.fleetfoot], const SkillState(xp: 1));
    });

    test('one heavy piece is enough to make it Bulwark', () {
      // arrange
      const helm = BaseItem(
        id: 'iron-helm',
        name: 'Iron Helm',
        glyph: '[',
        slot: EquipSlot.head,
        armor: 1,
        heavy: true,
      );
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(2, 1), attack: 1)],
        equipment: {
          EquipSlot.head: _worn(helm),
          EquipSlot.chest: _worn(_jerkin),
        },
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.north));

      // assert
      expect(after.skills[SkillId.bulwark], const SkillState(xp: 1));
      expect(after.skills[SkillId.fleetfoot], const SkillState());
    });

    test('a level-up reaches the log', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 2000)],
        skills: const {SkillId.arms: SkillState(level: 0, xp: 3)},
      );

      // act
      final (after, events) = step(game, const MoveAction(Direction.east));

      // assert
      expect(
        events,
        contains(const SkillLevelledUp(skill: SkillId.arms, level: 1)),
      );
      expect(after.skills[SkillId.arms]?.level, 1);
    });

    test('training mid-turn changes the very next monster swing', () {
      // arrange — Bulwark one point short of level one, two monsters adjacent
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [
          ghoul('ghoul-1', const Position(2, 1), attack: 6),
          ghoul('ghoul-2', const Position(1, 2), attack: 6),
        ],
        equipment: {EquipSlot.chest: _worn(_hauberk)},
        skills: const {SkillId.bulwark: SkillState(level: 3, xp: 9)},
      );

      // act
      final (_, events) = step(game, const MoveAction(Direction.north));

      // assert — the level-up lands between the two hits, so the second is
      // reduced by the armour the first one bought
      final taken = events
          .whereType<AttackHit>()
          .where((event) => event.targetId == 'hero')
          .map((event) => event.damage)
          .toList();
      expect(
        events,
        contains(const SkillLevelledUp(skill: SkillId.bulwark, level: 4)),
      );
      expect(taken, [2, 1]);
    });
  });

  group('the speed clock reads the derived speed', () {
    test('a speed affix buys extra hero turns', () {
      // arrange
      const swiftness = Affix(
        id: 'of-swiftness',
        affixName: 'of Swiftness',
        isPrefix: false,
        speed: 10,
      );
      GameState fresh({required Equipment worn}) => crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(5, 2))],
        equipment: worn,
      );
      int monsterTurnsOver(GameState start, int turns) {
        var game = start;
        var moved = 0;
        for (var turn = 0; turn < turns; turn++) {
          final (after, events) = step(game, const MoveAction(Direction.north));
          moved += events
              .whereType<ActorMoved>()
              .where((event) => event.actorId == 'ghoul-1')
              .length;
          game = after;
        }
        return moved;
      }

      // act
      final slow = monsterTurnsOver(fresh(worn: const {}), 2);
      final fast = monsterTurnsOver(
        fresh(
          worn: {
            EquipSlot.chest: _worn(_jerkin, affixes: const [swiftness]),
          },
        ),
        2,
      );

      // assert
      expect(slow, 2);
      expect(fast, 1);
    });
  });

  group('derived max hp', () {
    test('gear raises the hero ceiling', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        equipment: {
          EquipSlot.chest: _worn(_hauberk, affixes: const [_vigour]),
        },
      );

      // act
      final max = heroMaxHp(game.hero, game.loadout);

      // assert
      expect(max, 24);
    });
  });
}
