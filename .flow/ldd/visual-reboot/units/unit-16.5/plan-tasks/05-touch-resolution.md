# 05 — Intent-based touch resolution on dense cells

Governing: `../CONTRACT.md` scope item 3, acceptance 4; `../PLAN.md` §2 G7,
§7 E1–E2. Work from `packages/app`. Runs only after Main records
Checkpoint A "on track" in the ledger.

## Starting repository state

Tasks 01–04 committed (plus any Checkpoint A correction). `_DungeonScene`
converts taps/long-presses with `_geometry.positionAt` and calls
`ValueChanged<Position> onTap/onLongPress`; `game_screen.dart::_onMapTap`
routes armed → `TileTapped`, far known monster → `showEnemyInfo`, else
`TileTapped`; `_onMapLongPress` opens `showEnemyInfo` for
`state.inspectTargetAt(position)`. `GameBloc._onTileTapped` is the rules
authority (unchanged here).

## Owned files

new `lib/game/map_touch.dart`; `lib/game/dungeon_scene.dart` (callback
types and the three gesture handlers); `lib/game/game_screen.dart`
(`_onMapTap`, `_onMapLongPress` and the `DungeonSceneHost` wiring only);
new `test/game/map_touch_test.dart`; tests constructing `DungeonSceneHost`
or asserting map taps (`test/game/dungeon_scene_test.dart`,
`test/battle_view_test.dart`, `test/battle_flow_characterization_test.dart`,
`test/widget/crawl_action_row_test.dart` and any other grep hit for
`onTap: (` on the host).

Non-goals: callout and inspect state (Task 12 — inspect still opens the
existing sheet here); bloc rules; pan/recenter behaviour.

## Locked decisions

1. `map_touch.dart` implements PLAN G7 verbatim: `mapTouchRadius = 22`,
   the sealed `MapTouch` family, `resolveMapTap`, `resolveMapLongPress`,
   the armed list (1–4), the unarmed list (1–6, including the step-cell
   guard and the dominant-axis 4-way step with `|u| ≥ |v|` → horizontal),
   the melee/inspect split by `isOrthogonallyAdjacentTo`, and `nearest`
   with ties by distance, then `byRowThenColumn`, then `id`. Pure functions
   of `(GameViewState, GridGeometry, Offset)`; all dp↔cell arithmetic goes
   through `GridGeometry` (`positionAt`, `centreOf`).
2. `DungeonSceneHost` / `_DungeonScene` callbacks become
   `typedef MapTouchCallback = void Function(Offset local, GridGeometry geometry);`
   for `onTap` and `onLongPress`; handlers pass the canvas-local point and
   the scene's own `_geometry` for every touch (no null filtering in the
   scene). `onPan` unchanged. No rendering layer adds input handlers.
3. `GameScreen`: tap → `switch (resolveMapTap(state, geometry, local))`:
   `MapTouchCell(:final position)` → `bloc.add(TileTapped(position))`;
   `MapTouchInspect(:final actor)` → existing `showEnemyInfo(context, actor, state.presentationOf(actor.id)!)`;
   `MapTouchNothing` → nothing. Long-press → `resolveMapLongPress`, inspect
   or nothing.

## Proof (Red first)

`test/game/map_touch_test.dart` (pure; geometry from `GridGeometry.camera`
on a fixed `Size(390, 440)` with a small hand-built `GameState`):
- armed: a touch 21.9 dp from a legal monster's centre (in an empty cell)
  resolves to its cell; 22.1 dp resolves to the cell under the finger;
  two legal monsters equidistant → the upper (then left) one; a touch on a
  legal monster's own cell wins over a nearer-centred neighbour.
- unarmed: touch on an orthogonally adjacent monster's cell → cell (melee);
  on a far known monster's cell → inspect; 20 dp from a far monster in an
  empty non-neighbour cell → inspect; monster two cells east, touch on the
  east neighbour cell → that cell (guard); touch in a diagonal neighbour
  within 22 dp of the hero → the dominant-axis orthogonal step (exact
  diagonal → east/west); hero at the map's west edge, touch 15 dp west of
  it → falls through (no out-of-bounds step); touch 30 dp east → cell under
  the finger; unknown (not visible) monster within 5 dp is ignored;
  touch outside the grid with nothing within 22 dp → `MapTouchNothing`.
- long-press: nearest known monster within 22 → inspect; 22.1 → nothing.
Widget proof in `test/game/dungeon_scene_test.dart` (or a new
`test/widget/map_touch_wiring_test.dart`): pump `GameScreen` with a
`GameBloc`; tap at `centreOf(adjacent floor)` → hero moves one cell
(bloc state); tap 18 dp off a far monster's centre → the enemy sheet opens;
tap in blank space off the grid → no state change and no sheet.
Expected Red: `map_touch.dart` symbols missing. Existing interaction tests
must stay green; rewrite one only where it relied on the old cell-only
resolution (record which and why).
Green: `flutter test test/game test/battle_view_test.dart test/battle_flow_characterization_test.dart test/widget`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Internal helper names; how fixtures are built; whether the widget proof
lives in a new file.

## Escalate when

A rule in G7 cannot be implemented without a bloc/core change; an existing
test's expected behaviour contradicts G7 in a way not caused by the dense
cell (e.g. diagonal auto-walk now steps — list it, keep the G7 behaviour,
and report); Flame does not deliver canvas-local positions.

## Completion receipt

Red output, Green command/exit, analyzer/format exits, list of rewritten
existing tests with reasons. Commit:
`feat(app): resolve dense-map touches by intent within 22dp`.
