# Task 02 — Merchant, Bank, Inn and Tavern

Owner: a fresh `flow-plan-executor` on the Unit 7 feature checkout after task 01
is green. Read `../PLAN.md`, `../CONTRACT.md` and
`01-town-grammar-and-shell.md` before editing. You have no conversation history
and need none.

## Expected starting repository condition

Task 01 has landed:

- `packages/app/lib/town/town_style.dart` exports `markColumn`, `placeName`,
  `roomName` and `Commit`; `Purse` is a ruled block with no card; `TownRoom`
  renders its title in the body and its `AppBar` has no title; `MaterialsPanel`
  no longer exists;
- `packages/app/lib/town/town_screen.dart` shows a place header, a status block,
  `Heading('Materials')` + `MaterialRows`, the notice, and seven keyed
  destination rows with purpose lines;
- `bank_screen.dart` and `inn_screen.dart` already use `Commit` for `Bank gold`,
  `Take gold` and `Rest`, and are otherwise untouched;
- `packages/app/test/widget/town_shell_test.dart` exists and is green.

Before editing, inspect branch and `git status`, and read task 01's completion
receipt. If `Commit`, `Purse` or `TownRoom` do not match the plan, or a planned
file has unexplained changes, stop and report the contradiction. Preserve
architect-owned uncommitted `.flow` files.

## Behavioural slice and scope

This task reboots the four counter rooms onto the town grammar: the rooms where
the hero spends and stores. Every transaction, price, count, heading, refusal and
explanatory sentence they show today survives word for word; what changes is
hierarchy, notice placement, and the bank's two-zone reading.

Touch only:

- `packages/app/lib/town/merchant_screen.dart`;
- `packages/app/lib/town/bank_screen.dart`;
- `packages/app/lib/town/inn_screen.dart`;
- `packages/app/lib/town/tavern_screen.dart`;
- `packages/app/test/widget/bank_screen_test.dart` (extend only);
- add `packages/app/test/widget/tavern_screen_test.dart`.

Do not edit `town_style.dart`, `town_screen.dart`, `forge_screen.dart`,
`alchemist_screen.dart`, `roster_screen.dart`, `town_bloc.dart`,
`world_screen.dart`, `world_bloc.dart`, `main.dart`, any Unit 6 route, anything
under `lib/game`, `lib/save`, `lib/notice`, `packages/core`, `packages/content`,
dependency files, or LDD authority. Do not edit
`merchant_screen_test.dart`, `disabled_controls_test.dart` or
`world_screen_test.dart`: they are your unchanged regression gate.

## Locked implementation

### Shared rule for all four rooms

Every room's notice sits in one place: directly under `Purse`, before the first
`Heading`. That is already true of Merchant, Bank and Inn; the Tavern is the
outlier and moves. One town grammar means the player looks in one place.

No room may add a private heading style, a private row, a private button, a
private panel, a private empty-list sentence widget, or a second material block.
Use `Heading`, `NothingHere`, `ItemRow`, `Purse`, `Notice`, `CountStepper` and
`Commit` as they are.

### `merchant_screen.dart`

Children of `TownRoom(title: 'Merchant')`, in this exact order:

1. `Purse(carried: state.gold, banked: state.bankedGold)`
2. `Notice(state.notice)`
3. `Heading('For sale')`
4. `NothingHere('The shelf is bare until you come back.')` when
   `state.stock.isEmpty`
5. one `ItemRow` per `stacked(state.stock)` entry
6. `Heading('Sold this visit')` and its rows, **only** when
   `state.merchant.sold.isNotEmpty`
7. `Heading('Your pack')`
8. `NothingHere('You are carrying nothing.')` when
   `state.profile.inventory.isEmpty`
9. one `ItemRow` per `stacked(state.profile.inventory)` entry

Each row keeps `marking: stack.item.rarity.marking`, `name: stack.label`, and its
action word with the per-item price: `Buy ${buyPriceOf(stack.item)}`,
`Buy back ${sellPriceOf(stack.item)}`, `Sell ${sellPriceOf(stack.item)}`. Buy and
buy-back rows keep `reason: cannotAfford` and go dead exactly when
`state.gold < <that row's price>`; sell rows are never dead and never carry a
reason. Every press dispatches `BuyPressed` / `BuyBackPressed` / `SellPressed`
with `stack.item.id`.

The top-level `const String cannotAfford = 'you cannot afford this';` stays
public, at the same value, in this file.

In practice this room's structure is already correct and it inherits the reboot
from `TownRoom` and `Purse`. Change nothing you cannot justify against the list
above; an unnecessary edit here is pure risk.

### `bank_screen.dart` — the two-zone reading

Today the two gold dials sit together under a single `Heading('Gold')`, above two
item headings, so which dial banks and which withdraws is readable only from the
commit beneath it, and the carried/banked division is stated twice in two
different ways. Restructure into two zones, each one side of the death penalty,
each holding that side's gold **and** that side's items.

Children of `TownRoom(title: 'Bank')`, in this exact order:

1. `Purse(carried: state.gold, banked: state.bankedGold)`
2. `Notice(state.notice)`
3. `Heading('Carried — lost if you die')`
4. `CountStepper(value: pendingBank, cap: state.gold, onChanged: …)`
5. `Commit(label: 'Bank gold', onPressed: pendingBank <= 0 ? null : …)`
6. `Text(purseIsShort, style: monoDim)` when `state.gold <= 0`
7. `NothingHere('You are carrying nothing.')` when
   `state.profile.inventory.isEmpty`
8. one `ItemRow(action: 'Bank', …)` per `state.profile.inventory` item
9. `Heading('Banked — safe from death')`
10. `CountStepper(value: pendingTake, cap: state.bankedGold, onChanged: …)`
11. `Commit(label: 'Take gold', onPressed: pendingTake <= 0 ? null : …)`
12. `Text(vaultIsShort, style: monoDim)` when `state.bankedGold <= 0`
13. `NothingHere('The vault is empty.')` when `state.profile.bank.isEmpty`
14. one `ItemRow(action: 'Take out', …)` per `state.profile.bank` item

`Heading('Gold')` is deleted; the two zone headings now name both the gold and
the items under them, which is what makes the reading two-zone instead of four
sections.

Everything else is frozen:

- `_pendingBank` and `_pendingTake` stay private `State` fields, re-clamped on
  every build against `state.gold` and `state.bankedGold`;
- a commit dispatches `DepositGoldPressed(pendingBank)` or
  `WithdrawGoldPressed(pendingTake)` once with the dialled amount, then
  `setState`s its own pending count back to zero;
- item rows are never dead and carry no reason — the pack cap refuses through the
  notice, which is the existing behaviour;
- `purseIsShort` and `vaultIsShort` keep their exact values, stay public
  top-level constants in this file, and appear only while that side is empty;
- the carried zone stays first, so `find.text('+').first` and
  `find.text('MAX').first` still address the bank-side dial. `bank_screen_test.dart`
  depends on that ordinal and must not need editing to keep passing.

Keep and update the file's class dartdoc: it already records why the dials
replaced fixed buttons by user ruling and why item rows are never dead. Extend it
with the two-zone reading; do not delete the existing reasoning.

### `inn_screen.dart`

Children of `TownRoom(title: 'Inn')`, in this exact order:

1. `Purse(...)`
2. `Notice(state.notice)`
3. `Heading('A bed for the night')`
4. `Text('Health   ${state.hp} / ${state.maxHp}', style: mono)`
5. `Text('Price    $innPrice gold', style: mono)`
6. `Commit(label: 'Rest', onPressed: state.canRest && state.gold >= innPrice ? () => bloc.add(const RestPressed()) : null)`
7. `Text(_why(state), style: monoDim)`

`_why` is **frozen**, including its health-first precedence and all three exact
sentences:

```text
There is nothing wrong with you.
A night costs $innPrice and you carry ${state.gold}.
A night here mends everything the dungeon did.
```

A hero at full health is told so whatever their purse says. The reason always
renders, under the control, whether or not the control is alive. Remove only
spacing `SizedBox`es that `Commit`'s own padding now supplies.

### `tavern_screen.dart`

Children of `TownRoom(title: 'Tavern')`, in this exact order:

1. `Purse(carried: town.gold, banked: town.bankedGold)`
2. `Notice(town.notice ?? world.notice)` — **moved up** from between the offer
   and the second heading
3. `Heading('What they are saying')`
4. when `offered == null`, `NothingHere('Nobody here has anything left to tell you. You have heard of everywhere they know.')` with its existing two-part string literal preserved exactly
5. otherwise `ItemRow(marking: '[!]', name: 'Ask about the roads', action: 'Ask $rumorPrice', onPressed: () => _ask(context, world, town))`
6. `Heading('What you have been told')`
7. `NothingHere('Nothing yet.')` when `world.log.isEmpty`
8. otherwise one `Padding(vertical: 2)` + `Text(line, style: monoDim)` per entry
   of `world.log.reversed.take(6)`

`offered` stays `world.rumorOnOffer(rumorPool)`. The nested
`BlocBuilder<WorldBloc, WorldViewState>` over
`BlocBuilder<TownBloc, TownViewState>` stays as it is.

`_ask` is **frozen**: one `buyRumor(town.profile, world.world, rumorPool,
rumorPrice)` call, then `RumorBought(told)` to `TownBloc` and `RumorHeard(told)`
to `WorldBloc` as one synchronous pair. Do not split it, await between the
dispatches, precondition it on the purse, preflight a refusal, or move the
decision into the widget. A hero who cannot afford it presses the live control
and reads core's refusal in the notice; that is the existing behaviour and
`world_screen_test.dart:470-485` pins it.

The six-line cap and `reversed` order are behaviour, not styling: the tavern
shows the last six world log lines, newest first.

## Red/Green behavioural proof

Work test-first.

Establish behavioural Red:

1. In `bank_screen_test.dart`, assert that the carried heading is followed —
   before the banked heading — by a `CountStepper`, the `Bank gold` commit and
   the carried item rows, and that no `Gold` heading exists. Expected Red: the
   dials sit above both headings under `Heading('GOLD')`.
2. In the new `tavern_screen_test.dart`, assert the notice appears above
   `Heading('What they are saying')`. Expected Red: it sits below the offer row.

Then cut the source over and finish the Green set.

### `bank_screen_test.dart` — extend, do not rewrite

Keep every existing test, including `the fixed gold buttons are gone`, unchanged;
it is the one legitimate composition pin in this suite and it stays true. Add:

3. **Two zones, in order.** Assert the widget order is: carried heading, a
   stepper, `Bank gold`, carried item rows; then banked heading, a stepper,
   `Take gold`, banked item rows. Assert `Gold` is not a heading anywhere. Seed
   one carried item and one banked item so both row groups exist.
4. **Each zone's short sentence belongs to its own zone.** With gold 0 and
   banked 40, assert `purseIsShort` is present and `vaultIsShort` is not, the
   `Bank gold` commit is dead and the `Take gold` commit is alive; then the
   mirror case.
5. **Items are never dead in either zone.** With a full-to-cap inventory, assert
   every `Bank` and `Take out` control is still enabled and carries no reason.

### `tavern_screen_test.dart` — new

Pump `const TavernScreen()` under a real `TownBloc` and a real `WorldBloc` inside
a `MultiBlocProvider`, on `onAPhone`. Add:

6. **Both headings and the offer.** With an undiscovered place available, assert
   `What they are saying`, `What you have been told`, the `[!]` marking, the name
   `Ask about the roads` and the action `Ask $rumorPrice`.
7. **The exhausted line.** With every place already discovered, assert the full
   exhausted sentence is present and no `Ask` control exists.
8. **The last six lines, newest first.** Seed a `WorldBloc` whose log holds more
   than six lines. Assert exactly six are rendered, that they are the six most
   recent, that the newest is first, and that the older ones are absent.
9. **`Nothing yet.`** With an empty world log, assert the sentence renders.
10. **The notice comes from either bloc.** With a town notice and no world
    notice, assert the town's sentence renders; with no town notice and a world
    notice, assert the world's sentence renders; with both, assert the town's
    wins. Assert in each case that the notice sits above
    `What they are saying`.
11. **Asking spends once and tells both blocs.** With enough gold, tap the offer
    and assert the town profile's gold fell by exactly `rumorPrice` and the world
    bloc discovered exactly one new place. Do not re-prove the world-screen
    integration that `world_screen_test.dart:422-486` already owns.

Use real blocs and observable state, `// arrange` / `// act` / `// assert`, and
`addTearDown` to close any bloc you construct directly. Do not assert widget
types other than where an existing test already does, and do not assert paddings,
colours, pixel geometry or source text.

### Unchanged regression gate

`merchant_screen_test.dart`, `disabled_controls_test.dart`,
`world_screen_test.dart`, `town_shell_test.dart`, `count_stepper_test.dart` and
`town_bloc_test.dart` must pass **without being edited**. Between them they prove
merchant stacking and per-item pricing, the merchant's dead-row refusal, all
three inn sentences, both bank short sentences, the tavern purchase and its
refusal, and the whole transaction layer. If one fails, behaviour moved: fix the
source, not the test.

## Focused proof commands

From `packages/app`, after Green:

```sh
flutter test test/widget/bank_screen_test.dart \
  test/widget/tavern_screen_test.dart \
  test/widget/merchant_screen_test.dart \
  test/widget/disabled_controls_test.dart \
  test/widget/town_shell_test.dart \
  test/widget/world_screen_test.dart \
  test/widget/count_stepper_test.dart \
  test/town_bloc_test.dart

dart format lib/town/merchant_screen.dart lib/town/bank_screen.dart \
  lib/town/inn_screen.dart lib/town/tavern_screen.dart \
  test/widget/bank_screen_test.dart test/widget/tavern_screen_test.dart

dart analyze lib/town/merchant_screen.dart
dart analyze lib/town/bank_screen.dart
dart analyze lib/town/inn_screen.dart
dart analyze lib/town/tavern_screen.dart
dart analyze test/widget/bank_screen_test.dart
dart analyze test/widget/tavern_screen_test.dart
```

Re-run the focused tests after formatting or any static correction. Do not run
the full suite, whole-package `flutter analyze`, a whole-tree formatter, an app
build, an emulator, or a device install.

## Executor discretion

You may choose private helper and file-private widget names, local widget
splitting inside these four files, spacing within the locked vocabulary, test
helper names and fixture placement, and how a test measures widget order.

You may not change public class, constructor or constant names; `cannotAfford`,
`purseIsShort` or `vaultIsShort`; any displayed string; heading text or order;
row order; which control is dead and when; the events dispatched or their
arguments; `_why`'s precedence; `_ask`'s synchronous pair; the tavern's six-line
cap or `reversed` order; or the ordinal position of the bank's two steppers.

## Escalate when

- a preserved sentence cannot be produced from the existing bloc or core value
  without composing or rewording it;
- the bank's two-zone order would change which stepper `find.text('+').first`
  addresses, or would make a commit reachable without its dial;
- moving the tavern's notice changes which sentence wins, or the `??` fallback
  cannot be expressed without asking a bloc twice;
- a room cannot fit a phone without hiding a control, a price, or a reason;
- any required fix would cross into `town_style.dart`, `town_screen.dart`,
  `town_bloc.dart`, `world_screen.dart`, `lib/game`, `packages/core` or
  `packages/content`;
- an unedited regression suite fails for a reason other than a composition it
  pinned;
- a screen seems to need a new mark codepoint, a hue distinction, or an asset.

## Handoff state and completion receipt

Task 02 is complete when the four counter rooms render inside the rebooted town
grammar with one notice position, the bank reads as two zones of gold and items,
every listed sentence, price, count and control behaves exactly as before, the
new and extended tests are green, and every named regression suite passes
unchanged.

Report to Main in at most eight prose lines:

- the behavioural Red observed for the bank's interleaved gold section and the
  tavern's notice position;
- the focused test command and pass count;
- the two-zone proof and both short-sentence cases;
- the tavern's six-line cap, exhausted line and either-bloc notice results;
- confirmation that merchant, inn and every regression suite passed unedited;
- files added and changed, and confirmation no forbidden path changed;
- formatter and analyzer commands and results;
- any escalation or residual item for Main's broad and device gates.
