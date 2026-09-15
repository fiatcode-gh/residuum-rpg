# Task 04 — Heroes

Owner: a fresh `flow-plan-executor` on the Unit 7 feature checkout after task 03
is green. Read `../PLAN.md`, `../CONTRACT.md` and
`01-town-grammar-and-shell.md` before editing. You have no conversation history
and need none.

## Expected starting repository condition

Tasks 01–03 have landed:

- `town_style.dart` exports `markColumn`, `placeName`, `roomName` and `Commit`;
  `Purse` is a ruled block; `TownRoom` renders its title in the body and its
  `AppBar` has no title; `MaterialsPanel` no longer exists;
- `roster_screen.dart` already uses `Commit(label: 'New hero', …)` and is
  otherwise untouched;
- the town shell and all six rooms are rebooted and green.

Before editing, inspect branch and `git status`, and read task 03's completion
receipt. If `Commit` or `TownRoom` do not match the plan, or a planned file has
unexplained changes, stop and report the contradiction. Preserve architect-owned
uncommitted `.flow` files.

## Behavioural slice and scope

This task reboots the Heroes roster onto the town grammar and makes each hero's
facts attributable to that hero's own row. Heroes stays a `WorldScreen` action;
its entry point is Unit 8's work and is not touched here. Every navigation
answer, dialog, warning sentence and fallback behaves exactly as it does today.

Touch only:

- `packages/app/lib/town/roster_screen.dart`;
- `packages/app/test/widget/roster_screen_test.dart` (extend only).

Do not edit `town_style.dart`, `town_screen.dart`, any room,
`world_screen.dart`, `world_bloc.dart`, `main.dart`, `town_bloc.dart`,
`lib/save/**`, `lib/notice/**`, `lib/game/**`, `packages/core`,
`packages/content`, dependency files, or LDD authority. Do not edit
`roster_refusal_test.dart` or `roster_session_test.dart`: they are your unchanged
regression gate for the session rebuild.

## Locked implementation

### What is frozen

Everything below survives verbatim. This screen's behaviour is the contract; only
its composition is yours.

- The sealed `RosterChoice` hierarchy — `PlayHero(id)`, `MakeHero(label,
  {replacing})`, `DropHero(id)` — with its current fields, value equality,
  `hashCode` and `toString`. `main.dart` pattern-matches it. No case is added,
  renamed, or given a field.
- `RosterScreen`'s constructor: `const RosterScreen({required this.document,
  this.notice, super.key})`. It reads the live `SaveDocument`; it does not gain a
  bloc, a provider, a controller, or a `State`.
- The answer protocol: every choice is `Navigator.of(context).pop(<choice>)` from
  this screen, never a callback handed in, because each answer rebuilds the whole
  bloc tree and the screen must be off the stack first.
- Hero iteration is `document.heroes.keys` in map order. `playing` is
  `id == document.active`. The played hero's row has `onPlay == null`, so tapping
  it answers nothing.
- `rosterLine(SavedHero)` — its five clauses, its ` · ` join, `_visits`'s three
  cases, and `below (depth n)` / `in town`. `roster_screen_test.dart:277-326`
  pins the exact strings. It stays a public top-level function in this file.
- `_confirmDelete`: the title `Delete ${hero.label}?`, the composed warning from
  `_deletionWarning` with all four of its clauses including the living-crawl
  clause and `A new hero begins in a new world.` for the last hero, the actions
  `Keep this hero` and `Delete this hero`, the `context.mounted` guard, the flow
  into `_create(context, replacing: id)` when this is the last hero, and
  `pop(DropHero(id))` otherwise.
- `_create`: `heroLabelFor(document.heroes.length)` as the offered label, the
  `_NameDialog` prefilled with it, `Not yet` answering nothing, `Begin` answering
  the trimmed text, and a blank trimmed answer falling back to the offered label.
- `_NameDialog`: its title `Name your hero`, its autofocused `TextField` in
  `mono`, its `OutlineInputBorder`, its controller disposal, and both action
  words.

**The word `crawl` must not appear anywhere on a roster row.**
`roster_screen_test.dart:181` asserts `find.textContaining('crawl')` finds
nothing while a town-standing hero's delete dialog is open, and the rows behind a
dialog stay in the finder's scope.

### What changes

`RosterScreen.build` becomes `TownRoom(title: 'Heroes')` with children, in this
exact order:

1. `Notice(notice)`
2. one `_HeroRow` per `document.heroes` entry, each with
   `key: Key('roster-hero-$id')`
3. `Divider(color: rule, height: 1)` closing the list
4. `SizedBox(height: 12)`
5. `Commit(label: 'New hero', onPressed: () => _create(context))`

`_HeroRow` gains the row key and a leading `Divider(color: rule, height: 1)`, so
the roster reads as the same ruled list as the town's doors and the bench. Its
body keeps its shape:

- an `Expanded` `InkWell(onTap: onPlay)` — keep `InkWell`, so
  `tester.tap(find.text('<label>'))` still hits the play affordance and a null
  `onTap` still answers nothing;
- inside it, `Text(hero.label, style: mono)`, then `const Text('playing', style:
  monoDim)` separated by a `SizedBox(width: 10)` when and only when `playing`,
  then `SizedBox(height: 2)` and `Text(rosterLine(hero), style: monoDim)`;
- a trailing `SizedBox(width: 88)` holding the delete control.

The delete control changes from a `FilledButton` to a `TextButton` whose child is
`Text('Delete', maxLines: 1, style: TextStyle(fontFamily: 'monospace', fontSize:
12))`, still calling `onDelete`. One filled slab per hero row is the heavy
uniform furniture this unit replaces, and deletion is the row's secondary action:
the row's primary action is playing that hero. The control text stays exactly
`Delete` — `roster_screen_test.dart` taps `find.text('Delete').first` and
`.last`, and `roster_session_test.dart` depends on the same word.

`playing` stays a word beside the label, never a colour, a badge, or a mark. Who
is playing is read from the word and from the row's position; nothing new carries
it.

Update the class dartdoc to describe the screen as it now is, keeping its
existing reasoning about reading the save document rather than a bloc, about
popping a value rather than calling back, and about nothing being told apart by
colour. Dartdoc only — never a comment inside a function body.

## Red/Green behavioural proof

Work test-first, extending `packages/app/test/widget/roster_screen_test.dart`.
Keep every existing test in it unchanged.

Establish behavioural Red:

1. Add a three-hero fixture and assert that the row keyed
   `roster-hero-<id>` for each hero contains that hero's label and that hero's
   exact `rosterLine`, and that the word `playing` is a descendant of the active
   hero's row and of no other row. Expected Red: no keyed row exists, so the
   facts cannot be attributed to a hero at all — today a test can only say both
   strings are somewhere on the screen.

Then cut the source over and finish the Green set:

2. **Row order follows the document.** Assert the three keyed rows appear in
   `document.heroes.keys` order.
3. **Each row's delete belongs to its own hero.** Tap the `Delete` control inside
   a specific keyed row and assert the dialog title is `Delete <that hero's
   label>?`. Do this for a hero who is not first, so a positional coincidence
   cannot pass it.
4. **The played hero's row still answers nothing.** Tap the active hero's label
   inside its keyed row and assert no choice was popped and the route did not
   close; then tap another hero's label and assert `PlayHero(<that id>)`.
5. **The notice renders.** Pump with a `notice` and assert its sentence is on
   screen above the first row.
6. **Nothing on a row says `crawl`.** With a hero standing in a suspended crawl,
   assert the row reads `below (depth n)` and that `find.textContaining('crawl')`
   finds nothing before any dialog is opened.

Every existing test in this file — the two-hero row reading, the switch, the
played-hero no-op, the refused delete, the confirmed delete, both dialog warning
cases, the last-hero flow into creation, the backed-out name, the prefilled name,
the blank-name fallback, and the three `rosterLine` unit tests — must pass
**without being edited**.

### Unchanged regression gate

`roster_refusal_test.dart`, `roster_session_test.dart`,
`world_screen_test.dart`, `town_shell_test.dart` and `boot_wiring_test.dart` must
pass without being edited. Between them they prove that a roster answer rebuilds
the session, that a refused disk write keeps the session and says so, that a
retry can still land, that deleting the played hero lands on the one left, that
the last hero deleted is replaced rather than removed, that leaving the roster
without choosing changes nothing, and that the roster is reached from the world
screen and not from the town. If one fails, behaviour moved: fix the source, not
the test.

Structure test bodies `// arrange` / `// act` / `// assert`. Use
`find.descendant(of: find.byKey(...), matching: ...)` for attribution. Do not
assert paddings, colours, pixel geometry, widget types beyond what an existing
test already does, or source text.

## Focused proof commands

From `packages/app`, after Green:

```sh
flutter test test/widget/roster_screen_test.dart \
  test/widget/roster_refusal_test.dart \
  test/widget/roster_session_test.dart \
  test/widget/world_screen_test.dart \
  test/widget/boot_wiring_test.dart \
  test/widget/town_shell_test.dart

dart format lib/town/roster_screen.dart test/widget/roster_screen_test.dart

dart analyze lib/town/roster_screen.dart
dart analyze test/widget/roster_screen_test.dart
```

Re-run the focused tests after formatting or any static correction. Do not run
the full suite, whole-package `flutter analyze`, a whole-tree formatter, an app
build, an emulator, or a device install. Main owns those gates and the device
evidence.

## Executor discretion

You may choose private helper names, local widget splitting inside this file,
spacing within the locked vocabulary, test fixture names and placement, and how
a test measures row order.

You may not change public class, constructor, function or key names; any
`RosterChoice` case; `rosterLine` or `_visits`; any dialog title, warning clause
or action word; the offered-label or blank-name fallback; the pop protocol; the
`Delete` control's text; the `playing` word; or the iteration order.

## Escalate when

- a preserved sentence or answer cannot be produced without changing
  `RosterChoice`, `main.dart`, or the save layer;
- keying the rows changes what an existing finder matches;
- the last-hero replacement write or the living-crawl warning cannot be preserved
  as written;
- a row cannot show label, `playing`, `rosterLine` and `Delete` on a phone
  without hiding one of them;
- the screen seems to need a new mark codepoint, a hue distinction, or an asset;
- an unedited regression suite fails for a reason other than a composition it
  pinned;
- any required fix would cross into another unit's files.

## Handoff state and completion receipt

Task 04 is complete when Heroes renders inside the rebooted town grammar as a
ruled, keyed roster, every hero's facts are attributable to that hero's row, the
`playing` word marks only the active hero, switching, creation, the prefilled
name, the blank fallback, the confirmed delete, the living-crawl warning and the
never-empty replacement all behave exactly as before, the new assertions are
green, and every named regression suite passes unchanged.

This is the last implementation task in Unit 7. The tree is not accepted until
Main runs the broad gates, the integrated acceptance review against
`CONTRACT.md`, and the normal-colour and greyscale phone session described in
`../PLAN.md`.

Report to Main in at most eight prose lines:

- the behavioural Red observed for unattributable hero facts;
- the focused test command and pass count;
- the per-hero attribution, row order and per-row delete results;
- confirmation that the pop protocol, both delete paths and the name fallback
  are unchanged and proved by unedited tests;
- confirmation that no roster text says `crawl` and that `playing` is a word;
- files changed, and confirmation no forbidden path changed;
- formatter and analyzer commands and results;
- any escalation, plus the residual items Main still owes: the 600-pixel door
  reachability, the bench-versus-materials column alignment, and the confirmation
  that Unit 7 introduced no new mark codepoint, all on device.
