import '../engine/position.dart';
import 'floor_map.dart';
import 'flow_field.dart';

/// The shortest four-way path from [from] to [to] over walkable tiles.
///
/// Excludes [from] and includes [to], so the result is exactly the list of
/// moves to make. Empty when [to] is unreachable, is not walkable, or is where
/// the walker already stands.
///
/// Built on [computeFlowField] and [flowFieldStep], so the hero's tap-to-walk
/// and the monsters' chase break ties the same way — north, east, south, west —
/// and neither can surprise the other by preferring a different corner.
/// Monsters do not call this: one shared field serves all of them, while the
/// hero wants a whole route it can be interrupted part-way through.
List<Position> findPath(FloorMap map, Position from, Position to) {
  if (!map.isWalkable(to)) return const [];
  final field = computeFlowField(map, to);
  if (!field.containsKey(from)) return const [];
  final path = <Position>[];
  var current = from;
  while (current != to) {
    final next = flowFieldStep(map, field, current, const {});
    if (next == null) return const [];
    path.add(next);
    current = next;
  }
  return path;
}
