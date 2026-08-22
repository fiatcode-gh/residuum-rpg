import 'package:residuum_core/core.dart';

/// One line of the travel log for a day that has been walked.
///
/// The road's answer to `describeEvent`, and it exists for the same reason: what
/// happened is a value the rules produced, and turning it into a sentence is the
/// interface's business. [map] is here to turn a node id into the name a person
/// would say.
String describeRoadDay(RoadDay walked, WorldMap map) {
  final day = walked.whereabouts.day;
  final arrival = walked.arrivedAt;
  final event = switch (walked.event) {
    QuietDay() => 'The road is quiet.',
    TravelerMet(:final told) =>
      'A traveler stops to talk. They speak of ${map.nodeAt(told).name}.',
    DangerMet() => 'Something comes out of the scrub.',
  };
  if (arrival == null) return 'Day $day. $event';
  return 'Day $day. $event You reach ${map.nodeAt(arrival).name}.';
}

/// What the log says when the hero sets out.
String describeSettingOut(WorldMap map, Journey journey) {
  final days = journey.daysLeft == 1 ? 'a day' : '${journey.daysLeft} days';
  return 'You set out for ${map.nodeAt(journey.to).name}, $days away.';
}

/// What the log says when the hero walks away from a fight.
const String fledOnTheRoad = 'You get away, no further along than you were.';

/// What the log says when the hero wins one.
const String wonOnTheRoad = 'The road is yours again.';

/// What the log says when the road kills the hero.
String describeWakingAtHome(WorldMap map, NodeId home) =>
    'You wake in ${map.nodeAt(home).name} with nothing but what you wore.';
