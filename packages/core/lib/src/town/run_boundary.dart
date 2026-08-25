import '../dungeon/floor.dart';
import '../dungeon/fov.dart';
import '../dungeon/generator.dart';
import '../engine/energy.dart';
import '../engine/game_state.dart';
import '../engine/rng.dart';
import '../loot/drop.dart';
import '../magic/mana.dart';
import '../magic/spell.dart';
import 'profile.dart';

/// How a dungeon lays its floors out on a given visit.
///
/// [FloorBuilder] has the visit baked into it, because inside a run the visit
/// never changes. Walking in is the one moment it does, so entry needs one more
/// layer: hand the dungeon a visit and it hands back that reshuffle's floors.
typedef Dungeon = FloorBuilder Function(int visit);

/// How deep the delve goes on a given visit.
///
/// **A function of the visit rather than a number, and [Dungeon]'s shape for
/// [Dungeon]'s reason.** Entering is the one moment the visit changes and
/// [startRun] is where that bump lives, so a caller who had to name the visit
/// in order to name the depth would be keeping a second copy of the bump rule
/// — and the first copy to drift would hand out a depth rolled for a delve
/// nobody made, while looking exactly like one that had not drifted.
typedef DelveDepth = int Function(int visit);

/// The crawl a [profile] begins by walking into the dungeon.
///
/// **Town is not a `GameAction`, and this function is why.** A game action is a
/// turn: it draws from the crawl's random streams, it moves a clock, and it
/// ends with the monsters getting theirs. A hero buying a potion does none of
/// those — there is no map to stand on, no monsters to answer, and nothing
/// random about paying a stated price. Routing the town through `step` would
/// mean every transaction had to be careful not to advance a clock that was not
/// running, and `step` would grow a branch for every screen the town ever gets.
/// So `step` stays dungeon-only, town transactions are pure functions over a
/// [Profile], and the two worlds meet at exactly two named doors: this one and
/// [endRun].
///
/// **Entering bumps the visit, and it does so here.** Reshuffling on entry is
/// one rule and so it gets one home. Leaving the bump to the caller would mean
/// every caller — the town screen, a test, the balance bot — had to remember
/// it, and the first one that forgot would replay the same five floors forever
/// while looking exactly like the ones that did not.
///
/// [dropTables], [lootSeedSalt] and [deepest] come from content for the same
/// reason the dungeon does: core has the rules, content has the numbers.
///
/// Leaving [deepest] unsaid lays the crawl out to [deepestDepth], which is the
/// crypt's fixed bottom and what every caller got before delves rolled their
/// own.
GameState startRun(
  Profile profile, {
  required Dungeon dungeon,
  Map<int, DropTable> dropTables = const {},
  Map<String, Spell> spells = const {},
  int lootSeedSalt = 0,
  DelveDepth? deepest,
}) {
  final visit = profile.visit + 1;
  final buildFloor = dungeon(visit);
  final floor = buildFloor(1);
  final visible = computeFov(floor.map, floor.heroSpawn, fovRadius);
  return GameState(
    map: floor.map,
    hero: profile.hero.copyWith(
      position: floor.heroSpawn,
      energy: actThreshold,
    ),
    monsters: floor.monsters,
    rng: Rng(profile.worldSeed),
    lootRng: Rng(profile.worldSeed ^ lootSeedSalt),
    visible: visible,
    explored: {...visible},
    buildFloor: buildFloor,
    depth: 1,
    worldSeed: profile.worldSeed,
    visit: visit,
    deepest: deepest == null ? deepestDepth : deepest(visit),
    stairsDown: floor.stairsDown,
    stairsUp: floor.stairsUp,
    groundItems: floor.groundItems,
    inventory: profile.inventory,
    equipment: profile.equipment,
    skills: profile.skills,
    gold: profile.gold,
    dropTables: dropTables,
    spells: spells,
    knownSpells: profile.knownSpells,
    mana: heroMaxMana(profile.loadout),
  );
}

/// The profile [entered] became, after [state].
///
/// [entered] is a parameter because the vault never went into the dungeon. A
/// [GameState] holds a run; a bank in town is not part of one, and hanging it
/// off the state would leave `step` one typo away from spending it. So the door
/// out takes both halves: what walked in, and what the dungeon did to it.
///
/// Leaving alive brings everything home and heals nothing. The inn is what
/// heals, and a free cure at the door would make it decoration.
///
/// Dying burns the carried pack and the carried purse, keeps what the hero was
/// wearing and what it had learned, leaves the vault untouched, and wakes the
/// hero whole. Whole means the ceiling the surviving gear allows — the same
/// number the inn would have healed to over the same gear — so death is never
/// the cheaper rest. Both endings keep the bumped visit, so the dungeon the
/// hero walks back into is never the one it just left.
Profile endRun(Profile entered, GameState state, {required bool died}) {
  final carried = entered.copyWith(
    hero: state.hero,
    equipment: state.equipment,
    skills: state.skills,
    inventory: state.inventory,
    gold: state.gold,
    visit: state.visit,
    knownSpells: state.knownSpells,
  );
  if (!died) return carried;
  final stripped = carried.copyWith(inventory: const [], gold: 0);
  return stripped.copyWith(hero: stripped.hero.copyWith(hp: stripped.maxHp));
}

/// The profile [entered] became, with [state] left standing where it is.
///
/// **A homecoming for the hero, and nothing at all for the dungeon.** Leaving
/// alive and leaving to come back carry the identical set home — the same hit
/// points, gear, training, pack, purse and visit [endRun] carries — because what
/// the hero *is* does not depend on whether they mean to return. What differs is
/// the other half: [endRun] is the last anyone sees of the crawl, while this
/// leaves it whole for [resumeRun] to walk back into. Nothing here reads or
/// alters [state] beyond copying out of it; the caller keeps it, and the caller
/// is what has to write it down.
///
/// Heals nothing, for [endRun]'s reason: the inn is what heals, and a free cure
/// at the door would make it decoration.
///
/// **Afterwards the profile and the crawl agree about the visit**, because the
/// visit comes home with everything else. That is not bookkeeping — it is the
/// precondition [resumeRun] needs, and the reason resuming can be well defined
/// at all.
///
/// Must not be called on a game-over state. A dead hero has no camp to walk back
/// into, and this would bring the corpse home with its pack intact instead of
/// burning it. The gate belongs to the interface, exactly as it does for
/// [endRun] — the stairs offer leaving only while the hero is alive — and
/// stating the contract here rather than asserting it keeps one gate instead of
/// two that can drift apart.
Profile suspendRun(Profile entered, GameState state) => entered.copyWith(
  hero: state.hero,
  equipment: state.equipment,
  skills: state.skills,
  inventory: state.inventory,
  gold: state.gold,
  visit: state.visit,
  knownSpells: state.knownSpells,
);

/// The crawl [suspended] was, with [profile] walking back down into it.
///
/// **The mana, the ward and the binds come back exactly as they were left**, and
/// that is the split holding rather than an exception to it: a floor's budget is
/// a fact about the floor the hero is standing on, so it belongs to the crawl,
/// beside the clock and the two streams. Refilling here would make walking home
/// and back the cheapest way to buy a spell, and the suspend theorem — resume
/// roll for roll — would stop being true of anything a caster did.
///
/// What the hero has *learned* comes from the profile instead, because a book
/// read at the camp is a book the hero climbs back down knowing.
///
/// **Everything else the hero is comes from the profile; everything else the
/// dungeon is comes from the suspended crawl.** Those are exactly the two halves
/// [suspendRun] separated, put back together the other way round — so a potion
/// bought while camped is in the pack, a night at the inn shows in the hit
/// points, and a helm swapped at the gear door is the helm the hero climbs back
/// down wearing, while the floor, the monsters, the fog, the litter, the clock
/// and both random streams are the ones the hero walked away from.
///
/// The hero is the suspended actor wearing the profile's hit points, rather than
/// the profile's actor outright. Both read the same today, because nothing in
/// town moves a hero — but only one of them says which half owns where the hero
/// is standing, and a town that one day moved a position would teleport the
/// player instead of reddening a test.
///
/// Banked gold stays banked. A vault is not part of a run, which is why it is
/// not on the state at all, and a resume that carried it down would put the bank
/// inside the thing dying takes.
///
/// **Resuming is not entering, so the visit is not bumped and the dungeon does
/// not reshuffle** — `loadRun`'s argument about a relaunch, holding for the same
/// reason about a walk back down the same stairs. [startRun] is what reshuffles,
/// and giving the camp up to delve anew goes through it like every other entry;
/// that is what keeps a dungeon that can be left from being a dungeon that is
/// farmed out and never refills.
///
/// Requires `profile.visit == suspended.visit`, which [suspendRun] establishes
/// and no town transaction disturbs. Stated rather than asserted, for
/// [suspendRun]'s reason.
///
/// Built field by field rather than copied, because [GameState.copyWith] has no
/// gold: gold rides a run as a passenger and only the town moves it, so the one
/// door that moves it back in has to say the whole state out loud.
GameState resumeRun(Profile profile, GameState suspended) => GameState(
  map: suspended.map,
  hero: suspended.hero.copyWith(hp: profile.hero.hp),
  monsters: suspended.monsters,
  rng: suspended.rng,
  lootRng: suspended.lootRng,
  visible: suspended.visible,
  explored: suspended.explored,
  buildFloor: suspended.buildFloor,
  depth: suspended.depth,
  worldSeed: suspended.worldSeed,
  visit: suspended.visit,
  deepest: suspended.deepest,
  stairsDown: suspended.stairsDown,
  stairsUp: suspended.stairsUp,
  gold: profile.gold,
  isGameOver: suspended.isGameOver,
  floors: suspended.floors,
  groundItems: suspended.groundItems,
  inventory: profile.inventory,
  equipment: profile.equipment,
  skills: profile.skills,
  dropTables: suspended.dropTables,
  spells: suspended.spells,
  knownSpells: profile.knownSpells,
  mana: suspended.mana,
  warded: suspended.warded,
  bound: suspended.bound,
  nextDropNumber: suspended.nextDropNumber,
);
