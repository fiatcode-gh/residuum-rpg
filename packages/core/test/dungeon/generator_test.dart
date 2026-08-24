import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const monsterCounts = {1: 4, 2: 5, 3: 6, 4: 7, 5: 8};

GeneratedFloor floorAt(int depth, {int seed = 1}) =>
    generateFloor(seed, depth, monsterCount: monsterCounts[depth]!);

Set<Position> _reachableFrom(GeneratedFloor floor) =>
    computeFlowField(floor.map, floor.heroSpawn).keys.toSet();

Set<Position> _walkableTiles(FloorMap map) => {
  for (var y = 0; y < map.height; y++)
    for (var x = 0; x < map.width; x++)
      if (map.isWalkable(Position(x, y))) Position(x, y),
};

void main() {
  group('floorSeed', () {
    test(
      'the same world seed, depth and visit always mix to the same seed',
      () {
        // arrange
        const worldSeed = 4242;

        // act
        final first = floorSeed(worldSeed, 3, 0);
        final second = floorSeed(worldSeed, 3, 0);

        // assert
        expect(first, second);
      },
    );

    test('depth, visit and world seed each change the result', () {
      // arrange
      const worldSeed = 4242;

      // act
      final base = floorSeed(worldSeed, 3, 0);

      // assert
      expect(floorSeed(worldSeed, 4, 0), isNot(base));
      expect(floorSeed(worldSeed, 3, 1), isNot(base));
      expect(floorSeed(worldSeed + 1, 3, 0), isNot(base));
    });

    test('stays inside the range every platform can seed a generator with', () {
      // arrange
      const worldSeeds = [0, 1, 7, 99991, 2147483647];

      // act
      final seeds = [
        for (final worldSeed in worldSeeds)
          for (var depth = 1; depth <= 5; depth++)
            for (var visit = 0; visit < 4; visit++)
              floorSeed(worldSeed, depth, visit),
      ];

      // assert
      expect(seeds, everyElement(inInclusiveRange(0, 0x3fffffff)));
    });

    test('five depths of one world are five different seeds', () {
      // arrange
      const worldSeed = 12345;

      // act
      final seeds = {
        for (var depth = 1; depth <= 5; depth++) floorSeed(worldSeed, depth, 0),
      };

      // assert
      expect(seeds, hasLength(5));
    });
  });

  group('generateFloor geometry', () {
    test('the grid grows gently with depth, inside the design bounds', () {
      // arrange
      final sizes = <(int, int)>[];

      // act
      for (var depth = 1; depth <= 5; depth++) {
        final floor = floorAt(depth);
        sizes.add((floor.map.width, floor.map.height));
      }

      // assert
      expect(sizes.first, (24, 16));
      expect(sizes.last, (32, 20));
      for (var index = 1; index < sizes.length; index++) {
        expect(sizes[index].$1, greaterThan(sizes[index - 1].$1));
        expect(sizes[index].$2, greaterThan(sizes[index - 1].$2));
      }
    });

    test('the border is solid wall on every depth', () {
      // arrange
      final floors = [for (var depth = 1; depth <= 5; depth++) floorAt(depth)];

      // act
      final leaks = <Position>[];
      for (final floor in floors) {
        final map = floor.map;
        for (var x = 0; x < map.width; x++) {
          if (map.isWalkable(Position(x, 0))) leaks.add(Position(x, 0));
          if (map.isWalkable(Position(x, map.height - 1))) {
            leaks.add(Position(x, map.height - 1));
          }
        }
        for (var y = 0; y < map.height; y++) {
          if (map.isWalkable(Position(0, y))) leaks.add(Position(0, y));
          if (map.isWalkable(Position(map.width - 1, y))) {
            leaks.add(Position(map.width - 1, y));
          }
        }
      }

      // assert
      expect(leaks, isEmpty);
    });

    test('a floor is neither cramped nor an empty cave', () {
      // arrange
      final floor = floorAt(1);

      // act
      final open = _walkableTiles(floor.map).length;
      final total = floor.map.width * floor.map.height;

      // assert
      expect(open / total, greaterThan(0.15));
      expect(open / total, lessThan(0.6));
    });
  });

  group('generateFloor guarantees', () {
    test('every walkable tile is reachable from where the hero arrives', () {
      // arrange
      final floors = [for (var depth = 1; depth <= 5; depth++) floorAt(depth)];

      // act
      final orphans = [
        for (final floor in floors)
          ..._walkableTiles(floor.map).difference(_reachableFrom(floor)),
      ];

      // assert
      expect(orphans, isEmpty);
    });

    test('the hero arrives on walkable ground', () {
      // arrange
      final floors = [for (var depth = 1; depth <= 5; depth++) floorAt(depth)];

      // act
      final standing = floors.map((f) => f.map.isWalkable(f.heroSpawn));

      // assert
      expect(standing, everyElement(isTrue));
    });

    test('stairs down exist and are reachable on depths one to four', () {
      // arrange
      final floors = [for (var depth = 1; depth <= 4; depth++) floorAt(depth)];

      // act
      final stairs = floors.map((f) => f.stairsDown).toList();

      // assert
      for (var index = 0; index < floors.length; index++) {
        final floor = floors[index];
        expect(stairs[index], isNotNull);
        expect(floor.map.tileAt(stairs[index]!), Tile.stairsDown);
        expect(_reachableFrom(floor), contains(stairs[index]));
        expect(stairs[index], isNot(floor.heroSpawn));
      }
    });

    test('the fifth floor has no way down', () {
      // arrange
      final floor = floorAt(5);

      // act
      final stairs = floor.stairsDown;

      // assert
      expect(stairs, isNull);
      expect(
        _walkableTiles(floor.map).map(floor.map.tileAt),
        isNot(contains(Tile.stairsDown)),
      );
    });

    test('depth one has no way up', () {
      // arrange
      final floor = floorAt(1);

      // act
      final up = floor.stairsUp;

      // assert
      expect(up, isNull);
      expect(
        _walkableTiles(floor.map).map(floor.map.tileAt),
        isNot(contains(Tile.stairsUp)),
      );
    });

    test('depths two to five arrive on a real stairs-up tile', () {
      // arrange
      final floors = [for (var depth = 2; depth <= 5; depth++) floorAt(depth)];

      // act
      final up = floors.map((floor) => floor.stairsUp).toList();

      // assert
      for (var index = 0; index < floors.length; index++) {
        final floor = floors[index];
        expect(up[index], isNotNull);
        expect(up[index], floor.heroSpawn);
        expect(floor.map.tileAt(up[index]!), Tile.stairsUp);
        expect(_reachableFrom(floor), contains(up[index]));
        expect(up[index], isNot(floor.stairsDown));
      }
    });

    test('the stairs are a real walk away from where the hero arrives', () {
      // arrange
      final floor = floorAt(1);

      // act
      final distance = computeFlowField(
        floor.map,
        floor.heroSpawn,
      )[floor.stairsDown];

      // assert
      expect(distance, greaterThan(10));
    });

    test(
      'monsters spawn on distinct reachable tiles, never under the hero',
      () {
        // arrange
        final floors = [
          for (var depth = 1; depth <= 5; depth++) floorAt(depth),
        ];

        // act
        final spawns = floors.map((f) => f.monsterSpawns).toList();

        // assert
        for (var index = 0; index < floors.length; index++) {
          final floor = floors[index];
          expect(spawns[index], hasLength(monsterCounts[index + 1]));
          expect(spawns[index].toSet(), hasLength(spawns[index].length));
          expect(spawns[index], isNot(contains(floor.heroSpawn)));
          expect(spawns[index], isNot(contains(floor.stairsDown)));
          expect(_reachableFrom(floor), containsAll(spawns[index]));
        }
      },
    );

    test('no monster is in sight the moment the hero arrives', () {
      // arrange
      final floors = [for (var depth = 1; depth <= 5; depth++) floorAt(depth)];

      // act
      final seen = [
        for (final floor in floors)
          ...floor.monsterSpawns.where(
            computeFov(floor.map, floor.heroSpawn, fovRadius).contains,
          ),
      ];

      // assert
      expect(seen, isEmpty);
    });
  });

  group('generateFloor determinism', () {
    test('the same seed and depth build a byte-identical floor', () {
      // arrange
      const seed = 90210;

      // act
      final first = generateFloor(seed, 2, monsterCount: 5);
      final second = generateFloor(seed, 2, monsterCount: 5);

      // assert
      expect(first.map.toAscii(), second.map.toAscii());
      expect(first.heroSpawn, second.heroSpawn);
      expect(first.stairsDown, second.stairsDown);
      expect(first.monsterSpawns, second.monsterSpawns);
    });

    test('a second golden seed is stable too', () {
      // arrange
      const seed = 7;

      // act
      final first = generateFloor(seed, 4, monsterCount: 7);
      final second = generateFloor(seed, 4, monsterCount: 7);

      // assert
      expect(first.map.toAscii(), second.map.toAscii());
      expect(first.monsterSpawns, second.monsterSpawns);
    });

    test('different seeds build different floors', () {
      // arrange
      const depth = 3;

      // act
      final one = generateFloor(11, depth, monsterCount: 6).map.toAscii();
      final another = generateFloor(12, depth, monsterCount: 6).map.toAscii();

      // assert
      expect(one, isNot(another));
    });
  });

  group('generateFloor validation', () {
    test('a rejected attempt is regenerated from a derived retry seed', () {
      // arrange
      var attempts = 0;
      String? rejectTheFirstTwo(
        GeneratedFloor floor,
        int depth,
        int count,
        int deepest,
      ) {
        attempts++;
        return attempts <= 2 ? 'rejected for the test' : null;
      }

      // act
      final retried = generateFloor(
        500,
        2,
        monsterCount: 5,
        findProblem: rejectTheFirstTwo,
      );
      final thirdAttempt = generateFloor(502, 2, monsterCount: 5);

      // assert
      expect(attempts, 3);
      expect(retried.map.toAscii(), thirdAttempt.map.toAscii());
      expect(retried.monsterSpawns, thirdAttempt.monsterSpawns);
    });

    test('a floor that never validates throws with the diagnostic', () {
      // arrange
      String? alwaysWrong(
        GeneratedFloor floor,
        int depth,
        int count,
        int deepest,
      ) => 'the corridors are haunted';

      // act
      void act() =>
          generateFloor(1, 1, monsterCount: 4, findProblem: alwaysWrong);

      // assert
      expect(
        act,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('the corridors are haunted'),
              contains('$maxGenerationAttempts'),
            ),
          ),
        ),
      );
    });

    test('a floor split in two is reported as split', () {
      // arrange
      final split = GeneratedFloor(
        map: FloorMap.parse('#####\n#.#.#\n#####'),
        heroSpawn: const Position(1, 1),
        monsterSpawns: const [Position(3, 1)],
        stairsDown: const Position(3, 1),
      );

      // act
      final problem = describeFloorProblem(split, 1, 1, deepestDepth);

      // assert
      expect(problem, contains('split'));
    });

    test('a floor missing its stairs is reported', () {
      // arrange
      final noStairs = GeneratedFloor(
        map: FloorMap.parse('######\n#....#\n######'),
        heroSpawn: const Position(1, 1),
        monsterSpawns: const [],
        stairsDown: null,
      );

      // act
      final problem = describeFloorProblem(noStairs, 2, 0, deepestDepth);

      // assert
      expect(problem, contains('no stairs down'));
    });

    test('stairs on the deepest floor are reported', () {
      // arrange
      final tooDeep = GeneratedFloor(
        map: FloorMap.parse('######\n#...>#\n######'),
        heroSpawn: const Position(1, 1),
        monsterSpawns: const [],
        stairsDown: const Position(4, 1),
      );

      // act
      final problem = describeFloorProblem(
        tooDeep,
        deepestDepth,
        0,
        deepestDepth,
      );

      // assert
      expect(problem, contains('bottom'));
    });

    test('the wrong number of monsters is reported', () {
      // arrange
      final floor = GeneratedFloor(
        map: FloorMap.parse('######\n#...>#\n######'),
        heroSpawn: const Position(1, 1),
        monsterSpawns: const [Position(2, 1)],
        stairsDown: const Position(4, 1),
      );

      // act
      final problem = describeFloorProblem(floor, 1, 3, deepestDepth);

      // assert
      expect(problem, contains('wanted 3 monsters, placed 1'));
    });

    test('a monster standing in the arrival light is reported', () {
      // arrange
      final floor = GeneratedFloor(
        map: FloorMap.parse('######\n#...>#\n######'),
        heroSpawn: const Position(1, 1),
        monsterSpawns: const [Position(2, 1)],
        stairsDown: const Position(4, 1),
      );

      // act
      final problem = describeFloorProblem(floor, 1, 1, deepestDepth);

      // assert
      expect(problem, contains('in sight before the hero has moved'));
    });

    test('the shipped validator passes every floor the generator builds', () {
      // arrange
      final problems = <String>[];

      // act
      for (var depth = 1; depth <= 5; depth++) {
        final floor = floorAt(depth, seed: 31 * depth);
        final problem = describeFloorProblem(
          floor,
          depth,
          monsterCounts[depth]!,
          deepestDepth,
        );
        if (problem != null) problems.add('depth $depth: $problem');
      }

      // assert
      expect(problems, isEmpty);
    });

    test(
      'two hundred seeds across five depths all generate without throwing',
      () {
        // arrange
        final failures = <String>[];

        // act
        for (var seed = 0; seed < 200; seed++) {
          for (var depth = 1; depth <= 5; depth++) {
            try {
              floorAt(depth, seed: seed);
            } on StateError catch (error) {
              failures.add('seed $seed depth $depth: ${error.message}');
            }
          }
        }

        // assert
        expect(failures, isEmpty);
      },
    );

    test('a count no floor can hold is refused rather than half-filled', () {
      // arrange
      const impossible = 5000;

      // act
      void act() => generateFloor(1, 1, monsterCount: impossible);

      // assert
      expect(act, throwsStateError);
    });
  });

  group('generateFloor in a delve deeper than the crypt', () {
    test("lays stairs down on every floor above the delve's bottom", () {
      // arrange
      const deepest = 7;

      // act
      final floors = [
        for (var depth = 1; depth < deepest; depth++)
          generateFloor(41 * depth, depth, monsterCount: 4, deepest: deepest),
      ];

      // assert
      expect(floors.map((floor) => floor.stairsDown), everyElement(isNotNull));
    });

    test("leaves the way down off the delve's own bottom", () {
      // act
      final bottom = generateFloor(287, 7, monsterCount: 4, deepest: 7);

      // assert
      expect(bottom.stairsDown, isNull);
    });

    test('still lays stairs on depth five when the delve goes to seven', () {
      // act
      final fifth = generateFloor(505, 5, monsterCount: 4, deepest: 7);

      // assert
      expect(fifth.stairsDown, isNotNull);
    });

    test('passes its own validator on every floor of a seven-deep delve', () {
      // arrange
      const deepest = 7;
      final problems = <String>[];

      // act
      for (var depth = 1; depth <= deepest; depth++) {
        final floor = generateFloor(
          61 * depth,
          depth,
          monsterCount: 4,
          deepest: deepest,
        );
        final problem = describeFloorProblem(floor, depth, 4, deepest);
        if (problem != null) problems.add('depth $depth: $problem');
      }

      // assert
      expect(problems, isEmpty);
    });
  });

  group('the validator on where the delve bottoms out', () {
    test('refuses a floor above the bottom with no way down, naming both', () {
      // arrange
      final noStairs = GeneratedFloor(
        map: FloorMap.parse('######\n#....#\n######'),
        heroSpawn: const Position(1, 1),
        monsterSpawns: const [],
        stairsDown: null,
      );

      // act
      final problem = describeFloorProblem(noStairs, 5, 0, 7);

      // assert
      expect(problem, contains('no stairs down'));
      expect(problem, contains('5'));
      expect(problem, contains('7'));
    });

    test('refuses the bottom carrying a way down, naming both', () {
      // arrange
      final tooDeep = GeneratedFloor(
        map: FloorMap.parse('######\n#...>#\n######'),
        heroSpawn: const Position(1, 1),
        monsterSpawns: const [],
        stairsDown: const Position(4, 1),
      );

      // act
      final problem = describeFloorProblem(tooDeep, 6, 0, 6);

      // assert
      expect(problem, contains('bottom'));
      expect(problem, contains('6'));
    });

    test(
      'takes depth six for an ordinary floor when the delve goes deeper',
      () {
        // act
        final problem = describeFloorProblem(
          generateFloor(909, 6, monsterCount: 3, deepest: 7),
          6,
          3,
          7,
        );

        // assert
        expect(problem, isNull);
      },
    );
  });

  group("the bottom generateFloor assumes when nobody names one", () {
    test("is the crypt's five, so an unnamed delve builds today's floor", () {
      // act
      final named = generateFloor(777, 4, monsterCount: 6, deepest: 5);
      final unnamed = generateFloor(777, 4, monsterCount: 6);

      // assert
      expect(unnamed.map.toAscii(), named.map.toAscii());
      expect(unnamed.stairsDown, named.stairsDown);
      expect(unnamed.monsterSpawns, named.monsterSpawns);
    });

    test('leaves depth five stairless when nobody says otherwise', () {
      // act
      final floor = generateFloor(778, 5, monsterCount: 6);

      // assert
      expect(floor.stairsDown, isNull);
    });
  });
}
