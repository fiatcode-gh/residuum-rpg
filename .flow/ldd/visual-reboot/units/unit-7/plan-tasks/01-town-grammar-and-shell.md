# Task 01 — The town grammar and the town shell

Owner: first fresh `flow-plan-executor` on the Unit 7 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. You have no conversation
history and need none: everything this task depends on is in those two files and
in the repository.

## Expected starting repository condition

- A non-`main` feature checkout branched from `319d945` (house name
  `residuum-visual-reboot-7`), with `packages/` clean.
- `packages/app/lib/town/town_style.dart` still defines `MaterialsPanel` and a
  card-shaped `Purse`, and `TownRoom` still puts its title in an `AppBar`.
- `packages/app/lib/town/town_screen.dart` still shows the town name only in the
  `AppBar` and seven bare `FilledButton` doors with no purpose lines.
- `packages/app/test/widget/craft_rooms_test.dart` still contains the group
  `the town door column`.
- `.flow/**` may be dirty with architect-owned records. Do not touch, revert, or
  stash them.

Before editing, inspect branch and `git status`. If a planned file has
unexplained changes or the seams in `../PLAN.md` no longer match source, stop and
report the contradiction rather than improvising.

## Behavioural slice and scope

This task establishes the rebooted town presentation vocabulary and delivers its
first consumer: the town shell gets a typographic place header, a compact status
block, and seven destination rows that say what each door is for. It also
performs — and is the **only** task that may perform — the mechanical call-site
migrations its own removals force, so the tree is green and every other room
already sits on the new grammar before tasks 02–04 reboot their composition.

Touch only:

- rewrite `packages/app/lib/town/town_style.dart`;
- rewrite `packages/app/lib/town/town_screen.dart`;
- mechanical edits only, described exactly below, in
  `packages/app/lib/town/bank_screen.dart`,
  `packages/app/lib/town/inn_screen.dart`,
  `packages/app/lib/town/forge_screen.dart`,
  `packages/app/lib/town/alchemist_screen.dart`,
  `packages/app/lib/town/roster_screen.dart`;
- add `packages/app/test/widget/town_shell_test.dart`;
- remove the group `the town door column` from
  `packages/app/test/widget/craft_rooms_test.dart` and any import it alone
  needed.

Do not otherwise recompose any room; tasks 02–04 own that. Do not edit
`town_bloc.dart`, `world_screen.dart`, `main.dart`, `merchant_screen.dart`,
`tavern_screen.dart`, any Unit 6 route (`character_screen.dart`,
`gear_screen.dart`, `spells_screen.dart`, `skills_screen.dart`,
`town/pack_screen.dart`), anything under `lib/game`, `lib/save`, `lib/notice`,
`packages/core`, `packages/content`, dependency files, or LDD authority.

## Locked implementation

### 1. `town_style.dart` — additions

Add beside the existing colour and type constants, each with dartdoc in the
file's existing voice:

```dart
const double markColumn = 28;

const TextStyle placeName = TextStyle(
  fontFamily: 'monospace',
  fontSize: 20,
  letterSpacing: 5,
  color: ink,
);

const TextStyle roomName = TextStyle(
  fontFamily: 'monospace',
  fontSize: 15,
  letterSpacing: 4,
  color: ink,
);
```

Use `markColumn` for the existing `SizedBox(width: 28)` in `ItemRow`'s marking
column and in `MaterialRows`'s marking column. That substitution is
value-identical; change nothing else in either widget. The 84-wide word column in
`MaterialRows` keeps its literal.

Add the one shared committing control:

```dart
/// The one control that commits a room's work.
///
/// Six screens hand-rolled the same full-width button at two font sizes and two
/// paddings; a town with one grammar has one of them. Null [onPressed] leaves
/// the control on the row and dead rather than taking it away, which is the
/// inn's rule and the bank's: a control that vanishes teaches nothing.
class Commit extends StatelessWidget {
  const Commit({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
      ),
    ),
  );
}
```

`Commit` **must** render a real `FilledButton` whose direct text child is
`label`. `craft_rooms_test.dart` reads
`tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Brew'))` and its
`onPressed`, and the forge group does the same for `Smelt`. Do not add a key,
an icon, a semantics wrapper, a loading state, or a width constraint.

### 2. `town_style.dart` — reshapes and removal

`Purse` loses its card. Keep the class name, the `const` constructor, both
fields, and both strings **exactly**:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Carried  $carried gold', style: mono),
    Text('Banked   $banked gold', style: mono),
    const Divider(color: rule, height: 20),
  ],
)
```

The `Container`, `BoxDecoration`, `panel` fill and 4-radius are deleted. The two
strings keep their internal double spaces; several suites assert them character
for character.

`TownRoom` moves its title into the body:

```dart
Scaffold(
  appBar: AppBar(backgroundColor: panel, foregroundColor: ink),
  body: ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    children: [
      Text(title, style: roomName),
      const Divider(color: rule, height: 22),
      ...children,
      const SizedBox(height: 24),
    ],
  ),
)
```

The `AppBar` keeps no `title`. It stays because it carries the automatically
inserted back button, which both the player and `tester.pageBack()` depend on.
**Render `title` verbatim — never upper-cased, never abbreviated.** Twelve town
routes are found by `find.text('<Title>')`, including
`character_screen_test.dart`'s four Unit 6 routes.

Delete `MaterialsPanel` entirely. No alias, no deprecation, no re-export.

### 3. Mechanical call-site migrations

These are the only edits permitted in the five room files this task touches. Make
no other change in them.

In `forge_screen.dart` and `alchemist_screen.dart`, replace the single child

```dart
MaterialsPanel(materials: state.materials),
```

with the two children

```dart
const Heading('Materials'),
MaterialRows(materials: state.materials),
```

`Materials` is the word `game/pack_screen.dart:149` already uses for this block,
so the town and the crawl name the same thing the same way. Leave the
surrounding `SizedBox(height: 10)` and the `Notice` where they are; task 03 owns
that ordering.

Replace each hand-rolled commit `FilledButton` with `Commit`, preserving its
exact label and its exact `onPressed` expression including the `setState` reset:

| File | Label | Notes |
| --- | --- | --- |
| `bank_screen.dart` | `Bank gold` | `onPressed` stays `pendingBank <= 0 ? null : …` |
| `bank_screen.dart` | `Take gold` | `onPressed` stays `pendingTake <= 0 ? null : …` |
| `inn_screen.dart` | `Rest` | `onPressed` stays `state.canRest && state.gold >= innPrice ? … : null` |
| `forge_screen.dart` | `Smelt` | `onPressed` stays `pending <= 0 ? null : …` |
| `alchemist_screen.dart` | `Brew` | `onPressed` stays `pending <= 0 ? null : …` |
| `roster_screen.dart` | `New hero` | `onPressed` stays `() => _create(context)` |

Remove any `SizedBox` that existed only to space a button you have replaced, if
and only if `Commit`'s own vertical padding now supplies that gap; otherwise
leave the spacing alone. Do not reorder anything.

### 4. `town_screen.dart`

Keep the class name, the `const` constructor, `_titleFor`, `_descentsSoFar`,
`_open`, and the entire scroll skeleton — `LayoutBuilder` →
`SingleChildScrollView` → `ConstrainedBox(minHeight: room.maxHeight)` →
`IntrinsicHeight` → `Padding(EdgeInsets.all(20))` → `Column(crossAxisAlignment:
stretch)` — unchanged. That skeleton is the fix for a column that once overflowed
a 600-pixel screen by 45 pixels; it is not decoration and it is not yours to
simplify.

Remove the `AppBar`'s `title`; keep `backgroundColor: panel` and
`foregroundColor: ink`.

The `Column`'s children become exactly, in this order:

```dart
Text(_titleFor(state.town), style: placeName),
const SizedBox(height: 4),
Text(_descentsSoFar(state.profile.visit), style: monoDim),
const Divider(color: rule, height: 28),
Text('Health   ${state.hp} / ${state.maxHp}', style: mono),
Text('Carried  ${state.gold} gold', style: mono),
Text('Banked   ${state.bankedGold} gold', style: mono),
const Heading('Materials'),
MaterialRows(materials: state.materials),
Notice(state.notice),
const Spacer(),
// the seven doors
```

The three figure strings keep their internal double spaces verbatim.

Reshape the private `_Door`:

```dart
class _Door extends StatelessWidget {
  const _Door({
    required this.label,
    required this.purpose,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String purpose;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(color: rule, height: 1),
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          foregroundColor: ink,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: mono),
            const SizedBox(height: 2),
            Text(purpose, style: monoDim),
          ],
        ),
      ),
    ],
  );
}
```

A `TextButton` and not a bare `InkWell`, so the row keeps a button role for
accessibility; not a `FilledButton`, because seven identical filled slabs are the
heavy uniform furniture this unit replaces. Both `Text`s carry explicit colours,
so the button's foreground never decides them.

The seven doors, in this exact order, with these exact labels, purpose lines,
keys and targets:

| Key | Label | Purpose | Target |
| --- | --- | --- | --- |
| `town-door-merchant` | `Merchant` | `Buy, sell, and buy back` | `const MerchantScreen()` |
| `town-door-bank` | `Bank` | `Gold and gear, safe from death` | `const BankScreen()` |
| `town-door-inn` | `Inn` | `A bed for the night` | `const InnScreen()` |
| `town-door-character` | `Character` | `Gear, spells, skills, and pack` | `const CharacterScreen()` |
| `town-door-tavern` | `Tavern` | `Ask about the roads` | `const TavernScreen()` |
| `town-door-forge` | `Forge` | `Smelt ore, temper steel` | `const ForgeScreen()` |
| `town-door-alchemist` | `Alchemist` | `Brew herbs into potions` | `const AlchemistScreen()` |

Every `onPressed` stays `() => _open(context, const XScreen())`. No door is
added, removed, renamed, reordered, grouped, disabled, or given a badge. There is
no Heroes door: Heroes is a world action and `world_screen_test.dart:197` asserts
its absence from the town.

**Introduce no new mark codepoint** — no chevron, arrow, bullet, or dot anywhere
on this screen. Unit 5 shipped `↕` (U+2195) and Android resolved it through the
colour emoji font, which no widget test can see; U+2B65 is tofu on this target.
Separation is a rule, hierarchy is type size, affordance is the button. If you
believe a mark is required, escalate; do not add one.

Update the file's class dartdoc so it describes the screen as it now is, keeping
its existing reasoning about seven doors, the scroll wrapper, the back button,
and nothing being told apart by colour. Follow `AGENTS.md`: dartdoc only, never a
comment inside a function body.

## Red/Green behavioural proof

Work test-first. Add `packages/app/test/widget/town_shell_test.dart` with a
harness that pumps `const TownScreen()` under a real `TownBloc` and a real
`WorldBloc` inside a `MultiBlocProvider` — copy the shape of
`craft_rooms_test.dart`'s `_openRoom` helper; do not introduce a mock bloc.

Establish behavioural Red first:

1. **Every door says what it is for.** Assert all seven purpose strings are
   present, each exactly once. Expected Red: none exists.
2. **The place and its standing read together.** Assert that the town's name and
   the exact descents sentence are both on screen with the name appearing
   exactly once, and that the door rows carry both a label and a second line.
   Expected Red: the second line does not exist. The `findsOneWidget` on the name
   is what will later catch a header that duplicates the `AppBar` title instead
   of replacing it — a duplicate would break every exact-text finder that lands
   in a town.

Then cut the source over and finish the Green set:

3. **Seven doors, in order, and no eighth.** Collect the seven keyed rows and
   assert they appear in the locked order by widget order, that each carries its
   own label and purpose, and that `find.text('Heroes')` finds nothing.
4. **The last door is reachable on a 600-pixel-tall screen.** Do **not** call
   `onAPhone` in this test: the default 800×600 test surface is the exact
   geometry that once overflowed by 45 pixels. `scrollUntilVisible` to
   `Alchemist`, then assert it is found and `tester.takeException()` is null.
   Repeat the scroll for every one of the seven labels so no door is stranded.
5. **Every door opens its own room.** For each of the seven, tap the label, assert
   the room's title text is on screen, and `pageBack()`. This proves `_open` still
   provides both blocs — the tavern reads `WorldBloc` and would throw otherwise.
6. **The status block states the hero's facts.** With a seeded profile assert the
   three exact figure strings, the exact descents sentence for `visit` values 0,
   1, 2 and 5, one row per `MaterialId` with its marking and word, and that a
   seeded `SentenceNotice` is rendered.

Also run, unchanged, the suites that prove the mechanical migrations did not move
behaviour. `bank_screen_test.dart`, `disabled_controls_test.dart`,
`craft_rooms_test.dart`, `count_stepper_test.dart`, `roster_screen_test.dart`,
`character_screen_test.dart` and `merchant_screen_test.dart` must all pass
**without being edited**. If one fails, behaviour moved: fix the source, not the
test. The only test file you may edit is `craft_rooms_test.dart`, and only to
delete the `the town door column` group you moved into `town_shell_test.dart`
(migrate both of its tests: the seven-door reachability walk and the
mark/word/count material assertions).

Structure test bodies `// arrange` / `// act` / `// assert`. Use real blocs and
observable state. Do not assert widget types, paddings, pixel geometry, colours,
or source text; do not add a golden test.

## Focused proof commands

From `packages/app`, after Green:

```sh
flutter test test/widget/town_shell_test.dart \
  test/widget/craft_rooms_test.dart \
  test/widget/bank_screen_test.dart \
  test/widget/merchant_screen_test.dart \
  test/widget/disabled_controls_test.dart \
  test/widget/count_stepper_test.dart \
  test/widget/character_screen_test.dart \
  test/widget/roster_screen_test.dart \
  test/widget/roster_session_test.dart

dart format lib/town/town_style.dart lib/town/town_screen.dart \
  lib/town/bank_screen.dart lib/town/inn_screen.dart \
  lib/town/forge_screen.dart lib/town/alchemist_screen.dart \
  lib/town/roster_screen.dart \
  test/widget/town_shell_test.dart test/widget/craft_rooms_test.dart

dart analyze lib/town/town_style.dart
dart analyze lib/town/town_screen.dart
dart analyze lib/town/bank_screen.dart
dart analyze lib/town/inn_screen.dart
dart analyze lib/town/forge_screen.dart
dart analyze lib/town/alchemist_screen.dart
dart analyze lib/town/roster_screen.dart
dart analyze test/widget/town_shell_test.dart
dart analyze test/widget/craft_rooms_test.dart
```

Re-run the focused tests after formatting or any static correction. Do not run
the full suite, whole-package `flutter analyze`, a whole-tree formatter, an app
build, an emulator, or a device install. Main owns those gates.

## Executor discretion

You may choose private helper and file-private widget names, local widget
splitting inside `town_screen.dart`, test helper names and fixture placement, and
the exact wording of new dartdoc as long as it matches the file's existing voice.

You may not change public class, constructor, parameter, constant or key names;
the door order, labels, purpose lines or targets; any displayed string; the
`Commit` widget type or its text child; `TownRoom`'s verbatim title; the scroll
skeleton; the frozen primitives (`Heading`, `NothingHere`, `ItemRow`,
`MaterialRows`, `CountStepper`, `Notice`) beyond the `markColumn` substitution;
or the removal of `MaterialsPanel`.

## Escalate when

- the scroll skeleton cannot hold the taller door column without clipping, or the
  last door cannot be reached on a 600-pixel surface;
- `Commit` cannot replace a hand-rolled button without changing what a test finds
  or what a press dispatches;
- removing the `AppBar` title breaks a back affordance or a route finder;
- a purpose line collides with an existing finder, or a door label is no longer
  uniquely findable on the town screen;
- an existing town test fails for a reason other than the composition it pinned;
- the screen cannot read in greyscale, or seems to need a mark codepoint, a hue
  distinction, or an asset;
- any required fix would cross into `town_bloc.dart`, `world_screen.dart`, a
  Unit 6 route, `lib/game`, `packages/core`, or `packages/content`.

## Handoff state and completion receipt

Task 01 is complete when `town_style.dart` holds the vocabulary in `../PLAN.md`
section 1, `MaterialsPanel` is gone, all six commit buttons are `Commit`, every
room renders inside the rebooted `TownRoom`, the town shell shows the header,
the status block, the material rows, the notice and seven purposeful doors, the
new shell test is green, and every other named suite passes unchanged.

Report to Main in at most eight prose lines:

- the behavioural Red observed for the missing purpose lines and body header;
- the focused test command and pass count;
- the 600-pixel reachability result and the door-to-room navigation result;
- confirmation that `MaterialsPanel` is deleted and all six commits are `Commit`;
- which existing suites passed unchanged, and that `craft_rooms_test.dart` was
  edited only to move the town door group out;
- files added, changed and removed, and confirmation no forbidden path changed;
- formatter and analyzer commands and results;
- any escalation or residual item for Main's broad and device gates.
