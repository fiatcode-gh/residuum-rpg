import 'package:flutter/rendering.dart' show Offset;
import 'package:residuum_core/core.dart';

import 'game_bloc.dart' show GameViewState;
import 'grid_geometry.dart';

/// The touch radius PLAN.md G7 names, in dp: what "near enough to mean this
/// monster" is, amended by A1 to a 48 dp target.
const double mapTouchRadius = 24;

/// What a map tap or long-press resolves to, once the touch point's
/// distance from every candidate monster is weighed against the cell the
/// finger actually landed on.
sealed class MapTouch {
  const MapTouch();
}

/// The touch means a tile: a move, a bump, a cast, or whatever the bloc
/// decides a tap on [position] means today.
final class MapTouchCell extends MapTouch {
  const MapTouchCell(this.position);
  final Position position;
}

/// The touch means "tell me about this monster", at no turn cost.
final class MapTouchInspect extends MapTouch {
  const MapTouchInspect(this.actor);
  final Actor actor;
}

/// The touch means nothing: no known target nearby, no cell under the
/// finger.
final class MapTouchNothing extends MapTouch {
  const MapTouchNothing();
}

/// The member of [candidates] within [mapTouchRadius] of [distanceOf], with
/// the smallest distance; ties break by [byRowThenColumn] on position, then
/// by id. `null` when nothing qualifies.
Actor? _nearest(
  Iterable<Actor> candidates,
  double Function(Position) distanceOf,
) {
  Actor? best;
  var bestDistance = double.infinity;
  for (final actor in candidates) {
    final distance = distanceOf(actor.position);
    if (distance > mapTouchRadius) continue;
    if (best == null || distance < bestDistance) {
      best = actor;
      bestDistance = distance;
      continue;
    }
    if (distance == bestDistance) {
      final order = byRowThenColumn(actor.position, best.position);
      if (order < 0 || (order == 0 && actor.id.compareTo(best.id) < 0)) {
        best = actor;
      }
    }
  }
  return best;
}

/// The monsters [state]'s hero currently knows about: visible, with a
/// resolvable presentation.
Iterable<Actor> _known(GameViewState state) =>
    state.game.monsters.where((m) => state.inspectTargetAt(m.position) != null);

/// A bump on an adjacent monster, or the sheet on a distant one: identical
/// for a tap and a long-press once a monster is chosen.
MapTouch _meleeOrInspect(Actor actor, Position hero) =>
    actor.position.isOrthogonallyAdjacentTo(hero)
    ? MapTouchCell(actor.position)
    : MapTouchInspect(actor);

/// Resolves a map tap by intent: PLAN.md §2 G7. Armed casts at the marked
/// monster the finger is nearest to (or under); bare, a tap melees or
/// inspects the known monster it means, steps the hero toward a nearby one,
/// or falls back to the tile under the finger.
MapTouch resolveMapTap(
  GameViewState state,
  GridGeometry geometry,
  Offset local,
) {
  final game = state.game;
  final hero = game.hero.position;
  final under = geometry.positionAt(local);
  double dist(Position p) => (local - geometry.centreOf(p)).distance;

  if (state.armedSpellId != null) {
    final legalIds = state.armedTargets;
    if (under != null) {
      final monsterUnder = game.monsterAt(under);
      if (monsterUnder != null && legalIds.contains(monsterUnder.id)) {
        return MapTouchCell(under);
      }
    }
    final legal = game.monsters.where((m) => legalIds.contains(m.id));
    final nearestLegal = _nearest(legal, dist);
    if (nearestLegal != null) return MapTouchCell(nearestLegal.position);
    if (under != null) return MapTouchCell(under);
    return const MapTouchNothing();
  }

  if (under != null) {
    final monster = state.inspectTargetAt(under);
    if (monster != null) return _meleeOrInspect(monster, hero);
  }
  if (under != null && under.isOrthogonallyAdjacentTo(hero)) {
    return MapTouchCell(under);
  }
  final nearestKnown = _nearest(_known(state), dist);
  if (nearestKnown != null) return _meleeOrInspect(nearestKnown, hero);
  if (dist(hero) <= mapTouchRadius && under != hero) {
    final heroCentre = geometry.centreOf(hero);
    final u = (local.dx - heroCentre.dx) / mapCellWidth;
    final v = (local.dy - heroCentre.dy) / mapCellHeight;
    final direction = u.abs() >= v.abs()
        ? (u >= 0 ? Direction.east : Direction.west)
        : (v >= 0 ? Direction.south : Direction.north);
    final target = hero.step(direction);
    if (game.map.inBounds(target)) return MapTouchCell(target);
  }
  if (under != null) return MapTouchCell(under);
  return const MapTouchNothing();
}

/// Resolves a map long-press: the nearest known monster, if any, else
/// nothing. Never a cell — a long-press never moves the hero.
MapTouch resolveMapLongPress(
  GameViewState state,
  GridGeometry geometry,
  Offset local,
) {
  final under = geometry.positionAt(local);
  double dist(Position p) => (local - geometry.centreOf(p)).distance;
  if (under != null) {
    final monster = state.inspectTargetAt(under);
    if (monster != null) return MapTouchInspect(monster);
  }
  final nearest = _nearest(_known(state), dist);
  if (nearest != null) return MapTouchInspect(nearest);
  return const MapTouchNothing();
}
