# M3M Magic Implementation Plan

> **For agentic workers:** Use `superpowers:executing-plans` (inline) to implement this plan
> task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The hero learns spells from consumable books and casts them in the crawl, spending a
hero-only per-floor mana pool, training three new school skills, and dealing typed damage that
creature resistances and vulnerabilities modify — while melee stays byte-identical.

**Architecture:** A new `magic/` feature folder in `core` holds the `Spell` value object, the
`readRefusal` rule and the targeting rule. Spells are content data carried by identity on
`GameState` exactly as `dropTables` are. Mana, ward, bind and known spells are new `GameState`
fields; known spells mirror `skills` through all four run-boundary doors. Two new `GameAction`
cases join the `step` dispatch. The save format bumps to version 2; every pre-M3M save is refused.

**Tech Stack:** Dart 3 / Flutter 3.47.0 (no fvm in this repo — plain `flutter` / `dart`).
Packages: `core` (pure rules), `content` (data), `app` (Flutter shell). Dependency rule
`app → content → core`; `core` and `content` never import Flutter.

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-magic-spec-M3M.md`
(gitignored planning directory — cited by absolute path, never committed).
Recon: `.../docs/epic/m3-magic-recon.md`. Build prompt: `.../docs/epic/m3-magic-build-prompt.md`.

## Global Constraints

- **The bands RE-PIN, with a measured trail (ledger D56).** The architect's original
  band-identity control C1 is STRUCK: books riding the per-dungeon depth tables move every line,
  proven by measurement before any code was written. What replaces it:
  - The asserted soft bands 0.45-0.80 and the keep-below-cave ordering must still hold at
    convergence.
  - If a book weight pushes a line out, the only sanctioned counter-levers are book weights and
    that dungeon's own litter and drop chances — never creature or hero stats.
  - The trail argues every line's movement from table composition and pickup turns, never from
    combat math.
  - C2 (the designed-difficulty pin, both melee formula copies untouched at the hunk level) and
    C3 (the crypt LAYOUT goldens — confirm rather than assume that layout bytes survive table
    changes) remain the melee-untouched controls. C4 stands as written.
  - The new exact lines, histograms and the fleetfoot figure are re-pinned at convergence and
    quoted verbatim.
  Baseline measured on `936ca5b` for the trail's first row: `survivability: 20/40 won (50.0%),
  stalled 0, died at 1:1 2:9 3:4 4:6 5:20` / `greedy build: 20/40 won; fleetfoot-first build:
  14/40 won` / `sea-cave: 31/40 won (77.5%), stalled 0, died at 2:1 3:7 4:13 5:10 6:9` /
  `ruined keep: 28/40 won (70.0%), stalled 0, died at 1:4 2:6 3:1 4:1 5:13 6:9 7:6`.
- **No new RNG draw on any non-casting path.** The dodge gate's zero-skip stays exactly as
  written. bolt = exactly one `state.rng` draw; banish = exactly one; mend/ward/bind = zero.
- **No unseeded `Random()`** anywhere in `core` or `content`.
- **No changes** to: creature hp/attack/pierce/speed/dropChance; hero starting kit or fresh-hero
  stats; either copy of the melee damage formula (`step.dart` and
  `designed_difficulty_test.dart:72-75`); bot policy; generator/floor layout; the crypt's frozen
  files (`floorSeed,`generateFloor, `newGame`'s layout path, `buildFloor,`residuumDungeon, `dungeonFor`'s early return); `pubspec.yaml` dependencies.
- **Comments:** none in bodies. Dartdoc `///` only, on public API of `core` and `content`.
- **Ubiquitous language:** the spec's words exactly — `temper,`affix, `beat,`rumor, `residue,`school, `ward,`bind, `banish`.
- **Accessibility:** state, rarity and category encoded by shape, marking, position or a word —
  never hue alone. Every screen reads in greyscale.
- **Test bodies:** `// arrange` / `// act` / `// assert`.
- **Commits:** conventional. Every commit
  exits green. No commit touches `docs/epic/`. No push, no PR.
- **Goldens by hand**, old strings quoted in the same commit. Skills enum APPENDED, never
  reordered.
- Run `flutter test` from each package directory. `dart analyze .` and
  `dart format --set-exit-if-changed .` from the WORKTREE ROOT with pwd quoted.

## Rulings received (ledger D56, architect, 2026-08-25)

- **Ruling 1** — Option C. Books ride the per-dungeon depth tables exactly as contract 9 says, and
  all four band lines re-pin with a measured trail. Merchant-only and trophy-table-only were
  rejected: the first kills the found-in-dungeon goal loop the design spec promises, the second
  puts a Common-forced book in a table whose promise is a guaranteed rare and pays repeat winners
  in duplicate vendor trash. The merchant still carries the two ungated starter books per contract
  9's last clause; bots never shop, so that is band-safe, and the shelf-count pin extends knowingly
  per contract 10.
- **Ruling 2** — the gates were an architect arithmetic error. New gates: **frost-lance needs Wrath
  4, banish needs Binding 4, ward needs Mending 3.** Contract 1 stands at one xp per cast.
  `heroMaxMana`'s base of 4 is confirmed tunable UPWARD with a trail; the derivation shape stays.
  Reason sentences follow the new numbers.
- **Defects 3, 4 and 5** — approved as proposed. Two extra pins required: a stairs bounce
  (down-up-down) refills no mana, and a bind set on depth 1 does not reach a same-id monster on
  depth 2.
- **All three deviations approved.** The changed-files list extends by `core/engine/position.dart`
  and `content/save/actor_codec.dart` for the comparator move.

## Assumptions taken (pre-declared to the architect, proceeding unless overruled)

1. `byRowThenColumn` MOVES from `content/save/actor_codec.dart` into `core/engine/position.dart`;
   content imports it from core. Core cannot import content, and the targeting tie-break needs it.
2. Spell books ride `armory.dart` rather than a new `spell_books.dart, so`baseItemById` and the
   item codec keep working with one registry.
3. Mana refills only on arriving at a depth this run has never built (`_arriveBelow` when
   `state.floors[depth] == null`), NOT on every `_arriveOn`. Refilling on every arrival makes the
   documented stairs-bounce a free infinite-healing loop the moment Mend exists.
4. `bound` is cleared on arriving at any floor. Monster ids are unique per FLOOR, not per run, so
   a `bound` entry would otherwise bind a different monster of the same id on the next floor.
   `warded` is carried across stairs — it is on the hero, not the floor.
5. `resumeRun` RESTORES mana/ward/bound from the suspended run (contract 4 and the suspend
   theorem), not "starts full" as the changed-files bullet says.

## File structure

**Create (core):**

- `packages/core/lib/src/magic/spell.dart` — `DamageType,`SpellKind, `School` extension on
  `SkillId,`Spell` value object.
- `packages/core/lib/src/magic/read.dart` — `readRefusal, shared by dungeon and town.
- `packages/core/lib/src/magic/target.dart` — `nearestVisibleEnemy, the deterministic rule.
- `packages/core/lib/src/magic/mana.dart` — `heroMaxMana`. (Deviation from the spec's
  `loot/loadout.dart` placement: mana is a magic concept, and `loadout.dart` is the gear/skill
  derivation file. Same package, same import graph. Pre-declared.)

**Create (content):** `packages/content/lib/src/spells.dart` — the six spells and `spellsById`.

**Create (tests):** `core/test/magic/spell_test.dart,`core/test/magic/read_test.dart, `core/test/magic/target_test.dart,`core/test/magic/mana_test.dart, `core/test/engine/step_cast_test.dart,`core/test/engine/step_read_test.dart, `core/test/engine/step_ward_test.dart,`core/test/engine/step_bind_test.dart, `content/test/spells_test.dart,`content/test/save/version_gate_test.dart`.

**Modify:** as listed per task below.

---

### Task 1: The three school skills

**Files:**

- Modify: `packages/core/lib/src/skills/skill.dart`
- Test: `packages/core/test/skills/skill_test.dart`

**Interfaces:**

- Produces: `SkillId.wrath,`SkillId.mending, `SkillId.binding`; `untrainedSkills` with 7 entries.

- [ ] **Step 1: Write the failing test** — the enum appends after `fleetfoot` and untrained
      skills covers every case.

```dart
test('the three schools append after the four shipped skills', () {
  // arrange
  const shipped = [SkillId.arms, SkillId.might, SkillId.bulwark, SkillId.fleetfoot];

  // act
  final values = SkillId.values;

  // assert — appended, never reordered: the save's skills block is written in enum order
  expect(values.take(4), shipped);
  expect(values.skip(4), [SkillId.wrath, SkillId.mending, SkillId.binding]);
});

test('every skill starts untrained', () {
  // arrange
  // act
  final untrained = untrainedSkills;

  // assert
  expect(untrained.keys, SkillId.values);
  expect(untrained.values, everyElement(const SkillState()));
});
```

- [ ] **Step 2: Run to verify it fails.** `cd packages/core && flutter test test/skills/skill_test.dart`
      Expected: FAIL, `wrath` is not defined.
- [ ] **Step 3: Append the three cases** to `enum SkillId` after `fleetfoot, add the three entries
      to`untrainedSkills, and update the file's dartdoc from "four skills" to seven, naming the
      learn-by-doing trigger for the schools (one xp per successful cast of that school).
- [ ] **Step 4: Run the whole core suite.** Expected: PASS. The skills-block goldens live in
      `content, so`content` is expected to red at this point — that is Task 9's work. Keep this
      commit green by running core only, then land Task 1 and Task 9 in one commit if content reds.
- [ ] **Step 5: Commit** `feat(core): add the three spell-school skills`.

---

### Task 2: `DamageType,`SpellKind` and the `Spell` value object

**Files:**

- Create: `packages/core/lib/src/magic/spell.dart,`packages/core/test/magic/spell_test.dart`
- Modify: `packages/core/lib/core.dart` (export)

**Interfaces:**

- Produces: `enum DamageType { fire, frost }` with `marking` and `word`;
  `enum SpellKind { bolt, mend, ward, bind, banish }`;
  `class Spell` with `id,`name, `school,`manaCost, `requiredLevel,`kind, `type,`min, `max`; `extension School on SkillId` with `isSchool,`schoolWord, `schoolMarking`.

- [ ] **Step 1: Write the failing tests.**

```dart
test('a bolt carries the damage type it deals', () {
  // arrange
  const bolt = Spell(
    id: 'firebolt', name: 'Firebolt', school: SkillId.wrath,
    manaCost: 2, requiredLevel: 0, kind: SpellKind.bolt,
    type: DamageType.fire, min: 2, max: 4,
  );

  // act
  final type = bolt.type;

  // assert
  expect(type, DamageType.fire);
});

test('a spell whose school is not a school is refused at construction', () {
  // arrange
  // act
  spell() => Spell(
    id: 'bad', name: 'Bad', school: SkillId.arms,
    manaCost: 1, requiredLevel: 0, kind: SpellKind.mend, min: 1, max: 1,
  );

  // assert
  expect(spell, throwsA(isA<AssertionError>()));
});

test('a bolt without a damage type is refused at construction', () { /* ... */ });
test('a spell whose min exceeds its max is refused at construction', () { /* ... */ });
test('a spell costing no mana is refused at construction', () { /* ... */ });
test('a damage type reads without hue: a marking and a word', () {
  // arrange
  // act
  final markings = {for (final type in DamageType.values) type.marking};

  // assert — the Rarity pattern: a glyph plus a word, legible in greyscale
  expect(markings, hasLength(DamageType.values.length));
  expect(DamageType.fire.word, 'fire');
});
test('each school carries its own word and marking', () { /* ... */ });
```

- [ ] **Step 2: Run to verify they fail.** Expected: FAIL, `Spell` is not defined.
- [ ] **Step 3: Write `spell.dart`.** `Spell` is an `Equatable` with a `const` constructor whose
      asserts enforce: school is one of the three; `manaCost > 0`; `requiredLevel >= 0`;
      `type != null` exactly when `kind == SpellKind.bolt`; `min <= max`; and `min == max` for
      `ward`. Dartdoc states why `DamageType` ships with only `fire` and `frost` (YAGNI — the other
      five arrive with weapon typing, M4/M5).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): add the Spell value object and damage types`.

---

### Task 3: `heroMaxMana`

**Files:** Create `packages/core/lib/src/magic/mana.dart,`packages/core/test/magic/mana_test.dart`.

**Interfaces:** Produces `int heroMaxMana(Loadout loadout),`const int baseMana, `const int manaPerSchoolLevels`.

- [ ] **Step 1: Write the failing tests** — an untrained hero has the base pool; the three school
      levels sum and halve; a non-school skill contributes nothing.

```dart
test('an untrained hero carries the base pool', () {
  // arrange
  const loadout = Loadout(equipment: {}, skills: untrainedSkills);

  // act
  final max = heroMaxMana(loadout);

  // assert
  expect(max, baseMana);
});

test('the three schools sum and halve, and nothing else counts', () {
  // arrange
  final loadout = Loadout(equipment: const {}, skills: {
    ...untrainedSkills,
    SkillId.wrath: const SkillState(level: 3),
    SkillId.mending: const SkillState(level: 2),
    SkillId.binding: const SkillState(level: 1),
    SkillId.arms: const SkillState(level: 40),
  });

  // act
  final max = heroMaxMana(loadout);

  // assert — (3 + 2 + 1) ~/ 2 == 3, and Arms buys no mana at all
  expect(max, baseMana + 3);
});
```

- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Write `mana.dart`** with the two constants named so tuning is one edit, and dartdoc
      arguing why mana is derived from the schools rather than stored.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): derive the hero's mana pool from the school skills`.

---

### Task 4: `byRowThenColumn` moves to core, and the targeting rule

**Files:**

- Modify: `packages/core/lib/src/engine/position.dart` (add `byRowThenColumn`), `packages/content/lib/src/save/actor_codec.dart` (delete it, import from core).
- Create: `packages/core/lib/src/magic/target.dart,`packages/core/test/magic/target_test.dart`.

**Interfaces:** Produces `int byRowThenColumn(Position, Position)` (moved, unchanged), `int chebyshevTo(Position)` on `Position, and
`Actor? nearestVisibleEnemy(List<Actor> monsters, Set<Position> visible, Position from)`.

- [ ] **Step 1: Write the failing tests.**

```dart
test('the nearest visible enemy is the one chosen', () { /* two monsters, closer wins */ });
test('distance is Chebyshev, so a diagonal neighbour beats a tile two east', () { /* ... */ });
test('an invisible enemy is never chosen, however close', () { /* ... */ });
test('a tie is broken by row then column, so the choice is deterministic', () {
  // arrange — two monsters equidistant from the hero
  // act — the rule is asked twice
  // assert — the same monster both times, and it is the upper one
});
test('no visible enemy yields null rather than throwing', () { /* ... */ });
```

- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Move `byRowThenColumn` into `position.dart`** verbatim (dartdoc included), delete
      it from `actor_codec.dart, and let`actor_codec.dart` pick it up from its existing
      `package:residuum_core/core.dart` import. Write `target.dart` with dartdoc stating the rule
      and that it draws nothing.
- [ ] **Step 4: Run both suites.** Expected: PASS, and content's existing sort callers unchanged.
- [ ] **Step 5: Commit** `refactor(core): move byRowThenColumn to core and add the targeting rule`.

---

### Task 5: Spell books as base items

**Files:** Modify `packages/core/lib/src/loot/item.dart,`packages/core/lib/src/loot/drop.dart:87`;
tests`packages/core/test/loot/item_test.dart, `packages/core/test/loot/drop_test.dart`.

**Interfaces:** Produces `BaseItem.teaches: String?,`bool get isSpellBook, `bool get isConsumable => isPotion || isSpellBook`.

- [ ] **Step 1: Write the failing tests** — a book knows what it teaches, a book is consumable, a
      book is not equippable, and `rollDrop` forces a book to Common.

```dart
test('a spell book is forced to Common, for the potion\'s reason', () {
  // arrange — a table whose only item is a book and whose rarities all say Epic
  final table = DropTable(
    items: const [Weighted(bookBase, 1)],
    rarities: const [Weighted(Rarity.epic, 1)],
    weaponAffixes: weaponAffixes, armourAffixes: armourAffixes,
    minFloorItems: 0, maxFloorItems: 0,
  );

  // act
  final rolled = rollDrop(table, Rng(1), 'drop-1');

  // assert — an affixed book would lie about table rarity
  expect(rolled.rarity, Rarity.common);
  expect(rolled.affixes, isEmpty);
});
```

- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Add `teaches` to `BaseItem`** (constructor, field, `props`), add the two
      predicates, and switch `drop.dart:87` from `base.isPotion` to `base.isConsumable`. Extend the
      `rollDrop` dartdoc so the Common-forcing argument names books as well as potions.
- [ ] **Step 4: Run core.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): spell books are consumable base items forced to Common`.

---

### Task 6: `readRefusal` and `ReadAction`

**Files:**

- Create: `packages/core/lib/src/magic/read.dart,`packages/core/test/magic/read_test.dart, `packages/core/test/engine/step_read_test.dart`.
- Modify: `packages/core/lib/src/engine/action.dart,`engine/event.dart, `engine/step.dart,`engine/game_state.dart, `town/town.dart`.

**Interfaces:** Produces
`String? readRefusal(List<Item> inventory, Set<String> knownSpells, Map<SkillId, SkillState> skills, Map<String, Spell> spells, String itemId)`;
`final class ReadAction extends GameAction`; `final class SpellLearned extends GameEvent`;
`Transacted readBook(Profile profile, String itemId, Map<String, Spell> spells)`.

- [ ] **Step 1: Write the failing tests** — one per refusal sentence, in both contexts, plus the
      effect and the Drink-doctrine non-refusal.

```dart
test('reading what the hero is not carrying is refused', () { /* 'you are not carrying that' */ });
test('reading something that is not a book is refused', () {
  // assert — mirrors the drink wording
  expect(refusal, 'Healing Potion is not something to read');
});
test('reading a spell the hero already knows is refused', () {
  // assert
  expect(refusal, 'you already know Firebolt');
});
test('reading past a school gate is refused, and the reason names the gate', () {
  // assert
  expect(refusal, 'needs Wrath 4');
});
test('a book the hero could save for later is NOT refused', () {
  // assert — the Drink doctrine: a wasteful use is the player's to make
  expect(refusal, isNull);
});
test('reading learns the spell, spends the book and passes the turn', () {
  // assert
  expect(after.knownSpells, contains('firebolt'));
  expect(after.inventory.map((item) => item.id), isNot(contains('kit-4')));
  expect(events, contains(const SpellLearned(spellId: 'firebolt')));
});
test('the town refuses in the same words the dungeon does', () { /* both halves */ });
```

- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement.** `readRefusal` returns a plain string in the `wearRefusal` style.
      `step` wraps it in `ActionRefused`; `readBook` wraps it in `TownRefusal`. The effect adds the
      spell id to `knownSpells, removes the book by the filter-by-id idiom, emits`SpellLearned,
      and falls through to the monster phase. Dartdoc on `ReadAction` cites the Drink doctrine.
- [ ] **Step 4: Run core.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): read a spell book to learn its spell, in the dungeon or in town`.

---

### Task 7: Mana, ward and bound on `GameState`; the cast action and its five effects

**Files:** Modify `engine/game_state.dart,`engine/action.dart, `engine/event.dart,`engine/step.dart`; create`core/test/engine/step_cast_test.dart, `core/test/engine/step_ward_test.dart,`core/test/engine/step_bind_test.dart`.

**Interfaces:** Produces `GameState.mana,`.warded, `.bound,`.knownSpells, `.spells`;
`copyWith` exposing `mana`/`warded`/`bound`/`knownSpells` only;
`final class CastSpellAction extends GameAction`; events `SpellHit,`MendCast, `WardRaised,`WardStruck, `MonsterBound,`MonsterBanished`.

- [ ] **Step 1: Write the failing tests**, one behaviour each: unknown-spell refusal;
      not-enough-mana refusal; no-enemy-in-sight refusal for bolt/bind/banish; mend at full health
      NOT refused; bolt damage from exactly one `rng` draw; resistance halves rounding down with a
      floor of one; vulnerability doubles; a kill through a bolt still draws its spoils from
      `lootRng`; mend caps at missing hp and draws nothing; ward replaces rather than stacks;
      bind sets the counter to three; banish moves the target with exactly one draw; every
      successful cast spends mana and trains its school.

```dart
test('a bolt against a resistant target is halved, rounding down, with a floor of one', () {
  // arrange — a creature that resists fire, and a seed whose roll is known
  // act
  // assert
  expect(hit.damage, 2);
});

test('a bolt draws exactly one number from the combat stream', () {
  // arrange
  final before = game.rng.state;

  // act
  final (after, _) = step(game, const CastSpellAction('firebolt'));

  // assert — one advance, no more: the whole game's spine is this stream
  expect(_advancesBetween(before, after.rng.state), 1);
});
```

- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement.** Add the fields (`spells` carried by identity like `dropTables, never
      in`copyWith`). Add the`CastSpellAction` arm to `_refuse` and to the dispatch. Targeting uses
      Task 4's rule. Dartdoc where the cast lands states the auto-target rule and its tie-break,
      and why mana lives on `GameState` rather than `Actor` or `Profile`.
- [ ] **Step 4: Run core.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): cast spells from a per-floor mana pool`.

---

### Task 8: Ward in `_defend, bound in the monster phase, mana refill and bind cleanup

**Files:** Modify `engine/step.dart` (`_defend,`_monsterPhase, `_arriveOn,`_arriveBelow`).

- [ ] **Step 1: Write the failing tests.**

```dart
test('a ward absorbs after the floor of one, and the hero loses only the remainder', () {
  // assert
  expect(after.hero.hp, before.hero.hp - 1);
  expect(after.warded, 4);
  expect(events, contains(const WardStruck(absorbed: 2)));
});
test('a fully absorbed blow emits no AttackHit, because no hit points dropped', () { /* ... */ });
test('defence still trains on an absorbed blow', () { /* ... */ });
test('the ward adds no roll to the combat stream', () { /* rng state advance is unchanged */ });
test('a bound monster skips its scheduled turn and the counter falls', () { /* ... */ });
test('a bound monster still takes damage and dies normally', () { /* ... */ });
test('a bound entry does not outlive the monster it named', () { /* ... */ });
test('a bind does not survive a stairway', () {
  // assert — monster ids are unique per floor, not per run
  expect(after.bound, isEmpty);
});
test('mana refills on arriving at a floor this run has never built', () { /* ... */ });
test('bouncing back to a floor already walked refills nothing', () {
  // assert — the stairs bounce is two free actions; a refill here would be a healing loop
  expect(after.mana, spent);
});
```

- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement.** In `_defend, after the existing floor-of-one damage:
      `absorbed = min(warded, damage), hp loses `damage - absorbed,`warded` shrinks, `WardStruck`
  when `absorbed > 0, `AttackHit` only when hp actually drops, defence trains either way, and
      no new draw. In `_monsterPhase, a bound monster skips and decrements. In`_arriveOn, clear
      `bound`; in `_arriveBelow, refill mana only when the floor was never built.
- [ ] **Step 4: Run core.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): wards absorb, binds hold, and mana is a per-floor budget`.

---

### Task 9: `knownSpells` through the four run-boundary doors

**Files:** Modify `core/town/profile.dart,`core/town/run_boundary.dart`;
tests`core/test/town/profile_test.dart, `core/test/town/run_boundary_test.dart`.

- [ ] **Step 1: Write the failing tests** — known spells reach the crawl at `startRun, come home
      at`endRun, survive death like skills do, survive `suspendRun`/`resumeRun, and appear in
      `Profile.props`.
- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement.** `Profile.knownSpells` (unmodifiable set, `copyWith,`props`), copied
      at all four doors;`mana` starts full at `startRun` and is RESTORED at `resumeRun`; the
      `spells` registry is injected at `startRun` and carried from the suspended run at `resumeRun`.
- [ ] **Step 4: Run core.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): known spells survive death exactly as skills do`.

---

### Task 10: The version gate, save version 2, and the goldens by hand

**Files:** Create `content/test/save/version_gate_test.dart`; modify
`content/lib/src/save/save_codec.dart,`profile_codec.dart, `run_codec.dart,`actor_codec.dart`; rewrite the three goldens in`content/test/save/golden_save_test.dart`.

**Sequencing trap:** the v1 fixture is captured in `docs/reports/V1-GOLDENS-CAPTURED.txt`
BEFORE this task's rewrite. Write the refusal test first, against that captured string.

- [ ] **Step 1: Write the failing characterization test** — the captured v1 document is refused by
      the version-2 gate, with the version sentence.
- [ ] **Step 2: Run to verify it fails** (it passes today, because today's version IS 1 — so it
      goes red the moment `saveVersion` becomes 2, which is the point; write it, watch it fail
      against the version-1 gate for the right reason, then bump).
- [ ] **Step 3: Implement.** `saveVersion = 2`. New required keys, never defaulted: profile
      `knownSpells` (sorted list); run `mana,`warded, `bound` (sorted by monster id), `knownSpells`; actor `resists,`vulnerableTo` (sorted name lists, present even when empty).
      `encodeSkills` grows to seven by the enum.
- [ ] **Step 4: Rewrite the three goldens BY HAND**, quoting the old strings in the commit message.
- [ ] **Step 5: Run content.** Expected: PASS.
- [ ] **Step 6: Commit** `feat(content): save version 2 carries spells, mana and resistances`.

---

### Task 11: The six spells (content)

**Files:** Create `content/lib/src/spells.dart,`content/test/spells_test.dart`; modify
`content/lib/content.dart, `content/lib/src/new_game.dart,`content/test/content_validation_test.dart`.

- [ ] **Step 1: Write the failing content pins** — each spell's exact numbers, and the validation
      clauses: every spell's school is a real school skill; every book's `teaches` names a real
      spell; every spell has exactly one book; resist and vulnerable sets are disjoint per creature;
      the glyph set assertion grows to `{')', '[', '!', '?'}`.
- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Write `spells.dart`** with the six spells and `spellsById, gates as named
      constants. Fresh heroes know no spells and start at`heroMaxMana`.
- [ ] **Step 4: Run content.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(content): the six first spells`.

---

### Task 12: Books, distribution and the price term

**Files:** Modify `content/lib/src/armory.dart,`economy.dart, and whichever tables Q1 names;
tests `content/test/economy_test.dart,`content/test/content_validation_test.dart`.

- [ ] **Step 1: Write the failing tests** — the book price term, the exclusivity rule Q1 settles,
      and the extended shelf-count pin.
- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement.** Six book `BaseItem`s in `armory.dart` with glyph `?` and `teaches`;
      `sellPriceOf` gains the book term (`10 + requiredLevel, looked up by`teaches`). Crypt drops
      `bind` and `firebolt`; the sea-cave drops`mend` and `frost-lance`; the ruined keep drops
      `ward` and `banish`; weight 0 in every other table including`roadDropTable` and both trophy
      tables; `marketTable` carries `firebolt` and `mend` at low weight.
- [ ] **Step 4: Run the band suite and TUNE.** The lines move by design. Iterate book weights (and,
      only if a soft band or the ordering breaks, that dungeon's own litter and drop chances) until
      every line sits inside 0.45-0.80 with keep below cave. Every configuration tried goes in
      `docs/reports/TUNING-TRAIL.md, failures kept. Re-pin the four lines at convergence.
- [ ] **Step 5: Commit** `feat(content): spell books, priced and distributed`.

---

### Task 13: Resistances in the bestiaries — needs a measured trail

**Files:** Modify `content/lib/src/bestiary.dart,`sea_cave.dart, `ruined_keep.dart`;
`content/test/content_validation_test.dart`.

- [ ] **Step 1: Write the failing exclusivity test** — no creature both resists and is vulnerable
      to one type; every themed dungeon has at least one resistant and one vulnerable creature.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Add resistance fields ONLY.** No hp/attack/pierce/speed/dropChance moves. Starting
      trail: ghoul and wight vulnerable to fire; drowned creatures resist frost and are vulnerable
      to fire; the keep's armoured men resist fire and are vulnerable to frost.
- [ ] **Step 4: Run content INCLUDING the bands.** Expected: the four lines are UNCHANGED from
      Task 12's convergence — the bot never casts, so resistances are inert to it, and that is the
      proof they are. A line that moves here is a defect, not a re-pin.
- [ ] **Step 5: Record the trail** in `docs/reports/TUNING-TRAIL.md, then **commit**
      `feat(content): creatures resist and burn`.

---

### Task 14: The app — Spells section, Books section, mana readout, log lines

**Files:** Modify `app/lib/game/game_bloc.dart,`inventory_screen.dart, `item_presentation.dart,`event_messages.dart, `game_screen.dart,`app/lib/town/gear_screen.dart, `town_bloc.dart`;
tests `app/test/game_bloc_test.dart,`item_presentation_test.dart, `town_bloc_test.dart,`app/test/widget/palette_test.dart`.

- [ ] **Step 1: Write the failing bloc tests** — `ReadPressed` and `CastPressed` reach the rules;
      the view state carries `mana,`maxMana, `knownSpells` and a reason per spell; a locked book
      row carries its reason sentence; `PackSection.books` renders in the fixed order and
      `_sectionOf` no longer falls through.
- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement.** Spells section at the TOP of the pack screen: school word plus
      marking, mana cost, Cast button, reason sentence when disabled. Books rows get Read with a
      reason. Mana joins the STATUS area as `Mana n/m` — no sixth HUD control. Town gear screen
      grows a Books section so books are not invisible. Log lines carry the information the spec
      names.
- [ ] **Step 4: Run app.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(app): cast spells, read books, and read the mana`.

---

### Task 15: The suspend theorem extended

**Files:** Modify `content/test/save/suspend_theorem_test.dart`.

- [ ] **Step 1: Write the failing test** — suspend mid-run with mana spent, a ward up and a
      monster bound; resume must be roll-for-roll identical.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Fix whatever it catches.**
- [ ] **Step 4: Run content.** Expected: PASS.
- [ ] **Step 5: Commit** `test(content): the suspend theorem covers mana, wards and binds`.

---

### Task 16: Verification

- [ ] All three suites from their package directories; counts above 1361 with the delta stated.
- [ ] The four band lines from the FINAL commit, quoted verbatim, matching the re-pinned figures,
      with every soft band and the keep-below-cave ordering holding.
- [ ] `dart analyze .` and `dart format --set-exit-if-changed .` from the worktree ROOT, pwd quoted.
- [ ] The full mutation table, rows 1-12 red as NAMED SETS with clean reverts, both halves of rows
      4 and 5. **Row C1 is struck by ruling 1** and annotated as such in the report; C2, C3 and C4
      run and stay green.
- [ ] AVD pass: the shots the spec lists, greyscale copies, v1 refusal proven on device, both
      device save slots copied aside and SHA256-verified restored.
- [ ] Report mirrored to `docs/reports/BUILD-REPORT.md`; tuning trail complete.
