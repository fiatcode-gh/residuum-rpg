import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// A hero at the start of everything, for the assembly tests.
Profile _fresh({int worldSeed = 909}) => newProfile(worldSeed: worldSeed);

void main() {
  group('the world the game ships', () {
    test('is two towns and three dungeons', () {
      // act
      final kinds = {
        for (final node in residuumWorld.nodes) node.id: node.kind,
      };

      // assert
      expect(kinds[stonebridge], NodeKind.town);
      expect(kinds[northgate], NodeKind.town);
      expect(kinds[cryptNode], NodeKind.dungeon);
      expect(kinds[seaCave], NodeKind.dungeon);
      expect(kinds[ruinedKeep], NodeKind.dungeon);
      expect(kinds, hasLength(5));
    });

    test('is a triangle with both new dungeons hung off Northgate', () {
      // act
      final neighbours = {
        for (final node in residuumWorld.nodes)
          node.id: residuumWorld.adjacentTo(node.id),
      };

      // assert
      expect(neighbours[stonebridge], {northgate, cryptNode});
      expect(neighbours[northgate], {
        stonebridge,
        cryptNode,
        seaCave,
        ruinedKeep,
      });
      expect(neighbours[cryptNode], {stonebridge, northgate});
      expect(neighbours[seaCave], {northgate});
      expect(neighbours[ruinedKeep], {northgate});
    });

    test('puts neither new dungeon within reach of the home town', () {
      // act
      final fromHome = residuumWorld.adjacentTo(stonebridge);

      // assert
      expect(fromHome, isNot(contains(seaCave)));
      expect(fromHome, isNot(contains(ruinedKeep)));
    });

    test('walks a day to the sea-cave and two to the keep', () {
      // act
      final cave = residuumWorld.routeBetween(northgate, seaCave)!;
      final keep = residuumWorld.routeBetween(northgate, ruinedKeep)!;

      // assert
      expect((cave.days, cave.danger), (1, 30));
      expect((keep.days, keep.danger), (2, 40));
    });

    test('makes the longest walk the most dangerous one', () {
      // act
      final keep = residuumWorld.routeBetween(northgate, ruinedKeep)!;
      final others = [
        for (final route in residuumWorld.routes)
          if (route != keep) route,
      ];

      // assert
      expect(
        others,
        everyElement(predicate<Route>((r) => r.danger < keep.danger)),
      );
    });

    test('every road takes at least a day', () {
      // act
      final days = residuumWorld.routes.map((route) => route.days);

      // assert
      expect(days, everyElement(greaterThanOrEqualTo(1)));
    });

    test('every road carries a danger that is a chance in a hundred', () {
      // act
      final dangers = residuumWorld.routes.map((route) => route.danger);

      // assert
      expect(dangers, everyElement(inInclusiveRange(0, 100)));
    });

    test('the crawl loop is the safest road, and nothing is shorter', () {
      // arrange
      final loop = residuumWorld.routeBetween(stonebridge, cryptNode)!;

      // act
      final others = [
        for (final route in residuumWorld.routes)
          if (route != loop) route,
      ];

      // assert — the sea-cave road ties the loop on days and doubles its
      // danger, so "shortest" is now shared and "safest" is still the loop's
      // alone. That is what keeps the crypt the farming loop.
      expect(
        others,
        everyElement(predicate<Route>((r) => r.days >= loop.days)),
      );
      expect(
        others,
        everyElement(predicate<Route>((r) => r.danger > loop.danger)),
      );
    });

    test('the road that skips a town is worse than the road through it', () {
      // act
      final backRoad = residuumWorld.routeBetween(northgate, cryptNode)!;
      final throughTown = residuumWorld.routeBetween(stonebridge, northgate)!;

      // assert
      expect(backRoad.danger, greaterThan(throughTown.danger));
    });

    test('shopping the other shelf is a four day round trip', () {
      // act
      final there = residuumWorld.routeBetween(stonebridge, northgate)!;

      // assert
      expect(there.days * 2, 4);
    });

    test('every place has a name to put on a screen', () {
      // act
      final names = residuumWorld.nodes.map((node) => node.name);

      // assert
      expect(names, everyElement(isNotEmpty));
      expect(names.toSet(), hasLength(residuumWorld.nodes.length));
    });
  });

  group('where a hero starts', () {
    test('is the home town, on day zero, off any road', () {
      // act
      final where = newWhereabouts();

      // assert
      expect(where.at, stonebridge);
      expect(where.home, stonebridge);
      expect(where.day, 0);
      expect(where.isTravelling, isFalse);
    });

    test('knows the home town and the crypt and nothing else', () {
      // act
      final where = newWhereabouts();

      // assert
      expect(where.discovered, {stonebridge, cryptNode});
      expect(where.discovered, isNot(contains(northgate)));
    });

    test('is somewhere the shipped world actually has', () {
      // act
      final node = residuumWorld.nodeAt(newWhereabouts().at);

      // assert
      expect(node.kind, NodeKind.town);
    });
  });

  group('the rumor pool', () {
    test('every rumor points at a place the world has', () {
      // act
      final targets = rumorPool.map((rumor) => rumor.reveals);

      // assert
      for (final target in targets) {
        expect(() => residuumWorld.nodeAt(target), returnsNormally);
      }
    });

    test('every rumor is a sentence somebody could say', () {
      // act
      final lines = rumorPool.map((rumor) => rumor.line);

      // assert
      expect(lines, everyElement(endsWith('.')));
      expect(lines.toSet(), hasLength(rumorPool.length));
    });

    test('names every place, including the ones it can never sell', () {
      // act
      final targets = rumorPool.map((rumor) => rumor.reveals).toSet();

      // assert
      expect(targets, {northgate, cryptNode, seaCave, ruinedKeep});
    });

    test('uncovers the world in the order it is meant to be walked', () {
      // act
      final order = rumorPool.map((rumor) => rumor.reveals).toList();

      // assert
      expect(order, [northgate, cryptNode, seaCave, ruinedKeep]);
    });

    test('sells the sea-cave next, once the town is known', () {
      // arrange
      final knowing = newWhereabouts().hearingOf(northgate);

      // act
      final told = buyRumor(
        _fresh().copyWith(gold: 100),
        knowing,
        rumorPool,
        rumorPrice,
      );

      // assert
      expect(told.rumor!.reveals, seaCave);
      expect(told.whereabouts.discovered, contains(seaCave));
    });

    test('sells the keep last of all', () {
      // arrange
      final knowing = newWhereabouts().hearingOf(northgate).hearingOf(seaCave);

      // act
      final told = buyRumor(
        _fresh().copyWith(gold: 100),
        knowing,
        rumorPool,
        rumorPrice,
      );

      // assert
      expect(told.rumor!.reveals, ruinedKeep);
    });

    test('the first thing it can sell is the town nobody has heard of', () {
      // act
      final told = buyRumor(
        _fresh().copyWith(gold: 100),
        newWhereabouts(),
        rumorPool,
        rumorPrice,
      );

      // assert
      expect(told.rumor!.reveals, northgate);
      expect(told.whereabouts.discovered, contains(northgate));
    });

    test('once the map is uncovered there is nothing left to sell', () {
      // arrange
      final knowing = newWhereabouts()
          .hearingOf(northgate)
          .hearingOf(seaCave)
          .hearingOf(ruinedKeep);

      // act
      final told = buyRumor(
        _fresh().copyWith(gold: 100),
        knowing,
        rumorPool,
        rumorPrice,
      );

      // assert
      expect(told.rumor, isNull);
      expect(told.profile.gold, 100);
    });

    test('costs more than a bed, because a bed is one night', () {
      // assert
      expect(rumorPrice, greaterThan(innPrice));
    });
  });

  group('what walks the roads', () {
    test('is only creatures the bestiary has', () {
      // act
      final ids = roadSpawnTable.entries.map((entry) => entry.creatureId);

      // assert
      for (final id in ids) {
        expect(() => creatureById(id), returnsNormally);
      }
    });

    test('is nothing out of the crypt', () {
      // act
      final ids = roadSpawnTable.entries
          .map((entry) => entry.creatureId)
          .toSet();

      // assert
      expect(ids, {'rat', 'wolf'});
      expect(ids, isNot(contains('ghoul')));
      expect(ids, isNot(contains('skeleton')));
      expect(ids, isNot(contains('wight')));
    });

    test('is a smaller pack than the shallowest floor of the crypt', () {
      // act
      final floorOne = spawnTableFor(1);

      // assert
      expect(roadSpawnTable.maxCount, lessThan(floorOne.maxCount));
    });

    test('every entry carries a weight worth drawing', () {
      // act
      final weights = roadSpawnTable.entries.map((entry) => entry.weight);

      // assert
      expect(weights, everyElement(greaterThan(0)));
    });
  });

  group('what the roads give up', () {
    test('can never hand over what the dungeon is for', () {
      // act
      final drawn = {
        for (final rarity in roadDropTable.rarities)
          if (rarity.weight > 0) rarity.value,
      };

      // assert
      expect(drawn, {Rarity.common, Rarity.fine});
    });

    test('scatters nothing on open ground', () {
      // assert
      expect(roadDropTable.minFloorItems, 0);
      expect(roadDropTable.maxFloorItems, 0);
    });

    test('leans on potions harder than any floor of the crypt', () {
      // arrange
      int potionShare(DropTable table) {
        final total = table.items.fold(0, (sum, item) => sum + item.weight);
        final potion = table.items
            .where((item) => item.value.isPotion)
            .fold(0, (sum, item) => sum + item.weight);
        return potion * 100 ~/ total;
      }

      // act
      final road = potionShare(roadDropTable);

      // assert
      for (var depth = 1; depth <= deepestDepth; depth++) {
        expect(road, greaterThan(potionShare(dropTableFor(depth))));
      }
    });

    test('is keyed where the dungeon is not', () {
      // assert
      expect(roadDepth, isNot(inInclusiveRange(1, deepestDepth)));
    });
  });

  group('walking into a road fight', () {
    test('lands the hero on open ground with creatures on it', () {
      // act
      final fight = startRoadEncounter(_fresh(), day: 3);

      // assert
      expect(fight.isEncounter, isTrue);
      expect(fight.map.width, encounterWidth);
      expect(fight.monsters, isNotEmpty);
      expect(fight.map.isWalkable(fight.hero.position), isTrue);
    });

    test('brings the hero as they are, purse and pack and all', () {
      // arrange
      final rich = _fresh().copyWith(gold: 77);

      // act
      final fight = startRoadEncounter(rich, day: 3);

      // assert
      expect(fight.gold, 77);
      expect(fight.inventory, rich.inventory);
      expect(fight.equipment, rich.equipment);
      expect(fight.skills, rich.skills);
      expect(fight.hero.hp, rich.hero.hp);
    });

    test('does not bump the visit', () {
      // arrange
      final profile = _fresh().copyWith(visit: 4);

      // act
      final fight = startRoadEncounter(profile, day: 3);

      // assert
      expect(fight.visit, 4);
    });

    test('has no stairs and no floor beneath it', () {
      // act
      final fight = startRoadEncounter(_fresh(), day: 3);

      // assert
      expect(fight.stairsDown, isNull);
      expect(fight.stairsUp, isNull);
      expect(() => fight.buildFloor(1), throwsStateError);
    });

    test('gives the hero the first move', () {
      // act
      final fight = startRoadEncounter(_fresh(), day: 3);

      // assert
      expect(fight.hero.energy, actThreshold);
    });

    test('has nobody already swinging at the hero', () {
      // arrange
      final tooClose = <String>[];

      // act
      for (var day = 1; day <= 60; day++) {
        final fight = startRoadEncounter(_fresh(), day: day);
        for (final monster in fight.monsters) {
          if (monster.position.isOrthogonallyAdjacentTo(fight.hero.position)) {
            tooClose.add('day $day');
          }
        }
      }

      // assert
      expect(tooClose, isEmpty);
    });

    test('gives every creature on the ground its own name', () {
      // arrange
      final clashes = <String>[];

      // act
      for (var day = 1; day <= 60; day++) {
        final fight = startRoadEncounter(_fresh(), day: day);
        final ids = fight.monsters.map((monster) => monster.id).toSet();
        if (ids.length != fight.monsters.length) clashes.add('day $day');
      }

      // assert
      expect(clashes, isEmpty);
    });

    test('draws only from the road table', () {
      // arrange
      final names = <String>{};

      // act
      for (var day = 1; day <= 80; day++) {
        names.addAll(
          startRoadEncounter(_fresh(), day: day).monsters.map((m) => m.name),
        );
      }

      // assert
      expect(names, {'the giant rat', 'the dire wolf'});
    });

    test('the same world and day is the same fight', () {
      // act
      final one = startRoadEncounter(_fresh(), day: 9);
      final other = startRoadEncounter(_fresh(), day: 9);

      // assert
      expect(one.map.toAscii(), other.map.toAscii());
      expect(
        one.monsters.map((m) => (m.id, m.position)),
        other.monsters.map((m) => (m.id, m.position)),
      );
      expect(one.rng.state, other.rng.state);
    });

    test('two days of one world are two different fights', () {
      // act
      final grounds = {
        for (var day = 1; day <= 20; day++)
          startRoadEncounter(_fresh(), day: day).map.toAscii(),
      };

      // assert
      expect(grounds, hasLength(greaterThan(1)));
    });

    test('two worlds on one day are two different fights', () {
      // act
      final one = startRoadEncounter(_fresh(worldSeed: 1), day: 5);
      final other = startRoadEncounter(_fresh(worldSeed: 2), day: 5);

      // assert
      expect(one.map.toAscii(), isNot(other.map.toAscii()));
    });

    test('the ground it is fought on is not the stream it is fought with', () {
      // act
      final fight = startRoadEncounter(_fresh(), day: 5);

      // assert
      expect(
        fight.rng.state,
        isNot(Rng(ambushGroundSeed(_fresh().worldSeed, 5)).state),
      );
      expect(fight.rng.state, isNot(fight.lootRng.state));
    });

    test('never lands the hero where they could leave at once', () {
      // arrange
      final tooNearTheEdge = <String>[];

      // act
      for (var day = 1; day <= 80; day++) {
        final fight = startRoadEncounter(_fresh(), day: day);
        final hero = fight.hero.position;
        final fromEdge = [
          hero.x,
          hero.y,
          fight.map.width - 1 - hero.x,
          fight.map.height - 1 - hero.y,
        ].reduce((one, other) => one < other ? one : other);
        if (fromEdge < heroInsetFromEdge) tooNearTheEdge.add('day $day');
      }

      // assert
      expect(tooNearTheEdge, isEmpty);
    });

    test('the hero can walk off it in every direction', () {
      // arrange
      final fight = startRoadEncounter(_fresh(), day: 5);

      // act
      final atTheEdge = fight.copyWith(
        hero: fight.hero.copyWith(position: const Position(0, 5)),
      );
      final (_, events) = step(atTheEdge, const MoveAction(Direction.west));

      // assert
      expect(events, [const Fled()]);
    });
  });

  group('what a kill on the road gives up', () {
    /// Kills one creature on each of many days and collects what fell.
    ///
    /// The monster is moved next to the hero and left on one hit point, because
    /// what is under test is the drop table a road fight carries rather than how
    /// long a wolf takes to kill. The drop roll itself is untouched.
    List<Item> _spoilsOverManyDays() {
      final fell = <Item>[];
      for (var day = 1; day <= 120; day++) {
        final fight = startRoadEncounter(_fresh(), day: day);
        final hero = fight.hero.position;
        final beside = Position(hero.x + 1, hero.y);
        if (!fight.map.isWalkable(beside)) continue;
        final wounded = fight.monsters.first.copyWith(hp: 1, position: beside);
        final (_, events) = step(
          fight.copyWith(monsters: [wounded]),
          const MoveAction(Direction.east),
        );
        for (final event in events) {
          if (event is ItemDropped) fell.add(event.item);
        }
      }
      return fell;
    }

    test('is sometimes something', () {
      // act
      final fell = _spoilsOverManyDays();

      // assert
      expect(fell, isNotEmpty);
    });

    test('is only ever off the road table', () {
      // arrange
      final onTheRoadTable = {
        for (final weighted in roadDropTable.items) weighted.value.name,
      };

      // act
      final fell = _spoilsOverManyDays();

      // assert
      for (final item in fell) {
        expect(onTheRoadTable, contains(item.base.name));
      }
    });

    test('is never better than the road table allows', () {
      // act
      final fell = _spoilsOverManyDays();

      // assert
      expect(
        fell.map((item) => item.rarity).toSet(),
        everyElement(isIn([Rarity.common, Rarity.fine])),
      );
    });

    test('is named for the road rather than for a floor', () {
      // act
      final fell = _spoilsOverManyDays();

      // assert
      for (final item in fell) {
        expect(item.id, isNot(startsWith('floor-')));
      }
    });
  });

  group('the seeds a road draws on', () {
    test('never collide with a floor, a shelf or each other', () {
      // arrange
      final worlds = [1, 5, 909, 123456, 1755800000000, 2, 7, 99991];

      // act
      final collisions = <String>[];
      for (final worldSeed in worlds) {
        final travel = <int>{};
        final ground = <int>{};
        final fight = <int>{};
        for (var day = 0; day < 2000; day++) {
          travel.add(roadSeed(travelSeedFor(worldSeed), day));
          ground.add(ambushGroundSeed(worldSeed, day));
          fight.add(ambushFightSeed(worldSeed, day));
        }
        final floors = <int>{};
        for (var depth = 1; depth <= deepestDepth; depth++) {
          for (var visit = 0; visit < 2000; visit++) {
            floors.add(floorSeed(worldSeed, depth, visit));
          }
        }
        final named = {
          'travel': travel,
          'ground': ground,
          'fight': fight,
          'floors': floors,
        };
        for (final one in named.entries) {
          for (final other in named.entries) {
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

    test('the two ambush slots are not one slot', () {
      // act
      final ground = ambushGroundSeed(909, 7);
      final fight = ambushFightSeed(909, 7);

      // assert
      expect(ground, isNot(fight));
    });

    test('the road salt is not the market salt or the loot salt', () {
      // assert
      expect(travelSalt, isNot(ambushSalt));
      expect(travelSalt, isNot(lootStreamSalt));
      expect(ambushSalt, isNot(lootStreamSalt));
    });
  });
}
