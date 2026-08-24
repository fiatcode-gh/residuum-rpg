import 'package:residuum_core/core.dart';

import 'affix_pool.dart';
import 'armory.dart';
import 'bestiary.dart';
import 'dungeon_spawn.dart';

/// Slow and armoured, and the first thing the tide leaves behind.
const CreatureSpec shoreCrab = CreatureSpec(
  id: 'crab',
  name: 'the shore crab',
  glyph: 'c',
  hp: 12,
  attackMin: 2,
  attackMax: 4,
  speed: 5,
  dropChance: 35,
);

const CreatureSpec drownedSailor = CreatureSpec(
  id: 'drowned',
  name: 'the drowned sailor',
  glyph: 'd',
  hp: 14,
  attackMin: 3,
  attackMax: 5,
  speed: 10,
  dropChance: 45,
  pierce: 1,
);

/// Thin and twice the hero's speed: the cave's answer to the dire wolf.
const CreatureSpec morayEel = CreatureSpec(
  id: 'eel',
  name: 'the moray eel',
  glyph: 'e',
  hp: 8,
  attackMin: 3,
  attackMax: 6,
  speed: 20,
  dropChance: 30,
  pierce: 2,
);

const CreatureSpec brineHag = CreatureSpec(
  id: 'hag',
  name: 'the brine hag',
  glyph: 'h',
  hp: 18,
  attackMin: 4,
  attackMax: 6,
  speed: 10,
  dropChance: 55,
  pierce: 3,
);

/// What stands at the bottom of the sea-cave, and is never rolled for.
const CreatureSpec drownedCaptain = CreatureSpec(
  id: 'drowned-captain',
  name: 'the drowned captain',
  glyph: 'D',
  hp: 40,
  attackMin: 5,
  attackMax: 8,
  speed: 10,
  dropChance: 100,
  pierce: 4,
);

/// Everything the sea-cave has, in the order the hero meets it.
///
/// The captain is last and is in no spawn table: it is placed on the bottom
/// floor and nowhere else.
const List<CreatureSpec> seaCaveBestiary = [
  shoreCrab,
  drownedSailor,
  morayEel,
  brineHag,
  drownedCaptain,
];

/// What waits on each depth of the sea-cave.
///
/// The crypt's shape with the cave's cast: counts slide up as the floors get
/// bigger, and each creature fades in and out over its own band so no floor is
/// one monster on repeat. The eel spans the whole cave because a fast thing is
/// what makes a corridor a decision at every depth.
const Map<int, DungeonSpawnTable> seaCaveSpawnTables = {
  1: DungeonSpawnTable(
    minCount: 4,
    maxCount: 5,
    entries: [Weighted(shoreCrab, 6), Weighted(morayEel, 1)],
  ),
  2: DungeonSpawnTable(
    minCount: 5,
    maxCount: 6,
    entries: [
      Weighted(shoreCrab, 3),
      Weighted(morayEel, 2),
      Weighted(drownedSailor, 2),
    ],
  ),
  3: DungeonSpawnTable(
    minCount: 6,
    maxCount: 8,
    entries: [
      Weighted(morayEel, 2),
      Weighted(drownedSailor, 3),
      Weighted(brineHag, 1),
    ],
  ),
  4: DungeonSpawnTable(
    minCount: 7,
    maxCount: 9,
    entries: [
      Weighted(morayEel, 1),
      Weighted(drownedSailor, 3),
      Weighted(brineHag, 2),
    ],
  ),
  5: DungeonSpawnTable(
    minCount: 8,
    maxCount: 10,
    entries: [Weighted(drownedSailor, 2), Weighted(brineHag, 3)],
  ),
};

/// What each depth of the sea-cave can give up.
///
/// **One notch richer than the crypt at the same depth**, which is the theme's
/// whole payment: the cave is a crypt graduate's next stop, the creatures hit
/// harder and pierce deeper, and the rarity curve is the crypt's own curve read
/// one floor further down. Depth five goes past the crypt's bottom because there
/// is no sixth crypt floor to copy — it continues the same slide rather than
/// inventing a new one.
const Map<int, DropTable> seaCaveDropTables = {
  1: DropTable(
    items: [
      Weighted(healingPotion, 9),
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
    minFloorItems: 3,
    maxFloorItems: 5,
  ),
  2: DropTable(
    items: [
      Weighted(healingPotion, 9),
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
    minFloorItems: 3,
    maxFloorItems: 5,
  ),
  3: DropTable(
    items: [
      Weighted(healingPotion, 9),
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
    minFloorItems: 3,
    maxFloorItems: 5,
  ),
  4: DropTable(
    items: [
      Weighted(healingPotion, 9),
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
    minFloorItems: 3,
    maxFloorItems: 5,
  ),
  5: DropTable(
    items: [
      Weighted(healingPotion, 9),
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
    minFloorItems: 3,
    maxFloorItems: 5,
  ),
};

/// What the captain is standing over.
///
/// The bottom table with the sub-rare tiers weighted to nothing — the same
/// weight-zero idiom [Rarity.legendary] rides everywhere else — so the one
/// guaranteed item of the run cannot come back Common. **The potion's weight
/// goes to nothing too, and that is not tidiness:** [rollDrop] forces a
/// consumable to Common whatever the rarity list says, so a trophy that rolled a
/// healing potion would break the promise while every weight still read as
/// rare-or-better.
const DropTable seaCaveTrophyTable = DropTable(
  items: [
    Weighted(healingPotion, 0),
    Weighted(warAxe, 6),
    Weighted(greatsword, 6),
    Weighted(maul, 5),
    Weighted(kiteShield, 6),
    Weighted(ironHelm, 6),
    Weighted(mailHauberk, 10),
    Weighted(ironGauntlets, 5),
    Weighted(ironGreaves, 6),
  ],
  rarities: [
    Weighted(Rarity.common, 0),
    Weighted(Rarity.fine, 0),
    Weighted(Rarity.rare, 70),
    Weighted(Rarity.epic, 30),
    Weighted(Rarity.legendary, 0),
  ],
  weaponAffixes: weaponAffixes,
  armourAffixes: armourAffixes,
  minFloorItems: 0,
  maxFloorItems: 0,
);
