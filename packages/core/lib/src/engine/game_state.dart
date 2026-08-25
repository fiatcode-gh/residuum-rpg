import '../dungeon/floor.dart';
import '../dungeon/floor_map.dart';
import '../dungeon/floor_memory.dart';
import '../dungeon/generator.dart';
import '../loot/drop.dart';
import '../loot/item.dart';
import '../loot/loadout.dart';
import '../magic/spell.dart';
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
    this.deepest = deepestDepth,
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
    Map<String, Spell> spells = const {},
    Set<String> knownSpells = const {},
    Map<String, int> bound = const {},
    this.mana = 0,
    this.warded = 0,
    this.nextDropNumber = 1,
    this.isEncounter = false,
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
       dropTables = Map.unmodifiable(dropTables),
       spells = Map.unmodifiable(spells),
       knownSpells = Set.unmodifiable(knownSpells),
       bound = Map.unmodifiable(bound);

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

  /// How many floors this delve laid out. The floor at [deepest] is the one
  /// with no way down, and the only one the boss and the trophy stand on.
  ///
  /// **Optional with a default, because a road fight has no bottom.** An
  /// encounter is the same engine on smaller ground: nothing on the road reads
  /// this, and a fixture that only wants a grid and two actors should not have
  /// to invent a depth for a dungeon it is not in. The default is the crypt's
  /// five — the one dungeon whose depth is not rolled — so a state built
  /// without naming one is the state the game has always built.
  ///
  /// **Never written to a save file, and re-derived instead.** The depth is a
  /// pure function of the dungeon, the world seed and the visit, all three of
  /// which the save already holds for their own reasons, so `loadRun`
  /// recomputes it exactly as it recomputes the floor builder and the drop
  /// tables. A delve that stored its own depth would be a save document that
  /// could disagree with the world about how deep a place is.
  final int deepest;

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

  /// All seven skills, always present.
  final Map<SkillId, SkillState> skills;

  /// What each depth can give up.
  ///
  /// Empty means this crawl has no loot in it at all, which is what most rule
  /// tests want and why it is not required.
  final Map<int, DropTable> dropTables;

  /// The number the next kill's item id is built from.
  final int nextDropNumber;

  /// Every spell this build knows how to cast, by id.
  ///
  /// Content data carried by identity, exactly as [dropTables] are, and injected
  /// at the same door: the rules know the five spell kinds and nothing about
  /// which spells exist. Empty means this crawl has no magic in it at all, which
  /// is what most rule tests want and why it is not required.
  final Map<String, Spell> spells;

  /// What the hero has learned to cast, by spell id.
  ///
  /// Mirrors [skills] in every way that matters: learned by doing, kept on the
  /// [Profile] between runs, and carried home through death. A book is spent to
  /// get one, and nothing takes one away.
  final Set<String> knownSpells;

  /// What the hero has left to cast with on this floor.
  ///
  /// **A run field, and never on [Actor] or [Profile].** Monsters do not cast,
  /// so a pool on the actor would be a number written into every monster of
  /// every save for nothing; and a pool on the profile would be a resource the
  /// town could sell, which a per-floor budget that starts full makes
  /// meaningless. It refills on arriving at a floor this run has never built —
  /// see `step`'s arrival — so what magic costs is what the floor can afford,
  /// not what the purse can.
  final int mana;

  /// What is left of the hero's ward: damage it will soak before hit points do.
  ///
  /// Zero when no ward stands. A second ward replaces this rather than adding to
  /// it, so the spell is a decision about timing and never a pool to stack up
  /// before walking downstairs.
  final int warded;

  /// How many scheduled turns each held monster still has to sit out, by id.
  ///
  /// **Cleared on every arrival**, because a monster id is unique to a floor and
  /// not to a run: the crypt's first ghoul is `ghoul-1` on depth one and a
  /// different `ghoul-1` waits on depth two, so a counter carried down the
  /// stairs would hold a monster the hero never bound.
  final Map<String, int> bound;

  /// Whether this is a fight on the road rather than a crawl in the dungeon.
  ///
  /// **It changes exactly one rule: a step off the grid is fleeing rather than
  /// a bumped wall.** That is the whole of it. Nothing else in `step` reads
  /// this, and nothing else should — an encounter is the same engine on smaller
  /// ground, and a field that started forking combat or the monster phase would
  /// make two games out of one.
  ///
  /// **Inert in a crawl, and pinned so.** A crawl's border is solid wall by
  /// construction — the generator insets every room one tile inside its leaf
  /// and corridors only join room centres — so a crawling hero can never stand
  /// on the grid edge and never reach the branch this field guards. Turning it
  /// on for a crawl therefore changes nothing observable, which is a stated
  /// property rather than an accident: the flee rule is safe to add to the one
  /// `step` both worlds share precisely because the crypt cannot get to it.
  ///
  /// **Never written to a save file.** An encounter is re-derived from the world
  /// and the day, so there is nothing to restore; a decoded crawl gets the
  /// default of false. See `encodeRun` for why that asymmetry is deliberate.
  final bool isEncounter;

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
    Set<String>? knownSpells,
    Map<String, int>? bound,
    int? mana,
    int? warded,
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
    deepest: deepest,
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
    spells: spells,
    knownSpells: knownSpells ?? this.knownSpells,
    bound: bound ?? this.bound,
    mana: mana ?? this.mana,
    warded: warded ?? this.warded,
    nextDropNumber: nextDropNumber ?? this.nextDropNumber,
    isEncounter: isEncounter,
  );
}
