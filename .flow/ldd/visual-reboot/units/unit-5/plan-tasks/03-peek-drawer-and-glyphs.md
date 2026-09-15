# Task 03 — The peek above the controls, the drawer overlay, and the glyph column

Owner: third fresh sequential executor in the Unit 5 feature checkout, in the
same non-isolated checkout task 02 left green. Read `../PLAN.md`,
`../CONTRACT.md`, and `02-drawer-and-follow-state.md` first.

## Expected starting repository condition

Tasks 01 and 02 are landed and green:

- `packages/app/lib/game/log_line.dart` holds `LogCategory` (ten members, each
  with `mark` and `word`), `LogLine`, and `LogDrawerExtent`;
- `GameViewState` carries `logDrawerExtent`, `logFollowing`, `logUnread`,
  normalized in the initializer list so game-over collapses to `peek`;
- `GameBloc` registers and handles `LogDrawerHandlePulled`, `LogDrawerClosed`,
  `LogFollowBroken`, `LogFollowResumed`;
- `game_screen.dart` still renders the private `_MessageLog(log: state.log)`
  **after** `_Controls` at `:120-121`, and `packages/app/lib/game/log_drawer.dart`
  does not exist.

If `packages/app` carries changes you did not make, treat them as user-owned:
do not reset, stash, or discard them; report and stop.

## Scope

Touch only:

- add `packages/app/lib/game/log_drawer.dart`;
- update `packages/app/lib/game/game_screen.dart`;
- add `packages/app/test/widget/log_drawer_test.dart`;
- update `packages/app/test/game/dungeon_scene_test.dart` — one added case only.

Do not touch `game_bloc.dart`, `log_line.dart`, `event_messages.dart`,
`main.dart`, `packages/core`, `packages/content`, or any save file. Do not add
an animation controller, a `Draggable`/`DraggableScrollableSheet`, a gesture
that dispatches a game action, a tap-to-actor handler on a log row, an
`assets:` block, or any HUD change beyond moving the peek above the controls.

## Locked implementation

### `lib/game/log_drawer.dart`

Holds both widgets and their keys, in the shape `battle_view.dart` already uses
for `BattleDock`/`BattleShelf`. `game_screen.dart` is 935 lines and owns
composition, not chrome.

```dart
const logPeekKey = Key('log-peek');
const logHandleKey = Key('log-handle');
const logDrawerKey = Key('log-drawer');
const logCloseKey = Key('log-close');
const logUnreadKey = Key('log-unread');

class LogPeek extends StatelessWidget {
  const LogPeek({required this.state, required this.bloc, super.key});
  final GameViewState state;
  final GameBloc bloc;
}

class LogDrawer extends StatefulWidget {
  const LogDrawer({required this.state, required this.bloc, super.key});
  final GameViewState state;
  final GameBloc bloc;
}
```

#### `LogPeek`

Keyed `logPeekKey` at its `game_screen.dart` call site. The container keeps the
exact values `_MessageLog` has
today: `height: 104`, `width: double.infinity`, `color: Color(0xFF15181F)`,
`padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)`. Inside, a
`Column`:

1. a 12-logical-pixel row holding a centred 32×4 rounded pill in `0xFF8A919E` —
   the mock's drag handle;
2. `Expanded` holding the existing `reverse: true` `ListView.builder` unchanged:
   `fontFamily: 'monospace'`, `fontSize: 13`,
   `Color(index == 0 ? 0xFFE6EAF0 : 0xFF8A919E)`, rendering
   `state.log[state.log.length - 1 - index].sentence`.

The whole strip is the hit target: a `GestureDetector` with
`behavior: HitTestBehavior.opaque` and
`onTap: state.game.isGameOver ? null : () => bloc.add(const LogDrawerHandlePulled())`,
wrapped in
`Semantics(button: true, enabled: !state.game.isGameOver, label: 'Open the message log')`.

Total height stays exactly 104 so "fixed compact height" is preserved as a
number. The peek draws **no** glyph column: the mock's peek has none and the
contract puts glyphs in the expanded log only.

#### `LogDrawer`

Keyed `logDrawerKey` at its `game_screen.dart` call site:

```dart
Align(
  alignment: Alignment.bottomCenter,
  child: FractionallySizedBox(
    widthFactor: 1,
    heightFactor:
        widget.state.logDrawerExtent == LogDrawerExtent.full ? 1.0 : 0.45,
    child: ColoredBox(color: const Color(0xFF15181F), child: … ),
  ),
)
```

Do **not** reach for `Positioned.fill`: a `Positioned` must be a direct child of
a `Stack`, and `LogDrawer` returns its root rather than being one, so it would
throw. A non-positioned `Stack` child gets loose constraints, `Align` expands to
the bounded maximum, and `FractionallySizedBox` takes the full width and the
chosen fraction of the height anchored to the bottom. `_DeathOverlay`
(`game_screen.dart:714`) is the existing precedent.

`0.45` is the half fraction. Contents, in a `Column`, matching the mock's COMBAT
LOG panel:

1. a 20-logical-pixel handle row keyed `logHandleKey`: the same centred pill, in
   a `GestureDetector` with `behavior: HitTestBehavior.opaque` dispatching
   `LogDrawerHandlePulled`, wrapped in
   `Semantics(button: true, label: 'Resize the message log')`;
2. a title row: `Text('MESSAGE LOG')` in `0xFFE6EAF0` monospace, `Spacer()`, and
   `IconButton(key: logCloseKey, icon: const Icon(Icons.close), tooltip: 'Close the message log', onPressed: () => widget.bloc.add(const LogDrawerClosed()))`;
3. `Expanded` holding a `Stack`: the list, plus — only when
   `!widget.state.logFollowing && widget.state.logUnread > 0` — a
   `Positioned(right: 12, bottom: 12, child: FilledButton(key: logUnreadKey, …))`
   whose child is `Text('↓ ${widget.state.logUnread} new')`. Its `onPressed`
   dispatches `LogFollowResumed` and jumps the controller to `maxScrollExtent`.
   It shows the number; never a dot.

**The list is oldest-first and not reversed**, unlike the peek. This is what
makes "new lines accumulate without yanking the viewport" true: items lay out
from offset zero, so an append lands beyond the far edge and every offset the
reader is parked at keeps showing the same words. A `reverse: true` list anchors
the newest end at offset zero, so each append would push the reader's content
away by the height of the new line. Do not reverse it.

Each row:

```dart
Semantics(
  label: '${line.category.word}. ${line.sentence}',
  child: ExcludeSemantics(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 20, child: Text(line.category.mark, style: rowStyle)),
        Expanded(child: Text(line.sentence, style: rowStyle)),
      ],
    ),
  ),
)
```

`rowStyle` is `fontFamily: 'monospace'`, `fontSize: 13`,
`Color(index == state.log.length - 1 ? 0xFFE6EAF0 : 0xFF8A919E)`. The mark takes
its row's colour, so hue carries nothing and the newest/older value contrast the
peek has always used survives into the drawer.

#### Follow, owned by the widget's scroll position only

`LogDrawer` holds one `ScrollController`. `static const double _followTolerance = 8;`

- "at the newest entry" is
  `position.maxScrollExtent - position.pixels <= _followTolerance`;
- on a scroll leaving that window while `widget.state.logFollowing` is true,
  dispatch `LogFollowBroken`; on one re-entering it while `logFollowing` is
  false, dispatch `LogFollowResumed`. Criterion 6 is therefore the same code
  path as the `↓ N new` affordance, not a second one;
- after any build in which `widget.state.logFollowing` is true **and** either the
  log length grew since the previous build or follow just turned on, a
  post-frame callback jumps to `maxScrollExtent`, guarded by
  `_controller.hasClients`;
- dispose the controller in `dispose`.

A log shorter than the viewport has `maxScrollExtent == 0` and `pixels == 0`, so
it is always "at newest", follow never breaks, and the jump is a no-op. Do not
add an `isEmpty` special case; the arithmetic already covers it.

### `game_screen.dart`

- delete `_MessageLog` entirely; import `log_drawer.dart`;
- add `const controlsKey = Key('crawl-controls');` beside `recenterKey`,
  `shelfKey`, `overflowKey`, `shelfWaitKey` at `:17-20`;
- replace `:120-121` so the peek precedes the controls:

```dart
LogPeek(key: logPeekKey, state: state, bloc: bloc),
_Controls(key: controlsKey, state: state),
```

- add the drawer as a `Stack` child **between** the `Column` and
  `_DeathOverlay`:

```dart
if (state.logDrawerExtent != LogDrawerExtent.peek)
  LogDrawer(key: logDrawerKey, state: state, bloc: bloc),
if (state.game.isGameOver) _DeathOverlay(state: state),
```

`_Controls` does **not** accept a key today: its constructor at `:371` is
`const _Controls({required this.state});`. Widen it to
`const _Controls({required this.state, super.key});` — that one parameter is
the whole change to the class, and it exists so the peek-above-controls order
is assertable from a widget test.

The `Column` must not change shape when the drawer opens. That is the whole of
criterion 3: collapsing restores the pre-expansion composition because there was
nothing to restore, and the Flame scene is untouched because `Expanded` and
`DungeonSceneHost` keep their position in the tree and
`_DungeonSceneHostState._reusesProjection` (`dungeon_scene.dart:165-170`) does
not read any field the drawer changes.

## Red/Green behavioral proof

Write the tests first. Adding the keys before the reorder gives a genuine Red:
the order assertion fails against the current tree because the peek is below the
controls.

### `test/widget/log_drawer_test.dart`

Pump the real `GameScreen` over a real `GameBloc`, following
`test/battle_view_test.dart:105-130`'s `_pushGame` shape (`MaterialApp` →
`TextButton` → pushed `MultiBlocProvider` with `TownBloc` and `GameBloc`), and
size the surface with `onAPhone(tester)` from `test/support/phone.dart`.

1. **The peek is above the controls.**
   `tester.getTopLeft(find.byKey(logPeekKey)).dy <
   tester.getTopLeft(find.byKey(controlsKey)).dy`, at phone size, with a
   non-empty seeded log. Expected Red against the pre-reorder tree.
2. **The handle drives three states.** Capture
   `tester.getRect(find.byKey(dungeonSceneSlotKey))` and
   `tester.getRect(find.byKey(logPeekKey))` before expanding. Tap
   `logPeekKey` → `logDrawerKey` is found; tap `logHandleKey` → still found and
   its height has grown; tap `logHandleKey` again → `logDrawerKey` is gone.
   Assert both captured rects are identical at every step, which proves the
   overlay never reflowed the map and that collapse restored the exact
   composition. Criteria 3 and part of 7.
3. **The close affordance collapses from full.** Reach `full`, tap
   `logCloseKey`, assert `logDrawerKey` is gone and `logPeekKey` is present.
4. **The glyph column and its words.** Seed the bloc with one `LogLine` per
   `LogCategory` member, open to `full`, and assert for every member that
   `find.text(member.mark)` finds it and `find.bySemanticsLabel` matching
   `'${member.word}. '` finds its row. Also assert the peek shows **no** mark:
   `find.text(LogCategory.struck.mark)` is absent while collapsed.
5. **Newest/older contrast in the drawer.** With at least two seeded lines, read
   the `Text` widgets' styles and assert the last line's colour is `0xFFE6EAF0`
   and an earlier one's is `0xFF8A919E`, and that each row's mark shares its
   sentence's colour.
6. **Follow held at newest.** With a seeded log long enough to scroll, open to
   `half`, drive `bloc.add(const WaitPressed())`, pump, and assert `logUnreadKey`
   is absent and the new sentence is visible.
7. **Follow broken, the count exact, the viewport still.** Drag
   `find.byKey(logDrawerKey)` downward far enough to leave the newest end,
   pump, record `tester.getTopLeft` of a visible sentence, drive two stepping
   events, pump, and assert: that sentence has not moved, `logUnreadKey` is
   present, and its text is `↓ N new` where `N` is exactly the number of lines
   those two steps appended — computed from the log length delta the test itself
   measured, not hard-coded. Criterion 5.
8. **The affordance returns and resumes.** Tap `logUnreadKey`, pump, assert it
   is gone and the newest sentence is visible.
9. **Scrolling back resumes without the affordance.** Break follow, drive a
   step, then drag back to the newest end and assert `logUnreadKey` disappears
   without having been tapped. Criterion 6.
10. **Empty and one-line logs.** Pump a `GameBloc` with an empty log and one with
    `log: const [roadOpeningLog]`, open each to `half` and to `full`, and assert
    `tester.takeException()` is null at every step and that the handle and the
    panel are present in both. Criterion 9.
11. **Death collapses and the overlay works.** With the drawer at `full`, drive
    the step that kills the hero, pump, and assert `logDrawerKey` is gone,
    `logPeekKey` is present, tapping `logPeekKey` does not bring the drawer back,
    and the `_DeathOverlay` button (`find.text('Return to town')`, or
    `'Wake at home'` in an encounter) is present and can be tapped without a
    hit-test error. Criterion 8.

### `test/game/dungeon_scene_test.dart`

Add exactly one case to the existing host group: rebuild `DungeonSceneHost` with
a `GameViewState` that differs **only** in `logDrawerExtent`, and assert the
Flame `GameWidget`'s game instance is `same` as before and the projected cell
identities are unchanged. That is the contract's "do not rebuild the Flame scene
on a drawer state change", proved at the seam rather than asserted in prose.

Do not add a golden-image test — AGENTS.md forbids them. Do not assert widget
source text or private class names.

## Proof commands

From `packages/app`, after Green:

```sh
flutter test test/widget/log_drawer_test.dart test/game/dungeon_scene_test.dart \
  test/battle_view_test.dart test/widget/back_guard_test.dart \
  test/widget/world_screen_test.dart test/widget/hud_depth_test.dart \
  test/widget/disabled_controls_test.dart test/game_bloc_test.dart
dart format lib/game/log_drawer.dart lib/game/game_screen.dart \
  test/widget/log_drawer_test.dart test/game/dungeon_scene_test.dart
dart analyze lib/game/log_drawer.dart
dart analyze lib/game/game_screen.dart
dart analyze test/widget/log_drawer_test.dart
dart analyze test/game/dungeon_scene_test.dart
```

Re-run the focused test command after any formatting or static correction. Do
not run the full suite or the whole-project analyzer, and do not attempt device
or emulator evidence: criterion 12 is the architect's gate, run by Main after
this task lands.

## Executor discretion

Pill dimensions, header row spacing and font sizes other than the locked `13`,
the `IconButton` sizing, the private widget/helper names inside
`log_drawer.dart`, whether the scroll boundary is watched with
`controller.addListener` or a `NotificationListener<ScrollUpdateNotification>`,
and test fixture placement are yours — provided the locked `104`, `0.45`, `1.0`,
`8`, `0xFF15181F`, `0xFFE6EAF0`, `0xFF8A919E`, the five keys plus `controlsKey`,
the oldest-first drawer list, the reversed peek list, and the `Stack` order
(drawer before `_DeathOverlay`) are preserved.

## Escalate when

- the overlay cannot reach half or full without reflowing the `Column`, or the
  collapsed rects do not match the pre-expansion ones;
- `_reusesProjection` turns out to be sensitive to a field the drawer changes,
  so an extent change re-projects the Flame scene;
- an oldest-first list cannot hold a reader's offset across an append in a
  widget test;
- a locked mark renders as a missing glyph in the test font — report which one
  rather than silently substituting;
- `_DeathOverlay`'s scrim does not absorb a tap aimed at collapsed drawer chrome,
  or its button cannot be tapped with the peek present;
- the `↓ N new` count observed on screen differs from the log-length delta the
  test measured;
- making a proof pass would need a `game_bloc.dart`, `log_line.dart`, `core`,
  `content`, or save change.

## Handoff state and completion receipt

Task 03 is complete only when `log_drawer.dart` exists with `LogPeek` and
`LogDrawer`, `_MessageLog` is deleted, the peek renders above the controls, the
drawer is a `Stack` child before `_DeathOverlay`, the focused suites are green,
and no file outside `packages/app` has changed. Unit 5's implementation is then
whole and Main owns the final gates.

Report to Main, in prose, at most eight lines:

- the focused test command run and its pass count;
- the Red you observed for the peek order and for the follow count;
- the measured `↓ N new` value and the log-length delta it was checked against;
- whether every locked mark rendered in the test font, and any you had to
  report;
- the files changed, and confirmation that nothing outside `packages/app` moved;
- anything escalated.
