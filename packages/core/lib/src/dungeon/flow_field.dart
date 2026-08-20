import 'dart:collection';

import '../engine/position.dart';
import 'floor_map.dart';

/// The order neighbours are considered in when two of them are equally good.
///
/// Fixed, so a chase is a property of the map rather than of iteration order:
/// the same seed replays the same pursuit, tile for tile.
const List<Direction> chaseOrder = [
  Direction.north,
  Direction.east,
  Direction.south,
  Direction.west,
];

/// Breadth-first distance in tiles from [goal], over walkable tiles.
///
/// The goal itself reads zero and every walkable tile reachable from it carries
/// the number of orthogonal steps it takes to get there. Unreachable tiles and
/// walls carry no entry at all, so a lookup that misses means "there is no way
/// from here" — a walled-off monster reads nothing and stands still.
///
/// Monsters chase down this one shared field rather than each pathfinding for
/// themselves. Three reasons: n monsters cost one sweep instead of n; every
/// monster reads the same numbers, so a pack never disagrees about the route;
/// and a monster walking down the field cannot oscillate between two tiles the
/// way a per-monster greedy chase does when a wall sits between it and the
/// hero.
///
/// That last property comes from the grid, not from any comparison in the
/// movement rule. A four-way grid is bipartite — colour tiles by the parity of
/// `x + y` and every step changes colour — so two orthogonally adjacent
/// reachable tiles can never share a distance: they differ by exactly one.
/// Every neighbour is therefore either one closer or one further, never level,
/// and a chase that declines to step further away must strictly approach.
Map<Position, int> computeFlowField(FloorMap map, Position goal) {
  final field = <Position, int>{goal: 0};
  final frontier = Queue<Position>()..add(goal);
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    final next = field[current]! + 1;
    for (final direction in chaseOrder) {
      final neighbour = current.step(direction);
      if (!map.isWalkable(neighbour) || field.containsKey(neighbour)) continue;
      field[neighbour] = next;
      frontier.add(neighbour);
    }
  }
  return field;
}

/// The tile an actor at [from] moves to when chasing down [field], or null when
/// it should stand still.
///
/// The rule is: the orthogonal neighbour with the **strictly** smallest field
/// value that is walkable and not in [occupied], ties broken in [chaseOrder].
/// Standing still when nothing improves is what lets a pack queue up in a
/// corridor instead of shuffling.
///
/// The strict comparison is not what forbids oscillation — see
/// [computeFlowField]; the grid's bipartiteness already guarantees that. Its
/// real job is the tie-break. Every improving neighbour sits at exactly one
/// less than the current tile, so several can be equally good; comparing
/// strictly against the best found so far keeps the **first** in [chaseOrder]
/// and discards the rest. Relaxing it to "no worse" would silently hand the
/// win to the *last* candidate instead, reversing the pursuit direction on
/// every tie while leaving every path still monotonically closing.
Position? flowFieldStep(
  FloorMap map,
  Map<Position, int> field,
  Position from,
  Set<Position> occupied,
) {
  final here = field[from];
  if (here == null) return null;
  Position? best;
  var bestDistance = here;
  for (final direction in chaseOrder) {
    final neighbour = from.step(direction);
    final distance = field[neighbour];
    if (distance == null || distance >= bestDistance) continue;
    if (!map.isWalkable(neighbour) || occupied.contains(neighbour)) continue;
    best = neighbour;
    bestDistance = distance;
  }
  return best;
}
