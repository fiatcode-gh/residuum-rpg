import 'package:residuum_core/core.dart';

import 'affix_pool.dart';
import 'armory.dart';

/// What each depth of the dungeon can give up.
///
/// Three dials slide together as the hero goes down. Better base items fade in
/// and the starting sword fades out; the rarity weights shift from mostly
/// Common toward Fine and Rare; and the healing potion keeps a heavy weight at
/// every depth, because potions are the only healing in the game and the whole
/// balance of a descent rests on how many the hero can find.
///
/// [Rarity.legendary] carries weight zero everywhere. The tier exists, it is
/// never drawn, and armour sets arrive with M4 to give it something to mean.
const Map<int, DropTable> dropTables = {
  1: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 6),
      Weighted(ironSword, 4),
      Weighted(warAxe, 1),
      Weighted(greatsword, 1),
      Weighted(maul, 0),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 5),
      Weighted(leatherCap, 6),
      Weighted(mailHauberk, 3),
      Weighted(leatherJerkin, 6),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 5),
      Weighted(leatherBoots, 6),
    ],
    rarities: [
      Weighted(Rarity.common, 70),
      Weighted(Rarity.fine, 25),
      Weighted(Rarity.rare, 5),
      Weighted(Rarity.epic, 0),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 4,
    maxFloorItems: 6,
  ),
  2: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 3),
      Weighted(ironSword, 5),
      Weighted(warAxe, 3),
      Weighted(greatsword, 2),
      Weighted(maul, 1),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 5),
      Weighted(mailHauberk, 5),
      Weighted(leatherJerkin, 5),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 5),
      Weighted(leatherBoots, 5),
    ],
    rarities: [
      Weighted(Rarity.common, 60),
      Weighted(Rarity.fine, 28),
      Weighted(Rarity.rare, 10),
      Weighted(Rarity.epic, 2),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 4,
    maxFloorItems: 6,
  ),
  3: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 0),
      Weighted(ironSword, 4),
      Weighted(warAxe, 5),
      Weighted(greatsword, 3),
      Weighted(maul, 2),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 4),
      Weighted(mailHauberk, 7),
      Weighted(leatherJerkin, 4),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 6),
      Weighted(leatherBoots, 4),
    ],
    rarities: [
      Weighted(Rarity.common, 50),
      Weighted(Rarity.fine, 30),
      Weighted(Rarity.rare, 15),
      Weighted(Rarity.epic, 5),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 4,
    maxFloorItems: 6,
  ),
  4: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 0),
      Weighted(ironSword, 2),
      Weighted(warAxe, 6),
      Weighted(greatsword, 4),
      Weighted(maul, 3),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 3),
      Weighted(mailHauberk, 8),
      Weighted(leatherJerkin, 3),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 6),
      Weighted(leatherBoots, 3),
    ],
    rarities: [
      Weighted(Rarity.common, 40),
      Weighted(Rarity.fine, 32),
      Weighted(Rarity.rare, 20),
      Weighted(Rarity.epic, 8),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 4,
    maxFloorItems: 6,
  ),
  5: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 0),
      Weighted(ironSword, 1),
      Weighted(warAxe, 6),
      Weighted(greatsword, 5),
      Weighted(maul, 4),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 2),
      Weighted(mailHauberk, 9),
      Weighted(leatherJerkin, 2),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 6),
      Weighted(leatherBoots, 2),
    ],
    rarities: [
      Weighted(Rarity.common, 30),
      Weighted(Rarity.fine, 33),
      Weighted(Rarity.rare, 25),
      Weighted(Rarity.epic, 12),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 4,
    maxFloorItems: 6,
  ),
};

/// The drop table for [depth].
///
/// Throws [ArgumentError] outside one to five, so a floor can never be built
/// from a table that does not exist.
DropTable dropTableFor(int depth) {
  final table = dropTables[depth];
  if (table == null) {
    throw ArgumentError.value(depth, 'depth', 'no drop table for this depth');
  }
  return table;
}
