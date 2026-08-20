import 'package:equatable/equatable.dart';

/// The four orthogonal directions on the dungeon grid.
///
/// Screen coordinates: y grows downward, so north is negative y.
enum Direction {
  north(0, -1),
  south(0, 1),
  east(1, 0),
  west(-1, 0);

  const Direction(this.dx, this.dy);

  /// The horizontal component of one step in this direction.
  final int dx;

  /// The vertical component of one step in this direction.
  final int dy;
}

/// An immutable tile coordinate on a dungeon floor.
class Position extends Equatable {
  const Position(this.x, this.y);

  final int x;
  final int y;

  /// The neighbouring position one step in [direction].
  Position step(Direction direction) =>
      Position(x + direction.dx, y + direction.dy);

  /// Whether [other] is exactly one orthogonal step away.
  ///
  /// Diagonal neighbours are never adjacent: movement in Residuum is 4-way.
  bool isOrthogonallyAdjacentTo(Position other) =>
      (x - other.x).abs() + (y - other.y).abs() == 1;

  /// The direction of the single step from here to [other], or null when
  /// [other] is not orthogonally adjacent.
  Direction? directionTo(Position other) {
    if (!isOrthogonallyAdjacentTo(other)) return null;
    if (other.x > x) return Direction.east;
    if (other.x < x) return Direction.west;
    return other.y > y ? Direction.south : Direction.north;
  }

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'Position($x, $y)';
}
