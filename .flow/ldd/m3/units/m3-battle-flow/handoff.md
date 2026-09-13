# m3-battle-flow handoff — folded 2026-09-03 (CLOSED)

Folded chronologically from dispatcher.md (2 entries) and worker.md (3 entries). REPORT mirrored as m3-battle-flow-build-report.md. The unit: M3BF — the battle interaction rebuild from playtest verdicts V1+V2+V8+V9: NOW/IN-N turn-order chips on a whole-header backing, armed-target flow with attack as a bar action, bump-attack and map tap-to-attack retired, bare tap = enemy info, core WaitAction + "You hold your ground.", the two-state battle glyph. Verified and accepted at `12f3746` (D104); merged via GitHub PR #2 as `bf8bcb6` (D106). Four shape deviations pre-declared and approved (D1 sealed ArmedAction, D2 bottom sheet, D3 GlyphCell.marked painter outline, D4 codepoints first — the CustomPaint swap never fired).

=== DISPATCHER ENTRIES ===

## 1 — dispatcher — 2026-09-03T16:45:23+07:00
Dispatch note — m3-battle-flow (story M3BF), dispatched 2026-09-03.

Worker: read the build prompt at /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-battle-flow-build-prompt.md in full and follow it. The spec is /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-battle-flow-spec-M3BF.md; recon at /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-battle-flow-recon.md. Worktree /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-battle-flow — ALREADY CREATED on branch m3-battle-flow off main 6a1500a; do NOT create it. Base: main 6a1500a (= 594bc80 + a .gitignore-only commit), 1941 green (architect-verified at 594bc80; measure your own fresh baseline).

Mailbox tool (all writes go through it): /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox

Locked decisions you inherit (D97/D98/D103): the V2 action-first flow with armed-target marking in dock AND map; attack as a bar action (bump-attack gesture retired, core bump mechanism untouched); bare card tap = enemy info; map tap-to-attack retired into the watched-refusal branch; core WaitAction + HeroWaited with the app WaitPressed and the log line "You hold your ground."; chips NOW/IN-N + whole-header backing; two-state glyph with the drawn-glyph fallback pre-declared if codepoints fail on the AVD. Save v3 stands; no save shape change. The bands pin: crypt 16/40 {1:1,2:9,3:8,4:6,5:16}, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40 — byte-identical or stop. Attack the spec's central claims by measurement (the prompt names five); deviations are pre-declared here before code.

disposed through worker entry: none yet

disposed through worker entry: none yet

## 2 — dispatcher — 2026-09-03T16:56:55+07:00
Acknowledged entry 1 — all four deviations APPROVED, none is a hold; build them as declared.

D1 APPROVED — the sealed ArmedAction (ArmedAttack / ArmedSpell(spellId)) is the right fork of the spec's enum-or-sentinel choice: a sentinel string would be a naked string for a domain concept. One commit moves the state with every consumer and the :2039 group's pins, old values quoted. Your consumer enumeration stands ratified.

D2 APPROVED — modal bottom sheet for enemy info, words-only, dismissal costs no turn.

D3 APPROVED — GlyphCell gains a default-false `marked` flag; the painter strokes a one-pixel ink rect outline before the glyph. No per-cell widgets, draw order unchanged. Note for the AVD pass: the outline must read over any terrain glyph the plan can put under it — check the read on both floor and wall adjacency, and in the greyscale shots.

D4 ACKNOWLEDGED — build with '◉'/'✖'; the spec pre-authorises the CustomPaint swap, declared in the mailbox if the AVD shows bad coverage.

Your five attack results all match my own recon and my own re-read of position.dart directionTo (orthogonal-only, verified just now at source) — no finding changes the spec. The auto-walk guard (monsterAt(next) -> stopWalking) closes the third swing path I was worried about; good catch to have it on the record.

Standing notes: (a) the mutation table in the prompt gains whatever rows your own measurement says the map-outline pass and the sealed-class widening need — named sets both phases; (b) the watched-refusal branch stays ONE sentence per the spec — if the monster-tile gate and the watched walk both land there, keep the single sentence and its pin; (c) plan doc uncommitted as instructed. My watch is standing; acks within a task. Proceed.

disposed through worker entry 1

disposed through worker entry 1


=== WORKER ENTRIES ===

## 1 — worker — 2026-09-03T16:55:29+07:00
Kickoff — m3-battle-flow worker, entry 1.

Worktree confirmed: /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-battle-flow, git rev-parse --show-toplevel names it, HEAD = 6a1500a on branch m3-battle-flow, tree clean.

Watch status: standing watch running as a harness background task (bg_run), restarted after its first fire delivered your entry 1; liveness verified (PID alive past one 30-second tick). Your entry 1 read in full and disposed.

Fresh baseline measured on unmodified 6a1500a, per package directory, all exits 0: core 828, content 550, app 563 — 1941 green, matches your count.

Spec claims attacked by measurement (all five, before any code):

1. Bump dispatch sites — CONFIRMED two, and I add a third-place audit: MoveAction call sites in app are exactly game_bloc.dart:540 (_onTileTapped directionTo branch), :674 (FleePressed, dispatches wayOut which by construction points off the grid edge, never at a monster), :746 (auto-walk step, guarded at :739 by game.monsterAt(next) != null -> stopWalking, so auto-walk can never step INTO a monster tile). StageCardTapped adjacent bare tap dispatches TileTapped(monster.position) which re-enters the same directionTo branch. No third swing path exists. Auto-walk ending at a monster: the guard stops the walk, no bump.

2. Attack geometry — CONFIRMED consistent, no finding. Position.directionTo (core position.dart:53) returns null unless isOrthogonallyAdjacentTo (Manhattan == 1), so the map bump can no more strike diagonally than the card gate. 4-way movement is a documented core rule (position.dart dartdoc). The armed-Attack target set = orthogonally adjacent monsters matches both surfaces.

3. Wait verb bot-visibility — CONFIRMED safe. The content bot (survivability_test.dart _decide) constructs actions directly and has NO switch over GameAction; _anyStep likewise. The only exhaustive switches over GameAction are core's own two (step.dart:81 main switch, :435 _refuse) — both will fail to compile on the new sealed subtype, which is the loud, wanted tripwire. Nothing in content/ or app/ switches exhaustively over GameAction.

4. NOW chip clock — CONFIRMED correct. step.dart:68 spends actCost from hero energy BEFORE _monsterPhase, which schedules on the post-spend energy (step.dart:600). upNext (game_bloc.dart:290) replays scheduleMonsterTurns with hero.energy - actCost on the current state — exactly the engine's next-step schedule. Wait spends actCost like every non-refused action (the spend at :68 happens before the switch), so upNext on a post-wait state is the same formula with no special case. NOW = upNext.first agrees after a wait.

5. armedSpellId consumers — enumerated in full: battle_view.dart:218,223 (bar marking); game_bloc.dart:155 (ctor), :196 (field), :551,565,587,663,703,778 (carry-through in every rebuild), :576-578 (stage-card dispatch), :647 (SkillArmed set); tests: battle_view_test.dart:195,394,450; game_bloc_test.dart armed-skill lifecycle group :2039 (8 blocTests, 12 having() pins). No other consumer anywhere. I will rename the field and update every site plus the pins in the one commit that moves the state, old values quoted.

Pre-declared shape deviations (holding build of the affected pieces until your ack):

D1 — armed-state widening: I replace `String? armedSpellId` on GameViewState with `ArmedAction? armedAction`, a sealed class: `ArmedAttack` (const, no fields) and `ArmedSpell(spellId)`. Rationale: the spec's enum-or-sentinel fork; a sentinel string 'attack' would be a naked string for a domain concept (house rule), and a sealed class keeps the SkillArmed carry-through pattern mechanical (`armedAction: state.armedAction`). Test churn: the :2039 group's `having((s) => s.armedSpellId, 'armed', 'firebolt')` pins become `having((s) => s.armedAction, 'armed', const ArmedSpell('firebolt'))` etc., moved in the same commit with old values quoted. If you prefer the sentinel or an enum, say so and I build that.

D2 — C4 enemy info surface: a modal bottom sheet (showModalBottomSheet), monospace, ink-on-panel, listing name+glyph, wounds, attack min-max, reach in words, speed, Resists/Burns lines from DamageType.word. Rationale: the app already has no dialog precedent for info; a sheet keeps the map visible and dismisses on tap-outside with no state change.

D3 — map target outline: I extend GlyphCell with an optional `marked` flag (default false) and have the painter stroke a one-pixel ink rect outline around a marked cell before painting its glyph — no per-cell widgets, draw order unchanged, marking is shape+position not hue. Alternative shapes (separate pass list on the plan) available if you prefer.

D4 — C6 glyph codepoints: build with '◉' watched / '✖' engaged per spec; CustomPaint-drawn eye/cross swap is pre-authorised by the spec if the AVD pass shows bad monospace coverage — I will declare the swap in the mailbox if it fires.

Nothing else deviates from the spec. Plan document next at docs/plans/2026-09-03-m3-battle-flow.md (uncommitted), then characterization tests on 6a1500a, then core wait verb TDD while D1-D4 wait for your ack.

disposed through dispatcher entry 1

disposed through dispatcher entry 1

## 2 — worker — 2026-09-03T17:01:05+07:00
Acknowledged entry 2 — D1 (sealed ArmedAction), D2 (bottom sheet), D3 (GlyphCell.marked), D4 (codepoints first) all APPROVED; building them as declared. Disposed through your entry 2.

Standing notes taken: extra mutation rows will be added where my measurement says the outline pass and the widening need them; the watched-refusal branch keeps its single sentence and its pin; plan doc stays uncommitted.

Progress: core wait verb is green. New test file packages/core/test/engine/step_wait_test.dart (7 tests: one event only, stand-still + world tick, reach-holder shoots a waiting hero, bound monster sits out, encounter legality, never refused, seed determinism). Core suite 835 green (baseline 828 + 7). Committing the verb next.

One watch lapse, disclosed: my standing watch died between entries (process gone, liveness check failed at the last boundary — cause not diagnosed, the task's output file is empty). Restarted it first thing, liveness re-verified (PID 675945, past one tick). Boundary checks continue.

disposed through dispatcher entry 2

## 3 — worker — 2026-09-03T17:50:11+07:00
DONE — m3-battle-flow. REPORT.md is in the channel directory; this is the done notice.

Summary: 11 commits on m3-battle-flow (5bc47c2..12f3746), nothing pushed, nothing under docs/ committed, parent repo untouched. Suites green per package directory: core 835, content 550, app 589 (baseline 828/550/563 = 1941, measured fresh on 6a1500a). Five band lines byte-identical, quoted from my own run. dart analyze + dart format clean from the worktree root. Mutation table complete in the report — 7 rows, named reds and greens both phases, reverts proven clean. AVD pass done with the save-aside ritual (both saves verified aside AND restored byte-identical after); chips, backing, outlines, glyph in all three states, info sheet, map refusal, bar Wait, and the armed bump all read in pixels; greyscale variants included; both glyph codepoints render correctly so the CustomPaint swap never fired.

Deviations D1-D4 as pre-declared and approved. One road-row Wait surface is widget-tested but unshot on device (no road fight occurred this run) — declared in the report, section 7.

My watch: I stop restarting it now and let the final instance expire on its timeout — the unit is closing.

disposed through dispatcher entry 2
