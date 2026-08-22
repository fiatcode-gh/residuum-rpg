import 'package:equatable/equatable.dart';

import '../loot/equip_slot.dart';
import '../loot/item.dart';
import '../skills/skill.dart';
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

/// The hero took the stairs and arrived on a shallower floor.
final class Ascended extends GameEvent with Equatable {
  const Ascended({required this.newDepth});

  final int newDepth;

  @override
  List<Object?> get props => [newDepth];

  @override
  String toString() => 'Ascended(to $newDepth)';
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

/// An item landed on the floor: a kill spilled it, or the hero put it down.
final class ItemDropped extends GameEvent with Equatable {
  const ItemDropped({required this.item, required this.at});

  final Item item;
  final Position at;

  @override
  List<Object?> get props => [item, at];

  @override
  String toString() => 'ItemDropped(${item.id}, at $at)';
}

/// The hero picked something up off the floor.
final class ItemPickedUp extends GameEvent with Equatable {
  const ItemPickedUp({required this.item});

  final Item item;

  @override
  List<Object?> get props => [item];

  @override
  String toString() => 'ItemPickedUp(${item.id})';
}

/// The hero is carrying all it can and left the item where it lay.
final class InventoryFull extends GameEvent with Equatable {
  const InventoryFull();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'InventoryFull()';
}

/// The hero put something on.
final class ItemEquipped extends GameEvent with Equatable {
  const ItemEquipped({required this.item, required this.slot});

  final Item item;
  final EquipSlot slot;

  @override
  List<Object?> get props => [item, slot];

  @override
  String toString() => 'ItemEquipped(${item.id}, ${slot.name})';
}

/// The hero took something off, whether by choice or displaced by other gear.
final class ItemUnequipped extends GameEvent with Equatable {
  const ItemUnequipped({required this.item, required this.slot});

  final Item item;
  final EquipSlot slot;

  @override
  List<Object?> get props => [item, slot];

  @override
  String toString() => 'ItemUnequipped(${item.id}, ${slot.name})';
}

/// The rules would not even try what was asked, and said why.
///
/// A refusal is not a turn: nothing changed and no monster acted. It covers
/// every control the interface should not have offered — wearing what the hero
/// is not carrying, taking what is not there, climbing stairs that are not
/// underfoot.
final class ActionRefused extends GameEvent with Equatable {
  const ActionRefused({required this.reason});

  /// Written to be read aloud in the log, not parsed.
  final String reason;

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => 'ActionRefused($reason)';
}

/// The hero drank a potion and got [healed] hit points back.
///
/// [healed] can be zero: drinking at full health wastes the potion.
final class PotionDrunk extends GameEvent with Equatable {
  const PotionDrunk({required this.item, required this.healed});

  final Item item;
  final int healed;

  @override
  List<Object?> get props => [item, healed];

  @override
  String toString() => 'PotionDrunk(${item.id}, $healed)';
}

/// A swing at the hero missed entirely.
final class AttackDodged extends GameEvent with Equatable {
  const AttackDodged({required this.attackerId});

  final String attackerId;

  @override
  List<Object?> get props => [attackerId];

  @override
  String toString() => 'AttackDodged($attackerId)';
}

/// The hero walked off the edge of a road fight and got away.
///
/// Only ever emitted in an encounter, because only there is the grid edge
/// somewhere a hero can stand. It ends the fight where it is: nothing is
/// resolved, nothing is cleared, and the road the hero was walking is exactly
/// as long as it was. Getting away is not getting anywhere.
final class Fled extends GameEvent with Equatable {
  const Fled();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'Fled()';
}

/// A skill crossed into a new level by being used.
final class SkillLevelledUp extends GameEvent with Equatable {
  const SkillLevelledUp({required this.skill, required this.level});

  final SkillId skill;

  /// The level just reached.
  final int level;

  @override
  List<Object?> get props => [skill, level];

  @override
  String toString() => 'SkillLevelledUp(${skill.name}, $level)';
}
