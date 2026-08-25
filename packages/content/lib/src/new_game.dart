import 'package:residuum_core/core.dart';

import 'armory.dart';
import 'drop_tables.dart';
import 'spawn_tables.dart';
import 'spells.dart';

/// What the loot stream's seed is offset by, so it never runs in step with the
/// combat stream.
///
/// A literal rather than a derived value, because a world seed has to describe
/// the same loot to every player who types it in — including one running a
/// build compiled years apart from another's.
const int lootStreamSalt = 0x100D;

/// The hero, as every crawl begins: twenty hit points, bare fists, and the
/// baseline speed everything else is measured against.
///
/// The fists are the *whole* of the hero's own attack. A weapon adds to this
/// rather than replacing it, so an unarmed hero still punches for one or two,
/// and the starting rusty sword's `+2/+3` lands the opening attack on three to
/// five — the same three to five the game shipped with before there was any
/// such thing as a weapon to take off.
Actor _freshHero(Position at) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: 20,
  maxHp: 20,
  attackMin: 1,
  attackMax: 2,
  speed: 10,
  energy: actThreshold,
);

/// What the hero is wearing when it walks in: one rusty sword.
Equipment _startingEquipment() => {
  EquipSlot.mainHand: const Item(
    id: 'kit-1',
    base: rustySword,
    rarity: Rarity.common,
  ),
};

/// What the hero is carrying when it walks in: two healing potions.
///
/// Two, not one and not five. One is a single mistake's worth of slack and five
/// makes the first two floors a formality; two is enough to survive a bad room
/// and not enough to survive a bad plan.
List<Item> _startingInventory() => const [
  Item(id: 'kit-2', base: healingPotion, rarity: Rarity.common),
  Item(id: 'kit-3', base: healingPotion, rarity: Rarity.common),
];

/// The floor at [depth] of the dungeon that [worldSeed] and [visit] describe.
///
/// Layout comes from the generator's own generator-of-numbers, seeded on the
/// floor seed alone. Which creature stands on which tile is drawn from the same
/// stream, and so is what lies on the ground — and all three are separate from
/// the crawl's combat stream, so how a fight goes can never reshuffle the map,
/// and two players sharing a world seed walk the same five floors and find the
/// same things lying on them.
///
/// Monster ids are the creature's id plus its place in the spawn list, and item
/// ids are the depth plus their place in the litter, which makes both unique on
/// the floor by construction.
Floor buildFloor(int depth, {required int worldSeed, required int visit}) {
  final seed = floorSeed(worldSeed, depth, visit);
  final table = spawnTableFor(depth);
  final drops = dropTableFor(depth);
  final rng = Rng(seed);
  final count = table.rollCount(rng);
  final itemCount = rollFloorItemCount(drops, rng);
  final generated = generateFloor(
    seed,
    depth,
    monsterCount: count,
    itemCount: itemCount,
  );
  final monsters = <Actor>[];
  for (final spawn in generated.monsterSpawns) {
    final creature = table.rollCreature(rng);
    monsters.add(
      creature.spawn(id: '${creature.id}-${monsters.length + 1}', at: spawn),
    );
  }
  final groundItems = <Position, List<Item>>{};
  for (final spawn in generated.itemSpawns) {
    final item = rollDrop(drops, rng, 'floor-$depth-${groundItems.length + 1}');
    groundItems[spawn] = [item];
  }
  assert(
    monsters.map((monster) => monster.id).toSet().length == monsters.length,
    'two monsters on depth $depth share an id',
  );
  return Floor(
    map: generated.map,
    heroSpawn: generated.heroSpawn,
    stairsDown: generated.stairsDown,
    monsters: monsters,
    groundItems: groundItems,
  );
}

/// A hero who has never gone down: armed, stocked, untrained, broke, and with no
/// spell to their name.
///
/// The hero stands nowhere in particular, because a profile is a hero between
/// runs and there is no floor to stand on. `startDungeonRunAt` is what puts it
/// on one.
Profile newProfile({int worldSeed = 1}) => Profile(
  hero: _freshHero(const Position(0, 0)),
  worldSeed: worldSeed,
  equipment: _startingEquipment(),
  inventory: _startingInventory(),
  skills: untrainedSkills,
);

/// The dungeon [worldSeed] describes, ready to be reshuffled by a visit.
Dungeon residuumDungeon(int worldSeed) =>
    (visit) =>
        (depth) => buildFloor(depth, worldSeed: worldSeed, visit: visit);

/// A fresh crawl on the first floor of the dungeon [worldSeed] describes, laid
/// out for [visit].
///
/// The direct door: no profile, no visit bump, exactly the crawl the arguments
/// name. `startDungeonRunAt` is the door the town walks through.
GameState newGame({int worldSeed = 1, int visit = 0}) {
  final floor = buildFloor(1, worldSeed: worldSeed, visit: visit);
  final visible = computeFov(floor.map, floor.heroSpawn, fovRadius);
  return GameState(
    map: floor.map,
    hero: _freshHero(floor.heroSpawn),
    monsters: floor.monsters,
    rng: Rng(worldSeed),
    lootRng: Rng(worldSeed ^ lootStreamSalt),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) =>
        buildFloor(depth, worldSeed: worldSeed, visit: visit),
    depth: 1,
    worldSeed: worldSeed,
    visit: visit,
    stairsDown: floor.stairsDown,
    groundItems: floor.groundItems,
    inventory: _startingInventory(),
    equipment: _startingEquipment(),
    skills: untrainedSkills,
    dropTables: dropTables,
    spells: spellsById,
    mana: heroMaxMana(const Loadout(equipment: {}, skills: untrainedSkills)),
  );
}
