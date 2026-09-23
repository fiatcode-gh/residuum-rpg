# 12 — Anchored map callout for inspected monsters

Governing: `../CONTRACT.md` scope item 4 ("Exploration callout"), scope
item 3 (inspect on tap/long-press), acceptance 2; `../PLAN.md` §2 G7
(routing), G11 (callout facts). Work from `packages/app`.

## Starting repository state

Task 11 committed. Map taps/long-presses resolve through `map_touch.dart`;
`MapTouchInspect` opens `showEnemyInfo` (bottom sheet). `targetActor =
selectedActor ?? (battle ? nearest : null)`. `GameViewState` handlers rebuild
state naming only the fields they carry (reset-by-construction).

## Owned files

`lib/game/game_bloc.dart` (`inspectedActorId`, `inspectedActor`,
`targetActor`, two events + handlers), new `lib/game/map_callout.dart`,
`lib/game/game_screen.dart` (map-slot Stack + inspect routing),
`lib/game/dungeon_scene.dart` (`_reusesProjection` if the target id source
changes), `lib/game/crawl_style.dart` (callout constants); tests
`test/game_bloc_test.dart`, new `test/widget/map_callout_test.dart`,
`test/battle_view_test.dart`, `test/game/dungeon_scene_test.dart` and
`test/widget/crawl_surfaces_test.dart` (its enemy-sheet surface test opens
the sheet from the timeline or calls `showEnemyInfo` directly) where map
inspect expected the sheet.

Non-goals: timeline selection keeps `TimelineActorSelected` + the sheet.

## Locked decisions

1. `GameViewState` gains `final String? inspectedActorId` (constructor
   param, default null) and
   `Actor? get inspectedActor` (alive, visible, presentation known — same
   test as `selectedActor`). `targetActor` becomes
   `inspectedActor ?? selectedActor ?? (isBattleOpen ? nearest : null)`.
   Events: `ActorInspected(String actorId)` → emits a state carrying the
   same fields the `TimelineActorSelected` handler carries (`game`, `log`,
   `autoPath`, `walkId`, `armedSpellId`, `hasFled`, `actorIdentity`,
   `logDrawerExtent`, `logFollowing`, `logUnread`) with
   `selectedActorId: state.selectedActorId` unchanged and
   `inspectedActorId: actorId` (ignored when the actor is not
   alive/visible/known);
   `InspectDismissed()` → same carry with `inspectedActorId: null`, no-op
   when already null. No other handler names `inspectedActorId`, so any step,
   pan, recenter, log, arm or tap clears it by construction.
2. Routing in `GameScreen`: `MapTouchInspect(actor)` →
   `bloc.add(ActorInspected(actor.id))` (tap and long-press);
   `MapTouchNothing` → `InspectDismissed()` only when
   `state.inspectedActorId != null`; `MapTouchCell` unchanged. Map inspect
   no longer opens the sheet.
3. `MapCallout` (inside the map-slot Stack, above `DungeonSceneHost`, below
   the recenter pill and notes), shown when `state.inspectedActor != null`
   and its cell rect intersects the viewport. Geometry from the same
   `GridGeometry.camera(size, …, state.cameraFocus, state.pan)` the recenter
   check uses. Card width 172; height
   `20 + 17 + 4 + 13 + 4 + 14·k`, `k = 2 + resists.length + vulnerableTo.length`;
   placement: above-right (`left = cell.right + 14`, `bottom = cell.top − 6`),
   flip left when `right > width − 8`, below (`top = cell.bottom + 6`) when
   `top < 8`, then clamp inside `[8, width − 8] × [8, height − 8]`.
   Content (padding 10): name `displayName` (capitalised display name,
   single line scale-down), `HP a/b` `monoData`, lines `monoMeta`:
   `ATK a–b  SPD s`, `Reach r`/`Adjacent`, one `Resists <word>` /
   `Burns at <word>` per type. Card `crawlCalloutFill`, 1 dp `crawlFrame`,
   radius 6. Leader: 1 dp `crawlGold` α 0.7 from the cell's top-right
   corner (or top-left when flipped, bottom corner when below) to the card's
   nearest corner, 2.5 dp dot at the cell end; drawn by an `IgnorePointer`
   `CustomPaint`. The card sits in a `GestureDetector(behavior: opaque, onTap: () {})`
   so touches inside it never reach the map; outside touches reach the map
   unchanged.

## Proof (Red first)

`test/game_bloc_test.dart`: `ActorInspected` sets `inspectedActorId` and
`targetActor`; ignored for an invisible/unknown/dead actor (AC2 negative);
`InspectDismissed` clears it; `MapPanned`, `WaitPressed`, `TileTapped`,
`SkillArmed`, `LogDrawerHandlePulled` each clear it; `cameraFocus` does not
change on inspect.
`test/widget/map_callout_test.dart` on `onTheTargetPhone`:
- tap 18 dp off a far known monster's centre → callout with its name,
  `HP a/b`, attack/speed and reach lines; no bottom sheet; heavy brackets on
  that monster's cell;
- a monster near the right edge → card flips left; near the top → below;
  card rect always inside the map slot;
- tapping inside the card changes nothing; tapping empty blank space
  dismisses; tapping a floor cell dismisses and the bloc answers the tap as
  before (step, walk or the watched refusal); a long-press on the monster
  opens the callout;
- the monster leaving sight (step the game so it is not visible) removes the
  callout; the map rect is unchanged with and without the callout;
- timeline actor tap still opens the sheet (battle).
Expected Red: events/state/widget missing; map inspect opens a sheet.
Green: `flutter test test/game_bloc_test.dart test/widget/map_callout_test.dart test/battle_view_test.dart test/game test/widget/crawl_layout_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Painter/card widget split; exact leader corner choice when the card is
clamped; test fixtures.

## Escalate when

Reset-by-construction does not clear the callout on some handler that
steps the game (report which); the card cannot avoid covering the target
cell on a 13 × 16 map near a corner; anything would show facts of a hidden
actor.

## Completion receipt

Red output, Green command/exit, analyzer/format exits, list of handlers
verified to clear the callout. Commit:
`feat(app): show inspected monsters in an anchored map callout`.
