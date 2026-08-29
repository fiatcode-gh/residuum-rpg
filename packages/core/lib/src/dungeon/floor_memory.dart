import '../craft/gather_node.dart';
import '../engine/actor.dart';
import '../engine/position.dart';
import '../loot/item.dart';
import 'floor_map.dart';

/// Everything a floor keeps while the hero is somewhere else.
///
/// **Monsters freeze rather than carry on.** There is no fair way to run a
/// floor the hero is not standing on: every rule that decides where a monster
/// goes is a question about where the hero is, and with the hero gone the
/// question has no answer. Any substitute — wander at random, drift home, heal
/// up — is a rule invented to fill a silence, and it would make the floor the
/// player walks back onto a different floor from the one they left, for reasons
/// they never got to watch. Frozen time is the honest choice and the
/// deterministic one: what you left is what is waiting.
///
/// Energy is snapshotted with the rest, and deliberately not zeroed. A monster
/// holding a turn it has not spent is an ordinary mid-floor state — the speed
/// clock stops the moment the hero comes due, so it routinely leaves monsters
/// over the threshold — and clearing it on the way out would quietly hand the
/// player a free turn for every floor they had walked away from.
///
/// The terrain is kept here too. It is static, so it could have been rebuilt
/// from the seed instead; keeping it means restoring a floor never runs the
/// generator at all, and a restore that cannot regenerate cannot accidentally
/// reshuffle.
class FloorMemory {
  FloorMemory({
    required this.map,
    required List<Actor> monsters,
    required Map<Position, List<Item>> groundItems,
    required Set<Position> explored,
    required this.stairsDown,
    required this.stairsUp,
    Map<Position, GatherKind> nodes = const {},
  }) : monsters = List.unmodifiable(monsters),
       nodes = Map.unmodifiable(nodes),
       groundItems = Map.unmodifiable({
         for (final tile in groundItems.entries)
           tile.key: List<Item>.unmodifiable(tile.value),
       }),
       explored = Set.unmodifiable(explored);

  final FloorMap map;

  /// Living monsters, at the positions, hit points and energies they held.
  final List<Actor> monsters;

  final Map<Position, List<Item>> groundItems;

  /// What is still there to be worked on this floor.
  ///
  /// A worked node is gone from here for the rest of the run, which is
  /// [groundItems]' lifetime exactly: a floor the hero stripped stays stripped
  /// until the next entry reshuffles the dungeon. Optional with a default,
  /// unlike its siblings, because seventy-odd rule tests build a floor memory to
  /// ask one question about monsters and none of them is about gathering.
  final Map<Position, GatherKind> nodes;

  /// What the hero had seen of this floor.
  ///
  /// Explored belongs to a floor and not to a crawl. A single set spanning five
  /// floors would light up tiles on the floor below at the coordinates of a
  /// room the hero happened to have walked through above it, which is not fog
  /// of war lifting but the map lying.
  final Set<Position> explored;

  /// Null exactly on the deepest floor.
  final Position? stairsDown;

  /// Null exactly on depth one.
  final Position? stairsUp;

  @override
  String toString() =>
      'FloorMemory(${monsters.length} monsters, ${explored.length} explored)';
}
