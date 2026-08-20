import '../engine/actor.dart';
import '../engine/position.dart';
import 'floor_map.dart';

/// A dungeon floor ready to be played: its terrain, where the hero arrives, and
/// who is already waiting on it.
///
/// The generator produces geometry; this is geometry with creatures standing on
/// it. Content builds one of these, because only content knows the bestiary.
class Floor {
  const Floor({
    required this.map,
    required this.heroSpawn,
    required this.monsters,
    required this.stairsDown,
  });

  final FloorMap map;

  /// Where the hero arrives on this floor.
  final Position heroSpawn;

  final List<Actor> monsters;

  /// Null exactly on the deepest floor.
  final Position? stairsDown;
}

/// Builds the floor at [depth] for the crawl in progress.
///
/// Descending has to happen inside `step`, which lives in core, but the floor
/// it lands on is made of content — the bestiary, the spawn tables. Rather than
/// invert the dependency rule, the game state carries this closure, supplied by
/// content when the crawl begins. It follows the precedent set by the state's
/// random number generator: a collaborator carried by reference, so the rules
/// can reach it without importing where it came from.
typedef FloorBuilder = Floor Function(int depth);
