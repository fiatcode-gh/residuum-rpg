import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Direction', () {
    test('north is one step up the screen', () {
      // arrange
      const direction = Direction.north;

      // act
      final delta = (direction.dx, direction.dy);

      // assert
      expect(delta, (0, -1));
    });

    test('every direction moves exactly one orthogonal tile', () {
      // arrange
      const origin = Position(4, 4);

      // act
      final steps = Direction.values.map(origin.step).toList();

      // assert
      expect(Direction.values, hasLength(4));
      expect(
        steps,
        containsAll(const [
          Position(4, 3),
          Position(4, 5),
          Position(5, 4),
          Position(3, 4),
        ]),
      );
    });
  });

  group('Position', () {
    test('is a value object', () {
      // arrange
      const one = Position(2, 3);
      const another = Position(2, 3);

      // act
      final same = one == another;

      // assert
      expect(same, isTrue);
      expect(one.hashCode, another.hashCode);
      expect(one.toString(), 'Position(2, 3)');
    });

    test('orthogonal neighbours are adjacent', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final adjacency = Direction.values
          .map(origin.step)
          .map(origin.isOrthogonallyAdjacentTo);

      // assert
      expect(adjacency, everyElement(isTrue));
    });

    test('diagonal neighbours are not adjacent', () {
      // arrange
      const origin = Position(5, 5);
      const diagonals = [
        Position(4, 4),
        Position(6, 4),
        Position(4, 6),
        Position(6, 6),
      ];

      // act
      final adjacency = diagonals.map(origin.isOrthogonallyAdjacentTo);

      // assert
      expect(adjacency, everyElement(isFalse));
    });

    test('a tile is not adjacent to itself, nor to a tile two steps away', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final self = origin.isOrthogonallyAdjacentTo(origin);
      final far = origin.isOrthogonallyAdjacentTo(const Position(7, 5));

      // assert
      expect(self, isFalse);
      expect(far, isFalse);
    });

    test('directionTo names the step to an orthogonal neighbour', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final directions = [
        origin.directionTo(const Position(5, 4)),
        origin.directionTo(const Position(5, 6)),
        origin.directionTo(const Position(6, 5)),
        origin.directionTo(const Position(4, 5)),
      ];

      // assert
      expect(directions, [
        Direction.north,
        Direction.south,
        Direction.east,
        Direction.west,
      ]);
    });

    test('directionTo is null for diagonal, distant and identical tiles', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final diagonal = origin.directionTo(const Position(6, 6));
      final distant = origin.directionTo(const Position(5, 9));
      final self = origin.directionTo(origin);

      // assert
      expect(diagonal, isNull);
      expect(distant, isNull);
      expect(self, isNull);
    });
  });
}
