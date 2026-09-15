# Task 01 — Fixed world route diagram

Owner: first fresh `flow-plan-executor` on the Unit 8 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. You have no conversation
history and need none: repository state plus those two artifacts is the complete
authority.

## Expected starting repository condition

- A non-`main` feature checkout branched from
  `f322d78c8ec445df8c0a66bdf528b37178322cb0`, by house convention
  `residuum-visual-reboot-8`, with `packages/` clean.
- No Unit 8 production change has landed. `world_screen.dart` still renders
  `_Place`/`_Unheard` `ItemRow`s under `Heading('The world')`, and
  `test/support/world_nav.dart` still finds a `Row` and taps `Walk`.
- `.flow/**` may be dirty with architect-owned records. Do not edit, revert,
  stash, commit, or relocate them.

Before editing, inspect branch and worktree state. Implementation on `main` is
forbidden. If a planned file has unexplained changes, the graph is not exactly
the five nodes/five routes in `../PLAN.md`, or a revalidated seam no longer
matches, stop and report the contradiction rather than improvising.

## Behavioral slice and file ownership

Replace the vertical place menu with the complete fixed spatial route diagram.
The handoff is valid when the world surface is behaviorally green with no
material/theme work yet: travel, rumors, saves, roads, dungeons, camps, towns,
and Heroes behave exactly as before.

Touch only:

- add `packages/app/lib/world/world_route_diagram.dart`;
- edit `packages/app/lib/world/world_screen.dart`;
- edit `packages/app/test/widget/world_screen_test.dart` for diagram behavior
  and obsolete world-menu finder/assertion migration;
- edit `packages/app/test/support/world_nav.dart` only to replace the retired
  `ItemRow`/`Walk` lookup with the labelled node-control lookup.

Do not edit `world_bloc.dart`, `main.dart`, anything under `lib/game`,
`town_bloc.dart`, town/Character composition, save/dependency/generated/asset
files, any other test helper, `packages/core`, `packages/content`, or LDD
records. Do not introduce theme context; tasks 02–03 own it.

## Locked implementation

### `world_route_diagram.dart`

Implement the exact public constructor and immutable inputs in `../PLAN.md`
section 1. The widget imports Flutter/core/content as needed but does not import
`flutter_bloc` or any app bloc. It retains no state and dispatches only
`onDestination(WorldNode)`.

Use a 430-logical-pixel portrait `Stack` behind the existing world scroll. The
node centers are fixed:

- Sea-Cave `(0.20, 0.12)`;
- Ruined Keep `(0.80, 0.12)`;
- Northgate `(0.50, 0.39)`;
- Crypt `(0.74, 0.68)`;
- Stonebridge `(0.26, 0.84)`.

Recognize these exact content ids; do not derive positions from list order,
route order, names, glyphs, or kind. A private lookup that receives anything
else must fail clearly rather than produce a generic placement. Node slots are
120×72 logical pixels minimum. Towns have a square/2-radius outline; dungeons a
stadium outline. A known node shows its source name plus the word `TOWN` or
`DUNGEON` and exactly one state phrase:

- `HERE` only when no journey exists and this is `whereabouts.at`;
- `REACHABLE` only when its id is in the supplied destinations;
- `NO ROAD FROM HERE` for another discovered, nonadjacent node while standing;
- `TRAVEL IN PROGRESS` for discovered nodes while a journey exists.

Use a second outline and `Semantics.selected: true` for `HERE`. Use explicit
value/word/shape contrast with existing neutral `ink`, `dim`, `panel`, `rule`;
no state or kind is hue-only. A known node is a semantic button with one label
containing kind, exact name, and state. It is enabled only when `REACHABLE` and
not travelling. Disabled known nodes remain in traversal but cannot invoke the
callback.

An undiscovered slot is an identical neutral circular marker at its fixed node
center. Its visible child is only `?`. It has no gesture, button role, focus
action, tooltip, hidden label, or callback; its complete semantic label is
`Unknown location. Not discovered.` Exclude the visual `?` from a duplicate
announcement. Never expose the hidden `NodeId`, name, kind, region, route
endpoint, cost, danger, or reachability through any rendered/semantic string.
Widget keys may identify fixed slots for tests but must not enter semantics.

Routes are drawn behind all node controls. Filter `map.routes` to routes whose
**both endpoints** are in `whereabouts.discovered` before looking up endpoint
names, label positions, days, or current danger and before invoking
`dangerFor`. Do not draw even an unlabelled line to an unknown node: connectivity
is a gameplay fact and the contract grants only fixed unknown positions.

For each projected route, call `dangerFor(route)` exactly once during that
projection. Draw a neutral solid line and overlay visible text on two lines:
`<N> DAY`/`<N> DAYS`, then `DANGER <danger>/100`. Give it one non-action semantic
container:

`Route from <from name> to <to name>. <N> day(s). Current danger <danger> in 100.`

Exclude the visible route text from duplicate semantics. Use the fixed label
centers from `../PLAN.md`: cave spur `(0.33, 0.24)`, keep spur `(0.67, 0.24)`,
Stonebridge–Northgate `(0.37, 0.58)`, Northgate–Crypt `(0.63, 0.54)`, and
Stonebridge–Crypt `(0.56, 0.82)`. You may nudge only a label's local offset or
padding to avoid overlap. Do not move a node or reassociate a label.

If `whereabouts.journey` joins a route, draw that route with a double/thicker
value-contrast line and append visible `ON THIS ROAD`. Its semantic label also
appends `You are on this road. <daysLeft> day(s) remain.` This is where the
hero's current map location lives while travelling; never call
`Whereabouts.at` current during a journey.

Use explicit semantic traversal order that remains stable as discovery changes.
Use only words and ASCII punctuation already available; add no icon, arrow,
chevron, bullet, new mark codepoint, asset, animation, pan/zoom, terrain, or
future-map abstraction. Painter output itself carries no semantics; overlay
semantic route containers.

### `world_screen.dart`

Keep the `Scaffold`, `SafeArea`, header padding, expanded `ListView`, notice,
road log, action-area padding, `_Standing`, `_confirmTravel`, `_Here` and all its
state/dialog helpers, `_CampLost`, `_CampWarning`, and `WorldDoor` behavior.
Preserve every displayed string outside the new diagram.

Inside the existing `ListView`, replace `Heading('The world')`, the `_Place`
loop, and the appended `_Unheard` loop with one world heading plus
`WorldRouteDiagram`. Supplying `Heading('The world')` is allowed and expected;
the menu rows themselves are not. Capture `final world =
context.read<WorldBloc>()` once per WorldBloc build, compute destinations from
`state.destinationsFrom(world.map)`, and pass the existing `_confirmTravel` as
the only destination callback.

Wrap only `WorldRouteDiagram` in a `BlocBuilder<TownBloc, TownViewState>` whose
`buildWhen` compares `before.profile != after.profile`. Its builder calls the
existing `world.dangerFor` closure; it does not call `dangerOn` or read a profile
inside the diagram. This ensures skill progression changes displayed danger
without giving profile ownership to `WorldBloc`.

Delete `_unheardOf`, `_Place`, and `_Unheard` completely. Leave no hidden
`ListView`, compatibility widget, list fallback, dead marker function, or
second graph projection. Keep `_confirmTravel`'s direct-route null guard,
day wording, dialog, cancellation, and `TravelRequested` dispatch unchanged.
Do not put Heroes in the diagram.

### Test migration

Work test-first in `world_screen_test.dart`:

1. Replace the obsolete `[T]`/`(D)`/`[?]` and generic unheard-row composition
   tests with a fresh discovery boundary test using semantics. On a fresh save,
   assert exactly Stonebridge and The Crypt are named, the other three names and
   all hidden town/dungeon/route facts are absent from both visible and semantic
   labels, exactly three safe unknown semantic labels exist, and only the
   Stonebridge–Crypt route label (`1 DAY`, current danger) exists. Expected Red:
   no fixed-node/route semantics or cost/danger label exists and current unknown
   prose is not the locked safe label.
2. Add a fully discovered test with a profile whose total skill levels make
   `dangerOn(route, profile)` differ from every base `Route.danger`. Assert all
   five names, two town/three dungeon kind words, all five day labels and all
   five **current** danger values. Assert direct destinations are enabled and
   known nonadjacent nodes expose `NO ROAD FROM HERE` and disabled semantics.
   Expected Red: the list exposes no route values and no current-danger
   projection.
3. Add a fixed-slot discovery test: record the unknown Northgate slot center and
   safe semantics on a fresh screen, buy the existing first rumor through the
   real Tavern flow, return, and assert Northgate occupies the identical center,
   is named/kinded, and its newly known routes appear while Sea-Cave/Keep remain
   safe unknowns with no spur lines/labels. Expected Red: current unknown rows
   are appended generically rather than occupying Northgate's fixed site.
4. Add a journey test from a persisted `Journey`: assert the matching route has
   `ON THIS ROAD`, semantics include days remaining, no node says `HERE`, every
   node travel control is disabled, and existing header plus `Walk on` remain.
   Expected Red: the header exists but the list has no current-route mark.
5. Keep the existing confirmation/cancellation test behavioral: select the
   Crypt node itself, assert the unchanged dialog, choose `Stay here`, and
   verify day/location unchanged. Do not assert `OutlinedButton`, painter type,
   normalized coordinates, colours, or private classes.
6. Keep every existing travel/save/tavern/town/camp/dungeon/road-fight state and
   wording assertion. Migrate only the two direct `Row`/`Walk` finders and any
   old marker assertions. A preserved test failure means behavior moved; fix
   production, not the test.

In `test/support/world_nav.dart`, make `walkTo(tester, place)` find the enabled
ancestor control of the exact place-name text, tap it, and retain the same
`Set out` plus timer pumping. Do not expose diagram geometry to the helper and
do not change `enterTown`, `backToTheWorld`, or `openTownDoor`.

Use real `WorldBloc`/`TownBloc`/session state, `tester.ensureSemantics()` with
proper disposal, and `// arrange` / `// act` / `// assert`. No golden, source
text assertion, mock bloc, screenshot, arbitrary delay, or test-only production
hook.

## Red/Green proof and commands

Record the focused Red from the new/changed world tests before production edits.
After Green, run from `packages/app`:

```sh
flutter test test/widget/world_screen_test.dart \
  test/world_bloc_test.dart \
  test/widget/suspend_door_test.dart \
  test/widget/boot_wiring_test.dart \
  test/widget/town_shell_test.dart

dart format lib/world/world_route_diagram.dart lib/world/world_screen.dart \
  test/widget/world_screen_test.dart test/support/world_nav.dart

dart analyze lib/world/world_route_diagram.dart
dart analyze lib/world/world_screen.dart
dart analyze test/widget/world_screen_test.dart
dart analyze test/support/world_nav.dart
```

Re-run the focused tests after formatting or static correction. Do not run the
full suite, whole-package analyzer, whole-tree formatter, build, emulator, or
device install. `world_bloc_test.dart` must pass without edits.

## Executor discretion

You may choose private helper/painter names, test helper names and fixture
placement, and small route-label padding/offset adjustments that prevent overlap
without changing locked centers, association, text, semantics, or touch size.
You may split private widgets inside the new file. Add no new app Dartdoc
(`AGENTS.md` allows `///` only on the public API of `core` and `content`) and no
body comments beyond existing test arrange/act/assert structure.

You may not change the public constructor, node centers, route-label
associations, node shapes/kind/state words, unknown label, route/danger wording,
discovery filter order, danger source/rebuild ownership, callback, touch size,
WorldBloc/TownBloc interfaces, existing dialogs/actions, or deletion of the old
menu classes.

## Escalate when

- any unknown visible or semantic surface would reveal a forbidden fact or a
  route line would reveal hidden connectivity;
- `dangerFor` cannot be refreshed from the existing TownBloc profile without a
  bloc/model change or current danger differs from the value travel uses;
- fixed labels cannot avoid node overlap without moving locked centers,
  shortening facts, hiding a route, or dropping below the touch minimum;
- a direct discovered destination cannot remain a labelled button while current,
  nonadjacent, unknown, and travelling nodes remain inert/disabled;
- any preserved transition, save, dialog, notice, road/camp/dungeon, Heroes, or
  source-wording test fails;
- implementation appears to require `world_bloc.dart`, `main.dart`, `lib/game`,
  town/Character work, core/content/save/dependency/assets, a new codepoint, or
  work on `main`.

## Handoff state and completion receipt

Task 01 is complete when the old list projection and classes are deleted, the
fixed five-node diagram safely projects known nodes/routes/current danger and
journey location, all current actions remain outside it, the focused world
suite is green, and no forbidden file changed. Task 02 may start from that
repository state without this executor's context.

Report to Main in at most eight prose lines:

- branch/base and the exact behavioral Red observed;
- focused test command and pass count, including unchanged `world_bloc_test`;
- fresh/fully-discovered/fixed-rumor-slot/journey accessibility results;
- current-danger source and direct-route confirmation/cancellation result;
- confirmation `_Place`, `_Unheard`, `_unheardOf`, and old `Walk` finder are gone;
- files added/changed and confirmation no forbidden path changed;
- formatter/analyzer commands and results;
- any escalation or residual device-fit item.