import '../engine/position.dart';
import '../engine/rng.dart';
import 'floor_map.dart';
import 'flow_field.dart';
import 'tile.dart';

/// How wide every patch of road the hero is ambushed on is.
///
/// Fixed rather than a function of anything. A crawl floor grows with depth
/// because descending is meant to feel like going further in; a road fight is
/// the same size every time because it is the same event every time — a few
/// creatures out of the scrub, and a decision about whether to stand.
const int encounterWidth = 15;

/// How deep every patch of road the hero is ambushed on is.
const int encounterHeight = 11;

/// How far from the edge the hero always lands.
///
/// **The whole tension of an encounter is priced here.** Stepping off any edge
/// is how the hero runs, so a hero who spawned on the border could leave before
/// anything had a turn and the danger roll would cost nothing. Three tiles means
/// running is always available and never free: it is three turns of somebody
/// swinging at your back, and that is the decision the screen is asking for.
const int heroInsetFromEdge = 3;

/// How many times [generateEncounter] may re-roll before giving up.
const int maxEncounterAttempts = 8;

/// The ground one road fight happens on, and who is standing on it.
///
/// Deliberately not a [GeneratedFloor]. There are no stairs to be null, no
/// depth to carry and no way down to validate, and a type with three fields
/// that are always absent would invite somebody to start filling them in.
class EncounterGround {
  const EncounterGround({
    required this.map,
    required this.heroSpawn,
    required this.monsterSpawns,
  });

  final FloorMap map;

  /// Where the hero is standing when the fight opens.
  final Position heroSpawn;

  /// Where the creatures are standing, in the order they were placed.
  ///
  /// Unlike a crawl's, these are allowed to be in plain sight. A monster the
  /// hero can see across a crawl floor is an ambush they never got to decline;
  /// on the road the ambush has already happened, and hiding the attackers
  /// would only hide the reason to run.
  final List<Position> monsterSpawns;
}

/// Reports what is wrong with a patch of ground, or null when it is sound.
typedef EncounterProblem =
    String? Function(EncounterGround ground, int monsterCount);

/// Builds the ground for one road fight from [seed], sound or not at all.
///
/// **A second generator, not a setting on the first one.** `generateFloor`
/// sizes itself from a depth, places stairs by depth, and its validator rejects
/// a stairless floor, a walkable border and any monster in sight of the hero —
/// every one of which an encounter needs to be the opposite of. Reaching those
/// through parameters would leave one function whose contract is "one of two
/// unrelated things depending on five flags", and would put the crawl's exact
/// floor layouts one edit away from moving. The two share `FloorMap`, the flow
/// field and the retry shape, and nothing else.
///
/// Open ground with a few things scattered on it. Obstructions stay strictly
/// inside the border, because the border is the way out and a wall on it would
/// be a stretch of edge the hero could not step off.
///
/// **On a validation failure the ground is re-rolled from `seed + attempt`, at
/// most [maxEncounterAttempts] times, and then it throws.** `generateFloor`'s
/// contract verbatim: the player must never be dropped onto broken ground, and
/// a generator that re-rolls for ever is a hang wearing a safety net's coat.
///
/// [monsterCount] is a parameter for the reason `generateFloor`'s is: how many
/// creatures a road carries is a content table, while where they can stand is a
/// property of the ground. They are drawn after the terrain and after the hero,
/// so asking for more of them cannot move the ground under the ones already
/// there.
///
/// [findProblem] is the seam that makes the retry contract testable, for
/// `generateFloor`'s reason: the shipped validator does not fail on real seeds.
EncounterGround generateEncounter(
  int seed, {
  required int monsterCount,
  EncounterProblem findProblem = describeEncounterProblem,
}) {
  var problem = 'no attempt was made';
  for (var attempt = 0; attempt < maxEncounterAttempts; attempt++) {
    final ground = _attemptGround(seed + attempt, monsterCount);
    if (ground == null) {
      problem = 'not enough open ground for $monsterCount creatures';
      continue;
    }
    final found = findProblem(ground, monsterCount);
    if (found == null) return ground;
    problem = found;
  }
  throw StateError(
    'could not lay out ground for $monsterCount creatures from seed $seed '
    'in $maxEncounterAttempts attempts: $problem',
  );
}

/// What is wrong with [ground], or null when nothing is.
///
/// Checks, in order: the map is the one fixed size; no tile is a stairway; every
/// tile of the border is walkable, because the border is the way out; the hero
/// stands on walkable ground far enough in to have to run for it; every walkable
/// tile is reachable from the hero; and the creatures are the right number,
/// distinct, reachable, and not already close enough to be swinging.
///
/// It is the mirror image of `describeFloorProblem` on three counts and says so
/// on purpose — walkable border instead of solid, sight allowed instead of
/// forbidden, no stairs instead of stairs required. Anybody reading the two side
/// by side should be able to see that they disagree deliberately.
String? describeEncounterProblem(EncounterGround ground, int monsterCount) {
  final map = ground.map;
  if (map.width != encounterWidth || map.height != encounterHeight) {
    return 'the ground is ${map.width}x${map.height} and not '
        '${encounterWidth}x$encounterHeight';
  }
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final tile = map.tileAt(Position(x, y));
      if (tile == Tile.stairsDown || tile == Tile.stairsUp) {
        return 'there are stairs at ${Position(x, y)} on a patch of road';
      }
    }
  }
  for (final edge in _borderOf(map)) {
    if (!map.isWalkable(edge)) {
      return 'the way out is blocked at $edge';
    }
  }

  final hero = ground.heroSpawn;
  if (!map.isWalkable(hero)) {
    return 'the hero arrives at $hero, which is not walkable';
  }
  final fromEdge = [
    hero.x,
    hero.y,
    map.width - 1 - hero.x,
    map.height - 1 - hero.y,
  ].reduce((one, other) => one < other ? one : other);
  if (fromEdge < heroInsetFromEdge) {
    return 'the hero arrives $fromEdge from the edge and could leave at once';
  }

  final reachable = computeFlowField(map, hero).keys.toSet();
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final position = Position(x, y);
      if (map.isWalkable(position) && !reachable.contains(position)) {
        return 'the ground is split: $position is walled off from the hero';
      }
    }
  }

  final spawns = ground.monsterSpawns;
  if (spawns.length != monsterCount) {
    return 'wanted $monsterCount creatures, placed ${spawns.length}';
  }
  if (spawns.toSet().length != spawns.length) {
    return 'two creatures share a spawn tile';
  }
  for (final spawn in spawns) {
    if (spawn == hero || spawn.isOrthogonallyAdjacentTo(hero)) {
      return 'the creature at $spawn is already swinging at the hero';
    }
    if (!reachable.contains(spawn)) {
      return 'the creature at $spawn is walled off';
    }
  }
  return null;
}

/// The fewest and most things scattered on one patch of ground.
///
/// Never zero. Bare ground is a fight with nothing to break a line of sight or
/// a charge, which is the one shape of encounter where standing and running are
/// the same decision.
const int _minObstructions = 5;
const int _maxObstructions = 9;

/// The longest run of tiles one obstruction covers.
const int _maxObstructionLength = 3;

EncounterGround? _attemptGround(int seed, int monsterCount) {
  final rng = Rng(seed);
  final tiles = List.generate(
    encounterHeight,
    (y) => List.filled(encounterWidth, Tile.floor),
    growable: false,
  );

  final obstructions = rng.rollRange(_minObstructions, _maxObstructions);
  for (var placed = 0; placed < obstructions; placed++) {
    final x = rng.rollRange(1, encounterWidth - 2);
    final y = rng.rollRange(1, encounterHeight - 2);
    final along =
        Direction.values[rng.rollRange(0, Direction.values.length - 1)];
    final length = rng.rollRange(1, _maxObstructionLength);
    for (var step = 0; step < length; step++) {
      final at = Position(x + along.dx * step, y + along.dy * step);
      if (at.x < 1 ||
          at.y < 1 ||
          at.x > encounterWidth - 2 ||
          at.y > encounterHeight - 2) {
        break;
      }
      tiles[at.y][at.x] = Tile.wall;
    }
  }

  final map = FloorMap.parse(_render(tiles));
  final middle = [
    for (
      var y = heroInsetFromEdge;
      y <= encounterHeight - 1 - heroInsetFromEdge;
      y++
    )
      for (
        var x = heroInsetFromEdge;
        x <= encounterWidth - 1 - heroInsetFromEdge;
        x++
      )
        if (map.isWalkable(Position(x, y))) Position(x, y),
  ];
  if (middle.isEmpty) return null;
  final heroSpawn = middle[rng.rollRange(0, middle.length - 1)];

  final reachable = computeFlowField(map, heroSpawn).keys.toSet();
  final pool = [
    for (final tile in reachable)
      if (tile != heroSpawn && !tile.isOrthogonallyAdjacentTo(heroSpawn)) tile,
  ];
  pool.sort(_readingOrder);
  if (pool.length < monsterCount) return null;
  final monsterSpawns = [
    for (var placed = 0; placed < monsterCount; placed++)
      pool.removeAt(rng.rollRange(0, pool.length - 1)),
  ];

  return EncounterGround(
    map: map,
    heroSpawn: heroSpawn,
    monsterSpawns: monsterSpawns,
  );
}

/// Orders tiles top to bottom and left to right.
///
/// The flow field hands its tiles back in whatever order it happened to reach
/// them, which is a detail of the search and not a property of the ground.
/// Sorting before drawing is what makes one seed lay out one fight — the
/// encoder's argument about sorted positions, in a generator rather than a
/// document.
int _readingOrder(Position one, Position other) =>
    one.y == other.y ? one.x - other.x : one.y - other.y;

Iterable<Position> _borderOf(FloorMap map) sync* {
  for (var x = 0; x < map.width; x++) {
    yield Position(x, 0);
    yield Position(x, map.height - 1);
  }
  for (var y = 1; y < map.height - 1; y++) {
    yield Position(0, y);
    yield Position(map.width - 1, y);
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
              Tile.stairsUp => '<',
            },
          )
          .join(),
    )
    .join('\n');
