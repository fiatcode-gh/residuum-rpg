# Unit 6 — Character, Spells, and Pack Recon

Status: source-verified at `55a226d` on `residuum-visual-reboot-6`; no production code changed.

## Purpose

Unit 6 removes the current duplicated management-page information architecture
without changing the underlying item, spell, equipment, skill, save, or
transaction rules. The approved reboot handoff requires a concise Character
overview, a dedicated grimoire, and a Pack that manages carried objects rather
than reproducing the hero page.

## Source facts

| Fact | Source | Consequence |
| --- | --- | --- |
| `InventoryScreen` is one `ListView` containing derived stats, learned spells with `Cast`, six worn slots, carried items, materials, and every skill. | `packages/app/lib/game/inventory_screen.dart:25-100` | The crawl Pack duplicates hero, spell, equipment, material, and progression information. |
| A carried crawl row still performs real actions: `DrinkPressed`, `ReadPressed`, `EquipPressed`, and `DropPressed`; spell-book refusals are shown beside the only action they refuse. | `packages/app/lib/game/inventory_screen.dart:227-309` | A Pack redesign must retain every existing context-valid item action and its refusal semantics. |
| `CharacterScreen` repeats the town's derived stats, known spells, six worn slots, all carried item sections, materials, and every skill. It dispatches `WearPressed`, `TakeOffPressed`, and `ReadBookPressed`. | `packages/app/lib/town/character_screen.dart:31-104` | Town transactional actions must move with their items, never disappear behind a new presentation route. |
| `SpellRow` already supplies the shared school mark + word, name, cost, optional effect, refusal, and trailing action grammar. | `packages/app/lib/game/spell_row.dart:19-79` | The two spell surfaces must reuse this factual row grammar rather than invent a second spell representation. |
| `packSections` is the existing source of four ordered item categories: Weapons, Armour, Potions, Books. It sorts/merges item stacks and deliberately preserves every category even when empty. | `packages/app/lib/game/item_presentation.dart:63-110` | Unit 6 filters use these real categories; it must not derive categories from mock art or reorder stack semantics. |
| `Profile` has no player-name or portrait field. It carries a hero actor, loadout, skills, known-spell ids, inventory, materials, and economy/run state. | `packages/core/lib/src/town/profile.dart:22-84` | Character cannot add a fictional name, portrait, character level, or mock-only attributes. |
| The crawl Pack is opened from the contextual shelf. Town offers a single `Character` door. | `packages/app/lib/game/game_screen.dart:430-467`; `packages/app/lib/town/town_screen.dart:89-118` | Crawl and town need separate state drivers, but both can expose the same focused information architecture. |
| Unit 3's shelf overflow already exposes every known spell with no prepared-kit restriction. | `.flow/ldd/visual-reboot/units/unit-3/CONTRACT.md:56-75` | Retiring Pack's duplicate learned-spell cast section does not make a spell unreachable. |
| Existing widget tests prove town stat/spell/worn/carried/material/skill facts and `WearPressed`/`TakeOffPressed`/`ReadBookPressed`; crawl tests prove spell refusal/cast and item-category/material facts. | `packages/app/test/widget/character_screen_test.dart`; `packages/app/test/battle_characterization_test.dart`; `packages/app/test/widget/magic_surfaces_test.dart`; `packages/app/test/widget/craft_surfaces_test.dart` | Tests must migrate to consumer-visible routes and retain the real action/refusal assertions instead of pinning the old long-page layout. |

## Design decisions confirmed with the user

1. **Character overview with routes.** Character is a short town hero summary
   with explicit routes for Gear, Spells, Skills, and Pack. It is not a tabbed
   dashboard and not another long management page.
2. **Read-only grimoire.** The dedicated Spells surface is reference-only. In a
   crawl, the Unit 3 shelf and overflow remain the sole spell-cast entry; in
   town no cast action is invented. Pack no longer contains a learned-spell
   section.
3. **Local Pack category filter.** Pack filters only existing source categories:
   All, Weapons, Armour, Potions, Books, and Materials. The filter is local,
   transient presentation state; it is not saved and does not change pack or
   item ordering semantics.

## Derived unit boundary

- Character owns hero overview/navigation only.
- Gear owns the six worn slots and town `Take off` action.
- Spells owns the known-spell reference list only.
- Skills owns the complete skill/progress list only.
- Pack owns carried item and material scanning plus only the actions valid in
  the route's current game/town context.
- `core`, `content`, game rules, save document/version, balance bands, RNG,
  item ids, and the Unit 3 shelf/overflow rules are not Unit 6 work.

## Planning hazards

- Do not add mock-only identity data, attributes, locked spells, favorite
  assignment, or a prepared-kit rule. The source does not support them.
- Do not retain a hidden second learned-spell list merely to preserve the old
  Pack layout. Shelf overflow is the existing exhaustive crawl access path.
- A disabled item action must retain its rule-owned refusal text. Do not
  replace a refusal with unexplained grey styling.
- `PackSection`'s fixed sorting/stacking and `MaterialRows`' zero rows are
  consumer-visible information contracts, not incidental layout.
- The current main head includes the accepted Unit 5 merge (`55a226d` contains
  `0bf6da1`); no Unit 5 branch dependency remains.
