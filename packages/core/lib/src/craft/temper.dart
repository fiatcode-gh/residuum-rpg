import '../loot/item.dart';
import '../skills/skill.dart';
import '../town/profile.dart';
import 'material.dart';

/// The highest temper a forge can work a piece of steel to.
///
/// Three, and the ceiling is the point rather than the number. Tempering is the
/// only thing in the game that improves an item the world already handed over,
/// so it has to stop somewhere short of making the item itself irrelevant: a
/// hero who could keep paying would end up with a rusty sword that outclassed
/// every drop in the dungeon, and the design guard says crafting serves loot and
/// never competes with it. Three tiers is enough to feel like an investment in
/// something found, and few enough that the found thing still matters most.
///
/// Perks that reach tempering arrive a milestone later, so the tiers are kept a
/// plain count with a plain ceiling rather than anything cleverer: there is
/// nothing here for a perk to have to undo.
const int maxTemper = 3;

/// What the forge asks for one tier of temper.
class TemperPrice {
  const TemperPrice({
    required this.blacksmith,
    required this.ingots,
    required this.gold,
  });

  /// The Blacksmith level the hero has to have reached.
  final int blacksmith;

  final int ingots;
  final int gold;
}

/// What each tier costs, cheapest first.
///
/// **The first tier is ungated on purpose.** A hero who has never swung a pick
/// has to be able to buy the tier that teaches them what tempering is for, and a
/// gate on the first one would make the forge a door that stays shut until
/// something else has already happened.
///
/// After that the curve is [xpToNext]'s shape applied to a purse: every tier
/// costs strictly more training, more iron and more coin than the one below it,
/// so a third tier is a real investment. Twelve ore and eighty-five gold takes a
/// piece all the way — several delves' worth of looking down, against gold sinks
/// of twelve for a bed and fifteen for a rumor, so the forge competes with the
/// inn for a purse rather than dwarfing it.
///
/// The gates at five and ten are reachable by doing the work: gathering, smelting
/// and tempering each grant one point, so a delve that turns up half a dozen
/// veins moves Blacksmith about eight points, and five arrives inside a few trips
/// while ten stays a goal.
const List<TemperPrice> temperPrices = [
  TemperPrice(blacksmith: 0, ingots: 1, gold: 10),
  TemperPrice(blacksmith: 5, ingots: 2, gold: 25),
  TemperPrice(blacksmith: 10, ingots: 3, gold: 50),
];

/// What it costs to take a piece already at [temper] up one tier.
///
/// Throws [RangeError] at [maxTemper], where there is no next tier to price.
/// Callers ask [temperRefusal] first, which answers the ceiling by name.
TemperPrice temperPriceFrom(int temper) => temperPrices[temper];

/// Why the forge will not work [itemId] for this hero, or null when it will.
///
/// **A [Profile] rather than the pieces of one**, unlike [wearRefusal], and the
/// difference is which worlds the rule serves. Wearing happens in a corridor and
/// in a shop, so its rule takes only what both have; tempering happens at a
/// forge and nowhere else, so the one thing every caller has is the hero. Five
/// unpacked parameters would be five chances to assemble the question wrong.
///
/// **The order of the checks is the contract**, and it runs from what cannot be
/// changed to what can:
///
/// 1. what the hero is holding — asked first, because everything below it is a
///    question about an item, and there is no item;
/// 2. what the item is — 'only steel takes a temper', before any price, so a
///    player is never told a potion is too expensive;
/// 3. the ceiling — before the gate, because a piece at `+3` is finished and
///    telling its owner to go and train would be a lie;
/// 4. the training;
/// 5. the iron, then the coin. Iron before coin because iron is what the forge
///    is *for*: a hero sent to look for gold when they are also out of ore would
///    go and do the wrong thing first.
///
/// Public because the screen reads it for its dead-row reasons, following
/// [readRefusal]: a button that greyed itself out on its own arithmetic would
/// eventually refuse something the rules would have allowed, and a UI that lies
/// about the rules is worse than either answer alone.
String? temperRefusal(Profile profile, String itemId) {
  final item = _held(profile, itemId);
  if (item == null) return 'you are not holding that';
  if (!item.base.takesTemper) return 'only steel takes a temper';
  if (item.temper >= maxTemper) return 'that is worked as far as it goes';
  final price = temperPriceFrom(item.temper);
  final level = profile.skills[SkillId.blacksmith]?.level ?? 0;
  if (level < price.blacksmith) {
    return 'that needs Blacksmith ${price.blacksmith}';
  }
  if (countOf(profile.materials, MaterialId.ingot) < price.ingots) {
    return 'that takes ${price.ingots} '
        '${price.ingots == 1 ? 'ingot' : 'ingots'}';
  }
  if (profile.gold < price.gold) return 'you cannot afford that';
  return null;
}

/// The carried or worn item [itemId], or null when the hero has no such thing.
///
/// Worn counts, so the hero does not have to undress to visit the forge — which
/// matters because the piece most worth tempering is usually the one they are
/// wearing.
Item? heldItem(Profile profile, String itemId) => _held(profile, itemId);

Item? _held(Profile profile, String itemId) {
  for (final item in profile.inventory) {
    if (item.id == itemId) return item;
  }
  for (final item in profile.equipment.values) {
    if (item.id == itemId) return item;
  }
  return null;
}
