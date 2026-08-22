import 'package:equatable/equatable.dart';

import 'node.dart';
import 'world_map.dart';

/// A road the hero is part way along.
///
/// [from] is where the leg started rather than where the hero is, because on a
/// road there is no node to be at — the hero is a day and a half out of
/// Harbour, and the honest way to write that down is the pair of ends and what
/// is left. It is also what a save document holds, so a journey survives a
/// relaunch as the journey it was rather than as the nearest node to it.
class Journey extends Equatable {
  /// Throws [ArgumentError] on a road with nothing left to walk, which is not a
  /// road being walked but an arrival.
  Journey({required this.from, required this.to, required this.daysLeft}) {
    if (daysLeft < 1) {
      throw ArgumentError.value(
        daysLeft,
        'daysLeft',
        'a road being walked has at least a day left on it',
      );
    }
    if (from == to) {
      throw ArgumentError.value(
        from,
        'from',
        'a journey cannot leave and arrive at the same place',
      );
    }
  }

  /// The place this leg started from.
  final NodeId from;

  /// The place this leg ends at.
  final NodeId to;

  /// How many more days of walking there are. At least one.
  ///
  /// **This and [Whereabouts.day] are two numbers on purpose, and a day on the
  /// road may move one without the other.** A quiet day moves both: the world
  /// is a day older and the destination is a day nearer. A day something came
  /// out of the trees moves only the counter — the hero spent the day and
  /// covered no ground. Collapsing the pair into one would make fleeing an
  /// encounter free, because getting away would also have got the hero
  /// somewhere, and the danger roll would stop being a tax on the road and
  /// become an animation the player sits through. See `travelOneDay`.
  final int daysLeft;

  /// This journey, one day nearer, or null when that day was the last.
  Journey? get nearer => daysLeft <= 1
      ? null
      : Journey(from: from, to: to, daysLeft: daysLeft - 1);

  @override
  List<Object?> get props => [from, to, daysLeft];

  @override
  String toString() => 'Journey(${from.value} -> ${to.value}, $daysLeft left)';
}

/// Where the hero is in the world, what day it is, and what of it they know.
///
/// The world's answer to [Profile]: everything about a hero between crawls that
/// is about *place* rather than about the hero themself. It is kept apart from
/// the profile for the reason the profile is kept apart from a game state — the
/// two are read and written by different screens under different rules, and a
/// single object holding both would let a shop move a hero across the map.
///
/// **[at] is where the hero last stood, on a road as well as off one.** A hero
/// mid-journey is not at either end, so [journey] is what says where they
/// really are and [at] is where the leg began. Reading [at] alone on a
/// travelling hero would put them back at the town they left, which is exactly
/// the bug that made the pair worth writing down separately.
class Whereabouts extends Equatable {
  /// Throws [ArgumentError] when the hero stands somewhere they have not heard
  /// of, calls somewhere home they have not heard of, is on a day before the
  /// first one, or is on a road that starts anywhere but [at].
  ///
  /// Everything checkable without a map is checked here. Whether a place
  /// exists, whether a road runs where the journey says it does, and whether
  /// home is really a town are questions only a [WorldMap] can answer, so they
  /// live in the functions that take both.
  Whereabouts({
    required this.at,
    required this.home,
    required Set<NodeId> discovered,
    this.day = 0,
    this.journey,
  }) : discovered = Set.unmodifiable(discovered) {
    if (day < 0) {
      throw ArgumentError.value(day, 'day', 'the world starts on day zero');
    }
    if (!this.discovered.contains(at)) {
      throw ArgumentError.value(
        at,
        'at',
        'the hero cannot stand somewhere they have never heard of',
      );
    }
    if (!this.discovered.contains(home)) {
      throw ArgumentError.value(
        home,
        'home',
        'the hero cannot wake somewhere they have never heard of',
      );
    }
    final leg = journey;
    if (leg != null && leg.from != at) {
      throw ArgumentError.value(
        leg,
        'journey',
        'the road the hero is on has to start where they last stood',
      );
    }
  }

  /// The place the hero stands, or the place the current leg started from.
  final NodeId at;

  /// The town the hero wakes at when a road kills them.
  ///
  /// The last town stood in, not the town they started at. Walking to the
  /// second town and shopping there makes it the place a death sends you back
  /// to, which is what makes going there a commitment rather than an errand.
  final NodeId home;

  /// Everywhere the hero has heard of, and so everywhere they may walk to.
  ///
  /// Unmodifiable: discovery is a rule, and a set the screen could add to would
  /// be a map the player uncovered by looking at it.
  final Set<NodeId> discovered;

  /// How many days the hero has been in the world. Counts up and never back.
  ///
  /// The whole of what a road encounter's seed is drawn from, together with the
  /// world. It never runs backwards, which is why a day cannot be re-rolled.
  ///
  /// **Every day on the road moves this one, including the days that move
  /// nothing else.** It is the counter, not the distance; [Journey.daysLeft] is
  /// the distance, and the two part company on exactly the days a fight
  /// happens. Keeping them apart is what prices fleeing correctly — see
  /// [Journey.daysLeft] for why one number would not.
  final int day;

  /// The road the hero is part way along, or null when they are standing still.
  final Journey? journey;

  /// Whether the hero is on a road rather than at a place.
  bool get isTravelling => journey != null;

  /// This, with [node] heard of.
  ///
  /// Nothing else moves. A rumor tells the hero where somewhere is; it does not
  /// take them there, and it does not cost a day.
  Whereabouts hearingOf(NodeId node) => Whereabouts(
    at: at,
    home: home,
    discovered: {...discovered, node},
    day: day,
    journey: journey,
  );

  /// This, with the hero standing at [node], off any road.
  ///
  /// **Arriving is what uncovers the map.** Every place one road from here is
  /// heard of on arrival, so walking somewhere is always worth something even
  /// when nothing happened on the way. A town arrived at also becomes [home],
  /// because home is wherever the hero last had a bed.
  Whereabouts arrivingAt(WorldMap map, NodeId node) => Whereabouts(
    at: node,
    home: map.nodeAt(node).kind == NodeKind.town ? node : home,
    discovered: {...discovered, node, ...map.adjacentTo(node)},
    day: day,
  );

  /// This, one day further on, on the road it names.
  Whereabouts onDay(int day, {Journey? journey}) => Whereabouts(
    at: at,
    home: home,
    discovered: discovered,
    day: day,
    journey: journey,
  );

  @override
  List<Object?> get props => [
    at,
    home,
    {...discovered.map((node) => node.value)}.toList()..sort(),
    day,
    journey,
  ];

  @override
  String toString() =>
      'Whereabouts(${journey ?? at.value}, day $day, '
      '${discovered.length} known)';
}
