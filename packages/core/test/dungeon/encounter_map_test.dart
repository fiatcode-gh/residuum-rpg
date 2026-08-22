import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// Every tile on the outermost ring of [map].
Iterable<Position> _border(FloorMap map) sync* {
  for (var x = 0; x < map.width; x++) {
    yield Position(x, 0);
    yield Position(x, map.height - 1);
  }
  for (var y = 1; y < map.height - 1; y++) {
    yield Position(0, y);
    yield Position(map.width - 1, y);
  }
}

void main() {
  group('the ground a road fight happens on', () {
    test('is the same size whatever the seed', () {
      // arrange
      const seeds = [1, 2, 3, 99, 12345];

      // act
      final sizes = {
        for (final seed in seeds)
          (
            generateEncounter(seed, monsterCount: 3).map.width,
            generateEncounter(seed, monsterCount: 3).map.height,
          ),
      };

      // assert
      expect(sizes, {(encounterWidth, encounterHeight)});
    });

    test('has no stairs anywhere on it', () {
      // act
      final ground = generateEncounter(7, monsterCount: 3);

      // assert
      final tiles = {
        for (var y = 0; y < ground.map.height; y++)
          for (var x = 0; x < ground.map.width; x++)
            ground.map.tileAt(Position(x, y)),
      };
      expect(tiles, {Tile.wall, Tile.floor});
    });

    test('has a walkable border on every seed, which is the way out', () {
      // arrange
      final walled = <String>[];

      // act
      for (var seed = 0; seed < 200; seed++) {
        final ground = generateEncounter(seed, monsterCount: 3);
        for (final edge in _border(ground.map)) {
          if (!ground.map.isWalkable(edge)) walled.add('seed $seed at $edge');
        }
      }

      // assert
      expect(walled, isEmpty);
    });

    test('is open ground rather than a warren', () {
      // act
      final ground = generateEncounter(31, monsterCount: 4);

      // assert
      var walkable = 0;
      for (var y = 0; y < ground.map.height; y++) {
        for (var x = 0; x < ground.map.width; x++) {
          if (ground.map.isWalkable(Position(x, y))) walkable++;
        }
      }
      final area = encounterWidth * encounterHeight;
      expect(walkable / area, greaterThan(0.7));
    });

    test('has something on it to stand behind', () {
      // arrange
      final bare = <int>[];

      // act
      for (var seed = 0; seed < 60; seed++) {
        final ground = generateEncounter(seed, monsterCount: 3);
        var walls = 0;
        for (var y = 1; y < ground.map.height - 1; y++) {
          for (var x = 1; x < ground.map.width - 1; x++) {
            if (!ground.map.isWalkable(Position(x, y))) walls++;
          }
        }
        if (walls == 0) bare.add(seed);
      }

      // assert
      expect(bare, isEmpty);
    });
  });

  group('where the hero lands', () {
    test('is walkable', () {
      // act
      final ground = generateEncounter(5, monsterCount: 3);

      // assert
      expect(ground.map.isWalkable(ground.heroSpawn), isTrue);
    });

    test('is never within a step or two of the way out', () {
      // arrange
      final tooClose = <String>[];

      // act
      for (var seed = 0; seed < 200; seed++) {
        final spawn = generateEncounter(seed, monsterCount: 3).heroSpawn;
        final fromEdge = [
          spawn.x,
          spawn.y,
          encounterWidth - 1 - spawn.x,
          encounterHeight - 1 - spawn.y,
        ].reduce((one, other) => one < other ? one : other);
        if (fromEdge < heroInsetFromEdge) {
          tooClose.add('seed $seed at $spawn is $fromEdge from the edge');
        }
      }

      // assert
      expect(tooClose, isEmpty);
    });
  });

  group('where the monsters land', () {
    test('is as many of them as were asked for', () {
      // act
      final ground = generateEncounter(11, monsterCount: 4);

      // assert
      expect(ground.monsterSpawns, hasLength(4));
    });

    test('is never two on one tile', () {
      // arrange
      final shared = <int>[];

      // act
      for (var seed = 0; seed < 200; seed++) {
        final spawns = generateEncounter(seed, monsterCount: 4).monsterSpawns;
        if (spawns.toSet().length != spawns.length) shared.add(seed);
      }

      // assert
      expect(shared, isEmpty);
    });

    test('is somewhere the hero can walk to', () {
      // arrange
      final walledOff = <String>[];

      // act
      for (var seed = 0; seed < 200; seed++) {
        final ground = generateEncounter(seed, monsterCount: 4);
        final reachable = computeFlowField(
          ground.map,
          ground.heroSpawn,
        ).keys.toSet();
        for (final spawn in ground.monsterSpawns) {
          if (!reachable.contains(spawn)) walledOff.add('seed $seed at $spawn');
        }
      }

      // assert
      expect(walledOff, isEmpty);
    });

    test('is never already swinging at the hero', () {
      // arrange
      final onTop = <String>[];

      // act
      for (var seed = 0; seed < 200; seed++) {
        final ground = generateEncounter(seed, monsterCount: 4);
        for (final spawn in ground.monsterSpawns) {
          if (spawn == ground.heroSpawn ||
              spawn.isOrthogonallyAdjacentTo(ground.heroSpawn)) {
            onTop.add('seed $seed at $spawn');
          }
        }
      }

      // assert
      expect(onTop, isEmpty);
    });

    test('is allowed to be in plain sight, unlike a crawl', () {
      // arrange
      var seenSomewhere = false;

      // act
      for (var seed = 0; seed < 60 && !seenSomewhere; seed++) {
        final ground = generateEncounter(seed, monsterCount: 4);
        final visible = computeFov(ground.map, ground.heroSpawn, fovRadius);
        seenSomewhere = ground.monsterSpawns.any(visible.contains);
      }

      // assert
      expect(seenSomewhere, isTrue);
    });
  });

  group('the validator', () {
    test('says nothing is wrong with what the generator makes', () {
      // arrange
      final complaints = <String>[];

      // act
      for (var seed = 0; seed < 200; seed++) {
        final problem = describeEncounterProblem(
          generateEncounter(seed, monsterCount: 4),
          4,
        );
        if (problem != null) complaints.add('seed $seed: $problem');
      }

      // assert
      expect(complaints, isEmpty);
    });

    test('catches a wall sitting on the way out', () {
      // arrange
      final ascii = [
        for (var y = 0; y < encounterHeight; y++)
          [
            for (var x = 0; x < encounterWidth; x++)
              x == 0 && y == 5 ? '#' : '.',
          ].join(),
      ].join('\n');
      final ground = EncounterGround(
        map: FloorMap.parse(ascii),
        heroSpawn: const Position(7, 5),
        monsterSpawns: const [Position(9, 5)],
      );

      // act
      final problem = describeEncounterProblem(ground, 1);

      // assert
      expect(problem, contains('the way out'));
    });

    test('catches a hero standing on the way out', () {
      // arrange
      final ground = EncounterGround(
        map: FloorMap.parse(_openGround()),
        heroSpawn: const Position(0, 5),
        monsterSpawns: const [Position(9, 5)],
      );

      // act
      final problem = describeEncounterProblem(ground, 1);

      // assert
      expect(problem, contains('the edge'));
    });

    test('catches stairs somebody added', () {
      // arrange
      final ascii = [
        for (var y = 0; y < encounterHeight; y++)
          [
            for (var x = 0; x < encounterWidth; x++)
              x == 4 && y == 4 ? '>' : '.',
          ].join(),
      ].join('\n');
      final ground = EncounterGround(
        map: FloorMap.parse(ascii),
        heroSpawn: const Position(7, 5),
        monsterSpawns: const [Position(9, 5)],
      );

      // act
      final problem = describeEncounterProblem(ground, 1);

      // assert
      expect(problem, contains('stairs'));
    });

    test('catches a monster nobody can reach', () {
      // arrange
      final ascii = [
        for (var y = 0; y < encounterHeight; y++)
          [
            for (var x = 0; x < encounterWidth; x++)
              y >= 1 && y <= 3 && x >= 1 && x <= 3
                  ? (x == 2 && y == 2 ? '.' : '#')
                  : '.',
          ].join(),
      ].join('\n');
      final ground = EncounterGround(
        map: FloorMap.parse(ascii),
        heroSpawn: const Position(7, 5),
        monsterSpawns: const [Position(2, 2)],
      );

      // act
      final problem = describeEncounterProblem(ground, 1);

      // assert
      expect(problem, contains('walled off'));
    });

    test('catches a monster already on top of the hero', () {
      // arrange
      final ground = EncounterGround(
        map: FloorMap.parse(_openGround()),
        heroSpawn: const Position(7, 5),
        monsterSpawns: const [Position(8, 5)],
      );

      // act
      final problem = describeEncounterProblem(ground, 1);

      // assert
      expect(problem, contains('already'));
    });

    test('catches the wrong number of monsters', () {
      // arrange
      final ground = EncounterGround(
        map: FloorMap.parse(_openGround()),
        heroSpawn: const Position(7, 5),
        monsterSpawns: const [Position(10, 5)],
      );

      // act
      final problem = describeEncounterProblem(ground, 3);

      // assert
      expect(problem, contains('wanted 3'));
    });

    test('is the seam the retry contract is testable through', () {
      // arrange
      var asked = 0;

      // act
      final ground = generateEncounter(
        4,
        monsterCount: 2,
        findProblem: (ground, count) {
          asked++;
          return asked < 3 ? 'not yet' : null;
        },
      );

      // assert
      expect(asked, 3);
      expect(ground.map.width, encounterWidth);
    });

    test('gives up loudly rather than rolling for ever', () {
      // act
      EncounterGround make() => generateEncounter(
        4,
        monsterCount: 2,
        findProblem: (ground, count) => 'never good enough',
      );

      // assert
      expect(make, throwsStateError);
    });

    test('refuses to place more monsters than there is ground for', () {
      // act
      EncounterGround make() => generateEncounter(4, monsterCount: 500);

      // assert
      expect(make, throwsStateError);
    });
  });

  group('the golden road fights', () {
    test('seed 8080 is the fight it has always been', () {
      // arrange
      const seed = 8080;

      // act
      final ground = generateEncounter(seed, monsterCount: 4);

      // assert
      expect(ground.map.toAscii(), _golden8080);
      expect(ground.heroSpawn, const Position(7, 6));
      expect(ground.monsterSpawns, const [
        Position(8, 10),
        Position(14, 4),
        Position(9, 9),
        Position(10, 7),
      ]);
    });

    test('seed 17 is the fight it has always been', () {
      // arrange
      const seed = 17;

      // act
      final ground = generateEncounter(seed, monsterCount: 3);

      // assert
      expect(ground.map.toAscii(), _golden17);
      expect(ground.heroSpawn, const Position(11, 7));
      expect(ground.monsterSpawns, const [
        Position(2, 6),
        Position(14, 8),
        Position(1, 1),
      ]);
    });
  });

  group('the same road fight twice', () {
    test('is laid out identically', () {
      // arrange
      const seed = 8080;

      // act
      final one = generateEncounter(seed, monsterCount: 4);
      final other = generateEncounter(seed, monsterCount: 4);

      // assert
      expect(one.map.toAscii(), other.map.toAscii());
      expect(one.heroSpawn, other.heroSpawn);
      expect(one.monsterSpawns, other.monsterSpawns);
    });

    test('two seeds are two different fights', () {
      // act
      final one = generateEncounter(11, monsterCount: 4);
      final other = generateEncounter(12, monsterCount: 4);

      // assert
      expect(one.map.toAscii(), isNot(other.map.toAscii()));
    });

    test('asking for more monsters cannot move the ground under them', () {
      // arrange
      const seed = 8080;

      // act
      final few = generateEncounter(seed, monsterCount: 2);
      final many = generateEncounter(seed, monsterCount: 5);

      // assert
      expect(few.map.toAscii(), many.map.toAscii());
      expect(few.heroSpawn, many.heroSpawn);
    });
  });
}

/// A fixed-size sheet of nothing but floor, for the validator's own tests.
String _openGround() =>
    [for (var y = 0; y < encounterHeight; y++) '.' * encounterWidth].join('\n');

/// Seed 8080, exactly as the shipped generator lays it out.
///
/// Pasted from a real [generateEncounter] run, never edited by hand or by
/// tooling. Determinism tests say one seed builds one fight twice; this says
/// which fight, which is the part a change to the draw order would move while
/// every relation test stayed green.
const String _golden8080 =
    '...............\n'
    '...###.##.###..\n'
    '...............\n'
    '...............\n'
    '...............\n'
    '...#...........\n'
    '.....#.........\n'
    '.....#.........\n'
    '....##.........\n'
    '......##.......\n'
    '...............';

/// Seed 17, for [_golden8080]'s reason with a different scatter and count.
const String _golden17 =
    '...............\n'
    '...............\n'
    '......##.......\n'
    '..##...........\n'
    '...............\n'
    '...............\n'
    '.#.....#.......\n'
    '...............\n'
    '...............\n'
    '.#.............\n'
    '...............';
