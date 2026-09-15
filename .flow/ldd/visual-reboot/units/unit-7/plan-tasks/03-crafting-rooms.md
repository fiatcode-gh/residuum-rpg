# Task 03 — Forge and Alchemist

Owner: a fresh `flow-plan-executor` on the Unit 7 feature checkout after task 02
is green. Read `../PLAN.md`, `../CONTRACT.md` and
`01-town-grammar-and-shell.md` before editing. You have no conversation history
and need none.

## Expected starting repository condition

Task 01 and task 02 have landed:

- `town_style.dart` exports `markColumn` (28), `placeName`, `roomName` and
  `Commit`; `Purse` is a ruled block; `TownRoom` renders its title in the body;
  `MaterialsPanel` no longer exists;
- `forge_screen.dart` and `alchemist_screen.dart` already render
  `const Heading('Materials'), MaterialRows(materials: state.materials)` where
  `MaterialsPanel` used to be, and already use `Commit` for `Smelt` and `Brew`;
  nothing else in them has changed;
- the four counter rooms put `Notice` directly under `Purse`;
- `town_shell_test.dart` and `tavern_screen_test.dart` exist and are green.

Before editing, inspect branch and `git status`, and read task 02's completion
receipt. If `Commit`, `markColumn` or the material block do not match the plan,
or a planned file has unexplained changes, stop and report the contradiction.
Preserve architect-owned uncommitted `.flow` files.

## Behavioural slice and scope

This task reboots the two crafting rooms: the rooms where the hero spends
material rather than coin. Both are already dial-and-commit shaped; what changes
is hierarchy, notice placement, and column alignment between the material rows
and the bench rows that sit on the same screen. Every ratio line, price, count,
refusal and explanatory sentence survives word for word.

Touch only:

- `packages/app/lib/town/forge_screen.dart`;
- `packages/app/lib/town/alchemist_screen.dart`;
- `packages/app/test/widget/craft_rooms_test.dart` (extend only).

Do not edit `town_style.dart`, `town_screen.dart`, any counter room,
`roster_screen.dart`, `town_bloc.dart`, `world_screen.dart`, `main.dart`, any
Unit 6 route, anything under `lib/game`, `lib/save`, `lib/notice`,
`packages/core`, `packages/content`, dependency files, or LDD authority.

## Locked implementation

### `forge_screen.dart`

Children of `TownRoom(title: 'Forge')`, in this exact order:

1. `Purse(carried: state.gold, banked: state.bankedGold)`
2. `Notice(state.notice)` — **moved up** so the forge matches every other room
3. `Heading('Materials')`
4. `MaterialRows(materials: state.materials)`
5. `Heading('Smelting')`
6. `Text('$smeltCost ore makes 1 ingot.', style: mono)`
7. `CountStepper(value: pending, cap: cap, onChanged: …)`
8. `Commit(label: 'Smelt', onPressed: pending <= 0 ? null : …)`
9. the smelt sentence in `monoDim`
10. `Heading('The bench')`
11. when `workable.isEmpty`, `NothingHere('You have no steel for the bench.')`
12. otherwise `Heading('Worn steel')`, `NothingHere('You are wearing no steel.')`
    when `state.wornSteel.isEmpty`, a `_TemperRow` per `state.wornSteel` item,
    then `Heading('Carried steel')`,
    `NothingHere('You are carrying no steel.')` when
    `state.carriedSteel.isEmpty`, and a `_TemperRow` per `state.carriedSteel`
    item

Drop the bare `SizedBox(height: 10)` spacers that only separated the retired
purse and materials cards; `Heading`'s own top padding supplies that gap now.
Keep any `SizedBox` that still does work around the dial and the commit, and
remove one only where `Commit`'s own vertical padding replaces it.

Frozen exactly as they are:

- `cap = countOf(state.profile.materials, MaterialId.ore) ~/ smeltCost` and
  `pending = _pending.clamp(0, cap)`, re-clamped on every build;
- the commit dispatches `SmeltPressed(pending)` once and then `setState`s
  `_pending = 0`;
- the smelt sentence is `state.smeltReason == null ? 'The fire is hot and the ore
  is ready.' : _capitalised(state.smeltReason!)`, and `_capitalised` keeps its
  current body;
- `workable` is `state.temperable`, and the bench's worn-before-carried split
  comes from `state.wornSteel` / `state.carriedSteel`. The widget computes
  nothing about steel itself.

`_TemperRow` keeps its class, its three fields, its dartdoc reasoning, and every
line it draws. Two things change:

- its marking `SizedBox(width: 26)` becomes `SizedBox(width: markColumn)`, and
  each of its three `EdgeInsets.only(left: 26)` indents becomes
  `EdgeInsets.only(left: markColumn)`. This is why `markColumn` exists: the forge
  is the one screen that shows `MaterialRows` and bench rows together, and a
  two-pixel drift between their mark columns aligns on a desktop and steps
  sideways on the phone;
- it may gain a `Divider(color: rule, height: 1)` above each row so the bench
  reads as a ruled list like the town's doors, if and only if that is done for
  every row uniformly.

Frozen in `_TemperRow`:

- the control is a `TextButton` whose child is `Text('Temper', style:
  TextStyle(fontFamily: 'monospace', fontSize: 12))`, enabled exactly when
  `reason == null`. `craft_rooms_test.dart:433` asserts
  `find.widgetWithText(TextButton, 'Temper')` finds nothing when the bench is
  empty, so this control must stay a `TextButton` with that exact text;
- `statLine(item)` always renders;
- the `reason` sentence renders verbatim, unmodified, whenever it is non-null;
- `Next tier: n ingot(s).` renders whenever `item.temper < maxTemper`, **including
  on a refused row**, with the existing singular/plural expression. A row at the
  ceiling names no price.

### `alchemist_screen.dart`

Children of `TownRoom(title: 'Alchemist')`, in this exact order:

1. `Purse(carried: state.gold, banked: state.bankedGold)`
2. `Notice(state.notice)` — **moved up**
3. `Heading('Materials')`
4. `MaterialRows(materials: state.materials)`
5. `Heading('Brewing')`
6. `Text('$brewCost herbs make 1 healing potion.', style: mono)`
7. `Text('The shelf asks ${AlchemistScreen._worth()} gold for one.', style: monoDim)`
8. `CountStepper(value: pending, cap: cap, onChanged: …)`
9. `Commit(label: 'Brew', onPressed: pending <= 0 ? null : …)`
10. the brew sentence in `monoDim`

Frozen exactly as they are:

- `herbCap = countOf(state.profile.materials, MaterialId.herb) ~/ brewCost`,
  `room = inventoryCap - state.profile.inventory.length`,
  `cap = min(herbCap, room)`, `pending = _pending.clamp(0, cap)`;
- the commit dispatches `BrewPressed(pending)` once and then `setState`s
  `_pending = 0`;
- the brew sentence is `state.brewReason == null ? 'The pot is on and you have
  what it takes.' : '<brewReason capitalised>.'` with the existing inline
  expression;
- `AlchemistScreen._worth()` keeps reading `buyPriceOf` on a common healing
  potion, so a brewed potion and a bought one cannot come to be worth different
  things.

`Notice(state.notice)` renders the bloc's notice unmodified. That is how the
batch-loss sentence reaches the screen: `TownBloc._onBrew` emits
`SentenceNotice(_batchLoss(...))` and returns before `_levelled` can speak, so a
batch that lost herbs says so instead of announcing a level-up. The widget makes
no precedence decision of its own and must not filter, prefix, or re-rank a
notice.

Update both files' class dartdoc to describe the rooms as they now are, keeping
the existing reasoning about the dial being view state, the batch not being
atomic, the row wearing its price whether or not it can be worked, and nothing
being told apart by colour. Dartdoc only — never a comment inside a function
body.

## Red/Green behavioural proof

Work test-first, extending `packages/app/test/widget/craft_rooms_test.dart`. Keep
every existing test in it unchanged; they are the regression gate for both rooms.

Establish behavioural Red:

1. Assert the forge's notice appears above `Heading('Materials')`. Expected Red:
   the notice sits below the material block today.
2. Assert the alchemist's notice carries a batch-loss sentence after a batch that
   lost herbs, and that no level-up sentence is shown in its place. Use the
   existing `_stateBrewing` helper's sibling technique — search a
   `craftRngState` whose next rolls include at least one failure below the 5%
   floor — and drive the room's own `Brew` commit. Expected Red: this assertion
   does not exist yet; write it before the reshape so it also guards the reshape.

Then cut the source over and add the Green set:

3. **Forge order.** Assert the widget order is purse rows, notice, `MATERIALS`
   heading, material rows, `SMELTING` heading, ratio line, dial, `Smelt`,
   sentence, `THE BENCH`. Assert exactly one material block exists on the screen.
4. **Alchemist order.** The same shape through `BREWING`, ratio line, worth line,
   dial, `Brew`, sentence. Assert exactly one material block.
5. **Batch loss wins the notice slot.** From the Red above: after a batch with at
   least one failure, the alchemist shows the batch-loss sentence and does not
   show `Herbcraft rises to`. Read the expected sentence from the bloc's own
   `state.notice!.sentence` rather than hard-coding the arithmetic, so the test
   pins precedence rather than re-deriving `_batchLoss`.
6. **A refused bench row still names its price.** Extend or re-assert the
   existing refused-row case so that the reason sentence, the stat line and the
   `Next tier:` line are all present on the same row. The existing tests at
   `craft_rooms_test.dart:272-348` already cover most of this; add only what they
   do not.

Do not add a test that asserts a pixel width, a padding, a colour, or a widget's
geometry. The mark-column alignment is proved on device, not by transplanting
implementation geometry into a widget test — Unit 6 deleted exactly such a test
for that reason.

### Unchanged regression gate

Every existing test in `craft_rooms_test.dart`, plus `town_bloc_test.dart`,
`town_shell_test.dart`, `count_stepper_test.dart` and
`test/town/town_crawl_carry_test.dart`, must pass without further editing.
Between them they prove the smelt and brew caps, `MAX`, the held-edge repeat, the
per-unit draw, the batch arithmetic, the level-up sentence, the bench split, the
ceiling row, the potion exclusion, and that every town handler preserves an
arriving camp. If one fails, behaviour moved: fix the source, not the test.

## Focused proof commands

From `packages/app`, after Green:

```sh
flutter test test/widget/craft_rooms_test.dart \
  test/widget/town_shell_test.dart \
  test/widget/count_stepper_test.dart \
  test/town_bloc_test.dart \
  test/town/town_crawl_carry_test.dart

dart format lib/town/forge_screen.dart lib/town/alchemist_screen.dart \
  test/widget/craft_rooms_test.dart

dart analyze lib/town/forge_screen.dart
dart analyze lib/town/alchemist_screen.dart
dart analyze test/widget/craft_rooms_test.dart
```

Re-run the focused tests after formatting or any static correction. Do not run
the full suite, whole-package `flutter analyze`, a whole-tree formatter, an app
build, an emulator, or a device install.

## Executor discretion

You may choose private helper names, local widget splitting inside these two
files, spacing within the locked vocabulary, whether `_TemperRow` carries a
leading rule (uniformly or not at all), test helper names, and how a test
measures widget order.

You may not change public class or constructor names; `AlchemistScreen._worth`'s
source; any displayed string; heading text or order; the dial caps or their
clamping; the events dispatched or their arguments; the `Temper` control's widget
type or text; the `Next tier:` rule; the capitalisation helpers; or `markColumn`
itself.

## Escalate when

- a preserved sentence cannot be produced from the existing bloc or core value
  without composing or rewording it;
- `markColumn` does not in fact align the material rows with the bench rows,
  which would mean the shared constant is the wrong mechanism;
- the batch-loss precedence cannot be observed at the screen without changing
  `town_bloc.dart`;
- a row cannot show its marking, name, stat line, reason and next-tier price on a
  phone without hiding one of them;
- any required fix would cross into `town_style.dart`, `town_bloc.dart`,
  `lib/game`, `packages/core` or `packages/content`;
- an existing test fails for a reason other than a composition it pinned;
- a screen seems to need a new mark codepoint, a hue distinction, or an asset.

## Handoff state and completion receipt

Task 03 is complete when both crafting rooms render inside the rebooted town
grammar with the notice directly under the purse, one shared material block, mark
columns on one constant, every ratio line, cap, dial, commit, refusal and
next-tier price behaving exactly as before, the new assertions green, and every
named regression suite passing unchanged.

Report to Main in at most eight prose lines:

- the behavioural Red observed for the forge's notice position and the untested
  batch-loss precedence;
- the focused test command and pass count;
- the order proofs for both rooms and the confirmation of exactly one material
  block on each;
- the batch-loss-over-level-up result;
- the refused-row reason plus next-tier price result;
- files changed, and confirmation no forbidden path changed;
- formatter and analyzer commands and results;
- any escalation, plus an explicit note that bench-versus-materials column
  alignment is still owed a device reading in Main's evidence pass.
