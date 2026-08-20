import 'package:residuum_core/core.dart';

/// One line of the message log, or null when the event needs no words.
///
/// [names] maps actor ids to what the log calls them, taken from the state
/// *before* the turn ran — a monster that died this turn is gone from the state
/// but still has to be named in the sentence announcing it.
String? describeEvent(
  GameEvent event,
  Map<String, String> names,
) => switch (event) {
  ActorMoved(:final actorId, :final from, :final to) when actorId == heroId =>
    'You step ${_bearing(from, to)}.',
  ActorMoved() => null,
  MoveBlocked(:final actorId) when actorId == heroId => 'The way is blocked.',
  MoveBlocked() => null,
  AttackHit(:final attackerId, :final targetId, :final damage)
      when attackerId == heroId =>
    'You hit ${_named(names, targetId)} for $damage.',
  AttackHit(:final attackerId, :final damage) =>
    '${_capitalised(_named(names, attackerId))} claws you for $damage.',
  ActorDied(:final actorId) when actorId == heroId => 'You die.',
  ActorDied(:final actorId) => '${_capitalised(_named(names, actorId))} dies.',
  ActorNoticed(:final actorId) =>
    '${_capitalised(_named(names, actorId))} comes into view.',
  Descended(:final newDepth) => 'You descend to depth $newDepth.',
  GameOver() => null,
};

/// The id the hero always answers to.
const String heroId = 'hero';

/// What the log calls every actor in [game], the hero included.
Map<String, String> namesIn(GameState game) => {
  game.hero.id: game.hero.name,
  for (final monster in game.monsters) monster.id: monster.name,
};

String _named(Map<String, String> names, String id) =>
    names[id] ?? 'something in the dark';

String _capitalised(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

String _bearing(Position from, Position to) =>
    from.directionTo(to)?.name ?? 'aside';
