# Task 03 — Ephemeral dungeon and road theme context

Owner: third fresh `flow-plan-executor` on the Unit 8 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. Use the accepted repository
handoffs from tasks 01–02; do not depend on either executor's conversation.

## Expected starting repository condition

- The non-`main` `residuum-visual-reboot-8` checkout descends from `f322d78`.
- Task 01's fixed diagram and migrated world tests are green.
- Task 02's `DungeonPalette` has required complete context plus strict
  `paletteForDungeon`/`paletteForRoad`; four-theme renderer proofs are green.
- `GameScreen` still infers presentation from `GameBloc.dungeon`, and both
  session call sites still construct `const GameScreen()`.
- Architect-owned `.flow/**` records may be dirty and are preserved exactly.

Inspect branch/worktree before editing; implementation on `main` is forbidden.
If either prior task is incomplete, any planned file has unexplained changes, a
strict mapping/API differs from `../PLAN.md`, or source reality contradicts the
plan, stop and report rather than adding a fallback.

## Behavioral slice and file ownership

Make the regional context explicit for exactly one pushed crawl/fight route,
migrate every caller, and prove actual rendered dungeon/road output through the
session boundary while keeping all gameplay, stack, exit, wording, and save
behavior unchanged.

Production files:

- `packages/app/lib/game/game_screen.dart`;
- `packages/app/lib/main.dart`.

Behavioral integration tests:

- `packages/app/test/widget/world_screen_test.dart`;
- `packages/app/test/widget/boot_wiring_test.dart` only if needed for the
  boot-inside regional assertion.

Mechanical direct-caller migrations (no other edits in these files unless a
named regional proof requires it):

- `packages/app/test/battle_characterization_test.dart`;
- `packages/app/test/battle_flow_characterization_test.dart`;
- `packages/app/test/battle_view_test.dart`;
- `packages/app/test/widget/back_guard_test.dart`;
- `packages/app/test/widget/craft_surfaces_test.dart`;
- `packages/app/test/widget/hud_depth_test.dart`;
- `packages/app/test/widget/log_drawer_test.dart`;
- `packages/app/test/widget/pack_screen_test.dart`.

Do not edit `game_bloc.dart`, dungeon palette/material/scene files, `world_bloc`,
`world_screen.dart`, `world_nav.dart`, town/Character/save code, core/content,
dependencies/assets/generated files, or LDD authority. If integration proof
finds a task 01/02 defect, stop and return it to that ownership boundary instead
of repairing it opportunistically here.

## Locked implementation

### Required `GameScreen` input

Change only the constructor/context selection in `game_screen.dart`:

```dart
class GameScreen extends StatelessWidget {
  const GameScreen({required this.palette, super.key});

  final DungeonPalette palette;
}
```

Pass `palette` to the existing `DungeonSceneHost`. Delete
`paletteFor(bloc.dungeon)` and any nullable/default inference. Keep
`GameBloc.dungeon` reads in `_HitPoints._whereabouts`: crawls retain their exact
`<Dungeon> — depth n/m` status and road encounters retain exact `The road`.
Do not change Scaffold/PopScope, scene geometry/input, battle dock/shelf, HP,
log, controls, death overlay, exit functions, or any Unit 9-owned HUD chrome.

### Session derivation and lifetime

In `_SessionState._openRoadFight(DangerMet met)`, keep one use of the same
`met.road` for gameplay and derive presentation at the route builder:

```dart
child: GameScreen(palette: paletteForRoad(met.road))
```

Do not move this before the `mounted` guard if that would perform unused work;
the mapping is pure and may be evaluated where the child is constructed. Keep
`startRoadEncounter(... road: met.road)`, `roadOpeningLog`, providers, navigation
push/pop, fight close, autosave exclusion, and all comments/behavior describing
them. Palette does not affect encounter table, seed, monsters, geometry, loot,
log, carry-over, or ending.

In `_SessionState._openCrawl(... required NodeId dungeon)`, construct:

```dart
child: GameScreen(palette: paletteForDungeon(dungeon))
```

Keep the same `dungeon` on `GameBloc`, same resumed/opening log, autosaver watch,
providers, navigation route and close. This one convergence point covers boot
inside, fresh entry, resume, delve anew, and cross-dungeon abandonment.

The palette exists only as an immutable field on the pushed `GameScreen` and
then `DungeonSceneHost`/snapshot/material plan. Do not add it to GameBloc,
GameViewState, WorldBloc/state, TownBloc/state, core GameState, SaveDocument,
a provider, static mutable, serialized field, or callback. Do not derive from
`game.isEncounter`, a nullable dungeon id, glyphs, creatures, floor geometry, or
road table.

### Complete caller migration

Every direct test harness whose subject is not regional theming changes
`const GameScreen()` to
`const GameScreen(palette: DungeonPalette.crypt)` and imports the palette file.
No test changes assertions, fixtures, timings, blocs, events, or behavior for
this mechanical migration. Search the full `packages/app` tree: after cutover
there must be no unparameterized `GameScreen(` and no reference to retired
`paletteFor(`.

In `world_screen_test.dart`, update `_pushRoadFight` so its test fixture can take
an optional `Route`; when absent it explicitly selects the shipped
Stonebridge–Crypt lowland route. Pass the same route to
`startRoadEncounter(..., road: route)` and `paletteForRoad(route)` to
`GameScreen`. The optional parameter is test-fixture convenience only; it is not
a production fallback. Existing road ending/exit/save tests otherwise stay
unchanged.

## Red/Green behavioral proof

Establish Red before production edits. Because making `GameScreen.palette`
required creates compile failures in all callers at once, first add the regional
behavioral tests against the planned required constructor/mapping interface,
observe missing API/incorrect Crypt output, then perform the production and
mechanical caller cutover as one atomic Green. Do not leave an intermediate
commit with half the callers compiling.

### Actual material-output helper

In the owning integration test, build a private test helper that:

1. reaches the real `GameWidget` through `dungeonSceneKey` after navigation;
2. reads its single live `MaterialComponent` and the real `GameBloc.state.game`;
3. renders that component into an offscreen `ui.Image` at the map's material
   bounds and obtains raw RGBA bytes;
4. separately builds/renders `materialPlan(theSameGame, expectedPalette)` and
   one explicitly wrong palette;
5. asserts actual bytes equal expected bytes and differ from wrong bytes;
6. disposes every image and does not inspect `GameScreen.palette`, copy a field,
   assert source text, or add a production test hook.

This is a renderer-output contract: task 02 proves what each palette means; this
task proves navigation selected the right meaning. Keep images small/current-map
sized, compare deterministic bytes, and use `tester.runAsync` where Flutter test
requires it. No golden file or screenshot.

### Dungeon context through real session navigation

Add/extend focused cases in `world_screen_test.dart` (or put the boot-only case
in `boot_wiring_test.dart` if that avoids duplicated setup):

1. enter a real Sea-Cave crawl through its world door and prove actual bytes
   match `DungeonPalette.seaCave`, differ from Crypt, while the existing save
   dungeon and `The Sea-Cave — depth 1/` assertions remain;
2. enter a real Ruined Keep crawl and prove actual bytes match
   `DungeonPalette.ruinedKeep`, differ from Sea-Cave/Crypt, while its existing
   generated-map/save/status assertions remain;
3. boot inside or resume a saved Sea-Cave crawl and prove it retains Sea-Cave
   output, exact resumed wording, and the same saved dungeon. This specifically
   proves all entry modes converge on `_openCrawl`, not only fresh entry.

Do not merge these into one test if a failed route would obscure which context
was wrong. Expected Red: the current screen selects palette from the bloc and
can handle dungeon ids, but renderer task 02's complete regional output is not
passed explicitly; the road cases below still use Crypt.

### Road context through real session navigation

Add three real-session road-fight cases under the existing road group:

- Stonebridge–Crypt (neutral lowland);
- Northgate–Sea-Cave (Sea-Cave material);
- Northgate–Ruined-Keep (Keep material).

Use a removed throwaway Dart/test sweep over world seeds to find a literal seed
for which the first day on each chosen route produces `DangerMet` under current
`dangerOn`. Do not alter danger, inject a fake fight into production, or leave
the sweep in the suite. Record each literal beside the existing
`_dangerousWorld` style comment explaining route/day derivation. The exact
literal is executor discretion because it is a source-derived test fact, not a
product decision. Escalate if no bounded literal exists.

For each case, start from a source-valid fully discovered `Whereabouts` at the
correct endpoint, select the node through task 01's diagram, confirm with exact
`Set out`, pump only until the real `GameScreen` opens, and use the render-byte
helper to prove expected palette and reject at least Crypt/one other palette.
Also assert:

- `The road` remains present and no dungeon depth/name replaces it;
- the world remains on the same journey and the fight writes no crawl/save;
- the road's existing no-stairs and road-only exit explanation/control remain
  covered by the unchanged tests (do not duplicate every ending three times).

Expected Red: `_openRoadFight` constructs `const GameScreen()` and null dungeon
selects Crypt for every road.

### Existing preservation suites

All existing tests in every mechanically migrated direct-caller file must pass
with assertion bodies unchanged. `world_bloc_test.dart` remains untouched and
passes. Keep the existing world tests for travel confirmation, rumor discovery,
arrival/autosave, road pause/return/death, town/dungeon entry, resume/delve/
abandon, camp warning/loss, and Heroes. Keep exact road back refusal:
`You can only leave by walking off the edge of the road.`

Tests use real blocs/session/navigation and `// arrange` / `// act` / `// assert`.
No mock, source assertion, palette-field forwarding assertion, golden, random
fixture at runtime, arbitrary wait, or persistent test asset.

## Focused proof commands

After the named Reds and Green, run from `packages/app`:

```sh
flutter test test/widget/world_screen_test.dart \
  test/widget/boot_wiring_test.dart \
  test/world_bloc_test.dart \
  test/battle_characterization_test.dart \
  test/battle_flow_characterization_test.dart \
  test/battle_view_test.dart \
  test/widget/back_guard_test.dart \
  test/widget/craft_surfaces_test.dart \
  test/widget/hud_depth_test.dart \
  test/widget/log_drawer_test.dart \
  test/widget/pack_screen_test.dart \
  test/game/dungeon_scene_test.dart \
  test/game/dungeon_material_paint_test.dart

dart format lib/game/game_screen.dart lib/main.dart \
  test/widget/world_screen_test.dart test/widget/boot_wiring_test.dart \
  test/battle_characterization_test.dart \
  test/battle_flow_characterization_test.dart test/battle_view_test.dart \
  test/widget/back_guard_test.dart test/widget/craft_surfaces_test.dart \
  test/widget/hud_depth_test.dart test/widget/log_drawer_test.dart \
  test/widget/pack_screen_test.dart

dart analyze lib/game/game_screen.dart
dart analyze lib/main.dart
dart analyze test/widget/world_screen_test.dart
dart analyze test/widget/boot_wiring_test.dart
```

If analysis reports an error in a mechanically migrated caller, analyze that
file directly after correction. Re-run focused tests after formatting/static
correction. Do not run full suite/analyzer, whole-tree formatter, app build,
emulator, or device install; Main owns those gates.

## Executor discretion

You may choose private render-byte helper names/location, whether the boot
regional assertion sits in `world_screen_test.dart` or `boot_wiring_test.dart`,
and the literal deterministic first-day fight seeds discovered by the removed
sweep. You may consolidate imports and test helpers without changing behavior.

You may not make the `GameScreen` parameter optional, change public palette
functions, add context to a bloc/state/save/provider, change regional mapping,
read a field as the only test proof, alter gameplay fixtures/rules, change
road/dungeon wording or controls, edit task 01/02 production, or change any
mechanical caller assertion.

## Escalate when

- a production caller cannot provide palette strictly from its existing
  `dungeon` or `DangerMet.road` value;
- a route needs a fallback/guess or a regional palette affects the game passed
  to `GameBloc`/`startRoadEncounter`;
- actual output cannot be proved without a test-only production hook, field-copy
  assertion, golden, core/content edit, or save mutation;
- no bounded deterministic first-day fight seed exists for a shipped spur;
- a road loses `The road`, its edge-only exit, no-stairs rule, log, carry-over,
  autosave exclusion, or resumed journey behavior;
- any existing direct-caller assertion fails after the explicit Crypt migration;
- a fix would touch `game_bloc`, world/material source owned by prior tasks,
  save/dependency/assets, town/Character, Unit 9 HUD, core/content, LDD, or
  `main` branch.

## Handoff state and completion receipt

Task 03 is complete when every `GameScreen` receives an explicit palette, the
session is the sole derivation boundary, real Sea-Cave/Keep crawl entries and
lowland/cave/keep road fights render expected deterministic bytes, all preserved
world/road/crawl/save behaviors and direct callers pass, and no forbidden path
changed. Main then owns integrated format/analyze/full tests, scope audit,
acceptance review/corrections, and the device sequence in `../PLAN.md`.

Report to Main in at most eight prose lines:

- branch and compile/behavioral Reds observed;
- required `GameScreen` cutover and confirmation no old/unparameterized call remains;
- exact dungeon/road fixture routes/seeds and rendered-byte match/difference results;
- preserved road-only exit/`The road`/no-stairs/autosave/journey results;
- preserved dungeon boot/fresh/resume/save/status results;
- focused command pass counts plus unchanged direct-caller suites;
- files changed and formatter/analyzer results, with no forbidden path;
- any escalation or residual item for Main acceptance/device gates.