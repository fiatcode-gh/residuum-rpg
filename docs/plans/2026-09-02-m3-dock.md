# M3V dock fix — implementation plan

> Execute with flow-tdd, task by task, in the m3-dock worktree.

**Goal:** the map never leaves the screen while a fight holds reach —
battle pieces dock over it, and a far stage-card tap speaks in the log.
**Spec:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-dock-spec-M3V.md`

## Global constraints

- App-only: `git diff main -- packages/core packages/content` must stay empty.
- `isBattleOpen` (game_bloc.dart:318) is unchanged; it gates dock rows, not the map slot.
- Baseline (fresh, fda107f): core 793, content 541, app 560, all green; `dart analyze .` from worktree root clean.
- C1/C2 measured: C1 swap confirmed; C2 far tap is NOT silent — it emits "Something is watching. You stay put." (watched-refusal). Pre-declared to the architect, mailbox worker entry 2.
- Pre-declared: `game_bloc.dart` gains one event `StageCardTapped(Actor)` — the log is bloc state; no derived fact needed (adjacency decided from `state.game.hero.position`).
- Pre-declared: no new file; `battle_view.dart` keeps the dock widgets, `BattleView` is replaced.
- Commits: Conventional Commits, explicit paths only, nothing under `docs/`.
- Widget traps: `find.textContaining` case-sensitive; size phone tests 1080×2424 @ 2.625.

### Task 1: the dock — map never leaves, rows dock over it (T1, T2, T5)

**Files:** `packages/app/lib/game/game_screen.dart, `packages/app/lib/game/battle_view.dart, `packages/app/test/battle_view_test.dart, delete `packages/app/test/dock_characterization_test.dart`.

- [ ] RED: T1 — spitter at (4,1) (distance 3, in LOS): one pump shows `GlyphGrid` AND `the spitter` card. Fails on current code (swap).
- [ ] RED: T2 — dock up, tap floor tile (2,1) via `GridGeometry.camera` + `tester.tapAt`: hero moves to (2,1), dock stays up.
- [ ] RED: T5 — rewrite swap-return: three swings drop the adjacent ghoul; then `find.byType(BattleDock)` finds nothing, `GlyphGrid` one.
- [ ] GREEN: `game_screen.dart` Column becomes `[if (isBattleOpen) BattleDock, Expanded(Padding(GlyphGrid — always)), if (isBattleOpen && knownSpells.isNotEmpty) BattleSkillBar, _HitPoints, _Controls, _MessageLog]`.
- [ ] GREEN: `battle_view.dart`: `BattleView` → `BattleDock` (stage cards + turn strip, `mainAxisSize: min`) + `BattleSkillBar`; card `onTap` → `bloc.add(StageCardTapped(monster))` (event lands in Task 2; until then keep the D89 dispatch inline so this task stays green — no, see sequencing note).
- [ ] Sequencing: Task 1 keeps the card tap dispatching `TileTapped`/`CastPressed` exactly as D89 shipped (adjacent case is unchanged behaviour anyway; the far tap's new sentence arrives in Task 2). This keeps every commit green.
- [ ] Rewrite the first swap test into T1's group; delete `dock_characterization_test.dart` (its inverse now lives as T1/T2).
- [ ] Run app suite green; commit `feat: the dock — the map never leaves the screen during a fight`.

### Task 2: skill bar docks below the map; the phone fits (T6, T7)

**Files:** `packages/app/lib/game/battle_view.dart, `packages/app/test/battle_view_test.dart`.

- [ ] GREEN-carry: T6 — caster sees marking+name+cost below the map (`✳ Firebolt 2`); non-caster sees no bar. Re-point D89's group at the dock row.
- [ ] RED then GREEN: T7 — `_onAPhone` 1080×2424 @ 2.625: dock up (spitter + ghoul) and dock down: no exception; map, HP, controls, log all findable in both.
- [ ] Doc comment on `BattleDock`: the D90 chain in one sentence; preserved-defect-inverse note (the swap is retired on purpose); watched auto-path refusal is deliberate.
- [ ] Run app suite green; commit `feat: skill bar docks below the always-visible map`.

### Task 3: the far card tap speaks (T3, T4)

**Files:** `packages/app/lib/game/game_bloc.dart, `packages/app/test/battle_view_test.dart`.

- [ ] RED: T3 — tap `the spitter` card (distance 3, no armed skill): log gains exactly one line naming the spitter and saying walk; hero unmoved; armed state unchanged; no other state change.
- [ ] GREEN: `StageCardTapped` event + handler in `game_bloc.dart`: adjacent → dispatch exactly the D89 grammar (`TileTapped(position)` / `CastPressed(armedSpellId, targetId: id)`); beyond one step → emit fresh `GameViewState` carrying the guidance line, `walkId` and `armedSpellId` preserved, game untouched.
- [ ] Sentence: `'${monster.name} is out of reach. Walk to it.'` — names the monster, says walking.
- [ ] GREEN: T4 — rewrite/keep the D89 card-tap tests (bump-attack; armed cast names the target) against the dock.
- [ ] Doc comment on the handler: the sentence is presentation, not an engine refusal — core never sees the tap.
- [ ] Run app suite green; commit `feat: a far stage-card tap tells the player to walk`.

### Task 4: mutation table + final verification

**Files:** none (temporary seds, reverted each time).

- [ ] Run M1–M4, C-1, C-2 per the spec table; record NAMED red sets and greens; M2 is a temporary re-insertion (map slot gated `isBattleOpen ? SizedBox.shrink() : GlyphGrid` — BattleView no longer exists), run, report, revert.
- [ ] If C-1 (HP-bar length) has no existing named red, add a bar-length assertion to the rewritten stage test first, then run C-1.
- [ ] `dart format` clean; `dart analyze .` from worktree root; all three suites green from result files; band diff empty.
- [ ] AVD pass + greyscale shots to MAIN repo `docs/reports/shots/m3-dock/`.
- [ ] REPORT.md to the channel; done notice.