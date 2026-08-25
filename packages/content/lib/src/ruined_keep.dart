import 'package:residuum_core/core.dart';

import 'affix_pool.dart';
import 'armory.dart';
import 'bestiary.dart';
import 'dungeon_spawn.dart';

/// A soldier who stopped being one. The keep's rank and file.
const CreatureSpec deserter = CreatureSpec(
  id: 'deserter',
  name: 'the deserter',
  glyph: 'b',
  hp: 16,
  attackMin: 3,
  attackMax: 7,
  speed: 10,
  dropChance: 50,
  pierce: 5,
);

/// Twice the hero's speed and no armour at all: it closes, and it dies.
const CreatureSpec kennelHound = CreatureSpec(
  id: 'hound',
  name: 'the kennel hound',
  glyph: 'k',
  hp: 14,
  attackMin: 3,
  attackMax: 5,
  speed: 20,
  dropChance: 40,
  pierce: 5,
  vulnerableTo: {DamageType.fire},
);

/// Half the hero's speed, and the hardest thing in the game to fell that is not
/// standing at the bottom of a dungeon.
const CreatureSpec rustedManAtArms = CreatureSpec(
  id: 'man-at-arms',
  name: 'the rusted man-at-arms',
  glyph: 'm',
  hp: 22,
  attackMin: 4,
  attackMax: 8,
  speed: 5,
  dropChance: 60,
  pierce: 6,
  resists: {DamageType.fire},
  vulnerableTo: {DamageType.frost},
);

/// What holds the bottom of the keep, and is never rolled for.
const CreatureSpec fallenCastellan = CreatureSpec(
  id: 'castellan',
  name: 'the fallen castellan',
  glyph: 'C',
  hp: 55,
  attackMin: 6,
  attackMax: 10,
  speed: 10,
  dropChance: 100,
  pierce: 5,
  resists: {DamageType.fire},
  vulnerableTo: {DamageType.frost},
);

/// Everything the keep has, in the order the hero meets it.
///
/// The castellan is last and is in no spawn table: it is placed on the bottom
/// floor and nowhere else.
const List<CreatureSpec> ruinedKeepBestiary = [
  deserter,
  kennelHound,
  rustedManAtArms,
  fallenCastellan,
];

/// What waits on each depth of the keep.
///
/// Three creatures rather than the cave's four, and that is the tier showing:
/// the keep has no filler. The hound is the shallow floors' whole answer to
/// pace, the man-at-arms fades in at three and takes the bottom, and the
/// deserter runs the length of the place because a garrison is what the keep
/// *is* — which is why it keeps a weight on six and seven rather than fading to
/// nothing like the hound.
///
/// **Depths six and seven exist because the keep can roll five, six or seven
/// floors.** A delve draws its own bottom, so the table covers every depth the
/// roll can reach or a seven-deep keep would throw on arrival.
const Map<int, DungeonSpawnTable> ruinedKeepSpawnTables = {
  1: DungeonSpawnTable(
    minCount: 3,
    maxCount: 4,
    entries: [Weighted(kennelHound, 6), Weighted(deserter, 1)],
  ),
  2: DungeonSpawnTable(
    minCount: 4,
    maxCount: 5,
    entries: [Weighted(kennelHound, 3), Weighted(deserter, 3)],
  ),
  3: DungeonSpawnTable(
    minCount: 5,
    maxCount: 7,
    entries: [
      Weighted(kennelHound, 2),
      Weighted(deserter, 3),
      Weighted(rustedManAtArms, 1),
    ],
  ),
  4: DungeonSpawnTable(
    minCount: 6,
    maxCount: 8,
    entries: [
      Weighted(kennelHound, 1),
      Weighted(deserter, 3),
      Weighted(rustedManAtArms, 2),
    ],
  ),
  5: DungeonSpawnTable(
    minCount: 7,
    maxCount: 9,
    entries: [Weighted(deserter, 2), Weighted(rustedManAtArms, 3)],
  ),
  6: DungeonSpawnTable(
    minCount: 8,
    maxCount: 10,
    entries: [Weighted(deserter, 1), Weighted(rustedManAtArms, 4)],
  ),
  7: DungeonSpawnTable(
    minCount: 9,
    maxCount: 11,
    entries: [Weighted(deserter, 1), Weighted(rustedManAtArms, 5)],
  ),
};

/// What each depth of the keep can give up.
///
/// **Two notches richer than the crypt at the same depth, where the sea-cave is
/// one.** The spec's first guess paid both new dungeons alike; the keep is four
/// days a round trip against the cave's two and hits harder on every floor, and
/// a keep that paid a cave's rates would be a place with nothing to recommend
/// it. So the cave reads the crypt's curve one floor down and the keep reads it
/// two, which is the same rule applied twice rather than a second rule.
///
/// Depths six and seven continue that one slide — five off Common, one off Fine,
/// two onto Rare, four onto Epic per floor — so the deepest keep a roll can lay
/// out is the richest place in the game, which is what four days of walking is
/// supposed to buy.
const Map<int, DropTable> ruinedKeepDropTables = {
  1: DropTable(
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
      Weighted(bookOfWard, 2),
      Weighted(bookOfBanish, 2),
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
    minFloorItems: 1,
    maxFloorItems: 2,
  ),
  2: DropTable(
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
      Weighted(bookOfWard, 2),
      Weighted(bookOfBanish, 2),
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
    minFloorItems: 1,
    maxFloorItems: 2,
  ),
  3: DropTable(
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
      Weighted(bookOfWard, 2),
      Weighted(bookOfBanish, 2),
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
    minFloorItems: 1,
    maxFloorItems: 2,
  ),
  4: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 0),
      Weighted(ironSword, 0),
      Weighted(warAxe, 6),
      Weighted(greatsword, 6),
      Weighted(maul, 5),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 1),
      Weighted(mailHauberk, 10),
      Weighted(leatherJerkin, 1),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 6),
      Weighted(leatherBoots, 1),
      Weighted(bookOfWard, 2),
      Weighted(bookOfBanish, 2),
    ],
    rarities: [
      Weighted(Rarity.common, 25),
      Weighted(Rarity.fine, 33),
      Weighted(Rarity.rare, 28),
      Weighted(Rarity.epic, 14),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 1,
    maxFloorItems: 2,
  ),
  5: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 0),
      Weighted(ironSword, 0),
      Weighted(warAxe, 5),
      Weighted(greatsword, 7),
      Weighted(maul, 6),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 0),
      Weighted(mailHauberk, 11),
      Weighted(leatherJerkin, 0),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 6),
      Weighted(leatherBoots, 0),
      Weighted(bookOfWard, 2),
      Weighted(bookOfBanish, 2),
    ],
    rarities: [
      Weighted(Rarity.common, 20),
      Weighted(Rarity.fine, 32),
      Weighted(Rarity.rare, 30),
      Weighted(Rarity.epic, 18),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 1,
    maxFloorItems: 2,
  ),
  6: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 0),
      Weighted(ironSword, 0),
      Weighted(warAxe, 4),
      Weighted(greatsword, 8),
      Weighted(maul, 7),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 0),
      Weighted(mailHauberk, 12),
      Weighted(leatherJerkin, 0),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 6),
      Weighted(leatherBoots, 0),
      Weighted(bookOfWard, 2),
      Weighted(bookOfBanish, 2),
    ],
    rarities: [
      Weighted(Rarity.common, 15),
      Weighted(Rarity.fine, 31),
      Weighted(Rarity.rare, 32),
      Weighted(Rarity.epic, 22),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 1,
    maxFloorItems: 2,
  ),
  7: DropTable(
    items: [
      Weighted(healingPotion, 14),
      Weighted(rustySword, 0),
      Weighted(ironSword, 0),
      Weighted(warAxe, 3),
      Weighted(greatsword, 9),
      Weighted(maul, 8),
      Weighted(kiteShield, 6),
      Weighted(ironHelm, 6),
      Weighted(leatherCap, 0),
      Weighted(mailHauberk, 13),
      Weighted(leatherJerkin, 0),
      Weighted(ironGauntlets, 5),
      Weighted(ironGreaves, 6),
      Weighted(leatherBoots, 0),
      Weighted(bookOfWard, 2),
      Weighted(bookOfBanish, 2),
    ],
    rarities: [
      Weighted(Rarity.common, 10),
      Weighted(Rarity.fine, 30),
      Weighted(Rarity.rare, 34),
      Weighted(Rarity.epic, 26),
      Weighted(Rarity.legendary, 0),
    ],
    weaponAffixes: weaponAffixes,
    armourAffixes: armourAffixes,
    minFloorItems: 1,
    maxFloorItems: 2,
  ),
};

/// What the castellan is standing over.
///
/// [seaCaveTrophyTable]'s shape, weighted for the harder place: the same
/// sub-rare tiers at nothing, the same potion at nothing for the same reason
/// [rollDrop] forces a consumable Common, and Epic nearly as likely as Rare
/// because the keep is the longest walk in the world and the bottom of it is
/// where the best thing in the game should be.
const DropTable ruinedKeepTrophyTable = DropTable(
  items: [
    Weighted(healingPotion, 0),
    Weighted(warAxe, 5),
    Weighted(greatsword, 7),
    Weighted(maul, 6),
    Weighted(kiteShield, 6),
    Weighted(ironHelm, 6),
    Weighted(mailHauberk, 11),
    Weighted(ironGauntlets, 5),
    Weighted(ironGreaves, 6),
  ],
  rarities: [
    Weighted(Rarity.common, 0),
    Weighted(Rarity.fine, 0),
    Weighted(Rarity.rare, 55),
    Weighted(Rarity.epic, 45),
    Weighted(Rarity.legendary, 0),
  ],
  weaponAffixes: weaponAffixes,
  armourAffixes: armourAffixes,
  minFloorItems: 0,
  maxFloorItems: 0,
);
