import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// What the shelf a hero walks up to is made of, in words a reader can check.
List<String> _shelf(int worldSeed, int visit, NodeId town) => [
  for (final item in merchantStock(worldSeed, visit, town))
    '${item.id}: ${item.displayName}',
];

void main() {
  group('the shelf a hero walks up to', () {
    /// **Re-pinned when each town started rolling its own stock.**
    ///
    /// This test was written against the shelf as it stood at `844376f`, before
    /// the town was folded into the seed, and it is recorded here rather than
    /// deleted so the change is a re-pin with a reason and not a drift nobody
    /// noticed. World 909 on its first visit used to hold:
    ///
    /// ```
    /// market-0-potion-1: Common Healing Potion
    /// market-0-potion-2: Common Healing Potion
    /// market-0-potion-3: Common Healing Potion
    /// market-0-gear-1: Common Leather Cap
    /// market-0-gear-2: Common Rusty Sword
    /// market-0-gear-3: Fine Sturdy Leather Boots
    /// market-0-gear-4: Common Mail Hauberk
    /// ```
    ///
    /// It moved because the seed gained a term and the ids gained the town.
    /// Nothing about how a shelf is rolled changed — same table, same weights,
    /// same number of draws — so this is the same shop on a world that now has
    /// two of them.
    test('world 909 at Stonebridge is the shelf that world rolls', () {
      // arrange
      const worldSeed = 909;

      // act
      final shelf = _shelf(worldSeed, 0, stonebridge);

      // assert
      expect(shelf, const [
        'market-stonebridge-0-potion-1: Common Healing Potion',
        'market-stonebridge-0-potion-2: Common Healing Potion',
        'market-stonebridge-0-potion-3: Common Healing Potion',
        'market-stonebridge-0-gear-1: Rare Sturdy Reinforced Leather Cap',
      ]);
    });

    test('the same world at Northgate is a different shop', () {
      // arrange
      const worldSeed = 909;

      // act
      final shelf = _shelf(worldSeed, 0, northgate);

      // assert
      expect(shelf, const [
        'market-northgate-0-potion-1: Common Healing Potion',
        'market-northgate-0-potion-2: Common Healing Potion',
        'market-northgate-0-potion-3: Common Healing Potion',
        'market-northgate-0-gear-1: Fine Maul of Fury',
      ]);
    });

    test('world 4 rolls its own shelf, and the same one every time', () {
      // arrange
      const worldSeed = 4;

      // act
      final shelf = _shelf(worldSeed, 0, stonebridge);

      // assert
      expect(shelf, const [
        'market-stonebridge-0-potion-1: Common Healing Potion',
        'market-stonebridge-0-potion-2: Common Healing Potion',
        'market-stonebridge-0-potion-3: Common Healing Potion',
        'market-stonebridge-0-gear-1: Common Leather Cap',
      ]);
    });

    test('a later visit turns the whole shelf over', () {
      // arrange
      const worldSeed = 9;

      // act
      final shelf = _shelf(worldSeed, 4, stonebridge);

      // assert
      expect(shelf, const [
        'market-stonebridge-4-potion-1: Common Healing Potion',
        'market-stonebridge-4-potion-2: Common Healing Potion',
        'market-stonebridge-4-potion-3: Common Healing Potion',
        'market-stonebridge-4-gear-1: Common Iron Gauntlets',
        'market-stonebridge-4-gear-2: Common Iron Gauntlets',
      ]);
    });
  });

  group('two towns are two shops', () {
    test('the same world and visit stock them differently', () {
      // arrange
      const worldSeed = 909;

      // act
      final here = merchantStock(worldSeed, 0, stonebridge);
      final there = merchantStock(worldSeed, 0, northgate);

      // assert
      expect(
        here.map((item) => item.displayName).toList(),
        isNot(there.map((item) => item.displayName).toList()),
      );
    });

    test('no stock id is ever on both shelves', () {
      // arrange
      final shared = <String>[];

      // act
      for (var visit = 0; visit < 40; visit++) {
        final here = merchantStock(
          909,
          visit,
          stonebridge,
        ).map((item) => item.id).toSet();
        final there = merchantStock(
          909,
          visit,
          northgate,
        ).map((item) => item.id).toSet();
        shared.addAll(here.intersection(there));
      }

      // assert
      expect(shared, isEmpty);
    });

    test('every town in the world gets a shop of its own', () {
      // arrange
      final towns = [
        for (final node in residuumWorld.nodes)
          if (node.kind == NodeKind.town) node.id,
      ];

      // act
      final shelves = {
        for (final town in towns)
          town: merchantStock(909, 0, town).map((item) => item.displayName),
      };

      // assert
      expect(towns, hasLength(2));
      expect(
        shelves[towns.first]!.toList(),
        isNot(shelves[towns.last]!.toList()),
      );
    });

    test('two towns rarely agree, over many worlds', () {
      // arrange
      var agreed = 0;

      // act
      for (var worldSeed = 1; worldSeed <= 100; worldSeed++) {
        final here = merchantStock(
          worldSeed,
          0,
          stonebridge,
        ).map((item) => item.displayName).toList();
        final there = merchantStock(
          worldSeed,
          0,
          northgate,
        ).map((item) => item.displayName).toList();
        if (here.toString() == there.toString()) agreed++;
      }

      // assert
      expect(agreed, lessThan(3));
    });
  });
}
