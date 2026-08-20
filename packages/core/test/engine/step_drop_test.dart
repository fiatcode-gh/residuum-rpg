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

const _hauberk = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 3,
  heavy: true,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _weaponAffixes = [
  Affix(id: 'keen', affixName: 'Keen', isPrefix: true, attackMax: 2),
  Affix(id: 'vicious', affixName: 'Vicious', isPrefix: true, attackMin: 2),
  Affix(id: 'of-embers', affixName: 'of Embers', isPrefix: false, attackMin: 1),
  Affix(id: 'of-fury', affixName: 'of Fury', isPrefix: false, speed: 1),
];

const _armourAffixes = [
  Affix(id: 'sturdy', affixName: 'Sturdy', isPrefix: true, armor: 1),
  Affix(id: 'reinforced', affixName: 'Reinforced', isPrefix: true, armor: 2),
  Affix(id: 'of-vigour', affixName: 'of Vigour', isPrefix: false, maxHp: 4),
  Affix(
    id: 'of-swiftness',
    affixName: 'of Swiftness',
    isPrefix: false,
    speed: 2,
  ),
];

const _table = DropTable(
  items: [Weighted(_sword, 3), Weighted(_hauberk, 3), Weighted(_potion, 4)],
  rarities: [
    Weighted(Rarity.common, 5),
    Weighted(Rarity.fine, 3),
    Weighted(Rarity.rare, 2),
  ],
  weaponAffixes: _weaponAffixes,
  armourAffixes: _armourAffixes,
  minFloorItems: 2,
  maxFloorItems: 4,
);

const _tables = {1: _table};

/// A crawl where the hero one-shots a monster standing to its east.
GameState _killable({
  int dropChance = 100,
  int lootSeed = 2,
  Map<int, DropTable> tables = _tables,
  int nextDropNumber = 1,
}) => crawl(
  ascii: _hall,
  heroAt: const Position(1, 1),
  heroAttack: 50,
  monsters: [
    ghoul('ghoul-1', const Position(2, 1), hp: 1, dropChance: dropChance),
  ],
  lootSeed: lootSeed,
  dropTables: tables,
  nextDropNumber: nextDropNumber,
);

void main() {
  group('a kill spills loot', () {
    test('a certain drop lands on the tile the monster died on', () {
      // arrange
      final game = _killable();

      // act
      final (after, events) = step(game, const MoveAction(Direction.east));

      // assert
      final dropped = events.whereType<ItemDropped>().single;
      expect(dropped.at, const Position(2, 1));
      expect(after.itemsAt(const Position(2, 1)), [dropped.item]);
    });

    test('a creature that never drops leaves nothing', () {
      // arrange
      final game = _killable(dropChance: 0);

      // act
      final (after, events) = step(game, const MoveAction(Direction.east));

      // assert
      expect(events.whereType<ItemDropped>(), isEmpty);
      expect(after.groundItems, isEmpty);
    });

    test('no table for the depth means no drop and no crash', () {
      // arrange
      final game = _killable(tables: const {});

      // act
      final (after, events) = step(game, const MoveAction(Direction.east));

      // assert
      expect(events, contains(const ActorDied(actorId: 'ghoul-1')));
      expect(events.whereType<ItemDropped>(), isEmpty);
      expect(after.groundItems, isEmpty);
    });

    test('drop ids run in sequence, so two kills never collide', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        heroAttack: 50,
        monsters: [
          ghoul('ghoul-1', const Position(2, 1), hp: 1, dropChance: 100),
          ghoul('ghoul-2', const Position(1, 2), hp: 1, dropChance: 100),
        ],
        dropTables: _tables,
      );

      // act
      final (first, oneEvents) = step(game, const MoveAction(Direction.east));
      final (second, twoEvents) = step(
        first,
        const MoveAction(Direction.south),
      );

      // assert
      expect(oneEvents.whereType<ItemDropped>().single.item.id, 'drop-1');
      expect(twoEvents.whereType<ItemDropped>().single.item.id, 'drop-2');
      expect(second.nextDropNumber, 3);
    });

    test('a wounded but living monster spills nothing', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        heroAttack: 1,
        monsters: [
          ghoul('ghoul-1', const Position(2, 1), hp: 200, dropChance: 100),
        ],
        dropTables: _tables,
      );

      // act
      final (after, events) = step(game, const MoveAction(Direction.east));

      // assert
      expect(events.whereType<ItemDropped>(), isEmpty);
      expect(after.nextDropNumber, 1);
    });
  });

  group('the loot stream is independent of the combat stream', () {
    test('the same kill on the same loot seed drops the same item', () {
      // arrange
      GameState fresh() => _killable();

      // act
      final (_, one) = step(fresh(), const MoveAction(Direction.east));
      final (_, other) = step(fresh(), const MoveAction(Direction.east));

      // assert
      expect(
        one.whereType<ItemDropped>().single.item,
        other.whereType<ItemDropped>().single.item,
      );
    });

    test('a different combat seed cannot change what dropped', () {
      // arrange — the same loot seed, two wildly different combat streams
      GameState fresh(int combatSeed) => crawl(
        ascii: _hall,
        heroAt: const Position(1, 1),
        heroAttack: 50,
        monsters: [
          ghoul('ghoul-1', const Position(2, 1), hp: 1, dropChance: 100),
        ],
        seed: combatSeed,
        lootSeed: 2,
        dropTables: _tables,
      );

      // act
      final drops = [
        for (final combatSeed in [1, 2, 3, 17, 99, 12345])
          step(
            fresh(combatSeed),
            const MoveAction(Direction.east),
          ).$2.whereType<ItemDropped>().single.item,
      ];

      // assert
      expect(
        drops.map((item) => (item.base.id, item.rarity, item.affixes)).toSet(),
        hasLength(1),
      );
    });

    test('fighting first cannot reshuffle a later kill\'s drop', () {
      // arrange — one crawl swings at a wall for a while before the kill, the
      // other walks straight to it. Same loot seed: same spoils.
      GameState fresh() => crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        heroHp: 10000,
        heroAttack: 50,
        monsters: [
          ghoul('ghoul-1', const Position(3, 1), hp: 1, dropChance: 100),
          ghoul('ghoul-2', const Position(2, 2), hp: 400, dropChance: 100),
        ],
        lootSeed: 2,
        dropTables: _tables,
      );

      Item spoilsAfterBrawling(int swings) {
        var game = fresh();
        for (var swing = 0; swing < swings; swing++) {
          final (after, _) = step(game, const MoveAction(Direction.south));
          game = after;
        }
        final (_, events) = step(game, const MoveAction(Direction.east));
        return events.whereType<ItemDropped>().single.item;
      }

      // act
      final straightAway = spoilsAfterBrawling(0);
      final afterAFight = spoilsAfterBrawling(6);

      // assert
      expect(afterAFight, straightAway);
    });
  });

  group('descending', () {
    test('leaves the floor\'s litter behind and takes up the new floor\'s', () {
      // arrange
      const below = Item(id: 'floor-2-1', base: _sword, rarity: Rarity.common);
      Floor deeper(int depth) => Floor(
        map: FloorMap.parse(_hall),
        heroSpawn: const Position(1, 1),
        monsters: const [],
        stairsDown: const Position(4, 2),
        groundItems: {
          const Position(3, 2): [below],
        },
      );
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 2),
        stairsDown: const Position(2, 2),
        buildFloor: deeper,
        groundItems: {
          const Position(1, 1): [
            const Item(id: 'floor-1-1', base: _potion, rarity: Rarity.common),
          ],
        },
      );

      // act
      final (after, _) = step(game, const DescendAction());

      // assert
      expect(after.depth, 2);
      expect(after.itemsAt(const Position(3, 2)), [below]);
      expect(after.itemsAt(const Position(1, 1)), isEmpty);
    });

    test('carried and worn gear comes down the stairs', () {
      // arrange
      const carried = Item(id: 'kit-1', base: _potion, rarity: Rarity.common);
      const worn = Item(id: 'kit-2', base: _sword, rarity: Rarity.common);
      Floor deeper(int depth) => Floor(
        map: FloorMap.parse(_hall),
        heroSpawn: const Position(1, 1),
        monsters: const [],
        stairsDown: const Position(4, 2),
      );
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 2),
        stairsDown: const Position(2, 2),
        buildFloor: deeper,
        inventory: const [carried],
        equipment: const {EquipSlot.mainHand: worn},
        skills: const {SkillId.arms: SkillState(level: 4)},
      );

      // act
      final (after, _) = step(game, const DescendAction());

      // assert
      expect(after.inventory, [carried]);
      expect(after.equipment[EquipSlot.mainHand], worn);
      expect(after.skills[SkillId.arms], const SkillState(level: 4));
    });
  });
}
