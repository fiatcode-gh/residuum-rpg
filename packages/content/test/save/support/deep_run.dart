import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// A crawl standing on [depth] with every shallower floor fully walked.
///
/// The worst case a save has to carry: five floors of terrain, monsters, litter
/// and lifted fog. The encode-cost measurement and the multi-floor round-trip
/// both need exactly this.
///
/// The way back up follows the rule `step` follows when it builds a floor: below
/// depth one, the arrival tile is the stairs up where the generator did not name
/// one. Without that, a synthesized state would be one no descent could have
/// produced, and a test built on it would prove nothing about resuming.
///
/// The nodes come from the builder for the same reason: a floor walked away from
/// keeps the veins nobody worked, so a synthesized state with none would be a
/// state no descent could have produced.
GameState deepRun({int worldSeed = 7, int depth = 5, int visit = 1}) {
  final builder = residuumDungeon(worldSeed)(visit);
  final floors = <int, FloorMemory>{};
  for (var shallower = 1; shallower < depth; shallower++) {
    final floor = builder(shallower);
    floors[shallower] = FloorMemory(
      map: floor.map,
      monsters: floor.monsters,
      groundItems: floor.groundItems,
      nodes: floor.nodes,
      explored: walkableTiles(floor.map),
      stairsDown: floor.stairsDown,
      stairsUp: shallower == 1 ? null : (floor.stairsUp ?? floor.heroSpawn),
    );
  }
  final here = builder(depth);
  return GameState(
    map: here.map,
    hero: newProfile(
      worldSeed: worldSeed,
    ).hero.copyWith(position: here.heroSpawn, energy: actThreshold),
    monsters: here.monsters,
    rng: Rng.fromState(-8613303245920329199),
    lootRng: Rng.fromState(2420599403871909411),
    visible: computeFov(here.map, here.heroSpawn, fovRadius),
    explored: walkableTiles(here.map),
    buildFloor: builder,
    depth: depth,
    worldSeed: worldSeed,
    visit: visit,
    stairsDown: here.stairsDown,
    stairsUp: depth == 1 ? null : (here.stairsUp ?? here.heroSpawn),
    gold: 137,
    floors: floors,
    groundItems: here.groundItems,
    nodes: here.nodes,
    inventory: const [
      Item(id: 'kit-2', base: healingPotion, rarity: Rarity.common),
    ],
    equipment: const {
      EquipSlot.mainHand: Item(
        id: 'drop-3',
        base: warAxe,
        rarity: Rarity.rare,
        affixes: [keen, ofEmbers],
      ),
    },
    skills: const {
      SkillId.arms: SkillState(level: 9, xp: 4),
      SkillId.might: SkillState(),
      SkillId.bulwark: SkillState(level: 2, xp: 1),
      SkillId.fleetfoot: SkillState(xp: 3),
    },
    dropTables: dropTables,
    nextDropNumber: 12,
  );
}

/// Every tile of [map] an actor could stand on.
Set<Position> walkableTiles(FloorMap map) => {
  for (var y = 0; y < map.height; y++)
    for (var x = 0; x < map.width; x++)
      if (map.isWalkable(Position(x, y))) Position(x, y),
};
