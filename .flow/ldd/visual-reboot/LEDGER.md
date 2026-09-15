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
- **Units 1–6 are all accepted and present on `main`.** Verified at source on
  2026-09-15: PR #13 `650fa7c`, #14 `15e737a`, #15 `55a226d`, #16 `319d945`
  are all MERGED, and `main` is at `319d945` with a clean worktree in sync
  with `origin/main`. Earlier "interrupted"/"uncommitted" wording in this file
  for Units 4 and 6 is superseded.
- Sea-Cave and Ruined Keep material parity remains Unit 8.
- **Unit 7 (town + transactional rooms + heroes) is the active unit.** It is
  in the contract stage; no implementation is authorized.

## Epic status

| Unit | Dependencies | State | Verification | Notes |
|---|---|---|---|---|
| Unit 0 — design baseline + recon | none | complete | source recon and approved mock inspection; no code | matrix, seam inventory, corrections: `units/unit-0/recon.md` |
| Unit 1 — dungeon scene foundation | Unit 0 | **merged** to `main` | 682 app tests, analyzer, final COR/TTC/CRF, Pixel_10 AVD and greyscale pass | on `main` at `5f8db47`; contract: `units/unit-1/CONTRACT.md`; Flame only in `packages/app` |
| Unit 2 — graphical dungeon language | Unit 1 | **merged** to `main` | 721 app tests, analyzer, corrective COR/TTC/CRF, Pixel_10 AVD and greyscale pass | on `main` at `06a8b9f`/`7cd32f2`; cold-charcoal continuous material, warm clipped light, strict no-geometry-leak fog |
| Unit 3 — crawl interaction reboot | Unit 2 | **merged** to `main` | 736 app tests, analyzer, review pass; deferred AVD/greyscale discharged by the combined Unit 3 + Unit 4 device gate | merged at `4164741`; map-first melee; favorites + overflow |
| Unit 4 — turn timeline + duplicate identity | Unit 3 | **merged** to `main` | final tree `dart format` 19 files/0 changed, analyzer clean, full app 765 tests; combined Unit 3 + Unit 4 colour/greyscale gate on `emulator-5554` | merged by PR #13 `650fa7c` and PR #14 `15e737a`; code `0d27a18` |
| Unit 5 — log drawer | Unit 3 | **merged** to `main` | 797 app tests, `dart format` 0 changed, analyzer clean; integrated acceptance review ACCEPT WITH FINDINGS, all must-fix corrected; full criterion 12 colour + greyscale device gate on `emulator-5554` | merged by PR #15 at `55a226d`; `0bf6da1` is an ancestor; contract: `units/unit-5/CONTRACT.md` |
| Unit 6 — character / spells / pack | Unit 3 | **merged** to `main` | 789 app tests, `dart format` 0 changed, analyzer clean; integrated acceptance review ACCEPT; Medium_Phone colour/greyscale device gate | merged by PR #16 at `319d945` (code `89927ef`); contract: `units/unit-6/CONTRACT.md` |
| Unit 7 — town + rooms + heroes | Unit 6 | **accepted**; awaiting integration | 816 app tests, `dart format` 99 files 0 changed, analyzer clean; acceptance review ACCEPT WITH FINDINGS, all taken findings corrected; `Medium_Phone` device gate with greyscale twins | branch `residuum-visual-reboot-7` at `cb8fcbc`; contract: `units/unit-7/CONTRACT.md` |
| Unit 8 — world + theme parity | Unit 7 | pending | final accessibility + device-size pass | Sea-Cave/Keep material identity |
| Unit 9 — crawl HUD chrome | Unit 8 | pending | own colour/greyscale device pass | depth header, labelled HP/Mana bars, icon control chips |

Recon locks the execution order: **1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9**.
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
  composition, room-background ratios, and the full non-dungeon icon language
  are **deferred to the post-Unit-8 art pass**, not blockers for Unit 7: the
  Unit 7 contract delivers town atmosphere as typographic and procedural
  treatment and adds no asset surface.
- Where do the leftover crawl HUD chrome items (depth header, labelled HP/Mana
  bars, icon control chips) land — Unit 8, or a new Unit 9?
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

### Unit 5 acceptance receipt

- 2026-09-14 — **Unit 5 is accepted** on `residuum-visual-reboot-5` at `0bf6da1`
  (code `3a78971` → `36aa0d5` → `7f93bc9`, correction `0bf6da1`) and
  **published with user approval as
  [PR #15](https://github.com/fiatcode-gh/residuum-rpg/pull/15)** at `cf27196`.
  All four CI gates pass: `gates (app)`, `gates (content)`, `gates (core)` and
  GitGuardian. **Merge remains user-owned and has not happened.** The contract
  commit `864aa6e` was briefly committed on local `main`; at the user's
  direction local `main` was rewound to `origin/main` (`15e737a`) so the commit
  lives only on the unit branch and enters `main` through the PR. That is the
  same route Unit 4's contract and recon took. Nothing was lost — the commit
  stayed reachable from `residuum-visual-reboot-5` throughout, and only a branch
  pointer moved.
- 2026-09-14 — Correction to this ledger's own record: Unit 4's PR #13 **and**
  #14 were already merged to `main` (`650fa7c`, `15e737a`) before this session
  began, and Unit 5's base `864aa6e` descends from both. The RESUME text saying
  Unit 4's merge "has not happened" was stale and was repeated once in this
  session before being checked. Merge state is cheap to verify with
  `git merge-base --is-ancestor`; verify it rather than quoting the pointer.
- Final tree: `dart format --output=none --set-exit-if-changed lib test` reports
  94 files, 0 changed; `flutter analyze` reports no issues; the full
  `packages/app` suite passes 797 tests. Run by the architect at `0bf6da1`. Only
  `.flow/` documents changed afterwards, so that proof still describes the code.
- The integrated `flow-acceptance-reviewer` pass returned ACCEPT WITH FINDINGS
  with one must-fix (F1) and five optional items; F1–F5 were all corrected in one
  round. F1 was real: the test claiming criterion 5's headline behavior ran
  against a one-line log where `maxScrollExtent == 0`, so `_maybeJumpToNewest`
  could have been deleted outright without failing. It is now seeded with 60
  lines and asserts the appended row lies inside the viewport; its Red is sharp
  (0 widgets found).
- **Device gate finding, and the lesson worth keeping.** `LogCategory.moved`
  shipped as `↕` (U+2195). On the phone target Android resolved that codepoint
  through the colour emoji font: a blue-cyan box at saturation 0.51
  (`rgb(65,117,134)`) that ignored the row's `style.color`. Two violations at
  once — hue carried part of the category, and the mark lost the newest/older
  value contrast. The codepoint was swapped to `⇅` (U+21C5); the shape
  vocabulary was never in question. Re-measured after the fix: no coloured pixel
  in the mark column, and the mark takes its row's colour exactly, older
  `rgb(138,145,158)` and newest `rgb(230,234,240)`.
  **No widget test can catch this class of defect** — the test font resolves
  every codepoint and `find.text` matches regardless of emoji fallback. Only a
  device gate sees it. U+2B65 was also probed and is tofu on this target.
- Criterion 12 is fully discharged in colour and greyscale, in
  `.flow/evidence/visual-reboot/unit-5-device/` with a `-greyscale.png` twin of
  every frame: peek above the controls on a one-line log, multi-line peek,
  half and full extents overlaying a live map, composition restored after
  collapse, follow held at newest, follow broken with the viewport held and
  `↓ 4 new` reporting an exact count, the affordance returning to newest, the
  full combat glyph column, the death overlay, and a road encounter's one-line
  log. One frame carries eight categories at once — `⇅ ◎ ✕ ← → † ■ ◆` — all
  monochrome and mutually legible in greyscale, with `←` on `claws you` and `→`
  on `You hit`, and Unit 4's `rat¹`/`rat²` identity carried into the sentences.
  The `■` / `◆` pair the review flagged as the narrowest silhouette gap reads as
  two shapes at true phone density.
- The inert death handle was proven, not asserted: `ev-death-drawer-collapsed`
  and `ev-death-handle-inert` are **pixel-identical below the status bar**
  (0 of 7,484,400 subpixels differ), so tapping the handle while dead changes
  nothing.
- Device scenes were sourced deterministically rather than by hunting:
  `buildFloor(1, worldSeed: 752, visit: 1)` puts two giant rats within a few
  steps of `heroSpawn`, and `roadSeed(travelSeedFor(10), day: 1)` rolls 11
  against danger 15 so the first Stonebridge → Crypt departure meets a fight.
  Death was reached honestly by waiting beside a dire wolf, 20 → 0. No fixture,
  no bent generation, no save edit, no code change.
- Device save hygiene: `save.json` and `save-previous.json` were copied off the
  device before the session and restored afterwards; both verify SHA-256
  identical to the pre-session backup (`18995c4a…`, `8909f70c…`). The
  on-device saves were deliberately cleared mid-session for seed control and
  restored from those host-side backups, which were never written to.
- Host note: the AVD on this machine is now `Medium_Phone` (Android 17,
  1080x2400), not the `Pixel_10` earlier units used. It segfaults on launch from
  a tool shell (`qemu-system-x86_64-headless`, exit 139, no error line, KVM
  healthy); the user launched it and it then ran fine for the whole session.

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

### Unit 6

- 2026-09-15 — Unit 6 source recon completed at `55a226d`, after PR #15
  merged. The two current long pages duplicate stats, spells, worn gear,
  carried items, materials, and skills; their item rows are not cosmetic:
  crawl dispatches drink/read/wear/drop, town dispatches wear/read/take-off.
  The user settled the information architecture: Character is a concise
  overview with Gear, Spells, Skills, and Pack routes; Spells is read-only and
  crawl casting remains exclusively on the exhaustive Unit 3 shelf/overflow;
  Pack filters only All, Weapons, Armour, Potions, Books, and Materials as
  transient presentation state. `units/unit-6/{recon,CONTRACT}.md` are the
  authority. No production code changed.

- 2026-09-15 — Unit 6 execution plan accepted at source base `55a226d`.
  `PLAN.md` and its two fresh-executor tasks pass the integrated planning gate:
  COR/TTC/CRF PASS; SEC skip because this is local Flutter presentation with no
  new trust boundary. The graph is `01-filtered-crawl-pack` then
  `02-town-character-and-routes`, then Main formatter/analyzer/full-suite,
  scope/review, and device gates. The shared `PackContents` seam is deliberately
  the sole cross-task interface; it retains local filter state across bloc
  rebuilds and resets on route disposal. First implementation task is ready.

### Unit 6 acceptance receipt

- 2026-09-15 — **Unit 6 is accepted locally** on
  `residuum-visual-reboot-6`, with `55a226d` as its source base. It is committed
  locally as `89927ef` and open as
  [PR #16](https://github.com/fiatcode-gh/residuum-rpg/pull/16); no merge or
  other remote action is authorized. The crawl long Pack is replaced by
  `CrawlPackScreen`/shared `PackContents`; town Character is an overview that
  routes to Gear, read-only Spells, Skills, and town Pack. Core, content,
  saves, dependencies, and generated paths remain untouched.
- The independent acceptance review returned **ACCEPT**: COR, TTC, and CRF
  passed; SEC was skipped because no trust boundary changed. Its selected-chip
  accessibility observation was corrected before device evidence: the active
  ChoiceChip remains selected **and enabled**, and tapping it is a local
  no-op. Its stale known-spell ownership dartdoc observation was also
  corrected. The optional route-specific ordering-test observation is recorded
  as accepted risk, not a behavior defect: shared ordering owners and existing
  tests cover the current contract.
- Fresh final app evidence from `packages/app`: `dart format
  --set-exit-if-changed --output=none lib test` checked 97 files with 0
  changes; `flutter analyze` found no issues; `flutter test` passed **789
  tests**. The correction's focused semantic proof passed 18 Pack tests and
  asserts the selected filter is both selected and enabled while the game and
  log object identities remain unchanged.
- Current-phone evidence is in
  `.flow/evidence/visual-reboot/unit-6-device/`. `Medium_Phone` (Android 17,
  1080x2400) shows the compact Character overview, Gear, Spells, Skills, town
  Pack, and crawl Pack in normal colour and greyscale. Every locked filter was
  exercised on the corrected crawl Pack; `ev-corrected-crawl-pack-all*` and
  `ev-corrected-crawl-pack-books*` show the selected check mark, label, and
  position remaining legible in greyscale. The captured hero had no learned
  spell, so device evidence shows the honest empty grimoire while the full
  widget suite proves nonempty spell-row facts and read-only behavior.
- Filter navigation was shown not to spend a turn: after opening Pack,
  selecting Books, and returning, the cropped app frames are pixel-identical
  (`magick compare -metric AE`: `0 (0)`) in
  `ev-filter-no-turn-{before,after}-app.png`. Both device save slots were
  copied before install and restored after capture. Their final SHA-256 values
  exactly match the backups: `save.json` `18995c4…b46d3` and
  `save-previous.json` `8909f70c…a9b11`.

### Unit 6 integration and epic state correction

- 2026-09-15 — **Unit 6 merged.** PR #16 is MERGED at `319d945` with code
  `89927ef`; the branch is gone and `main` is clean and in sync with
  `origin/main`. Checked at the same time: PRs #13 `650fa7c`, #14 `15e737a`,
  #15 `55a226d` are all MERGED, and Units 1–2 sit on `main` directly at
  `5f8db47` / `06a8b9f` / `7cd32f2`. **Units 1–6 are therefore all on `main`.**
  The epic status table's earlier "interrupted acceptance" row for Unit 4 and
  "accepted locally; uncommitted" row for Unit 6 were stale and are corrected
  above. Verify merge state at the forge before repeating a merge claim from
  this file.

### Unit 7 opening

- 2026-09-15 — **Unit 7 recon** (`agent://TownRoomsScout`,
  `agent://HeroesScout`) verified the town surface at source. Every town room
  is still original M3-era composition on `TownRoom` + `town_style.dart`;
  Units 1–6 rebooted the crawl and the Character information architecture only,
  and Unit 6's `CharacterScreen` renders inside the old town grammar. `TownBloc`
  carries 23 events and `TownViewState` projects every refusal computed in core
  (`smeltReason`, `brewReason`, `temperReason`, `wearReason`, `takeOffReason`,
  `readReason`). Recon correction 9 holds: Heroes is a `WorldScreen` action
  reading the live `SaveDocument`, not a town door and not a bloc consumer.
- 2026-09-15 — **The game is one active hero with a roster of alts, never a
  party.** Each `SavedHero` owns its profile, suspended run, world whereabouts,
  and merchant visit; deleting the last hero is a replacement write because the
  roster is never empty. Nothing in the reboot may imply party play.
- 2026-09-15 — **Unit 7 contract drafted** at `units/unit-7/CONTRACT.md`,
  awaiting explicit user approval. Its own locked position, pending that
  approval: no static art, no `assets/` declaration, no portrait slot, and no
  icon family in this unit — town atmosphere is typographic and procedural
  only, and the art bible stays deferred to the post-Unit-8 art pass already
  agreed with the user. Marks stay text codepoints and every new one is read on
  device before acceptance.
- 2026-09-15 — **The user approved the Unit 7 contract as written.** That
  approval covers the WHAT/boundary/acceptance in `units/unit-7/CONTRACT.md`,
  including its no-static-art lock. It authorizes planning only; local
  implementation needs separate approval of the execution-grade plan.
- 2026-09-15 — **The leftover crawl HUD chrome becomes Unit 9**, after Unit 8,
  by the user's decision. Unit 8 stays focused on world and theme parity, and
  the depth header, labelled HP/Mana bars, and icon control chips get their own
  colour/greyscale device pass rather than riding a broader final unit.

### Unit 7 planning and execution shape

- 2026-09-15 — **The execution-grade plan is written and approved by the
  user**: `units/unit-7/PLAN.md` plus four briefs under `units/unit-7/
  plan-tasks/`. Planner receipt: `agent://Unit7Planner`. Implementation is
  authorized within that envelope only; publication remains user-owned.
- 2026-09-15 — Work happens on `residuum-visual-reboot-7`, branched from `main`
  at `319d945`. The contract and plan ride the unit branch as `105dea2`, the
  same way Unit 5's contract commit reached `main` through its PR.
- 2026-09-15 — **The user chose to parallelize tasks 02–04** after task 01.
  Task 01 rewrites the shared grammar, so it runs alone and non-isolated;
  02 (counter rooms), 03 (crafting rooms) and 04 (Heroes) are file-disjoint and
  read-only on `town_style.dart`/`town_screen.dart`, so they run concurrently in
  isolated workspaces off the committed task-01 grammar. The known cost of that
  choice is three isolated checkouts merging back over a just-rewritten
  `town_style.dart`; Main owns the integrated broad gates afterwards.
- 2026-09-15 — Plan decisions worth carrying past this unit: **no new mark
  codepoint is introduced anywhere in Unit 7** (a structural answer to the
  Unit 5 colour-emoji trap rather than a test for it), and `Heading`,
  `NothingHere`, `ItemRow`, `MaterialRows`, `CountStepper` and `Notice` are
  **frozen** because `world_screen.dart` (Unit 8) and the crawl Pack share
  them. Reshaping is confined to the town-only primitives: `Purse`, `TownRoom`,
  the new `Commit`, and the deletion of `MaterialsPanel`.

### Unit 7 task 01 receipt

- 2026-09-15 — **Task 01 (town grammar + shell) is landed and verified**, on
  `residuum-visual-reboot-7` as `45b44e8`. Worker receipt:
  `agent://U7T01Shell`. `town_style.dart` now exports `markColumn`,
  `placeName`, `roomName` and `Commit`; `Purse` lost its card; `TownRoom`
  renders its title in the body; `MaterialsPanel` is deleted and both former
  call sites use `Heading('Materials')` + `MaterialRows`. The shell has a place
  header, the status block, and seven keyed doors with purpose lines.
- Architect-run evidence at that commit, from `packages/app`: full `flutter
  test` **795 passing** (789 before the unit, plus 8 new town-shell tests, less
  2 migrated out of `craft_rooms_test.dart`), `dart format
  --set-exit-if-changed` 11 files 0 changed, `flutter analyze` no issues.
- **A real regression was caught by the architect's broad gate that the worker's
  focused run could not see.** Three tavern tests in `world_screen_test.dart`
  tap `find.text('Tavern')` without scrolling. The rebooted shell is taller, so
  on the 800x600 test surface the fifth door now sits at y=608 — below the fold
  — and the tap derived an off-screen offset. The worker never ran that file
  because its brief named it another task's gate.
- **Decision: the design stands and the call sites scroll.** The contract
  already says the last door stays reachable on a 600-pixel-tall screen by
  scrolling rather than clipping, and the shell's scroll skeleton exists for
  exactly that. Those three taps encoded a stale geometry assumption, not a
  behavioural contract. `test/support/world_nav.dart` gained
  `openTownDoor(tester, label)`, which ensures the door is visible before
  tapping; only the three tavern call sites migrated to it. Every assertion in
  those tests is unchanged.
- **Trap for Unit 8 and Unit 9:** the town door column is now within about 8
  pixels of the 600-pixel fold. Any further growth pushes door 5 and below out
  of reach of an unscrolled tap, and roughly a dozen town-door taps across
  `boot_wiring_test.dart`, `roster_session_test.dart`, `suspend_door_test.dart`,
  `character_screen_test.dart` and `world_screen_test.dart` still tap directly.
  Prefer `openTownDoor` in new tests.

### Unit 7 tasks 02–04 and integration checkpoint

- 2026-09-15 — **Tasks 02, 03 and 04 ran concurrently in isolated workspaces**
  off `45b44e8` and are integrated as `340980c`. Receipts:
  `agent://U7T02Counter`, `agent://U7T03Craft`, `agent://U7T04Heroes`.
  02 restructured the bank into two zones and retired `Heading('Gold')`, moved
  the tavern's notice under `Purse`, and added `tavern_screen_test.dart` — the
  tavern's first test file ever. 03 moved both crafting notices up, gave each
  room exactly one material block, and put `_TemperRow` on `markColumn` so the
  bench aligns with the material rows. 04 keyed every roster row
  (`Key('roster-hero-$id')`) so a hero's facts are attributable to that hero,
  and quietened the per-row delete to a `TextButton`.
- **OMP did not auto-apply any of the three isolated patches**; all three were
  merged by the architect with `git apply --include='packages/*'`. The full
  patches also carried the architect's own uncommitted `.flow` edits, which
  conflicted — restricting the apply to `packages/` is the working recipe, and
  the next epic should expect the same.
- **Architect-run integrated evidence at `340980c`**, from `packages/app`: full
  `flutter test` **815 passing** (795 after task 01), `dart format
  --set-exit-if-changed` over `lib` and `test` 99 files 0 changed, `flutter
  analyze` no issues. Scope audit: zero changes under `packages/core` and
  `packages/content`, and zero changes under `packages/app/lib` outside
  `lib/town/`.
- `merchant_screen.dart` is the one room task 02 did not edit, reporting that
  its structure already matched the brief. That judgement is referred to the
  acceptance review rather than taken on trust.

### Unit 7 acceptance review

- 2026-09-15 — The integrated acceptance review returned **ACCEPT WITH
  FINDINGS** at `340980c`: one must-fix and five optional. Full text:
  `agent://U7Acceptance`. It independently re-ran analyze, format and the 815
  tests, diffed every displayed string literal in the nine town library files
  base versus head, audited every added non-ASCII codepoint, and hashed
  `roster_screen.dart`'s sealed-type region to prove `RosterChoice` is
  byte-identical.
- **Correction to this ledger's own evidence claim (the must-fix, F1).** Unit 7
  did **not** leave every regression gate untouched. Besides the nine library
  files it also edited `packages/app/test/support/world_nav.dart` (new
  `openTownDoor` helper) and `packages/app/test/widget/world_screen_test.dart`
  (three tavern call sites). The edit is correct and behaviour-preserving — it
  unpinned a composition assumption, not a behaviour — but the plan's TTC
  argument rested on that suite passing unedited, and it did not. The
  architect's own scope audit missed it because the audit covered
  `packages/app/lib` only. Audit `packages/app/test` too, next time.
- Findings taken in one correction round (`agent://U7Corrections`): route the
  eight remaining raw town-door taps through `openTownDoor` (F2); give the
  roster `Delete` and forge `Temper` texts an explicit town colour so one rule
  governs button-borne text (F3); add the missing end-to-end proof that the
  forge shows its blacksmith level-up sentence (F4); close the two new suites'
  leaked blocs with `addTearDown` (F5).
- **Finding F6 is deliberately not fixed here and is Unit 8 input.**
  `character_screen.dart` is the room behind door 4 and is still built from
  four full-width `FilledButton` slabs plus a `Container` with
  `BoxDecoration(color: panel)` — the card-and-slab furniture Unit 7 stripped
  from `Purse`, `MaterialsPanel` and the doors. The plan froze every Unit 6
  route, which gave it the rebooted scaffold but not a rebooted interior. After
  Unit 7 it is the last old-grammar surface in the town.

### Greyscale evidence rule, narrowed

- 2026-09-15 — **The blanket "every device frame gets a greyscale twin" rule is
  retired at the user's decision.** From Unit 7's device gate onward, colour
  capture is the default and a greyscale twin is required only for a frame that
  introduces a **new mark codepoint** or a **non-neutral colour**.
- The reasoning is specific, not a relaxation of the accessibility contract,
  which is unchanged: no state may be carried by hue alone. The town palette
  has no hue in it — `ink` `0xFFE6EAF0`, `dim` `0xFF8A919E`, `panel`
  `0xFF15181F`, `rule` `0xFF2A2E38` are all neutral greys — so desaturating a
  town frame is close to a no-op, which is why every Unit 6 twin matched its
  original. The twin earns nothing on a hueless screen.
- Where it does earn its keep is colour the project did not author:
  **font fallback** (Unit 5's `↕` U+2195 rendered through Android's colour
  emoji font and ignored the row's text colour) and **theme defaults** (this
  unit's finding F3: roster `Delete` and forge `Temper` let Material's primary
  decide their text colour). Neither is a palette mistake, so palette care
  cannot catch either.
- **Unit 9 (crawl HUD chrome) is the expected trigger to reinstate twins** —
  labelled HP/Mana bars are exactly where a hue-only state first appears. Unit 8
  needs them for any frame touching the Sea-Cave and Ruined Keep palettes, which
  are not neutral.
- Unit 7's own gate was already capturing twins when this was decided and was
  allowed to finish; its evidence set is therefore the last complete twinned set
  in this epic.

### Unit 7 device gate and acceptance

- 2026-09-15 — **Unit 7 is accepted.** The device gate passed at `cb8fcbc` on
  `emulator-5554` (`Medium_Phone`, Android 17, 1080x2400, about 411x914 logical).
  Verifier receipt: `agent://U7Device`. Evidence is
  `.flow/evidence/visual-reboot/unit-7-device/`: nine frames — town shell, the
  Alchemist-fold frame, Merchant, Bank, Inn, Tavern, Forge, Alchemist, Heroes —
  each with a greyscale twin.
- **The forge alignment question is answered quantitatively, not by eye.** The
  item-name text of the three material rows begins at x=128/130/129 and the
  bench's `Common Rusty Sword` at x=129 — within about 2 pixels, which is
  antialiasing. `markColumn` does what it was introduced to do.
- **The fold question is answered for this device only.** All seven doors sit on
  screen at rest with room to spare, and a scroll gesture produced no movement.
  This AVD is far taller than the 600-pixel reference the plan worried about, so
  the tightest case was *not* exercised. The widget-level 600-pixel reachability
  walk in `town_shell_test.dart` remains the only proof for that geometry.
- **No hue-only state.** Every dead control stays distinguishable by lightness
  once desaturated and is additionally backed by its own refusal sentence. The
  only codepoint Unit 7 introduced anywhere is U+2014, and it renders as a
  proper dash — no tofu, no colour-emoji resolution.
- Both device save slots were backed up before install and verified by the
  architect after all driving: `save.json`
  `18995c4ac55edc6dfb23b0b13b0e09cf2d79747e6028964b0187a2a4182b46d3` and
  `save-previous.json`
  `8909f70c64c633c1678b42ff90390216be2e76c29e3ff2f482219d470f8a9b11`, identical
  to the pre-session backup.
- **Device trap worth carrying:** the saves live in `app_flutter/`, not
  `files/`, and the installed package is `com.example.residuum_app`. A
  `run-as … cat files/save.json` silently returns an *error string*, and hashing
  that yields a plausible-looking but meaningless digest — two slots appearing to
  share one hash is the tell. Read `app_flutter/save.json`.
- **Observation for the art pass, not a Unit 7 defect:** the town's only hue is
  Material's default seed on `FilledButton` — the lilac `Bank`, `Ask 15` and
  `New hero` controls. Unit 7 stripped the slabs from the doors, so those
  remaining filled controls are now the one coloured element on an otherwise
  neutral screen. It carries no meaning by itself and reads in greyscale, but it
  is unauthored colour and the town has no theme of its own.