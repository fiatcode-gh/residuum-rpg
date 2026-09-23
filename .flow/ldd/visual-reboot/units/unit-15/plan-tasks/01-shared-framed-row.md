# Task 01 — Shared framed row

## Starting condition

- Read `../CONTRACT.md`, `../PLAN.md`, and this capsule before editing.
- Start from application source matching base `4033de53f96470bfc75dabba6b28bc0ae67816a6`; only approved earlier ledger changes and this plan may already be dirty.
- This task has no production-task dependency. Do not edit another U15 task's files except the shared files listed below.
- Do not commit, push, publish, add assets, or edit core/content/save/dungeon code.

## Behavioral slice

Introduce the single stable framed-row geometry and make the existing merchant/bank/Tavern `ItemRow` adapter consume it. The handoff is valid when the empty medallion is measurable without placeholder content and the existing item/offer transactions still behave through the same callbacks.

## Exact ownership

Production:

- `packages/app/lib/style/surfaces.dart`
  - add `FramedRow` with the exact constructor and geometry in `../PLAN.md`.
- `packages/app/lib/town/town_style.dart`
  - replace `ItemRow.build`'s bespoke Padding/Row layout with `FramedRow` composition;
  - add `List<String> details = const []` to `ItemRow`;
  - pass the current `marking` as centered text inside the medallion;
  - pass `name` as title, `details` followed by a disabled `reason` as detail lines, and the current 104 dp themed `FilledButton` as trailing content;
  - preserve `action`, `onPressed`, keys, text, and enabled/refusal semantics.

Proof:

- create `packages/app/test/widget/framed_row_test.dart`;
- update no other test merely to pin implementation. Existing tests listed below are behavioral regression proof and should remain behavior-oriented.

## Red proof first

Add focused widget cases before production code:

1. Pump one empty and one marked `FramedRow`, each with a distinct `medallionKey`. Assert both hosts are exactly 44×44 dp, their left/top alignment matches, the inner well is 36×36 dp with transparent fill and a `rule`/`hairline` circular border, and the empty host contains no `Image`, `Icon`, or `Text`.
2. Assert the outer rendered surface uses `panel`, `rule`/`hairline`, radius 6, and no elevation.
3. Tap a whole-row instance and assert its callback fires once and button/enabled semantics are present; assert a null-callback row has no button semantic.
4. Pump an `ItemRow` with a normal detail and a disabled reason. Assert detail order, action text, reason visibility only while disabled, and that tapping an enabled instance calls exactly the supplied callback.

Expected Red: `FramedRow` does not exist and `ItemRow` cannot accept `details`; once the API compiles, old `ItemRow` geometry still fails the framed-row assertions until Green.

## Green implementation

Implement only the API/geometry locked in `../PLAN.md`.

- Keep all row measurements derived from existing U14 constants plus the explicit 8/6/36 dimensions in the plan; do not add token/theme policy.
- The medallion host always exists. A null child stays transparent and empty.
- Do not apply `ColorFiltered`, tint, opacity, or a fallback glyph to medallion content.
- Use Material/InkWell only for whole-row `onPressed`. Static rows with trailing controls must not gain a second tap target or button semantic.
- Keep `ItemRow` as the narrow town-domain adapter; do not create a second general row component.

## Locked decisions

- Public API, dimensions, padding, styles, border/fill, null fallback, and ownership are exactly those in `../PLAN.md`.
- Existing merchant, bank, and Tavern callsites remain source-compatible in this task.
- Existing transaction callbacks and refusal conditions do not move into `FramedRow`.
- No authored asset or placeholder is introduced.

## Executor discretion

- Private helper names and whether the internal surface is expressed as `Material` plus `InkWell` or equivalent Flutter composition.
- Test helper structure and matcher factoring.
- Dartdoc wording that faithfully records the locked contract.

## Focused proof and hygiene

From `packages/app`:

```sh
dart format lib/style/surfaces.dart lib/town/town_style.dart test/widget/framed_row_test.dart
flutter test test/widget/framed_row_test.dart test/widget/merchant_screen_test.dart test/widget/bank_screen_test.dart test/widget/tavern_screen_test.dart
dart analyze lib/style/surfaces.dart
dart analyze lib/town/town_style.dart
dart analyze test/widget/framed_row_test.dart
```

Green requires zero relevant failures and preservation of merchant/bank/Tavern callback behavior. Inspect the resulting files after formatting and confirm `ItemRow` has no independent outer row geometry.

## Escalate when

- 44×44 host plus 36×36 well cannot fit an existing named consumer without overflow on the repository phone fixture;
- Flutter semantics create two active buttons for a static row with a trailing action;
- an existing merchant/bank/Tavern behavior test requires changing transaction behavior or wording to pass;
- the planned API would require a token/theme, asset, model, content, or save change;
- repository source no longer matches the named symbols or another task has edited these files.

## Handoff state and receipt

Return a compact receipt with:

- files changed;
- Red failure observed and Green command results;
- exact `FramedRow` API/geometry delivered;
- confirmation that merchant, bank, and Tavern behavior suites passed;
- any deviation or escalation (otherwise `none`).

The repository handed to Task 02 must compile with `FramedRow` public from `style/surfaces.dart` and `ItemRow` already composing it.
