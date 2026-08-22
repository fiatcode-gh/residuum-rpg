import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// Depth two of seed 90210, exactly as the shipped generator lays it out.
///
/// Pasted from a real [generateFloor] run at base `844376f`, never edited by
/// hand or by tooling. The existing generator tests check that one seed builds
/// the same floor twice, which is a statement about determinism and not about
/// *which* floor — a generator that changed every layout in the game would keep
/// every one of them green. This says which floor, so the arrival of a second
/// generator beside this one cannot move the first one's output without saying
/// so.
const String _seed90210Depth2 =
    '##########################\n'
    '#....#########....##....##\n'
    '#....##....###..........##\n'
    '#..<.......###....##....##\n'
    '#....##...........########\n'
    '#########.####....########\n'
    '#########.####....########\n'
    '#....####.######.#########\n'
    '#....####.######.#########\n'
    '#....####.#####...###....#\n'
    '#....####.#####...###....#\n'
    '#...........###...###....#\n'
    '#....##.....###........>.#\n'
    '#...........###...###....#\n'
    '#....##.....###...###....#\n'
    '#######.....###...########\n'
    '##########################';

/// Depth four of seed 7, for [_seed90210Depth2]'s reason at a second size.
///
/// Two depths rather than one, because the grid's width and height are both a
/// function of depth: a change that only showed up on the larger floors would
/// slip past a single pin.
const String _seed7Depth4 =
    '##############################\n'
    '#...###....#######...#########\n'
    '#...###....#######...####....#\n'
    '#.<........#######...####..>.#\n'
    '#...###....########.#####....#\n'
    '###.###############.#######.##\n'
    '###.###############.#######.##\n'
    '###.###....#######....####...#\n'
    '#....##....#######....####...#\n'
    '#..........#######....####...#\n'
    '#....##....########..#####...#\n'
    '###.###############..#####..##\n'
    '###.###############..#####..##\n'
    '##...##...#########..###.....#\n'
    '##........###.....#..###.....#\n'
    '##...##..............###.....#\n'
    '#######...###................#\n'
    '#############.....############\n'
    '##############################';

void main() {
  group('the crypt generator, pinned byte for byte', () {
    test('depth two of seed 90210 is the floor it has always been', () {
      // arrange
      const seed = 90210;

      // act
      final floor = generateFloor(seed, 2, monsterCount: 5);

      // assert
      expect(floor.map.toAscii(), _seed90210Depth2);
      expect(floor.heroSpawn, const Position(3, 3));
      expect(floor.stairsDown, const Position(23, 12));
      expect(floor.stairsUp, const Position(3, 3));
    });

    test('depth four of seed 7 is the floor it has always been', () {
      // arrange
      const seed = 7;

      // act
      final floor = generateFloor(seed, 4, monsterCount: 7);

      // assert
      expect(floor.map.toAscii(), _seed7Depth4);
      expect(floor.heroSpawn, const Position(2, 3));
      expect(floor.stairsDown, const Position(27, 3));
      expect(floor.stairsUp, const Position(2, 3));
    });

    test('the monsters stand where they have always stood', () {
      // arrange
      const seed = 90210;

      // act
      final floor = generateFloor(seed, 2, monsterCount: 5);

      // assert
      expect(floor.monsterSpawns, const [
        Position(23, 14),
        Position(15, 11),
        Position(15, 14),
        Position(11, 12),
        Position(24, 10),
      ]);
    });

    test('the draw order puts the items after the monsters', () {
      // arrange
      const seed = 90210;

      // act
      final bare = generateFloor(seed, 2, monsterCount: 5);
      final littered = generateFloor(seed, 2, monsterCount: 5, itemCount: 4);

      // assert
      expect(littered.map.toAscii(), bare.map.toAscii());
      expect(littered.monsterSpawns, bare.monsterSpawns);
    });
  });

  group('the crypt border', () {
    test('is solid wall on two thousand floors', () {
      // arrange
      final leaks = <String>[];

      // act
      for (var depth = 1; depth <= 5; depth++) {
        for (var seed = 0; seed < 400; seed++) {
          final map = generateFloor(
            seed,
            depth,
            monsterCount: 3,
            itemCount: 2,
          ).map;
          for (var x = 0; x < map.width; x++) {
            if (map.isWalkable(Position(x, 0)) ||
                map.isWalkable(Position(x, map.height - 1))) {
              leaks.add('seed $seed depth $depth column $x');
            }
          }
          for (var y = 0; y < map.height; y++) {
            if (map.isWalkable(Position(0, y)) ||
                map.isWalkable(Position(map.width - 1, y))) {
              leaks.add('seed $seed depth $depth row $y');
            }
          }
        }
      }

      // assert
      expect(leaks, isEmpty);
    });
  });
}
