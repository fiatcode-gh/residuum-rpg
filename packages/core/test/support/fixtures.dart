import 'package:residuum_core/core.dart';

Actor hero(
  Position at, {
  int hp = 20,
  int attack = 4,
  int? attackMax,
  int speed = 10,
}) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: hp,
  maxHp: 20,
  attackMin: attack,
  attackMax: attackMax ?? attack,
  speed: speed,
  energy: actThreshold,
);

Actor ghoul(
  String id,
  Position at, {
  int hp = 10,
  int attack = 3,
  int speed = 10,
  int dropChance = 0,
  int pierce = 0,
  Set<DamageType> resists = const {},
  Set<DamageType> vulnerableTo = const {},
}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
  speed: speed,
  energy: actThreshold,
  dropChance: dropChance,
  pierce: pierce,
  resists: resists,
  vulnerableTo: vulnerableTo,
);

Floor noFloorBelow(int depth) =>
    throw StateError('this crawl was not meant to descend');

/// A craft-stream state whose next percent roll lands at or above [floor].
int stateRollingAtLeast(int floor) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) >= floor) return state;
  }
  throw StateError('no state rolls at or above $floor');
}

/// A craft-stream state whose next percent roll lands below [ceiling].
int stateRollingBelow(int ceiling) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) < ceiling) return state;
  }
  throw StateError('no state rolls below $ceiling');
}

/// A craft-stream state whose next [draws] percent rolls all land at or above
/// [floor].
int stateRollingAtLeastFor(int floor, int draws) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    var clean = true;
    for (var roll = 0; roll < draws; roll++) {
      if (rng.rollRange(0, 99) < floor) clean = false;
    }
    if (clean) return state;
  }
  throw StateError('no state rolls at or above $floor for $draws draws');
}

GameState crawl({
  required String ascii,
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
  int heroAttack = 4,
  int? heroAttackMax,
  int heroSpeed = 10,
  int seed = 1,
  int lootSeed = 2,
  int depth = 1,
  Position? stairsDown,
  Position? stairsUp,
  Map<int, FloorMemory> floors = const {},
  int gold = 0,
  FloorBuilder buildFloor = noFloorBelow,
  Map<Position, List<Item>> groundItems = const {},
  List<Item> inventory = const [],
  Equipment equipment = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
  Map<int, DropTable> dropTables = const {},
  Map<String, Spell> spells = const {},
  Set<String> knownSpells = const {},
  Map<String, int> bound = const {},
  Map<MaterialId, int> materials = const {},
  int mana = 0,
  int warded = 0,
  int nextDropNumber = 1,
  bool isEncounter = false,
}) {
  final map = FloorMap.parse(ascii);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: hero(
      heroAt,
      hp: heroHp,
      attack: heroAttack,
      attackMax: heroAttackMax,
      speed: heroSpeed,
    ),
    monsters: monsters,
    rng: Rng(seed),
    lootRng: Rng(lootSeed),
    visible: visible,
    explored: {...visible},
    buildFloor: buildFloor,
    depth: depth,
    stairsDown: stairsDown,
    stairsUp: stairsUp,
    floors: floors,
    gold: gold,
    groundItems: groundItems,
    inventory: inventory,
    equipment: equipment,
    skills: skills,
    dropTables: dropTables,
    spells: spells,
    knownSpells: knownSpells,
    bound: bound,
    materials: materials,
    mana: mana,
    warded: warded,
    nextDropNumber: nextDropNumber,
    isEncounter: isEncounter,
  );
}
