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

const _room = '''
#####
#...#
#...#
#####''';

void main() {
  group('GameState loot fields', () {
    test('a fresh crawl carries no loot and every skill untrained', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final loadout = game.loadout;

      // assert
      expect(game.inventory, isEmpty);
      expect(game.groundItems, isEmpty);
      expect(game.equipment, isEmpty);
      expect(loadout.skills, untrainedSkills);
      expect(game.nextDropNumber, 1);
    });

    test('reads the items lying on a tile, newest last', () {
      // arrange
      const first = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);
      const second = Item(id: 'drop-2', base: _sword, rarity: Rarity.fine);
      final game = crawl(
        ascii: _room,
        heroAt: const Position(2, 2),
        groundItems: {
          Position(1, 1): [first, second],
        },
      );

      // act
      final here = game.itemsAt(const Position(1, 1));

      // assert
      expect(here, [first, second]);
      expect(game.itemsAt(const Position(2, 2)), isEmpty);
    });

    test('the loot stream is a different generator from the combat stream', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final same = identical(game.rng, game.lootRng);

      // assert
      expect(same, isFalse);
    });

    test('copyWith carries every loot field it was not given', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);
      final game = crawl(
        ascii: _room,
        heroAt: const Position(2, 2),
        inventory: const [item],
        equipment: const {EquipSlot.mainHand: item},
        skills: const {SkillId.arms: SkillState(level: 3)},
        groundItems: {
          Position(1, 1): [item],
        },
      );

      // act
      final after = game.copyWith(depth: 2);

      // assert
      expect(after.inventory, game.inventory);
      expect(after.equipment, game.equipment);
      expect(after.skills, game.skills);
      expect(after.groundItems, game.groundItems);
      expect(after.dropTables, game.dropTables);
      expect(after.nextDropNumber, game.nextDropNumber);
      expect(identical(after.lootRng, game.lootRng), isTrue);
    });

    test('copyWith replaces the loot fields it is given', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final after = game.copyWith(
        inventory: const [item],
        equipment: const {EquipSlot.mainHand: item},
        skills: const {SkillId.might: SkillState(level: 1)},
        groundItems: {
          Position(1, 1): [item],
        },
        nextDropNumber: 4,
      );

      // assert
      expect(after.inventory, [item]);
      expect(after.equipment[EquipSlot.mainHand], item);
      expect(after.skills[SkillId.might], const SkillState(level: 1));
      expect(after.itemsAt(const Position(1, 1)), [item]);
      expect(after.nextDropNumber, 4);
    });
  });

  group('Actor.dropChance', () {
    test('defaults to nothing, so the hero never drops itself', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final chance = game.hero.dropChance;

      // assert
      expect(chance, 0);
    });

    test('survives copyWith', () {
      // arrange
      const monster = Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: Position(1, 1),
        hp: 10,
        maxHp: 10,
        attackMin: 2,
        attackMax: 4,
        speed: 10,
        energy: actThreshold,
        dropChance: 40,
      );

      // act
      final after = monster.copyWith(hp: 3);

      // assert
      expect(after.dropChance, 40);
    });
  });

  group('loot events', () {
    test('are value objects', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);
      const pairs = <(GameEvent, GameEvent)>[
        (ItemPickedUp(item: item), ItemPickedUp(item: item)),
        (InventoryFull(), InventoryFull()),
        (
          ItemEquipped(item: item, slot: EquipSlot.mainHand),
          ItemEquipped(item: item, slot: EquipSlot.mainHand),
        ),
        (
          ItemUnequipped(item: item, slot: EquipSlot.mainHand),
          ItemUnequipped(item: item, slot: EquipSlot.mainHand),
        ),
        (
          ActionRefused(reason: 'both hands are full'),
          ActionRefused(reason: 'both hands are full'),
        ),
        (
          PotionDrunk(item: item, healed: 5),
          PotionDrunk(item: item, healed: 5),
        ),
        (
          AttackDodged(attackerId: 'ghoul-1'),
          AttackDodged(attackerId: 'ghoul-1'),
        ),
        (
          SkillLevelledUp(skill: SkillId.arms, level: 2),
          SkillLevelledUp(skill: SkillId.arms, level: 2),
        ),
        (
          ItemDropped(item: item, at: Position(1, 1)),
          ItemDropped(item: item, at: Position(1, 1)),
        ),
      ];

      // act
      final equal = [for (final (one, other) in pairs) one == other];

      // assert
      expect(equal, everyElement(isTrue));
    });

    test('events with different fields are not equal', () {
      // arrange
      const one = SkillLevelledUp(skill: SkillId.arms, level: 2);
      const other = SkillLevelledUp(skill: SkillId.arms, level: 3);

      // act
      final same = one == other;

      // assert
      expect(same, isFalse);
    });
  });
}
