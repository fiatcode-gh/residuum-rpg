import '../engine/actor.dart';
import '../engine/game_state.dart';
import 'equip_slot.dart';
import 'item.dart';
import 'loadout.dart';

/// Why the rules will not put the carried item [itemId] on, or null when they
/// will.
///
/// The reason is a sentence written to be read aloud, and it is deliberately a
/// plain string rather than an event or a refusal object: the dungeon wraps it in
/// an `ActionRefused` and the town wraps it in a `TownRefusal`, so the rule and
/// the words it refuses in have one home while each context keeps its own
/// answer type.
String? wearRefusal(Loadout loadout, List<Item> inventory, String itemId) {
  final item = _find(inventory, itemId);
  if (item == null) return 'you are not carrying that';
  final slot = item.base.slot;
  if (slot == null) return '${item.base.name} is not worn';
  if (slot == EquipSlot.offHand && loadout.wieldsTwoHanded) {
    return 'both hands are on the weapon';
  }
  return null;
}

/// Why the rules will not take the piece in [slot] off, or null when they will.
String? takeOffRefusal(
  Equipment equipment,
  List<Item> inventory,
  EquipSlot slot,
) {
  if (!equipment.containsKey(slot)) return 'nothing is on your ${slot.name}';
  if (inventory.length >= inventoryCap) {
    return 'your hands are too full to stow it';
  }
  return null;
}

/// What the hero wears and carries after one piece moved, and which pieces
/// moved.
///
/// [taken] is in the order the pieces must be announced in, which is why it is a
/// list rather than a set: the message log is the player's record of what
/// happened, and a two-hander that displaces a weapon and a shield has to read
/// in the order the hero would have done it.
class Worn {
  const Worn({
    required this.equipment,
    required this.inventory,
    required this.taken,
    required this.put,
  });

  final Equipment equipment;
  final List<Item> inventory;

  /// The pieces that came off, in the order they must be announced.
  final List<(Item, EquipSlot)> taken;

  /// The piece that went on, or null when nothing did.
  final (Item, EquipSlot)? put;
}

/// Puts the carried item [itemId] in its slot, displacing what it cannot share a
/// body with.
///
/// A two-handed weapon and a shield are the one pair that exclude each other,
/// and the exclusion is asymmetric on purpose. Equipping the two-hander
/// **displaces** the shield into the inventory, because the player's intent is
/// unambiguous — they picked the weapon. Equipping a shield while a two-hander
/// is held is **refused** instead (see [wearRefusal]), because silently dropping
/// the hero's best weapon to make room for a shield is the kind of help that
/// loses a run.
///
/// **A displacement can push the pack past [inventoryCap], and that is preserved
/// behaviour rather than an oversight.** Wearing a two-hander over a weapon and
/// a shield spends one carried item and returns two, so a full pack ends one
/// over the cap. Nothing here checks for it, in either the dungeon or the town.
/// It is left alone because a rule fixed in one context and not the other is
/// worse than a rule that is wrong in both: the pack cap would then mean
/// different things depending on which screen the player was looking at.
/// Fixing it at all is a decision about the cap, not about wearing, and belongs
/// to whoever owns the cap.
Worn wear(Equipment equipment, List<Item> inventory, String itemId) {
  final item = inventory.firstWhere((carried) => carried.id == itemId);
  final slot = item.base.slot!;
  final worn = {...equipment};
  final carried = [
    for (final held in inventory)
      if (held.id != itemId) held,
  ];
  final emptying = <EquipSlot>[
    if (worn.containsKey(slot)) slot,
    if (item.base.hands == WeaponHands.two &&
        worn.containsKey(EquipSlot.offHand))
      EquipSlot.offHand,
  ];
  final taken = <(Item, EquipSlot)>[];
  for (final emptied in emptying) {
    final removed = worn.remove(emptied)!;
    carried.add(removed);
    taken.add((removed, emptied));
  }
  worn[slot] = item;
  return Worn(
    equipment: worn,
    inventory: carried,
    taken: taken,
    put: (item, slot),
  );
}

/// Takes the piece in [slot] off and stows it at the end of the pack.
Worn takeOff(Equipment equipment, List<Item> inventory, EquipSlot slot) {
  final taken = equipment[slot]!;
  return Worn(
    equipment: {...equipment}..remove(slot),
    inventory: [...inventory, taken],
    taken: [(taken, slot)],
    put: null,
  );
}

/// The hero with its hit points brought inside the ceiling [loadout] allows.
///
/// Taking off +max-hp gear that was carrying the hero above its own ceiling has
/// to bring the hit points down with it. The clamp has a floor of one:
/// undressing must never be a way to die. That floor is defence in depth rather
/// than a live rule — the hero's own base maximum is twenty and content forbids
/// a negative max-hp affix, so the clamp can never reach zero — and it stays
/// because the day an affix subtracts hit points is the day it becomes
/// load-bearing, and by then nobody will remember to add it.
///
/// **Where this is called from is asymmetric, and the asymmetry is inherited
/// rather than chosen.** The dungeon clamps when the hero takes a piece off and
/// does not when it puts one on, so a dungeon swap into an occupied slot that
/// lowers the ceiling leaves the hero above it. The town clamps on both paths.
/// The dungeon's behaviour is frozen for this milestone — changing it would move
/// balance the seeded runs are measured against — while the town is new surface
/// that would otherwise print "24 / 20" at the player. Both are pinned by test.
/// Unifying them is a ruling about balance, not about wearing.
Actor clampedToMaxHp(Actor hero, Loadout loadout) {
  final ceiling = heroMaxHp(hero, loadout);
  if (hero.hp <= ceiling) return hero;
  return hero.copyWith(hp: ceiling < 1 ? 1 : ceiling);
}

Item? _find(List<Item> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) return item;
  }
  return null;
}
