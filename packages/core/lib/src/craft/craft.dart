import '../engine/game_state.dart';
import '../town/profile.dart';
import 'material.dart';

/// How much ore one ingot takes.
///
/// Two, so that ore is the bulk material and the ingot is the unit of
/// investment. At one to one the forge's first door would be a button that
/// renames a counter, and at three to one the very first temper would sit two
/// delves away — long enough that a player would never find out what tempering
/// is for.
///
/// It also sets the real price of a temper in things the hero has to go and
/// find: one ingot is two ore, so working a piece all the way to `+3` costs six
/// ingots and therefore twelve ore, which is several trips of looking down.
const int smeltCost = 2;

/// How many herbs one potion takes.
///
/// Three, and brewing is the only thing herbs are for — they are not on the
/// shelf, not in the vault, and a death takes them. A delve that turns up half a
/// dozen patches is worth about two potions, which is roughly what the shop
/// charges for one and what a bad room costs: enough to make gathering worth
/// stopping for, not enough to make the merchant's potions pointless.
const int brewCost = 3;

/// Why the forge will not smelt, or null when it will.
///
/// No gold changes hands. Smelting is the hero doing work on ore they already
/// carried out of the dark, exactly as reading a book is the hero spending a page
/// they already own — charging for it would make the forge a shop rather than a
/// workshop, and would mean a hero who walked out broke could not turn their haul
/// into anything.
String? smeltRefusal(Profile profile) =>
    countOf(profile.materials, MaterialId.ore) < smeltCost
    ? 'that takes $smeltCost ore'
    : null;

/// Why the alchemist will not brew, or null when they will.
///
/// **The pack cap is answered here, in [buyItem]'s exact words.** Brewing
/// produces an item, so it runs into the same twenty slots a purchase does, and
/// two different sentences for one rule would teach the player that the two
/// screens have two different caps.
String? brewRefusal(Profile profile) {
  if (countOf(profile.materials, MaterialId.herb) < brewCost) {
    return 'that takes $brewCost herbs';
  }
  if (profile.inventory.length >= inventoryCap) {
    return 'you cannot carry any more';
  }
  return null;
}
