# m3-fixes (M3F) Implementation Plan

> Execute with flow-executing-plans, task by task.

**Goal:** Road fights stop wiping the profile's learned spells and materials
and become magic-aware; gathering nodes stay visible on the remembered map;
the town "Gear" door becomes a "Character" menu with the dungeon Pack's shape.
**Spec:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-fixes-spec-M3F.md`
**Build prompt:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-fixes-build-prompt.md`

## Global constraints

- Worktree `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-fixes,
  branch `m3-fixes, base `54ec315`. Every command starts `cd <worktree> &&`.
- Never commit `docs/epic/, `docs/reports/, `docs/plans/, `.pi/` — stage
  explicit paths only (`docs/plans/` is NOT gitignored in this repo; the plan
  file stays untracked).
- Baseline measured this session on `54ec315`: 762 core + 530 content + 498
  app = 1790 green. Four band lines quoted:
  - `survivability: 20/40 won (50.0%), stalled 0, died at 1:1 2:6 3:6 4:7 5:20`
  - `greedy build: 20/40 won; fleetfoot-first build: 14/40 won`
  - `sea-cave: 30/40 won (75.0%), stalled 0, died at 2:1 3:8 4:13 5:9 6:9`
  - `ruined keep: 25/40 won (62.5%), stalled 0, died at 1:4 2:5 3:4 4:2 5:13 6:6 7:6`
- The fix adds ZERO rng draws; all four band lines must stay byte-identical.
- No save-format change, no content-table change, no band pin edit, no edit to
  `dungeon_door_characterization_test.dart`. No new dependencies, no
  suppressions, no `Random()`.
- Commits: Conventional Commits.
- No fvm: plain `dart` / `flutter` (3.47.0). `dart analyze .` from worktree
  root; `dart format --set-exit-if-changed .`; `flutter analyze`.
- Greyscale rule: state by shape/word/position, never hue alone. The Pack
  grammar (marking column 28px, `—` for empty, tier word in name) carries over.
- Comments: none in bodies; dartdoc `///` only, on public API only.
- Test bodies: `// arrange` / `// act` / `// assert`; pure tests (state in,
  state out, no mocks).

## Pre-declared shape decisions (mailed to the architect before coding)

1. **Instrument (item 2):** new file `packages/app/lib/game/glyph_plan.dart`
   beside `glyph_grid.dart, exporting `GlyphCell` (position, glyph, ink,
   opacity), `const double rememberedOpacity = 0.4, and the pure function
   `List<GlyphCell> glyphPlan(GameState game, DungeonPalette palette)`.
   Two deviations from the spec's literal `glyphPlan(GameViewState)`:
   (a) it takes `GameState` — the plan reads only game facts (map, visible,
   explored, nodes, groundItems, monsters, hero) and `GameViewState` adds
   nothing the plan needs, so the test needs no bloc; (b) it takes
   `DungeonPalette palette` because terrain ink is themed by dungeon and the
   plan must be fully observable. `_GlyphPainter` is reduced to consuming the
   plan (`for (final cell in glyphPlan(...)) paint(cell)`); constants and
   order are unchanged.
2. **C2 sequencing:** the plan function does not exist on `54ec315, so C2
   cannot literally run on the unmodified base. The extraction lands first as
   a pure `refactor:` commit (logic lifted, not changed — diff quoted in the
   report), C2 is written immediately after against the seam and quoted
   passing before the node branch changes. C1 runs on the true base commit.
3. **Mana display (item 3):** a town profile has no current mana (the pool
   lives on `GameState`), so the stats panel shows `Mana <max>` from
   `heroMaxMana(profile.loadout)` — the same number the delve start opens
   with. No `x/y` pair because there is nothing to be half of in town.

## Task 1 — Baseline + C1 (no code change)

**Files:** none.

- [x] Run all three suites on `54ec315`; record 762/530/498 = 1790.
- [x] Quote the four band lines.
- [x] Run the `walking into a road fight` group (C1) — 14 tests pass.

## Task 2 — Item 2 instrument: extract the glyph plan (pure refactor)

**Files:** new `packages/app/lib/game/glyph_plan.dart`;
`packages/app/lib/game/glyph_grid.dart` (painter becomes a plan consumer).

- [ ] Write `glyph_plan.dart`: `GlyphCell, `rememberedOpacity = 0.4, `glyphPlan(GameState game, DungeonPalette palette)` — the terrain loop,
      node loop, litter loop, monster loop and hero glyph lifted verbatim from
      `_GlyphPainter.paint` into plan construction, in the same order. The
      node loop keeps its CURRENT visible-only rule in this task (the fix is
      Task 4's red).
- [ ] Reduce `_GlyphPainter.paint` to: build geometry →
      `for (final cell in glyphPlan(state.game, palette)) _paint(canvas, cell)`.
- [ ] `cd packages/app && flutter test` — all 498 green (nothing observes the
      painter yet; behavior identity is argued from the diff: every loop
      lifted, none rewritten).
- [ ] Commit `refactor: extract the glyph paint plan from the painter`
      (staging only the two files).

## Task 3 — C2: terrain characterization (must pass unchanged)

**Files:** new `packages/app/test/game/glyph_plan_test.dart`.

Fixture: a real crypt run (`startDungeonRunAt(cryptNode, profile)`) with
`copyWith` of `visible`/`explored` to control visibility. Helpers:
`cellAt(plan, position)`.

- [ ] C2a: a tile in `explored` but not `visible` has a plan cell with
      `opacity == rememberedOpacity` (0.4) and the terrain glyph/ink for its
      tile.
- [ ] C2b: a tile in neither set has no plan cell.
- [ ] Run: passes immediately (characterization — current behaviour pinned).
      It pins the path the node fix rides and guards M6's control.
- [ ] Commit `test: pin remembered-terrain paint through the glyph plan`.

## Task 4 — R5 red → green: remembered nodes render

**Files:** `packages/app/lib/game/glyph_plan.dart` (node loop only), `packages/app/test/game/glyph_plan_test.dart`.

- [ ] RED R5a: node at a position in `visible` → plan cell glyph
      `node.value.glyph, ink `nodeInk, opacity `1.0`.
- [ ] RED R5b: node in `explored` not `visible` → same cell at
      `rememberedOpacity`.
- [ ] RED R5c: node in neither → no cell.
- [ ] RED R5d (order): every terrain cell's index < the node cell's index <
      the hero cell's index (draw order unchanged).
- [ ] Run the three new tests — confirm they fail on the visible-only loop
      (R5a passes already since visible nodes paint today; R5b and R5c are the
      failing pair — confirm R5b fails for the right reason: cell absent, not
      wrong opacity).
- [ ] GREEN: node loop becomes
      ```dart
      for (final node in game.nodes.entries) {
        final seen = game.visible.contains(node.key);
        final remembered = game.explored.contains(node.key);
        if (!seen && !remembered) continue;
        cells.add(
          GlyphCell(node.key, node.value.glyph, nodeInk,
            seen ? fullOpacity : rememberedOpacity),
        );
      }
      ```
      with dartdoc: a vein is part of the place — it stays drawn on the
      remembered map at the remembered opacity, unlike litter and monsters,
      which are events.
- [ ] Full app suite green. Commit `fix: remembered gathering nodes stay on
      the map`.

## Task 5 — Item 1 reds: road carry (content)

**Files:** `packages/content/test/world_test.dart` (new tests in the
`walking into a road fight` group; no existing line touched).

Fixture hero, schooled field by field: `_fresh()` = `newProfile(worldSeed:
909)` → untrained skills, no spells, no materials. Schooled fixture:

```dart
Profile _schooled() => _fresh().copyWith(
  knownSpells: const {firebolt.id, mend.id},
  materials: const {MaterialId.ore: 3, MaterialId.herb: 1},
);
```

(firebolt requires Wrath 0 and mend Mending 0, so the ids alone are enough
for the boundary test — the fixture asserts carry, not casting gates.)

- [ ] RED R1: `endRun(profile, startRoadEncounter(profile, day: 3), died:
      false)` → `knownSpells == {firebolt, mend}` and `materials == {ore: 3,
      herb: 1}`.
- [ ] RED R2: the encounter state itself — `mana ==
      heroMaxMana(profile.loadout)` (> baseMana because schooled), `knownSpells == profile.knownSpells, `spells` contains `firebolt` (a
      known id findable in `state.spells`), and `spells.length ==
      spellbook.length` (the whole book, same as a delve).
- [ ] RED R3: `endRun(..., died: true)` → knownSpells kept, `materials`
      empty, gold 0, inventory empty (the road-shaped round trip of the death
      price).
- [ ] Run the three — confirm each fails on the current defaults
      (`knownSpells = const {}` etc.), not on a typo.
- [ ] Commit `test: pin what a road fight must carry home` (test-only red
      commit? NO — every commit's exit state is green: combine with Task 6's
      green in ONE commit, see below).

Note: the build prompt requires every commit green, so Task 5 and Task 6 land
as one commit: tests first in the working tree (watched red), then the
arguments, then the combined commit quoting both states in its message body.

## Task 6 — Item 1 green: the four constructor arguments

**Files:** `packages/content/lib/src/world.dart` (`startRoadEncounter` only).

- [ ] Add exactly, to the `GameState(...)` in `startRoadEncounter`:
      ```dart
      spells: spellsById,
      knownSpells: profile.knownSpells,
      materials: profile.materials,
      mana: heroMaxMana(profile.loadout), ```
- [ ] Extend the dartdoc: the carry-list doctrine (everything the profile
      owns rides through on the carry list rather than by luck — the m3-world
      list missed every field M3M/M3C later added) and road mana starts full,
      the same doctrine a delve start carries.
- [ ] R1, R2, R3 green. C1 group green. Content suite green.
- [ ] Verify NO rng draws added: the diff touches only constructor arguments
      and dartdoc; `world_test.dart` fingerprints stay green.
- [ ] Commit `fix: road fights carry the profile's magic and materials`
      (tests from Task 5 + these four lines; old values quoted in body).

## Task 7 — R4 red + green: the app-layer witness

**Files:** `packages/app/test/town_bloc_test.dart` (the `coming home off the
road` group).

- [ ] RED R4: new blocTest with a schooled, stocked profile (`_rich()` +
      knownSpells + materials); `EncounterEnded(startRoadEncounter(..., day:
      4), died: false)` → `profile.knownSpells` contains both spell ids and
      `profile.materials` carries both counts.
- [ ] Watch it fail (the wipe's app-layer witness). Then Task 6's fix makes
      it pass (same change).
- [ ] Full app suite green.

Sequencing: write R4 (red, app suite shows exactly this one failing), then
make Tasks 6+7 green together, then commit Tasks 5+6+7 as the single
`fix:` commit described in Task 6. Exit state green.

## Task 8 — Item 3 red: R6 widget tests

**Files:** new `packages/app/test/widget/character_screen_test.dart`;
`packages/app/test/widget/craft_rooms_test.dart` (door label).

- [ ] R6a (in craft_rooms_test): door list `'Gear'` → `'Character'` — golden
      edit, old value `'Gear'` quoted in the commit.
- [ ] R6b: the character screen shows every section: derived stats lines
      (`Attack, `Armour, `Dodge, `Speed, `Health, `Mana`), Spells (a
      known spell's name + its `schoolWord`), Worn (all six `slotLabel`
      values), Carried (weapons/armour/potions/books headings from
      `packSections`), Materials (all three `MaterialId.word` rows even at
      zero), Skills (a `skillName` for every `SkillId`).
- [ ] R6c: actions route through the existing events — tap `Wear` on a
      carried wearable and the profile's equipment changes (TownBloc state);
      tap `Take off` and the slot empties; a carried book with a schooled
      hero offers `Read` and `ReadBookPressed` is delivered (bloc state
      change observed — knownSpells grows).
- [ ] Phone-sized (360×640, the `craft_rooms_test` precedent).
- [ ] Run — confirm the tests fail because `CharacterScreen` does not exist
      (compile error counts as red: the door text `'Character'` is absent and
      the import target missing). Commit nothing yet.

## Task 9 — Item 3 green: the Character screen

**Files:** new `packages/app/lib/town/character_screen.dart`; delete
`packages/app/lib/town/gear_screen.dart`; `packages/app/lib/town/town_screen.dart`
(import, door label `Gear` → `Character, `GearScreen` → `CharacterScreen`).

- [ ] `CharacterScreen`: a `TownRoom` titled `Character, driven by
      `TownBloc`/`TownViewState` (`state.profile`), sections in Pack order:
      1. stats panel — `Attack min-max` (`heroAttack(profile.hero,
         profile.loadout)`), `Armour` (`heroArmor(profile.loadout)`), `Dodge
         %` (`heroDodgePercent`), `Speed` (`heroSpeed`), `Health hp/maxHp`
         (`profile.maxHp`), `Mana max` (`heroMaxMana(profile.loadout)`).
      2. `Spells` — known spells from `profile.knownSpells` through
         `spellsById, sorted school then name (the Pack's order doctrine),
         each row `schoolMarking` + name + `schoolWord · manaCost`; no cast
         button, read-only.
      3. `Worn` — six `slotLabel` rows with `TakeOffPressed` (GearScreen's
         `_WornRow` shape).
      4. `Carried` — full `packSections(profile.inventory), all four
         sections even when empty; wearables `WearPressed` (`_WearableRow`
         shape with `deltaLine(wornDeltas(...))`), books `ReadBookPressed`
         with `readRefusal(profile.loadout, profile.inventory,
         profile.knownSpells, spellsById, id), potions a row with no action
         (no town Drink event exists and the spec forbids new events).
      5. `Materials` — `MaterialRows(state.materials)` (already every
         material even at zero).
      6. `Skills` — all `SkillId.values, `skillName, level, XP bar
         (`xpToNext`), the Pack's `_SkillRow` grammar (second occurrence —
         duplicated, not extracted; a third would extract it).
- [ ] dartdoc on the class: the Pack's twin, one grammar for hero state
      everywhere; the differences are the driver (`TownViewState` vs
      `GameViewState`) and no cast action.
- [ ] Delete `gear_screen.dart`. `grep -rn GearScreen packages/app` → only
      the new screen's history remains (zero references).
- [ ] Full app suite green (R6a/craft_rooms + R6b/c + all 498).
- [ ] Commit `feat: the town Gear door becomes a Character menu` (old
      `'Gear'` quoted in body).

## Task 10 — Mutation table M1–M7 (on final code, from worktree root)

Run each row; record named reds AND greens. Exact commands (run with `pwd`
quoted beside output):

- M1 `sed -i 's/knownSpells: profile.knownSpells/knownSpells: const {}/'
  packages/content/lib/src/world.dart` → red: R1, R4; green: C1 group, four
  band lines.
- M2 `sed -i 's/spells: spellsById/spells: const {}/'
  packages/content/lib/src/world.dart` → red: R2, R4; green: C1, bands.
- M3 `sed -i 's/materials: profile.materials/materials: const {}/'
  packages/content/lib/src/world.dart` → red: R1, R3, R4; green: C1, bands.
- M4 `sed -i 's/mana: heroMaxMana(profile.loadout)/mana: 0/'
  packages/content/lib/src/world.dart` → red: R2; green: C1, bands.
- M5 (multiline, `sed -z`) restore the visible-only node loop in
  `glyph_plan.dart` → red: R5b, R5c, R5d; green: R6, R5a.
- M6 `sed -i '/node.value.glyph/s/seen ? fullOpacity :
  rememberedOpacity/seen ? fullOpacity : 0.0/' packages/app/lib/game/glyph_plan.dart`
  → red: R5b; green: C2 (terrain untouched).
- M7 `sed -i 's/packSections(profile.inventory)/const []/'
  packages/app/lib/town/character_screen.dart` → red: R6's Carried
  assertions; green: the stats/spells/skills assertions, bloc equip tests.

Revert after each row; `git status` clean before the next.

## Task 11 — Closing verification

- [ ] Full three suites, counts quoted (expect 1790 + new).
- [ ] Four band lines byte-identical, quoted.
- [ ] `dart analyze .` (worktree root) clean; `dart format
      --set-exit-if-changed .` clean; `flutter analyze` clean.
- [ ] `git log --oneline main..m3-fixes` quoted (commits not on main).
- [ ] AVD pass (unsandboxed): copy BOTH save slots aside (`run-as`), check
      free space, `adb -s emulator-5554 install -r` the debug APK, verify the
      Character door + screen and a remembered node; screenshots + greyscale
      variant into `docs/reports/shots/m3-fixes/`; saves restored.
- [ ] BUILD-REPORT.md in the handoff directory; done notice in worker.md.