import 'package:residuum_core/core.dart';

import 'spawn_tables.dart';

/// The hero, as every crawl begins: twenty hit points, a rusty sword folded
/// straight into its attack range, and the baseline speed everything else is
/// measured against.
///
/// There is no inventory to hang a weapon on yet, so the sword is the numbers.
Actor _freshHero(Position at) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: 20,
  maxHp: 20,
  attackMin: 3,
  attackMax: 5,
  speed: 10,
  energy: actThreshold,
);

/// The floor at [depth] of the dungeon that [worldSeed] and [visit] describe.
///
/// Layout comes from the generator's own generator-of-numbers, seeded on the
/// floor seed alone. Which creature stands on which tile is drawn from the same
/// stream, and both are separate from the crawl's combat stream — so how a
/// fight goes can never reshuffle the map, and two players sharing a world seed
/// walk the same five floors.
///
/// Monster ids are the creature's id plus its place in the spawn list, which
/// makes them unique on the floor by construction.
Floor buildFloor(int depth, {required int worldSeed, required int visit}) {
  final seed = floorSeed(worldSeed, depth, visit);
  final table = spawnTableFor(depth);
  final rng = Rng(seed);
  final count = table.rollCount(rng);
  final generated = generateFloor(seed, depth, monsterCount: count);
  final monsters = <Actor>[];
  for (final spawn in generated.monsterSpawns) {
    final creature = table.rollCreature(rng);
    monsters.add(
      creature.spawn(id: '${creature.id}-${monsters.length + 1}', at: spawn),
    );
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
  );
}

/// A fresh crawl on the first floor of the dungeon [worldSeed] describes.
///
/// [visit] is 0 for now; it exists so a death can reshuffle the dungeon without
/// changing the world.
GameState newGame({int worldSeed = 1, int visit = 0}) {
  final floor = buildFloor(1, worldSeed: worldSeed, visit: visit);
  final visible = computeFov(floor.map, floor.heroSpawn, fovRadius);
  return GameState(
    map: floor.map,
    hero: _freshHero(floor.heroSpawn),
    monsters: floor.monsters,
    rng: Rng(worldSeed),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) =>
        buildFloor(depth, worldSeed: worldSeed, visit: visit),
    depth: 1,
    worldSeed: worldSeed,
    visit: visit,
    stairsDown: floor.stairsDown,
  );
}
