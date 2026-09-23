# Task 03 — Forge navigation and Tavern affordability

## Starting condition

- Read `../CONTRACT.md`, `../PLAN.md`, and this capsule.
- Repository precondition: the current sequential checkout contains the accepted Task 01–02 production state, including `FramedRow`, `ItemRow.details`, custom Pack filters, and the completed list-consumer cutover. This task depends on those files and named focused proofs, not on prior executor context; escalate if they are absent or materially different.
- Do not change transaction classes, core rules, content, prices, save data, BLoC ownership, art, or route vocabulary. Do not commit, push, or publish.

## Behavioral slice

Reorganize Forge into two presentation routes around its existing work, and add an explicit Tavern affordability cue without changing either room's transaction outcomes or refusal path.

## Exact ownership

Production:

- `packages/app/lib/town/forge_screen.dart`
  - make `ForgeScreen` a stateless menu with purse, notice, current Forge illustration, then exactly two empty-medallion `FramedRow` routes:
    - key `forge-route-smelt`, title `Smelt`, detail `Turn ore into ingots.`;
    - key `forge-route-temper`, title `Temper`, detail `Work carried or worn steel.`;
  - push both routes under `BlocProvider.value` with the current TownBloc;
  - move `_pending` and all current smelting widgets/callbacks into private `_SmeltingScreen`/`_SmeltingScreenState` titled `Smelting`;
  - move all current bench lists/callbacks into private `_TemperingScreen` titled `Tempering`;
  - each console renders purse → notice → Materials heading/`MaterialRows` → its own work;
  - make `_TemperRow` compose `FramedRow` with rarity marking, display name, stat/reason/next-tier detail order, and current Temper control;
  - retain the exact `SmeltPressed(pending)` and `TemperPressed(item.id)` dispatches, pending clamp/reset, work/refusal calculations, list split, and notice source.
- `packages/app/lib/town/tavern_screen.dart`
  - pass exactly one affordability sentence from `../PLAN.md` through `ItemRow.details`;
  - keep `Ask $rumorPrice` enabled whenever `offered != null`, including when poor;
  - leave `_ask` and its paired synchronous dispatches unchanged.

Proof migrations:

- `packages/app/test/widget/craft_rooms_test.dart`
- `packages/app/test/widget/tavern_screen_test.dart`
- `packages/app/test/widget/town_illustration_test.dart`
- `packages/app/test/style/material_palette_test.dart`

## Red proof first

Forge:

1. Add a root-menu test asserting exactly `forge-route-smelt` and `forge-route-temper`, their exact titles/details, no commit controls at root, and no third work route or `Craft` text.
2. Add a navigation test proving each route opens the named console with the same TownBloc and that returning to the menu does not mutate profile state.
3. Adapt existing smelt tests to enter `forge-route-smelt` before finding the stepper/commit. Keep proofs for disabled short-ore state, exact one/batch commit, cap, MAX, hold repeat, and notice.
4. Adapt existing temper tests to enter `forge-route-temper`. Keep proofs for eligible-only steel, worn/carried split, empty halves, exact refusal, retained next-tier price, ceiling, live temper, level-up notice, and exclusion of potions.
5. Replace the obsolete combined-screen order pin with behavior: each console has one shared Materials block before its work and exposes only its own transaction.
6. Keep the Forge illustration proof at the root menu; do not require or duplicate it in the consoles.

Tavern:

1. Assert the exact affordable sentence at/above `rumorPrice` and the exact `Need N more gold` sentence below it.
2. For a poor hero, tap Ask rather than dispatching a result directly. Assert gold and discovered destinations are unchanged and `you cannot afford that` appears through the existing notice path.
3. Retain the successful one-press proof: exactly one price spent and one destination revealed.
4. Retain offered/exhausted state, six newest log lines, and notice precedence/order.

Palette test migration:

- Enter the Smelting route before inspecting the enabled Smelt control.
- Keep the Tavern Ask control proof and existing U14 colour assertions; do not replace behavior with source-text checks.

Expected Red: Forge is still one combined screen with transaction controls at root, and Tavern has no affordability sentence/poor-press widget proof.

## Green implementation

- Navigation is presentation-only; private console screens read the same TownBloc instance.
- Pending smelt count remains screen-local and dies when the Smelting route is popped.
- Do not share, cache, or move transaction state into Forge menu state.
- Root menu remains transaction-free. No new work verb is rendered.
- Tavern affordability is recomputed from current `town.gold` each build. It informs but never disables or short-circuits `_ask`.

## Locked decisions

- Exact route keys/titles/details, console titles, and child ownership are fixed by `../PLAN.md`.
- Forge has only Smelt and Temper transaction paths.
- Existing materials, purse, notice, illustration, price, refusal, and dispatch facts remain authoritative.
- Tavern still has exactly one offer and keeps the press-to-refuse behavior.
- No mock Tavern verb and no additional production art is introduced.

## Executor discretion

- Private navigation/helper method names.
- Whether repeated console header widgets are a small private helper inside `forge_screen.dart`, provided no state or behavior moves into it.
- Test helper factoring for entering a Forge route.

## Focused proof and hygiene

From `packages/app`:

```sh
dart format lib/town/forge_screen.dart lib/town/tavern_screen.dart test/widget/craft_rooms_test.dart test/widget/tavern_screen_test.dart test/widget/town_illustration_test.dart test/style/material_palette_test.dart
flutter test test/widget/craft_rooms_test.dart test/widget/tavern_screen_test.dart test/widget/town_illustration_test.dart test/style/material_palette_test.dart
dart analyze lib/town/forge_screen.dart
dart analyze lib/town/tavern_screen.dart
dart analyze test/widget/craft_rooms_test.dart
dart analyze test/widget/tavern_screen_test.dart
dart analyze test/widget/town_illustration_test.dart
dart analyze test/style/material_palette_test.dart
```

Green requires zero relevant failures and both old transaction paths proved through the new navigation.

## Escalate when

- preserving a transaction requires a core/content/BLoC event change;
- the same TownBloc cannot be retained through the planned private routes;
- the poor Tavern press no longer produces the existing refusal through current `buyRumor`/bloc behavior;
- moving the pending dial into Smelting changes its clamp/reset or causes persistence beyond that route;
- the menu/console split requires removing the existing illustration or inventing a third work verb;
- repository source no longer matches the planned symbols or earlier tasks changed these seams incompatibly.

## Handoff state and receipt

Return:

- files changed;
- Red failures and Green command results;
- confirmation of exactly two Forge routes, root transaction absence, same-bloc navigation, unchanged Smelt/Temper outcomes, Tavern affordable/poor cues, poor refusal, and successful paired transaction;
- any deviation/escalation (otherwise `none`).

Task 04 starts from this complete presentation/transaction handoff.
