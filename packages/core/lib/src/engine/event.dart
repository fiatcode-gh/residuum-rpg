import 'package:equatable/equatable.dart';

import '../craft/gather_node.dart';
import '../craft/material.dart';
import '../loot/equip_slot.dart';
import '../loot/item.dart';
import '../magic/spell.dart';
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

/// The hero read a book and knows a spell it did not know before.
///
/// The book is gone by the time this is emitted: learning is what spends it,
/// and there is no state in which the hero both knows the spell and still holds
/// the page. It is carried here anyway, whole, for [PotionDrunk]'s reason — the
/// log has to name the thing that was used up, and it can no longer be looked
/// up anywhere.
final class SpellLearned extends GameEvent with Equatable {
  const SpellLearned({required this.book, required this.spell});

  final Item book;
  final Spell spell;

  @override
  List<Object?> get props => [book, spell];

  @override
  String toString() => 'SpellLearned(${book.id}, ${spell.id})';
}

/// A bolt landed on a monster for [damage], after its make-up had its say.
///
/// [damage] is what the target actually lost, so the log never has to redo the
/// arithmetic; [bite] is why that number differs from the roll, and it is
/// carried rather than derived because the message layer has no bestiary to
/// look the creature up in.
final class SpellHit extends GameEvent with Equatable {
  const SpellHit({
    required this.spell,
    required this.targetId,
    required this.damage,
    required this.bite,
  });

  final Spell spell;
  final String targetId;
  final int damage;
  final SpellBite bite;

  @override
  List<Object?> get props => [spell, targetId, damage, bite];

  @override
  String toString() =>
      'SpellHit(${spell.id} -> $targetId, $damage, ${bite.name})';
}

/// The hero mended itself for [healed] hit points.
///
/// [healed] can be zero: mending at full health spends the mana and the turn
/// for nothing, which is the potion's doctrine and not the rules' to undo.
final class MendCast extends GameEvent with Equatable {
  const MendCast({required this.healed});

  final int healed;

  @override
  List<Object?> get props => [healed];

  @override
  String toString() => 'MendCast($healed)';
}

/// A ward now stands, holding [absorbs] damage.
///
/// Emitted on every successful cast, including one over a ward already standing:
/// the new pool replaces what was left rather than adding to it, and the log
/// says the new number so the player can see what they traded away.
final class WardRaised extends GameEvent with Equatable {
  const WardRaised({required this.absorbs});

  final int absorbs;

  @override
  List<Object?> get props => [absorbs];

  @override
  String toString() => 'WardRaised($absorbs)';
}

/// A ward took [absorbed] of a blow, and has [remaining] left in it.
final class WardStruck extends GameEvent with Equatable {
  const WardStruck({required this.absorbed, required this.remaining});

  final int absorbed;
  final int remaining;

  @override
  List<Object?> get props => [absorbed, remaining];

  @override
  String toString() => 'WardStruck($absorbed, $remaining left)';
}

/// A monster is held still for [turns] of its own turns.
final class MonsterBound extends GameEvent with Equatable {
  const MonsterBound({required this.targetId, required this.turns});

  final String targetId;
  final int turns;

  @override
  List<Object?> get props => [targetId, turns];

  @override
  String toString() => 'MonsterBound($targetId, $turns)';
}

/// The hero worked a node, and it is not there any more.
///
/// [material] is carried rather than read back off [kind], for [PotionDrunk]'s
/// reason: the thing is gone by the time anyone reads this, and the message
/// layer should not have to look up what a vein used to give.
final class NodeGathered extends GameEvent with Equatable {
  const NodeGathered({
    required this.kind,
    required this.at,
    required this.material,
  });

  final GatherKind kind;

  /// The tile it was on, which is the tile the hero is standing on.
  final Position at;

  /// What the hero has one more of.
  final MaterialId material;

  @override
  List<Object?> get props => [kind, at, material];

  @override
  String toString() => 'NodeGathered(${kind.name}, at $at)';
}

/// A monster was moved elsewhere on the floor.
///
/// It is not gone: it is somewhere else on the same floor, and it is coming
/// back. What banishing buys is the turns that takes.
final class MonsterBanished extends GameEvent with Equatable {
  const MonsterBanished({
    required this.targetId,
    required this.from,
    required this.to,
  });

  final String targetId;
  final Position from;
  final Position to;

  @override
  List<Object?> get props => [targetId, from, to];

  @override
  String toString() => 'MonsterBanished($targetId, $from -> $to)';
}

/// The hero held ground: the turn passed and nothing else changed.
///
/// The one event that names no change, because no change happened — the world
/// simply got a turn. Everything the turn cost is already true of the state
/// the event rides with.
final class HeroWaited extends GameEvent with Equatable {
  const HeroWaited();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => 'HeroWaited()';
}
