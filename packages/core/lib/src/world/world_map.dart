import 'package:equatable/equatable.dart';

import 'node.dart';

/// One road between two places, with what it costs to walk and what it risks.
///
/// **A road runs both ways.** [from] and [to] are how it is written down, not a
/// direction of travel: [joins] answers without caring which end is named
/// first, and the map refuses a second road between the same pair so there is
/// never a fast way out and a slow way back that nobody meant to build.
class Route extends Equatable {
  /// Throws [ArgumentError] on a road of less than a day, a road that leaves
  /// and arrives at the same place, or a danger that is not a chance in a
  /// hundred.
  Route({
    required this.from,
    required this.to,
    required this.days,
    this.danger = 0,
  }) {
    if (days < 1) {
      throw ArgumentError.value(days, 'days', 'a road takes at least a day');
    }
    if (from == to) {
      throw ArgumentError.value(
        from,
        'from',
        'a road cannot leave and arrive at the same place',
      );
    }
    if (danger < 0 || danger > 100) {
      throw ArgumentError.value(
        danger,
        'danger',
        'must be a chance in a hundred',
      );
    }
  }

  final NodeId from;
  final NodeId to;

  /// How many days walking this road takes. At least one.
  ///
  /// Days rather than distance, because a day is the unit everything else on
  /// the road is priced in: one encounter roll, one line in the log, one tick
  /// of the counter a save writes down.
  final int days;

  /// The chance in a hundred that any one day on this road is a fight.
  ///
  /// Per day, not per journey, so a longer road is a more dangerous one
  /// without content having to price that twice.
  final int danger;

  /// Whether this road joins [one] and [other], in either order.
  bool joins(NodeId one, NodeId other) =>
      (from == one && to == other) || (from == other && to == one);

  /// The end of this road that is not [end].
  ///
  /// Throws [ArgumentError] when [end] is neither end, because a caller asking
  /// that has a road it did not check against a place it did not check.
  NodeId otherEnd(NodeId end) {
    if (end == from) return to;
    if (end == to) return from;
    throw ArgumentError.value(end, 'end', 'is not an end of this road');
  }

  @override
  List<Object?> get props => [from, to, days, danger];

  @override
  String toString() => 'Route(${from.value} <-> ${to.value}, $days days)';
}

/// Every place in the world and every road between them.
///
/// Immutable and self-validating, for [FloorMap]'s reason: the screen, the
/// travel rules and the save codec all read this, and a map that was wrong
/// would be wrong in three places at once. Everything checkable is checked
/// once, here, when it is built — so nothing downstream has to ask again.
///
/// **Connected, not merely non-empty.** A place no road reaches is a place the
/// player can be told about by a rumor and then never walk to, which reads as a
/// bug in the tavern rather than a hole in the map.
class WorldMap extends Equatable {
  /// Throws [ArgumentError] on an empty world, two places under one id, a road
  /// to a place that is not here, a second road between one pair, or a place
  /// nothing reaches.
  WorldMap({required List<WorldNode> nodes, required List<Route> routes})
    : nodes = List.unmodifiable(nodes),
      routes = List.unmodifiable(routes) {
    if (this.nodes.isEmpty) {
      throw ArgumentError.value(nodes, 'nodes', 'a world needs places in it');
    }
    final ids = <NodeId>{};
    for (final node in this.nodes) {
      if (!ids.add(node.id)) {
        throw ArgumentError.value(
          node.id,
          'nodes',
          'two places are filed under one id',
        );
      }
    }
    for (final route in this.routes) {
      for (final end in [route.from, route.to]) {
        if (!ids.contains(end)) {
          throw ArgumentError.value(
            end,
            'routes',
            'a road runs to a place that is not on the map',
          );
        }
      }
    }
    for (var index = 0; index < this.routes.length; index++) {
      for (var other = index + 1; other < this.routes.length; other++) {
        final road = this.routes[other];
        if (this.routes[index].joins(road.from, road.to)) {
          throw ArgumentError.value(
            road,
            'routes',
            'two roads join the same pair of places',
          );
        }
      }
    }
    if (_reachableFrom(this.nodes.first.id).length != ids.length) {
      throw ArgumentError.value(
        routes,
        'routes',
        'a place on the map has no road to it',
      );
    }
  }

  final List<WorldNode> nodes;
  final List<Route> routes;

  /// The place filed under [id].
  ///
  /// Throws [ArgumentError] when nothing answers to it, following
  /// `creatureById`: a typo in a rumor or a route fails the content validation
  /// suite rather than the game.
  WorldNode nodeAt(NodeId id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    throw ArgumentError.value(id, 'id', 'no such place');
  }

  /// Every place one road away from [id].
  Set<NodeId> adjacentTo(NodeId id) => {
    for (final route in routes)
      if (route.from == id || route.to == id) route.otherEnd(id),
  };

  /// The road joining [one] and [other], or null when none does.
  ///
  /// Null rather than a throw, because "can the hero walk there from here" is a
  /// question the travel rules ask about places the player chose, and the
  /// answer no is an ordinary refusal rather than a fault.
  Route? routeBetween(NodeId one, NodeId other) {
    if (one == other) return null;
    for (final route in routes) {
      if (route.joins(one, other)) return route;
    }
    return null;
  }

  Set<NodeId> _reachableFrom(NodeId start) {
    final seen = {start};
    final pending = [start];
    while (pending.isNotEmpty) {
      for (final next in adjacentTo(pending.removeLast())) {
        if (seen.add(next)) pending.add(next);
      }
    }
    return seen;
  }

  @override
  List<Object?> get props => [nodes, routes];

  @override
  String toString() =>
      'WorldMap(${nodes.length} places, ${routes.length} roads)';
}
