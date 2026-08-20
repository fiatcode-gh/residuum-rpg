import 'package:residuum_core/core.dart';

String? describeEvent(GameEvent event) => switch (event) {
  ActorMoved(:final actorId, :final from, :final to) when actorId == 'hero' =>
    'You step ${_bearing(from, to)}.',
  ActorMoved() => null,
  MoveBlocked(:final actorId) when actorId == 'hero' => 'The way is blocked.',
  MoveBlocked() => null,
  AttackHit(:final attackerId, :final damage) when attackerId == 'hero' =>
    'You hit the ghoul for $damage.',
  AttackHit(:final damage) => 'The ghoul claws you for $damage.',
  ActorDied(:final actorId) when actorId == 'hero' => 'You die.',
  ActorDied() => 'The ghoul dies.',
  GameOver() => null,
};

String _bearing(Position from, Position to) =>
    from.directionTo(to)?.name ?? 'aside';
