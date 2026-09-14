# Task 02 — Scene long-press input

Owner: sole sequential owner, non-isolated checkout `residuum-visual-reboot-3`.

## Scope

`packages/app/lib/game/dungeon_scene.dart` and its test
`packages/app/test/game/dungeon_scene_test.dart`. No screen/widget changes yet.

## Change

- `DungeonSceneHost` gains `required this.onLongPress` of type
  `ValueChanged<Position>`, threaded to `_DungeonScene`.
- `_DungeonScene` adds `LongPressCallbacks` to its mixins (alongside
  `TapCallbacks, DragCallbacks`) and implements
  `onLongPressStart(LongPressStartEvent event)`: convert
  `event.canvasPosition` through `_geometry.positionAt(...)` and call
  `_onLongPress(position)` when non-null.
- Keep `onTapUp`/`onDragUpdate` exactly as they are. The long-press callback is
  additive and does not disturb tap/drag dispatch (Flame recognizes each
  gesture independently).
- Store `_onLongPress` like `_onTap`/`_onPan`, updated in `synchronize(...)`.

## Proof (Red first)

In `dungeon_scene_test.dart`, add a widget test that pumps a real
`DungeonSceneHost` with a captured `onLongPress` and asserts the callback fires
with the correct `Position` after a long-press gesture over a tile, and that a
normal tap still fires `onTap` (regression for the shared gesture surface).

Existing scene tests must still pass after the host signature change; update
their constructor call sites with `onLongPress:`.

## Escalate when

- Flame's `LongPressCallbacks` and `DragCallbacks` cannot coexist on the same
  component (gesture collision) in a way the executor cannot resolve by
  confirming which gesture wins a stationary hold. If a long-press also triggers
  a drag, report the exact observed behavior and stop this task clean.

## Verification ownership

- Focused proof: `flutter test test/game/dungeon_scene_test.dart` from
  `packages/app`.
- Formatter: `dart format` on `dungeon_scene.dart` + its test.
- Focused static: `flutter analyze` from `packages/app`, fix only touched files.
- Main-owned gates: full `flutter test`, final `flutter analyze`, AVD/greyscale
  acceptance — after all tasks land.
