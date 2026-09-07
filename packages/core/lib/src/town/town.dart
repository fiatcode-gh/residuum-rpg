import 'package:equatable/equatable.dart';

import '../craft/craft.dart';
import '../craft/material.dart';
import '../craft/risk.dart';
import '../craft/temper.dart';
import '../engine/game_state.dart';
import '../loot/equip_slot.dart';
import '../loot/item.dart';
import '../loot/rarity.dart';
import '../loot/wear.dart';
import '../magic/read.dart';
import '../magic/spell.dart';
import '../skills/skill.dart';
import 'profile.dart';

/// Why the town would not do what was asked.
///
/// The sentence a transaction answers in, refusal or loss alike.
///
/// **Two kinds, because they point opposite ways.** A [TownRefusal] changes
/// nothing at all; a [CraftLoss] marks a craft the bench worked and lost —
/// the profile it answers with is not the profile it arrived on. The screen
/// reads only the sentence, which is why the pair shares one shape.
sealed class TownAnswer extends Equatable {
  const TownAnswer(this.reason);

  /// Written to be read aloud on the screen, not parsed.
  final String reason;

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => '$runtimeType($reason)';
}

/// The town's answer to [ActionRefused], and it exists for the same reason: a
/// refused transaction changes nothing at all, so the caller gets a sentence
/// rather than a value it cannot tell apart from success.
class TownRefusal extends TownAnswer {
  const TownRefusal(super.reason);
}

/// A craft the bench worked and lost: the material is gone, the result is not.
///
/// **Not a refusal, and the difference is the whole point.** A refusal changes
/// nothing at all; a loss took exactly one material and trained the skill
/// anyway, so a caller that treated it as a refusal would believe the pack
/// unchanged. The bench says the sentence in the town slot, worded with the
/// loss, never a colour.
class CraftLoss extends TownAnswer {
  const CraftLoss(super.reason);
}

/// A profile after a craft, and the sentence that answers for it, or null.
///
/// The craft transactions' shape, identical to [Transacted] but for the
/// answer's kind: a craft can be refused before any work, or worked and lost.
typedef Crafted = (Profile, TownAnswer?);

/// A profile after a transaction, and the refusal that stopped it, or null.
///
/// The pair mirrors `step`'s `(GameState, List<GameEvent>)`: the new value
/// first, whatever the rules had to say second. On a refusal the first element
/// is the profile that went in, unchanged and equal to it.
typedef Transacted = (Profile, TownRefusal?);

/// Buys [item] for [price].
///
/// Refused when the purse is short or the pack is full. The pack cap is the
/// dungeon's cap and applies here too, because a merchant who could stuff the
/// hero past twenty items would make the cap a rule only the dungeon obeyed.
Transacted buyItem(Profile profile, Item item, int price) {
  if (profile.gold < price) {
    return (profile, const TownRefusal('you cannot afford that'));
  }
  if (profile.inventory.length >= inventoryCap) {
    return (profile, const TownRefusal('you cannot carry any more'));
  }
  return (
    profile.copyWith(
      gold: profile.gold - price,
      inventory: [...profile.inventory, item],
    ),
    null,
  );
}

/// Sells the carried item [itemId] for [price].
///
/// Only what the hero is carrying is for sale. The vault is storage, not a
/// second shop counter, and selling out of it would let a player empty a bank
/// they never had to walk anything home from.
Transacted sellItem(Profile profile, String itemId, int price) {
  if (_find(profile.inventory, itemId) == null) {
    return (profile, const TownRefusal('you are not carrying that'));
  }
  return (
    profile.copyWith(
      gold: profile.gold + price,
      inventory: _without(profile.inventory, itemId),
    ),
    null,
  );
}

/// Sleeps off every wound for [price].
///
/// Refused at full health rather than charging for nothing: an inn that takes
/// the last of a hero's gold for a bed it did not need is a trap, not a rule.
Transacted restAtInn(Profile profile, int price) {
  if (profile.gold < price) {
    return (profile, const TownRefusal('you cannot afford a bed'));
  }
  final ceiling = profile.maxHp;
  if (profile.hero.hp >= ceiling) {
    return (profile, const TownRefusal('there is nothing wrong with you'));
  }
  return (
    profile.copyWith(
      hero: profile.hero.copyWith(hp: ceiling),
      gold: profile.gold - price,
    ),
    null,
  );
}

/// Moves the carried item [itemId] into the vault, which has no cap.
Transacted depositItem(Profile profile, String itemId) {
  final item = _find(profile.inventory, itemId);
  if (item == null) {
    return (profile, const TownRefusal('you are not carrying that'));
  }
  return (
    profile.copyWith(
      inventory: _without(profile.inventory, itemId),
      bank: [...profile.bank, item],
    ),
    null,
  );
}

/// Takes the banked item [itemId] back out. The pack cap applies.
Transacted withdrawItem(Profile profile, String itemId) {
  final item = _find(profile.bank, itemId);
  if (item == null) {
    return (profile, const TownRefusal('the vault does not hold that'));
  }
  if (profile.inventory.length >= inventoryCap) {
    return (profile, const TownRefusal('you cannot carry any more'));
  }
  return (
    profile.copyWith(
      bank: _without(profile.bank, itemId),
      inventory: [...profile.inventory, item],
    ),
    null,
  );
}

/// Wears the carried item [itemId].
///
/// The rule itself lives in [wearRefusal] and [wear], which the dungeon calls
/// too, so gear behaves the same whether the hero dresses in a shop or in a
/// corridor — including the displacement that can push the pack one past
/// [inventoryCap]. No gold changes hands: this is the hero deciding what to
/// carry, not a transaction with anyone.
Transacted equipItem(Profile profile, String itemId) {
  final refusal = wearRefusal(profile.loadout, profile.inventory, itemId);
  if (refusal != null) return (profile, TownRefusal(refusal));
  return (
    _dressed(profile, wear(profile.equipment, profile.inventory, itemId)),
    null,
  );
}

/// Takes the piece in [slot] off and stows it in the pack.
Transacted unequipItem(Profile profile, EquipSlot slot) {
  final refusal = takeOffRefusal(profile.equipment, profile.inventory, slot);
  if (refusal != null) return (profile, TownRefusal(refusal));
  return (
    _dressed(profile, takeOff(profile.equipment, profile.inventory, slot)),
    null,
  );
}

/// The profile wearing what [worn] says, with hit points brought inside the
/// ceiling the new loadout allows.
///
/// Both dressing transactions come through here so neither can forget the
/// clamp. See [clampedToMaxHp] for why the town clamps on both paths where the
/// dungeon clamps on only one.
Profile _dressed(Profile profile, Worn worn) => _clamped(
  profile.copyWith(equipment: worn.equipment, inventory: worn.inventory),
);

/// [profile] with its hit points brought inside the ceiling its gear allows.
///
/// **Every town transaction that can change what the hero is wearing comes
/// through here**, which is now three of them rather than two: putting a piece
/// on, taking one off, and working a piece the hero has on. One door means none
/// of the three can forget the clamp, and a fourth will inherit it by being
/// written the same way.
Profile _clamped(Profile profile) =>
    profile.copyWith(hero: clampedToMaxHp(profile.hero, profile.loadout));

/// Smelts [smeltCost] ore into one ingot, and trains Blacksmith by doing it.
///
/// Refused in [smeltRefusal]'s sentence when the hero is short of ore. No gold
/// changes hands — see [smeltRefusal] for why the forge's first door is a
/// workshop and not a shop.
///
/// **The counters move by one function**, [withMaterial], which drops an entry
/// that empties. So a hero who smelts their last two ore comes out of this with
/// no `ore` key at all rather than a zero — which is what keeps a save document's
/// materials block the size of what the hero is actually carrying.
Transacted smeltOre(Profile profile) {
  final refusal = smeltRefusal(profile);
  if (refusal != null) return (profile, TownRefusal(refusal));
  final spent = withMaterial(profile.materials, MaterialId.ore, -smeltCost);
  return (
    profile.copyWith(
      materials: withMaterial(spent, MaterialId.ingot, 1),
      skills: trainedIn(profile.skills, SkillId.blacksmith),
    ),
    null,
  );
}

/// Brews [brewCost] herbs into one [potion], and trains Herbcraft by doing it.
///
/// [potion] is a parameter because `core` has no armory, exactly as [readBook]
/// takes the spell registry: the rules know that brewing makes a potion, and
/// content knows which one.
///
/// The new item's id is `brew-<n>` off [Profile.brewNumber], and the counter is
/// bumped in the same breath. **A derived id would not do**: an id has to be
/// unique among everything the hero holds, and anything read off the pack or the
/// visit would hand out the number of a potion that was drunk an hour ago.
///
/// Refused in [brewRefusal]'s sentences — short of herbs, or a full pack in
/// [buyItem]'s exact words, because a brewed potion runs into the same twenty
/// slots a bought one does.
Crafted brewPotion(Profile profile, BaseItem potion) {
  final refusal = brewRefusal(profile);
  if (refusal != null) return (profile, TownRefusal(refusal));
  final level = profile.skills[SkillId.herbcraft]?.level ?? 0;
  final (drawn, failed) = craftDraw(profile, brewFailChance(level));
  if (failed) {
    return (
      drawn.copyWith(
        materials: withMaterial(drawn.materials, MaterialId.herb, -brewCost),
        skills: trainedIn(drawn.skills, SkillId.herbcraft),
      ),
      CraftLoss('the brew fails and takes $brewCost herbs'),
    );
  }
  final brewed = Item(
    id: 'brew-${drawn.brewNumber}',
    base: potion,
    rarity: Rarity.common,
  );
  return (
    drawn.copyWith(
      inventory: [...drawn.inventory, brewed],
      materials: withMaterial(drawn.materials, MaterialId.herb, -brewCost),
      brewNumber: drawn.brewNumber + 1,
      skills: trainedIn(drawn.skills, SkillId.herbcraft),
    ),
    null,
  );
}

/// Works the carried or worn item [itemId] up one tier of temper.
///
/// Spends the tier's ingots, trains Blacksmith, and refuses in
/// [temperRefusal]'s sentences — which the screen reads too, so a dead row says
/// exactly what the transaction would have said. Gold changes hands nowhere:
/// the bench is a workshop, and the balancer is training, not the purse.
///
/// **Applies to a worn piece as well as a carried one**, so the hero does not
/// have to undress to visit the forge; the piece most worth working is usually
/// the one they have on. A worn temper goes through [_clamped], with dressing.
///
/// **Any future temper term that reaches `maxHp` must keep coming through
/// [_clamped].** Today it cannot: a tier lands on a weapon's damage or a piece of
/// armour's armour and on nothing else, so no clamp scenario exists and there is
/// deliberately no test pretending one does. The route is here because the
/// invariant is "the town never leaves a hero above their ceiling", not "the
/// current arithmetic happens not to lower one" — and the day a perk gives temper
/// a hit-point term, this is the line that is already right.
///
/// This is the only thing in the game that changes [Item.temper].
///
/// **The piece [heldItem] found is the piece that gets worked** — the first
/// match in the pack, else the first match among the worn, in that order. A
/// legacy pack can hold duplicate ids, and one hammer blow does not temper
/// every twin.
Crafted temperItem(Profile profile, String itemId) {
  final refusal = temperRefusal(profile, itemId);
  if (refusal != null) return (profile, TownRefusal(refusal));
  final item = heldItem(profile, itemId)!;
  final price = temperPriceFrom(item.temper);
  final level = profile.skills[SkillId.blacksmith]?.level ?? 0;
  final (drawn, failed) = craftDraw(
    profile,
    temperFailChance(item.temper + 1, level),
  );
  if (failed) {
    return (
      drawn.copyWith(
        materials: withMaterial(drawn.materials, MaterialId.ingot, -1),
        skills: trainedIn(drawn.skills, SkillId.blacksmith),
      ),
      const CraftLoss('the temper fails and takes 1 ingot'),
    );
  }
  final worked = item.tempered(item.temper + 1);
  final at = drawn.inventory.indexWhere((carried) => carried.id == itemId);
  final inventory = at < 0
      ? drawn.inventory
      : ([...drawn.inventory]..[at] = worked);
  final equipment = at >= 0
      ? drawn.equipment
      : {
          for (final slot in drawn.equipment.keys)
            slot: drawn.equipment[slot]!.id == itemId
                ? worked
                : drawn.equipment[slot]!,
        };
  return (
    _clamped(
      drawn.copyWith(
        inventory: inventory,
        equipment: equipment,
        materials: withMaterial(
          drawn.materials,
          MaterialId.ingot,
          -price.ingots,
        ),
        skills: trainedIn(drawn.skills, SkillId.blacksmith),
      ),
    ),
    null,
  );
}

/// Reads the carried spell book [itemId], learning what it teaches.
///
/// The rule itself lives in [readRefusal], which the dungeon calls too, so a
/// book behaves the same whether the hero opens it at a camp or in a corridor —
/// including the gate, and including the sentence the gate refuses in.
///
/// **No gold changes hands, and no merchant is involved.** Learning is the hero
/// spending a page they already own, not a transaction: charging for it would
/// make the book a receipt rather than a find, and would mean a hero who walked
/// out of the dungeon broke could not read what they had carried home.
Transacted readBook(Profile profile, String itemId, Map<String, Spell> spells) {
  final refusal = readRefusal(
    profile.loadout,
    profile.inventory,
    profile.knownSpells,
    spells,
    itemId,
  );
  if (refusal != null) return (profile, TownRefusal(refusal));
  final book = _find(profile.inventory, itemId)!;
  return (
    profile.copyWith(
      inventory: _without(profile.inventory, itemId),
      knownSpells: {...profile.knownSpells, book.base.teaches!},
    ),
    null,
  );
}

/// Banks [amount] of carried gold, putting it out of death's reach.
Transacted depositGold(Profile profile, int amount) {
  if (amount <= 0) {
    return (profile, const TownRefusal('that is not an amount'));
  }
  if (profile.gold < amount) {
    return (profile, const TownRefusal('you are not carrying that much'));
  }
  return (
    profile.copyWith(
      gold: profile.gold - amount,
      bankedGold: profile.bankedGold + amount,
    ),
    null,
  );
}

/// Takes [amount] of banked gold into the purse, where death can reach it.
Transacted withdrawGold(Profile profile, int amount) {
  if (amount <= 0) {
    return (profile, const TownRefusal('that is not an amount'));
  }
  if (profile.bankedGold < amount) {
    return (profile, const TownRefusal('the vault does not hold that much'));
  }
  return (
    profile.copyWith(
      gold: profile.gold + amount,
      bankedGold: profile.bankedGold - amount,
    ),
    null,
  );
}

Item? _find(List<Item> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) return item;
  }
  return null;
}

List<Item> _without(List<Item> items, String itemId) =>
    withoutFirst(items, itemId);
