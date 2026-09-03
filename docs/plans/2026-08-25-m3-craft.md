# Implementation plan — M3C `m3-craft`

Spec: `docs/epic/m3-craft-spec-M3C.md` (gitignored, cited by absolute path in the
report). Base: `m3-craft` @ `83b5336`.

## Baseline, measured

| suite | command, from its package dir | green |
|---|---|---|
| core | `dart test` | 657 |
| content | `dart test` | 472 |
| app | `flutter test` | 441 |
| | **total** | **1570** |

Band lines, verbatim:

```
survivability: 20/40 won (50.0%), stalled 0, died at 1:1 2:6 3:6 4:7 5:20
greedy build: 20/40 won; fleetfoot-first build: 14/40 won
sea-cave: 30/40 won (75.0%), stalled 0, died at 2:1 3:8 4:13 5:9 6:9
ruined keep: 25/40 won (62.5%), stalled 0, died at 1:4 2:5 3:4 4:2 5:13 6:6 7:6
```

## Declared deviations

| # | Deviation | Reason |
|---|---|---|
| D1 | `GatherKind, not`NodeKind`; file`craft/gather_node.dart` | `core.dart` already exports `NodeKind { town, dungeon }`. A second one is an ambiguous export — a compile error in all three packages. Field `nodes, salt`gatherSalt, event `NodeGathered` unchanged. |
| D2 | `temperItem`/`smeltOre`/`brewPotion` live in `town/town.dart`; `craft/` holds rules and data only | `temperItem` needs `_dressed` and `_find, both private to town.dart, and`Transacted` is declared there. Refusals live in `craft/` so widgets can read them without importing the town layer (the `readRefusal` precedent). |
| D3 | One `craft/craft.dart` for smelt and brew, not two files | Eight lines each, one concern. Duplicate twice before extracting. |
| D4 | `trainedIn` added to `skills/skill.dart`; `step.dart`'s `_train` delegates to it | The grant rule gets one copy. Town training needs the same rule without an event list. |
| D5 | Town-side level-up notice derived in `TownBloc, not carried through`Transacted` | Keeps `Transacted` at two elements. The training is core's and unit-testable there; the sentence is the app's, beside every other sentence. |
| D6 | Node counts and placement in a new `content/lib/src/gathering.dart` | Both floor builders call it, so the shared helper needs a neutral home. `dungeons.dart` is 375 lines and is about dungeon identity. |
| D7 | Node band `1..3` per floor, not `0..2` | Tuning trail. |
| D8 | `sellPriceOf` temper term is `temper * 2, not`* 3` | Arithmetic: `worth` weights `attackMin + attackMax + armor * 2, and one temper tier adds exactly 2 to that sum either way (+1/+1 on a weapon, +1 armour doubled).`* 3` prices a tempered item above what the same stats cost by any other route, and makes a `+1` temper on a Legendary net gold. Trail records the check. |

## Phases

Every phase is red → green → refactor per behaviour, exits with all three suites
green, and is one conventional commit.

### 1 — capture the version-2 refusal fixture

No production change. `version_gate_test.dart` gains `_versionTwoTown, the exact
current`_goldenTown` string from `golden_save_test.dart, plus a test that this
build still *accepts* it. Commit order is the proof the fixture predates the
codec: phase 8 flips that test to a refusal.

### 2 — the two skills

* `herbcraft,`blacksmith` appended after `binding`;`untrainedSkills` grows to
  nine; the enum dartdoc's owed list shrinks to four.
* `trainedIn(skills, skill)` added (D4); `_train` delegates.
* Red first: `skill_test.dart`'s `values.skip(4)` and the two stale names.
* `_skillName` in `event_messages.dart` is an exhaustive switch — a compile
  error is the tripwire, and it gets `Herbcraft`/`Blacksmith` arms.
* Goldens are NOT touched here; the skills blocks move in phase 8 with the
  version bump, so this phase leaves the codec writing seven and reading nine.
  **That cannot ship half-done** — the golden tests redden the moment the enum
  grows, so phases 2 and 8 land in one commit if the suite cannot be green
  between them. Decided at implementation time by running the suite; if red,
  phase 2 is folded into phase 8.

### 3 — materials as counters

* `craft/material.dart`: `MaterialId { ore, ingot, herb }` with `word` and
  `marking` (`◆` / `▮` / `✿`).
* `Profile.materials,`GameState.materials, both unmodifiable, both in
  `copyWith` (GameState's gold is not in `copyWith`; materials must be, because
  gathering moves them mid-run).
* `startRun`/`endRun`/`suspendRun`/`resumeRun` carry them; the death path clears
  them beside gold and inventory.
* Tests: markings distinct; all four doors; cleared on death; not banked.

### 4 — nodes on the floor

* `craft/gather_node.dart`: `GatherKind { oreVein, herbPatch }` with `glyph`
  (`*` / `"`), `marking,`word, `yields`.
* `Floor.nodes,`FloorMemory.nodes, `GameState.nodes, all
  `Map<Position, GatherKind>`.
* `content/lib/src/gathering.dart`: `gatherSalt = 0x6A1E, the per-dungeon bands,
  and`gatherNodesOn(...)` — placed from `Rng(floorSeed(...) ^ gatherSalt)` over
  the tiles where `tileAt == Tile.floor` and the tile is not the hero spawn,
  walked row-then-column. Called as the LAST statement of `buildFloor` and
  `themedFloor, after every existing draw, on a generator of its own.
* Tests: same seed → same nodes; a different `gatherSalt` → different nodes;
  **map bytes, monsters, litter, hero spawn and stairs identical with nodes
  present vs. the pre-change values** (the load-bearing control); never on
  stairs or the spawn; the salt disjointness sweep; the glyph collision test
  extended; every `GatherKind` yields a real `MaterialId`; every dungeon has a
  band and every depth of it rolls inside the band.

### 5 — `GatherAction`

* `GatherAction()` in `action.dart`; `NodeGathered` in `event.dart`.
* `_refuse` arm: `'there is nothing here to gather'`.
* Dispatch arm: counter +1 (flat, no draw), node removed for the rest of the
  run, `NodeGathered` emitted, the matching skill trained, turn passes.
* `_snapshot`/`_built`/`_arriveOn` carry `nodes` beside `groundItems`.
* Tests: effect and refusal and depletion and training per kind; **no draw** —
  `rng.state` and `lootRng.state` unchanged across a gather; suspend/resume
  round-trips nodes and materials roll for roll.

### 6 — temper on `Item`

* `Item.temper` (int, default 0); `attackMin`/`attackMax` add it for weapons, `armor` adds it for armour; `maxHp`/`speed` untouched; `props` gains it;
  `Item tempered(int temper)` added.
* `statLine` gains `‡+N temper`; `stackKey` gains temper; `wornDeltas` sees it
  through the getters already.
* `sellPriceOf` gains `item.temper * 2` inside `worth` (D8).
* Tests: both stat ends; armour; potions and books unmoved; props and stackKey
  separation; the worn-delta; the price term; the no-arbitrage test stays green;
  `marketTable` carries no materials (exclusion pinned).

### 7 — the craft rules and the three transactions

* `craft/temper.dart`: `maxTemper = 3, the gate table (Blacksmith 0 / 5 / 10),
  the cost table (1 ingot + 10 gold / 2 + 25 / 3 + 50), and`temperRefusal`
  returning the sentence or null — readable by the widget.
* `craft/craft.dart`: `smeltCost = 2,`brewCost = 3, `smeltRefusal,`brewRefusal`.
* `town.dart`: `smeltOre,`brewPotion, `temperItem` — the last through
  `_dressed, with the dartdoc sentence contract 6 asks for. No clamp test:
  temper never reaches`maxHp, so a clamp test could not fail.
* Tests: every refusal sentence; the ceiling; the gates by level; the ingot and
  gold debits; carried AND equipped; the pack-cap sentence for brewing, in
  `buyItem`'s exact words; brewed-id uniqueness across brew/drop/brew.

### 8 — save version 3

* `item_codec`: `temper, required, always written.
* `profile_codec`: `materials` (sorted by enum order), `brewNumber`.
* `run_codec`: `materials`; each floor block and the active floor get `nodes,
  sorted`byRowThenColumn`.
* `saveVersion = 3`; the "last break" dartdoc replaced with follow-up 20's rule.
* The three goldens rewritten **by hand**, old strings quoted in the commit
  message and in the report with a structural added/changed key diff.
* `version_gate_test`: phase 1's fixture flips to a refusal; the v1 fixture test
  stays green; `'this build writes version three'`.

### 9 — the two pins item 11 asks for

* A profile differing only in Blacksmith/Herbcraft levels rolls a higher road
  tier (craft levels DO tax roads).
* `heroMaxMana` is unchanged by craft levels, pinned in `mana_test.dart`.

### 10 — the crawl screens

`game_bloc` (`GatherPressed,`canGather, `nodeUnderfoot, materials on the
view state),`game_screen` (one control, labelled `Mine` or `Gather` by kind,
shown only on a node — watch the row width), `glyph_grid` (a node pass between
terrain and items, its own painter constant, not a palette field), `event_messages`(`NodeGathered` arm), `inventory_screen` (Materials panel, fixed
order, marking + word + count; nine skill rows).

### 11 — the town screens

`forge_screen,`alchemist_screen, two more doors in `town_screen` (the "five
doors" dartdoc updated; the column already scrolls), three `town_bloc` events
and handlers **on the `_settled` carry-forward list**, the level-up notice (D5),
Materials rows on the town screen, temper in `item_presentation`'s dead-row
reasons via `temperRefusal`.

### 12 — verification

Mutation rows 1–12 on committed code from the worktree root, reds as named sets,
clean reverts, both halves of rows 1, 5, 6; C1–C5; analyze and format from the
root; the AVD pass with the save-slot copy-aside ritual first; the report mirror.
