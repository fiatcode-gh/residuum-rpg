# Spec — m3-battle-flow (story M3BF, unit 2 of the D98 wave)

2026-09-03. Base: `main` = `594bc80` (1941 green). Branch `m3-battle-flow`,
worktree `.worktrees/m3-battle-flow` (architect creates it before dispatch).
Locked scope: D97 verdicts V1 + V2 + V8 + V9, wave order D98. The
spec-time details D97 explicitly delegated to this spec are RULED below
(chip wording, bare-tap behavior, glyph shapes, count persistence, wait
surfaces, naming). Contracts are binding; shape deviations are pre-declared
in the unit mailbox before code.

## Goal

Rebuild the battle interaction so a fight reads and plays in two taps:
the dock legible over any map tile (V1), every action armed-first with its
legal targets marked in dock and map (V2), the hero able to hold ground in
any fight (V8), and watched vs engaged distinguishable at a glance (V9).
One no-op core verb; everything else app-side. Nothing bot-visible moves.

## Precedent

- The bump-attack is a blocked move in core (`_moveHero` → swing); it has
  no action of its own. This unit RETIRES THE GESTURE, not the mechanism —
  core stays untouched except for the wait verb.
- Armed marking precedent: `BorderSide(color: ink)` + `' — armed'` word on
  bar buttons (battle_view.dart:217–226). Target marks follow it.
- Fog of war marks by per-cell opacity (glyph_plan.dart), never hue; the
  house rule "Nothing is told apart by hue" binds every new mark.
- Wait semantics already true of the engine: a reach-holder shoots a hero
  standing at distance (`_holdsReach` step.dart:743; spitter stands its
  ground, step.dart:670–672). The verb only exposes it.
- D92's walk sentence lives today on the far-card branch
  (`_outOfReach`, game_bloc.dart:914). It MOVES to the armed path verbatim.

## Contracts

### C1 — Turn-order chips + whole-header backing (V1)

- `_TurnStrip` (dim 12px `'Next: X'` / `'X — N turns out'`) retires.
- The dock header is wrapped in ONE translucent dark backing panel that
  covers the stage cards row AND the chip row — every dock string reads
  over any map tile. Cards keep their opaque panel background; the backing
  shows through the gaps, behind the cards, and behind the chips.
- Chip row replaces the strip: first chip `NOW — ${name}` (the monster
  whose turn is next, `upNext.first`); one chip per arrival,
  `IN ${n} — ${name}`. Position (NOW is first) and word (NOW vs IN) carry
  the state — never dim-on-map, never hue. Chips render in `ink`, monospace,
  on the backing. Empty `upNext` → no NOW chip (same conditional as today).

### C2 — Attack as a bar action; armed-target flow (V2a/V2b)

- The skill bar renders for EVERY hero when the dock is open (the
  `knownSpells.isNotEmpty` condition drops), and contains, in order:
  **Attack**, the known spells, **Wait** (C5).
- One armed slot at a time (today's `armedSpellId`, widened by the worker's
  chosen shape — enum or sentinel — pre-declared). Arming Attack works like
  arming a spell: border + `' — armed'` on the bar button.
- Legal targets while armed:
  - Attack: monsters orthogonally adjacent to the hero (the bump rule).
  - Target-needing spells: visible enemies (unchanged sight rule).
  - Mend/ward: cast straight from the bar, never arm (unchanged).
- While an action is armed, every legal target is MARKED: stage card gets
  the ink border; the map paints an outline around the monster's glyph cell
  (extend the glyph plan/painter — CustomPaint, no per-cell widgets).
  Outline/marking/word, never hue. Nothing is marked when nothing is armed.
- Tapping a MARKED stage card applies the armed action:
  - Attack armed + adjacent monster → the existing bump dispatch
    (`MoveAction` toward it; core unchanged, `'You hit the ghoul for 4.'`
    grammar intact).
  - Spell armed + visible monster → `CastPressed(spellId, targetId: …)`
    (unchanged).
- Tapping an UNMARKED stage card while armed → the walk sentence
  `'$name is out of reach. Walk to it.'` (log-only, no step) — verbatim.
- Bump-attack on a bare card tap RETIRES (see C4).

### C3 — Map tap-to-attack retires (V2c)

- In `_onTileTapped`, a tap onto a tile that holds a monster NEVER dispatches
  the move/bump — armed or not — and falls through to the watched-refusal
  branch (`'Something is watching. You stay put.'`). One sentence, one
  branch; do not fork the refusal grammar.
- The map stays a movement surface: taps on empty walkable tiles are
  unchanged (walk starts; armed state preserved; tap during watched still
  refuses via the same branch).
- All fights go through the dock.

### C4 — Bare stage-card tap = enemy info (V2 ruling)

- Nothing armed + card tap → an enemy info surface (bottom sheet or dialog —
  implementer's choice, pre-declared): name + glyph, wounds `hp / maxHp`,
  attack `min–max`, reach in words (`strikes adjacent` / `strikes at range
  N`), speed, `Resists <word>` per resistance, `Burns at <word>` per
  vulnerability. Words carry everything — greyscale-safe by construction.
  Data comes from the `Actor` the card already holds; no bestiary lore, no
  new core reads, no save change.
- Dismissal costs no turn and mutates nothing.

### C5 — The wait verb (V8)

- Core: `WaitAction` in `action.dart` (house Action grammar — the ledger's
  "WaitPressed" names the APP event). New event `HeroWaited` in `event.dart`
  (past-tense house style). In `step`: a case that appends `HeroWaited()`
  and changes nothing else, falling through to the monster phase. Always
  legal — no refusal path; the turn is spent exactly as a wall-bump is.
- App: `WaitPressed` bloc event → `_act(const WaitAction())`; stops
  auto-walk first (house behavior of every control tap) and disarms like
  any step.
- Log line: `describeEvent(HeroWaited())` → `'You hold your ground.'`
  (the D97 candidate — locked).
- No regen, no discount, no exception: a waiting hero at reach is shot
  (existing engine truth — pin it, do not change it).
- Surfaces, per the V8 ruling "road encounter row and the crawl alike":
  (a) the bar's Wait button when the dock is open; (b) the road encounter's
  `_Controls` row gains Wait (visible while the encounter is live —
  `!isRoadClear`). The core verb itself is general; this unit exposes those
  two surfaces only.

### C6 — Two-state battle glyph (V9)

- A fixed-size glyph cell in `_HitPoints`, between the HP bar and the
  FittedBox. States: nothing in sight → empty cell; watched (`enemiesInSight
  > 0`, nothing holds reach) → eye mark + word; engaged (dock open) →
  crossed marks + word.
- Words move into the fitted string, replacing the `'  Engaged N'` suffix:
  `Watched ${n}` when watched, `Engaged ${n}` when engaged (count persists
  for both states — the ruled reading of V9's "distinguishable at a
  glance"). Glyph shapes: watched `'◉'`, engaged `'✖'` — monospace coverage
  unproven; if either codepoint renders wrong on the AVD, swap to a
  CustomPaint-drawn eye/cross (pre-declare the swap). Shape pair differs by
  form; word is the greyscale backstop.
- The scale-down behavior of the string is unchanged.

### C7 — Nothing else moves

- Save v3 untouched (no new persisted field; armed state stays view-scoped).
- The five band lines byte-identical; crypt floor tripwire untouched; golden
  saves byte-identical. Expected, not assumed — the trail proves it.
- `WaitAction` changes no existing core path; every engine test green
  unchanged is the control.

## Test plan (controls and mutation)

- Strict TDD; characterization first. Write and run GREEN against
  unmodified `594bc80` the tests that pin what this unit FLIPS: far card
  tap sentence, bump-on-bare-card-tap, `'Next: …'`/`'… turns out'` strip
  texts, `'Engaged N'` suffix, non-caster no bar, map-tap-to-attack
  (adjacent monster tile dispatches a move), `'Something is watching. You
  stay put.'` branch reuse. These flip WITH the change, old values quoted
  in the same commit.
- New core tests: wait spends the turn and runs the monster phase (spitter
  shoots a waiting hero at range — the verb's guarantee); wait emits
  `HeroWaited` and nothing else; wait with bound monsters (they sit out);
  wait in an encounter state; wait is never refused; determinism — same
  seed, same wait sequence, identical states.
- New app tests: chip row words/order; backing panel present behind cards
  and chips; armed Attack + marked card tap → attack; armed spell + marked
  far card tap → named cast; armed + unmarked far card → walk sentence;
  bare card tap → info surface with resist words; map monster tap → refusal
  (armed and bare); Wait in bar and road row dispatch `WaitPressed`;
  glyph states watched/engaged/empty with word backstop; non-caster bar =
  Attack + Wait; overflow test re-pinned at 1080×2424 @ 2.625.
- Mutation rows (named sets both phases, definitions matched exactly; the
  worker extends by measurement): M1 wait's monster-phase fall-through
  removed → the ranged-shoots-waiting-hero test + clock tests red; M2 the
  monster-tile map gate reverted → the map-tap-attack-retired test red;
  M3 the stage-card target mark removed → the marking test red; M4 chip
  order/words reverted → the chip test red. Pre-flip rows pin the OLD
  behavior against `594bc80` where meaningful.
- Controls: five band lines byte-identical; `golden_save_test` untouched;
  `dungeon_door_characterization_test.dart` untouched.

## Hazards

- The D56 lesson: expected byte-identical bands; ANY movement is
  stop-and-report, never a re-pin.
- `describeEvent` is an exhaustive switch — the new event will force a case;
  keep it exhaustive and the sentence in the house voice.
- The armed-state widening touches several armed-skill lifecycle tests
  (:2039 group) — flip them in the commit that moves the state, old values
  quoted.
- `_onStageCardTapped` and `_onTileTapped` are the only two known
  bump-shaped dispatch sites; grep again before declaring the map retired.
- Widget traps restated: `find.textContaining` is case-sensitive;
  `scrollUntilVisible` is one-way (monotonic document order); size at least
  one widget test like a phone.
- The AVD pass is MANDATORY: save-aside ritual before ANY install, emulator
  serial pinned, chips/backing/outlines/glyph read in pixels, greyscale
  shots for the author's eye.

## Definition of done

- All suites green (core/content/app, per package directory) with the new
  tests; counts reported from result files.
- Five band lines byte-identical, quoted from the worker's own run.
- Mutation table complete, named sets, reverts proven clean.
- `dart analyze .` and `dart format --set-exit-if-changed .` clean from the
  worktree root, pwd quoted.
- AVD pass evidence + shots; no device save harmed (copy-aside ritual).
- REPORT.md in the channel; deviations pre-declared before code; nothing
  under `docs/` committed; conventional commits; nothing pushed.