# Task 02 — Town, Character, Spells, and Pack cutover

## Starting condition

- Read `../CONTRACT.md`, `../PLAN.md`, and this capsule.
- Repository precondition: the current checkout contains Task 01's public `FramedRow` and `town_style.dart::ItemRow` composition, and the Task 01 focused proof named in `01-shared-framed-row.md` was accepted by Main. This task depends on that repository state, not on any prior executor conversation; escalate if the symbols are absent or materially different.
- Do not redesign the API, preserve a second row anatomy, commit, push, publish, add assets, or edit core/content/save/dungeon code.

## Behavioral slice

Migrate every named town destination, Character route, known-spell row, and Pack item row to the shared grammar; represent Character mana as capacity; add identity-safe locked-spell presentation; and replace stock Pack chips while preserving Pack selection and actions.

This is one cutover boundary. A partial handoff would leave the contract's named consumers on two production grammars, so complete and prove all four proof clusters before returning.

## Exact ownership

Production:

- `packages/app/lib/town/town_screen.dart`
  - replace all seven `_Door` uses with keyed whole-row `FramedRow`s;
  - keep labels, purpose strings, order, callbacks, `_open`, and keys unchanged;
  - delete `_Door` completely.
- `packages/app/lib/town/character_screen.dart`
  - replace the four padded `FilledButton` route blocks with keyed whole-row `FramedRow`s using the same labels/callbacks and empty medallions;
  - replace the Mana `ResourceMeter` with `LabelledValue(label: 'Mana capacity', value: '$mana')`;
  - remove `characterManaMeterKey`; keep the Health meter unchanged.
- `packages/app/lib/game/spell_row.dart`
  - make `SpellRow` compose `FramedRow` while preserving its public spell/style/detail/reason/trailing inputs;
  - school marking is medallion content; title and detail order follow `../PLAN.md`;
  - keep `knownSpellsInOrder` and `effectOf` unchanged.
- `packages/app/lib/town/spells_screen.dart`
  - render `KNOWN SPELLS` and `LOCKED SPELLS` headings;
  - compute `lockedCount` from `spellsById.length - known.length` without enumerating unknown spell data into widgets;
  - when positive, render one empty-medallion `FramedRow` titled `1 spell remains locked` or `<N> spells remain locked`, with only `Unknown until learned.` as detail;
  - at zero, render `NothingHere('No spells remain locked.')`;
  - retain the existing known-empty sentence under `KNOWN SPELLS`.
- `packages/app/lib/game/pack_screen.dart`
  - add private `_PackFilterControl` with the exact state grammar in `../PLAN.md` and preserve all six existing filter keys;
  - remove every `ChoiceChip`/`Chip` use from Pack;
  - change `_allSections` so empty item sections emit neither heading nor apology; Materials always emits its heading and `MaterialRows`;
  - keep `_itemSection` heading plus its one concise empty sentence when explicitly selected;
  - replace `_PackItemRow`'s bespoke layout with `FramedRow`, preserving `pack-stack-*`, detail order, and every action key/callback; place the current primary action (when present) before Drop in a vertical 104 dp trailing column so two actions never squeeze the title column.

Proof migrations:

- `packages/app/test/widget/town_shell_test.dart`
- `packages/app/test/widget/character_screen_test.dart`
- `packages/app/test/widget/pack_screen_test.dart`
- `packages/app/test/style/material_palette_test.dart`

Do not add a source-text or widget-class pin except the contract-level negative assertion that Pack contains no `ChoiceChip` or `Chip`.

## Red proof first

Update/add behavioral assertions before production edits.

Town:

- retain all seven labels, purposes, keys, order, destinations, bloc propagation, and 600 px reachability;
- for each destination, find a 44×44 empty medallion host and assert no placeholder content;
- assert `_Door`-specific widget assumptions are removed rather than repinned.

Character/Spells:

- assert `Mana capacity <N>` is visible through `LabelledValue`, no Mana `LinearProgressIndicator` is present, and Health remains a live meter;
- retain four route keys, destination screens, and TownBloc identity;
- known spells retain current school/name ordering, detail, and no action;
- assert `LOCKED SPELLS` exists, the count summary is correct, every unavailable spell name is absent from text and semantics, and the locked-summary subtree contains only the generic count plus `Unknown until learned.` rather than identity-bearing school/cost/effect data;
- assert the all-known case reads `No spells remain locked.`.

Pack:

- rewrite `_filter` helpers to read selected/enabled semantics and rendered state rather than cast to `ChoiceChip`;
- assert all six keys, selected checkmark, armed border/weight/fill, and selected semantics;
- assert no `ChoiceChip` or `Chip` exists;
- with empty inventory in `All`, assert WEAPONS/ARMOUR/POTIONS/BOOKS headings and all four apology sentences are absent, while MATERIALS and every zero-inclusive material row remain;
- after selecting an empty item category, assert that category heading and exactly its concise empty sentence appear;
- retain category order, stacking, no-turn/transient state, no-navigation mutation, and every Drink/Read/Wear/Drop success/refusal assertion.

Expected Red: old Character renders a full Mana meter; Spells lacks the locked section; Pack still contains `ChoiceChip` and repeated empty sections; named rows lack the shared medallion/frame geometry.

## Green implementation

Implement only the migrations above.

- Use the shared primitive directly or through the already-approved `ItemRow`/`SpellRow` adapters; do not copy its frame/medallion layout.
- A locked summary may use only count plus the exact generic sentence. Do not build hidden/offstage widgets from unknown spell objects.
- `_PackFilterControl` state is local presentation state; do not dispatch to GameBloc/TownBloc.
- Keep selected-filter reset on route reopen and retention across in-place town Pack state changes exactly as current tests require.
- Preserve existing action widgets/keys and refusal calculation; only their row container changes.

## Locked decisions

- Every label, route, category, ordering rule, and item action remains current game truth.
- Mana is capacity-only and has no invented current value.
- Locked spell identities are absent from render and semantics, not merely obscured.
- `All` omits empty item sections; explicit empty filters retain one concise message; Materials is always complete and zero-inclusive.
- Pack has no stock `ChoiceChip` or `Chip`.
- No new route, transaction, action, content, or asset is introduced.

## Executor discretion

- Private helper extraction inside the named files.
- Whether the selected `✓` and label use one `Row` or text spans, provided pixels and semantics meet the locked state grammar.
- Test helper factoring and fixture reuse.

## Focused proof and hygiene

From `packages/app`:

```sh
dart format lib/town/town_screen.dart lib/town/character_screen.dart lib/game/spell_row.dart lib/town/spells_screen.dart lib/game/pack_screen.dart test/widget/town_shell_test.dart test/widget/character_screen_test.dart test/widget/pack_screen_test.dart test/style/material_palette_test.dart
flutter test test/widget/town_shell_test.dart test/widget/character_screen_test.dart test/widget/pack_screen_test.dart test/style/material_palette_test.dart
dart analyze lib/town/town_screen.dart
dart analyze lib/town/character_screen.dart
dart analyze lib/game/spell_row.dart
dart analyze lib/town/spells_screen.dart
dart analyze lib/game/pack_screen.dart
dart analyze test/widget/town_shell_test.dart
dart analyze test/widget/character_screen_test.dart
dart analyze test/widget/pack_screen_test.dart
dart analyze test/style/material_palette_test.dart
```

Green requires zero relevant failures, including existing action/route transaction assertions.

## Escalate when

- deriving the locked count requires changing content APIs or rendering any unavailable spell identity;
- a named route/category/action cannot preserve its current callback or bloc identity through `FramedRow`;
- the six custom filter controls do not fit the repository phone fixture at current text scale;
- the shared row geometry causes an unreachable seventh town destination or Pack overflow;
- a test can pass only by changing gameplay, wording authority, save state, or unknown-spell secrecy;
- Task 01 API or repository symbols differ materially from the plan.

## Handoff state and receipt

Return:

- files changed;
- Red failures and Green command results by Town, Character/Spells, and Pack cluster;
- explicit confirmation of seven town routes, four Character routes, mana-capacity presentation, locked identity absence, custom filter semantics, `All`/explicit-empty behavior, and unchanged Pack actions;
- any deviation/escalation (otherwise `none`).

Task 03 starts only after all named consumers in this capsule are Green on the shared grammar.
