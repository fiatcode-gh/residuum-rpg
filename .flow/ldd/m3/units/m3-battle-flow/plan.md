# m3-battle-flow Implementation Plan

> Execute with flow-executing-plans, task by task.

**Goal:** Rebuild the battle interaction — turn-order chips over a whole-header
backing (V1), armed-first actions with marked legal targets in dock and map
(V2), a core wait verb (V8), and a two-state battle glyph (V9) — so every
action in a fight is two taps.
**Spec:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-battle-flow-spec-M3BF.md`

## Global constraints

- Baseline `main` @ `6a1500a`: core 828, content 550, app 563 — 1941 green,
  measured fresh this session, per package directory.
- Suites run per package directory: `cd packages/<pkg> && flutter test`. No
  root pubspec.
- Every commit's exit state is green. Existing text pins move only in the
  commit that moves them, old values quoted in that commit's message.
- Nothing under `docs/` is committed. Conventional commits. Nothing pushed.
- Save v3 untouched; the five band lines byte-identical; golden saves
  byte-identical; `dungeon_door_characterization_test.dart` untouched.
- No hue-only state: marks are shape, word, position, border — greyscale-safe.
- Pre-declared deviations D1–D4 sit in worker.md entry 1, awaiting ack before
  the affected pieces (Tasks 5–9) are built. Tasks 2–4, 10–11 are unaffected
  and proceed.
- Worker-only: no push, no PR, no device installs without the save-aside
  ritual, emulator serial pinned.

## Measured facts this plan builds on (all verified at source)

- Bump dispatch sites: `_onTileTapped` directionTo branch
  (game_bloc.dart:538–541) and the adjacent bare-tap branch of
  `_onStageCardTapped` (:571–589). Auto-walk is guarded (`monsterAt(next)`
  → stop, :738–741); FleePressed goes off-grid (:674); the content bot
  constructs actions with no switch over `GameAction`.
- `Position.directionTo` is orthogonal-only (position.dart:53–54) — map and
  card surfaces agree on adjacency; no diagonal discrepancy.
- `step` spends `actCost` at :68 before the switch; `_monsterPhase` schedules
  on the post-spend energy (:600). `upNext` replays `hero.energy − actCost`.
  Wait inherits both by being an ordinary non-refused action.
- Exhaustive switches over `GameAction`: core `step.dart:81` (main) and
  `step.dart:435` (`_refuse`) — the new subtype forces both cases (loud).
- `armedSpellId` consumers: battle_view.dart:218,223; game_bloc.dart:155,196,
  551,565,576–578,587,647,663,703,778; battle_view_test.dart:195,394,450;
  game_bloc_test.dart armed group :2039 (12 pins).

## Task 1: Characterization — pin what this unit flips (pre-flip)

**Files:** `packages/app/test/battle_flow_characterization_test.dart` (new).

Write the pins that capture today's behavior, run GREEN against unmodified
`6a1500a`. Existing pins already cover the far-tap sentence
(battle_view_test.dart:190–192), bump-on-bare-tap (:433–451), strip texts
(:315–316), `'Engaged 1'` (battle_characterization_test.dart:215),
non-caster no bar (:369–378), watched refusal (game_bloc_test.dart:510–524).
Add the missing one:

- [ ] Write: a map tap on a tile orthogonally adjacent holding a monster
      dispatches the bump (hero swings, monster claws back) — the behavior C3
      retires. Reuse the `_arena`/`ghoulAt`/`_pushGame` shape from
      battle_view_test.dart (copy the three helpers in; the file stands
      alone).
- [ ] Run `cd packages/app && flutter test test/battle_flow_characterization_test.dart`
      — confirm GREEN on unmodified `6a1500a`. Also run the five pinned
      suites listed above — all green.
- [ ] If any of these are red on `6a1500a`: STOP and report via the mailbox.
      Do not work around.
- [ ] Commit: `test: pin the battle gestures m3-battle-flow retires` (quote
      the pinned behaviors in the body).

## Task 2: Core wait verb — `WaitAction` + `HeroWaited`

**Files:** `packages/core/lib/src/engine/action.dart`,
`packages/core/lib/src/engine/event.dart`,
`packages/core/lib/src/engine/step.dart`, `packages/core/test/engine/step_wait_test.dart` (new),
`packages/app/lib/game/event_messages.dart` (the sentence lives app-side).

- [ ] Write failing tests in `step_wait_test.dart` (pure, arrange/act/assert):
  1. wait emits exactly `HeroWaited()` and nothing else, no state change
     beyond the monster phase's own effects on a monsterless arena;
  2. wait runs the monster phase: a spitter (`reach: 3`) at Chebyshev
     distance 3 shoots a waiting hero — hero hp drops (the verb's guarantee,
     pinning M1);
  3. wait with a bound monster: the bound monster sits out (its `bound`
     count decrements by one turn), no swing;
  4. wait in an encounter state (`isEncounter: true` arena) — legal, world
     ticks;
  5. wait is never refused: `step` with `WaitAction` never returns
     `ActionRefused` / `InventoryFull` (assert event list shape on a bare
     arena and on a full-inventory arena);
  6. determinism: same seed, same wait sequence, identical states
     (deep compare via the save codec's equality or field-by-field asserts
     used by the clock tests).
- [ ] Run: `cd packages/core && flutter test test/engine/step_wait_test.dart`
      — RED (compile error on missing types is the red).
- [ ] Implement: `final class WaitAction extends GameAction { const
      WaitAction(); }` in action.dart (dartdoc: always legal, spends the turn
      exactly as a wall-bump does). Event: `final class HeroWaited extends
      GameEvent with Equatable { const HeroWaited(); }` (toString
      `'HeroWaited()'`). In `_refuse`: `case WaitAction(): return null;`. In
      the main switch: `case WaitAction(): events.add(const HeroWaited());`
      — the monster phase then runs unchanged (fall-through to
      `_monsterPhase` at :170). Nothing else.
- [ ] Run the core suite: all green, count ≥ 828 + 6.
- [ ] Commit: `feat: core wait verb — WaitAction spends the turn and ticks the world`.

## Task 3: The sentence, the app event, and the two wait surfaces

**Files:** `packages/app/lib/game/event_messages.dart`,
`packages/app/lib/game/game_bloc.dart`, `packages/app/lib/game/battle_view.dart`,
`packages/app/lib/game/game_screen.dart`,
`packages/app/test/game_bloc_test.dart` (new tests appended),
`packages/app/test/battle_view_test.dart` (new tests appended).

- [ ] Bloc test (red): `WaitPressed` → `_act(const WaitAction())` semantics —
      log gains `'You hold your ground.'`, a spitter at range shoots the
      waiting hero, armed state disarms (new state drops the arm by
      construction), auto-walk stops first (walk in progress + WaitPressed →
      `isWalking` false AND the turn spent).
- [ ] Widget tests (red): bar Wait button dispatches `WaitPressed` (dock
      open); road encounter `_Controls` row gains `Wait` visible while
      `!isRoadClear` and dispatches `WaitPressed`; Wait absent from the crawl
      row when no encounter is live.
- [ ] Implement: `describeEvent` gains `HeroWaited() => 'You hold your
      ground.'` (exhaustive switch — the compiler forces the case). New
      `final class WaitPressed extends GameBlocEvent { const WaitPressed(); }`
      with handler `_onWaitPressed`: stops auto-walk first (house behavior —
      build the fresh state with `autoPath: const []`? No: `_act` spends the
      turn and its fresh state already drops `autoPath`), so the handler is
      `if (!state.game.isGameOver) _act(const WaitAction(), emit);`. Bar: add
      an `Attack` button and a `Wait` button to `BattleSkillBar` (Wait is
      Task 6's slot; here add only the Wait button after the spells —
      attack joins with the armed-flow task) — wait: C2's bar order is
      Attack, spells, Wait; to keep each commit green, this task adds the
      Wait button LAST and the attack-first reorder lands in Task 6 in the
      same commit as the armed flow. `_Controls`: an `Expanded(_Control(label:
      'Wait', ...))` conditioned on `state.isEncounter && !state.isRoadClear`.
- [ ] Run app suite: green. Commit: `feat: the wait surfaces — bar button, road-row control, the hold-ground sentence`.

## Task 4: Turn-order chips + whole-header backing (C1)

**Files:** `packages/app/lib/game/battle_view.dart`,
`packages/app/test/battle_view_test.dart` (strip pins move in this commit).

- [ ] Flip the strip pins first in the same commit: `'Next: the ghoul'` /
      `'the ghoul — 4 turns out'` (:315–316) → `'NOW — the ghoul'` and
      `'IN 4 — the ghoul'`. Old values quoted in the commit message.
- [ ] Implement: `_TurnStrip` retires; new `_TurnChips` renders `NOW —
      ${state.upNext.first.name}` (same empty-`upNext` conditional as today),
      then `IN ${turns} — ${monster.name}` per arrival; chips in `ink`,
      monospace, on the backing. The dock header wraps stage cards AND chips
      in ONE translucent dark backing (`Color(0x99000000)`-style scrim —
      pick from the existing dark constants; the cards keep their opaque
      `panel` background and the backing shows through the gaps).
- [ ] Tests: chip order (NOW first, then arrivals in count order), words
      (`NOW` vs `IN n`), backing present behind cards and chips (a widget
      assertion on the decoration), chips read over the map (no exception,
      phone-sized surface). Mutation row M4 targets this test.
- [ ] Run app suite green. Commit: `feat: turn-order chips on a whole-header backing — the dock reads over any tile`.

## Task 5 (D1 ack): Armed-state widening — `ArmedAction`

**Files:** `packages/app/lib/game/game_bloc.dart`,
`packages/app/test/game_bloc_test.dart` (armed group :2039 flips here),
`packages/app/test/battle_view_test.dart` (:195,394,450 flip here).

- [ ] Replace `String? armedSpellId` with `ArmedAction? armedAction`:

      ```dart
      sealed class ArmedAction { const ArmedAction(); }
      final class ArmedAttack extends ArmedAction { const ArmedAttack(); }
      final class ArmedSpell extends ArmedAction {
        const ArmedSpell(this.spellId);
        final String spellId;
      }
      ```

      Carry-throughs become `armedAction: state.armedAction` (mechanical);
      `SkillArmed` keeps its `String? spellId` and sets
      `ArmedSpell(spellId)` / null. Old pin values (`'firebolt'`) quoted in
      the commit message; new pins `const ArmedSpell('firebolt')`.
- [ ] Run app suite green. Commit: `refactor: the armed slot widens to ArmedAction — attack joins the bar`.

## Task 6 (D1 ack): Attack as a bar action; armed-target flow (C2)

**Files:** `packages/app/lib/game/game_bloc.dart`,
`packages/app/lib/game/battle_view.dart`,
`packages/app/test/battle_view_test.dart`,
`packages/app/test/battle_characterization_test.dart`,
`packages/app/test/game_bloc_test.dart`.

- [ ] Bloc tests (red): arming Attack (`SkillArmed` widened — attack is a bar
      button, so arming is `AttackArmed` bloc event or `SkillArmed` carrying
      attack; shape: keep `SkillArmed` for spells and add
      `final class AttackArmed extends GameBlocEvent { const AttackArmed(); }`);
      armed Attack + marked adjacent card tap → the bump dispatch
      (`MoveAction` toward it — same sentence `'You hit the ghoul for 4.'`);
      armed + UNMARKED far card → the walk sentence verbatim
      `'$name is out of reach. Walk to it.'` (log-only, no step); one armed
      slot (arming attack disarms the spell and vice versa).
- [ ] Widget tests (red): bar renders for every hero when the dock is open
      (`knownSpells.isNotEmpty` condition drops — the non-caster-no-bar pin
      at battle_view_test.dart:369–378 flips here, old value quoted); bar
      order Attack, spells, Wait; Attack button border + `' — armed'` while
      armed.
- [ ] Implement `_onStageCardTapped`:

      ```dart
      final armed = state.armedAction;
      if (armed == null) { /* info surface — Task 7 */ }
      else if (armed is ArmedAttack &&
          hero.position.isOrthogonallyAdjacentTo(monster.position)) {
        add(TileTapped(monster.position));
      } else if (armed is ArmedSpell &&
          game.visible.contains(monster.position)) {
        add(CastPressed(armed.spellId, targetId: monster.id));
      } else {
        emit(out-of-reach sentence, armedAction carried);
      }
      ```

      Spell legality stays sight-only (unchanged rule); Attack legality is
      orthogonal adjacency. Bar renders `Attack` button first, then spells,
      then Wait; `BattleSkillBar` reads `armedAction`.
- [ ] Run app suite green; the far-tap and bump pins moved in this commit
      quote old values. Commit: `feat: attack is a bar action — armed targets marked by tap, far taps say walk`.

## Task 7 (D2 ack): Bare stage-card tap = enemy info (C4)

**Files:** `packages/app/lib/game/battle_view.dart` (or a new
`enemy_info.dart` if battle_view grows past comfort),
`packages/app/test/battle_view_test.dart`.

- [ ] Widget tests (red): nothing armed + card tap → modal bottom sheet with
      name + glyph, `hp / maxHp`, `min–max` attack, reach in words
      (`strikes adjacent` / `strikes at range N`), speed, `Resists fire` /
      `Burns at frost` lines from the Actor's sets; dismissal costs no turn
      (log unchanged, hero position unchanged, no events dispatched).
- [ ] Implement the sheet (D2): `showModalBottomSheet`, monospace ink on
      panel, data straight off the card's `Actor`. No core reads, no save
      change.
- [ ] Run app suite green. Commit: `feat: a bare card tap opens the enemy's numbers`.

## Task 8 (D1 ack): Map tap-to-attack retires (C3)

**Files:** `packages/app/lib/game/game_bloc.dart`,
`packages/app/test/battle_flow_characterization_test.dart` (the Task 1 pin
flips here; old behavior quoted in the commit message).

- [ ] Bloc tests (red): `_onTileTapped` on a monster-holding adjacent tile —
      armed or not — falls to the watched-refusal branch when enemies are in
      sight (`'Something is watching. You stay put.'`, one branch, no fork);
      empty walkable tiles still walk, armed state preserved.
- [ ] Implement: in `_onTileTapped`, gate the `directionTo` dispatch on
      `game.monsterAt(event.position) == null`; a monster tile falls through
      to the watched-refusal branch (or the walk-start branch below it when
      nothing is in sight — a monster tile is never walkable, so the
      existing `isWalkable` guard already refuses it silently when unwatched;
      the change is only that the directionTo branch no longer fires).
- [ ] Run app suite green. Commit: `feat: the map stops swinging — monster tiles refuse like watched ground`.

## Task 9 (D3 ack): Armed-target marking on stage cards and map (C2)

**Files:** `packages/app/lib/game/game_bloc.dart` (a
`Set<String> armedTargets` getter or equivalent),
`packages/app/lib/game/battle_view.dart`, `packages/app/lib/game/glyph_plan.dart`,
`packages/app/lib/game/glyph_grid.dart`,
`packages/app/test/battle_view_test.dart`, `packages/app/test/palette_test.dart` (if ink constants land there).

- [ ] Bloc/getter tests (red): with Attack armed, legal targets = monsters
      orthogonally adjacent; with a target spell armed, legal targets =
      visible enemies; nothing armed → empty set.
- [ ] Widget tests (red): armed + legal target card shows the ink border;
      map paints an outline around the target's glyph cell (extend
      `GlyphCell` with `marked` — D3 — painter strokes a rect outline; no
      per-cell widgets); nothing marked when nothing is armed.
- [ ] Implement: getter over state (`armedTargets`), stage card border
      `BorderSide(color: ink)` precedent, painter outline pass after the
      monster pass.
- [ ] Run app suite green. Commit: `feat: armed actions mark their legal targets on cards and map`.

## Task 10: Two-state battle glyph (C6)

**Files:** `packages/app/lib/game/game_screen.dart`,
`packages/app/test/battle_characterization_test.dart` (`'Engaged 1'` :215
flips here), `packages/app/test/battle_view_test.dart` (:240
`find.textContaining('Engaged')` re-pin), `packages/app/test/widget/hud_depth_test.dart` (if it composes the line).

- [ ] Flip `'  Engaged ${enemiesInSight}'` suffix pins: watched →
      `Watched ${n}` word + `'◉'` glyph cell; engaged → `Engaged ${n}` word +
      `'✖'` glyph cell; nothing in sight → empty cell, no suffix. Count
      persists for both states (the ruled reading of V9). Old values quoted
      in the commit message.
- [ ] Implement: fixed-size glyph cell in `_HitPoints` between the bar and
      the FittedBox; the word moves into the fitted string. Scale-down
      behavior unchanged.
- [ ] Run app suite green. Commit: `feat: watched and engaged read apart — glyph and word, not hue`.

## Task 11: Whole-suite verification and controls

- [ ] `cd packages/core && flutter test` → all green, count recorded.
- [ ] Same for content and app; counts recorded from result files.
- [ ] Five band lines verbatim from this session's content-suite run,
      byte-compared to: crypt 16/40 (40.0%) `{1:1,2:9,3:8,4:6,5:16}`,
      casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40 (65.0%),
      ruined keep 24/40 (60.0%). Any movement: STOP and report.
- [ ] `dart analyze .` and `dart format --output=none --set-exit-if-changed .`
      from the worktree root, clean.
- [ ] `git status` clean of docs/; parent repo untouched.

## Task 12: Mutation table

- [ ] M1: remove wait's monster-phase fall-through (make the WaitAction case
      return early) → named reds: the ranged-shoots-a-waiting-hero core test
      + the clock tests. Revert.
- [ ] M2: revert the monster-tile map gate → the map-tap-attack-retired test
      red. Revert.
- [ ] M3: remove the stage-card target mark → the marking test red. Revert.
- [ ] M4: revert chip order/words → the chip test red. Revert.
- [ ] Pre-flip rows (Task 1 pins against `6a1500a`) named in the report.
- [ ] Prove the tree clean after the last revert.

## Task 13: AVD pass

- [ ] Save-aside ritual before any install (both slots, checksums); pin
      `-s emulator-5554`; prefer the emulator; never a phone.
- [ ] Shots: chips, backing, target outlines, glyph in both states; greyscale
      variants. Read in pixels. If '◉'/'✖' render wrong, pre-declare the
      CustomPaint swap in the mailbox before swapping.
- [ ] Record emulator free space before install; uninstall-old only after
      verified copy-aside.

## Task 14: Report

- [ ] Write `REPORT.md` in the channel directory (verification block, all ten
      items), append the done notice to `worker.md`, stop the watch by
      letting it expire.