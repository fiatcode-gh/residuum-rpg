import '../engine/actor.dart';
import '../engine/position.dart';

/// The monster a targeted spell lands on, or null when none is in sight.
///
/// **A rule rather than a tap, and that is a design decision.** Nothing in the
/// interface can point at a tile — a tap beyond arm's reach is a walk order —
/// so a spell that asked the player to choose would need a targeting mode
/// carried by every handler that rebuilds the view state, which is every one of
/// them. A rule the player can learn is cheaper and, once learned, faster: the
/// nearest thing you can see is what you were going to pick anyway.
///
/// **It draws nothing.** The whole game's spine is a seeded stream, and a target
/// chosen at random would put a roll on the front of every cast — so ties are
/// broken by [byRowThenColumn] on the target's tile, which is a total order over
/// tiles and therefore a total order over candidates. Two identical crawls burn
/// the same ghoul.
///
/// Distance is Chebyshev; see [Position.chebyshevTo] for why a bolt does not
/// measure in walked steps.
Actor? nearestVisibleEnemy(
  List<Actor> monsters,
  Set<Position> visible,
  Position from,
) {
  Actor? nearest;
  var shortest = 0;
  for (final monster in monsters) {
    if (!visible.contains(monster.position)) continue;
    final distance = from.chebyshevTo(monster.position);
    if (nearest == null || distance < shortest) {
      nearest = monster;
      shortest = distance;
      continue;
    }
    if (distance == shortest &&
        byRowThenColumn(monster.position, nearest.position) < 0) {
      nearest = monster;
    }
  }
  return nearest;
}
