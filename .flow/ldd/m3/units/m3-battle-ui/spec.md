# Spec — `m3-battle-ui` (story M3U, unit B of the battle overhaul)

Unit A (`m3-battle`) is merged at `d576d1c`; this unit builds the battle
screen over the rules it shipped. App-only: no changes to `packages/core`
or `packages/content` unless a found defect forces one (pre-declare first).

Rulings folded in: D71 (battle as a view over the map), D72 (ranged reach =
LoS), D74 (split), D78/D79 (spitter final form, crypt floor), D83 (ranged
verb + ambush beat; riders 30/31 ride). Recon:
`docs/epic/m3-battle-ui-recon.md`.

## Goal

When a monster holds reach on the hero — adjacent, or the spitter within
three tiles along the hero's line of sight — the dungeon screen becomes a
battle screen: enemies on stage at the top, battle UI below, tap-to-target,
a turn strip naming who acts next and who is still walking in. When nothing
holds reach, the crawl view returns. Measurable effect: the fight the unit
A rules created becomes visible and playable per round — pick a skill, tap
a target — and the ambush reads on the screen and in the log.

## Shape — precedent to follow, read from the codebase

- **View-scoped facts stay off `GameState`**: the `hasFled` precedent
  (`game_bloc.dart`); the open/close rule is a pure getter over `game`.
- **Section-swapping in the `Stack`/`Column`**: the `_DeathOverlay`
  precedent (conditional layer) and the existing column order (map, HP,
  controls, log).
- **The skill bar is the parked dock fork, now living**: school marking
  (`✳/✚/⛒` from `SkillId.schoolMarking`) + spell name + mana cost,
  wrap-flow, hidden for non-casters; the Pack's `_SpellRow` grammar, but
  **extracted**, not copied a fourth time (D65-D's threshold — three
  private copies already ship).
- **Greyscale doctrine**: state by shape, marking, position, word — HP by
  bar length and number, school by marking and word, reach by the
  marking, never hue.
- **Refusals speak in the log**: a refused cast stays tappable and the
  refusal sentence lands in the log (`CastRefused`-via-refusal path);
  never a dimmed guess.

## New files

- `packages/app/lib/game/battle_view.dart` — the battle view (stage,
  turn strip, skill bar) as its own widget file.
- `packages/app/lib/game/spell_row.dart` (or similar shared piece) — the
  extracted spell-row grammar shared by Pack, Character, and the battle
  skill bar.
- Widget tests: `battle_view_test.dart` (and extensions to
  `game_bloc_test.dart` for the derived state).

## Changed files (exact paths)

- `packages/app/lib/game/game_bloc.dart` — derived getters
  (`monstersHoldingReach, `upNext, `arrivals`), the armed-skill view
  state, `CastPressed` gains the optional `targetId, the mirrored
  `castRefusal` updated to core's contract (target branch included), the
  ranged-verb/ambush-beat presentation.
- `packages/app/lib/game/game_screen.dart` — the battle view swaps in for
  the map section while the fight holds; the crawl view returns when
  nothing holds reach.
- `packages/app/lib/game/inventory_screen.dart` and
  `packages/app/lib/town/character_screen.dart` — the extraction's
  consumers (their private copies replaced by the shared piece).
- `packages/app/lib/game/event_messages.dart` — the ranged verb.
- `packages/app/test/*` — new battle-view tests; existing text pins updated
  ONLY where the rulings move them.
- `packages/app/lib/game/inventory_screen.dart` rider — follow-up 31: the
  Pack's skills-row spacing ("Blacksmith0") fixed.

No `packages/core` or `packages/content` changes are expected or wanted;
if one is forced, pre-declare before code.

## Per-item contract

### 1. Derived state (pure getters, no persisted fields)

- `monstersHoldingReach`: the engine's rule mirrored exactly — orthogonal
  adjacency OR (`reach > 1` AND position in `state.visible` AND
  `chebyshevTo(hero) <= reach`). Mirroring `_holdsReach` exactly is the
  contract; the hero-safe one-way-sight corner case is accepted and
  documented (unit A's probe: 40 asymmetric pairs, hero-safe direction).
- `upNext`: `scheduleMonsterTurns(heroSpeed, heroEnergy, speeds,
  energies).monsterTurns` mapped to monsters, bound ids filtered by
  `GameState.bound` (they sit out) — "who acts before the hero again".
- `arrivals`: non-reach, in-sight-or-pathed monsters with
  turns-to-arrival from `computeFlowField` distance ÷ speed, rounded up;
  unreachable monsters excluded (they stand still in the engine too).
- The battle view's open/close rule: **open when
  `monstersHoldingReach` is non-empty; closed when it is empty.** A pure
  getter. No hysteresis, no persisted flag.
- The armed-skill selection is view state on the `hasFled` shape: it
  survives `GameViewState` rebuilds ONLY where named; it resets on any new
  game state (the `pan` convention) and when the battle view closes.

### 2. The battle view

- Replaces the map section (the `Expanded(GlyphGrid)` slot) while
  `monstersHoldingReach` is non-empty; `_HitPoints, `_Controls, and
  `_MessageLog` stay. The death overlay keeps its place.
- **Stage**: one card per holding-reach monster — creature glyph, name
  ("the ghoul"), HP bar (length + numbers, greyscale-safe), and the
  school-style reach marking for reach > 1 (a word works: "at range").
  The hero is not a card; the vitals row is the hero.
- **Turn strip**: one line under the stage — "Next: {name}" from
  `upNext.first, then arrivals "{name} — n turns out". Greyscale-safe by
  position and word.
- **Skill bar**: one row of wrap-flow buttons from `knownSpells` (marking
  + name + cost), visible only for casters, above the control row. An
  armed spell is marked by position and a word ("armed"/border shape),
  never hue.
- **Pack stays** on the control row; casting happens from the bar, reading
  happens in the Pack. The log and all existing rows are unchanged.
- The crawl view (map + unchanged rows) returns exactly when
  `monstersHoldingReach` empties.

### 3. Gestures

- Tapping a skill button arms it; tapping a stage card with an armed spell
  dispatches `CastPressed(spellId, targetId: monster.id)`. An out-of-sight
  or invalid target is refused by the rules and the sentence lands in the
  log (button stays tappable).
- Tapping a stage card with NO armed skill is the regular attack:
  `MoveAction` toward it (the bump-attack), unchanged semantics.
- Mend/Ward ignore targets (they are cast on the hero); casting them from
  the bar does not require a card tap.
- The map's own tap semantics are untouched — the crawl view behaves
  exactly as today.
- The armed selection resets on: any new game state, battle view close,
  or a completed cast.

### 4. The drifted mirror

- The app's `castRefusal` gains the target branch: a named target that is
  not a visible enemy refuses "you cannot see that target" — the same
  sentence core uses, asserted by a test that pins both sides' agreement
  on a shared fixture.
- The Pack's cast path is unchanged (no target → nearest fallback).

### 5. Log flavor (D83)

- Reach > 1 monsters: the monster-attack sentence uses a ranged verb —
  "**{Name}** strikes you from afar for N." — instead of "claws". Adjacent
  monsters keep "claws".
- The ambush beat: when a step's events contain a monster attack on the
  hero and the step's start state held no reach-holders (the fight opened
  on the monster's terms), a beat sentence — "The {name} gets the drop on
  you." — precedes the hit sentence. Pinned by a deterministic fixture
  test; the worker is invited to attack the detection rule's edge cases
  (hero-closed openings vs monster-closed) and pre-declare any refinement.

### 6. Riders

- **Follow-up 31**: the Pack's skills row gains the missing separation so
  the longest skill name never touches its level digit ("Blacksmith0" →
  "Blacksmith 0"); a widget test pins it at the phone surface.
- **Follow-up 30**: the AVD pass shows the status line and the battle
  view on the phone-sized surface; greyscale variant of every acceptance
  shot (standing rule).

### 7. Follow-up 30's device ritual (mandatory AVD pass)

The full ritual, restated in the build prompt verbatim: both save slots
copied aside (md5) BEFORE any install, storage-trap resolution only after
the copies verify, `run-as stdin` restore, greyscale variants, shots into
`docs/reports/shots/m3-battle-ui/`.

## Test plan

### Characterization first (against unmodified `d576d1c, must pass)

- The current screen pins: status-line strings, control labels, refusal
  sentences (the files listed in the recon §widget tests), quoted green.
- The Pack's spell rows render with school marking + cost (the extraction
  source behavior).
- The crawl view with an adjacent monster behaves exactly as today (the
  battle view does not exist yet — a test asserting its absence is NOT
  written; instead the screen's current structure is pinned).

### New tests (red first, then green)

- Derived state: `monstersHoldingReach` (adjacent + spitter-in-LoS; a
  spitter out of LoS or beyond reach excluded), `upNext` (fast monster
  twice; bound monster excluded), `arrivals` (flow-field distance ÷
  speed, rounded up).
- Open/close: battle view opens on reach, closes when the monster dies or
  the hero disengages; the crawl view is untouched otherwise.
- Stage: card content (glyph, name, HP bar numbers, reach marking);
  multiple monsters; greyscale (the shot variant, plus bar-length
  assertions).
- Skill bar: order (school-then-name), armed selection + reset rules,
  wrap-flow with many spells (the arena fixture + added books), silent for
  non-casters.
- Targeting: armed cast dispatches `CastSpellAction(spellId, targetId)`;
  out-of-sight refusal sentence lands in the log; regular attack without
  an armed skill; Mend/Ward need no target.
- Mirror agreement: the app's `castRefusal` and core's refusal agree on
  the same fixture states (both sides quoted).
- Log flavor: ranged verb for reach monsters; ambush beat fires on the
  opening swing and not on ordinary swings (the edge cases attacked).
- Rider 31: the skills row reads "Blacksmith 0" at the phone width.
- Mutation-table pins: each row below names its reds.

### Mutation table (both halves)

| Row | Mutation | Expected red (named set) | Expected green control |
|---|---|---|---|
| M1 | open/close getter: `isEmpty` → `isNotEmpty` inverted | battle-view open/close tests red; crawl-view tests green | death-overlay tests green |
| M2 | `monstersHoldingReach`: drop the `reach > 1` branch | spitter-in-LoS stage tests red; adjacent-only tests green | crawl-view tests green |
| M3 | armed-skill reset removed | the reset-on-new-state test reds | happy cast tests green |
| M4 | `targetId` dropped at the dispatch site | armed-cast tests red (action loses its target) | nearest-fallback cast tests green |
| M5 | ranged verb branch removed | ranged-verb log tests red | adjacent "claws" tests green |
| M6 | ambush beat condition always true | the beat-not-on-ordinary-swings test reds | the opening-swing beat test green |

Reds as named sets, never counts; a row that reddens nothing is a hole.
Mutate the branch the test pins, not a shared constant (D69 lesson).

### Sequencing traps

- The spell-row extraction lands FIRST as a verbatim-lift refactor commit
  (every loop lifted, all suites green, quoted), THEN the battle view
  consumes it — the honest form of "characterization against unmodified
  code" when the shared piece is new (D65-B precedent).
- The `castRefusal` mirror update lands before the targeting gesture (the
  gesture's refusals must render through the corrected copy).
- Existing text pins move only in the same commit as the change that moves
  them, old values quoted.

## Hazards

- Every pinned string listed in the recon; the status line is one string
  by design — do not split it without a ruling (the parked two-fixed-lines
  fork is NOT in this unit).
- `GameViewState` constructor-drop: a field not named in a handler's
  rebuild silently resets (the `pan` dartdoc); the armed-skill state must
  be named deliberately everywhere it should survive.
- Widget traps: `find.textContaining` case-sensitive;
  `scrollUntilVisible` one-way (monotonic assertions); at least one
  phone-sized test (`_onAPhone` precedent).
- The AVD ritual is mandatory (UI unit): save-aside before install,
  storage trap, `run-as stdin` restore, greyscale variants.
- Bands as controls: all five band lines must hold byte-identical; the
  bot never reads widgets, so any movement means something leaked.
- Environment traps restated verbatim in the build prompt.

## Follow-ups to log

- Per-creature attack verbs (content lever, bestiary ruling) — the generic
  ranged verb is the interim form.
- A turn-strip "up next" readout is informational; if it earns a strategic
  role (visible initiative planning), that is a later ruling.
- The crawl HUD's parked two-fixed-lines fork stays parked until the
  battle screen's own vitals presentation settles in play.

## Definition of done

- All three suites green from the worker's own result files, counts
  re-derived; analyze + format clean from the worktree root with pwd
  quoted; app suite delta explained by new tests.
- All five band lines byte-identical to `d576d1c`'s, quoted.
- The battle view: opens on reach, closes on disengage or clear, on the
  emulator (AVD) and in widget tests, including a phone-sized surface.
- Greyscale variant of every acceptance shot.
- Mutation table run, both halves, named sets, tree clean after each.
- Characterization quoted green against unmodified `d576d1c` first.
- Follow-ups 30 and 31 closed (30 verified on device, 31 pinned by test).
- BUILD-REPORT.md in the mailbox, done notice as a worker entry; nothing
  under `docs/` committed.