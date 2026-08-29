import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _mail = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 4,
  heavy: true,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 6,
);

Item _item(String id, BaseItem base, {int temper = 0}) =>
    Item(id: id, base: base, rarity: Rarity.common).tempered(temper);

Profile _hero({
  List<Item> inventory = const [],
  Equipment equipment = const {},
  Map<MaterialId, int> materials = const {},
  int gold = 1000,
  int blacksmith = 100,
  int herbcraft = 0,
  int brewNumber = 1,
  int hp = 20,
}) => Profile(
  hero: hero(const Position(0, 0), hp: hp),
  worldSeed: 5,
  inventory: inventory,
  equipment: equipment,
  materials: materials,
  gold: gold,
  brewNumber: brewNumber,
  skills: {
    ...untrainedSkills,
    SkillId.blacksmith: SkillState(level: blacksmith),
    SkillId.herbcraft: SkillState(level: herbcraft),
  },
);

void main() {
  group('smeltOre', () {
    test('turns the ore into an ingot', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.ore: 2});

      // act
      final (after, refusal) = smeltOre(profile);

      // assert
      expect(refusal, isNull);
      expect(after.materials, const {MaterialId.ingot: 1});
    });

    test('spends exactly the smelt cost and leaves the rest', () {
      // arrange
      final profile = _hero(
        materials: const {MaterialId.ore: 5, MaterialId.herb: 3},
      );

      // act
      final (after, _) = smeltOre(profile);

      // assert
      expect(after.materials, const {
        MaterialId.ore: 3,
        MaterialId.herb: 3,
        MaterialId.ingot: 1,
      });
    });

    test('drops the ore entry when the last of it goes in', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.ore: 2});

      // act
      final (after, _) = smeltOre(profile);

      // assert - no zero entries, so a save's materials block is the size of
      // what the hero is actually carrying
      expect(after.materials.containsKey(MaterialId.ore), isFalse);
    });

    test('trains Blacksmith', () {
      // arrange
      final profile = _hero(
        materials: const {MaterialId.ore: 2},
        blacksmith: 0,
      );

      // act
      final (after, _) = smeltOre(profile);

      // assert
      expect(after.skills[SkillId.blacksmith], const SkillState(xp: 1));
    });

    test('costs no gold at all', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.ore: 2}, gold: 7);

      // act
      final (after, _) = smeltOre(profile);

      // assert - the hero is doing work on ore they carried out of the dark,
      // not buying anything from anyone
      expect(after.gold, 7);
    });

    test('refuses a hero short of ore, and changes nothing', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.ore: 1});

      // act
      final (after, refusal) = smeltOre(profile);

      // assert
      expect(refusal, const TownRefusal('that takes 2 ore'));
      expect(after, profile);
    });

    test('refuses a hero with no ore whatsoever', () {
      // arrange
      final profile = _hero();

      // act
      final (_, refusal) = smeltOre(profile);

      // assert
      expect(refusal, isNotNull);
    });
  });

  group('brewPotion', () {
    test('puts a Common healing potion in the pack', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.herb: 3});

      // act
      final (after, refusal) = brewPotion(profile, _potion);

      // assert
      expect(refusal, isNull);
      expect(after.inventory.single.base, _potion);
      expect(after.inventory.single.rarity, Rarity.common);
      expect(after.inventory.single.affixes, isEmpty);
    });

    test('spends the herbs', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.herb: 5});

      // act
      final (after, _) = brewPotion(profile, _potion);

      // assert
      expect(after.materials, const {MaterialId.herb: 2});
    });

    test('trains Herbcraft', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.herb: 3});

      // act
      final (after, _) = brewPotion(profile, _potion);

      // assert
      expect(after.skills[SkillId.herbcraft], const SkillState(xp: 1));
    });

    test('names the potion off the counter and bumps it', () {
      // arrange
      final profile = _hero(
        materials: const {MaterialId.herb: 3},
        brewNumber: 7,
      );

      // act
      final (after, _) = brewPotion(profile, _potion);

      // assert
      expect(after.inventory.single.id, 'brew-7');
      expect(after.brewNumber, 8);
    });

    test('two potions brewed in a row never share an id', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.herb: 6});

      // act
      final (once, _) = brewPotion(profile, _potion);
      final (twice, _) = brewPotion(once, _potion);

      // assert
      expect(twice.inventory.map((item) => item.id), ['brew-1', 'brew-2']);
    });

    test('an id is not reused after the potion is drunk', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.herb: 6});

      // act
      final (once, _) = brewPotion(profile, _potion);
      final drunk = once.copyWith(inventory: const []);
      final (twice, _) = brewPotion(drunk, _potion);

      // assert - the whole reason the counter is a field and not a derivation:
      // anything read off the pack would hand back a freed number
      expect(twice.inventory.single.id, 'brew-2');
    });

    test('refuses a hero short of herbs, and changes nothing', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.herb: 2});

      // act
      final (after, refusal) = brewPotion(profile, _potion);

      // assert
      expect(refusal, const TownRefusal('that takes 3 herbs'));
      expect(after, profile);
    });

    test('refuses a full pack in the merchant\'s exact words', () {
      // arrange
      final profile = _hero(
        materials: const {MaterialId.herb: 3},
        inventory: [
          for (var made = 0; made < inventoryCap; made++)
            _item('kit-$made', _potion),
        ],
      );

      // act
      final (after, refusal) = brewPotion(profile, _potion);

      // assert - one rule, one sentence: two wordings would teach the player
      // that the two screens have two different caps
      expect(refusal, const TownRefusal('you cannot carry any more'));
      expect(after, profile);
    });

    test('answers the herbs before the pack', () {
      // arrange
      final profile = _hero(
        inventory: [
          for (var made = 0; made < inventoryCap; made++)
            _item('kit-$made', _potion),
        ],
      );

      // act
      final (_, refusal) = brewPotion(profile, _potion);

      // assert
      expect(refusal, const TownRefusal('that takes 3 herbs'));
    });
  });

  group('temperItem on a carried piece', () {
    test('works it up one tier', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword)],
        materials: const {MaterialId.ingot: 1},
      );

      // act
      final (after, refusal) = temperItem(profile, 'drop-1');

      // assert
      expect(refusal, isNull);
      expect(after.inventory.single.temper, 1);
    });

    test('the damage moves with it', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword)],
        materials: const {MaterialId.ingot: 1},
      );

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.inventory.single.attackMin, 4);
      expect(after.inventory.single.attackMax, 6);
    });

    test('spends the tier\'s ingots and gold', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword)],
        materials: const {MaterialId.ingot: 4},
        gold: 100,
      );

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.materials, const {MaterialId.ingot: 3});
      expect(after.gold, 90);
    });

    test('the second tier costs more than the first', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword, temper: 1)],
        materials: const {MaterialId.ingot: 4},
        gold: 100,
      );

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.inventory.single.temper, 2);
      expect(after.materials, const {MaterialId.ingot: 2});
      expect(after.gold, 75);
    });

    test('trains Blacksmith', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword)],
        materials: const {MaterialId.ingot: 1},
        blacksmith: 0,
      );

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.skills[SkillId.blacksmith], const SkillState(xp: 1));
    });

    test('leaves every other carried item alone', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword), _item('kit-2', _potion)],
        materials: const {MaterialId.ingot: 1},
      );

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.inventory.map((item) => item.id), ['drop-1', 'kit-2']);
      expect(after.inventory.last.temper, 0);
    });

    test('stops at the ceiling and says so', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword, temper: maxTemper)],
        materials: const {MaterialId.ingot: 9},
      );

      // act
      final (after, refusal) = temperItem(profile, 'drop-1');

      // assert
      expect(refusal, const TownRefusal('that is worked as far as it goes'));
      expect(after, profile);
      expect(after.inventory.single.temper, maxTemper);
    });

    test('three tempers in a row reach the ceiling and no further', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword)],
        materials: const {MaterialId.ingot: 9},
      );

      // act
      var worked = profile;
      for (var tier = 0; tier < maxTemper + 1; tier++) {
        worked = temperItem(worked, 'drop-1').$1;
      }

      // assert - six ingots and eighty-five gold for the whole way up, and the
      // fourth attempt buys nothing
      expect(worked.inventory.single.temper, maxTemper);
      expect(worked.materials, const {MaterialId.ingot: 3});
      expect(worked.gold, 1000 - 85);
    });

    test('a refused temper spends nothing', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword)],
        materials: const {},
        gold: 100,
      );

      // act
      final (after, refusal) = temperItem(profile, 'drop-1');

      // assert
      expect(refusal, isNotNull);
      expect(after.gold, 100);
      expect(after.materials, isEmpty);
      expect(after.skills[SkillId.blacksmith]!.xp, 0);
    });

    test('refuses a potion without spending anything', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-2', _potion)],
        materials: const {MaterialId.ingot: 4},
      );

      // act
      final (after, refusal) = temperItem(profile, 'kit-2');

      // assert
      expect(refusal, const TownRefusal('only steel takes a temper'));
      expect(after, profile);
    });
  });

  group('temperItem on a worn piece', () {
    test('works the piece the hero has on', () {
      // arrange
      final profile = _hero(
        equipment: {EquipSlot.chest: _item('drop-1', _mail)},
        materials: const {MaterialId.ingot: 1},
      );

      // act
      final (after, refusal) = temperItem(profile, 'drop-1');

      // assert - the piece most worth working is usually the one they are
      // wearing, so the forge does not make them undress
      expect(refusal, isNull);
      expect(after.equipment[EquipSlot.chest]!.temper, 1);
      expect(after.equipment[EquipSlot.chest]!.armor, 5);
    });

    test('leaves the other slots alone', () {
      // arrange
      final profile = _hero(
        equipment: {
          EquipSlot.chest: _item('drop-1', _mail),
          EquipSlot.mainHand: _item('kit-1', _sword),
        },
        materials: const {MaterialId.ingot: 1},
      );

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.equipment[EquipSlot.mainHand]!.temper, 0);
      expect(after.equipment.keys, profile.equipment.keys);
    });

    test(
      'never moves the hit-point ceiling, because a tier is not hit points',
      () {
        // arrange
        final profile = _hero(
          equipment: {
            EquipSlot.chest: Item(
              id: 'drop-1',
              base: _mail,
              rarity: Rarity.fine,
              affixes: const [_vigour],
            ),
          },
          materials: const {MaterialId.ingot: 1},
          hp: 26,
        );

        // act
        final (after, _) = temperItem(profile, 'drop-1');

        // assert - the clamp is on the path for the invariant's sake, not because
        // today's arithmetic reaches it: a tier lands on armour and nowhere else
        expect(after.maxHp, profile.maxHp);
        expect(after.hero.hp, 26);
      },
    );
  });
}
