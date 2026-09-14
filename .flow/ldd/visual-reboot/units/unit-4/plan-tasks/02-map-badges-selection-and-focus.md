# Task 02 — Map badges, selected shape, and camera focus

Owner: second fresh sequential executor in the same Unit 4 feature checkout.
Read `../PLAN.md`, `../CONTRACT.md`, `../recon.md`, and inspect task 01's landed
public interfaces. Planning artifacts do not authorize implementation.

## Preconditions and scope

Task 01 focused proofs are Green. `ActorPresentation`, `ActorIdentityContext`,
`GameViewState.presentationOf`, `selectedActor`, and `cameraFocus` exist with the
locked semantics. Touch only:

- `packages/app/lib/game/glyph_plan.dart`;
- `packages/app/lib/game/glyph_marks.dart`;
- `packages/app/lib/game/dungeon_scene.dart`;
- `packages/app/lib/game/game_screen.dart` only for `_heroOffScreen`'s camera
  geometry (no timeline or inspect-sheet migration yet);
- `packages/app/test/game/glyph_plan_test.dart`;
- `packages/app/test/game/glyph_marks_test.dart`;
- `packages/app/test/game/dungeon_scene_test.dart`;
- `packages/app/test/game/armed_targets_test.dart`;
- the camera/recenter assertions in `packages/app/test/battle_view_test.dart`
  only if the focus change requires them.

Do not change battle dock/timeline UI, inspect signatures, bloc semantics,
core/content/save, or `.omp/`.

## Locked implementation

### Projection facts

Extend `GlyphCell` with optional `badge` and `selected` (default null/false).
Keep `glyph` as the raw semantic glyph and keep `renderId` exactly
`(layer, entity ?? position)`.

Extend `glyphPlan` with named inputs:

```dart
Map<String, ActorPresentation> actorPresentations = const {},
String? selectedActorId,
```

For each currently visible monster only:

- `badge = actorPresentations[monster.id]?.badge`;
- `selected = monster.id == selectedActorId`;
- `marked` remains `markedIds.contains(monster.id)`;
- `glyph` remains `monster.glyph`, never `presentation.glyphLabel`.

Terrain, node, litter, hero, draw order, FOV/explored filtering, inks, and
opacity remain unchanged. A known but currently hidden actor produces no
`GlyphCell` and therefore no badge/selection/target fact.

### Shape grammar

Add `enum GlyphOutlineShape { square, circle }` and extend
`GlyphMarkTreatment` with nullable `targetOutline` and `selectedOutline`:

- marked target → square;
- selected actor → circle;
- selected + marked → both;
- neither → neither.

Preserve existing scale/halo decisions. Neither outline may rely on a distinct
hue for meaning.

### Scene and retained components

`DungeonSceneSnapshot.fromViewState` calls `glyphPlan` with
`state.actorIdentity.knownActors`, `state.armedTargets`, and
`state.selectedActor?.id`, and sets `focus: state.cameraFocus`.

`_DungeonSceneHostState` projection-reuse inputs must include the exact actor
identity context instance and selected actor id in addition to current game,
palette, and armed spell. A pan-only state reuses the existing cell list but
calls `withViewport(... focus: state.cameraFocus, pan: state.pan)`. A notice,
selection, arm change, or game-state change rebuilds projection cells.

Extend retained `_GlyphComponent` behavior without changing its render id:

- main `_text` always renders `cell.glyph`;
- optional badge is a separate small monospace `TextComponent` at the
  top-right, created/updated/removed only when `cell.badge` changes;
- target outline remains an inset stroked `RectangleComponent`;
- selected outline is a distinct centered stroked `CircleComponent`;
- both may be children simultaneously and remain visible around the glyph;
- synchronization updates/removes these children in place and includes badge,
  selected, marked, ink, and opacity changes as applicable.

Do not add animation, pulse, easing, timers, another Flame update loop, or
per-frame rebuilding. The existing pause-after-update behavior remains.

### Hero off-screen/recenter geometry

Change only `GameScreen._heroOffScreen`: build `GridGeometry.camera` around
`state.cameraFocus` and `state.pan`, then ask `heroOffScreen` about
`state.game.hero.position`. A selected distant actor therefore makes the
existing recenter affordance appear; task 01's `RecenterPressed` clears
selection and returns focus to hero.

## Red/Green behavioral proof

Write failing behavioral tests first.

`test/game/glyph_plan_test.dart` and `test/game/armed_targets_test.dart`:

1. Two known duplicate presentations project raw `g` semantic glyphs with
   separate `¹`/`²` badges on the correct actor ids.
2. A known but currently hidden duplicate produces no monster cell and no badge
   or selected/marked projection.
3. One selected actor's cell is selected; the other is not.
4. A selected, armed-target duplicate has `badge == '¹'`, `selected == true`,
   and `marked == true` on the same stable actor cell.

Expected Red: `GlyphCell` and `glyphPlan` lack these facts; replacing glyph text
with `g¹` must fail the semantic-glyph assertion.

`test/game/glyph_marks_test.dart`:

- target-only treatment is square;
- selected-only treatment is circle;
- selected + target carries both shapes;
- neither carries neither;
- existing hero halo and layer hierarchy remain unchanged.

Expected Red: there is no selected/outline shape grammar; a second rectangle or
hue-only implementation fails.

`test/game/dungeon_scene_test.dart`:

- snapshot passes badge/selected/target facts and uses selected actor position
  as focus;
- pan-only `withViewport` preserves the exact cells while retaining selected
  focus;
- identity notice or selection change forces projection synchronization while
  retaining the actor component object by stable render id;
- inspect the monster component children: semantic `g` main text and separate
  superscript badge text are both present; selected monster has a circle,
  target has a rectangle, and selected-target has both;
- clearing selection/badge removes only the relevant children, not the actor
  component;
- existing tap/pan/long-press and material-retention tests remain Green.

Expected Red: snapshot always focuses hero and reuse ignores identity/selection;
renderer has only the target rectangle and one glyph text.

Camera/widget proof (existing or a focused addition in
`battle_view_test.dart`): a distant selected actor makes the recenter button
visible; pressing it clears selection, keeps armed spell/log/game unchanged,
and makes the button disappear when the hero is on screen.

Do not add golden tests. The final current-phone-AVD session owns visual
placement/greyscale acceptance.

## Proof commands

From `packages/app`, after Green/refactor:

```sh
flutter test test/game/glyph_plan_test.dart \
  test/game/glyph_marks_test.dart test/game/dungeon_scene_test.dart \
  test/game/armed_targets_test.dart test/battle_view_test.dart
dart format lib/game/glyph_plan.dart lib/game/glyph_marks.dart \
  lib/game/dungeon_scene.dart lib/game/game_screen.dart \
  test/game/glyph_plan_test.dart test/game/glyph_marks_test.dart \
  test/game/dungeon_scene_test.dart test/game/armed_targets_test.dart \
  test/battle_view_test.dart
dart analyze lib/game/glyph_plan.dart
dart analyze lib/game/glyph_marks.dart
dart analyze lib/game/dungeon_scene.dart
dart analyze lib/game/game_screen.dart
dart analyze test/game/glyph_plan_test.dart
dart analyze test/game/glyph_marks_test.dart
dart analyze test/game/dungeon_scene_test.dart
dart analyze test/game/armed_targets_test.dart
dart analyze test/battle_view_test.dart
```

If `battle_view_test.dart` was not touched, omit it from format/analyze but keep
it in the focused regression test command. Re-run focused tests after any
format/static correction. Do not run full suite/analyzer.

## Executor discretion

Exact badge font size/offset and outline stroke widths/insets are local choices.
Choose restrained values that keep `g`, superscript, circle, and square legible
together at `cameraCellSize`; use the actor's existing ink/value contrast. Child
helper names are discretionary. Public projection fields, square/circle
semantics, stable component identity, and no-loop rule are locked.

## Escalate when

- task 01 interfaces differ materially from `PLAN.md`;
- selected focus would reveal an actor not both visible and known;
- a badge requires replacing semantic glyph text or render identity;
- Flame cannot show circle and square simultaneously on one retained component;
- projection reuse cannot distinguish pan-only from identity/selection change
  without a new scheduler/loop;
- the actual phone-scale mark cannot plausibly fit the glyph and badge (report
  dimensions; do not remove either identity or shape contract).

## Handoff state

Task 02 is complete only when projection and retained rendering are focused-
Green, selected focus/recenter geometry is proven, semantic glyphs remain raw,
and no timeline/stage production path has changed. Task 03 consumes these map
facts and task 01's typed queue from repository state.
