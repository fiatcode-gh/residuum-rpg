import 'package:residuum_core/core.dart';

/// The home town, discovered from the first save.
NodeId get harbour => NodeId('harbour');

/// The second town, hidden until something reveals it.
NodeId get ridge => NodeId('ridge');

/// The dungeon node, discovered from the first save.
NodeId get crypt => NodeId('crypt');

/// A triangle: two towns and a dungeon, every pair joined by one road.
///
/// A triangle rather than a line, so that adjacency reveal and rumors both have
/// work to do — every place is one road from every other, and hiding one of
/// them is the only thing that makes the map worth uncovering.
WorldMap smallWorld() => WorldMap(
  nodes: [
    WorldNode(id: harbour, kind: NodeKind.town, name: 'Harbour'),
    WorldNode(id: ridge, kind: NodeKind.town, name: 'Ridge'),
    WorldNode(id: crypt, kind: NodeKind.dungeon, name: 'The Crypt'),
  ],
  routes: [
    Route(from: harbour, to: crypt, days: 1, danger: 20),
    Route(from: harbour, to: ridge, days: 2, danger: 30),
    Route(from: ridge, to: crypt, days: 2, danger: 30),
  ],
);

/// A hero standing at the home town on day zero, knowing only what a fresh save
/// knows.
Whereabouts atHome() =>
    Whereabouts(at: harbour, home: harbour, discovered: {harbour, crypt});
