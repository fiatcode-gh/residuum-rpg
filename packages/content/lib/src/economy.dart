import 'package:residuum_core/core.dart';

import 'affix_pool.dart';
import 'armory.dart';

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

/// What the merchant pays for [item].
///
/// Worth is read off what the thing does rather than a price tag on the base
/// item, so a weapon cannot be added to the armory with its economy forgotten.
/// Armour counts double against attack because a point of armour applies to
/// every blow of a fight while a point of damage applies to one swing.
///
/// The tier multiplies rather than adds, because a tier *is* its affix count:
/// a Rare is two bonuses on the same base, and the price says so.
int sellPriceOf(Item item) {
  final worth =
      item.base.attackMin +
      item.base.attackMax +
      item.base.armor * 2 +
      item.base.heal;
  final priced = worth * (1 + item.rarity.affixCount);
  return priced < 1 ? 1 : priced;
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
/// The town also goes into every stock id. An id names one roll off one shelf,
/// and the visit alone stopped being enough to say which the moment there were
/// two shelves: a hero who bought `market-0-gear-1` in one town would have found
/// it missing from the other's shelf, because what the merchant remembers is a
/// list of ids and nothing else.
List<Item> merchantStock(int worldSeed, int visit, NodeId town) {
  final rng = Rng(
    floorSeed(worldSeed ^ _marketSalt ^ _townSalt(town), _marketDepth, visit),
  );
  final gear = rng.rollRange(2, 4);
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
