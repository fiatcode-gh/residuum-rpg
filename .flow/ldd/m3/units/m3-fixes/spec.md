# m3-fixes — Story spec (M3F)

Architect decision base: D62, D63. Recon: `docs/epic/m3-fixes-recon.md`
(read it first; its file:line citations were measured on `54ec315`).
Base commit: `54ec315` (`main, PR #12 merged). Branch: `m3-fixes`.

## Goal

Ship the 2026-08-29 playtest's two defects and its town-menu verdict:
(1) road fights stop wiping the profile's learned spells and materials and
become magic-aware; (2) a gathering node stays visible on the remembered
map after the hero walks away; (3) the town "Gear" door becomes a
"Character" menu with the dungeon Pack's shape. Measurable effect: a
schooled, stocked hero can travel, fight on the road, and arrive with
spells and materials intact; a node seen once is never invisible again;
the town offers one screen holding stats, spells, worn gear, the whole
pack, materials, and skills.

## Shape

Three items, each following a precedent read from the codebase:

1. **Road-encounter carry** — the precedent is `startRun`
   (`packages/core/lib/src/town/run_boundary.dart:92-94`) as invoked by
   `startDungeonRunAt` (`packages/content/lib/src/dungeons.dart:379-386`):
   the profile's own fields ride through, and `endRun` carries them home.
   `startRoadEncounter` gets the same four arguments.
2. **Remembered nodes** — the precedent is remembered terrain in the same
   painter (`glyph_grid.dart`: explored-but-not-visible draws at
   `_rememberedOpacity`). The node loop joins the terrain rule; the
   painter's own dartdoc ("part of the place") is the argument of record.
3. **Town character menu** — the precedent is `InventoryScreen`
   (`inventory_screen.dart:24`): the Pack's section list and grammar,
   driven by `TownViewState`/`Profile` instead of `GameViewState, with
   `GearScreen`'s existing equip/read events.

## New files

- `packages/app/lib/town/character_screen.dart` (the Pack-shaped successor
  of `gear_screen.dart, which is deleted).
- App tests for the character screen (widget, phone-sized — follow-up 26).
- One instrument file for the glyph paint plan (see item 2's contract;
  exact name is the worker's, pre-declared if it deviates from a pure
  `glyphPlan(GameViewState)` function beside `glyph_grid.dart`).

## Changed files

- `packages/content/lib/src/world.dart` — `startRoadEncounter` gains
  exactly four constructor arguments; nothing else in content changes.
- `packages/app/lib/game/glyph_grid.dart` — the node loop's visibility
  rule (fence: the `for (final node in game.nodes.entries)` block).
- `packages/app/lib/town/town_screen.dart` — one door rename + route.
- Touched tests, each edit with the old value quoted in the same commit:
  `packages/app/test/widget/craft_rooms_test.dart` (door label),
  any test constructing `GearScreen` (worker sweeps first).

## Per-item contract

### Item 1 — `startRoadEncounter` carries magic and materials

The constructor gains exactly:

```dart
spells: spellsById,
knownSpells: profile.knownSpells,
materials: profile.materials,
mana: heroMaxMana(profile.loadout), ```

It must NOT: add any rng draw (the encounter map, monster spawns, and both
fight streams are pinned by `world_test.dart` fingerprints and must come out
identical); touch any table, weight, or salt; change any other field; change
`isEncounter`. Road mana starts full — the same doctrine a delve start
carries (`startRun`), stated in dartdoc. Books become readable mid-fight
and spells castable; the existing `endRun` copy (which already carries
`knownSpells` and `materials` home) needs NO change in core.

**Pre-declared consequence to keep:** a hero dying on the road loses
materials and pack but keeps spells — `endRun`'s death branch already
prices this identically to dungeon death; do not special-case the road.

### Item 2 — remembered nodes render

After the change: a node at a position in `visible` paints as today (full
paint, `nodeInk`); a node at a position in `explored` but not `visible`
paints at `_rememberedOpacity`; a node at neither paints nothing. Draw
order is unchanged — nodes still paint after terrain and before litter,
monsters, and the hero. No interaction change: gathering still demands
standing on the tile.

The instrument: the repo has no golden-image tests and nothing today
instantiates the painter. Make the plan observable without screenshots —
an extracted pure function (e.g. `glyphPlan(GameViewState)` returning
per-position glyph/ink/opacity) is the suggested seam, with the painter
reduced to consuming it. If you choose a different instrument (recording
canvas, etc.), pre-declare it in the mailbox before coding.

### Item 3 — the town "Character" screen

The door reads `Character` where it read `Gear`. The screen is a `TownRoom`
with, in Pack order: derived stats (attack range, armour, dodge, speed, HP,
mana — town values via `Profile`/`loadout`), Spells (known spells, `schoolMarking` + `schoolWord, read-only — no casting in town), Worn (six
`slotLabel` rows, `TakeOffPressed`), Carried (full `packSections`:
weapons, armour, potions, books — wearables `WearPressed, books
`ReadBookPressed`), Materials (`MaterialRows, every material even at
zero), Skills (`SkillState` level + XP bar, all `SkillId` values). No new
bloc events; `TakeOffPressed`/`WearPressed`/`ReadBookPressed` unchanged.
The screen stays presentation: no game rule in a widget. The greyscale
grammar carries over unchanged (marking + word, `—` for empty, fixed
marking column).

## Behaviour arguments that must land in documentation

1. **The carry-list doctrine** (`world.dart` dartdoc on
   `startRoadEncounter, quoting the bloc's own line): everything the
   profile owns rides through the encounter "on the carry list rather than
   by luck" — written in the m3-world era, it missed every field M3M/M3C
   later added; the four new arguments close that and the dartdoc says what
   "carries" now means.
2. **Road mana starts full** — same doctrine as a delve start, so an
   ambush is a fair arena for a casting hero, not a mana-less one.
3. **"Part of the place"** (`glyph_grid.dart` node dartdoc, extended): a
   vein is terrain-like and stays drawn on the remembered map at the
   remembered opacity, unlike litter and monsters which are events.
4. **The character menu is the Pack's twin, not a new design** — one
   grammar for hero state everywhere; the only differences are the driver
   (`TownViewState` vs `GameViewState`) and the absence of a cast action.

## Test plan

**Characterization first — must pass against UNMODIFIED code:**

- C1 (content): the existing "walking into a road fight" group stays
  green untouched (map ascii, seeds, width, energy, carry list) — run it
  on the base commit before any change and quote the pass.
- C2 (app): remembered TERRAIN paints at `_rememberedOpacity, unexplored
  paints nothing — pins the path the node fix rides; passes today.

**Reds (new behaviour, fail before the change):**

- R1 (content): profile schooled in two spells with three materials →
  `startRoadEncounter` → `endRun(died: false)` → profile still knows both
  spells, still carries the materials.
- R2 (content): the encounter state opens with `mana == heroMaxMana, `spells` == the spellbook, `knownSpells` carried (a castable spell is
  findable in `state.spells` by a known id). Fixture hero must be schooled
  (a spell-less hero has max mana 0 and observes nothing).
- R3 (content): death on the road keeps spells, clears materials — the
  `endRun` death price already applies; the red is the road-shaped round
  trip.
- R4 (app, bloc): the "coming home off the road" group gains the
  spells-and-materials survive assertion (the wipe's app-layer witness).
- R5 (app): a node in `explored` but not `visible` paints at
  `_rememberedOpacity`; in `visible` at full; in neither, nothing.
- R6 (app widget, phone-sized): the town door reads `Character`; the
  screen shows every section with the Pack grammar; equip/take-off/book
  actions still route through the existing events.

**Mutation table — run every row, report greens too:**

| # | Mutation (sed) | Expected red | Expected green (control) |
|---|---|---|---|
| M1 | `knownSpells: profile.knownSpells` → `knownSpells: const {}` in `world.dart` | R1, R4 by name | C1 entire group; all four band lines |
| M2 | `spells: spellsById` → `spells: const {}` in `world.dart` | R2, R4 by name | C1; bands |
| M3 | `materials: profile.materials` → `materials: const {}` in `world.dart` | R1, R3, R4 by name | C1; bands |
| M4 | `mana: heroMaxMana(profile.loadout)` → `mana: 0` in `world.dart` | R2 by name | C1; bands |
| M5 | node remembered branch removed (visible-only loop restored) | R5 by name | R6 (nodes don't touch the town screen); visible-node assertions inside R5 |
| M6 | node remembered opacity changed to `0.0` where the fix paints it | R5 by name | C2 (terrain opacity unaffected) |
| M7 | character screen's `packSections` call replaced with `const []` | R6 by name (Carried section assertions) | bloc equip tests; R6's stats/spells/skills sections |

Sequencing trap: none of the mutations delete code the change itself
removes; every row runs after the change on the final code. M5 mutates a
branch the fix adds — it must still be runnable by sed against the
post-fix loop.

**What the tests cannot prove:** no instrument measures whether gathering
now FEELS discoverable or the road fight feels fair to a casting hero —
human-judged (follow-up 29's class), re-opened at the HUD+cast playtest.

## Hazards

- Every environment trap in the ledger's traps block, restated in the build
  prompt verbatim — especially the AVD ritual (copy BOTH save slots aside
  BEFORE any install; `adb install -r` only; ~153 MB APK, check space;
  `-s emulator-5554`).
- The user's device save holds a wiped hero (pre-fix). No migration — v3
  stands. The AVD pass says so in the report rather than hiding it.
- `dart analyze .` from the WORKTREE ROOT; mutation reds as named sets;
  goldens by hand with the old value quoted in the same commit.
- No fvm: plain `flutter`/`dart` (3.47.0).

## Follow-ups to log

- The M3M casting-feel and M3C gathering-pace verdicts RE-OPEN after this
  unit + the HUD+cast unit (D63) — the playtest could not judge either
  through these defects.
- Road-fight UI surface: what Pack offers mid-ambush is now worth a look
  at the HUD+cast brainstorm (the encounter screen may want the cast
  affordance early).
- Follow-up 30 (status line on a real phone) still rides the HUD unit.

## Definition of done

- 1790 + all new tests green across the three suites; counts quoted from
  result files with the baseline stated (1790 on `54ec315, measured fresh
  this session in D62).
- All four band lines byte-identical, quoted verbatim in the report.
- The `world_test.dart` fingerprint group green untouched (C1 quoted).
- Full mutation table reported, greens included.
- AVD pass done: new door + character screen verified, a remembered-node
  screenshot (plus a greyscale variant), saves restored, copy-aside ritual
  honored.
- `flutter analyze` clean, `dart format --set-exit-if-changed .` clean
  project-wide.
- BUILD-REPORT.md mirrored in the unit's handoff directory.