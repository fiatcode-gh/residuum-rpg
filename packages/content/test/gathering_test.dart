import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const List<int> _sweptSeeds = [1, 5, 77, 909, 4242, 123456];

/// Everything about a floor that existed before gathering did, as one string.
///
/// The terrain, the arrival tile, the way down, every creature and its tile, and
/// every littered tile and what lies on it. Nothing about nodes, deliberately:
/// this is the half of a floor the node pass must not be able to reach.
String _layoutOf(Floor floor) => [
  floor.map.toAscii(),
  '${floor.heroSpawn.x},${floor.heroSpawn.y}',
  '${floor.stairsDown?.x},${floor.stairsDown?.y}',
  for (final monster in floor.monsters)
    '${monster.id}@${monster.position.x},${monster.position.y}',
  for (final tile in floor.groundItems.keys.toList()..sort(byRowThenColumn))
    '${tile.x},${tile.y}:'
        '${floor.groundItems[tile]!.map((item) => item.id).join(",")}',
].join('|');

/// [_layoutOf] as one number, by the mix [floorSeed] uses.
///
/// Hand-rolled rather than `String.hashCode`, which the language does not
/// promise to keep across releases of the toolchain — a golden that could move
/// under a Dart upgrade is a golden that will one day be re-pinned instead of
/// investigated.
int _digest(Floor floor) {
  var hash = 0x811c9dc5;
  for (final unit in _layoutOf(floor).codeUnits) {
    hash = ((hash ^ (unit & 0x0fffffff)) & 0x0fffffff) * 0x01000193;
    hash &= 0x3fffffff;
  }
  return hash;
}

/// The digest of every floor of the crypt on two worlds, and of both themed
/// dungeons on one, **captured on the code that had no gathering in it at all**.
///
/// This is the load-bearing control of the whole unit. Nodes are placed after
/// the last existing draw, from a generator of their own, so not one of these
/// numbers may move — and the reason to pin them rather than to argue it is that
/// the argument was made once before, about drop tables, and was wrong.
const Map<String, int> _layoutsBeforeGathering = {
  'crypt 1 1': 635912583,
  'crypt 1 2': 1016437778,
  'crypt 1 3': 39520538,
  'crypt 1 4': 490748196,
  'crypt 1 5': 236594728,
  'crypt 909 1': 274595190,
  'crypt 909 2': 600797202,
  'crypt 909 3': 24071604,
  'crypt 909 4': 283613421,
  'crypt 909 5': 705801560,
  'sea-cave 909 1': 498183893,
  'sea-cave 909 2': 700749605,
  'sea-cave 909 3': 390509088,
  'sea-cave 909 4': 892938172,
  'ruined-keep 909 1': 798330516,
  'ruined-keep 909 2': 816479651,
  'ruined-keep 909 3': 807712208,
  'ruined-keep 909 4': 888934769,
  'ruined-keep 909 5': 399434599,
  'ruined-keep 909 6': 663931325,
  'ruined-keep 909 7': 443972664,
};

/// Where nine known floors put their nodes, kind by kind.
///
/// **The pin [gatherSalt] is load-bearing to.** Every other test here is about a
/// property — same seed twice, never on the stairs, inside the band — and a
/// property survives a changed salt. These do not: change the constant and every
/// one of these nine strings moves, which is what makes the salt something the
/// build has to mean rather than something it happens to have.
const Map<String, String> _pinnedNodes = {
  'crypt 909 1': '3,1:herbPatch|21,5:herbPatch|14,13:herbPatch',
  'crypt 909 2': '11,5:oreVein|12,13:oreVein|21,14:oreVein',
  'crypt 909 3': '9,3:oreVein|25,5:oreVein|4,8:herbPatch',
  'crypt 909 4': '13,4:oreVein|28,10:oreVein|26,15:oreVein',
  'crypt 909 5': '3,4:oreVein|10,4:herbPatch|17,8:herbPatch',
  'sea-cave 909 1': '7,4:herbPatch',
  'sea-cave 909 2': '21,11:oreVein|14,14:herbPatch|3,15:herbPatch',
  'ruined-keep 909 1': '21,14:oreVein',
  'ruined-keep 909 2': '11,4:herbPatch',
};

Floor _themed(ThemedDungeon dungeon, int depth, {int worldSeed = 909}) =>
    themedFloor(
      dungeon,
      depth,
      worldSeed: worldSeed,
      visit: 1,
      deepest: delveDepth(dungeon.node, worldSeed, 1),
    );

void main() {
  group('the layout the node pass must not reach', () {
    test('every pinned floor is byte for byte the floor it always was', () {
      // arrange
      final measured = <String, int>{};

      // act
      for (final worldSeed in [1, 909]) {
        for (var depth = 1; depth <= deepestDepth; depth++) {
          measured['crypt $worldSeed $depth'] = _digest(
            buildFloor(depth, worldSeed: worldSeed, visit: 1),
          );
        }
      }
      for (final dungeon in themedDungeons) {
        final deepest = delveDepth(dungeon.node, 909, 1);
        for (var depth = 1; depth <= deepest; depth++) {
          measured['${dungeon.node.value} 909 $depth'] = _digest(
            _themed(dungeon, depth),
          );
        }
      }

      // assert - the terrain, the arrival, the stairs, every creature and every
      // piece of litter, unmoved by gathering existing
      expect(measured, _layoutsBeforeGathering);
    });
  });

  group('where a floor puts its nodes', () {
    test('the same floor lays out the same nodes twice', () {
      // arrange
      const worldSeed = 909;

      // act
      final once = buildFloor(3, worldSeed: worldSeed, visit: 1).nodes;
      final again = buildFloor(3, worldSeed: worldSeed, visit: 1).nodes;

      // assert
      expect(again, once);
    });

    test('a different world lays out different nodes', () {
      // act
      final layouts = {
        for (final worldSeed in _sweptSeeds)
          _named(buildFloor(1, worldSeed: worldSeed, visit: 1).nodes),
      };

      // assert - six worlds, six answers; one shared answer would mean the
      // stream is not reading the world seed at all
      expect(layouts, hasLength(_sweptSeeds.length));
    });

    test('a different visit reshuffles them, as it reshuffles the floor', () {
      // act
      final layouts = {
        for (var visit = 1; visit <= 5; visit++)
          _named(buildFloor(1, worldSeed: 909, visit: visit).nodes),
      };

      // assert
      expect(layouts, hasLength(5));
    });

    test('a different salt lays out different nodes', () {
      // arrange
      final floor = buildFloor(1, worldSeed: 909, visit: 1);
      final seed = floorSeed(909, 1, 1);

      // act
      final elsewhere = gatherNodesOn(
        floor.map,
        floor.heroSpawn,
        seed ^ (gatherSalt + 1),
        cryptGathering,
      );

      // assert - the salt is what keeps the node stream off the layout stream,
      // so it has to be a number the answer depends on
      expect(elsewhere, isNot(floor.nodes));
    });

    test('nodes never sit on the stairs or on the arrival tile', () {
      // act
      final trespasses = <String>[];
      for (final worldSeed in _sweptSeeds) {
        for (var depth = 1; depth <= deepestDepth; depth++) {
          final floor = buildFloor(depth, worldSeed: worldSeed, visit: 1);
          for (final at in floor.nodes.keys) {
            if (at == floor.heroSpawn) {
              trespasses.add('$worldSeed:$depth spawn');
            }
            if (at == floor.stairsDown) {
              trespasses.add('$worldSeed:$depth stairs');
            }
          }
        }
      }

      // assert
      expect(trespasses, isEmpty);
    });

    test('a node never blocks: the tile under it stays plain floor', () {
      // act
      final wrong = <String>[];
      for (final worldSeed in _sweptSeeds) {
        for (var depth = 1; depth <= deepestDepth; depth++) {
          final floor = buildFloor(depth, worldSeed: worldSeed, visit: 1);
          for (final at in floor.nodes.keys) {
            if (floor.map.tileAt(at) != Tile.floor) {
              wrong.add('$worldSeed:$depth ${floor.map.tileAt(at).name}');
            }
          }
        }
      }

      // assert - a fifth Tile would have reddened every map-byte golden in the
      // repository; nodes are state over the terrain and never terrain
      expect(wrong, isEmpty);
    });

    test('a themed floor lays out nodes too, on its own stream', () {
      // act
      final cave = _themed(theSeaCave, 2).nodes;
      final keep = _themed(theRuinedKeep, 2).nodes;

      // assert
      expect(cave, isNotEmpty);
      expect(keep, isNotEmpty);
      expect(_named(cave), isNot(_named(keep)));
    });
  });

  group('how many nodes a floor gets', () {
    test('every count is inside the dungeon it was rolled for', () {
      // act
      final outside = <String>[];
      for (final worldSeed in _sweptSeeds) {
        for (var visit = 1; visit <= 20; visit++) {
          for (var depth = 1; depth <= deepestDepth; depth++) {
            final count = buildFloor(
              depth,
              worldSeed: worldSeed,
              visit: visit,
            ).nodes.length;
            if (count < cryptGathering.fewest || count > cryptGathering.most) {
              outside.add('crypt $worldSeed/$visit/$depth: $count');
            }
          }
        }
      }
      for (final dungeon in themedDungeons) {
        final band = gatherBandFor(dungeon.node);
        for (var depth = 1; depth <= dungeon.deepestDelve; depth++) {
          final count = themedFloor(
            dungeon,
            depth,
            worldSeed: 909,
            visit: 1,
            deepest: dungeon.deepestDelve,
          ).nodes.length;
          if (count < band.fewest || count > band.most) {
            outside.add('${dungeon.node.value} $depth: $count');
          }
        }
      }

      // assert
      expect(outside, isEmpty);
    });

    test('every floor has at least one, so looking is always worth it', () {
      // act
      final empty = <String>[];
      for (final worldSeed in _sweptSeeds) {
        for (var depth = 1; depth <= deepestDepth; depth++) {
          if (buildFloor(depth, worldSeed: worldSeed, visit: 1).nodes.isEmpty) {
            empty.add('$worldSeed:$depth');
          }
        }
      }

      // assert - a floor that can hold nothing teaches the player not to look,
      // and the band's floor of one is what stops that
      expect(empty, isEmpty);
    });

    test('the band is rolled uniformly over its whole width', () {
      // act
      final counts = <int>{};
      for (var visit = 1; visit <= 200; visit++) {
        counts.add(buildFloor(1, worldSeed: 909, visit: visit).nodes.length);
      }

      // assert
      expect(counts, {
        for (
          var count = cryptGathering.fewest;
          count <= cryptGathering.most;
          count++
        )
          count,
      });
    });
  });

  group('which kind of node a dungeon favours', () {
    test('the sea-cave is the greener of the two themed dungeons', () {
      // act
      final cave = gatherBandFor(theSeaCave.node).orePercent;
      final keep = gatherBandFor(theRuinedKeep.node).orePercent;

      // assert - kelp and anemones under the water, masonry and old iron in the
      // castle; the crypt sits between them and favours neither
      expect(cave, lessThan(cryptGathering.orePercent));
      expect(keep, greaterThan(cryptGathering.orePercent));
    });

    test('both kinds turn up in every dungeon', () {
      // act
      final kinds = <NodeId, Set<GatherKind>>{};
      for (var visit = 1; visit <= 40; visit++) {
        kinds
            .putIfAbsent(cryptNode, () => {})
            .addAll(buildFloor(1, worldSeed: 909, visit: visit).nodes.values);
        for (final dungeon in themedDungeons) {
          kinds
              .putIfAbsent(dungeon.node, () => {})
              .addAll(
                themedFloor(
                  dungeon,
                  1,
                  worldSeed: 909,
                  visit: visit,
                  deepest: dungeon.deepestDelve,
                ).nodes.values,
              );
        }
      }

      // assert - a lean is flavour; a dungeon with only one kind would make one
      // of the two skills untrainable there
      for (final entry in kinds.entries) {
        expect(entry.value, GatherKind.values.toSet(), reason: entry.key.value);
      }
    });
  });

  group('the salt the node stream is mixed with', () {
    test('is not any of the salts the world already mixes with', () {
      // arrange
      final theirs = {lootStreamSalt, travelSalt, ambushSalt, depthSlot};

      // assert
      expect(theirs, isNot(contains(gatherSalt)));
    });

    test('never collides with a floor stream of the same dungeon', () {
      // arrange
      final worlds = [1, 5, 909, 123456, 1755800000000, 2, 7, 99991];

      // act
      final collisions = <String>[];
      for (final worldSeed in worlds) {
        for (final node in [cryptNode, seaCave, ruinedKeep]) {
          final salted = node == cryptNode
              ? worldSeed
              : worldSeed ^ dungeonSalt(node);
          final floors = <int>{};
          final gathering = <int>{};
          for (var depth = 1; depth <= 7; depth++) {
            for (var visit = 0; visit < 2000; visit++) {
              floors.add(floorSeed(salted, depth, visit));
              gathering.add(floorSeed(salted, depth, visit) ^ gatherSalt);
            }
          }
          final shared = floors.intersection(gathering);
          if (shared.isNotEmpty) {
            collisions.add('${node.value} on $worldSeed: ${shared.length}');
          }
        }
      }

      // assert - the constant is load-bearing rather than decorative: two other
      // plausible values for it put seeds in both sets
      expect(collisions, isEmpty);
    });
  });

  group('the pinned node layouts', () {
    test('nine known floors grow their nodes where they always have', () {
      // arrange
      final measured = <String, String>{};

      // act
      for (var depth = 1; depth <= deepestDepth; depth++) {
        measured['crypt 909 $depth'] = _named(
          buildFloor(depth, worldSeed: 909, visit: 1).nodes,
        );
      }
      for (final dungeon in themedDungeons) {
        for (var depth = 1; depth <= 2; depth++) {
          measured['${dungeon.node.value} 909 $depth'] = _named(
            _themed(dungeon, depth).nodes,
          );
        }
      }

      // assert
      expect(measured, _pinnedNodes);
    });
  });
}

/// [nodes] as one comparable string, in a stated order.
String _named(Map<Position, GatherKind> nodes) => [
  for (final at in nodes.keys.toList()..sort(byRowThenColumn))
    '${at.x},${at.y}:${nodes[at]!.name}',
].join('|');
