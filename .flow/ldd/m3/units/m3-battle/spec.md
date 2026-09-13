# Spec — `m3-battle` (story M3U, unit A of the battle overhaul)

Unit B (`m3-battle-ui, app only) is specced after this unit lands. This spec
implements the battle *rules*; unit B implements the battle *view*.

Forks locked by the user (D72/D74): battle is a view over the map; ambush =
first turn, never a free hit; ranged reach = LoS; modest spitter, crypt
depths 1–2; save v3 stands via default-encode; casting bot rides this unit.

## Goal

Combat gains three ruled changes, measured by the existing bot with a
documented band trail:

1. **Ambush opening:** when reach on the hero is newly created this turn —
   a monster steps adjacent, a spitter walks into shootable line of sight, or
   the hero's own move closes with a monster — the monster(s) that now hold
   reach attack in this turn's monster phase even if the clock does not owe
   them. The chase gets teeth and "it caught me" has a consequence.
2. **Explicit cast targeting:** `CastSpellAction` may name its target; the
   nearest-enemy rule becomes the fallback for casts that name none.
3. **Ranged monsters:** a `reach` stat; a monster with reach > 1 attacks from
   within `reach` tiles when it holds line of sight, and stands its ground
   while shooting. Proven end to end by one new creature, **the spitter**.

Measurable effect: the band lines move (ambush openings + a new crypt
creature) and are re-pinned through a measured trail; the casting-bot line
(follow-up 29) exists to judge the new fight. Everything else — turn loop,
save version, suspend theorem, road fights, boss placement — holds.

## Shape — precedent to follow, read from the codebase

- **Ambush arithmetic:** `_built`'s fresh-clock precedent
  (`step.dart` — generated monsters at `actThreshold`) plus `_arriveOn`'s
  "arrival runs no monster phase". The ambush is *energy arithmetic plus a
  reach snapshot*, never a new roll.
- **House ambush voice:** `encounter_map.dart` — "on the road the ambush has
  already happened". Road fights open with attackers in plain sight and never
  adjacent (validator); encounter *construction* does not ambush.
- **Ranged branch:** beside the existing adjacency branch in `_monsterPhase`
  (`step.dart` ~585). The attack pipeline `_defend` is reused verbatim —
  dodge gate, armour minus pierce, floor of one, ward. The reach test is
  pure: `state.visible.contains(monster.position) &&
  monster.position.chebyshevTo(hero.position) <= monster.reach`. It draws
  nothing (the `nearestVisibleEnemy` precedent: "It draws nothing").
- **Targeting refusal order:** `_castRefusal`'s documented contract — "an
  empty pool is answered before an empty room". Unknown spell → mana →
  target, preserved.
- **Band re-baseline:** the M3B trail method (`936ca5b`): after every content
  delta, re-run the survivability suite, record all band lines as one trail
  row, keep failed configurations as rows, iterate to targets, then re-pin
  exact figures in test source with each old pin quoted in the dartdoc.

## New files

- `packages/core/test/engine/step_ambush_test.dart` — ambush openings.
- `packages/core/test/engine/step_ranged_test.dart` — reach/LoS attacks.

## Changed files (exact paths)

- `packages/core/lib/src/engine/action.dart` — `CastSpellAction` gains
  `String? targetId`.
- `packages/core/lib/src/engine/actor.dart` — `Actor.reach` (default 1).
- `packages/core/lib/src/engine/step.dart` — ambush opening; ranged branch in
  `_monsterPhase`; explicit-target validation in `_castRefusal`/`_castSpell`;
  `_targetOf` honours an explicit target.
- `packages/core/lib/src/engine/game_state.dart` — only if the reach
  snapshot needs a helper; prefer a local snapshot in `step()`.
- `packages/content/lib/src/bestiary.dart` — `CreatureSpec.reach` (default 1);
  the spitter.
- `packages/content/lib/src/spawn_tables.dart` — crypt d1/d2 entries.
- `packages/content/lib/src/save/actor_codec.dart` — reach, omit-on-default.
- `packages/content/test/content_validation_test.dart` — new pins (named
  below).
- `packages/content/test/survivability_test.dart` — casting build,
  informational line, band re-pins.
- `packages/content/test/designed_difficulty_test.dart` — only if the ruling
  below requires it (it should not).
- `packages/content/test/save/golden_save_test.dart` — must NOT change; its
  byte-identity is a control (see hazards).
- `packages/content/test/dungeon_door_characterization_test.dart` —
  `_openingMonsters` re-pinned in the same commit as the spawn-table change.

## Per-item contract

### 1. Reach field

- `CreatureSpec.reach` and `Actor.reach, `int, default 1, validated ≥ 1.
- reach = 1 means exactly today's behavior: attack only from orthogonal
  adjacency. **All fourteen existing creatures are behaviorally
  byte-identical** — a validation test pins `reach == 1` for every existing
  creature by id.
- Codec: `reach` is encoded **only when != 1**, decoded as 1 when absent.
  Existing v3 documents decode unchanged; the golden save documents stay
  byte-identical (this is asserted, not hoped).
- The ranged attack uses the untyped melee pipeline: `_defend` unchanged —
  dodge gate, roll, armour minus pierce, floor of one, ward. No damage type
  on ranged attacks; no to-hit roll; **zero new rng draws**.

### 2. The ambush opening

- At the top of `step()` (after the refuse/flee checks, before the hero
  action switch), snapshot the set of monsters currently holding reach on
  the hero (adjacent for reach-1 creatures; the LoS-reach test for reach > 1).
- In the monster phase that follows the hero's action, a monster that **was
  not in reach at turn start and is now** attacks in this phase even if the
  clock does not owe it — once, using exactly `_defend`'s draws, and it does
  not also attack again as its owed turn. Its energy is spent by the opening
  (the exact arithmetic is the worker's, pinned by named-set tests).
- A monster that moves into reach during the phase attacks in the same phase
  (its lunge) — this is the chase catching the hero.
- **Arrival never ambushes.** Floor arrival (both directions) keeps its
  documented safety; a fresh floor's monsters at `actThreshold` swing only
  when the clock owes them. This contract is pinned, not assumed.
- **Encounter construction never ambushes** (road fights: the ambush already
  happened — they are visible, not owed a hit). The spitter is not on roads,
  but the rule must state the exemption for the bestiary unit's future.
- The opening swing is the monster's only ambush; "never a free hit" means
  the opening uses the monster's action, it does not stack on one.

### 3. Explicit cast targeting

- `CastSpellAction(spellId, {targetId})`. With a target:
  - the spell must be known and affordable (existing checks, same order);
  - for targeted kinds (bolt, bind, banish) the target must be a visible
    enemy — else refusal `'you cannot see that target'`;
  - mend/ward ignore the target (they are cast on the hero) — passing one is
    not an error.
- With no target: today's nearest-enemy behavior, unchanged, including its
  refusal ordering. The Pack's cast path keeps working unchanged.
- The app's mirrored `castRefusal` (`game_bloc.dart`) is **not touched in
  this unit** (app code is unit B's); the optional parameter keeps every
  existing call site compiling. The drift hazard is recorded for unit B.
- Events unchanged: `SpellHit`/`MonsterBound`/`MonsterBanished` already carry
  the target id.

### 4. The spitter (bestiary ruling, user-approved D72/D74)

- id `spitter, name `the spitter, glyph `p, **hp 7, attack 2–3,
  speed 5, dropChance 40, pierce 0, reach 3**, no resist or vulnerability
  sets.
- Spawn tables: crypt d1 gains `SpawnEntry('spitter', 1)` (table becomes
  rat 6, wolf 1, spitter 1); crypt d2 gains `SpawnEntry('spitter', 1)`
  (rat 3, wolf 2, ghoul 2, spitter 1). Counts unchanged (3–4, 4–5).
- The spitter stands still while it can shoot; it walks only when its target
  is out of reach or unseen.

### 5. Content validation pins (exact new values)

- Crypt bestiary pin `hasLength(5)` → `hasLength(6)`; game-wide
  `hasLength(14)` → `hasLength(15)`.
- Reachability set gains `'spitter'` (exact set equality updated).
- Glyph `p` must pass the existing uniqueness/charset validation (verified
  unused against creatures, items `), `[, gathers `*, `", hero `@`).
- Designed-difficulty: the spitter stands only on depths 1–2, outside the
  depth ≥ 3 requirement — the shallow-exempt set is **not** edited; add a
  test line asserting the spitter appears in no depth ≥ 3 table.
- Speed-diversity pin {5, 10, 20} still holds (spitter is 5).

### 6. The casting bot (follow-up 29)

- New `_Build.casting` policy in `survivability_test.dart`: read a carried
  book when its spell is unknown; cast a known bolt at the fallback nearest
  enemy when one is visible and mana allows; otherwise the melee priority
  order, unchanged. The kit for this build carries one Firebolt book (the
  bot's dead-weight-book pin is updated, old value quoted).
- One new print line beside the four band lines, informational:
  `casting build: X/40 won`. Pinned to its measured value by the trail's end,
  old value quoted if re-pinned later. The four existing band lines keep
  their melee-bot meaning — the casting line is an ADDITIONAL line, never a
  replacement.

## Behaviour arguments that must land in documentation

- **The ambush is a turn, not a bonus.** The opening monster swings once and
  spends the opening; it does not stack with its owed turn. The sentence the
  player reads is "it got the drop on me", and the arithmetic must never say
  "it swung twice".
- **Arrival is still safe.** Descending has never let the floor swing first,
  and the ambush does not change that; a fresh floor ambushes nobody. Pin
  with a test so nobody "fixes" it.
- **Encounter construction does not ambush** — road monsters are seen, not
  owed a hit; the ambush fires on reach created *during play*.
- **reach defaults to 1 and stays invisible for every existing creature** —
  this is what lets the band trail attribute all movement to the ambush rule
  and the spitter, and what keeps v3 documents byte-identical.
- **The explicit target widens choice, never the rules' power:** an explicit
  out-of-sight target is a refusal, not an auto-correction to the nearest.
- **The casting bot knows the whole floor, like the melee bot** — same
  navigator, same honesty; the casting line measures content, not bot skill.

## Test plan

### Characterization first (against unmodified `8168861, must pass)

- `step_monsters_test.dart`'s existing pin: an adjacent monster claws the
  hero instead of moving (the branch the ranged rule sits beside).
- Nearest-enemy targeting: a bolt with no explicit target hits the nearest
  visible enemy, row-then-column ties; refusal ordering (unknown → mana →
  no-enemy-in-sight).
- Arrival safety: descending runs no monster phase even with a generated
  monster adjacent to the arrival tile (exists; do not weaken).
- Golden save documents decode/encode byte-identically (the v3 control).

### New tests (red first, then green)

- **Ambush:** (a) a monster whose move creates adjacency attacks in the same
  phase; (b) a hero who walks to adjacency eats the opening swing even when
  the clock does not owe it; (c) a monster already in reach at turn start
  does NOT get a second (unowed) swing; (d) arrival runs no ambush.
- **Ranged:** spitter at distance 2–3 with LoS shoots (no movement);
  spitter at distance 1 melee-attacks; spitter beyond reach or without LoS
  walks; a dodged shot and a warded shot behave exactly per `_defend`.
- **Targeting:** explicit in-sight target honored; explicit out-of-sight
  target refuses with the pinned sentence; explicit target on mend is
  accepted and ignored; no-target casts keep the nearest fallback.
- **Spitter content:** stat pin; crypt d1/d2 table pins (exact entries);
  reachability; glyph validation; no-depth-≥3 placement.
- **Save:** a v3 run document containing a reach-1 actor decodes with
  `reach == 1`; a spitter round-trips `reach == 3`; goldens byte-identical.
- **Casting bot:** the line prints; the build reads its book and casts when
  the rules allow (a small deterministic-seed test, not a band).

### Mutation table (both halves)

| Row | Mutation (sed on committed code) | Expected red (named set) | Expected green control |
|---|---|---|---|
| M1 | delete the ambush pre-charge condition in `step()` | the ambush reds (a) and (b); `step_monsters_test` adjacent-claw stays green | arrival-safety test green (arrival never ambushes, before or after) |
| M2 | ranged branch `<= reach` → `< reach` | spitter tests at exactly distance 3 red; distance-2 tests green | adjacent-attack tests green |
| M3 | drop `visible.contains` from the reach test | "cannot shoot without LoS" reds | open-LoS shot tests green |
| M4 | codec: encode reach unconditionally | golden save test reds (bytes move) | decode-default test green |
| M5 | swap mana/unknown order in `_castRefusal` | refusal-order test reds | happy-path cast green |
| M6 | spitter `reach: 3` → `1` | spitter shoot tests red | `hasLength` content pins green |

Report reds as NAMED SETS, never counts; a row that reddens nothing is a
hole, not a pass. Mutate the branch the test pins — not a shared constant
(the D69 lesson).

### Sequencing traps

- The reach codec change must land **before** the spitter (a creature with
  reach 3 cannot exist before the codec carries it), and the goldens control
  must run **before** the codec change (characterization) and **after**
  (still byte-identical).
- The ambush rule lands **before** the band trail starts; every trail row
  then measures ambush + whatever content delta the row carries.
- `_openingMonsters` (seed 4242) re-pins **in the same commit** as the
  spawn-table change, old value quoted in the body.

## Hazards

- Golden save tests byte-pin run documents; omit-on-default is the contract
  that keeps them green — an unconditional encode is a defect, pinned by M4.
- `dungeon_door_characterization_test.dart` pins the crypt's first floor and
  its opening monsters at seed 4242; the crypt floor LAYOUTS stay frozen —
  only the monster roster of depth 1–2 moves.
- The app's mirrored `castRefusal`/`_needsATarget` copy is not touched here;
  unit B owns it. Do not "fix the drift" early.
- Environment traps (verbatim in the build prompt): sandbox git (`cd` first),
  bfs `find` quirks, worktree cwd traps, no fvm (plain flutter/dart), `docs/epic/` gitignored and never committed, personal persona author,
  analyze from the WORKTREE ROOT with pwd quoted, `find.textContaining`
  case-sensitive, `scrollUntilVisible` one-way.
- **No AVD pass in this unit** — unit A is headless (core + content). The
  device ritual belongs to unit B.

## Follow-ups to log

- Hero ranged attacks (bows, long spells) with the LoS reach rule — content
  for a future bestiary/kit unit; the engine rule this unit builds is its
  prerequisite.
- Deeper/stronger spitters (depth ≥ 3) — needs designed-difficulty numbers
  and a bestiary ruling.
- Monster exclusive skills/spells, attacking and supporting (follow-up 32)
  — the stage/targeting model is its carrier; a shaman's ally-heal wants an
  ally-targeting mode in unit B's UI.
- Road fights with ranged creatures: state the construction-vs-play ambush
  exemption in the bestiary unit that puts one on a road.

## Definition of done

- All three suites green from the worker's own result files, counts
  re-derived (never inherited), analyze + format clean from the worktree
  root with pwd quoted.
- Every pin moved in this unit is re-pinned with its old value quoted in the
  same commit: band lines (all four + the new casting line), `hasLength` pins, reachability set, `_openingMonsters` seed 4242.
- The band trail exists as commit-by-commit rows (message or untracked
  plan), failed configurations kept as rows.
- Mutation table run, both halves reported as named sets, tree reverted
  clean after each row.
- The ambush/red tests red before their green commits; characterization
  tests quoted passing against unmodified `8168861` first.
- BUILD-REPORT.md written to the unit mailbox; done notice as a worker
  entry; no commit touches `docs/epic/`.