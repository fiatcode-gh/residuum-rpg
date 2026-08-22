import 'package:equatable/equatable.dart';

import '../dungeon/generator.dart';
import '../engine/rng.dart';
import 'node.dart';
import 'whereabouts.dart';
import 'world_map.dart';

/// Why the world would not take the hero where they asked to go.
///
/// The road's answer to [TownRefusal], and it exists for that reason: a refused
/// journey changes nothing at all, so the caller gets a sentence rather than a
/// whereabouts it cannot tell apart from one that moved.
class TravelRefusal extends Equatable {
  const TravelRefusal(this.reason);

  /// Written to be read aloud on the screen, not parsed.
  final String reason;

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => 'TravelRefusal($reason)';
}

/// A whereabouts after a travel decision, and the refusal that stopped it, or
/// null.
///
/// The pair mirrors [Transacted], which mirrors `step`'s own: the new value
/// first, whatever the rules had to say second. On a refusal the first element
/// is the whereabouts that went in, unchanged and equal to it.
typedef Travelled = (Whereabouts, TravelRefusal?);

/// Sets the hero walking from where they stand to [destination].
///
/// **Discovered and adjacent, both.** A place the hero has not heard of is not
/// somewhere they can decide to walk to, and a place with no road from here is
/// somewhere they would have to walk through somewhere else to reach — the
/// player picks the legs, because the legs are where the days and the fights
/// are. Neither is a fault; both are ordinary refusals with a sentence.
///
/// Setting out costs no day. The day is spent walking, and a hero who changed
/// their mind before the first step has not been anywhere.
Travelled beginTravel(Whereabouts where, WorldMap map, NodeId destination) {
  if (where.isTravelling) {
    return (where, const TravelRefusal('you are already on the road'));
  }
  if (destination == where.at) {
    return (where, const TravelRefusal('you are already there'));
  }
  if (!where.discovered.contains(destination)) {
    return (where, const TravelRefusal('you have not heard of that place'));
  }
  final road = map.routeBetween(where.at, destination);
  if (road == null) {
    return (where, const TravelRefusal('no road runs there from here'));
  }
  return (
    where.onDay(
      where.day,
      journey: Journey(from: where.at, to: destination, daysLeft: road.days),
    ),
    null,
  );
}

/// What one day on the road turned out to be.
///
/// Three things can happen and no more, which is why this is sealed: the day
/// passed, somebody was on it, or something was. Everything the screen draws
/// and everything the log says forks here, so a fourth kind would be a fourth
/// branch everywhere at once rather than a quiet addition.
sealed class RoadEvent {
  const RoadEvent();
}

/// Nothing happened. Most days are this one.
final class QuietDay extends RoadEvent {
  const QuietDay();

  @override
  String toString() => 'QuietDay()';
}

/// Somebody coming the other way said where [told] is.
///
/// The free half of discovery. A tavern rumor costs gold and is asked for; this
/// is the road giving one away, which is what makes a long walk to the second
/// town pay for itself even when nothing fought the hero on it.
final class TravelerMet extends RoadEvent {
  const TravelerMet(this.told);

  /// The place the hero had not heard of until today.
  final NodeId told;

  @override
  String toString() => 'TravelerMet(${told.value})';
}

/// Something on [road] wants a fight.
final class DangerMet extends RoadEvent {
  const DangerMet(this.road);

  /// The road it happened on, so content knows which danger table to draw from.
  final Route road;

  @override
  String toString() => 'DangerMet(${road.from.value} <-> ${road.to.value})';
}

/// One day walked: where the hero is now, what the day was, and the place they
/// reached if the day finished the leg.
class RoadDay {
  const RoadDay({
    required this.whereabouts,
    required this.event,
    this.arrivedAt,
  });

  final Whereabouts whereabouts;
  final RoadEvent event;

  /// The place the hero reached, or null when there is still road ahead.
  ///
  /// Named rather than left to be worked out from [whereabouts], because
  /// arriving is the thing the screen has to react to and
  /// `journey == null` is also true of a hero who never set out.
  final NodeId? arrivedAt;
}

/// The generator the [day]th day of travel in the world [travelSeed] describes
/// draws from.
///
/// **There is no travel stream, and that is the point.** A stream would be a
/// generator state to write down, and a state written down is a state that can
/// be written down twice — kill the app between the roll and the save and the
/// day comes back a different day. Deriving the day's generator from the world
/// and the day number instead means the answer for day nine is the answer for
/// day nine whatever happened to the process, because the day counter only ever
/// counts up and both halves are already in the save document for their own
/// reasons.
///
/// It borrows [floorSeed]'s mix and the salt precedent `lootStreamSalt` and the
/// market's set: [travelSeed] is the world seed with content's own road salt
/// exclusive-ored in, which is what keeps a road from ever drawing in step with
/// a floor or a shelf. The road is not a depth, and zero is not one either —
/// mixing at a depth the dungeon does not have is the market's argument,
/// holding here for the same reason.
int roadSeed(int travelSeed, int day) => floorSeed(travelSeed, _roadDepth, day);

const int _roadDepth = 0;

/// Walks the hero one day further along the road they are on.
///
/// **A fight costs the day and none of the distance.** A quiet day and a day
/// somebody was met both bring the destination one day nearer; a day something
/// came out of the trees does not. That is what stops fleeing from being free —
/// stepping off the edge of an encounter gets the hero away, and gets them
/// nowhere — and it is why the counter and the leg are two numbers rather than
/// one.
///
/// The day is decided by [roadSeed] on the day being walked, so the same world
/// on the same day always decides the same way. The route's own danger is the
/// only thing the world map contributes, which is what lets a long road be a
/// dangerous one without content pricing that twice.
///
/// [travelerChance] is a parameter rather than a constant for [generateFloor]'s
/// reason about monster counts: how talkative the roads are is a content number,
/// while what a traveler *does* is a rule. The traveler is skipped when the hero
/// has already heard of everywhere, and the day is quiet instead — there is no
/// such thing as being told something you know.
///
/// Requires a hero who is actually on a road. Throws [StateError] otherwise,
/// because a hero standing in a town has no day to walk and a caller asking for
/// one has lost track of where they are — that is a fault in the interface, not
/// a decision the player made, so it is not a [TravelRefusal].
RoadDay travelOneDay(
  Whereabouts where,
  WorldMap map, {
  required int travelSeed,
  required int travelerChance,
}) {
  final leg = where.journey;
  if (leg == null) {
    throw StateError('the hero is not on a road and has no day to walk');
  }
  final road = map.routeBetween(leg.from, leg.to);
  if (road == null) {
    throw StateError(
      'the hero is on a road between ${leg.from.value} and ${leg.to.value} '
      'that this world does not have',
    );
  }
  final day = where.day + 1;
  final rng = Rng(roadSeed(travelSeed, day));

  if (rng.rollRange(1, 100) <= road.danger) {
    return RoadDay(
      whereabouts: where.onDay(day, journey: leg),
      event: DangerMet(road),
    );
  }

  final walked = where.onDay(day, journey: leg.nearer);
  if (rng.rollRange(1, 100) <= travelerChance) {
    final untold = _untold(map, where);
    if (untold.isNotEmpty) {
      final told = untold[rng.rollRange(0, untold.length - 1)];
      return _arriving(map, walked.hearingOf(told), leg, TravelerMet(told));
    }
  }
  return _arriving(map, walked, leg, const QuietDay());
}

/// Everywhere on [map] the hero has not heard of, in one settled order.
///
/// Sorted by id, because the set the hero carries has no order of its own and a
/// rumor drawn out of an unordered set would name a different place on a
/// different run of the same world. It is the encoder's argument about sorting
/// positions, holding for a draw rather than for a document.
List<NodeId> _untold(WorldMap map, Whereabouts where) {
  final untold = [
    for (final node in map.nodes)
      if (!where.discovered.contains(node.id)) node.id,
  ];
  untold.sort((one, other) => one.value.compareTo(other.value));
  return untold;
}

/// [walked], having arrived if the leg it was on is finished.
RoadDay _arriving(
  WorldMap map,
  Whereabouts walked,
  Journey leg,
  RoadEvent event,
) {
  if (walked.isTravelling) {
    return RoadDay(whereabouts: walked, event: event);
  }
  return RoadDay(
    whereabouts: walked.arrivingAt(map, leg.to),
    event: event,
    arrivedAt: leg.to,
  );
}
