import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const twoByThree = '''
###
#.#
###''';

void main() {
  group('FloorMap.parse', () {
    test('maps > to stairs down', () {
      // arrange
      const ascii = '###\n#>#\n###';

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect(map.tileAt(const Position(1, 1)), Tile.stairsDown);
      expect(map.isWalkable(const Position(1, 1)), isTrue);
    });

    test('reads the grid dimensions', () {
      // arrange
      const ascii = twoByThree;

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect((map.width, map.height), (3, 3));
    });

    test('maps # to wall and . to floor', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final centre = map.tileAt(const Position(1, 1));
      final corner = map.tileAt(const Position(0, 0));

      // assert
      expect(centre, Tile.floor);
      expect(corner, Tile.wall);
    });

    test('ignores the leading and trailing newlines of a literal', () {
      // arrange
      const ascii = '\n##\n##\n';

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect((map.width, map.height), (2, 2));
    });

    test('rejects a ragged grid', () {
      // arrange
      const ascii = '###\n##\n###';

      // act
      FloorMap parse() => FloorMap.parse(ascii);

      // assert
      expect(parse, throwsArgumentError);
    });

    test('rejects an unknown character', () {
      // arrange
      const ascii = '###\n#x#\n###';

      // act
      FloorMap parse() => FloorMap.parse(ascii);

      // assert
      expect(parse, throwsArgumentError);
    });

    test('rejects an empty floor', () {
      // arrange
      const ascii = '   ';

      // act
      FloorMap parse() => FloorMap.parse(ascii);

      // assert
      expect(parse, throwsArgumentError);
    });

    test('accepts a single-row floor', () {
      // arrange
      const ascii = '###';

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect((map.width, map.height), (3, 1));
    });
  });

  group('FloorMap queries', () {
    test('a floor tile is walkable and transparent', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final centre = const Position(1, 1);

      // assert
      expect(map.isWalkable(centre), isTrue);
      expect(map.isTransparent(centre), isTrue);
    });

    test('a wall tile is neither walkable nor transparent', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final wall = const Position(0, 1);

      // assert
      expect(map.isWalkable(wall), isFalse);
      expect(map.isTransparent(wall), isFalse);
    });

    test('inBounds covers the whole grid and nothing outside it', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final inside = map.inBounds(const Position(2, 2));
      final beyond = map.inBounds(const Position(3, 2));
      final negative = map.inBounds(const Position(0, -1));

      // assert
      expect(inside, isTrue);
      expect(beyond, isFalse);
      expect(negative, isFalse);
    });

    test('positions outside the grid are neither walkable nor transparent', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final outside = const Position(-1, 1);

      // assert
      expect(map.isWalkable(outside), isFalse);
      expect(map.isTransparent(outside), isFalse);
    });
  });

  group('FloorMap.toAscii', () {
    test('round-trips every tile kind back to the string it came from', () {
      // arrange
      const ascii = '#####\n#.>.#\n#####';

      // act
      final rendered = FloorMap.parse(ascii).toAscii();

      // assert
      expect(rendered, ascii);
    });

    test('renders the stairs tile as a greater-than sign', () {
      // arrange
      final map = FloorMap.parse('###\n#>#\n###');

      // act
      final rendered = map.toAscii();

      // assert
      expect(rendered.split('\n')[1], '#>#');
    });

    test('parses a less-than sign as the stairs up', () {
      // arrange
      final map = FloorMap.parse('###\n#<#\n###');

      // act
      final tile = map.tileAt(const Position(1, 1));

      // assert
      expect(tile, Tile.stairsUp);
    });

    test('renders the stairs up as a less-than sign', () {
      // arrange
      final map = FloorMap.parse('###\n#<#\n###');

      // act
      final rendered = map.toAscii();

      // assert
      expect(rendered.split('\n')[1], '#<#');
    });
  });
}
