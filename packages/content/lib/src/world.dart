import 'package:residuum_core/core.dart';

import 'affix_pool.dart';
import 'armory.dart';
import 'new_game.dart';
import 'spawn_tables.dart';

/// What the travel day's seed is offset by, so a road never draws in step with
/// a floor or a shelf.
///
/// A literal rather than a derived value, for [lootStreamSalt]'s reason: a world
/// seed has to describe the same roads to every player who types it in.
const int travelSalt = 0x7A0D;

/// What the fight a travel day produced is offset by.
///
/// A second salt rather than reuse of [travelSalt], because the decision to have
/// a fight and the fight itself must not be read off one number. Sharing the
/// seed would make the shape of the ambush a function of how narrowly the danger
/// roll landed, and two things that are supposed to be independent would move
/// together.
const int ambushSalt = 0x0A3B;

/// The world seed with the road salt folded in, ready for `roadSeed`.
int travelSeedFor(int worldSeed) => worldSeed ^ travelSalt;

/// The ground the ambush on [day] of the world [worldSeed] describes is laid out
/// on.
///
/// Mixed at a different slot from [ambushFightSeed] so the layout and the blows
/// struck on it come off separate streams. The slots are `floorSeed`'s depth
/// argument used as a purpose rather than a depth, which is the market's own
/// trick: the road is not a depth, and neither is a fight on it.
int ambushGroundSeed(int worldSeed, int day) =>
    floorSeed(worldSeed ^ ambushSalt, _groundSlot, day);

/// The stream the ambush on [day] of the world [worldSeed] describes is fought
/// on.
///
/// **Per day, unlike a crawl's.** `startRun` re-seeds combat from the world seed
/// on every entry, so two crawls of one world trade the same blows; that is
/// tolerable when entering is rare and deliberate. Road fights are neither, and
/// a hero who met wolves on four different days should not watch the same four
/// swings each time. The day is already in the derivation, so this costs
/// nothing.
int ambushFightSeed(int worldSeed, int day) =>
    floorSeed(worldSeed ^ ambushSalt, _fightSlot, day);

const int _groundSlot = 2;
const int _fightSlot = 1;

/// The road is not a depth, and zero is not one either.
///
/// The market's argument, for the same purpose: a road fight has to key a drop
/// table by something, and keying it at a depth the dungeon does not have is
/// what keeps the road's loot and the crypt's loot from ever being the same
/// lookup.
const int roadDepth = 0;

/// The town a hero starts in, and the one they wake in until they sleep
/// elsewhere.
final NodeId stonebridge = NodeId('stonebridge');

/// The second town: hidden on a fresh save, and worth the walk for its own
/// shelf.
final NodeId northgate = NodeId('northgate');

/// The dungeon node. What is under it is the crawl the game shipped with.
final NodeId cryptNode = NodeId('crypt');

/// The world the game ships: two towns, one dungeon, and a road between every
/// pair.
///
/// **A triangle, and the day costs are the whole economy of the thing.**
///
/// Stonebridge to the crypt is one day and the safest road, because that is the
/// loop the hero walks constantly — bank the haul, buy potions, go back down.
/// Taxing it heavily would tax the game's core loop, and the farming economy
/// (D14) rests on that loop staying cheap.
///
/// Both Northgate roads are two days, which makes shopping the other shelf a
/// four-day round trip. That number is the point: it is what finally prices the
/// suspend-then-sleep-at-the-inn interim the leave unit shipped with (D35). A
/// hero who camps at the stairs to heal now pays for it in days of encounter
/// rolls rather than in twelve gold, and the road is the cost.
///
/// The back road from Northgate to the crypt is the most dangerous, because it
/// is the one that skips a town. A route that let the hero bypass Stonebridge as
/// cheaply as going through it would make the middle of the map decoration.
final WorldMap residuumWorld = WorldMap(
  nodes: [
    WorldNode(id: stonebridge, kind: NodeKind.town, name: 'Stonebridge'),
    WorldNode(id: northgate, kind: NodeKind.town, name: 'Northgate'),
    WorldNode(id: cryptNode, kind: NodeKind.dungeon, name: 'The Crypt'),
  ],
  routes: [
    Route(from: stonebridge, to: cryptNode, days: 1, danger: 15),
    Route(from: stonebridge, to: northgate, days: 2, danger: 25),
    Route(from: northgate, to: cryptNode, days: 2, danger: 30),
  ],
);

/// The chance in a hundred that a day which was not a fight had somebody on it.
///
/// Checked after the danger roll, so a dangerous road is also a quieter one for
/// conversation — which is the right way round: the people who would stop and
/// talk are the ones who do not use the bad roads.
const int travelerChance = 20;

/// Where a hero who has never left stands, and what they have heard of.
///
/// **The second town starts hidden, and that is the whole reason discovery
/// exists.** A map with everything on it from the first save is a menu; one
/// place worth finding turns the tavern into a shop that sells something and
/// makes the first walk to Northgate an arrival rather than an errand. The home
/// town and the crypt are known because a hero who did not know where the
/// dungeon was would have nothing to do.
Whereabouts newWhereabouts() => Whereabouts(
  at: stonebridge,
  home: stonebridge,
  discovered: {stonebridge, cryptNode},
);

/// What the tavern charges to tell the hero something.
///
/// More than a night at the inn, because a bed is one night and a place on the
/// map is permanent. Cheap enough that a first haul covers it, because a world
/// the player cannot afford to uncover is a world that stays a menu.
const int rumorPrice = 15;

/// Everything the taverns have to say, in the order the world is uncovered in.
///
/// The crypt's entry can never be sold — a fresh save already knows where it is
/// — and it is here for the reason [Rarity.legendary] carries weight zero in the
/// drop tables: a table that names everything it could carry is a table a reader
/// can check. It also stops the pool from being a one-line list that reads like
/// an oversight.
final List<Rumor> rumorPool = [
  Rumor(
    line: 'A carter says there is a town north of the moor that buys iron.',
    reveals: northgate,
  ),
  Rumor(
    line: 'An old man says the crypt door on the hill still opens.',
    reveals: cryptNode,
  ),
];

/// What walks the roads.
///
/// **Rats and wolves only, and no undead.** The crypt's creatures are in the
/// crypt: a wight on a public road between two towns would be a story event, not
/// a random encounter, and the design's own themes (section 6) put the undead
/// underground. Rats and wolves read as lowland wilderness and need no
/// explanation.
///
/// The wolf's weight is what makes the road frightening rather than tedious. It
/// moves at twice the hero's speed, so it is the creature that makes fleeing a
/// decision with a cost — three tiles to the edge is three tiles it closes
/// twice over.
///
/// One table for all three roads, and the roads differ by how often they bite
/// rather than by what bites. At three nodes they are all the same lowland
/// wilderness; themed danger arrives with the sea-cave and the ruined keep,
/// which is where a second table will have something to say.
const SpawnTable roadSpawnTable = SpawnTable(
  minCount: 2,
  maxCount: 3,
  entries: [SpawnEntry('rat', 3), SpawnEntry('wolf', 2)],
);

/// What a road fight can give up.
///
/// **Thinner than any floor of the crypt, on purpose.** The dungeon is where
/// loot comes from; a road that paid as well would make travelling the way to
/// farm and the crawl the scenic route. Potions carry the heaviest weight
/// because they are what a hero who has been jumped on the way home actually
/// needs, and nothing above Fine can drop, so the road can never hand over the
/// thing the dungeon is for.
///
/// No floor litter at either end of the range: open ground has nothing lying on
/// it, and the encounter generator places no items. Every road drop comes off a
/// kill.
const DropTable roadDropTable = DropTable(
  items: [
    Weighted(healingPotion, 16),
    Weighted(rustySword, 5),
    Weighted(ironSword, 2),
    Weighted(leatherCap, 5),
    Weighted(leatherJerkin, 5),
    Weighted(leatherBoots, 5),
    Weighted(ironHelm, 2),
    Weighted(kiteShield, 2),
  ],
  rarities: [
    Weighted(Rarity.common, 80),
    Weighted(Rarity.fine, 20),
    Weighted(Rarity.rare, 0),
    Weighted(Rarity.epic, 0),
    Weighted(Rarity.legendary, 0),
  ],
  weaponAffixes: weaponAffixes,
  armourAffixes: armourAffixes,
  minFloorItems: 0,
  maxFloorItems: 0,
);

/// The fight [profile] walks into on [day], on the road they are walking.
///
/// **The road's answer to `startDungeonRun`, and the two-door discipline holds:**
/// this is the way in and `endRun` is the way out, exactly as it is for a crawl.
/// That is what makes `endRun(died: false)` a reachable door again — the leave
/// unit left it with only death coming through it — because clearing a road
/// fight or walking off the edge of one both bring the hero home alive.
///
/// **The visit is not bumped, and that is load-bearing.** `startRun` bumps
/// because walking into a dungeon is what reshuffles it; a fight on a road is
/// not walking into anything. A bump here would relay out all five floors of the
/// crypt every time a rat jumped the hero, throw away the merchant shelf they
/// were shopping at, and — worst and quietest — break `resumeRun`'s requirement
/// that a camped hero's profile and camp agree about the visit. A hero who
/// camped at the stairs and was ambushed on the way to town would find their
/// camp unresumable, with nothing on screen to say why.
///
/// The hero arrives with a full turn of energy, as they do walking into a
/// dungeon: an ambush gets the first swing at nobody, because the hero acting
/// first is what makes running a choice they are given rather than one they are
/// denied.
GameState startRoadEncounter(Profile profile, {required int day}) {
  final seed = ambushGroundSeed(profile.worldSeed, day);
  final rng = Rng(seed);
  final count = roadSpawnTable.rollCount(rng);
  final ground = generateEncounter(seed, monsterCount: count);
  final monsters = <Actor>[];
  for (final spawn in ground.monsterSpawns) {
    final creature = roadSpawnTable.rollCreature(rng);
    monsters.add(
      creature.spawn(id: '${creature.id}-${monsters.length + 1}', at: spawn),
    );
  }
  final fightSeed = ambushFightSeed(profile.worldSeed, day);
  final visible = computeFov(ground.map, ground.heroSpawn, fovRadius);
  return GameState(
    map: ground.map,
    hero: profile.hero.copyWith(
      position: ground.heroSpawn,
      energy: actThreshold,
    ),
    monsters: monsters,
    rng: Rng(fightSeed),
    lootRng: Rng(fightSeed ^ lootStreamSalt),
    visible: visible,
    explored: {...visible},
    buildFloor: _noFloorUnderTheRoad,
    depth: roadDepth,
    worldSeed: profile.worldSeed,
    visit: profile.visit,
    gold: profile.gold,
    inventory: profile.inventory,
    equipment: profile.equipment,
    skills: profile.skills,
    dropTables: const {roadDepth: roadDropTable},
    isEncounter: true,
  );
}

/// There is nothing under a road.
///
/// A road fight has no stairs, so `step` can never reach a descent — the
/// controls are not offered and `DescendAction` finds no stairs underfoot. This
/// exists to say that out loud rather than to be called: a builder that quietly
/// handed back a crypt floor would turn a bug into a dungeon nobody entered.
Floor _noFloorUnderTheRoad(int depth) =>
    throw StateError('there is no floor below a road');
