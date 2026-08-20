import 'package:equatable/equatable.dart';

import 'position.dart';

/// Something that happened during a turn.
///
/// Events are value objects so tests can assert on them directly, and they are
/// the only channel by which the message log, the renderer and later the quest
/// triggers learn what the rules did.
sealed class GameEvent {
  const GameEvent();
}

/// An actor walked from one tile to another.
final class ActorMoved extends GameEvent with Equatable {
  const ActorMoved({
    required this.actorId,
    required this.from,
    required this.to,
  });

  final String actorId;
  final Position from;
  final Position to;

  @override
  List<Object?> get props => [actorId, from, to];

  @override
  String toString() => 'ActorMoved($actorId, $from -> $to)';
}

/// An actor tried to walk into something it could not enter.
final class MoveBlocked extends GameEvent with Equatable {
  const MoveBlocked({required this.actorId, required this.at});

  final String actorId;
  final Position at;

  @override
  List<Object?> get props => [actorId, at];

  @override
  String toString() => 'MoveBlocked($actorId, at $at)';
}

/// An attack landed for [damage] hit points.
final class AttackHit extends GameEvent with Equatable {
  const AttackHit({
    required this.attackerId,
    required this.targetId,
    required this.damage,
  });

  final String attackerId;
  final String targetId;
  final int damage;

  @override
  List<Object?> get props => [attackerId, targetId, damage];

  @override
  String toString() => 'AttackHit($attackerId -> $targetId, $damage)';
}

/// An actor ran out of hit points.
final class ActorDied extends GameEvent with Equatable {
  const ActorDied({required this.actorId});

  final String actorId;

  @override
  List<Object?> get props => [actorId];

  @override
  String toString() => 'ActorDied($actorId)';
}

/// The hero took the stairs and arrived on a deeper floor.
final class Descended extends GameEvent with Equatable {
  const Descended({required this.newDepth});

  final int newDepth;

  @override
  List<Object?> get props => [newDepth];

  @override
  String toString() => 'Descended(to $newDepth)';
}

/// A monster the hero could not see at the start of the turn is in sight now.
///
/// Emitted once, on the turn sight is gained, whether the monster walked into
/// view or the hero walked into view of it. It is what turns "something moved
/// out there" into a line in the log and a reason to stop walking.
final class ActorNoticed extends GameEvent with Equatable {
  const ActorNoticed({required this.actorId, required this.at});

  final String actorId;
  final Position at;

  @override
  List<Object?> get props => [actorId, at];

  @override
  String toString() => 'ActorNoticed($actorId, at $at)';
}

/// The crawl is over: the hero is dead.
final class GameOver extends GameEvent with Equatable {
  const GameOver();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'GameOver()';
}
