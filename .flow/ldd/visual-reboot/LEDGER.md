# Visual Reboot — Decision Ledger

Reboot the presentation and interaction layer of the existing M3 Flutter
game around a graphical-glyph, phone-first visual language — without
discarding the game. Existing core rules, content, deterministic
simulation, economy, saves, and progression remain product truth unless a
later decision here explicitly changes them. Canonical product spec:
`../../../docs/specs/2026-08-20-dungeon-game-design.md`; M3 contracts and traps:
`../m3/LEDGER.md`.

## Mode

- shared (tracked in git)

## Intake

The epic was opened from an approved external planning handoff:
`external/residuum-visual-reboot-handoff.md` (approved design direction,
795 lines, 18 sections). Intake status per the planning-handoff protocol:

- The handoff is **approved design direction, not an execution plan and not
  implementation authorization**. It proposes its own unit sequence
  (Units 0–8), which this ledger adopts as the working plan below.
- The approved mock is present and inspected at
  `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.
  It is the visual authority for direction, hierarchy, density, tone, and
  interaction intent; current source remains authoritative for game content.
- Where the mock conflicts with current game content, the repository is
  truth (handoff section 2). Do not invent gameplay objects from mock
  illustration.
- Section 12.4's seam inventory (`glyph_grid.dart`, `game_bloc.dart`,
  `battle_view.dart`, etc.) is evidence — fresh recon must verify it before
  any implementation.

## Current state

- **Unit 0 complete; no production code written.** Its source-verified
  baseline is `units/unit-0/recon.md`.
- **Unit 1 accepted.** Its Flame dungeon-scene contract is complete on
  `visual-reboot-unit-1`.
- **Unit 2 accepted.** The graphical Crypt material language is complete on
  `visual-reboot-unit-2`; Sea-Cave and Ruined Keep material parity remains
  Unit 8.
- **Unit 3 merged to `main` at `4164741`.** The suite, analyzer, and acceptance
  review passed. Its deferred AVD/greyscale evidence is scheduled for the
  combined final Unit 3 + Unit 4 device gate on the recreated AVD.
- **Unit 4 is an interrupted acceptance checkpoint** on
  `residuum-visual-reboot-4`, remotely checkpointed at WIP head `0d27a186`.
  Tasks 01–03 and all known review corrections are implemented. Acceptance
  remains open for the final TTC-1A closure review, final-tree formatting/app
  gates, and the combined Unit 3 + Unit 4 recreated-AVD colour/greyscale gate.
  The prior session limit stopped the device pass during encounter search; no
  device acceptance is claimed.

## Epic status

| Unit | Dependencies | State | Verification | Notes |
|---|---|---|---|---|
| Unit 0 — design baseline + recon | none | complete | source recon and approved mock inspection; no code | matrix, seam inventory, corrections: `units/unit-0/recon.md` |
| Unit 1 — dungeon scene foundation | Unit 0 | accepted | 682 app tests, analyzer, final COR/TTC/CRF, Pixel_10 AVD and greyscale pass | contract: `units/unit-1/CONTRACT.md`; Flame only in `packages/app` |
| Unit 2 — graphical dungeon language | Unit 1 | accepted | 721 app tests, analyzer, corrective COR/TTC/CRF, Pixel_10 AVD and greyscale pass | cold-charcoal continuous material, warm clipped light, strict no-geometry-leak fog |
| Unit 3 — crawl interaction reboot | Unit 2 | merged; device evidence pending | 736 app tests, analyzer, review pass; AVD blocked on this host | map-first melee; favorites + overflow |
| Unit 4 — turn timeline + duplicate identity | Unit 3 | interrupted acceptance; WIP checkpoint | initial full app 764 + analyzer clean; first correction full app 765 + analyzer clean; final semantics fix focused 34 + focused analyze clean; closure/final-tree broad/device gates pending | head `0d27a186`; session limit stopped the combined AVD gate during encounter search |
| Unit 5 — log drawer | Unit 3 | contract specified; plan pending | history reviewable during combat without shrinking the map | 3-line peek above the controls, half/full overlay, auto-follow, structured entry with per-line category; contract: `units/unit-5/CONTRACT.md` |
| Unit 6 — character / spells / pack | Unit 3 | pending | no duplicated information architecture | consolidation |
| Unit 7 — town + rooms + heroes | Unit 6 | pending | transactional/refusal semantics preserved | art bible locked before static art |
| Unit 8 — world + theme parity | Unit 7 | pending | final accessibility + device-size pass | Sea-Cave/Keep material identity |

Recon locks the execution order: **1 → 2 → 3 → 4 → 5 → 6 → 7 → 8**.
Units 4 and 5 stay sequential so identity-correct event names land before the
log drawer; no unit reordering is needed.

## Locked cross-unit contracts (inherited from the handoff, section 18)

- Phone-first; tablet later. Flame only for the dungeon scene — never the
  whole app, and **Flame is never authoritative game state**.
- Graphical-glyph dungeon (not sprite-tile), procedural deterministic
  terrain texture, smooth lighting over rules-driven FOV.
- Four-region responsibility rule: map = space/targets, timeline = time,
  log = causality, action shelf = verbs. No concern duplicated across
  regions.
- Map-first melee (tap adjacent enemy); explicit Attack shelf control is
  removed once direct melee is proven; long-press/timeline token inspect,
  never long-press-only.
- Targeted abilities: arm → map target marks → tap to cast; disarm path
  obvious.
- Full spell access with compact favorites/readied presentation + overflow
  (progressive disclosure, NOT a mechanical kit restriction; promotion to a
  true prepared-kit system is a separate future decision).
- Activation queue replaces `NOW`/`IN n` prose; repeated fast-actor
  activations shown literally; duplicate enemies get stable encounter-local
  labels used consistently across map/timeline/targeting/inspect/log.
- 3-line scrollable log peek + half/full overlay history; auto-follow with
  `↓ N new` return affordance.
- No pinch zoom in the first pass; no decorative interactable-looking props
  unsupported by rules; non-dungeon UI quiet and subordinate to the map.
- Accessibility non-negotiable (AGENTS.md + handoff 3.5): no important state
  carried by hue alone; targeting marks readable in greyscale/value.
- Input boundary: Flame hit-tests and emits intents; app state decides
  meaning and dispatches core actions. Presentation actor labels are not
  core entity identity.
- Dependency rule `app → content → core` preserved; no combat balance,
  content, generator, or recipe changes ride this epic (explicit non-goals,
  section 14).
- Everything locked in `../m3/LEDGER.md` (save v3, band controls, house
  method D113, CI/merge flow) still binds.

## Environment traps

- All M3 traps carry (`../m3/LEDGER.md`): no root pubspec (suites per
  package dir); copy BOTH device save slots aside before any install; phone
  build not debuggable (adb screenshots only); squash merges invisible to
  merge-base; never rename CI job/check names; widget-driven UI units with
  the AVD pass as final acceptance gate (D113).
- The band lines remain byte-identical controls for anything that could
  touch balance — this epic should not move them at all (non-goal).
- Old-era artifact paths (`docs/epic/…`, `docs/plans/…`,
  `docs/superpowers/…`) are stale. Durable standalone specs now live under
  `docs/specs/`; LDD records live under `.flow/ldd/`.

## Open questions

### User/product decisions

- Dungeon/material art bible subset: **locked for Unit 2**
  (`units/unit-2/ART-BIBLE.md`). Portrait framing, bulk static-art
  composition, and the full non-dungeon icon language remain to lock before
  Unit 7.
- Does the old-wave m3-quests (M3Q, save v4, `../m3/LEDGER.md`) still run,
  and where in the sequence?

### External dependencies

- Curated static art generation (section 11.2) requires a generation
  workflow outside the repo — owner and tool not yet decided.

## Decision log

Append-only. Supersede old decisions; do not rewrite history.

- 2026-09-14 — Unit 3 re-orient and recon: verified at source that the Flame
  scene already emits `onTap(position)`/`onPan(delta)` intents through
  `TapCallbacks`/`DragCallbacks` (Flame 1.38.2 also ships `LongPressCallbacks`
  with `canvasPosition`); `_onTileTapped` still refuses adjacent-monster taps
  with the watched refusal; `BattleSkillBar` still carries the explicit
  `Attack`/`ArmedAttack`/`AttackArmed`/`StageCardTapped` armed flow; target
  marks already render on the map via `markedIds: state.armedTargets` but map
  taps never cast. No Unit 3 surface drifted since Unit 2. The Unit 3 contract
  is proposed at `units/unit-3/CONTRACT.md`; two open decisions (camera
  ease-back scope, readied-slot model) await the user. No production code
  written.

- 2026-09-14 — Unit 3 open decisions resolved by the user: camera ease-back is
  deferred (Unit 3 ships only the recenter affordance over the current instant
  snap); readied slots are the fixed school-order first few known spells plus
  Wait with no pinning/persistence. Contract is decision-complete and ready for
  user review before any planning or code.

- 2026-09-14 — Unit 3 contract approved by the user. Execution-grade plan
  written at `units/unit-3/PLAN.md` with three sequential task briefs
  (`01-bloc-interaction`, `02-scene-input`, `03-shelf-and-screen`) on one
  non-isolated checkout `residuum-visual-reboot-3` from `affc138`. Plan quality
  gate: COR run, TTC run, CRF run, SEC skip. Key locked contracts: armed state
  collapses `ArmedAction`/`ArmedAttack`/`ArmedSpell` to one `String?
  armedSpellId`; map tap decides melee/cast/disarm in the bloc by
  branch-by-branch precedence; armed + non-target tap disarms (no move);
  map-targeted cast uses any visible monster (reconciled to core
  `_castRefusal`); stage cards become inspect-only; `AttackArmed`/
  `StageCardTapped`/`_outOfReach` are removed, not shimmed. Awaiting local
  implementation authorization before dispatch.

- 2026-09-13 — Epic bootstrapped during the docs/LDD restructure. The
  external handoff is accepted as approved design direction; its proposed
  unit sequence is adopted as the working plan; its baseline summary is
  recorded as inherited locked contracts pending Unit 0 recon validation.
  No implementation authorization granted yet — Unit 0 (read-only recon)
  is the first authorized step, and the Unit 1 contract requires review
  before any production code.

- 2026-09-13 — Unit 0 accepted the approved mock at
  `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`,
  verified the app seams at source, and recorded the behavior matrix,
  corrections, and execution-order confirmation in `units/unit-0/recon.md`.
  The external markdown handoff lacks the current protocol manifest, so it
  remains accepted design evidence rather than a validator-compliant intake
  bundle. Unit 1's Flame boundary and acceptance contract is proposed at
  `units/unit-1/CONTRACT.md`; user review remains required before code.

- 2026-09-13 — User approved the Unit 1 Flame dungeon-scene contract.
  Implementation is authorized only within `units/unit-1/CONTRACT.md`, on
  `visual-reboot-unit-1`; no later visual-reboot unit is authorized.

- Unit 1 review disposition: **COR run** (renderer replacement), **TTC run**
  (behavioral/widget contracts), **CRF run** (new scene boundary and
  maintainability), **SEC skip** (no security boundary or external input).

- 2026-09-13 — Unit 1 replaced the crawl `CustomPainter` with a state-owned
  Flame scene host on `visual-reboot-unit-1`. Initial COR/TTC/CRF found
  viewfinder-coordinate, pan-allocation, and camera-sync-proof defects; the
  owner corrected them with fresh Red/Green evidence. The complete
  `packages/app` suite then passed (680 tests). The user paused before the
  corrected review rerun and AVD/greyscale acceptance; no Unit 1 acceptance
  decision has been made.

- 2026-09-13 — Unit 1 acceptance resumed. COR/TTC/CRF found and the owner
  corrected component-reconciliation, battle-dock scene retention, pan-only
  projection reuse, renderer-boundary, and README-drift defects. Final COR,
  TTC, and CRF were clean; SEC remains skipped because no security boundary
  changed. Pixel_10 AVD acceptance confirmed the Flame scene renders the
  crawl, adjacent-monster taps retain the watched refusal, and the marked
  glyph/message remain legible in greyscale. Unit 1 is accepted; Unit 2 is
  not authorized.

- 2026-09-13 — User approved the Unit 2 dungeon-material art direction: an
  etched dark-fantasy diagram built from continuous cold-charcoal stone,
  near-black unknown void, dark/flat remembered geometry, restrained warm
  amber illumination clipped to authoritative visibility, low-to-medium
  deterministic procedural texture, and crisp graphical-glyph actors.
  Value/detail, not hue alone, must distinguish knowledge and targeting
  states. Exact palette anchors may tune during device acceptance without
  reopening the direction. This lock covers dungeon material language;
  portrait framing, bulk static-art composition, and the full non-dungeon
  icon family remain deferred before Unit 7.

- 2026-09-13 — Unit 2 intake: the ChatGPT planning handoff
  (`external/unit-2-chatgpt-handoff/`) passed the planning-handoff validator
  against observed ref `216cd469788486db6ba907490462cce0c87e8079`; local HEAD
  equals the observed ref with no intervening commits. Its Unit 2 contract
  and art bible are reconciled canonically at `units/unit-2/`. Unit 2
  separates material terrain presentation from semantic glyph/entity
  projection: the renderer receives explicit known-terrain tile/knowledge
  facts rather than parsing terminal terrain glyphs; procedural decoration
  uses presentation-only deterministic coordinate/theme hashing, never
  gameplay RNG; lighting is a smooth presentation transform clipped to the
  authoritative visible set, never a second FOV/shadow simulation;
  Sea-Cave/Ruined Keep material parity stays with Unit 8. The handoff carries
  `authorization: not-carried` — normal local execution approval is required
  before production writes.

- 2026-09-13 — Unit 2 accepted on `visual-reboot-unit-2`. The renderer uses
  an immutable explicit known-terrain material plan, cached continuous
  hero-local light clipped to authoritative visibility, deterministic sparse
  decoration, and exposed known-wall faces contained within known material.
  Stairs remain semantic glyph marks derived from material facts; core state,
  gameplay RNG, FOV, input, and Unit 1 interaction semantics are unchanged.
  COR and TTC completed clean; CRF findings were corrected and re-verified.
  SEC was skipped because no security boundary changed.

- 2026-09-14 — Unit 3 implementation authorized and dispatched to one
  non-isolated `flow-plan-executor` (`Unit3Executor`) on
  `residuum-visual-reboot-3`. The executor completed all three tasks
  (bloc semantics, scene long-press, shelf+screen) but was force-stopped
  mid-edit once on a soft request budget; Main revived it with a precise
  six-point resume directive and it finished. Full app suite 733 passed and
  analyzer clean at implementation commit `a8eacf1`.

- 2026-09-14 — Unit 3 acceptance review (single `flow-acceptance-reviewer`,
  per the planned path). Verdict CHANGES. Contract satisfaction, plan
  conformance, and correctness all PASS; the one Important finding was a
  test-contract gap: every cast test fired at an orthogonally-adjacent
  monster, so the retired adjacency-only dock path was not actually
  protected by a test. One Minor: `inspectTargetAt` returned
  `monsterAt(position)` with no visibility gate. Batched both to the live
  executor; it added the distant-visible-monster cast test + unseen-monster
  disarm negative, and gated inspect on `game.visible.contains`. Correction
  committed `0156a0b`; full suite 736 passed and analyzer clean. Security
  skip (no trust boundary).

- 2026-09-14 — Unit 4 start: source recon at `4164741` confirmed that
  `GameViewState.upNext` already exposes core's literal repeated scheduled
  actors, while `BattleDock` still renders stage cards plus raw-name
  `NOW`/`IN n` prose. `glyphPlan`/the Flame scene have a stable entity-id
  projection seam and `_describe` already supplies pre-step event names. The
  reconciled contract at `units/unit-4/CONTRACT.md` locks the direct
  `[YOU] → upNext → [YOU]` queue, no-knowledge-leak truncation, view-scoped
  deterministic duplicate labels, map badge/selected-outline ownership, and
  token inspect/focus without a core action. No production code written.

- 2026-09-14 — Unit 4 execution plan accepted by the architect at
  `units/unit-4/PLAN.md`, with three sequential fresh-executor briefs:
  identity/queue/bloc lifetime; map badges/selection/focus; then timeline and
  legacy cutover. COR/TTC/CRF passed and SEC is skipped (no external trust
  boundary). User implementation authorization is granted; Task 01 has focused
  proof and Task 02 is active on the non-main `residuum-visual-reboot-4` branch.
  Main owns final app suite/analyzer, acceptance review, and the combined Unit 3
  + Unit 4 colour/greyscale evidence on the current recreated AVD.

- 2026-09-14 — User directed that Unit 3's missing opportunity for device
  acceptance be folded into Unit 4. The final Unit 4 current-AVD colour/greyscale
  session must now demonstrate Unit 3's one-handed melee, arm → target → cast,
  inspect, and shelf flow alongside Unit 4's timeline/identity acceptance
  criteria. This discharges the Unit 3 device-evidence debt; no Unit 3 code is
  reopened.

- 2026-09-14 — **Unit 4 is accepted.** TTC-1A is closed by a targeted PASS
  review, the final tree passes scoped formatting, `flutter analyze`, and 765
  `packages/app` tests, and the combined Unit 3 + Unit 4 colour/greyscale device
  gate passed on `emulator-5554` against a real generated crypt and a real road
  ambush. Unit 3's deferred device-evidence debt is discharged with it. The unit
  is ready for `flow-integrating`; publication and merge remain user-owned.
- 2026-09-14 — Device-scene sourcing rule, learned here and worth keeping: the
  first delve bumps `visit` to 1, so a floor probed at `visit: 0` is not the
  floor the player meets. Probe `buildFloor(depth, worldSeed:, visit: 1)` and
  `startRoadEncounter`/`roadSeed` to pick a world and day that already contain
  the required cast, then play it — never add a fixture or bend generation.

- 2026-09-14 — Unit 4 published as
  [PR #13](https://github.com/fiatcode-gh/residuum-rpg/pull/13) against `main`
  with user approval. Merge remains user-owned.
- 2026-09-14 — **Art/asset work is deferred until Units 5-8 are done.** A gap
  read of the mock's crawl panel against the live screen found three remaining
  differences: HUD chrome (depth header plus labelled HP/Mana bars, icon control
  chips, peek above controls), the log drawer (Unit 5), and an art pass (tile
  texture, wall-face art, torch and prop sprites, edge fog). `packages/app` has
  no `assets:` block, no asset directory, and no sprite reference anywhere in
  `lib/`, so the art pass needs an asset pipeline that does not exist yet. The
  user rejected interleaving a chrome/asset unit before Unit 5; the original
  1 → 8 order stands and asset planning happens after Unit 8. HUD chrome has no
  owning unit yet and must be placed before the epic closes.
- 2026-09-14 — Unit 5 recon completed and recorded at `units/unit-5/recon.md`.
  The log is already exact, ordered, and identity-correct; what is missing is
  the drawer, the follow state, and any structure on an entry. The open
  contract question is per-line category icons, which `List<String>` cannot
  carry: either introduce a structured presentation entry or drop icons for
  this unit, never infer a category from sentence text.
- 2026-09-14 — **Unit 5's three contract forks are settled with the user and
  `units/unit-5/CONTRACT.md` is written.**
  1. *Structured entry now.* `GameViewState.log` becomes a list of an app-only
     presentation entry carrying the sentence plus one category, rather than
     `List<String>`. Decisive facts: the log is pure view state that
     deliberately does not survive a suspend (`main.dart:572`), so there is no
     save-format exposure; and the only correct category source is the
     `GameEvent` variant, available exactly where `describeEvent` already
     switches on it (`event_messages.dart:19-79`). Deferring icons would not
     shrink the migration, only move it into a later unit that is not about the
     log. Rejected: dropping icons for this unit; a parallel category list
     beside the strings; any text-matching inference.
  2. *Unit 5 moves the peek above the controls*, matching the mock. This
     discharges one item from the unowned HUD-chrome list; the depth header,
     labelled HP/Mana bars, and icon control chips remain unowned.
  3. *Death wins.* Game-over collapses the drawer and inerts its handle; the
     `_DeathOverlay` scrim (`game_screen.dart:714`, `0xCC0E1014` over the whole
     `Stack`) stays the one interactive surface. Rejected: keeping the log
     readable behind the overlay, and rendering the final lines inside the
     overlay.
  The category set itself is contract-bounded but not enumerated in the
  contract: the design spec has no log-category vocabulary, so naming must come
  from existing `core` event words and inventing a synonym is a defect. The
  contract fixes the distinctions the set must support and forbids a catch-all
  member; the enum's membership is planning work.
- 2026-09-14 — Migration cost measured before deciding, not estimated:
  `packages/app/test` has 87 `log`-touching references across 8 files. Mechanical
  churn for the entry migration, and it must not change any asserted sentence.

## Verification receipts

- 2026-09-13 — Unit 0 inspected the approved mock and source-verified the
  renderer, BLoC/action boundary, camera/input, battle dock, log formatter,
  Pack/Character, world, town, and transactional-screen seams. The external
  handoff validator was also run and correctly reported its absent
  `FLOW-HANDOFF.json`; no production behavior was exercised or changed.

- 2026-09-13 — Unit 1 worker proof: initial scene test Red; focused Green
  tests, `flutter analyze`, and formatting passed. After review corrections,
  focused scene/game tests and `flutter analyze` passed; the architect ran
  `flutter test` from `packages/app` successfully (680 tests). An AVD
  `Pixel_10` was started but no app install or visual acceptance was performed;
  it was stopped when the work pause began.

- 2026-09-13 — Final Unit 1 evidence: `flutter test && flutter analyze` from
  `packages/app` passed (682 tests; no analyzer issues). Final COR/TTC/CRF
  review findings were clean after the last correction. Pixel_10 AVD images
  are `.flow/evidence/visual-reboot/unit-1-initial.png`,
  `unit-1-adjacent-monster-tap.png`, and
  `unit-1-adjacent-monster-tap-greyscale.png`; the latter preserves the
  glyph outline and refusal message without hue.

### Unit 2 intake receipt

- 2026-09-13 — Unit 2 intake validation: `validate-planning-handoff.py` ok
  (`kind=ldd repository=fiatcode-gh/residuum-rpg observed_ref=216cd46…`).
  Local checkout confirmed on `main` at the same ref, dirty tree limited to
  the untracked handoff bundle. Source seams re-verified at that ref:
  `dungeon_scene.dart` renders `glyphPlan` cells through `_GlyphComponent`;
  `glyph_plan.dart` owns terrain/node/litter/monster/hero projection over
  `visible`/`explored`; `dungeon_palette.dart` selects Crypt/Sea-Cave/Ruined
  Keep; pan-only projection reuse (`_reusesProjection`) is present. The
  approved mock was re-inspected against the proposed art bible and matches
  its direction. No production code was written during intake.

### Unit 2 acceptance receipt

- 2026-09-13 — Unit 2 worker Red/Green proof covers renderer-level
  continuous-light clipping, remembered/unknown no-leak, projection cache
  refresh, material-fact stairs, known-wall continuity, immutable plan
  ownership, and deterministic applicable decoration. Main ran
  `flutter test && flutter analyze` from `packages/app`: 721 tests passed
  with no analyzer issues. Final Pixel_10 evidence is
  `.flow/evidence/visual-reboot/unit-2-crypt-crawl-final-no-leak.png` and
  `unit-2-crypt-crawl-final-no-leak-greyscale.png`. The device save and
  previous-save bytes were restored and SHA-256 verified after the smoke
  session. COR and TTC found no remaining defects; CRF findings were
  corrected with focused proof. SEC was skipped because no security boundary
  changed.

### Unit 3 acceptance receipt

- 2026-09-14 — Unit 3 worker proof: task 01 Red→Green on bloc semantics
  (map melee, armed cast/disarm, inspect getter, recenter, `heroOffScreen`);
  task 02 scene long-press Red→Green; task 03 shelf/overflow/inspect/recenter
  Red→Green. Focused proof 204 tests across 8 files, then 125 bloc tests after
  the review correction; `dart format` on all touched files.
- 2026-09-14 — Main ran `flutter test && flutter analyze` from `packages/app`
  at implementation head `a8eacf1`: 733 tests, no analyzer issues. After the
  acceptance-review correction `0156a0b` (visible-cast test + inspect
  visibility gate): 736 tests, no analyzer issues.
- 2026-09-14 — Acceptance review (single `flow-acceptance-reviewer`,
  `Unit3AcceptReview`): CHANGES → one Important test-contract gap (cast tests
  only covered adjacency, so the retired adjacency-only path was unprotected)
  and one Minor (`inspectTargetAt` missing a visibility gate). Corrected by the
  executor with fresh proof; Main re-verified 736 tests + clean analyzer.
  skip (no trust boundary). Contract satisfaction, plan conformance,
  correctness PASS.
- 2026-09-14 — **AVD/greyscale acceptance BLOCKED (environment).** Two
  Pixel_10 launches died at scene-init/memory stage on this 14 GiB host
  (4.4 GiB available vs the AVD's 16 GiB recommendation); no `adb` device ever
  registered. Not a code defect. Criterion 10 (device evidence) remains open
  and must be captured on a host that can boot the AVD before Unit 3 is
  accepted for merge.
- 2026-09-14 — Unit 3 pushed to `origin/residuum-visual-reboot-3` and opened
  as PR #12 (`https://github.com/fiatcode-gh/residuum-rpg/pull/12`). Merge is
  user-owned and gated on the still-open AVD acceptance.


### Unit 4 interrupted-session receipt

- 2026-09-14 — Tasks 01–03 completed on `residuum-visual-reboot-4`. Main's
  first broad gate passed `flutter analyze` and full `flutter test` with 764
  tests before acceptance review. The single `flow-acceptance-reviewer`
  returned CHANGES with two Important TTC coverage gaps plus stale LDD status;
  it found no Critical production defect and statically traced the production
  behavior/ownership path cleanly.
- 2026-09-14 — `CorrectUnit4Coverage` fixed the duplicate-identity/survivor
  contract and genuinely overflowing phone-timeline coverage without changing
  production code. Focused proof passed 40 tests; Main then passed full
  `flutter test` with 765 tests and `flutter analyze` clean. Targeted
  `ReReviewUnit4Coverage` resolved TTC-2 and narrowed TTC-1 to one remaining
  Important gap: the second duplicate timeline token's exact assistive
  semantics were not asserted.
- 2026-09-14 — `CloseTimelineSemantics` added the exact second-duplicate
  semantics assertion (`the ghoul²`, button=true) as a test-only correction.
  `battle_view_test.dart` passed 34 tests; scoped format changed nothing and
  focused analysis was clean. The session ended before a targeted closure
  re-review. Because this assertion changed the final test tree after the
  765-test broad gate, final-tree formatting/analyzer/full-test proof remains
  open.
- 2026-09-14 — The recreated `Medium_Phone` AVD timed out its initial
  180-second readiness wait but later registered as `emulator-5554`; Flutter
  reached its ready state. Exploratory local screenshots were captured from
  town/crypt/dungeon/crawl progression, but the session limit terminated the
  run during encounter search before Unit 3's one-handed melee/cast/inspect
  flow, Unit 4's duplicate/repeated-activation/timeline focus flow, or the
  greyscale selected/target-state criterion were accepted. No completed device
  acceptance or save-slot backup/restoration receipt was recorded.
- 2026-09-14 — After the involuntary session-limit stop, the user created and
  pushed recovery checkpoint `0d27a186` (`feat(wip): visual reboot unit 4`) to
  `origin/residuum-visual-reboot-4`. This is a resumable WIP checkpoint, not a
  Unit 4 acceptance or integration decision.

### Unit 4 acceptance receipt

- 2026-09-14 — Resumed at `cfd472f` on `residuum-visual-reboot-4`, clean tree,
  identical to the remote branch (`0d27a18` code plus the docs checkpoint).
- 2026-09-14 — Targeted closure review (`Unit4ClosureReview`,
  `flow-acceptance-reviewer`): **PASS, TTC-1A closed.** The second duplicate's
  semantics are asserted by exact equality (`the ghoul²`, `button: true`) on the
  token's own `Semantics` node resolved through `Key('timeline-actor-ghoul-2-3')`,
  and the ordering is pinned by the exact `dock-backing` text list. The
  correction was test-only; no other assertion was weakened. Focused run:
  `battle_view_test.dart` 34 tests passed.
- 2026-09-14 — Final-tree Main gates from `packages/app`: scoped
  `dart format --set-exit-if-changed` reported 19 files, 0 changed;
  `flutter analyze` found no issues; full `flutter test` passed 765 tests.
- 2026-09-14 — **Combined Unit 3 + Unit 4 device gate PASSED** on the
  `Medium_Phone` AVD (`emulator-5554`, 1080×2400). Evidence is under
  `.flow/evidence/visual-reboot/unit-4-device/` as `ev-*.png` with a greyscale
  copy of every frame. The scene was reached by deterministic content probing
  (world seed `1789378289602`, visit 1) rather than by any production fixture:
  crypt depth 1 held two giant rats plus a dire wolf, depth 2 held two dire
  wolves and the Book of Firebolt, and the day-5 lowland road ambush held two
  rats plus a dire wolf. No content, generator, or production code was touched.
- 2026-09-14 — Criteria observed on device: (1) the row read
  `@ YOU › r¹ › r² › w › w › @ YOU`, the speed-20 wolf occupying two separate
  tokens, and later `@ YOU › r¹ › w › r² › w › @ YOU`; (2) map badge, timeline
  token, inspect header (`r² the giant rat²`) and log (`The giant rat² claws
  you for 1.`) agreed, while singletons stayed unbadged (`w the dire wolf`);
  (3) badges appeared only once the second member was seen, and the survivor
  kept `r¹` after `The giant rat² dies.`; (4) a hidden owed dire wolf truncated
  the row to `@ YOU` while an engaged rat stood adjacent — no placeholder,
  count, or name leaked; (5) tapping a timeline token centred the camera on the
  actor, drew the circular selection, and opened inspect with a byte-identical
  hero/monster/energy/RNG save snapshot before and after the tap; (6) armed
  firebolt drew square target outlines while the selected wolf carried both a
  square and a circle, legible in the greyscale copy; (7) no stage card, `NOW`,
  `IN n`, or arrival estimate appeared anywhere in the dock.
- 2026-09-14 — Unit 3's deferred device criteria were discharged in the same
  session: map-tap melee (`You hit the giant rat² for 3.`), arm → target → cast
  (`Firebolt burns the giant rat¹ for 2.`) with the contextual combat shelf
  (`✳ Firebolt 2 — armed`, `Wait`), map inspect on a non-adjacent monster, and
  the pan → recenter path (affordance appears when the hero leaves the viewport
  and returns focus to the hero when tapped).
- 2026-09-14 — Device save hygiene: `save.json` and `save-previous.json` were
  copied off the device before the session and restored afterwards; both files
  verify SHA-256 identical to the pre-session backup
  (`18995c4a…`, `8909f70c…`). Session-local checkpoints used during evidence
  capture stay in the untracked evidence directory. Throwaway content probes
  were deleted; `git status` is clean and no `packages/` file changed.

## Corrections to inherited assumptions

- The approved mock is present at the canonical untracked evidence path; mock
  placement is no longer open.
- The external markdown handoff has no `FLOW-HANDOFF.json`. Its approved
  design direction remains ledger/user-authorized evidence, while source
  claims were revalidated in Unit 0.
- At Unit 0, source used `GameScreen`, `GlyphGrid`, `CustomPainter`, and
  `TextPainter`; Unit 1 replaced that renderer with the Flame scene host.
- Current map taps on adjacent monsters refuse rather than melee; direct melee
  is an approved Unit 3 behavior change, not a Unit 1 preservation contract.
- The source uses raw-name `NOW` / `IN n` text, a `List<String>` log, and no
  duplicate presentation identity. `event_messages.dart` is the safe seam for
  later actor-label decoration.
- `Market` in the handoff is stale: the current town door is `Merchant`, and
  Heroes is entered from the world screen.