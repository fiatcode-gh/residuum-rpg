import 'package:residuum_core/core.dart';

import 'affix_pool.dart';
import 'armory.dart';
import 'bestiary.dart';
import 'dungeon_spawn.dart';
import 'new_game.dart';
import 'ruined_keep.dart';
import 'sea_cave.dart';

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

/// The second dungeon: a day west of Northgate, under the tide.
final NodeId seaCave = NodeId('sea-cave');

/// The third dungeon, and the longest walk to any of them.
final NodeId ruinedKeep = NodeId('ruined-keep');

/// The world the game ships: two towns, three dungeons, and the roads between
/// them.
///
/// **A triangle with two spurs off it, and the day costs are the whole economy
/// of the thing.**
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
/// The back road from Northgate to the crypt is the most dangerous of the three
/// roads between towns, because it is the one that skips a town. A route that
/// let the hero bypass Stonebridge as cheaply as going through it would make the
/// middle of the map decoration.
///
/// **Both new dungeons hang off Northgate, and neither is reachable from home.**
/// The crypt is a day from Stonebridge and everything harder is on the far side
/// of the two-day road, so the second town stops being a second shelf and
/// becomes the staging post the rest of the world is walked from. The sea-cave
/// is one day out and the keep is two, which prices them the way the crypt is
/// priced: the harder floor is also the longer walk, and a hero who wants the
/// keep's loot pays four days a trip for it before a single blow is struck.
///
/// The sea-cave road ties the crawl loop on days and doubles its danger, so the
/// crypt keeps the thing that makes it the farming loop — the cheapest road in
/// the world — without the sea-cave being an errand.
final WorldMap residuumWorld = WorldMap(
  nodes: [
    WorldNode(id: stonebridge, kind: NodeKind.town, name: 'Stonebridge'),
    WorldNode(id: northgate, kind: NodeKind.town, name: 'Northgate'),
    WorldNode(id: cryptNode, kind: NodeKind.dungeon, name: 'The Crypt'),
    WorldNode(id: seaCave, kind: NodeKind.dungeon, name: 'The Sea-Cave'),
    WorldNode(id: ruinedKeep, kind: NodeKind.dungeon, name: 'The Ruined Keep'),
  ],
  routes: [
    Route(from: stonebridge, to: cryptNode, days: 1, danger: 15),
    Route(from: stonebridge, to: northgate, days: 2, danger: 25),
    Route(from: northgate, to: cryptNode, days: 2, danger: 30),
    Route(from: northgate, to: seaCave, days: 1, danger: 30),
    Route(from: northgate, to: ruinedKeep, days: 2, danger: 40),
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

/// How many days a camp stands before the residue takes it back.
///
/// **Three, because an inn trip fits the window and a shopping tour does not.**
/// The crypt is a day from Stonebridge, so walking home, sleeping and walking
/// back costs two days and leaves a day of slack; the four-day round trip to
/// Northgate's shelf does not fit at all. That is the whole design of the
/// number: leaving the crawl at the stairs is priced, not closed, and what it
/// costs is the errand the player was tempted to run instead of finishing the
/// delve.
const int campLife = 3;

/// Whether a camp pitched on [campDay] has been taken back by [day].
///
/// Days only pass on the road, so this counts walking and nothing else: a hero
/// who camps and then shops, banks and sleeps in the town at the dungeon's own
/// door has spent no days at all and comes back to the camp they left.
bool isCampOverrun({required int day, required int campDay}) =>
    day - campDay >= campLife;

/// Whether one more day on the road would take the camp back.
///
/// The warning is exactly one day wide, because a warning the player can still
/// act on is the only kind worth printing — and at two days out the walk back
/// to the stairs is still inside the window.
bool isCampNearlyOverrun({required int day, required int campDay}) =>
    day - campDay == campLife - 1;

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
///
/// **One pool, ordered, and no per-town pools.** The order is the pacing: the
/// town comes first because a hero who found the sea-cave before Northgate would
/// be told about a place they cannot reach, and the keep comes last because it
/// is the hardest walk and the hardest floor. Splitting the pool per town would
/// buy nothing that this order does not already buy — the two new places both
/// hang off Northgate, and the two-day road to it is the stagger. A per-town
/// pool is machinery for a world that has outgrown first-untold ordering, and
/// this one has not.
final List<Rumor> rumorPool = [
  Rumor(
    line: 'A carter says there is a town north of the moor that buys iron.',
    reveals: northgate,
  ),
  Rumor(
    line: 'An old man says the crypt door on the hill still opens.',
    reveals: cryptNode,
  ),
  Rumor(
    line: 'A fisherman says the tide uncovers a cave under the north cliffs.',
    reveals: seaCave,
  ),
  Rumor(
    line:
        'A pedlar says the keep east of Northgate is not as empty as it '
        'looks.',
    reveals: ruinedKeep,
  ),
];

/// What walks the three roads between the towns and the crypt.
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
/// **A [DungeonSpawnTable] rather than a [SpawnTable], and the reason is the
/// roads that are not lowland.** A [SpawnEntry] names its creature by id and
/// resolves it through [creatureById], which searches the one global [bestiary]
/// — so a table naming the shore crab or the kennel hound could never roll one,
/// and would throw on the road rather than fail a content test. Holding the
/// [CreatureSpec] outright is what lets the three road tables be three tables of
/// one kind. The draws are identical — one range for the count, one per creature
/// walked against the weights in list order — so the lowland roads stand up the
/// creatures they always did, on the tiles they always did.
const DungeonSpawnTable lowlandRoadTable = DungeonSpawnTable(
  minCount: 2,
  maxCount: 3,
  entries: [Weighted(giantRat, 3), Weighted(direWolf, 2)],
);

/// What walks the road out to the sea-cave.
///
/// The tide's leavings come inland: crabs and drowned sailors, the two the cave
/// has most of. Not the eel and not the hag — the eel is a thing that lives in
/// water and the hag is what the deep floors are for, and a road that handed
/// over the bottom of a dungeon would make walking to it beside the point.
///
/// The counts and the shape are the lowland table's, because the road is still a
/// road. What changes is who is on it.
const DungeonSpawnTable shoreRoadTable = DungeonSpawnTable(
  minCount: 2,
  maxCount: 3,
  entries: [Weighted(shoreCrab, 3), Weighted(drownedSailor, 2)],
);

/// What walks the road out to the ruined keep.
///
/// The garrison ranges: hounds and deserters, in the hound's favour, because a
/// deserter on the road is a man who got further than most and a kennel hound
/// is what was sent after him. Not the man-at-arms — the keep's hardest thing
/// stays in the keep, for the hag's reason.
const DungeonSpawnTable garrisonRoadTable = DungeonSpawnTable(
  minCount: 2,
  maxCount: 3,
  entries: [Weighted(kennelHound, 3), Weighted(deserter, 2)],
);

/// What walks [route].
///
/// **Keyed on where the road goes, not on where it starts.** A road is named by
/// its two ends and either can be the one the hero set out from, so the question
/// this answers is which dungeon the road serves — the sea-cave road is the
/// sea-cave road whichever way it is walked. The three roads between the towns
/// and the crypt are lowland wilderness and share one table, which is the
/// arrangement the world has always had; the two spurs off Northgate are the
/// ones with something of their own to say.
DungeonSpawnTable roadTableFor(Route route) {
  final ends = {route.from, route.to};
  if (ends.contains(seaCave)) return shoreRoadTable;
  if (ends.contains(ruinedKeep)) return garrisonRoadTable;
  return lowlandRoadTable;
}

/// How far a road's danger climbs with what the hero has learnt.
///
/// One tier per eight skill levels, because eight is roughly what a delve's
/// worth of training comes to: the roads get a notch harder about as often as
/// the hero gets a notch better, which is what stops the first road being the
/// hardest thing a hero ever walks.
const int roadTierLevels = 8;

/// The most a hero's progression can add to a road's own danger.
///
/// Capped, because the road is a tax on travelling and not a second dungeon. An
/// uncapped tier would eventually make every day a fight, and a hero who cannot
/// cross the map is a hero who cannot use it.
const int roadTierCap = 20;

/// How dangerous [route] is for [profile], in the hundred [travelOneDay] rolls
/// against.
///
/// **The road scales with the hero, and this is where the two meet.** The
/// route's own danger is what the road is; the tier is who is walking it. Core
/// never sees a [Profile] — this is the whole of why the number is worked out in
/// content and handed in, following [travelerChance].
///
/// Total skill levels rather than any one skill, because what makes a road
/// easier is the hero being further along and not the hero having trained any
/// particular thing. It is also the one number that cannot be gamed by leaving a
/// skill alone.
int dangerOn(Route route, Profile profile) {
  final trained = profile.skills.values.fold(
    0,
    (total, skill) => total + skill.level,
  );
  final tier = trained ~/ roadTierLevels;
  return route.danger + (tier > roadTierCap ? roadTierCap : tier);
}

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
///
/// [road] says which table stands the fight up. Left unsaid it is the lowland
/// one, which is what the three original roads carry and what every test that
/// is about the shape of an ambush rather than about its cast wants.
GameState startRoadEncounter(Profile profile, {required int day, Route? road}) {
  final table = road == null ? lowlandRoadTable : roadTableFor(road);
  final seed = ambushGroundSeed(profile.worldSeed, day);
  final rng = Rng(seed);
  final count = table.rollCount(rng);
  final ground = generateEncounter(seed, monsterCount: count);
  final monsters = <Actor>[];
  for (final spawn in ground.monsterSpawns) {
    final creature = table.rollCreature(rng);
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
