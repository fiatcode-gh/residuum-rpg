# Unit 8 — World Graph and Theme Parity: Execution Plan

Status: **execution-grade; planning only.** This artifact does not authorize
production implementation.

Derived from the user-approved `CONTRACT.md`, `../../RESUME.md`, the Unit 8
records in `../../LEDGER.md`, `AGENTS.md`, and
`docs/specs/2026-08-20-dungeon-game-design.md`. Although `CONTRACT.md` still
carries its pre-approval status line, `RESUME.md:10-18` and
`LEDGER.md:894-908` record the user's approval and are authoritative for the
planning boundary.

The source base is `f322d78c8ec445df8c0a66bdf528b37178322cb0`
(`f322d78`) on `main`, the merged Unit 7 head. At planning time `main` matched
`origin/main`; `packages/` was clean at that base. The worktree was dirty only
in architect-owned LDD authority: modified
`.flow/ldd/visual-reboot/LEDGER.md` and `RESUME.md`, plus the untracked
`units/unit-8/` directory containing the approved contract and this plan.
Executors preserve those bytes and do not stash, revert, commit, or edit them.
A changed app revision requires targeted revalidation of the named seams, not
automatic redesign.

## Execution boundary and dependency graph

Implementation is **prohibited on `main`**. After explicit user approval of
this plan, use one non-isolated feature checkout branched from `f322d78`, by
house convention `residuum-visual-reboot-8`. Dispatch one fresh
`flow-plan-executor` per capsule, sequentially in that checkout:

```text
01-world-route-diagram
  -> 02-regional-materials
  -> 03-theme-context-wiring
  -> Main integrated gates
  -> integrated acceptance review and corrections
  -> user-started Medium_Phone device gate
```

Task 02 is file-disjoint and behaviorally independent of task 01, but the
execution order above is locked so task 03 receives one known repository state
and no isolated-workspace integration is needed. Task 03 depends on both: it
consumes task 02's strict palette interface and adds regional assertions to the
world suite after task 01 has migrated that suite.

1. `plan-tasks/01-world-route-diagram.md` replaces the world menu with the
   fixed five-node spatial route diagram, including safe discovery projection,
   current route danger, accessibility semantics, and existing world-test
   migration. It does not touch a bloc or gameplay path.
2. `plan-tasks/02-regional-materials.md` makes the existing deterministic
   material pipeline express Crypt, Sea-Cave, Ruined Keep, and neutral lowland
   road identities. It proves the renderer directly and does not wire a screen.
3. `plan-tasks/03-theme-context-wiring.md` makes `GameScreen` require the
   explicit ephemeral palette, derives it once at the session boundary for a
   dungeon or road, migrates every direct caller, and proves the actual rendered
   regional output through dungeon and road navigation.

Each executor owns its behavioral Red/Green, touched-file formatting, focused
analysis, and focused tests. No executor runs the full analyzer, full suite, app
build, emulator, device install, or external write. Main owns the integrated
commands and all review/device work after task 03.

Only `packages/app` may change. **Nothing under `packages/core` or
`packages/content` may change.** Save code/data, dependencies, generated files,
assets, town/Character composition, crawl HUD chrome, and LDD authority are also
forbidden. Unit 7 finding F6 about `character_screen.dart` is not granted scope
by the approved Unit 8 contract and remains untouched.

## Revalidated source seams

All paths were read at `f322d78`.

| Seam | Current fact | Planned consequence |
| --- | --- | --- |
| `lib/world/world_screen.dart:56-104` | A fixed header and current-action footer surround a `ListView` of `Heading('The world')`, one `_Place` row per discovered node, appended generic `_Unheard` rows, notice, and road log. | Keep header/footer/notice/log ownership; replace only the list-menu projection with `WorldRouteDiagram`. Delete `_Place`, `_Unheard`, `_unheardOf`, and the old `ItemRow` composition rather than retaining a fallback. |
| `world_screen.dart:113-159` | `_confirmTravel` resolves the direct route, asks with the route's day cost, and dispatches `TravelRequested` only after `Set out`. | Keep it behaviorally unchanged. The diagram invokes it only for enabled, discovered, one-road destinations. Cancellation remains day-free. |
| `world_screen.dart:162-205` | `_Standing` prints exact standing/journey, day/days-left, health, carried-gold, and banked-gold strings. | Preserve every string and projection. The diagram adds an on-route mark; it does not replace or reword the header. |
| `world_screen.dart:299-555` | `_HereState` owns pending-door stand-down plus town/dungeon/resume/delve/camp/abandon flows and exact dialogs. | Frozen. The new diagram remains above this area and never acquires these actions. |
| `world_screen.dart:598-619` | `WorldDoor` renders current-location and Heroes actions. | Frozen. Heroes remains a distinct world action in `_Here`, never a node. |
| `lib/world/world_bloc.dart:64-119` | `WorldViewState` owns `Whereabouts`, log/notice/fight/walk state and computes discovered one-road destinations. | No edit. The diagram uses the same `destinationsFrom(map)` result for enablement. |
| `world_bloc.dart:133-173` | `WorldBloc.map` and public `dangerFor(Route)` are immutable session dependencies; `dangerFor` closes over the live `TownBloc.profile` in `main.dart`. | No edit. `WorldScreen` passes this exact function to the diagram and rebuilds that diagram when `TownBloc.profile` changes, so the shown value is current rather than the content base danger. |
| `world_bloc.dart:175-333` | Travel, days, encounters, road returns, logs, notices, and rumor discovery are wholly bloc-owned. | Frozen. No diagram callback dispatches anything except the existing confirmed `TravelRequested`. |
| `lib/main.dart:265-382` | `_SessionState` is the only cross-bloc world/town/session boundary. | Remains the only theme-context derivation boundary as well. No new provider, persisted field, or bloc state is introduced. |
| `main.dart:400-438` | `_openRoadFight(DangerMet)` already receives the exact route and passes it to `startRoadEncounter`; `GameBloc.dungeon` is null and `GameScreen` currently falls back to Crypt presentation. | Derive `paletteForRoad(met.road)` at this boundary and pass it to the route's `GameScreen`. Fight generation, carry-over, route stack, autosave exclusion, and close remain byte-for-behavior. |
| `main.dart:483-603` | All boot/fresh/resume/delve-new dungeon paths converge on `_openCrawl(..., dungeon:)`; its `GameBloc` keeps the dungeon id. | Derive `paletteForDungeon(dungeon)` here and pass it to `GameScreen`. The id still labels the crawl through `GameBloc`; presentation is not stored there. |
| `lib/game/game_screen.dart:25-138` | `GameScreen` has no constructor data and infers `paletteFor(bloc.dungeon)` at the `DungeonSceneHost`; null means road and therefore Crypt. | Make palette a required immutable constructor input and pass it through. Remove all inference/fallback. Nothing else in the screen changes; Unit 9 owns its HUD. |
| `game_screen.dart:300-319` | Crawls name their dungeon through `GameBloc.dungeon`; encounters say exactly `The road`. | Frozen. A palette never changes or replaces the road-only location/exit wording. |
| `lib/game/dungeon_palette.dart:5-50` | Three palette constants carry glyph inks and a deterministic theme salt; `paletteFor(NodeId?)` maps null to Crypt. | Expand the same object into the complete material/light context, add neutral lowland road, replace the nullable fallback with strict `paletteForDungeon` and `paletteForRoad`. No parallel theme abstraction. |
| `lib/game/dungeon_material.dart:17-259` | `materialPlan` projects only `visible ∪ explored`, hashes marks from position/kind/knowledge/salt, and computes masonry only from known walls. | Preserve those boundaries and existing hash fields. Add the selected palette to the immutable plan and one independent deterministic pattern phase; never inspect an unknown neighbor or any RNG. |
| `lib/game/dungeon_scene_material.dart:9-404` | Renderer colors/light are global Crypt constants, so non-Crypt salts vary marks but the continuous material remains Crypt. Light is a single cached radial gradient clipped to visible material; all material is precomputed on projection changes. | Move surface/light anchors into `DungeonPalette`; select one cached structural pattern per regional identity; retain one clipped light pass, known-cell-only drawing, and allocation-free `render`. Crypt output remains the baseline. |
| `lib/game/dungeon_scene.dart:43-183` | Snapshot receives a palette, builds glyph/material plans, and reuses projection only when game/palette/identity/selection/arm inputs match. | No production edit required. Its existing palette lifetime and pan-only reuse are already correct; task 02 updates only constructor fixtures forced by the plan model and runs the scene suite unchanged. |
| `test/widget/world_screen_test.dart` | Owns world composition, confirmation, rumor/discovery, travel/save, road-fight, dungeon/camp, and source wording. Several first-group assertions pin `[T]`, `(D)`, generic unheard rows, `Row` ancestry and `Walk`. | Replace only obsolete list-composition assertions/finders with spatial/discovery/accessibility behavior. Preserve all transition/save/camp/road tests; task 03 later adds rendered-theme integration here. |
| `test/support/world_nav.dart:28-44` | `walkTo` finds an `ItemRow` ancestor and taps its child `Walk`. | Migrate it to tap the enabled labelled node control, then use the same confirmation/timer sequence. All consumers remain behavior tests rather than learning diagram geometry. |
| `test/widget/palette_test.dart` and `test/game/dungeon_material*_test.dart` | Pin palette value hierarchy, material determinism, visible clipping, known-face edges, no unknown pixels, and Crypt paint behavior. | Retain the useful contracts, delete the obsolete nullable-road fallback assertion, and expand proofs across the four material identities. No goldens. |
| Direct `const GameScreen()` callers | Two production call sites and nine test harnesses construct the screen without theme context. | Production callers derive strict context; direct test harnesses state `DungeonPalette.crypt` unless the test explicitly owns a regional road. No optional constructor default or compatibility alias. |

## Locked architecture and interfaces

### 1. Fixed world diagram

Add `packages/app/lib/world/world_route_diagram.dart`. It owns the fixed
projection and nothing about travel state mutation:

```dart
class WorldRouteDiagram extends StatelessWidget {
  const WorldRouteDiagram({
    required this.map,
    required this.whereabouts,
    required this.destinations,
    required this.dangerFor,
    required this.onDestination,
    super.key,
  });

  final WorldMap map;
  final Whereabouts whereabouts;
  final Set<NodeId> destinations;
  final int Function(Route) dangerFor;
  final ValueChanged<WorldNode> onDestination;
}
```

`WorldScreen` supplies `map: world.map`, `whereabouts: state.world`, and
`destinations: state.destinationsFrom(world.map).map((node) => node.id).toSet()`.
It supplies `dangerFor: world.dangerFor` and routes `onDestination` to the
existing `_confirmTravel(context, node, state)`. The diagram does not import
`flutter_bloc`, read a bloc, call `beginTravel`, dispatch an event, or retain
state.

The diagram is a `SizedBox`/`LayoutBuilder` with a 430-logical-pixel portrait
canvas and a `Stack`; it is not scrollable, pannable, zoomable, or generated.
The surrounding existing world `ListView` provides vertical reachability on a
short surface. The five node centers, expressed as fractions of the diagram
width/height, are locked:

| Node | Center `(x, y)` | Reading |
| --- | --- | --- |
| The Sea-Cave | `(0.20, 0.12)` | north-west spur |
| The Ruined Keep | `(0.80, 0.12)` | north-east spur |
| Northgate | `(0.50, 0.39)` | northern junction |
| The Crypt | `(0.74, 0.68)` | eastern lowland |
| Stonebridge | `(0.26, 0.84)` | southern home |

Each node slot is 120×72 logical pixels (never below Flutter's 48-pixel touch
minimum). Towns use a square/2-radius outline; dungeons use a stadium outline.
The kind also appears as the word `TOWN` or `DUNGEON`, so shape is not the sole
carrier. A discovered node shows kind, exact source name, and exactly one state
word/phrase: `HERE`, `REACHABLE`, `NO ROAD FROM HERE`, or
`TRAVEL IN PROGRESS`. The current node has a second outline and selected
semantics. During a journey neither endpoint says `HERE`; the active route says
where the hero is.

An undiscovered slot is the same neutral circular marker at every position,
shows only `?`, has no gesture and no button semantics, and exposes only the
semantic label `Unknown location. Not discovered.` It must not expose its
`NodeId`, name, kind, route, cost, danger, endpoint, or regional identity in
visible text, tooltip, semantic label/value/hint, focus action, or announcement.
Widget keys may identify fixed slots for tests but are not rendered or placed in
semantics.

A private fixed-site lookup recognizes exactly the five shipped `NodeId`s and a
private fixed-route-label lookup recognizes exactly the five shipped endpoint
pairs. An unrecognized/missing/extra node or route is an escalation-worthy
source contradiction; do not add a generic layout engine or silently place it.

### 2. Route visibility, labels, accessibility, and danger

A route is projected only after **both endpoints are discovered**. Filtering
happens before its cost/danger text is built and before `dangerFor(route)` is
called. Therefore a hidden endpoint yields no line, route semantics, endpoint
name, day count, or danger. This is the discovery-leak rule; the fixed `?`
remains without revealing connectivity.

Every projected route has:

- one neutral solid line behind the nodes;
- a two-line visible label, `<N> DAY`/`<N> DAYS` above `DANGER <n>/100`;
- one non-action semantic container labelled
  `Route from <from name> to <to name>. <N> day(s). Current danger <n> in 100.`;
- `n` computed exactly once for that projection with `WorldBloc.dangerFor`, not
  `Route.danger`, `dangerOn` in a widget, or a cached number in state.

The five compact label centers are fixed at `(0.33, 0.24)` (Sea-Cave spur),
`(0.67, 0.24)` (Keep spur), `(0.37, 0.58)` (Stonebridge–Northgate),
`(0.63, 0.54)` (Northgate–Crypt), and `(0.56, 0.82)`
(Stonebridge–Crypt). Small local offsets/padding may be tuned only to prevent
text/node overlap without changing node positions or route association.

The active `Journey` route uses a double/thicker value-contrast line and adds
the visible words `ON THIS ROAD`; its semantic label appends
`You are on this road. <daysLeft> day(s) remain.` Hue never carries activity.
Other known routes remain visible while travelling. No route is tappable.

Known nodes use explicit `Semantics(button: true, enabled: ..., selected: ...)`
with one composed label: kind, exact name, and the same state phrase in sentence
case. `enabled` is true only when the node id is in the supplied `destinations`
and `whereabouts.journey == null`. Disabled current/nonadjacent/travelling nodes
remain labelled controls but cannot call `onDestination`. Semantic traversal
order follows the fixed geography, not discovery order. Route semantics are
read once and their visual text is excluded from duplicate announcements.

`WorldScreen` wraps only the diagram in a `BlocBuilder<TownBloc, TownViewState>`
with `buildWhen: (before, after) => before.profile != after.profile`; the builder
still calls `world.dangerFor`. This is a rebuild dependency, not transfer of
danger ownership. `_Standing` keeps its existing TownBloc projection and
`_HereState` keeps its own listener/builder.

Use only existing ASCII punctuation and words in the new diagram. Introduce no
new mark codepoint, icon, asset, animation, gradient terrain, or hue-coded
state. Retain `ink`, `dim`, `panel`, and `rule`; value, word, outline count,
shape, and position carry the reading.

### 3. Complete regional palette context

Keep `DungeonPalette` as the one context already consumed by `glyphPlan`,
`materialPlan`, `DungeonSceneSnapshot`, and `DungeonSceneHost`. Do not add a
parallel `Theme`, provider, inherited widget, bloc field, or persisted model.
Add:

```dart
enum RegionMaterial {
  cryptStone,
  seaCaveStone,
  ruinedKeepMasonry,
  lowlandRoad,
}
```

`DungeonPalette` keeps `wall`, `floor`, `stairs`, and `themeSalt`, and gains the
required immutable fields `material`, `rememberedStone`, `visibleStone`,
`edgeInk`, `detailInk`, `lightInk`, `maxLightLift`, and `maxTintMix`. Static
constants are:

| Palette | material | wall / floor / stairs | remembered / visible / edge | detail / light | lift / tint | salt |
| --- | --- | --- | --- | --- | --- | --- |
| `crypt` | `cryptStone` | `B9BEC6` / `5B6270` / `E8ECF2` | `1A1E20` / `292A27` / `48463F` | `D4B77B` / `E8C58A` | `.30` / `.12` | `0x0C7` |
| `seaCave` | `seaCaveStone` | `9FC2C6` / `44575E` / `E4F1F2` | `161E21` / `263236` / `56676A` | `91B2B5` / `B9D7D8` | `.26` / `.10` | `0x5EA` |
| `ruinedKeep` | `ruinedKeepMasonry` | `C8B79C` / `64594A` / `F2EDE2` | `201B18` / `332B26` / `6C5A49` | `B78C65` / `E0B77D` | `.28` / `.11` | `0x10E` |
| `lowlandRoad` | `lowlandRoad` | `B9B6A9` / `57564F` / `E7E3D5` | `1B1C19` / `2D2C26` / `5B584C` | `A6A08B` / `D8CCA2` | `.22` / `.06` | `0x10A` |

Hex entries are opaque `0xFF...` colours. Crypt anchors and its rendered output
are unchanged. Non-Crypt renderer anchors may be tuned only in a device-finding
correction, while retaining the contract identities and all automated value
thresholds; an executor does not improvise alternatives during initial Green.

Replace `paletteFor(NodeId?)` entirely:

```dart
DungeonPalette paletteForDungeon(NodeId node)
DungeonPalette paletteForRoad(Route route)
```

`paletteForDungeon` maps only `cryptNode`, `seaCave`, and `ruinedKeep`, throwing
`ArgumentError.value` for anything else. `paletteForRoad` matches unordered
endpoints: Northgate–Sea-Cave → `seaCave`; Northgate–Ruined-Keep →
`ruinedKeep`; Stonebridge–Crypt, Stonebridge–Northgate, and
Northgate–Crypt → `lowlandRoad`; any other pair throws `ArgumentError.value`.
There is no nullable/default/creature/glyph inference. Strictness is deliberate:
the approved map is fixed, and content drift must not acquire a plausible but
wrong material.

### 4. Deterministic material and lighting decisions

`MaterialPlan` gains required `DungeonPalette palette` and defensively retains
it with the existing unmodifiable cell/mark/masonry collections.
`MaterialMark` gains required `double pattern`, included in equality/hash. It is
`0` for remembered cells; for visible cells it is
`_unit01(_hash(position, palette.themeSalt ^ 0x5555, kind.index))`. Existing
grit/speck/crack/edge formulas and salts do not change, preserving Crypt's
established deterministic marks.

In `dungeon_scene_material.dart` add:

```dart
enum SurfacePattern { none, tideStrata, ashlarFracture, roadWear }
```

`MaterialCellPaint` gains required `pattern` and `patternStrength`, including
them in equality/hash. `materialCellPaint` becomes
`materialCellPaint(cell, palette: ..., masonry: ...)`; `stoneLitColor` becomes
`stoneLitColor(palette, light)`. Both are pure. Remembered material is always
flat, unlit, pattern-free and less detailed than visible material.

The locked visible treatment table is:

| identity | walls | ordinary floors | stairs |
| --- | --- | --- | --- |
| Crypt | Existing `.55` edge, `.14` grit, exposed-wall curved crack `.5`; no new pattern. | Existing `.08` grit and sparse speck. | Same fill as floor; no speck/pattern. |
| Sea-Cave | `.42` softened/round edge, `.10` grit, `tideStrata` `.36`, no crack. | `.055` grit, sparse speck, `tideStrata` `.20`. | Same fill as floor; no speck/pattern. |
| Ruined Keep | `.68` square/butt edge, `.15` grit, `ashlarFracture` `.45`, exposed-wall angular crack `.70`. | `.07` grit, `ashlarFracture` `.28`, sparse angular fracture only where the deterministic phase gates it. | Same fill as floor; no speck/pattern. |
| Lowland road | `.32` neutral edge, `.07` grit, no crack/pattern. | `.045` grit, no speck, `roadWear` `.24`. | Same fill as floor; no speck/pattern (roads have no stairs, but the invariant remains total). |

The Sea-Cave pattern is two shallow, broken horizontal strata strokes with
rounded caps and phase-shifted insets. The Keep wall pattern is a short
right-angle ashlar joint; its fracture is a two-segment angular path. Keep floor
fractures are sparse and angular, never curved. Lowland road wear is two short
parallel diagonal scuffs on a visible floor. Pattern phase changes only the
safe inset/segment choice, never tile membership, FOV, topology, hit testing, or
actor position.

All pattern/crack/edge/grit/speck paths and paints are prepared in
`_rebuildRenderPlan`; `render` only draws cached objects. Every decoration is
inset and clipped to its own known cell. The one radial light shader is still
cached per adopted plan and clipped by `visibleMaterialMask(plan)`. It uses
`palette.visibleStone`, `palette.lightInk`, `maxLightLift`, and `maxTintMix`;
light changes value more than hue for every palette. `dungeonVoid` remains
`0xFF050607` for all identities. Unknown space has no `MaterialCell` and receives
neither base, edge, decoration, nor light. Known-wall faces and masonry still
consult only known cells; pattern hashes consult only position, kind,
knowledge, and palette salt. No `Random`, gameplay `Rng`, clock, asset, second
FOV, per-frame component, or per-frame collection allocation is introduced.

### 5. Ephemeral theme lifetime and clean caller cutover

`GameScreen` becomes:

```dart
class GameScreen extends StatelessWidget {
  const GameScreen({required this.palette, super.key});
  final DungeonPalette palette;
}
```

It passes `palette` unchanged to `DungeonSceneHost`. It never reads
`GameBloc.dungeon` to select presentation; that field remains solely the stable
dungeon identity used by the existing status line and crawl rules.

The only production constructors become:

- `_openRoadFight(DangerMet met)` →
  `GameScreen(palette: paletteForRoad(met.road))`;
- `_openCrawl(..., required NodeId dungeon)` →
  `GameScreen(palette: paletteForDungeon(dungeon))`.

The palette object lives for exactly one pushed route and is discarded when the
route pops. It is not placed in `GameViewState`, `GameBloc`, `WorldViewState`,
`WorldBloc`, `TownBloc`, `SaveDocument`, `GameState`, a global mutable, or a
provider. Road encounters still obtain creatures and gameplay state from the
same `met.road`; palette selection neither feeds nor conditions
`startRoadEncounter`.

Every direct test `GameScreen` caller is migrated in task 03. Harnesses whose
subject is not theme pass `DungeonPalette.crypt` explicitly. The
`world_screen_test.dart` road helper takes an optional fixture route only for
test setup, passes that route to `startRoadEncounter`, and passes
`paletteForRoad(route)` to the screen. There is no production default.

## Existing behavior and test migration policy

The following are preservation evidence, not rewrite targets:

- `world_bloc_test.dart` remains byte-unchanged and must pass. It owns legal
  destinations, travel days, encounters, rumor discovery, logs, and returns.
- In `world_screen_test.dart`, keep the travel/save/tavern/town/camp/dungeon/
  road-fight groups and their state assertions. Only obsolete assumptions about
  `_Place`/`ItemRow`, `[T]`, `(D)`, generic unheard prose, a `Walk` child, or
  `Row` ancestry are removed. Do not re-pin widget classes, exact pixel offsets,
  painter internals, or source text.
- Exact source wording remains exact: header lines, travel dialog, notices, road
  log, `The road`, road-only back refusal, town/dungeon doors, camp warning/loss,
  resume/delve/abandon dialogs, and Heroes.
- `dungeon_scene_test.dart` keeps all tap/pan/long-press/camera/reuse assertions.
  Constructor changes forced by required `MaterialPlan.palette` are mechanical.
- Existing Crypt deterministic number assertions remain exact. New regional
  assertions compare invariants, pattern categories, rendered output, and
  repeatability rather than brittle whole-frame goldens.
- `palette_test.dart` removes the obsolete `paletteFor(null) == crypt` contract.
  It gains strict dungeon/route mapping and neutral-road/value hierarchy tests.
- No new test exists merely to assert a field copy. Task 03 compares the bytes of
  the actual material component reached through session navigation with a
  separately rendered plan for the expected palette, and proves the wrong
  regional palette differs.

No production compatibility alias, optional theme fallback, hidden list view,
duplicate graph projection, deprecated API, or dead renderer path remains.

## Integrated proof ownership

After all task receipts are accepted, Main runs from `packages/app` on the
integrated feature tree:

```sh
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Main then audits the final diff: changes are confined to the task-owned
`packages/app/lib/world`, `packages/app/lib/game`, `packages/app/lib/main.dart`,
and named `packages/app/test` files plus architect-owned Unit 8 plan records.
There must be zero changes under `packages/core`, `packages/content`,
`packages/app/lib/save`, dependency/generated/asset files, town composition,
or crawl HUD chrome; no new asset declaration or mark codepoint; no nullable
`paletteFor` or unparameterized `GameScreen` call; no old world-menu fallback.

Main runs one integrated acceptance review against `CONTRACT.md` after these
commands. It checks correctness beyond plan compliance: discovery leakage in
visible and semantic surfaces; current danger provenance; direct-route
selection and confirmation; World/Town/session ownership; ephemeral route
context; strict regional mapping; road-only exit and autosave behavior;
determinism, known-geometry boundaries, renderer allocation/lifetime; test
quality; and greyscale accessibility. Any finding is corrected on the feature
checkout, followed by affected focused proof and the full commands whose
behavioral surface the correction traverses. Only a closed acceptance review
may proceed to device evidence.

### Device sequence

Use the current user-started `Medium_Phone` AVD; it segfaults when launched from
a tool shell, so Main asks the user to start it. Before any install or save
mutation, copy both
`app_flutter/save.json` and `app_flutter/save-previous.json` from package
`com.example.residuum_app` to untracked Unit 8 evidence, retain their exact
bytes, and record SHA-256. Never read the stale `files/` location. After all
driving, restore both streams if touched and prove both are byte-identical to
the backups by hash and byte comparison.

Use source-valid saves/world seeds and real generation; first delves are
observed at `visit: 1`, never `visit: 0`. No fixture, core/content edit, balance
change, or save-shape change is permitted to stage a frame. Capture colour
frames in this order:

1. fresh discovery-gated world: Stonebridge and Crypt known, three fixed `?`
   slots, only their one route/cost/current danger shown;
2. fully discovered world: all five named nodes and all five labelled routes,
   with kind/reachability/current state legible by shape and word;
3. active journey: header plus `ON THIS ROAD`, days remaining, disabled node
   travel, road log/notices, and `Walk on` when resumed;
4. Sea-Cave delve at `visit: 1` or later;
5. Ruined Keep delve at `visit: 1` or later;
6. lowland road fight;
7. Sea-Cave spur road fight;
8. Ruined Keep spur road fight.

For frames 4, 5, 7, and 8, also capture greyscale twins because they introduce
non-neutral regional palettes. The neutral world and lowland road need no twin
unless device reality reveals unauthorised colour or a new codepoint. Check that
Sea-Cave remains identifiable by strata/wet edge/value without hue, Keep by
square masonry/fracture/value without hue, and lowland by neutral road wear.
For every crawl/fight, verify actor/important-symbol priority, unknown void,
remembered vs visible ladder, light clipping, unchanged grid hit targets, and
no tofu/colour emoji. On each road fight confirm `The road`, no stairs, and the
road-only exit sentence/control. Tablet work is expressly deferred.

## Global escalation boundary

Stop the affected task and report to Main/architect if:

- branch/worktree/source preconditions do not match, a planned file has
  unexplained changes, or the shipped graph is no longer exactly the five nodes
  and five routes recorded above;
- a diagram would need a gameplay-derived fact other than current
  `Whereabouts`, direct reachability, approved day cost, or current danger;
- an unknown slot/route cannot avoid exposing a name, kind, endpoint, cost,
  danger, regional identity, focus action, or semantics hint;
- current danger cannot be projected through the existing
  `WorldBloc.dangerFor` closure and live `TownBloc.profile` rebuild without
  moving profile ownership into the world bloc;
- travel, rumor, save, road-fight, town arrival, dungeon/camp, roster, or route
  stack behavior would have to change to support presentation;
- strict dungeon/route mapping cannot cover exactly current content without a
  fallback, glyph/creature inference, core/content edit, or serialized field;
- regional material cannot be distinguished beyond hue while preserving
  Crypt output, the Unit 2 value ladder, known-only geometry, one clipped light
  pass, gameplay RNG, hit testing, and allocation-free render;
- a required test fails for a preserved transition/wording rather than an
  obsolete composition assumption;
- any solution appears to require `packages/core`, `packages/content`, a save or
  dependency change, an asset, animation, a new mark codepoint, Character/town
  work, Unit 9 HUD chrome, or implementation on `main`.

Executor discretion is limited to private helper names, file-private widget/
painter splitting, test helper names/fixture placement, and small padding or
route-label offsets needed to avoid overlap while preserving locked node
centers, topology, labels, semantics, and touch sizes. It does not include
public interfaces/names, palette anchors before device findings, regional
mapping, pattern categories, data ownership/lifetime, visible wording, node
shape/kind/state grammar, discovery filtering, danger provenance, task file
ownership, or any preservation boundary.

## Plan quality gate

- **COR — PASS.** State and mutation ownership remain source-true: WorldBloc
  owns discovery/travel/fights, TownBloc owns the live profile, and Main owns
  cross-bloc route construction. The diagram receives immutable projections and
  can dispatch only through the existing confirmation. Discovery filtering is
  before route projection and danger evaluation. Journey location is carried by
  an explicit on-route word/line rather than mislabelling `Whereabouts.at`.
  Palette context is required, strict, route-lifetime-only, and cannot affect
  gameplay. Renderer decisions remain known-cell-only, deterministic, cached,
  and clipped; Crypt and all road/crawl exits remain intact.
- **TTC — PASS.** Task 01 has Red for absent fixed slots, absent route cost/
  current-danger labels, unsafe unknown semantics, and no spatial journey mark;
  it reuses unchanged world/bloc transition suites. Task 02 has Red for missing
  lowland/strict mapping and identical Crypt material output across regions,
  then proves four-theme determinism, greyscale hierarchy, pattern identity,
  RNG preservation, unknown-neighbor independence, clipping, and cached reuse.
  Task 03 has a compile-time Red at every required `GameScreen` caller and a
  behavioral Red where real cave/keep/spur fights render Crypt; it compares
  actual navigated render bytes to expected regional render output and keeps
  road/camp/save tests green. Main owns full-suite and device proofs.
- **CRF — PASS.** The existing `DungeonPalette` becomes the one complete
  presentation context instead of gaining a second theme layer. The fixed graph
  gets one dedicated widget/painter, not a generic map engine. The old list and
  nullable palette fallback are deleted. Material patterns extend the existing
  plan/prepared-render pipeline; there are no per-tile components, per-frame
  decisions, global state, shims, duplicate projection, or future-map
  abstraction. Three tasks align with independently provable world, renderer,
  and integration boundaries.
- **SEC — SKIP (no new trust boundary).** Unit 8 is local Flutter presentation
  over existing immutable in-process state. It adds no network, external input,
  deserialization, persistence, privilege, secret, asset, or executable-data
  boundary. Unknown-location semantic redaction is treated under correctness/
  accessibility and has explicit negative proof. Save bytes and device install
  safety remain operational gates, not changed product code.

Residual risks deliberately left to implementation/device evidence:

1. Fixed labels may need a few pixels of offset on the actual 411×914 logical
   device; only label offsets/padding may tune, not topology, node centers,
   wording, touch size, or discovery rules.
2. Font/platform antialiasing can make thin strata/fractures too quiet or too
   loud. Automated proofs cover category/value/clipping; the colour/greyscale
   device pairs decide bounded non-Crypt stroke/anchor tuning.
3. Deterministic road-fight fixture seeds for the two spurs are source facts, not
   product choices. Task 03 derives them with a removed throwaway sweep and
   records literals in test comments; failure to find a first-day encounter is
   an escalation rather than a rules change.
4. A CustomPainter has no semantics of its own. The plan deliberately overlays
   explicit route semantic containers and node controls; the device/review gate
   must still confirm traversal is coherent and has no duplicate announcements.

None is an unresolved product or architecture decision.

## Planner receipt

- **STATUS:** READY — execution-grade; implementation remains separately
  unauthorized until explicit user approval of this plan.
- **Source/dirty assumption:** `f322d78` on `main`; packages clean;
  architect-owned `LEDGER.md`, `RESUME.md`, and `units/unit-8/` dirty/untracked
  and preserved. Implementation branches to `residuum-visual-reboot-8`, never
  writes on `main`.
- **Tasks:** `01-world-route-diagram.md` → `02-regional-materials.md` →
  `03-theme-context-wiring.md` → Main full gates → acceptance review/corrections
  → user-started Medium_Phone device gate.
- **Quality:** COR/TTC/CRF PASS; SEC SKIP for no trust-boundary change.
- **Next action:** Main inspects this receipt and the locked interfaces, presents
  the execution-grade plan for explicit user approval, and only after approval
  creates/checks out the non-main feature branch and dispatches task 01 to a
  fresh non-isolated `flow-plan-executor`.