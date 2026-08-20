import '../engine/position.dart';
import 'tile.dart';

/// An immutable rectangular grid of dungeon terrain.
///
/// A floor map holds terrain only. Actors live in the game state, so the same
/// map can be shared by every turn of a crawl.
class FloorMap {
  const FloorMap._(this._rows);

  /// Parses a rectangular ASCII floor: `#` is wall, `.` is floor, `>` is the
  /// stairs down.
  ///
  /// Leading and trailing blank lines are ignored so multi-line string
  /// literals read naturally. Throws [ArgumentError] on an empty floor, a
  /// ragged row, or any other character.
  factory FloorMap.parse(String ascii) {
    final lines = ascii.trim().split('\n');
    if (lines.first.isEmpty) {
      throw ArgumentError.value(ascii, 'ascii', 'a floor needs rows of tiles');
    }
    final width = lines.first.length;
    final rows = <List<Tile>>[];
    for (final line in lines) {
      if (line.length != width) {
        throw ArgumentError.value(
          ascii,
          'ascii',
          'ragged floor: row "$line" is not $width tiles wide',
        );
      }
      rows.add(List.unmodifiable(line.split('').map(_tileFor)));
    }
    return FloorMap._(List.unmodifiable(rows));
  }

  static Tile _tileFor(String character) => switch (character) {
    '#' => Tile.wall,
    '.' => Tile.floor,
    '>' => Tile.stairsDown,
    _ => throw ArgumentError.value(character, 'character', 'not a tile'),
  };

  static String _characterFor(Tile tile) => switch (tile) {
    Tile.wall => '#',
    Tile.floor => '.',
    Tile.stairsDown => '>',
  };

  final List<List<Tile>> _rows;

  /// The number of tiles across.
  int get width => _rows.first.length;

  /// The number of tiles down.
  int get height => _rows.length;

  /// Whether [position] lies on the grid.
  bool inBounds(Position position) =>
      position.x >= 0 &&
      position.y >= 0 &&
      position.x < width &&
      position.y < height;

  /// The terrain at [position], which must be [inBounds].
  Tile tileAt(Position position) => _rows[position.y][position.x];

  /// Whether an actor may stand at [position]. False outside the grid.
  bool isWalkable(Position position) =>
      inBounds(position) && tileAt(position).walkable;

  /// Whether sight passes through [position]. False outside the grid.
  bool isTransparent(Position position) =>
      inBounds(position) && tileAt(position).transparent;

  /// The exact inverse of [FloorMap.parse].
  ///
  /// A generated floor is only pinnable by a golden test if it can be written
  /// down; this is how a seed's layout becomes a string a human can read in a
  /// diff.
  String toAscii() =>
      _rows.map((row) => row.map(_characterFor).join()).join('\n');
}
