import '../dungeon/floor.dart';
import '../dungeon/fov.dart';
import '../engine/energy.dart';
import '../engine/game_state.dart';
import '../engine/rng.dart';
import '../loot/drop.dart';
import 'profile.dart';

/// How a dungeon lays its floors out on a given visit.
///
/// [FloorBuilder] has the visit baked into it, because inside a run the visit
/// never changes. Walking in is the one moment it does, so entry needs one more
/// layer: hand the dungeon a visit and it hands back that reshuffle's floors.
typedef Dungeon = FloorBuilder Function(int visit);

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
/// [dropTables] and [lootSeedSalt] come from content for the same reason the
/// dungeon does: core has the rules, content has the numbers.
GameState startRun(
  Profile profile, {
  required Dungeon dungeon,
  Map<int, DropTable> dropTables = const {},
  int lootSeedSalt = 0,
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
    stairsDown: floor.stairsDown,
    stairsUp: floor.stairsUp,
    groundItems: floor.groundItems,
    inventory: profile.inventory,
    equipment: profile.equipment,
    skills: profile.skills,
    gold: profile.gold,
    dropTables: dropTables,
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
  );
  if (!died) return carried;
  final stripped = carried.copyWith(inventory: const [], gold: 0);
  return stripped.copyWith(hero: stripped.hero.copyWith(hp: stripped.maxHp));
}
