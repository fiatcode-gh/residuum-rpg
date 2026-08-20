import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const allDepths = [1, 2, 3, 4, 5];

Floor floorAt(int depth, {int worldSeed = 1}) =>
    buildFloor(depth, worldSeed: worldSeed, visit: 0);

void main() {
  group('the bestiary', () {
    test('every creature has its own id and its own glyph', () {
      // arrange
      const creatures = bestiary;

      // act
      final ids = creatures.map((creature) => creature.id).toSet();
      final glyphs = creatures.map((creature) => creature.glyph).toSet();

      // assert
      expect(creatures, hasLength(5));
      expect(ids, hasLength(creatures.length));
      expect(glyphs, hasLength(creatures.length));
    });

    test('every creature is drawn as a single character', () {
      // arrange
      const creatures = bestiary;

      // act
      final lengths = creatures.map((creature) => creature.glyph.length);

      // assert
      expect(lengths, everyElement(1));
    });

    test('every creature has a sane stat line', () {
      // arrange
      const creatures = bestiary;

      // assert
      for (final creature in creatures) {
        expect(creature.hp, greaterThan(0), reason: creature.id);
        expect(creature.speed, greaterThan(0), reason: creature.id);
        expect(
          creature.attackMax,
          greaterThanOrEqualTo(creature.attackMin),
          reason: creature.id,
        );
        expect(creature.attackMin, greaterThan(0), reason: creature.id);
        expect(creature.name, startsWith('the '), reason: creature.id);
      }
    });

    test('the speeds are not all the same, so the clock is visible', () {
      // arrange
      const creatures = bestiary;

      // act
      final speeds = creatures.map((creature) => creature.speed).toSet();

      // assert
      expect(speeds, containsAll([5, 10, 20]));
    });

    test('a spawned creature arrives alive and ready to act', () {
      // arrange
      const creature = direWolf;

      // act
      final actor = creature.spawn(id: 'wolf-1', at: const Position(3, 4));

      // assert
      expect(actor.id, 'wolf-1');
      expect(actor.name, 'the dire wolf');
      expect((actor.hp, actor.maxHp), (8, 8));
      expect(actor.speed, 20);
      expect(actor.energy, actThreshold);
      expect(actor.position, const Position(3, 4));
    });

    test('an unknown creature id is refused', () {
      // arrange
      const id = 'basilisk';

      // act
      void act() => creatureById(id);

      // assert
      expect(act, throwsArgumentError);
    });
  });

  group('the spawn tables', () {
    test('every depth from one to five has a table', () {
      // arrange
      const depths = allDepths;

      // act
      final tables = depths.map(spawnTableFor);

      // assert
      expect(tables, hasLength(depths.length));
      expect(spawnTables.keys.toSet(), depths.toSet());
    });

    test('a depth outside the dungeon is refused', () {
      // arrange
      const depth = 6;

      // act
      void act() => spawnTableFor(depth);

      // assert
      expect(act, throwsArgumentError);
    });

    test('every entry names a creature that exists', () {
      // arrange
      const depths = allDepths;

      // act
      final referenced = [
        for (final depth in depths)
          for (final entry in spawnTableFor(depth).entries) entry.creatureId,
      ];

      // assert
      expect(referenced, isNotEmpty);
      for (final id in referenced) {
        expect(() => creatureById(id), returnsNormally, reason: id);
      }
    });

    test('every table is non-empty with positive weights and counts', () {
      // arrange
      const depths = allDepths;

      // assert
      for (final depth in depths) {
        final table = spawnTableFor(depth);
        expect(table.entries, isNotEmpty, reason: 'depth $depth');
        expect(table.minCount, greaterThan(0), reason: 'depth $depth');
        expect(
          table.maxCount,
          greaterThanOrEqualTo(table.minCount),
          reason: 'depth $depth',
        );
        for (final entry in table.entries) {
          expect(entry.weight, greaterThan(0), reason: entry.creatureId);
        }
      }
    });

    test('every creature in the bestiary can be met somewhere', () {
      // arrange
      const depths = allDepths;

      // act
      final reachable = {
        for (final depth in depths)
          for (final entry in spawnTableFor(depth).entries) entry.creatureId,
      };

      // assert
      expect(reachable, bestiary.map((creature) => creature.id).toSet());
    });

    test('a roll only ever returns a creature from that table', () {
      // arrange
      final rng = Rng(4);
      final table = spawnTableFor(3);
      final allowed = table.entries.map((entry) => entry.creatureId).toSet();

      // act
      final rolled = {
        for (var draw = 0; draw < 200; draw++) table.rollCreature(rng).id,
      };

      // assert
      expect(allowed, containsAll(rolled));
      expect(rolled, hasLength(allowed.length));
    });

    test('a count stays inside the table range', () {
      // arrange
      final rng = Rng(9);
      final table = spawnTableFor(5);

      // act
      final counts = [
        for (var draw = 0; draw < 100; draw++) table.rollCount(rng),
      ];

      // assert
      expect(
        counts,
        everyElement(inInclusiveRange(table.minCount, table.maxCount)),
      );
    });
  });

  group('buildFloor', () {
    test('every floor puts its monsters on distinct walkable tiles', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (final floor in floors) {
        final places = floor.monsters.map((m) => m.position).toList();
        expect(places.toSet(), hasLength(places.length));
        expect(places.map(floor.map.isWalkable), everyElement(isTrue));
        expect(places, isNot(contains(floor.heroSpawn)));
      }
    });

    test('monster ids are unique on every floor', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (final floor in floors) {
        final ids = floor.monsters.map((monster) => monster.id).toList();
        expect(ids.toSet(), hasLength(ids.length));
      }
    });

    test('the monster count comes from that depth\'s table', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (var index = 0; index < depths.length; index++) {
        final table = spawnTableFor(depths[index]);
        expect(
          floors[index].monsters,
          hasLength(inInclusiveRange(table.minCount, table.maxCount)),
          reason: 'depth ${depths[index]}',
        );
      }
    });

    test('every monster on a floor belongs to that depth\'s table', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (var index = 0; index < depths.length; index++) {
        final allowed = spawnTableFor(
          depths[index],
        ).entries.map((entry) => creatureById(entry.creatureId).glyph).toSet();
        expect(
          floors[index].monsters.map((monster) => monster.glyph).toSet(),
          everyElement(isIn(allowed)),
          reason: 'depth ${depths[index]}',
        );
      }
    });

    test('only the deepest floor has no stairs down', () {
      // arrange
      const depths = allDepths;

      // act
      final stairs = depths.map((depth) => floorAt(depth).stairsDown).toList();

      // assert
      expect(stairs.sublist(0, 4), everyElement(isNotNull));
      expect(stairs.last, isNull);
    });

    test('the same world seed builds the same five floors, twice over', () {
      // arrange
      const worldSeed = 31337;

      // act
      final first = [
        for (final depth in allDepths) floorAt(depth, worldSeed: worldSeed),
      ];
      final second = [
        for (final depth in allDepths) floorAt(depth, worldSeed: worldSeed),
      ];

      // assert
      for (var index = 0; index < first.length; index++) {
        expect(first[index].map.toAscii(), second[index].map.toAscii());
        expect(first[index].heroSpawn, second[index].heroSpawn);
        expect(first[index].stairsDown, second[index].stairsDown);
        expect(
          first[index].monsters.map((m) => (m.id, m.position)),
          second[index].monsters.map((m) => (m.id, m.position)),
        );
      }
    });

    test('two world seeds are two different dungeons', () {
      // arrange
      const depth = 2;

      // act
      final one = floorAt(depth, worldSeed: 1).map.toAscii();
      final another = floorAt(depth, worldSeed: 2).map.toAscii();

      // assert
      expect(one, isNot(another));
    });
  });

  group('newGame', () {
    test('arms the hero with the rusty sword at the baseline speed', () {
      // arrange
      final game = newGame();

      // act
      final hero = game.hero;

      // assert
      expect(hero.id, 'hero');
      expect(hero.name, 'you');
      expect(hero.glyph, '@');
      expect((hero.hp, hero.maxHp), (20, 20));
      expect((hero.attackMin, hero.attackMax), (3, 5));
      expect(hero.speed, 10);
      expect(hero.energy, actThreshold);
    });

    test('starts on the first floor, on ground it can stand on', () {
      // arrange
      final game = newGame();

      // act
      final start = game.hero.position;

      // assert
      expect(game.depth, 1);
      expect(game.map.isWalkable(start), isTrue);
      expect(game.stairsDown, isNotNull);
    });

    test('places the first floor\'s spawn table with distinct ids', () {
      // arrange
      final game = newGame();
      final table = spawnTableFor(1);

      // act
      final monsters = game.monsters;

      // assert
      expect(
        monsters,
        hasLength(inInclusiveRange(table.minCount, table.maxCount)),
      );
      expect(monsters.map((m) => m.id).toSet(), hasLength(monsters.length));
    });

    test(
      'starts with the hero seeing its own tile and nothing more explored',
      () {
        // arrange
        final game = newGame();

        // act
        final visible = game.visible;

        // assert
        expect(visible, contains(game.hero.position));
        expect(game.explored, visible);
        expect(game.isGameOver, isFalse);
      },
    );

    test(
      'hides every monster at the start, so the dark has something in it',
      () {
        // arrange
        final game = newGame();

        // act
        final seen = game.monsters.where(
          (monster) => game.visible.contains(monster.position),
        );

        // assert
        expect(seen, isEmpty);
      },
    );

    test('a monster reaches the hero and draws blood', () {
      // arrange
      var game = newGame();

      // act
      for (var turn = 0; turn < 200; turn++) {
        final (next, _) = step(game, const MoveAction(Direction.north));
        game = next;
        if (game.isGameOver || game.hero.hp < 20) break;
      }

      // assert
      expect(game.hero.hp, lessThan(20));
    });

    test('the same seed produces the same crawl', () {
      // arrange
      final one = newGame(worldSeed: 7);
      final another = newGame(worldSeed: 7);

      // act
      final first = _play(one, 12);
      final second = _play(another, 12);

      // assert
      expect(first, second);
    });

    test('a crawl can walk the stairs from depth one down to depth five', () {
      // arrange
      const worldSeed = 1;
      Floor bare(int depth) {
        final floor = buildFloor(depth, worldSeed: worldSeed, visit: 0);
        return Floor(
          map: floor.map,
          heroSpawn: floor.heroSpawn,
          monsters: const [],
          stairsDown: floor.stairsDown,
        );
      }

      final first = bare(1);
      final visible = computeFov(first.map, first.heroSpawn, fovRadius);
      var game = GameState(
        map: first.map,
        hero: newGame(
          worldSeed: worldSeed,
        ).hero.copyWith(position: first.heroSpawn),
        monsters: const [],
        rng: Rng(worldSeed),
        visible: visible,
        explored: {...visible},
        buildFloor: bare,
        worldSeed: worldSeed,
        stairsDown: first.stairsDown,
      );
      final depthsReached = <int>[game.depth];

      // act
      while (game.stairsDown != null) {
        for (final step_ in findPath(
          game.map,
          game.hero.position,
          game.stairsDown!,
        )) {
          final direction = game.hero.position.directionTo(step_)!;
          final (next, _) = step(game, MoveAction(direction));
          game = next;
        }
        final (below, events) = step(game, const DescendAction());
        game = below;
        expect(events.whereType<Descended>(), hasLength(1));
        depthsReached.add(game.depth);
      }

      // assert
      expect(depthsReached, [1, 2, 3, 4, 5]);
      expect(game.stairsDown, isNull);
      expect(game.hero.hp, 20);
    });

    test('the layout does not depend on how the fighting goes', () {
      // arrange
      final fighting = newGame(worldSeed: 55);
      final walking = newGame(worldSeed: 55);

      // act
      _play(fighting, 30, direction: Direction.north);
      _play(walking, 5, direction: Direction.east);
      final afterFighting = fighting.buildFloor(2);
      final afterWalking = walking.buildFloor(2);

      // assert
      expect(afterFighting.map.toAscii(), afterWalking.map.toAscii());
      expect(
        afterFighting.monsters.map((m) => (m.id, m.position)),
        afterWalking.monsters.map((m) => (m.id, m.position)),
      );
    });
  });
}

List<String> _play(
  GameState start,
  int turns, {
  Direction direction = Direction.east,
}) {
  final log = <String>[];
  var game = start;
  for (var turn = 0; turn < turns; turn++) {
    final (next, events) = step(game, MoveAction(direction));
    log.addAll(events.map((event) => event.toString()));
    game = next;
  }
  return log;
}
