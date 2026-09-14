# Task 01 — `LogLine`, the category set, and the `List<String>` cutover

Owner: first fresh sequential executor in the Unit 5 feature checkout. Read
`../PLAN.md`, `../CONTRACT.md`, and `../recon.md` first. Planning artifacts do
not authorize anything beyond this brief.

## Expected starting repository condition

App source equivalent to `864aa6e` (`main`, Unit 4 merged), on a Unit 5 feature
branch — normally `residuum-visual-reboot-5` — never on `main`. No task 02 or 03
change is present: `packages/app/lib/game/log_line.dart` and
`packages/app/lib/game/log_drawer.dart` do not exist, `GameViewState` has no
`logDrawerExtent`/`logFollowing`/`logUnread`, and `game_screen.dart:121` still
renders `_MessageLog(log: state.log)` after `_Controls`.

If `packages/app` is dirty when you start, treat those changes as user-owned:
do not reset, stash, or discard them; report and stop.

## Scope

Touch only:

- add `packages/app/lib/game/log_line.dart`;
- update `packages/app/lib/game/event_messages.dart`;
- update `packages/app/lib/game/game_bloc.dart`;
- update `packages/app/lib/game/game_screen.dart` — **one line inside
  `_MessageLog` only**;
- update `packages/app/lib/main.dart`;
- add `packages/app/test/support/log_sentences.dart`;
- add `packages/app/test/game/log_line_test.dart`;
- update `packages/app/test/game_bloc_test.dart`,
  `packages/app/test/battle_view_test.dart`,
  `packages/app/test/game/engine_boundary_test.dart`,
  `packages/app/test/widget/back_guard_test.dart`,
  `packages/app/test/widget/world_screen_test.dart`,
  `packages/app/test/widget/boot_wiring_test.dart`.

Do not touch `packages/core`, `packages/content`, any save/autosaver file,
`lib/world/world_bloc.dart` (its `List<String> log` is a different log), the
`Column` order in `game_screen.dart`, or `.omp/`. Do not add drawer state, the
drawer widget, follow state, keys, or glyph rendering — tasks 02 and 03 own
those.

## Locked implementation

### `lib/game/log_line.dart`

Its only import is `package:equatable/equatable.dart`. Implement exactly the
`LogCategory` enum (ten members, each with its `mark` and `word`) and the
`final class LogLine extends Equatable` from `PLAN.md` decision 1 — positional
constructor `const LogLine(this.sentence, this.category)`, fields `sentence` and
`category`, `props => [sentence, category]`. Dartdoc the enum, its two fields,
and the class; no comments in bodies.

Add nothing else: no actor id, severity, timestamp, `copyWith`, factory,
serialization, or category-from-text helper. `LogDrawerExtent` belongs to task
02 and must not appear yet.

### `event_messages.dart`

`describeEvent` keeps its name, parameters, and single exhaustive switch, and
changes its return type to `LogLine?`. Every sentence-producing arm becomes
`LogLine('…', LogCategory.x)` using the assignments in `PLAN.md` decision 2's
34-row table. The three `null` arms (`ActorMoved()`, `MoveBlocked()`,
`GameOver()`) stay `null`. Update the function's dartdoc to say it returns the
line and the kind it is.

Do not add a `categoryOf` function, a second switch, a default arm, or a
category lookup keyed by sentence.

### `game_bloc.dart`

- `GameViewState.log` becomes `final List<LogLine> log;`; the constructor
  parameter keeps its name.
- `GameBloc({List<LogLine> log = const []})`.
- `_describe` → `List<LogLine>`; `_ambushBeat` → `LogLine?`; `_beats` →
  `Iterable<LogLine>`; `_presentStep` → `({List<LogLine> lines, ActorIdentityContext identity})`.
- `_ambushBeat`'s sentence becomes `LogLine('… gets the drop on you.', LogCategory.struck)`.
- `_beats`' boss line becomes `LogCategory.died`; its bottom-of-the-delve entry
  appends the `bottomOfTheDelve` constant.
- `_watchedRefusal`, `_backRefusal`, `_roadBackRefusal` become
  `const LogLine(..., LogCategory.refused)`; `roadOpeningLog` becomes
  `const LogLine(..., LogCategory.noticed)`; `bottomOfTheDelve` becomes
  `const LogLine(..., LogCategory.moved)`. The sentence text of all five is
  byte-identical to today's. No `String` twin of any of them remains.
- Every existing `log: state.log` and `log: [...state.log, x]` site keeps its
  shape; only the element type changes.

### `game_screen.dart`

`_MessageLog`'s field becomes `final List<LogLine> log;` and its `itemBuilder`
renders `log[log.length - 1 - index].sentence`. Everything else about the
widget — the 104 height, the colours, the padding, `reverse: true`, and its
position after `_Controls` — is unchanged in this task.

### `main.dart`

`_openingLog()` → `List<LogLine>`; `_asSentence(String notice)` → `LogLine`
returning `LogLine('…', LogCategory.reported)`; `_resumed` →
`static const LogLine _resumed = LogLine('The crawl resumes.', LogCategory.reported)`.

Both are `reported` and neither is `refused` or `moved`. `SaveNotice` is a
channel, not a verdict — `LoadNotice` is "What booting found, **or failed to
find**, on disk" (`lib/notice/notice.dart:25`) and `SentenceNotice` carries the
forge's level-up announcements (`:63-69`) — so `✕ refused` would mark a neutral
find or an outright gain with the set's most negative glyph, and the call site
cannot tell which variant it holds. "The crawl resumes." is not a step, a stand,
a depth, or a road left behind, so `⇅ moved` would assert a spatial event that
did not happen on the first line every resumed crawl shows; `_openingLog`'s own
dartdoc says it (`main.dart:613`): "The notice is a fact about the launch, not
about this crawl."

The `_openCrawl` dartdoc at `:572` about the log being view state that does not
survive a suspend stays true and stays written; do not reword it. No save
document, save version, or autosaver field changes.

### `test/support/log_sentences.dart`

```dart
import 'package:residuum_app/game/game_bloc.dart';

List<String> logSentences(GameViewState state) => [
  for (final line in state.log) line.sentence,
];
```

This is test-only. Do not add an equivalent getter, extension, or accessor
anywhere under `lib/`.

## Red/Green behavioral proof

Write the tests first. For a brand-new type the first failure is unavoidably a
compile error; that is not the Red this task needs. Land the type and the
signature change with **every arm returning `LogCategory.moved`**, observe the
category assertions fail on wrong values, then make them pass. Record that the
Red you observed was wrong categories, not a missing symbol.

### `test/game/log_line_test.dart`

Pure tests over `describeEvent` and `LogCategory`, `// arrange` / `// act` /
`// assert` bodies:

1. **Direction is read from the variant, not the words.** `AttackHit` with
   `attackerId: heroId` is `LogCategory.hit`; the same event with a monster
   attacker is `LogCategory.struck`; `AttackDodged` is `LogCategory.struck`.
   Assert the sentences are unchanged in the same expectation, so a category fix
   that reworded a sentence fails here.
2. **Refusal is distinguished from movement.** `ActorMoved` on the hero is
   `moved` while `MoveBlocked` on the hero is `refused`; `Descended` and
   `Ascended` are `moved`; `InventoryFull` and `ActionRefused` are `refused`.
3. **The event mapping is total and no event-reachable member is dead.** Build
   one instance of every sentence-producing `GameEvent` variant listed in
   `PLAN.md` decision 2, map them through `describeEvent`, and assert the
   resulting category set is exactly
   `LogCategory.values.toSet()..remove(LogCategory.reported)` — spell the
   excluded member out rather than hard-coding nine, so adding an eleventh
   member fails this test. `reported` is app-injected only and is proved in
   `boot_wiring_test.dart` below; between the two assertions, every member of
   `LogCategory.values` is covered. This test fails the moment an event-side
   member goes dead, a new member arrives without an event mapping, or an event
   is quietly mapped to `reported`.
4. **The three silent variants stay silent.** `ActorMoved` for a monster,
   `MoveBlocked` for a monster, and `GameOver()` return `null`.
5. **Every category has a distinct mark and a distinct word.**
   `LogCategory.values.map((c) => c.mark).toSet()` and the same for `word` both
   have length `LogCategory.values.length`, and no `mark` or `word` is empty.

Expected Red: with all arms returning `moved`, tests 1–3 fail on category
values and test 5 fails until the enum carries ten distinct marks and words.

### `test/game_bloc_test.dart` additions

Alongside the migrated sentence assertions, add bloc-level proof that the
category reaches the state from the variant and from the call site:

- drive a monster attack on the hero and assert the resulting line's category is
  `LogCategory.struck` **and** its sentence is the existing
  `The ghoul claws you for 3.`;
- drive the hero's own kill and assert the `hit` line and the `died` line appear
  in that order with those categories;
- press the system back button in a crawl and in a road fight and assert the
  appended line is `refused` in both;
- tap a walkable tile with something in sight and assert the watched refusal is
  `refused`;
- construct `GameBloc(log: const [roadOpeningLog])` and assert the seeded line's
  category is `noticed` and the sentence is unchanged;
- drive an ambush step and assert the beat line's category is `struck` and that
  it still precedes the attack line it belongs to.

Do not assert that a field was copied, and do not assert source text.

### `test/widget/boot_wiring_test.dart` addition

`reported` is produced only by two private members of `_SessionState`, so no
pure or bloc test can reach it. Prove it through the real boot path instead. The
existing case `a document the hero is inside opens in the crawl` (`:50-70`)
already pumps the whole app with `PumpedApp` and asserts
`find.text('The crawl resumes.')`. Extend that case — do not add a second one —
to also read the live bloc and assert its log carries the exact value:

```dart
final crawl = BlocProvider.of<GameBloc>(
  tester.element(find.byType(GameScreen)),
);
expect(
  crawl.state.log,
  contains(const LogLine('The crawl resumes.', LogCategory.reported)),
);
```

`BlocProvider.of<GameBloc>(tester.element(find.byType(GameScreen)))` is the
lookup `test/widget/world_screen_test.dart:63-64` already uses, and `Equatable`
is what makes the value comparison work. Keep the existing
`find.text('The crawl resumes.')` expectation exactly as written: it is a
sentence assertion and the literal must not move.

Expected Red: with `_resumed` still carrying `LogCategory.moved`, this fails on
the category while the surrounding text assertion keeps passing — which is
precisely the defect it exists to catch.

### The migration itself

Rewrite only the sentence assertions, mechanically:

- `bloc.state.log` → `logSentences(bloc.state)` where the expectation is about
  strings;
- `.having((s) => s.log, 'log', …)` → `.having(logSentences, 'log', …)`;
- `s.log.where(...)`, `.last`, `.first`, `.join`, `.indexOf` over sentences →
  the same operation on `logSentences(s)`.

Leave untouched: every `log: const []`, `log: state.log`, `log: initial.log`,
`expect(x.log, same(y.log))`, `log.length`, and `log, isEmpty`. `const []`
infers `const <LogLine>[]` from the parameter type and needs no annotation.
`test/game_bloc_test.dart:1226`'s `expect(bloc.state.log.last, bottomOfTheDelve)`
stays as written: `bottomOfTheDelve` is now a `LogLine` and `Equatable` makes
the comparison work.

Do not touch `test/world_bloc_test.dart` — its eleven `.log` sites are
`WorldViewState.log` and are a different log. Do not touch
`test/game/dungeon_scene_test.dart` or `test/game/armed_targets_test.dart`:
their `.log` sites need no edit.

## Proof commands

From `packages/app`, after Green:

```sh
flutter test test/game/log_line_test.dart test/game_bloc_test.dart \
  test/battle_view_test.dart test/game/engine_boundary_test.dart \
  test/widget/back_guard_test.dart test/widget/world_screen_test.dart \
  test/widget/boot_wiring_test.dart \
  test/game/dungeon_scene_test.dart test/game/armed_targets_test.dart
dart format lib/game/log_line.dart lib/game/event_messages.dart \
  lib/game/game_bloc.dart lib/game/game_screen.dart lib/main.dart \
  test/support/log_sentences.dart test/game/log_line_test.dart \
  test/game_bloc_test.dart test/battle_view_test.dart \
  test/game/engine_boundary_test.dart test/widget/back_guard_test.dart \
  test/widget/world_screen_test.dart test/widget/boot_wiring_test.dart
dart analyze lib/game/log_line.dart
dart analyze lib/game/event_messages.dart
dart analyze lib/game/game_bloc.dart
dart analyze lib/game/game_screen.dart
dart analyze lib/main.dart
dart analyze test/game/log_line_test.dart
dart analyze test/support/log_sentences.dart
```

Then, from the repository root, the negative proof that no asserted sentence
changed:

```sh
for f in packages/app/test/game_bloc_test.dart \
         packages/app/test/battle_view_test.dart \
         packages/app/test/game/engine_boundary_test.dart \
         packages/app/test/widget/back_guard_test.dart \
         packages/app/test/widget/world_screen_test.dart \
         packages/app/test/widget/boot_wiring_test.dart; do
  diff <(git show 864aa6e:$f | grep -oE "'[^']*'" | sort) \
       <(grep -oE "'[^']*'" $f | sort) | grep '^<' && echo "LITERAL REMOVED IN $f"
done
```

Expected output: nothing at all. A `<` line is a literal that existed at
`864aa6e` and does not now; unless it is an import string you deliberately
moved, you have changed a sentence and the task is not green.

Re-run the focused test command after any formatting or static correction. Do
not run the full suite or the whole-project analyzer; Main owns those after task
03.

## Executor discretion

Private helper names, the order in which you land the switch arms, test fixture
placement inside the existing `game_bloc_test.dart` groups, and whether the
migrated `.having` uses a tear-off or a lambda are yours. Prefer the tear-off
`.having(logSentences, 'log', …)` for the shortest diff.

## Escalate when

- a `GameEvent` variant exists at the switch that `PLAN.md` decision 2 does not
  name, or a named one has disappeared;
- a category in decision 2 would be dishonest for the sentence its arm produces;
- an app injection site producing a log line is found beyond the nine in the
  decision-2 injection table;
- `AttackDodged` or `WardStruck` turns out to be emittable for an attacker that
  is the hero, contradicting `step.dart`'s `_defend`;
- the migration cannot be completed without editing a sentence literal, or the
  no-literal-removed check reports a removal you cannot justify;
- any required change reaches `packages/core`, `packages/content`, the save
  document, or the save version.

## Handoff state and completion receipt

Task 01 is complete only when `log_line.dart` exists, `describeEvent` returns
`LogLine?` from its one switch, no `List<String>` view of the game log survives
in `lib/`, the focused suites are green, and the no-literal-removed check is
silent. `game_screen.dart` still renders the peek after `_Controls` and the
drawer does not exist yet: task 02 starts from these public interfaces, not from
your session memory.

Report to Main, in prose, at most eight lines:

- the focused test command run and its pass count;
- the Red you observed and that it was wrong categories rather than a missing
  symbol;
- the output of the no-literal-removed check (expected: empty);
- the files changed, and confirmation that nothing outside `packages/app` moved;
- anything you escalated or deliberately left for task 02 or 03.
