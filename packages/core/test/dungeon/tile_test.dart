import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Tile', () {
    test('a wall blocks movement and sight', () {
      // arrange
      const tile = Tile.wall;

      // act
      final properties = (tile.walkable, tile.transparent);

      // assert
      expect(properties, (false, false));
    });

    test('a floor allows movement and sight', () {
      // arrange
      const tile = Tile.floor;

      // act
      final properties = (tile.walkable, tile.transparent);

      // assert
      expect(properties, (true, true));
    });
  });
}
