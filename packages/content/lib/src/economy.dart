import 'package:residuum_core/core.dart';

import 'affix_pool.dart';
import 'armory.dart';
import 'spells.dart';

/// What a night at the inn costs.
///
/// Flat, and cheap enough that an early hero can always afford to stop
/// bleeding: the inn is the answer to a bad floor, and an answer nobody can pay
/// for is not one. It does not scale with depth because the thing it competes
/// with, the healing potion, does not either — and it stays under that potion's
/// price so that walking home is the thrifty way to heal and drinking is the
/// way that does not cost a run.
const int innPrice = 12;

/// How many potions are always on the shelf.
///
/// Potions are not rolled. They are the one thing the hero has to be able to
/// plan around, and a shop that sometimes had none would turn every re-entry
/// into a dice roll made before the dungeon got a say in it.
const int stockedPotions = 3;

/// The floor a spell book is worth before its gate is counted.
///
/// A book has no attack, no armour and no healing, so the worth every other
/// item is read off comes to nothing for one — and the clamp used to price the
/// Book of Banish at a single gold, which is less than the merchant asks for a
/// rusty sword. The flat term is what a page is worth for being a page.
const int bookWorth = 10;

/// What the merchant pays for [item].
///
/// Worth is read off what the thing does rather than a price tag on the base
/// item, so a weapon cannot be added to the armory with its economy forgotten.
/// Armour counts double against attack because a point of armour applies to
/// every blow of a fight while a point of damage applies to one swing.
///
/// **A book is worth [bookWorth] plus the level its spell is gated behind**,
/// which is the same rule read off a different verb: what a book does is teach
/// one spell, and the gate is the only number that says which spells are worth
/// more than others. The gate is looked up through [BaseItem.teaches] rather
/// than written on the book, so a book cannot be added to the armory with its
/// price out of step with the spell it opens.
///
/// The tier multiplies rather than adds, because a tier *is* its affix count:
/// a Rare is two bonuses on the same base, and the price says so. It is always
/// one for a book, which [rollDrop] forces to Common — so the term above is
/// the whole of a book's price, and that is deliberate.
int sellPriceOf(Item item) {
  final worth =
      item.base.attackMin +
      item.base.attackMax +
      item.base.armor * 2 +
      item.base.heal +
      _bookWorthOf(item.base);
  final priced = worth * (1 + item.rarity.affixCount);
  return priced < 1 ? 1 : priced;
}

int _bookWorthOf(BaseItem base) {
  final teaches = base.teaches;
  if (teaches == null) return 0;
  return bookWorth + (spellOrNull(teaches)?.requiredLevel ?? 0);
}

/// What the merchant charges for [item]. Always more than [sellPriceOf].
///
/// Double, everywhere. That is the simplest shape that makes the no-arbitrage
/// rule true by construction rather than by a table somebody has to keep
/// re-checking: buy anything and sell it straight back and the hero is down
/// half its money, at every tier, for every base item in the game.
int buyPriceOf(Item item) => sellPriceOf(item) * 2;

/// What the merchant deals in.
///
/// Deliberately not a depth table. A depth table carries depth flavour — depth
/// one is potions and rusty swords, depth five has no rusty sword at all — and
/// a shop wants breadth instead: something for every slot, most of it plain,
/// occasionally something worth saving up for. The rolling machinery is shared
/// with the dungeon; only the weights are the shop's own.
///
/// The potion carries weight zero here because [stockedPotions] puts potions on
/// the shelf directly. It stays in the list at zero for the same reason
/// [Rarity.legendary] does in the drop tables: a table that names everything it
/// could carry is a table a reader can check.
///
/// **The shop stocks the two ungated books and only those.** A hero who has
/// never found a book has no way into magic at all otherwise, and the two that
/// open Wrath and Mending are the two a fresh hero can actually read. The other
/// four are named at zero rather than left out, for the reason above: they are
/// found in the places that teach them, and a shelf that sold them would make
/// the walk pointless.
const DropTable marketTable = DropTable(
  items: [
    Weighted(healingPotion, 0),
    Weighted(rustySword, 2),
    Weighted(ironSword, 4),
    Weighted(warAxe, 3),
    Weighted(greatsword, 2),
    Weighted(maul, 2),
    Weighted(kiteShield, 4),
    Weighted(ironHelm, 4),
    Weighted(leatherCap, 4),
    Weighted(mailHauberk, 3),
    Weighted(leatherJerkin, 4),
    Weighted(ironGauntlets, 4),
    Weighted(ironGreaves, 4),
    Weighted(leatherBoots, 4),
    Weighted(bookOfFirebolt, 2),
    Weighted(bookOfMend, 2),
  ],
  rarities: [
    Weighted(Rarity.common, 55),
    Weighted(Rarity.fine, 30),
    Weighted(Rarity.rare, 13),
    Weighted(Rarity.epic, 2),
    Weighted(Rarity.legendary, 0),
  ],
  weaponAffixes: weaponAffixes,
  armourAffixes: armourAffixes,
  minFloorItems: 0,
  maxFloorItems: 0,
);

/// What the merchant in [town] is holding on [visit] of the world [worldSeed]
/// describes.
///
/// Deterministic in those three and nothing else, so the shelf is a property of
/// the world rather than of how the last run went — the same promise the floors
/// make. The stream is salted off every floor's stream so that a restock can
/// never reshuffle a floor, and a floor can never reshuffle the shop.
///
/// **Each town rolls its own stock, and the ids say which town's.** Two towns
/// selling the same iron helm reads wrong and makes the second town pointless to
/// walk to; the four-day round trip has to buy the player something, and a
/// different shelf is that something. The town is folded into the seed by
/// [_townSalt], so Stonebridge and Northgate are two shops on one world rather
/// than one shop drawn twice.
///
/// **A thinner shelf than the shop used to keep**, and the reason is the same
/// one the floors were thinned for: the game's problem was never that gold
/// bought too little, it was that nothing was worth buying because the hero
/// already had everything. Prices did not move — a currency starts mattering
/// when income is scarce, not when the sinks get dearer — so the shelf carries
/// one to three pieces where it carried two to four, and the potions beside
/// them are untouched because those are what a hero has to be able to plan
/// around.
///
/// The town also goes into every stock id. An id names one roll off one shelf,
/// and the visit alone stopped being enough to say which the moment there were
/// two shelves: a hero who bought `market-0-gear-1` in one town would have found
/// it missing from the other's shelf, because what the merchant remembers is a
/// list of ids and nothing else.
List<Item> merchantStock(int worldSeed, int visit, NodeId town) {
  final rng = Rng(
    floorSeed(worldSeed ^ _marketSalt ^ _townSalt(town), _marketDepth, visit),
  );
  final gear = rng.rollRange(1, 3);
  final where = town.value;
  return [
    for (var n = 0; n < stockedPotions; n++)
      Item(
        id: 'market-$where-$visit-potion-${n + 1}',
        base: healingPotion,
        rarity: Rarity.common,
      ),
    for (var n = 0; n < gear; n++)
      rollDrop(marketTable, rng, 'market-$where-$visit-gear-${n + 1}'),
  ];
}

/// A number standing for [town] in a seed mix, the same on every build.
///
/// Derived from the id's own text rather than read out of a table, so a town
/// added to the world needs no second edit somewhere else to get a shelf — and
/// the one that got forgotten would be a town quietly sharing another's stock.
///
/// The mix is [floorSeed]'s, for [floorSeed]'s reason: everything is masked so
/// the arithmetic is exact on a web double as well as a native integer, because
/// a shared world seed has to describe the same shelves however the game was
/// compiled.
int _townSalt(NodeId town) {
  var hash = 0x811c9dc5;
  for (final unit in town.value.codeUnits) {
    hash = ((hash ^ (unit & 0x0fffffff)) & 0x0fffffff) * 0x01000193;
    hash &= 0x3fffffff;
  }
  return hash;
}

/// Keeps the shop's stream off every floor's stream.
const int _marketSalt = 0x5747;

/// The market is not a depth, and zero is not one either. Mixing the stock seed
/// at a depth the dungeon does not have is what keeps the two apart even if the
/// salt above were ever to collide with a real world seed.
const int _marketDepth = 0;
