import '../engine/position.dart';
import '../engine/rng.dart';
import 'floor_map.dart';
import 'flow_field.dart';
import 'fov.dart';
import 'tile.dart';

/// The seed of one floor, mixed from the world seed, the [depth] and the
/// [visit] count.
///
/// A Fowler–Noll–Vo style hash combine: exclusive-or the next value in, then
/// multiply by the FNV prime. Everything is masked to 28 bits before the
/// multiply and 30 bits after, so the arithmetic stays exact on a web double
/// as well as a native integer — a shared world seed must describe the same
/// dungeon whichever way the game is compiled.
///
/// [visit] is 0 throughout this milestone. It exists so that dying and coming
/// back reshuffles the dungeon without changing the world.
int floorSeed(int worldSeed, int depth, int visit) {
  var hash = 0x811c9dc5;
  for (final value in [worldSeed, depth, visit]) {
    hash = ((hash ^ (value & 0x0fffffff)) & 0x0fffffff) * 0x01000193;
    hash &= 0x3fffffff;
  }
  return hash;
}

/// The terrain and the placements of one generated floor.
///
/// Terrain only plus coordinates: which creature stands on which spawn tile is
/// content's business, not the generator's.
class GeneratedFloor {
  const GeneratedFloor({
    required this.map,
    required this.heroSpawn,
    required this.monsterSpawns,
    required this.stairsDown,
    this.itemSpawns = const [],
  });

  final FloorMap map;

  /// Where the hero starts, or arrives when descending.
  final Position heroSpawn;

  final List<Position> monsterSpawns;

  /// Null exactly on the deepest floor.
  final Position? stairsDown;

  /// Where this floor's starting items lie.
  ///
  /// Unlike [monsterSpawns] these are **not** kept out of the hero's opening
  /// field of view. An item across the room is a reason to walk over there; a
  /// monster across the room is a fight the player never got to decline.
  final List<Position> itemSpawns;
}

/// Reports what is wrong with a generated floor, or null when it is sound.
typedef FloorProblem =
    String? Function(GeneratedFloor floor, int depth, int monsterCount);

/// How many times [generateFloor] may re-roll before giving up.
const int maxGenerationAttempts = 8;

/// The deepest floor of the dungeon. Only this floor has no way down.
const int deepestDepth = 5;

/// Builds the floor for [depth] from [seed], guaranteed sound or not at all.
///
/// Rooms come from a binary space partition of the grid, one room per leaf,
/// each inset from its leaf so rooms never touch and the border stays wall.
/// Corridors then chain the rooms in leaf order with an L bend, which makes
/// full connectivity true by construction — the flood fill in
/// [describeFloorProblem] is the safety net the design spec asks for, not the
/// mechanism.
///
/// **On a validation failure the floor is re-rolled from `seed + attempt`, at
/// most [maxGenerationAttempts] times, and then it throws.** The player must
/// never walk onto a broken floor; but a generator that re-rolls forever on a
/// bad seed is a hang wearing a safety net's coat, so the retry is bounded and
/// the give-up is loud and carries the diagnostic.
///
/// [monsterCount] is a parameter rather than a table lookup because spawn
/// tables are content and this is core: the count stays a guarantee of the
/// floor, while the table that chose it stays where the creatures live.
///
/// [itemCount] is a parameter for the same reason as [monsterCount]: how much
/// loot a depth scatters is a content table, while *where* it lands is a
/// property of the floor. Items are drawn after the monsters, so raising
/// [itemCount] cannot reshuffle a layout or a spawn a player already shared the
/// seed for.
///
/// [findProblem] is the seam that makes the retry contract testable — the
/// shipped validator does not fail on real seeds, so a test can only reach the
/// retry path by supplying its own.
GeneratedFloor generateFloor(
  int seed,
  int depth, {
  required int monsterCount,
  int itemCount = 0,
  FloorProblem findProblem = describeFloorProblem,
}) {
  var problem = 'no attempt was made';
  for (var attempt = 0; attempt < maxGenerationAttempts; attempt++) {
    final floor = _attemptFloor(seed + attempt, depth, monsterCount, itemCount);
    if (floor == null) {
      problem = 'not enough room for $monsterCount monsters';
      continue;
    }
    final found = findProblem(floor, depth, monsterCount);
    if (found == null) return floor;
    problem = found;
  }
  throw StateError(
    'could not generate a sound floor for depth $depth from seed $seed '
    'in $maxGenerationAttempts attempts: $problem',
  );
}

/// What is wrong with [floor], or null when nothing is.
///
/// Checks, in order: the hero stands on walkable ground; every walkable tile is
/// reachable from the hero; the stairs exist, are reachable and are somewhere
/// else on depths above [deepestDepth] and are absent on it; and the monster
/// spawns are the right number, distinct, reachable, clear of the hero and the
/// stairs, and — the point of the whole rule — none of them is already in
/// sight when the hero arrives.
String? describeFloorProblem(
  GeneratedFloor floor,
  int depth,
  int monsterCount,
) {
  final map = floor.map;
  if (!map.isWalkable(floor.heroSpawn)) {
    return 'the hero arrives at ${floor.heroSpawn}, which is not walkable';
  }
  final reachable = computeFlowField(map, floor.heroSpawn).keys.toSet();
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final position = Position(x, y);
      if (map.isWalkable(position) && !reachable.contains(position)) {
        return 'the floor is split: $position is walled off from the hero';
      }
    }
  }

  final stairs = floor.stairsDown;
  if (depth >= deepestDepth) {
    if (stairs != null) return 'depth $depth is the bottom and has stairs down';
  } else if (stairs == null) {
    return 'depth $depth has no stairs down';
  } else if (!reachable.contains(stairs)) {
    return 'the stairs at $stairs cannot be walked to';
  } else if (stairs == floor.heroSpawn) {
    return 'the hero arrives standing on the stairs down';
  }

  final spawns = floor.monsterSpawns;
  if (spawns.length != monsterCount) {
    return 'wanted $monsterCount monsters, placed ${spawns.length}';
  }
  if (spawns.toSet().length != spawns.length) {
    return 'two monsters share a spawn tile';
  }
  final visible = computeFov(map, floor.heroSpawn, fovRadius);
  for (final spawn in spawns) {
    if (spawn == floor.heroSpawn) return 'a monster spawns under the hero';
    if (spawn == stairs) return 'a monster spawns on the stairs';
    if (!reachable.contains(spawn)) {
      return 'the monster at $spawn is walled off';
    }
    if (visible.contains(spawn)) {
      return 'the monster at $spawn is in sight before the hero has moved';
    }
  }
  return null;
}

const int _minLeafSize = 6;
const int _maxLeafWidth = 11;
const int _maxLeafHeight = 8;
const int _minRoomSize = 3;

GeneratedFloor? _attemptFloor(
  int seed,
  int depth,
  int monsterCount,
  int itemCount,
) {
  final rng = Rng(seed);
  final width = 24 + (depth - 1) * 2;
  final height = 16 + (depth - 1);

  final leaves = <_Rect>[];
  _partition(_Rect(0, 0, width, height), rng, leaves);
  final rooms = [for (final leaf in leaves) _carveRoom(leaf, rng)];
  if (rooms.length < 2) return null;

  final tiles = List.generate(
    height,
    (y) => List.filled(width, Tile.wall),
    growable: false,
  );
  for (final room in rooms) {
    for (var y = room.y; y < room.y + room.height; y++) {
      for (var x = room.x; x < room.x + room.width; x++) {
        tiles[y][x] = Tile.floor;
      }
    }
  }
  for (var index = 1; index < rooms.length; index++) {
    _carveCorridor(tiles, rooms[index - 1].centre, rooms[index].centre, rng);
  }

  final heroSpawn = rooms.first.centre;
  final bare = FloorMap.parse(_render(tiles));
  final distances = computeFlowField(bare, heroSpawn);
  final inSight = computeFov(bare, heroSpawn, fovRadius);

  Position? stairsDown;
  if (depth < deepestDepth) {
    stairsDown = _farthestRoomCentre(rooms, distances);
    if (stairsDown == null) return null;
    tiles[stairsDown.y][stairsDown.x] = Tile.stairsDown;
  }

  final pool = [
    for (final room in rooms.skip(1))
      for (final tile in room.tiles)
        if (tile != stairsDown &&
            distances.containsKey(tile) &&
            !inSight.contains(tile))
          tile,
  ];
  if (pool.length < monsterCount) return null;

  final monsterSpawns = [
    for (var placed = 0; placed < monsterCount; placed++)
      pool.removeAt(rng.rollRange(0, pool.length - 1)),
  ];

  final litter = [
    for (final room in rooms)
      for (final tile in room.tiles)
        if (tile != stairsDown &&
            tile != heroSpawn &&
            distances.containsKey(tile) &&
            !monsterSpawns.contains(tile))
          tile,
  ];
  if (litter.length < itemCount) return null;
  final itemSpawns = [
    for (var placed = 0; placed < itemCount; placed++)
      litter.removeAt(rng.rollRange(0, litter.length - 1)),
  ];

  return GeneratedFloor(
    map: FloorMap.parse(_render(tiles)),
    heroSpawn: heroSpawn,
    monsterSpawns: monsterSpawns,
    stairsDown: stairsDown,
    itemSpawns: itemSpawns,
  );
}

Position? _farthestRoomCentre(List<_Rect> rooms, Map<Position, int> distances) {
  Position? best;
  var bestDistance = 0;
  for (final room in rooms.skip(1)) {
    final distance = distances[room.centre];
    if (distance == null || distance <= bestDistance) continue;
    best = room.centre;
    bestDistance = distance;
  }
  return best;
}

void _partition(_Rect rect, Rng rng, List<_Rect> leaves) {
  final canSplitWide = rect.width >= 2 * _minLeafSize;
  final canSplitTall = rect.height >= 2 * _minLeafSize;
  final small = rect.width <= _maxLeafWidth && rect.height <= _maxLeafHeight;
  if (small || (!canSplitWide && !canSplitTall)) {
    leaves.add(rect);
    return;
  }
  final vertical = canSplitWide && (!canSplitTall || rect.width >= rect.height);
  if (vertical) {
    final cut = rng.rollRange(_minLeafSize, rect.width - _minLeafSize);
    _partition(_Rect(rect.x, rect.y, cut, rect.height), rng, leaves);
    _partition(
      _Rect(rect.x + cut, rect.y, rect.width - cut, rect.height),
      rng,
      leaves,
    );
    return;
  }
  final cut = rng.rollRange(_minLeafSize, rect.height - _minLeafSize);
  _partition(_Rect(rect.x, rect.y, rect.width, cut), rng, leaves);
  _partition(
    _Rect(rect.x, rect.y + cut, rect.width, rect.height - cut),
    rng,
    leaves,
  );
}

_Rect _carveRoom(_Rect leaf, Rng rng) {
  final availableWidth = leaf.width - 2;
  final availableHeight = leaf.height - 2;
  final roomWidth = rng.rollRange(_minRoomSize, availableWidth);
  final roomHeight = rng.rollRange(_minRoomSize, availableHeight);
  final x = rng.rollRange(leaf.x + 1, leaf.x + 1 + availableWidth - roomWidth);
  final y = rng.rollRange(
    leaf.y + 1,
    leaf.y + 1 + availableHeight - roomHeight,
  );
  return _Rect(x, y, roomWidth, roomHeight);
}

void _carveCorridor(
  List<List<Tile>> tiles,
  Position from,
  Position to,
  Rng rng,
) {
  final horizontalFirst = rng.rollRange(0, 1) == 0;
  final corner = horizontalFirst
      ? Position(to.x, from.y)
      : Position(from.x, to.y);
  _carveLine(tiles, from, corner);
  _carveLine(tiles, corner, to);
}

void _carveLine(List<List<Tile>> tiles, Position from, Position to) {
  final stepX = (to.x - from.x).sign;
  final stepY = (to.y - from.y).sign;
  var current = from;
  tiles[current.y][current.x] = Tile.floor;
  while (current != to) {
    current = Position(current.x + stepX, current.y + stepY);
    tiles[current.y][current.x] = Tile.floor;
  }
}

String _render(List<List<Tile>> tiles) => tiles
    .map(
      (row) => row
          .map(
            (tile) => switch (tile) {
              Tile.wall => '#',
              Tile.floor => '.',
              Tile.stairsDown => '>',
            },
          )
          .join(),
    )
    .join('\n');

class _Rect {
  const _Rect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;

  Position get centre => Position(x + width ~/ 2, y + height ~/ 2);

  Iterable<Position> get tiles sync* {
    for (var row = y; row < y + height; row++) {
      for (var column = x; column < x + width; column++) {
        yield Position(column, row);
      }
    }
  }
}
