import 'package:residuum_core/core.dart';

import 'first_floor.dart';

/// A fresh crawl on the first floor.
///
/// The hero carries the rusty sword, folded straight into its attack range —
/// Milestone 1 has no inventory to hang a weapon on.
GameState newGame({int seed = 1}) {
  final map = FloorMap.parse(firstFloorAscii);
  const hero = Actor(
    id: 'hero',
    glyph: '@',
    position: heroSpawn,
    hp: 20,
    maxHp: 20,
    attackMin: 3,
    attackMax: 5,
  );
  final monsters = <Actor>[
    for (var index = 0; index < ghoulSpawns.length; index++)
      Actor(
        id: 'ghoul-${index + 1}',
        glyph: 'g',
        position: ghoulSpawns[index],
        hp: 10,
        maxHp: 10,
        attackMin: 2,
        attackMax: 4,
      ),
  ];
  final visible = computeFov(map, hero.position, fovRadius);
  return GameState(
    map: map,
    hero: hero,
    monsters: monsters,
    rng: Rng(seed),
    visible: visible,
    explored: {...visible},
  );
}
