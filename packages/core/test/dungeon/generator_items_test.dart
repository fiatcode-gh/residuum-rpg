import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('generateFloor item spawns', () {
    test('places exactly the number of items asked for', () {
      // arrange
      const wanted = 4;

      // act
      final floor = generateFloor(
        floorSeed(1, 1, 0),
        1,
        monsterCount: 3,
        itemCount: wanted,
      );

      // assert
      expect(floor.itemSpawns, hasLength(wanted));
    });

    test('places none when none are asked for', () {
      // arrange
      const wanted = 0;

      // act
      final floor = generateFloor(
        floorSeed(1, 1, 0),
        1,
        monsterCount: 3,
        itemCount: wanted,
      );

      // assert
      expect(floor.itemSpawns, isEmpty);
    });

    test('every item lies on distinct walkable ground', () {
      // arrange
      final floors = [
        for (var depth = 1; depth <= deepestDepth; depth++)
          generateFloor(
            floorSeed(9, depth, 0),
            depth,
            monsterCount: 3,
            itemCount: 4,
          ),
      ];

      // act
      final problems = <String>[];
      for (final floor in floors) {
        if (floor.itemSpawns.toSet().length != floor.itemSpawns.length) {
          problems.add('two items share a tile');
        }
        for (final spawn in floor.itemSpawns) {
          if (!floor.map.isWalkable(spawn))
            problems.add('$spawn is not walkable');
          if (spawn == floor.heroSpawn)
            problems.add('$spawn is under the hero');
          if (spawn == floor.stairsDown)
            problems.add('$spawn is on the stairs');
        }
      }

      // assert
      expect(problems, isEmpty);
    });

    test('an item may be in sight from the arrival tile, unlike a monster', () {
      // arrange — over a spread of seeds, at least one floor greets the hero
      // with something it can see: loot in view is an invitation, not an ambush
      final seeds = [for (var seed = 1; seed <= 30; seed++) seed];

      // act
      final anyVisible = seeds.any((seed) {
        final floor = generateFloor(
          floorSeed(seed, 1, 0),
          1,
          monsterCount: 3,
          itemCount: 4,
        );
        final inSight = computeFov(floor.map, floor.heroSpawn, fovRadius);
        return floor.itemSpawns.any(inSight.contains);
      });

      // assert
      expect(anyVisible, isTrue);
    });

    test('the same seed places the same items', () {
      // arrange
      final seed = floorSeed(7, 3, 0);

      // act
      final one = generateFloor(seed, 3, monsterCount: 5, itemCount: 3);
      final other = generateFloor(seed, 3, monsterCount: 5, itemCount: 3);

      // assert
      expect(one.itemSpawns, other.itemSpawns);
    });

    test('item placement does not disturb the layout or the monsters', () {
      // arrange
      final seed = floorSeed(11, 2, 0);

      // act
      final withItems = generateFloor(seed, 2, monsterCount: 4, itemCount: 4);
      final withoutItems = generateFloor(
        seed,
        2,
        monsterCount: 4,
        itemCount: 0,
      );

      // assert — items are drawn after the monsters, so adding them cannot
      // reshuffle a floor a player already shared the seed for
      expect(withItems.map.toAscii(), withoutItems.map.toAscii());
      expect(withItems.monsterSpawns, withoutItems.monsterSpawns);
      expect(withItems.heroSpawn, withoutItems.heroSpawn);
    });
  });
}
