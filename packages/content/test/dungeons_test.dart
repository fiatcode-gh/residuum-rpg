import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const List<int> _sweptSeeds = [1, 5, 77, 909, 4242, 123456, 1755800000000];
const List<int> _sweptVisits = [0, 1, 2, 7];
const List<int> _cryptDepths = [1, 2, 3, 4, 5];

/// A mid-progression hero, for the tests that need a door walked through.
Profile _hero({int worldSeed = 909}) => newProfile(worldSeed: worldSeed);

/// How deep the delve the tests below walk goes.
int _rolled(ThemedDungeon dungeon, {int worldSeed = 909, int visit = 1}) =>
    delveDepth(dungeon.node, worldSeed, visit);

/// The depths that delve actually has, one to its rolled bottom.
List<int> _depthsOf(ThemedDungeon dungeon, {int worldSeed = 909}) => [
  for (var depth = 1; depth <= _rolled(dungeon, worldSeed: worldSeed); depth++)
    depth,
];

/// Every depth the dungeon has a table for, whatever any one delve rolls.
List<int> _tabledDepthsOf(ThemedDungeon dungeon) => [
  for (var depth = 1; depth <= dungeon.deepestDelve; depth++) depth,
];

/// Every floor seed one dungeon can produce over the standing sweep.
Set<int> _streamOf(NodeId node, int worldSeed) {
  final salted = node == cryptNode ? worldSeed : worldSeed ^ dungeonSalt(node);
  final themed = themedDungeonAt(node);
  final lowest = themed == null ? deepestDepth : themed.deepestDelve;
  return {
    for (var depth = 1; depth <= lowest; depth++)
      for (var visit = 0; visit < 2000; visit++)
        floorSeed(salted, depth, visit),
  };
}

Floor _floorOf(ThemedDungeon dungeon, int depth, {int worldSeed = 909}) =>
    themedFloor(
      dungeon,
      depth,
      worldSeed: worldSeed,
      visit: 1,
      deepest: _rolled(dungeon, worldSeed: worldSeed),
    );

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
      const depths = _cryptDepths;

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

  group('how deep a delve goes', () {
    test('is the same depth every time for one world, dungeon and visit', () {
      // act
      final once = delveDepth(seaCave, 4242, 3);
      final twice = delveDepth(seaCave, 4242, 3);

      // assert
      expect(once, twice);
    });

    test("stays inside the dungeon's own band over the standing sweep", () {
      // act
      final outside = <String>[];
      for (final dungeon in themedDungeons) {
        for (final worldSeed in _sweptSeeds) {
          for (var visit = 0; visit < 2000; visit++) {
            final rolled = delveDepth(dungeon.node, worldSeed, visit);
            if (rolled < dungeon.shallowestDelve ||
                rolled > dungeon.deepestDelve) {
              outside.add('${dungeon.node.value} $worldSeed/$visit: $rolled');
            }
          }
        }
      }

      // assert
      expect(outside, isEmpty);
    });

    test('reaches every depth in its band within a handful of visits', () {
      // act
      final reached = {
        for (final dungeon in themedDungeons)
          dungeon.node.value: {
            for (var visit = 0; visit < 200; visit++)
              delveDepth(dungeon.node, 909, visit),
          },
      };

      // assert
      expect(reached['sea-cave'], {4, 5, 6});
      expect(reached['ruined-keep'], {5, 6, 7});
    });

    test('is not the same depth on every visit', () {
      // act
      final rolled = {
        for (var visit = 1; visit <= 40; visit++)
          delveDepth(ruinedKeep, 909, visit),
      };

      // assert
      expect(rolled, hasLength(greaterThan(1)));
    });

    test('is spread evenly over its band, so no depth is the usual one', () {
      // arrange
      const draws = 3000;

      // assert
      for (final dungeon in themedDungeons) {
        final counted = <int, int>{};
        for (var visit = 0; visit < draws; visit++) {
          final rolled = delveDepth(dungeon.node, 4242, visit);
          counted[rolled] = (counted[rolled] ?? 0) + 1;
        }
        expect(counted, hasLength(3), reason: dungeon.node.value);
        for (final entry in counted.entries) {
          expect(
            entry.value,
            closeTo(draws / 3, draws / 30),
            reason: '${dungeon.node.value} depth ${entry.key}',
          );
        }
      }
    });

    test("is the crypt's fixed five, on every world and every visit", () {
      // assert
      for (final worldSeed in _sweptSeeds) {
        for (var visit = 0; visit < 200; visit++) {
          expect(
            delveDepth(cryptNode, worldSeed, visit),
            deepestDepth,
            reason: '$worldSeed/$visit',
          );
        }
      }
    });

    test('refuses a place with no dungeon under it', () {
      // act
      void act() => delveDepth(stonebridge, 909, 1);

      // assert
      expect(act, throwsArgumentError);
    });

    test('never draws off a stream a floor or a road draws off', () {
      // arrange
      final collisions = <String>[];

      // act
      for (final worldSeed in _sweptSeeds) {
        for (final dungeon in themedDungeons) {
          final salted = worldSeed ^ dungeonSalt(dungeon.node);
          final rolls = {
            for (var visit = 0; visit < 2000; visit++)
              floorSeed(salted, depthSlot, visit),
          };
          final floors = {
            for (var depth = 1; depth <= dungeon.deepestDelve; depth++)
              for (var visit = 0; visit < 2000; visit++)
                floorSeed(salted, depth, visit),
          };
          final roads = {
            for (var day = 0; day < 2000; day++) ...[
              ambushGroundSeed(worldSeed, day),
              ambushFightSeed(worldSeed, day),
            ],
          };
          final shared = rolls
              .intersection(floors)
              .union(rolls.intersection(roads));
          if (shared.isNotEmpty) {
            collisions.add(
              'world $worldSeed ${dungeon.node.value}: ${shared.length}',
            );
          }
        }
      }

      // assert
      expect(collisions, isEmpty);
    });

    test('is mixed at a slot no depth and no other purpose can be', () {
      // assert
      expect(depthSlot, greaterThan(theRuinedKeep.deepestDelve));
      expect(depthSlot, isNot(roadDepth));
    });
  });

  group('the delve a door opens', () {
    test('agrees with the roll about where its bottom is', () {
      // arrange
      const worldSeed = 4242;

      // act
      final disagreements = <String>[];
      for (final dungeon in themedDungeons) {
        final run = startDungeonRunAt(
          dungeon.node,
          _hero(worldSeed: worldSeed),
        );
        final rolled = delveDepth(dungeon.node, worldSeed, run.visit);
        if (run.deepest != rolled) {
          disagreements.add(
            '${dungeon.node.value}: state ${run.deepest} vs roll $rolled',
          );
        }
        for (var depth = 1; depth <= rolled; depth++) {
          final floor = run.buildFloor(depth);
          final wantsStairs = depth < rolled;
          if ((floor.stairsDown != null) != wantsStairs) {
            disagreements.add(
              '${dungeon.node.value} depth $depth of $rolled: stairs '
              '${floor.stairsDown}',
            );
          }
          final bosses = floor.monsters
              .where((monster) => monster.id == 'boss-${dungeon.node.value}')
              .length;
          if (bosses != (depth == rolled ? 1 : 0)) {
            disagreements.add(
              '${dungeon.node.value} depth $depth of $rolled: $bosses bosses',
            );
          }
        }
      }

      // assert
      expect(disagreements, isEmpty);
    });

    test("leaves the crypt's five alone on every path", () {
      // act
      final run = startDungeonRunAt(cryptNode, _hero(worldSeed: 4242));

      // assert
      expect(run.deepest, deepestDepth);
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
      final first = themedFloor(
        theSeaCave,
        2,
        worldSeed: 909,
        visit: 1,
        deepest: delveDepth(seaCave, 909, 1),
      );
      final second = themedFloor(
        theSeaCave,
        2,
        worldSeed: 909,
        visit: 2,
        deepest: delveDepth(seaCave, 909, 2),
      );

      // assert
      expect(first.map.toAscii(), isNot(second.map.toAscii()));
    });

    test('puts its monsters on distinct walkable tiles at every depth', () {
      // act
      final floors = [
        for (final dungeon in themedDungeons)
          for (final depth in _depthsOf(dungeon)) _floorOf(dungeon, depth),
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
          for (final depth in _depthsOf(dungeon)) _floorOf(dungeon, depth),
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
        for (final depth in _depthsOf(dungeon)) {
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
        for (final depth in _depthsOf(
          dungeon,
        ).where((depth) => depth < _rolled(dungeon))) {
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
        for (final depth in _depthsOf(dungeon)) {
          expect(
            _floorOf(dungeon, depth).stairsDown,
            depth == _rolled(dungeon) ? isNull : isNotNull,
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
        final bottom = _floorOf(dungeon, _rolled(dungeon));
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
        for (final depth in _depthsOf(
          dungeon,
        ).where((depth) => depth < _rolled(dungeon))) {
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

    test('is crowned once, on the rolled bottom and on no other floor', () {
      // arrange
      const worldSeed = 4242;

      // act
      final crowned = <String>[];
      for (final dungeon in themedDungeons) {
        for (var visit = 1; visit <= 12; visit++) {
          final deepest = delveDepth(dungeon.node, worldSeed, visit);
          for (var depth = 1; depth <= deepest; depth++) {
            final floor = themedFloor(
              dungeon,
              depth,
              worldSeed: worldSeed,
              visit: visit,
              deepest: deepest,
            );
            final bosses = floor.monsters
                .where((monster) => monster.id == 'boss-${dungeon.node.value}')
                .length;
            final trophies = floor.groundItems.values
                .expand((lying) => lying)
                .where((item) => item.id == 'trophy-${dungeon.node.value}')
                .length;
            final wanted = depth == deepest ? 1 : 0;
            if (bosses != wanted || trophies != wanted) {
              crowned.add(
                '${dungeon.node.value} visit $visit depth $depth of $deepest: '
                '$bosses bosses, $trophies trophies',
              );
            }
          }
        }
      }

      // assert
      expect(crowned, isEmpty);
    });

    test('is in no spawn table at any depth, because it is placed', () {
      // assert
      for (final dungeon in themedDungeons) {
        for (final depth in _tabledDepthsOf(dungeon)) {
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
      final bottom = _rolled(theSeaCave);
      final table = dungeonSpawnTableFor(theSeaCave.spawnTables, bottom);

      // act
      final floor = _floorOf(theSeaCave, bottom);

      // assert
      expect(
        floor.monsters,
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
            final deepest = delveDepth(dungeon.node, worldSeed, visit);
            final bottom = themedFloor(
              dungeon,
              deepest,
              worldSeed: worldSeed,
              visit: visit,
              deepest: deepest,
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
          final deepest = delveDepth(dungeon.node, worldSeed, 1);
          final bottom = themedFloor(
            dungeon,
            deepest,
            worldSeed: worldSeed,
            visit: 1,
            deepest: deepest,
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
        for (final depth in _depthsOf(
          dungeon,
        ).where((depth) => depth < _rolled(dungeon))) {
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
      final bottom = _rolled(theSeaCave);
      final drops = dungeonDropTableFor(theSeaCave.dropTables, bottom);
      final seed = floorSeed(
        worldSeed ^ dungeonSalt(theSeaCave.node),
        bottom,
        1,
      );
      final rng = Rng(seed);
      final count = dungeonSpawnTableFor(
        theSeaCave.spawnTables,
        bottom,
      ).rollCount(rng);
      final itemCount = rollFloorItemCount(drops, rng);

      // act — the same generated floor the bottom asks for, and the one it
      // would have asked for without a trophy to place
      final withTrophy = generateFloor(
        seed,
        bottom,
        monsterCount: count,
        itemCount: itemCount + 1,
        deepest: bottom,
      );
      final without = generateFloor(
        seed,
        bottom,
        monsterCount: count,
        itemCount: itemCount,
        deepest: bottom,
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
