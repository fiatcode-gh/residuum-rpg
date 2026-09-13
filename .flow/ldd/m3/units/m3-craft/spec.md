# Story spec — M3C `m3-craft`: gathering, forge, alchemist, tempering

Decisions: D20 (unit split), D59 (forks locked). Recon: `m3-craft-recon.md`.
Base: `main` @ `83b5336, 1570 tests green, four band lines verbatim (D58).

## Goal

The hero can mine ore veins and gather herb patches found in dungeons
(training Blacksmith and Herbcraft — the last two skills this milestone
owes), carry the materials home as counters, and spend them in two new town
rooms: the Forge (smelt ore into ingots; temper a found item's stats by
+1/+2/+3 tiers, gated by Blacksmith level, costing ingots and gold) and the
Alchemist (brew herbs into healing potions). Crafting serves loot and never
competes with it (the section 7.1 guard): nothing is forged from nothing,
and best-in-slot stays a found item you invested in. **All four band lines,
the merchant shelf golden, the crypt layout goldens, and both rng-state pins
return byte-identical** — nothing in this unit touches a drop table, a
weight total, or the combat/loot streams. Save format bumps to version 3
(D59); every pre-M3C save is refused; the "last break" finality claim is
retired from the codec's dartdoc.

## Shape — precedents to follow, read from this codebase

- **A counter the hero carries and death takes:** `gold` — on `Profile` AND
  `GameState, copied at the run-boundary doors, zeroed on the death path
  (`run_boundary.dart:123`), shown as labelled rows. `materials` mirrors it.
- **Per-floor state that suspends and resumes:** `groundItems` — on
  `GameState, `FloorMemory, and `Floor, snapshotted/restored at
  `_snapshot`/`_built`/`_arriveOn` (`step.dart:727-814`). `nodes` mirrors
  it field for field.
- **A separate salted stream that cannot disturb existing draws:**
  `lootSaltFor`/`dungeonSalt` + the purpose-slot registry
  (`dungeons.dart:121-143, `new_game.dart:8-14`), disjointness pinned at
  `dungeons_test.dart:60` and `world_test.dart:893`.
- **An underfoot action, refused not blocked:** `PickUpAction`
  (`step.dart:402-407`); the two-tier refusal is `AscendAction`'s shape.
- **A shared refusal rule readable by widgets:** `readRefusal` called
  directly from `gear_screen.dart:71-77` for dead-row reasons.
- **A town transaction:** `restAtInn`/`buyItem`/`readBook`
  (`town.dart`), returning `Transacted, refusing in sentences, threaded
  through `_transacted`/`_settled` in `town_bloc.dart` (mind the
  carry-forward list — its dartdoc warns that forgetting it erases camps).
- **Equip-path hp re-clamp:** `_dressed` (`town.dart:161-167`).
- **The sanctioned save reshape:** M3M/campDay — strict decoders, goldens
  rewritten by hand with old strings quoted, refusal fixture captured
  BEFORE the rewrite.
- **Category without hue:** `Rarity` marking + word; `DamageType`
  marking + word (M3M).

## New files

- `packages/core/lib/src/craft/material.dart` — `MaterialId` (ore, ingot,
  herb) with marking + word.
- `packages/core/lib/src/craft/node.dart` — `NodeKind` (oreVein,
  herbPatch) with glyph, marking, word, and the material each yields.
- `packages/core/lib/src/craft/temper.dart` — `temperRefusal, the tier
  gates, cost table, and `maxTemper = 3`.
- `packages/core/lib/src/craft/smelt.dart` and `brew.dart` — the two
  conversion rules (or one `craft.dart`; pre-declare the split).
- `packages/app/lib/town/forge_screen.dart, `alchemist_screen.dart`.
- Content: node counts per dungeon/depth (ride the existing per-dungeon
  files or a new `gathering.dart` — pre-declare).
- Tests per behavior as listed in the test plan.

## Changed files (exact; anything else is a pre-declared deviation)

- `packages/core/lib/src/skills/skill.dart` — `herbcraft, `blacksmith`
  APPENDED after `binding`; `untrainedSkills` grows to 9; the dartdoc's
  still-owed list shrinks to four.
- `packages/core/lib/src/engine/action.dart` — `GatherAction()` (one
  action; the node kind underfoot decides mining vs gathering — if the
  worker prefers two actions, pre-declare).
- `packages/core/lib/src/engine/step.dart` — the dispatch + `_refuse`
  arms; nodes snapshot/restore beside `groundItems`.
- `packages/core/lib/src/engine/game_state.dart` — `materials`
  (`Map<MaterialId, int>`), `nodes` (`Map<Position, NodeKind>`), both
  unmodifiable, both in `copyWith`.
- `packages/core/lib/src/engine/event.dart` — `NodeGathered`.
- `packages/core/lib/src/engine/actor.dart` — untouched (nothing here).
- `packages/core/lib/src/dungeon/floor.dart, `floor_memory.dart` —
  `nodes` field each.
- `packages/core/lib/src/loot/item.dart` — `Item.temper` (int, default 0):
  weapons add `temper` to `attackMin` and `attackMax`; armour adds
  `temper` to `armor`; `maxHp`/`speed` untouched; `props` gains it; a
  `copyWith`-equivalent for tempering (Item has none today).
- `packages/core/lib/src/town/profile.dart` — `materials` + `brewNumber`
  (or the worker's id-uniqueness mechanism — pre-declare) + `props`.
- `packages/core/lib/src/town/run_boundary.dart` — `materials` through
  the four doors; death clears them WITH gold and inventory.
- `packages/core/lib/src/town/town.dart` — `temperItem` (through
  `_dressed`), `smeltOre, `brewPotion` (pack-cap aware, unique item id).
- `packages/content/lib/src/new_game.dart, `dungeons.dart` — node
  placement from `Rng(floorSeed ^ gatherSalt)` AFTER generation, on
  walkable non-stairs non-spawn tiles; counts per dungeon/depth as
  content constants. **No existing draw moves; no drop table changes.**
- `packages/content/lib/src/economy.dart` — temper term in `sellPriceOf`
  (beside the book term; a tempered item must not sell untempered), NO
  material entries in `marketTable`.
- Save: `save_codec.dart` (`saveVersion = 3`; the "last break" dartdoc
  rewritten to follow-up 20's honest wording), `profile_codec.dart`
  (`materials` sorted, `brewNumber`), `run_codec.dart` (`materials,
  per-floor `nodes` sorted `byRowThenColumn`), `item_codec.dart`
  (`temper` key, required, always written).
- App: `game_bloc.dart` (`GatherPressed, `canGather, materials in the
  view state), `game_screen.dart` (a Gather/Mine control shown only on a
  node — label by node kind; watch the row-width lesson), `glyph_grid.dart` (node glyph pass between terrain and items, own
  painter constant, NOT a palette field — the palette is terrain-only by
  its own dartdoc), `event_messages.dart` (new arms), `inventory_screen.dart` (Materials panel — Purse shape, fixed order,
  word + count), `town_screen.dart` (Forge + Alchemist doors, both
  towns; the "five doors" dartdoc updated), `town_bloc.dart` (three new
  events + handlers; carry-forward list intact), `item_presentation.dart`
  (`stackKey` gains temper; temper marking in `statLine` or its own
  column — must not collide with Fine `+` / Rare `++`).
- Tests as per plan; three goldens rewritten by hand; stale names fixed
  ("all four skills start untrained", "the seven skills", `skill_test.dart`'s `values.skip(4)` hard-fail updated).

## Per-item contract

1. **Skills.** `herbcraft, `blacksmith` appended. Training: exactly one
   xp per successful gather (herbPatch → Herbcraft; oreVein →
   Blacksmith), per smelt (Blacksmith), per brew (Herbcraft), per temper
   (Blacksmith) — all via `_train`-style single-point grants; town-side
   training goes through the Profile's skills map (first town-side
   training in the game — pre-declare the mechanism; `SkillLevelledUp`
   is a GameEvent, so town screens report level-ups via the notice line
   instead).
2. **Materials** are counters: `MaterialId { ore, ingot, herb }, each
   with a word and a marking. On `Profile` and `GameState, default
   empty; carried into runs, back out alive, CLEARED on death beside
   gold and inventory. Never items, never in the pack, never on the
   shelf, not banked this unit.
3. **Nodes.** `NodeKind { oreVein, herbPatch }, each with glyph + word
   (glyphs distinct from `#.<>@, all item glyphs `)[!?, and every
   creature letter — run the collision test). Placed AFTER floor
   generation from `Rng(floorSeed(...) ^ gatherSalt)` — a new salt
   constant added to the disjointness pins. Counts per dungeon and depth
   are content constants (start: 0–2 per floor, themed dungeons slightly
   richer in their own material; exact numbers are the worker's with a
   reasoned trail — no band may move, so the trail records choices and
   pacing arguments, not band deltas). Nodes sit on walkable floor tiles,
   never on stairs or the hero spawn, never blocking (the tile under a
   node stays `Tile.floor`). A gathered node is REMOVED from the floor's
   map for the rest of the run (per-floor per-run, the groundItems
   lifetime); `visit` bumps regrow everything by construction.
4. **`GatherAction()`** — underfoot, refused not blocked: 'there is
   nothing here to gather' when no node underfoot. Effect: the node's
   material counter +1 (flat yield, no draw), the node removed, `NodeGathered` emitted, the matching skill trained, the turn passes
   (monster phase runs). **No draw from `state.rng` or `state.lootRng`
   anywhere in the gather path.**
5. **Forge — smelt:** `smeltOre(profile)` converts `smeltCost` ore
   (start: 2) → 1 ingot, trains Blacksmith, refuses 'you do not have
   enough ore'. No gold cost.
6. **Forge — temper (the star):** `temperItem(profile, itemId)` raises
   `item.temper` by one tier, to `maxTemper = 3`. Gates (Blacksmith
   level) and costs (ingots + gold) per tier, worker-tuned with a
   reasoned trail (start: +1 at level 0 / 1 ingot + 10 gold; +2 at 5 /
   2 + 25; +3 at 10 / 3 + 50). Applies to carried AND equipped weapons
   and armour only (never potions or books — refuse 'only steel takes a
   temper'); an equipped temper goes through `_dressed` (maxHp never
   moves from temper today, but the clamp is the invariant, not the
   current arithmetic). Refusals via shared `temperRefusal, readable by
   the widget for dead-row reasons: not temperable / already at +3 /
   'needs Blacksmith 5' / not enough ingots / cannot afford. Tempering
   is the only way `Item.temper` ever changes. NOTE on `_dressed`:
   temper as contracted never moves `maxHp, so no clamp scenario
   exists TODAY — the requirement is a dartdoc sentence on `temperItem`
   stating that any future temper term reaching `maxHp` must route
   through `_dressed, plus the route itself if it comes free. Do not
   write a clamp test that cannot observe anything (the
   mutation-that-cannot-fail class).
7. **Temper semantics:** weapons +tier to both attack ends; armour
   +tier to armor. `props` and `stackKey` carry temper (a +2 sword and
   a +0 sword are different rows and different equalities).
   `displayName` stays untouched; temper renders as its own marking
   beside the stat line — a form visually distinct from the rarity
   column's `+`/`++` (worker picks; word + number always present, e.g.
   "tempered +2"). `sellPriceOf` gains a temper term (start:
   `temper * 3` inside `worth`) — pinned so a tempered item never sells
   at its untempered price, and buy stays 2× sell (no-arbitrage test
   already exists and must stay green).
8. **Alchemist — brew:** `brewPotion(profile)` converts `brewCost`
   herbs (start: 3) → one Common healing potion into the pack (id
   unique via `brew-<brewNumber>, counter on Profile), trains
   Herbcraft, refuses on herbs, and on a full pack in `buyItem`'s exact
   sentence. Brewed potions are ordinary items in every way.
9. **Save version 3.** New required keys, never defaulted: profile
   `materials` (sorted by enum order) + `brewNumber`; run `materials`;
   each floor block `nodes` (sorted `byRowThenColumn`); every item
   `temper`. Skills blocks grow to nine entries by the enum. The v2
   golden is captured BEFORE any codec change as the version-refusal
   fixture (the M3M sequencing trap, verbatim); the v1 fixture test
   stays. Three goldens rewritten by hand, old strings quoted in the
   commit. **The `saveVersion` dartdoc drops every finality claim** and
   states follow-up 20's rule: the version freezes at the first shipped
   build; until then, each break is a sanctioned, recorded decision.
10. **Both towns get Forge and Alchemist doors** (town-blind, like Inn).
    The "five doors and a purse" dartdoc updates; the door column
    scrolls — the device pass must show all seven doors reachable on
    the phone viewport.
11. **Road danger keeps the unfiltered sum** — craft levels DO tax
    roads (a tempered hero is further along; the dartdoc's argument
    holds). Pinned by a NEW test: a profile differing only in
    Blacksmith/Herbcraft levels rolls a higher tier. `heroMaxMana`
    immunity pinned the same commit (craft levels grant no mana).
12. **UI:** the Gather control appears only when a node is underfoot,
    labelled by kind ("Mine" / "Gather"); Materials panel on the pack
    screen and town screen in fixed order with word + marking + count
    (greyscale rule); node glyphs render between terrain and items with
    their own unthemed painter constant; nine skill rows (the
    scroll-to-reach test pattern from M3M applies).
13. **What must NOT change:** any drop table, any `Weighted` list, any
    spawn table, `marketTable, any bestiary stat, the hero's starting
    kit, either damage-formula copy, the bot, the generator's existing
    draw order, `dungeonFor, and the crypt's frozen layout functions.

## Behaviour arguments that must land in documentation

- Why materials are counters and not items (the pack cap is a decision
  about GEAR; a currency that filled it would tax the wrong choice —
  plus the six collision sites, cited).
- Why nodes are state, not tiles and not items (the three frozen
  contracts, named: layout goldens, rng-state pins, band lines).
- Why the gather path draws nothing (the D56 lesson, cited in the
  dartdoc where the salt is defined).
- Why temper lives on `Item` and reaches `props`/`stackKey` (stacks
  merging tempers would hand an action an arbitrary one).
- Why `sellPriceOf` needs the explicit temper term (it reads `base.*`
  by design — the one consumer temper does not flow through).
- Why death takes materials (they ride the same risk gold does; the
  bank remains gear-and-gold only, deliberately, this unit).
- The retirement of "the last break" (twice failed; follow-up 20 is the
  rule; the honest sentence is written where the old claim was).

## Test plan

**Characterization first (all against unmodified code):** the 1570
existing tests, the four band lines, the shelf golden, the layout goldens,
and the rng-state pins ARE the characterization layer; the worker re-runs
and quotes all of them as its baseline block. Capture the v2 golden
refusal fixture before any codec edit.

**Unit tests (red → green per behavior):** gather effect/refusal/
depletion/training per node kind; node placement determinism (same seed →
same nodes; different `gatherSalt` → different nodes; layout bytes
IDENTICAL with nodes present vs absent — the load-bearing control);
nodes never on stairs/spawn; suspend/resume round-trips nodes and
materials roll-for-roll (suspend theorem extended); materials through all
four run-boundary doors and CLEARED on death; smelt/brew conversions,
refusals, pack-cap sentence, brewed-id uniqueness; every temper contract
in item 6-7 including the `_dressed` clamp, the +3 ceiling, gates by
level, ingot+gold debits, dead-row reasons; `stackKey`/`props`
separation; `sellPriceOf` temper term + no-arbitrage green; road-danger
and mana pins (item 11); nine-skill enum/UI/codec tests updated.

**Content validation:** every `NodeKind` yields a real `MaterialId`;
node counts reference real dungeons/depths; glyph collision test extended;
salt disjointness pins extended; `marketTable` carries NO materials
(exclusion pinned).

**Mutation table** (committed code, worktree root, pwd quoted, reds as
NAMED SETS, revert clean, report greens):

| # | Mutation | Expected |
|---|---|---|
| 1 | `gatherSalt` constant changed | REDS node-placement determinism pins; layout-identity control stays green (both halves reported) |
| 2 | `_train` grant deleted from the gather path | REDS the gather-training tests |
| 3 | node removal deleted (gathering never depletes) | REDS the depletion test |
| 4 | materials death-clear deleted | REDS the death test |
| 5 | `smeltCost` 2 → 1 | REDS the smelt pin |
| 6 | tier-gate clause deleted from `temperRefusal` | REDS gate refusals in core AND the widget reason test (both halves) |
| 7 | temper term deleted from the Item stat getters | REDS the temper stat tests and the worn-delta test |
| 8 | temper term deleted from `sellPriceOf` | REDS the temper price test |
| 9 | `maxTemper` ceiling check deleted (temper past +3) | REDS the ceiling test |
| 10 | temper dropped from `stackKey` | REDS the stack-separation test |
| 11 | `materials` dropped from `encodeProfile` | REDS the round-trip and the town golden |
| 12 | `nodes` dropped from the floors codec | REDS the suspended-nodes round-trip |
| C1 | — all four band lines, final commit | GREEN AND BYTE-IDENTICAL to baseline |
| C2 | — designed-difficulty pin | GREEN |
| C3 | — crypt layout goldens + BOTH rng-state integer pins | GREEN |
| C4 | — merchant shelf characterization | GREEN (no table touched) |
| C5 | mutation 5 re-run against `survivability_test.dart` only | GREEN (the bot never smelts) — both halves of row 5 |

Sequencing traps: rows 1–12 mutate new code — run after it ships. The v2
refusal fixture predates the golden rewrite (prove by commit order). Row 1's
green half is the unit's central claim — report it beside its red half.

## Hazards

- The three node conditions (separate Rng, not a Tile, not an Item) are
  each individually load-bearing. The rng-state integer pins at
  `dungeon_door_characterization_test.dart:84-85` are the tripwire —
  if they move, STOP; the defect is in the placement wiring.
- Temper × `sellPriceOf` and temper × `stackKey`/`props` (contracts 6-7)
  — the two named misses; the `_dressed` route is a documentation
  requirement, not a testable one (contract 6's note).
- Town-side skill training is new machinery — pre-declare its shape
  before building it.
- The `_settled` carry-forward list in `town_bloc.dart` (its own dartdoc
  warns forgetting it erases camps silently) — three new handlers ride it.
- Goldens by hand, old values quoted; enum appended; the two stale test
  names and the `values.skip(4)` hard-fail.
- Device pass mandatory: seven town doors on the phone viewport, node
  glyphs + Materials panel in greyscale, nine skill rows, the Gather
  control beside the existing row (label-width lesson); save-slot
  copy-aside before ANY install (the `flutter install` trap — it
  destroyed the data directory once); pin to `emulator-5554`.
- Analyze from the worktree root; suites from package dirs; band lines
  quoted verbatim never summarized.

## Follow-ups to log (not this unit)

- Camp brewing (the world-screen camp-door seam, mapped in the recon).
- Kill-drop/chest materials and material banking (band re-pin territory;
  chests need machinery).
- Basic gear forging arrives with M5 recipes.
- No instrument measures gathering pace or temper economy — human-judged
  (follow-up 29's class widens again).
- Travel-event gathering (spec parenthetical; salt slots reserved).

## Definition of done

- All three suites green from their package dirs; total strictly above
  1570; declaration cross-check consistent.
- **All four band lines byte-identical to the baseline block** (quoted,
  final commit), plus C2–C5 green as listed — the controls ARE the
  headline this unit.
- `dart analyze .` clean from the root (pwd quoted); format clean.
- Mutation rows 1–12 red as named sets, clean reverts; both halves of
  rows 1, 5, 6.
- Goldens rewritten by hand with old strings quoted; v2 refusal fixture
  proven pre-change; v1 fixture test still green.
- Suspend theorem extended (nodes + materials roll-for-roll).
- AVD pass with the shots listed (greyscale copies), both save slots
  copied aside and SHA256-verified restored, v2 refusal proven on device.
- No commit under `docs/epic/`; report mirrored to
  `docs/reports/BUILD-REPORT.md`; plan in `docs/plans/`; conventional
  commits authored `; PR NOT opened.
