# Unit 15 source recon

Reconciled at `4033de53f96470bfc75dabba6b28bc0ae67816a6` on 2026-09-22.
The codebase-memory index is ready; all listed paths report matching metadata
with no recorded coverage issue. Source files and current widget tests were
read directly.

## Shared seams

- `packages/app/lib/style/tokens.dart` owns the U14 surface/value authority:
  `panel`, `raised`, `recessed`, `armedFill`, `rule`, `radius == 6`,
  `hairline == 1`, `tapTarget == 44`, and text roles.
- `packages/app/lib/style/surfaces.dart` owns only `ResourceMeter` and
  `LabelledValue`; no framed row or filter primitive exists.
- `packages/app/lib/town/town_style.dart` has a bespoke `ItemRow`, `Commit`
  over `FilledButton`, and `TownRoom`. It is the natural town-side shared
  primitive seam, but its current item mark column is an accessibility fact,
  not decoration to discard.

## Consumer facts

- `town_screen.dart` has seven `_Door` `TextButton`s and passes each real
  route through `_open`; their labels and purposes are current game truth.
- `character_screen.dart` has four `FilledButton` routes and renders
  `ResourceMeter(value: mana, ceiling: mana)`. `TownViewState` has capacity
  only at this surface; capacity must become a non-fill presentation.
- `spell_row.dart` is an unframed mark/title/detail row shared with spell
  presentation. `spells_screen.dart` lists known spells only; adding a locked
  section must not enumerate or name unknown spells.
- `game/pack_screen.dart` owns both crawl and town-pack content. Its six
  `ChoiceChip` filters key by `pack-filter-<filter>`, its `All` view emits
  `NothingHere` for each empty item category, and `_PackItemRow` has a private
  mark/title/detail/action anatomy. `town/pack_screen.dart` only supplies its
  existing TownBloc callbacks.
- `forge_screen.dart` owns one screen with a smelting `CountStepper` + `Smelt`
  commit and `_TemperRow` transactions. There is no Craft action.
- `tavern_screen.dart` offers exactly `Ask about the roads` via `ItemRow` and
  calls the current `buyRumor` result into both TownBloc and WorldBloc.
  `tavern_screen_test.dart` proves a poor hero receives `you cannot afford
  that` and a successful purchase spends gold and reveals one destination;
  presentation must retain that press/refusal contract.
- `crawl_action_row.dart` keys both uniqueness and widgets by composed
  `label`; `game_screen.dart` composes labels with potion counts, inventory
  counts and spell mana costs. `_fitFor` measures all column candidates and
  reserves `— armed` caption height across armable rows. Stable identity may
  change, but that measurement/selection and no-reflow property are protected.

## Current proof seams

- `test/widget/crawl_action_row_test.dart` stages exploration, typical combat,
  worst legal combat and armed states; it owns legal wrapping/run capacity and
  chrome-height proof.
- `test/widget/pack_screen_test.dart` owns filter selection semantics,
  category order, no-turn navigation and item action behavior; it currently
  asserts the `ChoiceChip` implementation and must move to observable selected
  semantics.
- `test/widget/tavern_screen_test.dart` owns exhausted/offered states, notice
  ordering, refusal and the successful two-bloc transaction.
- `test/widget/craft_rooms_test.dart`, `test/widget/character_screen_test.dart`,
  town-shell/illustration tests and `test/style/material_palette_test.dart`
  protect the remaining route, transaction, room-order and themed-control
  behavior. Presentation-literal assertions need behavior-oriented rewrites,
  not new implementation pins.

## Planning consequences

The external four-task ordering remains viable: shared primitive first,
town/Character/Spells/Pack consumers second, Forge/Tavern third, crawl shelf
last. It is strategy only: the execution plan must determine exact primitive
APIs, test migrations, whether Forge's menu split preserves every existing
reachable transaction, Tavern's non-destructive affordability cue, and the
specific stable action-id vocabulary.
