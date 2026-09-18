# Task 01 — Crawl Style Seam, Scoped Theme, Mock Column Order

Owner: one fresh `flow-plan-executor` on the Unit 12 feature checkout.

Read `../CONTRACT.md`, `../recon.md`, `../PLAN.md`, then
`packages/app/lib/game/game_screen.dart`,
`packages/app/lib/game/crawl_status.dart`,
`packages/app/lib/town/town_style.dart`,
`packages/app/lib/main.dart`, `packages/app/lib/game/action_icon.dart`, and
`packages/app/test/support/phone.dart` before editing. Look at frames 2–4 of
`.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.

All commands run from `packages/app`. There is no root pubspec.

## Starting condition

- a non-isolated Unit 12 feature checkout, not `main`;
- production source descends from
  `60909e60ec3150cf9b590e6641a8ae51efca775c`;
- the approved contract and plan are present and implementation has explicit
  user approval;
- no Unit 12 production change is present: `lib/game/crawl_style.dart` and
  `lib/game/crawl_surfaces.dart` do not exist, `GameScreen`'s `Column` is still
  `BattleDock → Expanded map → BattleShelf → CrawlStatus → LogPeek →
  _Controls`, and `crawl_status.dart:6` still imports `../town/town_style.dart`;
- any pre-existing `.flow/` planning changes are user-owned and preserved.

Inspect branch, HEAD and worktree before editing. Never discard, stash or
reset user work. If a named seam differs materially from the above, stop and
report rather than adapting.

## Behavioral slice

The crawl renders in the approved mock's order with one crawl-owned style
authority behind its shell, and every fact, control, key, string and dispatch
on the screen still behaves exactly as it does today. Status moves above the
map; the map spans the full width and meets the chrome through hairlines; the
crawl's Material defaults come from a `GameScreen`-scoped theme instead of
stock Material 3.

This task does **not** merge the two action rows and does **not** restyle the
timeline, the log, the chips or the overlays. Those are Tasks 02 and 03.

## Owned files

- new `packages/app/lib/game/crawl_style.dart`;
- new `packages/app/lib/game/crawl_surfaces.dart`;
- `packages/app/lib/game/game_screen.dart`;
- `packages/app/lib/game/crawl_status.dart`;
- new `packages/app/test/widget/crawl_layout_test.dart`.

Do not touch `battle_view.dart`, `log_drawer.dart`, `action_icon.dart`,
`spell_row.dart`, `pack_screen.dart`, `main.dart`, `town_style.dart`,
`game_bloc.dart`, any `lib/town/**`, `lib/world/**`, Unit 11's renderer files,
`packages/core` or `packages/content`.

## Locked decisions

### `crawl_style.dart` — this task's membership only

A plain file of `const` values plus one `ThemeData`. Not a `ThemeExtension`,
not an `InheritedWidget`, no widgets, no change to the global theme. Declare
**only** what this task consumes; Tasks 02 and 03 append their own members.

```dart
const Color crawlInk = Color(0xFFE6EAF0);
const Color crawlDim = Color(0xFF8A919E);
const Color crawlPanel = Color(0xFF15181F);
const Color crawlRule = Color(0xFF2A2E38);
const Color crawlVoid = Color(0xFF0E1014);
const Color crawlRaised = Color(0xFF1B1F27);
const Color crawlRecessed = Color(0xFF11141A);

const double crawlGutter = 12;
const double crawlRhythm = 4;
const double crawlRadius = 6;
const double crawlHairline = 1;
const double crawlTapTarget = 44;

const TextStyle crawlPlace = TextStyle(
  fontFamily: 'monospace',
  fontSize: 15,
  letterSpacing: 3,
  fontWeight: FontWeight.w500,
  color: crawlInk,
);
const TextStyle crawlBody = TextStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  color: crawlInk,
);
const TextStyle crawlBodyDim = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  color: crawlDim,
);

final ThemeData crawlTheme = ThemeData(/* see below */);
```

`crawlTheme` is a **top-level `final`**, not a function and not built per
build, so Dart initialises it once and no `build` allocates a `ThemeData`. It
is constructed from scratch — never `Theme.of(context).copyWith(…)` — so it
cannot inherit a future global change. Configure exactly:

- `brightness: Brightness.dark`, `useMaterial3: true`,
  `scaffoldBackgroundColor: crawlVoid`;
- `iconTheme: IconThemeData(color: crawlInk, size: 18)`;
- `splashColor` and `highlightColor` from `crawlRaised` at reduced alpha;
- `progressIndicatorTheme: ProgressIndicatorThemeData(color: crawlInk,
  linearTrackColor: crawlRule)`;
- `textButtonTheme` with `foregroundColor: crawlInk` and
  `overlayColor: crawlRaised`;
- `bottomSheetTheme`: `backgroundColor: crawlPanel`,
  `surfaceTintColor: Colors.transparent`, `elevation: 0`, `showDragHandle:
  false`, and a top-rounded `crawlRadius` shape;
- `dialogTheme`: `backgroundColor: crawlPanel`,
  `surfaceTintColor: Colors.transparent`, and a `crawlRadius` shape with a
  `BorderSide(color: crawlRule, width: crawlHairline)`.

Leave `bottomSheetTheme.modalBarrierColor`, `dialogTheme.titleTextStyle` and
`dialogTheme.contentTextStyle` unset. Their values do not exist yet —
`crawlScrim` arrives in Task 03, `crawlPanelTitle` and `crawlLine` in Task 02 —
and Task 03 fills all three. Do not invent placeholder values for them here.

### The scoped theme's one application site

Wrap `GameScreen`'s `Scaffold` in `Theme(data: crawlTheme, child: Scaffold(…))`
— inside `BlocListener`, outside `Scaffold`. Everything in the crawl column,
both `Stack` overlays and the recenter affordance are then under it. Do not
wrap the `MaterialApp`, do not wrap a route, and do not touch `main.dart`.

The crawl pack route is pushed with `MaterialPageRoute` onto the root
navigator (`game_screen.dart:293-300`) and is therefore a sibling of
`GameScreen`, not a descendant of this `Theme` — that is what keeps the pack
screen on the town's appearance, and it must stay a root-navigator push.

### `crawl_surfaces.dart` — `CrawlPill` only

```dart
class CrawlPill extends StatelessWidget {
  const CrawlPill({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
}
```

- `Material(color:, shape: RoundedRectangleBorder(side: BorderSide(color:,
  width: crawlHairline), borderRadius: BorderRadius.circular(crawlRadius)))`
  wrapping an `InkWell(onTap: onPressed, borderRadius: …)`. The `Material` is
  required: without it the ink response lands on the `Scaffold` behind the
  pill.
- enabled: `crawlRaised` fill, `crawlRule` border, word in `crawlBody`;
  `onPressed == null`: `crawlRecessed` fill, `crawlRule` border, word in
  `crawlBodyDim`, no ink response.
- wrapped in `Semantics(button: true, enabled: onPressed != null, label: label,
  onTap: onPressed)` + `ExcludeSemantics`, matching `_Control`'s existing
  pattern at `game_screen.dart:496-501`.
- `icon == null`: `Padding(horizontal: crawlGutter, vertical: 8)` around
  `Text(label, style: …)`, `minHeight: 40`.
- `icon != null`: a `crawlTapTarget` square holding `Icon(icon)` centred, and
  `label` is the semantic label only — the word is not drawn.

Declare no other member in this file; Tasks 02 and 03 append theirs.

### The column order

`GameScreen`'s `Column` becomes exactly:

```text
CrawlStatus(state: state, dungeon: bloc.dungeon)
if (state.isBattleOpen) BattleDock(state: state, onActorSelected: …)
Expanded(key: dungeonSceneSlotKey, child: <map slot>)
LogPeek(key: logPeekKey, state: state, bloc: bloc)
if (state.isBattleOpen) BattleShelf(state: state, bloc: bloc)
_Controls(key: controlsKey, state: state)
```

`BattleShelf` immediately above `_Controls` is a **deliberately temporary**
arrangement: AC3 (one action row) is Task 03's, and moving the shelf here
leaves Task 03 one local merge site. `shelfKey` and `controlsKey` survive this
task unchanged.

`BattleDock`'s `onActorSelected` closure — `presentationOf`, the
`TimelineActorSelected` dispatch and `showEnemyInfo` — is moved verbatim.
The `PopScope`, `BlocListener`, `Scaffold`, `SafeArea`, `BlocBuilder`, `Stack`,
`LogDrawer` overlay condition and `_DeathOverlay` condition are unchanged.

### The map slot and its framing

Remove the `Padding(EdgeInsets.all(8))` at `game_screen.dart:80-81`. The
`Expanded(key: dungeonSceneSlotKey)` instead holds a `DecoratedBox` (or
`Container` with only a `decoration`) carrying
`Border(top: BorderSide(color: crawlRule, width: crawlHairline), bottom:
BorderSide(color: crawlRule, width: crawlHairline))` around the existing
`LayoutBuilder`. The map now spans the full surface width.

`DungeonSceneHost`, `dungeonSceneHostKey`, `LayoutBuilder`,
`constraints.biggest`, `GridGeometry.camera`, `_heroOffScreen`, `_onMapTap`,
`_onMapLongPress`, `MapPanned` and `RecenterPressed` keep their exact wiring.
The renderer's own output is untouched; only the box it is handed changes.

The recenter affordance keeps `recenterKey` and
`Positioned(top: 8, right: 8)`, and becomes:

```dart
CrawlPill(
  key: recenterKey,
  label: 'Recenter on the hero',
  icon: Icons.center_focus_strong,
  onPressed: () => bloc.add(const RecenterPressed()),
)
```

Nothing else in the map slot changes.

### `crawl_status.dart`

Replace the `../town/town_style.dart` import with `crawl_style.dart` and map:
`mono` → `crawlBody`, `ink` → `crawlInk`, `rule` → `crawlRule`; the place name
in `_HeaderRow` takes `crawlPlace`. Padding becomes
`EdgeInsets.symmetric(horizontal: crawlGutter, vertical: crawlRhythm)`, the
inner gap `SizedBox(height: crawlRhythm)`, and a `crawlHairline` `crawlRule`
rule is added beneath the resource row so the block reads as its own region
against the map below it.

Composition is otherwise frozen: `_HeaderRow`, `_ResourceRow`, `_Meter`,
`_BattleGlyph`, every `FittedBox(fit: BoxFit.scaleDown)`, the 18 dp glyph cell,
the 64 dp depth cell, the 8/6/6 meter flexes, `minHeight: 8`,
`hpMeterKey`, `manaMeterKey`, `depthPairKey`, `_placeName`, `_battleWord`,
`_condition` and every string are unchanged. The `LinearProgressIndicator`
keeps its explicit `backgroundColor: crawlRule` and
`valueColor: AlwaysStoppedAnimation(crawlInk)` — the theme entry is a floor,
not a replacement, and `crawl_status_test` reads `indicator.value`.

### `game_screen.dart` note rows

The three inline `TextStyle`s at `:233-238`, `:245-249` and `:260-264` become
`crawlBodyDim`. The sentences, their conditions and their order are unchanged,
and they keep wrapping onto a second line. Do not fold the shelf, control,
overflow, dialog or death-overlay styles — Task 03 rewrites those trees
wholesale and folding them here is work it deletes.

## Red proof

Write `test/widget/crawl_layout_test.dart` first. Stage a dungeon crawl and an
open battle over a real `GameBloc` and the real `GameScreen`, at phone size via
`onAPhone` from `test/support/phone.dart` — follow `crawl_controls_test.dart`'s
`_openCrawl` shape, or `log_drawer_test.dart`'s `_pushGame` if a `TownBloc` is
needed.

Assert:

1. exploring: `getTopLeft(find.byType(CrawlStatus)).dy <
   getTopLeft(find.byKey(dungeonSceneSlotKey)).dy`;
2. exploring: the map slot's bottom is at or above `logPeekKey`'s top, and
   `logPeekKey`'s top is above `controlsKey`'s top;
3. in an open battle: status top < `Key('dock-backing')` top < map slot top;
4. the map slot's rect spans the full surface width — `left == 0` and
   `right == surfaceWidth` — and its height is greater than zero in both
   scenes;
5. cycling the log extent peek → half → full → peek leaves the map slot rect
   and the peek rect unchanged.

Run:

```text
flutter test test/widget/crawl_layout_test.dart
```

Expected Red: 1, 2 and 3 fail because status and the timeline render below the
map today; 4 fails on the 8 dp horizontal inset. 5 passes before and after and
is the regression that proves the reorder introduced no reflow.

These must stay green while the new assertions fail, and be green at handoff:

```text
flutter test test/widget/crawl_status_test.dart test/widget/log_drawer_test.dart test/widget/crawl_controls_test.dart test/widget/battle_shelf_icons_test.dart test/widget/craft_surfaces_test.dart test/widget/back_guard_test.dart test/widget/suspend_door_test.dart test/widget/door_reentry_test.dart test/battle_view_test.dart test/battle_characterization_test.dart
```

If `crawl_status_test.dart`'s worst-case no-squeeze loop fails on
`crawlPlace`'s letterspacing, reduce `letterSpacing` toward 2 — the existing
`FittedBox` should absorb it. Do not remove the `FittedBox` and do not change
a status string.

## Green proof and package gates

Implement only this slice, rerun the focused commands until green, then from
`packages/app`:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Record the Red failure text and every Green exit status. Run no device gate in
this task.

## Executor discretion

- private widget and helper names; whether the map slot's border uses
  `DecoratedBox` or `Container`;
- the exact alpha on `splashColor`/`highlightColor`;
- `crawlPlace`'s `letterSpacing` inside 2–3 and `fontSize` inside 14–16, if the
  no-squeeze loop demands it;
- fixture arenas, hero stats and scene staging in the new test;
- whether `crawl_layout_test.dart` shares helpers with an existing test file or
  stages its own.

Not discretionary: the seam's member names and values, the column order, the
temporary `BattleShelf` placement, the theme's single application site, removal
of the map padding, `CrawlPill`'s API, or any string, key, guard or dispatch.

## Escalate when

- repository reality contradicts the starting condition or a named seam;
- the scoped `Theme` demonstrably reaches a screen outside `GameScreen`, or
  fails to reach a Material surface inside it;
- removing the map padding breaks the renderer's own output rather than only
  its framing;
- a `crawl_status_test` or `log_drawer_test` assertion can be kept green only
  by changing a player-facing string, a key or a progress value;
- the reorder reintroduces map reflow on a log extent change;
- meeting the slice would require editing `main.dart`, `town_style.dart`,
  `game_bloc.dart`, the renderer, `packages/core` or `packages/content`;
- following a locked decision here would knowingly ship a defect.

## Completion receipt

Return one compact receipt containing:

- `STATUS: COMPLETE` or `BLOCKED`;
- starting and resulting revision plus dirty-state summary;
- changed and added paths;
- the Red command and the behavioural failures observed;
- focused Green command plus format, analyze and full-suite results;
- the measured chrome height (surface height minus map slot height) at phone
  size, in exploration and in an open battle, and the measured map slot height
  for each;
- confirmation that: the column order matches the plan, `BattleShelf` sits
  immediately above `_Controls` as the temporary arrangement, the map spans
  full width with hairlines, `crawl_status.dart` no longer imports
  `town_style.dart`, `main.dart` is unchanged, and no string, key, guard or
  dispatch moved;
- residual findings and the exact next action: Task 02 may start only when this
  repository state and receipt are accepted.
