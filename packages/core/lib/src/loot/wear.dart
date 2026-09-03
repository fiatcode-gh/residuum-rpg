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
///
/// **What a swap would displace is counted before anything moves.** Wearing a
/// two-hander over a weapon and a shield spends one carried item and returns
/// two, so a full pack would end one over [inventoryCap] — and the refusal names
/// the full pack rather than letting the swap through. The count comes from the
/// same expression [wear] carries the pieces out with, because a refusal that
/// counted displacements its own way would eventually refuse a swap the swap
/// would have allowed.
String? wearRefusal(Loadout loadout, List<Item> inventory, String itemId) {
  final item = _find(inventory, itemId);
  if (item == null) return 'you are not carrying that';
  final slot = item.base.slot;
  if (slot == null) return '${item.base.name} is not worn';
  if (slot == EquipSlot.offHand && loadout.wieldsTwoHanded) {
    return 'both hands are on the weapon';
  }
  if (inventory.length - 1 + _displacedBy(loadout.equipment, item).length >
      inventoryCap) {
    return 'your pack is too full for what that would displace';
  }
  return null;
}

List<EquipSlot> _displacedBy(Equipment equipment, Item item) => [
  if (equipment.containsKey(item.base.slot!)) item.base.slot!,
  if (item.base.hands == WeaponHands.two &&
      item.base.slot != EquipSlot.offHand &&
      equipment.containsKey(EquipSlot.offHand))
    EquipSlot.offHand,
];

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
/// **A displacement can no longer push the pack past [inventoryCap].** Wearing a
/// two-hander over a weapon and a shield spends one carried item and returns
/// two, so a full pack used to end one over the cap in the dungeon and in the
/// town alike. [wearRefusal] now counts what would come off before anything
/// does, and refuses naming the full pack — in both contexts at once, which is
/// the only way the fix was ever worth making: a cap that meant one thing in a
/// corridor and another in a shop would be worse than a cap that was wrong in
/// both.
Worn wear(Equipment equipment, List<Item> inventory, String itemId) {
  final item = inventory.firstWhere((carried) => carried.id == itemId);
  final slot = item.base.slot!;
  final worn = {...equipment};
  final carried = withoutFirst(inventory, itemId);
  final emptying = _displacedBy(equipment, item);
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
/// **Every path that dresses the hero calls this, and that is one rule with one
/// home.** The dungeon used to clamp on taking a piece off and not on putting
/// one on, so a corridor swap into an occupied slot that lowered the ceiling
/// left the hero standing above it while the same swap in a shop did not. The
/// asymmetry was inherited rather than chosen and it is gone: hit points mean
/// the same thing on both screens, which is what stops the player being shown
/// "24 / 20" by whichever door they happened to use.
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
