import '../dungeon/floor.dart';
import '../dungeon/floor_map.dart';
import '../dungeon/floor_memory.dart';
import '../loot/drop.dart';
import '../loot/item.dart';
import '../loot/loadout.dart';
import '../skills/skill.dart';
import 'actor.dart';
import 'position.dart';
import 'rng.dart';

/// The most the hero can carry unworn.
///
/// A cap exists so that a full inventory is a decision — drop something, or
/// leave the drop behind — rather than a vacuum the player drags behind them.
const int inventoryCap = 20;

/// The whole state of one crawl.
///
/// Every field is immutable except [rng], [lootRng] and [buildFloor], which are
/// carried by reference. That is a deliberate, documented exception to the
/// immutable-state rule: threading a fresh generator out of every combat roll
/// would put a return value on every rule function for no gain in testability.
/// Determinism survives it, because determinism here means "the same seed plus
/// the same sequence of actions produces the same game" — each generator
/// advances once per roll, in rule order, so a replayed action sequence draws
/// the same numbers. Nothing relies on re-reading an earlier roll after a
/// *different* action sequence, and nothing may start to.
class GameState {
  GameState({
    required this.map,
    required this.hero,
    required List<Actor> monsters,
    required this.rng,
    required this.lootRng,
    required Set<Position> visible,
    required Set<Position> explored,
    required this.buildFloor,
    this.depth = 1,
    this.worldSeed = 1,
    this.visit = 0,
    this.stairsDown,
    this.stairsUp,
    this.gold = 0,
    this.isGameOver = false,
    Map<int, FloorMemory> floors = const {},
    Map<Position, List<Item>> groundItems = const {},
    List<Item> inventory = const [],
    Equipment equipment = const {},
    Map<SkillId, SkillState> skills = untrainedSkills,
    Map<int, DropTable> dropTables = const {},
    this.nextDropNumber = 1,
  }) : monsters = List.unmodifiable(monsters),
       visible = Set.unmodifiable(visible),
       explored = Set.unmodifiable(explored),
       groundItems = Map.unmodifiable({
         for (final tile in groundItems.entries)
           tile.key: List<Item>.unmodifiable(tile.value),
       }),
       floors = Map.unmodifiable(floors),
       inventory = List.unmodifiable(inventory),
       equipment = Map.unmodifiable(equipment),
       skills = Map.unmodifiable(skills),
       dropTables = Map.unmodifiable(dropTables);

  final FloorMap map;
  final Actor hero;

  /// Living monsters only. The dead are removed, not flagged.
  final List<Actor> monsters;

  final Rng rng;

  /// The stream every drop roll draws from, kept apart from [rng].
  ///
  /// Loot has to be a property of the world, not of how a fight went. If drops
  /// shared the combat stream, two players on one world seed who killed the
  /// same monsters in a different order — or who simply missed one extra swing
  /// on the way — would find different loot, and a shared seed would stop
  /// describing a shared dungeon. Splitting the streams is what makes "seed 7,
  /// depth 3, the axe is in the north room" a sentence one player can say to
  /// another and have it be true.
  final Rng lootRng;

  /// What the hero can see from where it now stands.
  final Set<Position> visible;

  /// Every tile the hero has ever seen, drawn dimmed when out of sight.
  final Set<Position> explored;

  /// How the next floor down is made. See [FloorBuilder].
  final FloorBuilder buildFloor;

  /// Which floor the hero is on, counting from one.
  final int depth;

  /// The seed the whole dungeon derives from.
  final int worldSeed;

  /// How many times this dungeon has been reshuffled.
  ///
  /// Every entry bumps it — see `startRun` — so re-entering after a death, or
  /// after a walk home with the haul, lays out five new floors from the same
  /// world.
  final int visit;

  /// Where the stairs down are on this floor, or null on the deepest one.
  final Position? stairsDown;

  /// Where the stairs up are on this floor, or null on depth one.
  final Position? stairsUp;

  /// Every floor the hero has left and can walk back onto, by depth.
  ///
  /// The floor the hero is standing on is **not** in here: that one is the map,
  /// the monsters and the ground items on the state itself. Keeping the active
  /// floor out of the snapshots means there is never a second copy of it to go
  /// stale, and a lookup by depth can never hand back the floor you are already
  /// on.
  final Map<int, FloorMemory> floors;

  /// What the hero is carrying in coin. Dying in the dungeon loses all of it.
  ///
  /// Nothing in `step` ever changes this. Monsters do not drop coin — selling
  /// what they drop is the whole economy — so gold rides a run as a passenger,
  /// and only the town moves it.
  final int gold;

  final bool isGameOver;

  /// What is lying on the floor, by tile.
  ///
  /// A tile with nothing on it has no entry rather than an empty list, so the
  /// map's size is the number of littered tiles and never the floor's area.
  final Map<Position, List<Item>> groundItems;

  /// What the hero is carrying but not wearing. Never longer than
  /// [inventoryCap].
  final List<Item> inventory;

  /// What the hero is wearing, by slot.
  final Equipment equipment;

  /// All four skills, always present.
  final Map<SkillId, SkillState> skills;

  /// What each depth can give up.
  ///
  /// Empty means this crawl has no loot in it at all, which is what most rule
  /// tests want and why it is not required.
  final Map<int, DropTable> dropTables;

  /// The number the next kill's item id is built from.
  final int nextDropNumber;

  /// The gear and training every effective hero stat derives from.
  Loadout get loadout => Loadout(equipment: equipment, skills: skills);

  /// What is lying on [position], oldest first.
  List<Item> itemsAt(Position position) => groundItems[position] ?? const [];

  /// The living monster standing on [position], or null when none does.
  Actor? monsterAt(Position position) {
    for (final monster in monsters) {
      if (monster.position == position) return monster;
    }
    return null;
  }

  GameState copyWith({
    FloorMap? map,
    Actor? hero,
    List<Actor>? monsters,
    Set<Position>? visible,
    Set<Position>? explored,
    int? depth,
    Position? stairsDown,
    bool clearStairsDown = false,
    Position? stairsUp,
    bool clearStairsUp = false,
    Map<int, FloorMemory>? floors,
    bool? isGameOver,
    Map<Position, List<Item>>? groundItems,
    List<Item>? inventory,
    Equipment? equipment,
    Map<SkillId, SkillState>? skills,
    int? nextDropNumber,
  }) => GameState(
    map: map ?? this.map,
    hero: hero ?? this.hero,
    monsters: monsters ?? this.monsters,
    rng: rng,
    lootRng: lootRng,
    visible: visible ?? this.visible,
    explored: explored ?? this.explored,
    buildFloor: buildFloor,
    depth: depth ?? this.depth,
    worldSeed: worldSeed,
    visit: visit,
    stairsDown: clearStairsDown ? null : (stairsDown ?? this.stairsDown),
    stairsUp: clearStairsUp ? null : (stairsUp ?? this.stairsUp),
    gold: gold,
    floors: floors ?? this.floors,
    isGameOver: isGameOver ?? this.isGameOver,
    groundItems: groundItems ?? this.groundItems,
    inventory: inventory ?? this.inventory,
    equipment: equipment ?? this.equipment,
    skills: skills ?? this.skills,
    dropTables: dropTables,
    nextDropNumber: nextDropNumber ?? this.nextDropNumber,
  );
}
