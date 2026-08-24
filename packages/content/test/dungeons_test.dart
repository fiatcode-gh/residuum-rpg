import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const List<int> _sweptSeeds = [1, 5, 77, 909, 4242, 123456, 1755800000000];
const List<int> _sweptVisits = [0, 1, 2, 7];
const List<int> _allDepths = [1, 2, 3, 4, 5];

/// A mid-progression hero, for the tests that need a door walked through.
Profile _hero({int worldSeed = 909}) => newProfile(worldSeed: worldSeed);

/// Every floor seed one dungeon can produce over the standing sweep.
Set<int> _streamOf(NodeId node, int worldSeed) {
  final salted = node == cryptNode ? worldSeed : worldSeed ^ dungeonSalt(node);
  return {
    for (var depth = 1; depth <= deepestDepth; depth++)
      for (var visit = 0; visit < 2000; visit++)
        floorSeed(salted, depth, visit),
  };
}

Floor _floorOf(ThemedDungeon dungeon, int depth, {int worldSeed = 909}) =>
    themedFloor(dungeon, depth, worldSeed: worldSeed, visit: 1);

void main() {
  group('the salt a dungeon is filed under', () {
    test('is a different number for every dungeon', () {
      // act
      final salts = {
        for (final node in [cryptNode, seaCave, ruinedKeep]) dungeonSalt(node),
      };

      // assert
      expect(salts, hasLength(3));
    });

    test('is not any of the salts the world already mixes with', () {
      // act
      final theirs = {lootStreamSalt, travelSalt, ambushSalt};

      // assert
      expect(theirs, isNot(contains(dungeonSalt(seaCave))));
      expect(theirs, isNot(contains(dungeonSalt(ruinedKeep))));
    });

    test('is read off the id text, so a new dungeon needs no second edit', () {
      // act
      final again = dungeonSalt(NodeId(seaCave.value));

      // assert
      expect(again, dungeonSalt(seaCave));
    });
  });

  group('dungeonFor', () {
    test('hands the crypt back exactly what residuumDungeon builds', () {
      // arrange
      const depths = _allDepths;

      // act
      final mismatches = <String>[];
      for (final worldSeed in _sweptSeeds) {
        for (final visit in _sweptVisits) {
          final through = dungeonFor(cryptNode, worldSeed)(visit);
          final direct = residuumDungeon(worldSeed)(visit);
          for (final depth in depths) {
            final one = through(depth);
            final other = direct(depth);
            if (one.map.toAscii() != other.map.toAscii() ||
                one.heroSpawn != other.heroSpawn ||
                one.stairsDown != other.stairsDown ||
                '${one.monsters.map((m) => '${m.id}@${m.position}')}' !=
                    '${other.monsters.map((m) => '${m.id}@${m.position}')}' ||
                '${one.groundItems}' != '${other.groundItems}') {
              mismatches.add('$worldSeed/$visit/$depth');
            }
          }
        }
      }

      // assert
      expect(mismatches, isEmpty);
    });

    test('lays the new dungeons out somewhere else entirely', () {
      // act
      final cave = _floorOf(theSeaCave, 1);
      final crypt = residuumDungeon(909)(1)(1);

      // assert
      expect(cave.map.toAscii(), isNot(crypt.map.toAscii()));
    });

    test('refuses a place with no dungeon under it', () {
      // act
      void act() => dungeonFor(stonebridge, 909);

      // assert
      expect(act, throwsArgumentError);
    });

    test('knows which nodes have a crawl under them', () {
      // assert
      expect(isDungeonNode(cryptNode), isTrue);
      expect(isDungeonNode(seaCave), isTrue);
      expect(isDungeonNode(ruinedKeep), isTrue);
      expect(isDungeonNode(stonebridge), isFalse);
      expect(isDungeonNode(northgate), isFalse);
    });
  });

  group('the three floor streams', () {
    test('never collide, over the standing sweep', () {
      // arrange
      final nodes = [cryptNode, seaCave, ruinedKeep];

      // act
      final collisions = <String>[];
      for (final worldSeed in _sweptSeeds) {
        final streams = {
          for (final node in nodes) node.value: _streamOf(node, worldSeed),
        };
        for (final one in streams.entries) {
          for (final other in streams.entries) {
            if (one.key == other.key) continue;
            final shared = one.value.intersection(other.value);
            if (shared.isNotEmpty) {
              collisions.add(
                'world $worldSeed: ${one.key} and ${other.key} share '
                '${shared.length}',
              );
            }
          }
        }
      }

      // assert
      expect(collisions, isEmpty);
    });

    test('give the two new dungeons different floors at one seed', () {
      // act
      final cave = _floorOf(theSeaCave, 3);
      final keep = _floorOf(theRuinedKeep, 3);

      // assert
      expect(cave.map.toAscii(), isNot(keep.map.toAscii()));
    });
  });

  group('a themed floor', () {
    test('is the same floor twice from one seed and visit', () {
      // act
      final once = _floorOf(theSeaCave, 4);
      final twice = _floorOf(theSeaCave, 4);

      // assert
      expect(once.map.toAscii(), twice.map.toAscii());
      expect(
        once.monsters.map((monster) => (monster.id, monster.position)),
        twice.monsters.map((monster) => (monster.id, monster.position)),
      );
      expect('${once.groundItems}', '${twice.groundItems}');
    });

    test('is a different floor on the next visit', () {
      // act
      final first = themedFloor(theSeaCave, 2, worldSeed: 909, visit: 1);
      final second = themedFloor(theSeaCave, 2, worldSeed: 909, visit: 2);

      // assert
      expect(first.map.toAscii(), isNot(second.map.toAscii()));
    });

    test('puts its monsters on distinct walkable tiles at every depth', () {
      // act
      final floors = [
        for (final dungeon in themedDungeons)
          for (final depth in _allDepths) _floorOf(dungeon, depth),
      ];

      // assert
      for (final floor in floors) {
        final places = floor.monsters.map((monster) => monster.position);
        expect(places.toSet(), hasLength(floor.monsters.length));
        expect(places.map(floor.map.isWalkable), everyElement(isTrue));
        expect(places, isNot(contains(floor.heroSpawn)));
      }
    });

    test('gives every monster on it an id of its own', () {
      // act
      final floors = [
        for (final dungeon in themedDungeons)
          for (final depth in _allDepths) _floorOf(dungeon, depth),
      ];

      // assert
      for (final floor in floors) {
        final ids = floor.monsters.map((monster) => monster.id).toList();
        expect(ids.toSet(), hasLength(ids.length));
      }
    });

    test('draws its count from that depth\'s own table', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final depth in _allDepths) {
          final table = dungeonSpawnTableFor(dungeon.spawnTables, depth);
          expect(
            _floorOf(dungeon, depth).monsters,
            hasLength(inInclusiveRange(table.minCount, table.maxCount)),
            reason: '${dungeon.node.value} depth $depth',
          );
        }
      }
    });

    test('stands nothing on it that is not in that depth\'s table', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final depth in [1, 2, 3, 4]) {
          final allowed = dungeonSpawnTableFor(
            dungeon.spawnTables,
            depth,
          ).creatures.map((creature) => creature.name).toSet();
          for (final monster in _floorOf(dungeon, depth).monsters) {
            expect(allowed, contains(monster.name), reason: monster.id);
          }
        }
      }
    });

    test('leaves the way down off the deepest floor and nowhere else', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final depth in _allDepths) {
          expect(
            _floorOf(dungeon, depth).stairsDown,
            depth == deepestDepth ? isNull : isNotNull,
            reason: '${dungeon.node.value} depth $depth',
          );
        }
      }
    });
  });

  group('the thing at the bottom', () {
    test('stands on the deepest floor of every themed dungeon', () {
      // assert
      for (final dungeon in themedDungeons) {
        final bottom = _floorOf(dungeon, deepestDepth);
        final bosses = bottom.monsters
            .where((monster) => monster.id == 'boss-${dungeon.node.value}')
            .toList();
        expect(bosses, hasLength(1), reason: dungeon.node.value);
        expect(bosses.single.name, dungeon.boss.name);
        expect(bosses.single.maxHp, dungeon.boss.hp);
        expect(bosses.single.pierce, dungeon.boss.pierce);
      }
    });

    test('stands on no floor above it', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final depth in [1, 2, 3, 4]) {
          final names = _floorOf(
            dungeon,
            depth,
          ).monsters.map((monster) => monster.name);
          expect(
            names,
            isNot(contains(dungeon.boss.name)),
            reason: '${dungeon.node.value} depth $depth',
          );
        }
      }
    });

    test('is in no spawn table at any depth, because it is placed', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final depth in _allDepths) {
          final rollable = dungeonSpawnTableFor(dungeon.spawnTables, depth);
          expect(
            rollable.creatures,
            isNot(contains(dungeon.boss)),
            reason: '${dungeon.node.value} depth $depth',
          );
        }
      }
    });

    test('never stands in the crypt', () {
      // act
      final bottom = buildFloor(deepestDepth, worldSeed: 909, visit: 1);

      // assert
      for (final dungeon in themedDungeons) {
        expect(
          bottom.monsters.map((monster) => monster.name),
          isNot(contains(dungeon.boss.name)),
        );
      }
    });

    test('replaces a rolled spawn rather than adding to the count', () {
      // arrange
      final table = dungeonSpawnTableFor(theSeaCave.spawnTables, deepestDepth);

      // act
      final bottom = _floorOf(theSeaCave, deepestDepth);

      // assert
      expect(
        bottom.monsters,
        hasLength(inInclusiveRange(table.minCount, table.maxCount)),
      );
    });
  });

  group('the trophy the boss is guarding', () {
    test('lies on the deepest floor, rare or better, every seed', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final worldSeed in _sweptSeeds) {
          for (final visit in _sweptVisits) {
            final bottom = themedFloor(
              dungeon,
              deepestDepth,
              worldSeed: worldSeed,
              visit: visit,
            );
            final trophies = [
              for (final lying in bottom.groundItems.values)
                for (final item in lying)
                  if (item.id == 'trophy-${dungeon.node.value}') item,
            ];
            expect(trophies, hasLength(1), reason: '$worldSeed/$visit');
            expect(
              trophies.single.rarity.index,
              greaterThanOrEqualTo(Rarity.rare.index),
              reason: '$worldSeed/$visit ${trophies.single.displayName}',
            );
          }
        }
      }
    });

    test('is never a potion, which the rules would force back to Common', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final worldSeed in _sweptSeeds) {
          final bottom = themedFloor(
            dungeon,
            deepestDepth,
            worldSeed: worldSeed,
            visit: 1,
          );
          final trophy = bottom.groundItems.values
              .expand((lying) => lying)
              .firstWhere((item) => item.id == 'trophy-${dungeon.node.value}');
          expect(trophy.base.isPotion, isFalse, reason: '$worldSeed');
        }
      }
    });

    test('lies on no floor above the bottom', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final depth in [1, 2, 3, 4]) {
          final ids = _floorOf(
            dungeon,
            depth,
          ).groundItems.values.expand((lying) => lying).map((item) => item.id);
          expect(ids, isNot(contains('trophy-${dungeon.node.value}')));
        }
      }
    });

    test('rides an extra spawn, so the litter under it does not move', () {
      // arrange
      const worldSeed = 909;
      final drops = dungeonDropTableFor(theSeaCave.dropTables, deepestDepth);
      final seed = floorSeed(
        worldSeed ^ dungeonSalt(theSeaCave.node),
        deepestDepth,
        1,
      );
      final rng = Rng(seed);
      final count = dungeonSpawnTableFor(
        theSeaCave.spawnTables,
        deepestDepth,
      ).rollCount(rng);
      final itemCount = rollFloorItemCount(drops, rng);

      // act — the same generated floor the bottom asks for, and the one it
      // would have asked for without a trophy to place
      final withTrophy = generateFloor(
        seed,
        deepestDepth,
        monsterCount: count,
        itemCount: itemCount + 1,
      );
      final without = generateFloor(
        seed,
        deepestDepth,
        monsterCount: count,
        itemCount: itemCount,
      );

      // assert
      expect(withTrophy.map.toAscii(), without.map.toAscii());
      expect(withTrophy.heroSpawn, without.heroSpawn);
      expect(withTrophy.monsterSpawns, without.monsterSpawns);
      expect(withTrophy.stairsDown, without.stairsDown);
      expect(withTrophy.itemSpawns.take(itemCount), without.itemSpawns);
      expect(withTrophy.itemSpawns, hasLength(itemCount + 1));
    });
  });

  group('the door into any dungeon', () {
    test('bumps the visit at every one of them', () {
      // arrange
      final profile = _hero();

      // act
      final runs = [
        for (final node in [cryptNode, seaCave, ruinedKeep])
          startDungeonRunAt(node, profile),
      ];

      // assert
      expect(runs.map((run) => run.visit), everyElement(profile.visit + 1));
    });

    test('carries the crypt in on the global tables and the plain salt', () {
      // arrange
      final profile = _hero(worldSeed: 77);

      // act
      final run = startDungeonRunAt(cryptNode, profile);

      // assert
      expect(run.dropTables, dropTables);
      expect(run.lootRng.state, Rng(77 ^ lootStreamSalt).state);
    });

    test('carries a themed dungeon in on its own tables and salt', () {
      // arrange
      final profile = _hero(worldSeed: 77);

      // act
      final run = startDungeonRunAt(seaCave, profile);

      // assert
      expect(run.dropTables, seaCaveDropTables);
      expect(
        run.lootRng.state,
        Rng(77 ^ lootStreamSalt ^ dungeonSalt(seaCave)).state,
      );
    });

    test('opens two dungeons of one world on different first floors', () {
      // arrange
      final profile = _hero();

      // act
      final cave = startDungeonRunAt(seaCave, profile);
      final keep = startDungeonRunAt(ruinedKeep, profile);
      final crypt = startDungeonRunAt(cryptNode, profile);

      // assert
      expect(cave.map.toAscii(), isNot(keep.map.toAscii()));
      expect(cave.map.toAscii(), isNot(crypt.map.toAscii()));
      expect(keep.map.toAscii(), isNot(crypt.map.toAscii()));
    });

    test('refuses a town', () {
      // act
      void act() => startDungeonRunAt(northgate, _hero());

      // assert
      expect(act, throwsArgumentError);
    });
  });
}
