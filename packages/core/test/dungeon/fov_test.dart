import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

FloorMap openField(int width, int height) =>
    FloorMap.parse(List.generate(height, (_) => '.' * width).join('\n'));

const occluded = '''
.......
.......
..###..
.......
.......''';

const closedRoom = '''
#####
#...#
#...#
#...#
#####''';

void main() {
  group('computeFov', () {
    test('always includes the origin, even inside a wall', () {
      // arrange
      final map = FloorMap.parse(closedRoom);
      const origin = Position(0, 0);

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, contains(origin));
    });

    test('lights an open field out to the radius', () {
      // arrange
      final map = openField(15, 15);
      const origin = Position(7, 7);

      // act
      final visible = computeFov(map, origin, 3);

      // assert
      expect(visible, contains(const Position(10, 7)));
      expect(visible, contains(const Position(7, 4)));
      expect(visible, contains(const Position(4, 7)));
      expect(visible, contains(const Position(7, 10)));
    });

    test('stops at the radius', () {
      // arrange
      final map = openField(15, 15);
      const origin = Position(7, 7);

      // act
      final visible = computeFov(map, origin, 3);

      // assert
      expect(visible, isNot(contains(const Position(11, 7))));
      expect(visible, isNot(contains(const Position(7, 11))));
    });

    test('the lit area is a circle, not a square', () {
      // arrange
      final map = openField(15, 15);
      const origin = Position(7, 7);

      // act
      final visible = computeFov(map, origin, 3);

      // assert
      expect(visible, contains(const Position(9, 9)));
      expect(visible, isNot(contains(const Position(10, 10))));
    });

    test('does not see past a wall', () {
      // arrange
      final map = FloorMap.parse(occluded);
      const origin = Position(3, 4);

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, contains(const Position(3, 3)));
      expect(visible, isNot(contains(const Position(3, 1))));
      expect(visible, isNot(contains(const Position(3, 0))));
    });

    test('lights the wall that blocks the view', () {
      // arrange
      final map = FloorMap.parse(occluded);
      const origin = Position(3, 4);

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, contains(const Position(3, 2)));
    });

    test('lights every wall of the room the hero stands in', () {
      // arrange
      final map = FloorMap.parse(closedRoom);
      const origin = Position(2, 2);
      final walls = <Position>{
        for (var x = 0; x < 5; x++) Position(x, 0),
        for (var x = 0; x < 5; x++) Position(x, 4),
        for (var y = 0; y < 5; y++) Position(0, y),
        for (var y = 0; y < 5; y++) Position(4, y),
      };

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, containsAll(walls));
    });

    test('is deterministic', () {
      // arrange
      final map = FloorMap.parse(occluded);
      const origin = Position(3, 4);

      // act
      final first = computeFov(map, origin, 8);
      final second = computeFov(map, origin, 8);

      // assert
      expect(first, second);
    });

    test('the hero sight radius is eight tiles', () {
      // arrange
      const expected = 8;

      // act
      final actual = fovRadius;

      // assert
      expect(actual, expected);
    });
  });
}
