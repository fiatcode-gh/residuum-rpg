# m3-battle (unit A) Implementation Plan

> Execute task by task, test-first; every commit's exit state is green.

**Goal:** ambush opening, explicit cast targeting, `reach` field + the spitter,
band re-baseline via measured trail, casting-bot informational line.
**Spec:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-spec-M3U.md`

## Global constraints

- Worktree `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle,
  branch `m3-battle, baseline `8168861`. Commits land on `m3-battle` only.
- Fresh baseline measured 2026-09-02: core 762 + content 533 + app 515 = 1810,
  all green (JSON result files in /tmp/m3-battle-baseline/).
- Characterization tests proven passing against unmodified `8168861`
  (golden save byte-identical 6/6; monsters/cast/target 53; descend 17 incl.
  the new adjacent-arrival pin).
- Characterization (existing pins quoted passing on base): adjacent-claw
  (`step_monsters_test.dart`), nearest-enemy + row-then-column ties
  (`target_test.dart`), refusal order unknown→mana→empty room
  (`step_cast_test.dart`), arrival safety (`step_descend_test.dart` + new
  adjacent-arrival pin), golden save byte identity.
- Author persona ; explicit paths
  only; nothing under `docs/` is ever committed.
- No app-package changes; no device work; no pushes/PRs.
- Mutation table M1–M6 runs at the end, both halves as named sets.

## Pinned arithmetic (worker's to pin, per spec)

**Ambush opening.**
- `_holdsReach(state, monster, heroPos)`: true when
  `monster.position.isOrthogonallyAdjacentTo(heroPos)` (any reach), or when
  `monster.reach > 1 && state.visible.contains(monster.position) &&
  monster.position.chebyshevTo(heroPos) <= monster.reach`.
- Snapshot `reachedAtStart` (set of monster ids) at the top of `step(), after
  refuse/flee, before the hero action switch — turn-start hero position,
  turn-start `state.visible`.
- In `_monsterPhase, an **opening pass** runs before the owed loop, in
  monster-list order: a monster that (1) is alive, (2) is not bound, (3) was
  NOT in `reachedAtStart, and (4) holds reach on the hero's post-action
  position, swings once via `_defend` — even if the clock does not owe it.
- If the opener was owed a turn this phase, the opening consumes exactly one
  occurrence of its owed turn (it does not swing again as its owed turn; a
  second owed occurrence, for a speed-20 monster, still runs).
- An unowed opener's energy is charged `actCost` at the phase's end:
  `energy = owed.monsterEnergies[index] - actCost`. An owed opener's energy is
  `owed.monsterEnergies[index]` (the schedule already spent it).
- **Lunge:** in the owed loop, after a monster's flow-field step, if it now
  holds reach it swings once via `_defend`. The move bought the lunge — no
  extra energy, exactly `_defend`'s draws. (Chase gets teeth; one move + one
  swing per owed turn.)
- Bound monsters never ambush (their counter still decrements when owed).
- Arrival never ambushes: arrivals return before any monster phase, and a
  fresh floor's monsters are in reach at turn start, so the snapshot excludes
  them from openings.
- Draw order: opening pass in monster-list order, then the owed loop.

**Ranged branch** (beside the adjacency branch): adjacent → melee `_defend`;
else `reach > 1 && state.visible.contains(m.position) &&
m.position.chebyshevTo(hero) <= m.reach` → shoot from where it stands; else
walk (and lunge if the step lands it in reach). A spitter that steps into a
tile the hero's turn-start FOV does not hold does not shoot until the hero's
next turn — pinned as deliberate.

**Cast targeting.** `CastSpellAction(spellId, {targetId})`. Refusal order
unknown → mana → target; with a target on a targeted kind, refusal
`'you cannot see that target'` unless a monster with that id stands in
`state.visible`; mend/ward ignore the target. No target → nearest fallback,
unchanged. `_targetOf` honours the explicit id (refusal already validated
visibility). Events unchanged.

**Reach codec.** `Actor.reach`/`CreatureSpec.reach, default 1, assert ≥ 1 on
Actor. Encode `'reach'` only when != 1; decode absent as 1. Goldens stay
byte-identical (control run before and after the codec commit).

## Task 1: characterization commit

- [x] Arrival-adjacent pin added to `step_descend_test.dart`; all
  characterization files quoted passing against unmodified `8168861`.
- [ ] Commit: `test: pin arrival safety beside an adjacent monster`
  (packages/core/test/engine/step_descend_test.dart).

## Task 2: reach field + omit-on-default codec

**Files:** `packages/core/lib/src/engine/actor.dart, `packages/content/lib/src/bestiary.dart, `packages/content/lib/src/save/actor_codec.dart, `packages/content/test/content_validation_test.dart, `packages/content/test/save/actor_codec_test.dart` (or save/ tests).

- [ ] Red: reach-default decode test (no `reach` key → 1), spitter-less
  round-trip, validation pin `reach == 1` for all 14 existing creatures by id.
- [ ] Green: `Actor.reach` (default 1, assert ≥ 1, copyWith carries it), `CreatureSpec.reach` (default 1, spawn passes it), codec omit-on-default.
- [ ] Golden save tests green immediately before AND after this commit.
- [ ] Commit: `feat: the reach field rides the save only when it is not one`

## Task 3: the spitter + crypt d1/d2 tables + content pins

**Files:** `bestiary.dart, `spawn_tables.dart, `content_validation_test.dart, `designed_difficulty_test.dart, `dungeon_door_characterization_test.dart`.

- [ ] Spitter: id `spitter, `the spitter, glyph `p, hp 7, 2–3, speed 5,
  dropChance 40, pierce 0, reach 3. Crypt d1: rat 6, wolf 1, spitter 1;
  d2: rat 3, wolf 2, ghoul 2, spitter 1. Counts unchanged.
- [ ] Pins: `hasLength(5)`→`6` (crypt), `hasLength(14)`→`15` (game-wide);
  reachability (computed set) gains spitter; glyph checks pass; speed set
  still contains 5; new test: spitter in no depth ≥ 3 table.
- [ ] DEVIATION (declared, non-hold): the computed shallow set in
  `designed_difficulty_test.dart` gains `spitter, so the named pin
  `{'rat','wolf','ghoul','crab'}` must become `{'rat','wolf','ghoul','crab','spitter'}`
  (old value quoted in the commit) — the spec's "the shallow-exempt set is
  not edited" cannot hold while every commit stays green; the exemption
  mechanism itself is untouched.
- [ ] Re-pin `_openingMonsters` at seed 4242 in the SAME commit, old value
  `['rat-1', 'wolf-2', 'rat-3']` quoted in the dartdoc.
- [ ] Commit: `feat: the spitter stands in the crypt's shallow floors`

## Task 4: ambush opening

**Files:** `packages/core/lib/src/engine/step.dart, `packages/core/test/engine/step_ambush_test.dart` (new).

- [ ] Red first: (a) lunge — move creates adjacency → swing same phase;
  (b) hero closes → opening swing unowed, energy charged; (c) in-reach-at-start
  monster gets no unowed second swing; (d) arrival never ambushes; opener owed
  → exactly one swing that phase; bound monsters never ambush.
- [ ] Green: snapshot + opening pass + owed-consumption + energy charge, per
  the pinned arithmetic above.
- [ ] Commit: `feat: the ambush opening`

## Task 5: ranged branch

**Files:** `step.dart, `packages/core/test/engine/step_ranged_test.dart` (new).

- [ ] Red first: shoot at distance 2–3 with LoS standing still; distance 1 →
  adjacency branch; beyond reach or without LoS → walks; dodged/warded shots
  per `_defend`; zero new draw kinds; corner-delay pin (stepping into a tile
  the hero could not yet see buys no shot this turn).
- [ ] Green: the branch beside adjacency, per pinned arithmetic.
- [ ] Commit: `feat: monsters with reach shoot from line of sight`

## Task 6: explicit cast targeting

**Files:** `action.dart, `step.dart, `step_cast_test.dart` (extend).

- [ ] Red first: explicit in-sight target honored (bolt/bind/banish);
  out-of-sight target refuses `'you cannot see that target'`; mend/ward accept
  and ignore a target; no-target casts keep nearest fallback + refusal order.
- [ ] Green per pinned arithmetic.
- [ ] Commit: `feat: a cast may name its target`

## Task 7: casting bot + band trail + re-pins

**Files:** `packages/content/test/survivability_test.dart`.

- [ ] `_Build.casting`: adjacent-attack first; read the carried Firebolt book
  when the spell is unknown; cast the known bolt at the fallback nearest enemy
  when one is visible and mana allows; otherwise the melee priority unchanged.
  Kit: `survivabilityKit(worldSeed)` + one Book of Firebolt; door
  `startDungeonRunAt(cryptNode, …)` (declared deviation: door is the
  graduate-kit door, the only one that can carry the book).
- [ ] Trail rows (recorded in this file's trail section AND commit messages):
  row 1 = ambush rule alone; row 2 = ambush + spitter; keep failed
  configurations as rows.
- [ ] New print `casting build: X/40 won` pinned to its measured value; the
  four band lines re-pinned BY HAND with old values quoted in the dartdoc;
  dead-weight-book narrative updated (old sentence quoted).
- [ ] Commit: `feat: the casting bot judges the new fight`

## Task 8: mutation table M1–M6 (no commits; mutate → run → revert → verify clean)

Per the spec's table; reds as named sets; both halves reported; `git status
--short` quoted after each row.

## Task 9: verification block + REPORT.md + done notice

- [ ] All three suites green from own result files; analyze + format clean
  from the worktree root with pwd quoted; REPORT.md in the channel directory;
  done notice appended to worker.md.

## Trail (filled during Task 7)

| Row | Delta | crypt | sea-cave | keep | greedy/exploit | casting |
|---|---|---|---|---|---|---|
| baseline | 8168861 | 20/40 {1:1,2:6,3:6,4:7,5:20} | 30/40 {2:1,3:8,4:13,5:9,6:9} | 25/40 {1:4,2:5,3:4,4:2,5:13,6:6,7:6} | 20/14 | — |
| row 1 | ambush opening (076bc7d) | 19/40 {2:7,3:6,4:8,5:19} | 26/40 {2:3,3:7,4:14,5:11,6:5} | 24/40 {1:5,2:5,3:3,4:2,5:13,6:7,7:5} | 19/9 | — |
| row 2 | + spitter d1+d2, hp 7 (f73a2ed) | 18/40 {1:1,2:8,3:9,4:4,5:18} — exactly on the floor | 26/40 | 24/40 | 18/11 | — |
| row 3 (failed, kept) | ranged branch, spitter hp 7: 40.0% | 16/40 {1:1,2:8,3:9,4:4,5:16} | 26/40 | 24/40 | 16/12 | — |
| row 4 (failed, kept) | D77 d2-drop | 15/40 {1:1,2:9,3:6,4:9,5:15} — harder, reverted | 26/40 | 24/40 | 15/7 | — |
| row 5 (failed, kept) | D78 hp 4, reach 3 | 16/40 {1:1,2:9,3:8,4:6,5:16} | 26/40 | 24/40 | 16/13 | — |
| experiment (kept, reverted) | D79 reach 3→2 | 18/40 {1:1,2:9,3:8,4:4,5:18} — exactly on the floor | 26/40 | 24/40 | 18/11 | — |
| final row (landed, 0a03867) | D78+D79: hp 4, reach 3, floor 0.40 crypt-only | 16/40 {1:1,2:9,3:8,4:6,5:16} | 26/40 | 24/40 | 16/13 | 40/40 (6bef5fb) |