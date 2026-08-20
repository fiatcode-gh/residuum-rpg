import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const room = '''
#######
#.....#
#.....#
#.....#
#######''';

const bentCorridor = '''
#######
#..#..#
#..#..#
#.....#
#######''';

const sealed = '''
#####
#.#.#
#.###
#...#
#####''';

void main() {
  group('findPath', () {
    test('walks a straight line, excluding where it starts', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final path = findPath(map, const Position(1, 1), const Position(4, 1));

      // assert
      expect(path, const [Position(2, 1), Position(3, 1), Position(4, 1)]);
    });

    test('includes the destination', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final path = findPath(map, const Position(1, 1), const Position(3, 3));

      // assert
      expect(path.last, const Position(3, 3));
    });

    test('takes the shortest route, not merely a route', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final path = findPath(map, const Position(1, 1), const Position(5, 3));

      // assert
      expect(path, hasLength(6));
    });

    test('every step is walkable and adjacent to the one before it', () {
      // arrange
      final map = FloorMap.parse(bentCorridor);

      // act
      final path = findPath(map, const Position(5, 1), const Position(1, 1));

      // assert
      var previous = const Position(5, 1);
      for (final step in path) {
        expect(map.isWalkable(step), isTrue);
        expect(step.isOrthogonallyAdjacentTo(previous), isTrue);
        previous = step;
      }
    });

    test('bends around a wall instead of through it', () {
      // arrange
      final map = FloorMap.parse(bentCorridor);

      // act
      final path = findPath(map, const Position(4, 1), const Position(2, 1));

      // assert
      expect(path, const [
        Position(4, 2),
        Position(4, 3),
        Position(3, 3),
        Position(2, 3),
        Position(2, 2),
        Position(2, 1),
      ]);
    });

    test('a path to where the hero already stands is empty', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final path = findPath(map, const Position(2, 2), const Position(2, 2));

      // assert
      expect(path, isEmpty);
    });

    test('an unreachable destination gives an empty path', () {
      // arrange
      final map = FloorMap.parse(sealed);

      // act
      final path = findPath(map, const Position(1, 1), const Position(3, 1));

      // assert
      expect(path, isEmpty);
    });

    test('a wall destination gives an empty path', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final path = findPath(map, const Position(1, 1), const Position(0, 0));

      // assert
      expect(path, isEmpty);
    });

    test('a destination off the grid gives an empty path', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final path = findPath(map, const Position(1, 1), const Position(99, 99));

      // assert
      expect(path, isEmpty);
    });

    test('ties are broken north, east, south, west', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final path = findPath(map, const Position(3, 3), const Position(1, 1));

      // assert
      expect(path.first, const Position(3, 2));
    });

    test('the same request always returns the same path', () {
      // arrange
      final map = FloorMap.parse(bentCorridor);

      // act
      final first = findPath(map, const Position(5, 1), const Position(1, 1));
      final second = findPath(map, const Position(5, 1), const Position(1, 1));

      // assert
      expect(first, second);
    });
  });
}
