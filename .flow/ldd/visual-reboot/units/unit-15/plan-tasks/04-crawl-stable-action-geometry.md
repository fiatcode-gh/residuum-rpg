# Task 04 — Crawl stable action identity and metadata geometry

## Starting condition

- Read `../CONTRACT.md`, `../PLAN.md`, and this capsule.
- Repository precondition: the current sequential checkout contains the accepted Task 01–03 production state and named focused proofs. This task is otherwise independent of prior executor context and owns only the crawl files below; escalate if the checkout does not match that handoff.
- This task owns only the crawl shelf presentation seams below. Do not edit GameBloc events, core/content, dungeon scene/rendering, camera constants, map allocation, timeline, log, assets, saves, or transactions. Do not commit, push, or publish.

## Behavioral slice

Give crawl actions stable identity independent of display text/count/cost, split changing metadata from the verb label, keep plain `+N` overflow, and preserve measure-all-candidates shortest layout plus armed no-reflow under the legal eleven-action ceiling.

## Exact ownership

Production:

- `packages/app/lib/game/crawl_action_row.dart`
  - add required `String id` and optional `String metadata = ''` to `CrawlAction`;
  - change uniqueness assertion and `_ActionChip` key from label to id;
  - expose semantics as label plus metadata when present;
  - render metadata in `crawlCaption` on its own line/slot;
  - extend `_RowFit` with the common metadata height;
  - update `_fitFor` exactly as specified in `../PLAN.md`: measure every candidate; include widest label word, metadata, and armed caption; reject wrapped metadata/caption and over-line labels; minimize total row height across all legal column counts; retain larger column count on exact ties; keep the full-width fallback;
  - reserve common metadata and armed-caption spacers so arming does not alter chip/row/map geometry.
- `packages/app/lib/game/game_screen.dart::_actionsFor`
  - assign the exact id/label/metadata vocabulary in `../PLAN.md` to every constructor;
  - remove count from Drink/Pack labels and mana cost from spell labels;
  - remove `ActionIcon.more` from overflow and keep visible `+N` only;
  - use `leave-dungeon` for both `Leave` and `Finish` states;
  - change no visibility guard, callback, event, ordering, `readiedSpellCount`, or note.

Proof:

- `packages/app/test/widget/crawl_action_row_test.dart`

No other production or proof file is in this task's normal scope.

## Red proof first

Update the owning widget suite before production edits.

Identity/metadata:

1. In real crawl scenes, find actions by stable keys (`drink`, `pack`, `spell:<id>`, `spells-overflow`, `leave-dungeon`) while separately asserting visible label and metadata text.
2. Assert Drink/Pack labels contain no count, spell labels contain no mana cost, and the plain overflow has no `Image` while still showing `+N`.
3. Pump a minimal `CrawlActionRow` twice with the same id but changed visible label and metadata. Capture the keyed element before/after and assert it is retained while text updates; this proves key identity is not derived from either field.
4. Assert duplicate ids trip the debug uniqueness assertion even when labels differ; distinct ids with equal labels are permitted by the row model.
5. Assert combined semantics includes both verb and metadata for a screen reader.

Protected geometry/behavior:

6. Update existing locators from label keys to id keys, but keep behavior assertions: exactly one row, Drink/Wait uniqueness, common width/height, icon over word, disabled readability, and event dispatch.
7. Preserve the armed test: second tap disarms through existing behavior; armed caption and heavier border appear; dungeon map rectangle is byte-for-byte equal in geometry before/after arm and disarm.
8. For exploration worst, combat typical, split-word, 1.3× text, and worst legal combat, keep `_expectLegalRow`, `_expectRunCapacity`, every-candidate/shortest behavior, and the current hard caps `<= 360`, `<= 450`, and `<= 600` dp respectively. Do not raise the 600 dp ceiling.
9. In worst legal combat assert exactly eleven stable action keys, `readiedSpellCount == 3`, plain overflow, and no `flee` action. Retain the one-extra-run bound for the longer legal verb.
10. Keep the game-over Drink action visible with icon/word/metadata and inert callback.

Expected Red: current widget keys are composed labels, metadata is embedded in labels, overflow still has an icon, and `CrawlAction` cannot express stable id/metadata separately.

## Green implementation

- Apply the exact id table from `../PLAN.md`; do not derive ids by lowercasing or otherwise transforming visible labels.
- Keep spell ids namespaced as `spell:<spell.id>`.
- Preserve action ordering and guards verbatim; only constructor presentation fields change.
- Measure metadata using the same `crawlCaption` object that renders it.
- Dispose every `TextPainter` created by the measurement pass.
- Continue measuring all column counts from `crawlChipMaxColumns` down to one and choose the minimum total height. A first legal candidate is not sufficient.
- Keep the same common icon envelope even for no-icon/plain overflow chips.
- Do not touch the 36 dp camera cell or `Expanded` map code.

## Locked decisions

- Public `CrawlAction` fields, stable id vocabulary, visible labels, metadata strings, overflow treatment, and semantics are fixed by `../PLAN.md`.
- The action ceiling is eleven and readied spell count remains three.
- Arming changes no row height or map allocation.
- Map-first melee and target-spell dispatch remain unchanged.
- The worst legal chrome ceiling remains 600 dp; no truncation, ellipsis, broken word, hidden action, or smaller camera cell may buy space.

## Executor discretion

- Private painter/helper factoring inside `crawl_action_row.dart`.
- Exact local variable names and whether metadata spacer rendering is a helper widget.
- Test helper factoring, provided tests exercise rendered geometry and behavior rather than source strings.

## Focused proof and hygiene

From `packages/app`:

```sh
dart format lib/game/crawl_action_row.dart lib/game/game_screen.dart test/widget/crawl_action_row_test.dart
flutter test test/widget/crawl_action_row_test.dart
dart analyze lib/game/crawl_action_row.dart
dart analyze lib/game/game_screen.dart
dart analyze test/widget/crawl_action_row_test.dart
```

Green requires zero relevant failures. Record the measured exploration-worst, combat-typical, and combat-worst-legal heights printed by assertion diagnostics or a temporary test log, then remove any temporary logging before handoff.

## Escalate when

- the separated metadata cannot remain under 600 dp at worst legal density without changing a protected action, label, camera cell, map allocation, or font role;
- a legal label/metadata/caption has no fitting candidate at the phone width or 1.3× text scale;
- retaining element identity would require state ownership beyond `CrawlAction.id`/Flutter keys;
- preserving the planned id table conflicts with two simultaneously visible actions;
- any existing dispatch, arm/disarm, map-first, visibility, or note behavior would have to change;
- another task or repository revision has changed the owning seams.

## Handoff state and receipt

Return:

- files changed;
- Red failures and Green command results;
- exact measured three chrome heights;
- confirmation of stable keys under label/metadata changes, plain overflow, eleven-action worst legal row, no crawl Flee, measure-all-candidates behavior, 1.3× legality, and unchanged map rectangle while arming/disarming;
- confirmation that dungeon/camera/map files were untouched;
- any deviation/escalation (otherwise `none`).

Main then owns final app-wide formatter/analyzer/full-suite gates and target-phone colour/greyscale evidence from `../PLAN.md`.
