import 'package:residuum_core/core.dart';

import '../drop_tables.dart';
import '../new_game.dart';
import 'actor_codec.dart';
import 'item_codec.dart';
import 'save_json.dart';

/// One suspended crawl, whole.
///
/// Everything the state holds except the two collaborators it carries by
/// reference — the floor builder and the drop tables — which come back from
/// content on load, exactly as `startRun` supplies them going in.
///
/// The floor the hero is standing on is written from the state's own fields, not
/// from [GameState.floors], which deliberately never holds it. Nothing in a
/// round-trip of `floors` alone would notice the active floor going missing, so
/// the map, monsters, litter and lifted fog of the current depth are named here
/// one by one.
///
/// **[GameState.isEncounter] is missing on purpose, and must stay missing.** A
/// road fight is never written down: it is re-derived from the world seed and
/// the day counter, both of which the world block already holds for their own
/// reasons, so an app killed mid-fight comes back to the same day, the same
/// creatures and a fresh fight rather than to a half-resolved one. What *is*
/// written is the journey, which is why the hero picks up where they were on
/// the road. The asymmetry looks like an oversight and is the design: anything
/// this encoded would be a fight the save could disagree with the world about.
/// Every run that comes back through [loadRun] is a crawl, and takes the
/// field's default.
Map<String, Object?> encodeRun(GameState run) => {
  'depth': run.depth,
  'worldSeed': encodeWide(run.worldSeed),
  'visit': run.visit,
  'gold': run.gold,
  'isGameOver': run.isGameOver,
  'nextDropNumber': run.nextDropNumber,
  'rngState': encodeWide(run.rng.state),
  'lootRngState': encodeWide(run.lootRng.state),
  'map': run.map.toAscii(),
  'hero': encodeActor(run.hero),
  'monsters': encodeActors(run.monsters),
  'visible': encodePositions(run.visible),
  'explored': encodePositions(run.explored),
  'stairsDown': encodeNullablePosition(run.stairsDown),
  'stairsUp': encodeNullablePosition(run.stairsUp),
  'groundItems': encodeGroundItems(run.groundItems),
  'inventory': encodeItems(run.inventory),
  'equipment': encodeEquipment(run.equipment),
  'skills': encodeSkills(run.skills),
  'floors': _encodeFloors(run.floors),
};

/// The crawl written at [key], ready to be played on.
///
/// **Resuming is not entering, so the visit is not bumped.** `startRun` bumps it
/// because walking in is what reshuffles the dungeon; a resume is that same walk
/// continuing. A bump here would change the floors under the player's feet
/// between one launch and the next — the floor they are standing on would stay,
/// because it is written in this document, and every floor below it would
/// silently become somebody else's.
///
/// The generators are restored with [Rng.fromState] rather than re-seeded from
/// the world seed. A re-seed would look identical in every field and be wrong in
/// every roll after it.
GameState loadRun(Map<String, Object?> from, String key) {
  final written = objectAt(from, key);
  final worldSeed = wideAt(written, 'worldSeed');
  final visit = intAt(written, 'visit');
  return GameState(
    map: _parseMap(stringAt(written, 'map')),
    hero: decodeActor(written['hero']),
    monsters: decodeActors(written, 'monsters'),
    rng: Rng.fromState(wideAt(written, 'rngState')),
    lootRng: Rng.fromState(wideAt(written, 'lootRngState')),
    visible: decodePositions(written, 'visible'),
    explored: decodePositions(written, 'explored'),
    buildFloor: residuumDungeon(worldSeed)(visit),
    depth: intAt(written, 'depth'),
    worldSeed: worldSeed,
    visit: visit,
    stairsDown: decodeNullablePosition(written, 'stairsDown'),
    stairsUp: decodeNullablePosition(written, 'stairsUp'),
    gold: intAt(written, 'gold'),
    isGameOver: boolAt(written, 'isGameOver'),
    floors: _decodeFloors(written),
    groundItems: decodeGroundItems(written, 'groundItems'),
    inventory: decodeItems(written, 'inventory'),
    equipment: decodeEquipment(written, 'equipment'),
    skills: decodeSkills(written, 'skills'),
    dropTables: dropTables,
    nextDropNumber: intAt(written, 'nextDropNumber'),
  );
}

List<Object?> _encodeFloors(Map<int, FloorMemory> floors) {
  final depths = floors.keys.toList()..sort();
  return [
    for (final depth in depths)
      {
        'depth': depth,
        'map': floors[depth]!.map.toAscii(),
        'monsters': encodeActors(floors[depth]!.monsters),
        'groundItems': encodeGroundItems(floors[depth]!.groundItems),
        'explored': encodePositions(floors[depth]!.explored),
        'stairsDown': encodeNullablePosition(floors[depth]!.stairsDown),
        'stairsUp': encodeNullablePosition(floors[depth]!.stairsUp),
      },
  ];
}

Map<int, FloorMemory> _decodeFloors(Map<String, Object?> written) {
  final floors = <int, FloorMemory>{};
  for (final entry in listAt(written, 'floors')) {
    if (entry is! Map<String, Object?>) {
      throw SaveMalformed('a floor in the save file is not an object');
    }
    floors[intAt(entry, 'depth')] = FloorMemory(
      map: _parseMap(stringAt(entry, 'map')),
      monsters: decodeActors(entry, 'monsters'),
      groundItems: decodeGroundItems(entry, 'groundItems'),
      explored: decodePositions(entry, 'explored'),
      stairsDown: decodeNullablePosition(entry, 'stairsDown'),
      stairsUp: decodeNullablePosition(entry, 'stairsUp'),
    );
  }
  return floors;
}

FloorMap _parseMap(String ascii) {
  try {
    return FloorMap.parse(ascii);
  } on ArgumentError {
    throw SaveMalformed('a floor in the save file is not a readable map');
  }
}
