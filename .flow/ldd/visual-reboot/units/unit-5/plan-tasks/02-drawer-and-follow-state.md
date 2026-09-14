# Task 02 — Drawer extent, follow state, and the unread count

Owner: second fresh sequential executor in the Unit 5 feature checkout, in the
same non-isolated checkout task 01 left green. Read `../PLAN.md`,
`../CONTRACT.md`, and `01-log-line-and-categories.md` first.

## Expected starting repository condition

Task 01 is landed and green: `packages/app/lib/game/log_line.dart` exists with
`LogCategory` and `LogLine`, `describeEvent` returns `LogLine?`,
`GameViewState.log` is `List<LogLine>`, `roadOpeningLog` and `bottomOfTheDelve`
are `const LogLine`, and `test/support/log_sentences.dart` exists.
`packages/app/lib/game/log_drawer.dart` does not exist and
`game_screen.dart:121` still renders `_MessageLog` after `_Controls`.

This task is bloc-only. No widget file changes, so nothing you write here is
visible on screen yet; that is correct and intended. Task 03 consumes the
interfaces you land.

If `packages/app` carries changes you did not make, treat them as user-owned:
do not reset, stash, or discard them; report and stop.

## Scope

Touch only:

- `packages/app/lib/game/log_line.dart` — add `LogDrawerExtent` and nothing
  else;
- `packages/app/lib/game/game_bloc.dart`;
- add `packages/app/test/game/log_drawer_state_test.dart`;
- `packages/app/test/game_bloc_test.dart` if an existing assertion needs the new
  carried fields named.

Do not touch `game_screen.dart`, `main.dart`, `event_messages.dart`,
`packages/core`, `packages/content`, or any save file. Do not add a
`ScrollController`, a widget, a key, or an animation.

## Locked implementation

### `LogDrawerExtent`

In `lib/game/log_line.dart`, beside `LogCategory`:

```dart
/// How much of the message log the drawer is showing.
enum LogDrawerExtent { peek, half, full }
```

It lives here rather than in a widget file because `game_bloc.dart` carries it
and must not import Flutter chrome to do so.

### `GameViewState`

Add three fields and normalize them in the initializer list, exactly:

```dart
GameViewState({
  required this.game,
  required this.log,
  this.autoPath = const [],
  this.walkId = 0,
  this.pan = Offset.zero,
  this.hasFled = false,
  this.armedSpellId,
  ActorIdentityContext? actorIdentity,
  this.selectedActorId,
  LogDrawerExtent logDrawerExtent = LogDrawerExtent.peek,
  bool logFollowing = true,
  int logUnread = 0,
}) : actorIdentity = actorIdentity ?? ActorIdentityContext.fromGame(game),
     logDrawerExtent = game.isGameOver ? LogDrawerExtent.peek : logDrawerExtent,
     logFollowing = _followsAt(game, logDrawerExtent, logFollowing),
     logUnread = _followsAt(game, logDrawerExtent, logFollowing) ? 0 : logUnread;

static bool _followsAt(
  GameState game,
  LogDrawerExtent extent,
  bool following,
) => following || game.isGameOver || extent == LogDrawerExtent.peek;

final LogDrawerExtent logDrawerExtent;
final bool logFollowing;
final int logUnread;
```

Three invariants therefore hold by construction and cannot be forgotten by a
handler, which is this file's documented convention for `pan` (`:181-188`):
game-over collapses to `peek`; game-over and `peek` both imply follow is on; and
following implies zero unread. Dartdoc each of the three fields with the rule it
carries. No comments in bodies.

### Carrying the fields through every transition

**Every** `GameViewState(...)` construction inside `GameBloc` must name
`logDrawerExtent`, `logFollowing` and `logUnread`. The view-only transitions at
`:603, 623, 638, 665, 728, 746, 766, 815, 918` carry all three unchanged.

The three append paths — `_act` (`:838`), `_onAutoWalkAdvanced` (`:888`),
`_afterAction` (`:907`) — deliberately drop `armedSpellId`, `pan` and
`selectedActorId` by not naming them. They must **not** drop these: a turn taken
with the drawer open does not close it. They carry
`logDrawerExtent: state.logDrawerExtent`, `logFollowing: state.logFollowing`, and
`logUnread: _unreadAfter(presentation.lines.length)`.

The two direct-append refusal sites use `_unreadAfter(1)`: the watched refusal
at `:623` and the system-back refusal at `:815`.

### The unread count

One private helper on `GameBloc`, and the only place the count is ever computed:

```dart
int _unreadAfter(int appended) =>
    state.logFollowing ? 0 : state.logUnread + appended;
```

`appended` is always the literal size of this transition's append. Never pass
`log.length`, never a difference of lengths, never a value re-derived from the
list. That is the whole defence against the count drifting into total history
length.

### The four events

Declared beside the existing `GameBlocEvent` subclasses and registered in the
constructor's `on<…>` block at `:545-564`:

```dart
final class LogDrawerHandlePulled extends GameBlocEvent {
  const LogDrawerHandlePulled();
}

final class LogDrawerClosed extends GameBlocEvent {
  const LogDrawerClosed();
}

final class LogFollowBroken extends GameBlocEvent {
  const LogFollowBroken();
}

final class LogFollowResumed extends GameBlocEvent {
  const LogFollowResumed();
}
```

Handlers, all view-only. Each emits a state carrying `game`, the identical `log`
list instance, `autoPath`, `walkId`, **`pan`**, `armedSpellId`, `hasFled`,
`actorIdentity`, and `selectedActorId` unchanged:

- `_onLogDrawerHandlePulled` — returns without emitting when
  `state.game.isGameOver`. Otherwise the extent advances
  `peek → half → full → peek`, and `logFollowing`/`logUnread` are passed through
  unchanged; the constructor invariant is what resumes follow and clears the
  count when the new extent is `peek`. Do not special-case that in the handler.
- `_onLogDrawerClosed` — emits nothing when the extent is already `peek`;
  otherwise emits with `logDrawerExtent: LogDrawerExtent.peek`, again passing
  follow state through.
- `_onLogFollowBroken` — emits nothing when `!state.logFollowing`; otherwise
  emits with `logFollowing: false`.
- `_onLogFollowResumed` — emits nothing when `state.logFollowing`; otherwise
  emits with `logFollowing: true`.

**`pan` is carried by all four and this is deliberate.** Criterion 7 names it,
and snapping the camera under an overlay the player just opened is a jump nobody
asked for. Note in the handler dartdoc that these join the pan, arm, recenter and
walk-bookkeeping handlers as the ones that change nothing about the game.

Emitting nothing on a no-op is required, not an optimization: the drawer's scroll
listener fires every frame of a drag and a re-emitted identical state would
rebuild the whole screen at scroll rate.

## Red/Green behavioral proof

Land the fields with the default values first, observe the transition tests fail
on wrong extents and counts, then make them pass. The Red must be wrong
behavior, not a missing symbol.

### `test/game/log_drawer_state_test.dart`

Bloc tests, `// arrange` / `// act` / `// assert`:

1. **Fresh state.** A new `GameBloc` is at `LogDrawerExtent.peek`, following, and
   `logUnread == 0`.
2. **The handle cycles.** Three `LogDrawerHandlePulled` events give
   `half`, `full`, `peek` in that order; a fourth gives `half` again.
3. **Close collapses from anywhere.** From `full`, `LogDrawerClosed` gives
   `peek`; a second `LogDrawerClosed` at `peek` emits nothing.
4. **A drawer interaction spends no turn and mutates nothing.** From a state
   with a non-zero `pan`, an armed spell, a selected actor, and a walk in
   progress, dispatch `LogDrawerHandlePulled`, then `LogFollowBroken`, then
   `LogDrawerClosed`, and assert on each emitted state: `game` is `same` as
   before, `log` is `same` as before, and `pan`, `autoPath`, `walkId`,
   `armedSpellId`, `selectedActorId` and the RNG-bearing `GameState` are all
   unchanged. This is criterion 7 and it is the test that fails if a handler
   forgets `pan`.
5. **Follow on: nothing accumulates.** At `half`, following, drive a
   `WaitPressed` step and assert `logUnread` is still `0` and the log grew by
   exactly the lines that turn produced.
6. **Follow off: the exact count.** At `half`, dispatch `LogFollowBroken`, then
   drive two separate stepping events that each append a known number of lines,
   and assert `logUnread` equals the sum of those two appends — not the log
   length, which the test asserts is strictly larger because the log was not
   empty when follow broke. This is the drift guard; seed the bloc with a
   non-empty log so the two numbers cannot coincide.
7. **Resuming clears.** `LogFollowResumed` sets `logFollowing` true and
   `logUnread` to `0`; a second `LogFollowResumed` emits nothing.
8. **Collapsing to peek resumes follow.** With follow broken and a non-zero
   count at `full`, `LogDrawerClosed` yields `peek`, following, count `0`. The
   same holds for the third `LogDrawerHandlePulled` that cycles back to `peek`.
9. **A turn does not close the drawer.** At `full` with follow broken, drive a
   step and assert the emitted state is still `full` and still not following.
10. **Death collapses and inerts.** With the drawer at `full` and follow broken,
    drive the step that kills the hero and assert the emitted state has
    `logDrawerExtent == LogDrawerExtent.peek`, `logFollowing == true`, and
    `logUnread == 0`. Then dispatch `LogDrawerHandlePulled` and assert **no**
    state is emitted, so the handle is inert. This is criterion 8's bloc half.
11. **The invariant is unconditional.** Construct a `GameViewState` directly with
    a game-over `GameState`, `logDrawerExtent: LogDrawerExtent.full`,
    `logFollowing: false`, `logUnread: 5`, and assert the constructed value is
    `peek`, following, `0`. A handler cannot be the only thing enforcing this.

Expected Red: with the fields present but no handlers, tests 2, 3, 7, 8 and 9
fail because nothing is emitted; with handlers but no `_unreadAfter` carry, test
6 fails on `0`; with append paths that drop the fields, test 9 fails at `peek`;
without the initializer-list normalization, tests 10 and 11 fail with `full`.

Do not write a test that only asserts a field was copied from one constructor
call to the next. Tests 4, 6, 9 and 10 observe invariants a consumer can see.

## Proof commands

From `packages/app`, after Green:

```sh
flutter test test/game/log_drawer_state_test.dart test/game_bloc_test.dart \
  test/game/dungeon_scene_test.dart test/game/armed_targets_test.dart \
  test/battle_view_test.dart
dart format lib/game/log_line.dart lib/game/game_bloc.dart \
  test/game/log_drawer_state_test.dart test/game_bloc_test.dart
dart analyze lib/game/log_line.dart
dart analyze lib/game/game_bloc.dart
dart analyze test/game/log_drawer_state_test.dart
```

Re-run the focused test command after any formatting or static correction. Do
not run the full suite or the whole-project analyzer; Main owns those after task
03.

## Executor discretion

The exact spelling of the boolean normalization (`following || …` versus a
conditional), the private helper name for the extent cycle, whether the four
handlers share a private "view-only rebuild" helper, and test fixture placement
are yours — provided the three invariants hold by construction, `pan` is carried,
the count only ever sees one append's size, and the four event class names and
their semantics are exactly as locked.

Do not introduce a `copyWith` on `GameViewState`: it would make the constructor
normalization bypassable and the drop-by-default convention meaningless.

## Escalate when

- some path genuinely needs a game-over state with an open drawer, or a `peek`
  state with follow off;
- an append path cannot report its own append size without reading `log.length`;
- carrying `pan` through a drawer handler breaks an existing Unit 3 camera
  contract in `game_bloc_test.dart` or `dungeon_scene_test.dart`;
- registering four new events collides with an existing handler name or ordering
  assumption in the `on<…>` block;
- a required proof needs a widget, a scroll controller, or a `core`/`content`/
  save change.

## Handoff state and completion receipt

Task 02 is complete only when `LogDrawerExtent` exists, `GameViewState` carries
and normalizes the three fields, all four events are registered and handled,
every append path uses `_unreadAfter`, the focused suites are green, and no
widget file has changed. Task 03 starts from these public interfaces —
`LogDrawerExtent`, `state.logDrawerExtent`, `state.logFollowing`,
`state.logUnread`, and the four event classes — not from your session memory.

Report to Main, in prose, at most eight lines:

- the focused test command run and its pass count;
- the Red you observed for the unread count and for the death invariant;
- confirmation that `pan` is carried by all four handlers and which test proves
  it;
- the files changed, and that no widget file moved;
- anything escalated or deliberately left for task 03.
