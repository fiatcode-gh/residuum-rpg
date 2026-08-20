import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const _fists = Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: Position(1, 1),
  hp: 20,
  maxHp: 20,
  attackMin: 1,
  attackMax: 2,
  speed: 10,
  energy: actThreshold,
);

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

const _swiftness = Affix(
  id: 'of-swiftness',
  affixName: 'of Swiftness',
  isPrefix: false,
  speed: 2,
);

const _keen = Affix(
  id: 'keen',
  affixName: 'Keen',
  isPrefix: true,
  attackMax: 2,
);

Item _rolled(BaseItem base, {List<Affix> affixes = const []}) => Item(
  id: 'worn-${base.id}',
  base: base,
  rarity: Rarity.values[affixes.length],
  affixes: affixes,
);

Loadout _wearing(List<Item> items, {Map<SkillId, SkillState>? skills}) =>
    Loadout(
      equipment: {for (final item in items) item.base.slot!: item},
      skills: skills ?? untrainedSkills,
    );

void main() {
  group('heroAttack', () {
    test('a bare hero swings its fists', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final range = heroAttack(_fists, loadout);

      // assert
      expect(range, (1, 2));
    });

    test('a weapon adds to the fists rather than replacing them', () {
      // arrange
      final loadout = _wearing([_rolled(_sword)]);

      // act
      final range = heroAttack(_fists, loadout);

      // assert
      expect(range, (4, 7));
    });

    test('stacked affixes all count', () {
      // arrange
      final loadout = _wearing([
        _rolled(_sword, affixes: const [_keen]),
        _rolled(_hauberk, affixes: const [_vigour]),
      ]);

      // act
      final range = heroAttack(_fists, loadout);

      // assert
      expect(range, (4, 9));
    });

    test('Arms trains the one-handed swing and Might leaves it alone', () {
      // arrange
      final trained = _wearing(
        [_rolled(_sword)],
        skills: const {
          SkillId.arms: SkillState(level: 6),
          SkillId.might: SkillState(level: 40),
        },
      );

      // act
      final range = heroAttack(_fists, trained);

      // assert
      expect(range, (7, 10));
    });

    test('Might trains the two-handed swing and Arms leaves it alone', () {
      // arrange
      final trained = _wearing(
        [_rolled(_maul)],
        skills: const {
          SkillId.arms: SkillState(level: 40),
          SkillId.might: SkillState(level: 6),
        },
      );

      // act
      final range = heroAttack(_fists, trained);

      // assert
      expect(range, (11, 16));
    });

    test('bare fists are trained by Arms', () {
      // arrange
      final trained = _wearing(
        const [],
        skills: const {SkillId.arms: SkillState(level: 4)},
      );

      // act
      final range = heroAttack(_fists, trained);

      // assert
      expect(range, (3, 4));
    });
  });

  group('heroArmor', () {
    test('is zero with nothing on', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final armor = heroArmor(loadout);

      // assert
      expect(armor, 0);
    });

    test('sums every worn piece and its affixes', () {
      // arrange
      final loadout = _wearing([
        _rolled(_hauberk, affixes: const [_swiftness]),
      ]);

      // act
      final armor = heroArmor(loadout);

      // assert
      expect(armor, 3);
    });

    test('Bulwark adds half its level', () {
      // arrange
      final loadout = _wearing(
        [_rolled(_hauberk)],
        skills: const {SkillId.bulwark: SkillState(level: 5)},
      );

      // act
      final armor = heroArmor(loadout);

      // assert
      expect(armor, 5);
    });
  });

  group('heroDodgePercent', () {
    test('is zero untrained, so an unskilled hero never rolls to dodge', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final dodge = heroDodgePercent(loadout);

      // assert
      expect(dodge, 0);
    });

    test('rises three points per Fleetfoot level', () {
      // arrange
      final loadout = _wearing(
        const [],
        skills: const {SkillId.fleetfoot: SkillState(level: 4)},
      );

      // act
      final dodge = heroDodgePercent(loadout);

      // assert
      expect(dodge, 12);
    });

    test('is capped, so dodge can never crowd out armour entirely', () {
      // arrange
      final loadout = _wearing(
        const [],
        skills: const {SkillId.fleetfoot: SkillState(level: 90)},
      );

      // act
      final dodge = heroDodgePercent(loadout);

      // assert
      expect(dodge, dodgeCapPercent);
    });
  });

  group('heroMaxHp and heroSpeed', () {
    test('base values come from the hero itself', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final derived = (heroMaxHp(_fists, loadout), heroSpeed(_fists, loadout));

      // assert
      expect(derived, (20, 10));
    });

    test('affixes add to both', () {
      // arrange
      final loadout = _wearing([
        _rolled(_hauberk, affixes: const [_vigour, _swiftness]),
      ]);

      // act
      final derived = (heroMaxHp(_fists, loadout), heroSpeed(_fists, loadout));

      // assert
      expect(derived, (24, 12));
    });
  });

  group('Loadout', () {
    test('knows whether anything worn is heavy', () {
      // arrange
      final heavy = _wearing([_rolled(_hauberk)]);
      final light = _wearing([_rolled(_jerkin)]);
      final bare = _wearing(const []);

      // act
      final wearsHeavy = (heavy.wearsHeavy, light.wearsHeavy, bare.wearsHeavy);

      // assert
      expect(wearsHeavy, (true, false, false));
    });

    test('knows whether the held weapon needs both hands', () {
      // arrange
      final twoHanded = _wearing([_rolled(_maul)]);
      final oneHanded = _wearing([_rolled(_sword)]);
      final empty = _wearing(const []);

      // act
      final both = (
        twoHanded.wieldsTwoHanded,
        oneHanded.wieldsTwoHanded,
        empty.wieldsTwoHanded,
      );

      // assert
      expect(both, (true, false, false));
    });

    test('reads a missing skill as untrained rather than throwing', () {
      // arrange
      const loadout = Loadout(equipment: {}, skills: {});

      // act
      final level = loadout.levelOf(SkillId.arms);

      // assert
      expect(level, 0);
    });
  });
}
