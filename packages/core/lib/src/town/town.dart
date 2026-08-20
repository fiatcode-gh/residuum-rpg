import 'package:equatable/equatable.dart';

import '../engine/game_state.dart';
import '../loot/item.dart';
import 'profile.dart';

/// Why the town would not do what was asked.
///
/// The town's answer to [ActionRefused], and it exists for the same reason: a
/// refused transaction changes nothing at all, so the caller gets a sentence
/// rather than a value it cannot tell apart from success.
class TownRefusal extends Equatable {
  const TownRefusal(this.reason);

  /// Written to be read aloud on the screen, not parsed.
  final String reason;

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => 'TownRefusal($reason)';
}

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

List<Item> _without(List<Item> items, String itemId) => [
  for (final item in items)
    if (item.id != itemId) item,
];
