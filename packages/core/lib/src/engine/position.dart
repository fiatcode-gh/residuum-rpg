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

  /// How many king's moves separate this tile from [other].
  ///
  /// Chebyshev rather than the walked distance, because the things that measure
  /// with it do not walk: a bolt crosses a room in a straight line, so a monster
  /// standing diagonally is as near as one standing beside you. Measuring in
  /// walked steps would make the tile a hero cannot reach in one move somehow
  /// further from the spell than one they can.
  int chebyshevTo(Position other) {
    final across = (x - other.x).abs();
    final down = (y - other.y).abs();
    return across > down ? across : down;
  }

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

/// Rows first, then columns, so a sorted list reads the way a floor does.
///
/// **A rule's comparator as much as a codec's.** It sorts the tiles of a save
/// document so one state encodes to one document, and it breaks the tie when two
/// monsters stand equally close to a spell: both want one total order over
/// tiles, and two orders that agreed today would be one refactor away from
/// disagreeing about which ghoul a firebolt hit.
int byRowThenColumn(Position first, Position second) => first.y == second.y
    ? first.x.compareTo(second.x)
    : first.y.compareTo(second.y);
