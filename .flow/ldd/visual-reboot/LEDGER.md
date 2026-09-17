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

- **Units 1–9 are accepted and present on `main`.** Verified at source on
  2026-09-16: PR #13 `650fa7c`, #14 `15e737a`, #15 `55a226d`, #16 `319d945`,
  #17 `f322d78`, #18 `2b0e0a4` and #19 `4bf865c` are MERGED. `main` is at
  `4bf865c` (Unit 9 code `92fd4aa`, `feat: rebuild crawl status`), in sync with
  `origin/main`.
- **Unit 8 is formally closed.** Its deferred criterion 9 device gate passed,
  including the user's physical TalkBack traversal to both below-fold
  world-diagram nodes and the Sea-Cave/Ruined Keep phone-density readings.
- **Unit 9 is complete and merged**, closing the locked order 1 → … → 9.
- **Unit 10 (authored art integration) is open at intake.** An external
  ChatGPT LDD bundle proposing it is under `units/unit-10/`, and 31 approved
  PNG assets are untracked at `packages/app/assets/visual/`. Neither carries
  local authorization; the unit contract is not yet approved.

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
| Unit 7 — town rooms + Heroes | Unit 6 | **merged** to `main` | 816 app tests, `dart format` 99 files/0 changed, analyzer clean; integrated acceptance review ACCEPT WITH FINDINGS, must-fix and F2–F5 corrected in `cb8fcbc`; `Medium_Phone` device gate passed with both save slots verified byte-identical | merged by PR #17 at `f322d78` (code `cb8fcbc`); contract: `units/unit-7/CONTRACT.md` |
| Unit 8 — world + theme parity | Unit 7 | **merged** to `main`; device gate open | 826 app tests, `dart format` 100 files/0 changed, analyzer clean; acceptance review rejected then closed on all four findings, scoped closure review ACCEPT WITH FINDINGS with zero must-fix; **acceptance criterion 9 device gate deferred and still outstanding** | merged by PR #18 at `2b0e0a4` (code `c85c7f9` + correction `54d6b4b`); contract: `units/unit-8/CONTRACT.md`; plan: `units/unit-8/PLAN.md` |
| Unit 9 — crawl HUD chrome | Unit 8 | **merged** to `main` | 834 app tests, `dart format` 101 files/0 changed, analyzer clean; integrated acceptance review PASS with zero findings; `Medium_Phone` colour/greyscale device gate across five status scenes, measured one-row (52 px) map cost, both save slots restored byte-identically | merged by PR #19 at `4bf865c` (code `92fd4aa`); contract: `units/unit-9/CONTRACT.md`; plan: `units/unit-9/PLAN.md`; two-row `crawl_status.dart`; red/blue meter fills rejected, icon control chips deferred |
| Unit 10 — authored art integration | Unit 9 | **open at intake** | not yet contracted | external bundle `units/unit-10/` (evidence only); assets `packages/app/assets/visual/` |

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
- The post-Unit-8 art pass (portraits, bulk static art, room-background
  ratios, the full non-dungeon icon language) still has no owning unit and is
  not part of Unit 9.
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

### Unit 7 integration and Unit 8 opening

- 2026-09-15 — The user reported PR #17 merged. Fresh `origin/main` verification
  found `f322d78` (`Merge pull request #17 from
  fiatcode-gh/residuum-visual-reboot-7`) at `HEAD`, with Unit 7's four commits
  in its first-parent history and a clean checkout. Unit 7 is integrated.
- 2026-09-15 — The user selected a **spatial route diagram** for the fixed
  five-node world and **route-linked regional material** for road encounters.
  The resulting Unit 8 contract is drafted at `units/unit-8/CONTRACT.md`.
  Its WHAT, boundaries, and acceptance criteria require explicit approval
  before planning; no implementation is authorized.
- 2026-09-15 — **The user approved the Unit 8 contract as written.** That
  approval covers the fixed five-node route diagram, discovery boundary,
  route-linked material, and preservation contract in
  `units/unit-8/CONTRACT.md`. It authorizes execution planning only.
- 2026-09-15 — `Unit8Planner` returned **READY** after producing
  `units/unit-8/PLAN.md` and three fresh-executor briefs: fixed world diagram,
  deterministic regional materials, then explicit route-lifetime theme wiring.
  Main inspected the artifacts against source seams and direct callsites. The
  plan's gate is COR/TTC/CRF PASS; SEC SKIP for no trust boundary. It awaits
  explicit execution approval; no production implementation is authorized.
- 2026-09-15 — **The user approved Unit 8's execution-grade plan.** This
  authorizes local implementation in its three task capsules only. The next
  action is creating the non-`main` `residuum-visual-reboot-8` checkout from
  `f322d78` and dispatching task 01; no remote publication is authorized.
- 2026-09-15 — **Task 01 is accepted.** It added the fixed 430-pixel,
  discovery-safe world diagram and migrated world navigation tests on
  `residuum-visual-reboot-8`, without touching forbidden production paths or
  LDD records. Main independently inspected the patch, corrected four plan
  deviations in a fresh bounded capsule, and ran
  `flutter test test/widget/world_screen_test.dart`: **49 passing**. Task 02
  may now begin.
- 2026-09-15 — **User decision:** defer Unit 8's planned AVD/device-size and
  greyscale evidence to the next unit session. This changes only the timing of
  that acceptance evidence; Task 02 and Task 03 implementation, focused proof,
  and final code review remain required before this session closes.
- 2026-09-15 — **Task 02 is accepted.** It added explicit, deterministic
  Crypt, Sea-Cave, Ruined Keep, and lowland material contexts plus isolated
  renderer proofs, without touching Task 01, core/content, or architect
  records. Main inspected the strict mappings and material invariants, then ran
  the exact focused renderer suite: **69 passing**. A seven-line app-Dartdoc
  convention correction followed; its source-only diff cannot affect that
  behavior evidence. Task 03 may now begin.
- 2026-09-15 — **Task 03 is accepted.** `GameScreen` now receives immutable
  regional context only at the session construction boundary. Main inspected
  the required cutover and navigation-output contract, then ran its exact
  focused integration suite: **197 passing**. A two-line app-test Dartdoc
  correction followed; it is source-only and leaves that behavioral proof
  applicable. Tasks 01–03 are complete; integrated acceptance review and
  repository gates remain before local completion.
- 2026-09-15 — **User direction:** pause Unit 8 immediately after the
  independent acceptance-review receipt is recorded. Do not begin repository
  gates or corrections in this session. Before closing, create one local commit
  and push `residuum-visual-reboot-8`; the user explicitly authorized that
  stakeholder-visible branch update. A fresh session will choose its own
  inference provider and resume from the review outcome; the device gate was
  already deferred.
- 2026-09-15 — **Independent acceptance review: REJECT.** The review accepts
  the fixed graph, strict mapping, deterministic materials, context lifetime,
  and focused proof as supported, but found four correction items:
  - **U8-AR-1 (Important):** enabled diagram nodes expose no semantic tap
    action because their child gesture semantics are excluded.
  - **U8-AR-2 (Important):** the route/crawl output tests reconstruct a
    `MaterialComponent` from the live plan instead of rendering the live
    component, leaving adoption/cache behavior unproven.
  - **U8-AR-3 (Minor):** the Task 02 brief asks for `MaterialMark.pattern`
    Dartdoc, which conflicts with the repository rule forbidding new app
    Dartdoc. Resolve the plan/convention contradiction before changing code.
  - **U8-AR-4 (Minor):** grit, speck, crack, and edge passes are not all
    clipped to their owning cell rect, contrary to the locked containment
    invariant.
  The user directed a pause after recording this receipt. Commit and push the
  feature branch as the authorized handoff; do not correct findings or run
  repository gates until the fresh session resumes.

### Unit 8 correction round

- 2026-09-15 — **Resumed at `c85c7f9` on `residuum-visual-reboot-8`**, clean and
  in sync with `origin/residuum-visual-reboot-8`. The previous session's agent
  receipts did not survive the session, so all four findings were re-verified
  directly at source before any correction was authorized. Each one reproduces:
  `_nodeSlot` wraps its `GestureDetector` in `ExcludeSemantics` under a
  `Semantics(button: true)` that declares no `onTap`;
  `_navigationMaterialBytes` builds a fresh `MaterialComponent(material.plan)`
  for its `actual` bytes; `_drawCellDecoration` clips the pattern pass only.
- 2026-09-15 — **U8-AR-3 is resolved in favour of the repository convention,
  not the brief.** `AGENTS.md` allows Dartdoc only on the public API of `core`
  and `content`, and `MaterialMark` is app API, so the Task 02 requirement to
  "document it as 0..1 deterministic phase" was the defect. The 0..1 phase
  constraint now lives in the brief and in the determinism tests instead. Both
  Unit 8 briefs are corrected in place (`02-regional-materials.md` requirement
  and latitude clause, `01-world-route-diagram.md` latitude clause); the shipped
  source already complies, because `MaterialMark.pattern` carries no Dartdoc and
  `dungeon_scene_material.dart`'s Dartdoc count fell from 50 to 37 over the
  unit. No production edit was needed to close this finding.
- 2026-09-15 — **Finding triage, recorded because it changes what the evidence
  can claim.** Only U8-AR-1 is a live defect with an observable Red: a screen
  reader cannot activate a reachable node. U8-AR-2 and U8-AR-4 are
  proof-strength and invariant-conformance items. Every decoration geometry is
  already inset inside its cell — grit reaches `0.8·cell + 1.2`, the speck
  centre `0.35·cell + 10` with radius `1.6`, and the rounded edge cap ends
  `0.1` inside the rect — so the missing clip leaks no pixel today and the
  worker was told explicitly not to manufacture a Red for either.
- 2026-09-15 — One in-plan correction capsule is dispatched to a fresh plan
  executor (`U8Corrections`) covering U8-AR-1, U8-AR-2 and U8-AR-4 across
  `world_route_diagram.dart`, `world_screen_test.dart`,
  `dungeon_scene_material.dart` and `dungeon_material_paint_test.dart`. It runs
  non-isolated on the unit branch with every git state-mutating command
  withheld, because the architect's `.flow` records are deliberately dirty.
- 2026-09-15 — **The correction round landed as expected.** Worker receipt:
  `agent://U8Corrections`, uncommitted on the unit branch. U8-AR-1 had a real
  Red first: `tester.semantics.tap` on the reachable Crypt node threw
  `StateError: The given node does not support SemanticsAction.tap`, and the
  one-line `onTap: enabled ? () => onDestination(node) : null` on the outer
  `Semantics` closes it with no label, key, centre, size or style moved.
  U8-AR-2 is now honest: `_navigationMaterialBytes` renders the live scene
  `MaterialComponent` through a new `_renderComponentBytes`, while
  `expected`/`wrong` stay plan-derived. U8-AR-4 wraps all five decoration
  passes in one `save`/`clipRect(cell.rect)`/`restore` and returns early for an
  undecorated cell, so `render` still allocates nothing.
- 2026-09-15 — **The worker proved the AR-4 no-Red claim instead of asserting
  it**: it snapshotted `_drawCellDecoration`'s exact bytes, temporarily reverted
  the clip, ran the new four-palette containment test against the unclipped
  renderer, saw it pass, then restored byte-identical content and re-ran. That
  is the right shape for a conformance fix with no observable delta.
- 2026-09-15 — **Dartdoc scope is narrowed further, deliberately.** U8-AR-3's
  rule is *no new Dartdoc on app library API*. Documented private test
  fixtures are a different thing and already landed on `main`:
  `world_screen_test.dart` carried 17 such lines at `f322d78`. The two new
  helper-doc lines explaining which render helper is the expectation side are
  therefore in-convention and are not a finding.
- 2026-09-15 — **The broad gate found a real Unit 8 regression that no focused
  gate could see, for the second epic running.** Full `flutter test` from
  `packages/app`: **825 tests, 1 failure** —
  `disabled_controls_test.dart` "a dead Walk on the world screen says there is
  no road when there is none" pins `find.text('no road runs there from here')`.
  It is **Task 01's** regression, not the correction round's: Task 01 deleted the
  world menu that rendered core's `TravelRefusal` as visible prose, and every
  Unit 8 gate until now was a named focused file (49-world, 69-material,
  197-integration), so the suite ran whole for the first time at this point.
  `dart format --set-exit-if-changed` over `lib` and `test` is 100 files 0
  changed and `flutter analyze` reports no issues.
- 2026-09-15 — **Decision: the diagram's word replaces the sentence, and the
  test migrates.** A destination with no road is now a disabled node reading
  `NO ROAD FROM HERE`, which contract criterion 1 and the Task 01 brief already
  locked; boundary 8 requires the replaced menu composition to be deleted
  outright. `TravelRefusal('no road runs there from here')` still exists in
  `packages/core/lib/src/world/travel.dart` and stays covered by
  `core/test/world/travel_test.dart`; it simply has no app surface, because only
  a reachable node can be selected. The player still learns the fact, so this is
  a composition change the approved plan authorized, not a lost refusal.
  Migration dispatched to `U8DeadNode`.
- 2026-09-15 — **Process correction for the rest of this epic:** a focused-file
  gate is not a unit gate. Run the full `packages/app` suite at the end of every
  task, not only at unit close, and audit `packages/app/test` as well as
  `packages/app/lib` (the Unit 7 F1 lesson, now paid for twice).
- 2026-09-15 — **The migration landed and the repository gates are green**, all
  architect-run from `packages/app` over the uncommitted worktree: full
  `flutter test` **826 passing**, `dart format --set-exit-if-changed` over `lib`
  and `test` 100 files 0 changed, `flutter analyze` no issues. Worker receipt:
  `agent://U8DeadNode`. The group is now `a dead destination on the world map`
  and asserts `NO ROAD FROM HERE` appears exactly once from the crypt while the
  old sentence is gone, and that a fresh hero at Stonebridge sees no roadless
  node and exactly one `HERE`. Its first `// assert` comment claimed the crypt
  node "is reachable" when the hero is standing on it; that is corrected to the
  node reading `HERE`.
- 2026-09-15 — **Scope audit over both trees this time.** Zero changes under
  `packages/core` and `packages/content`, for the whole unit against `f322d78`
  and for this session. This session touched five files, all under
  `packages/app`: `lib/world/world_route_diagram.dart`,
  `lib/game/dungeon_scene_material.dart`, `test/widget/world_screen_test.dart`,
  `test/game/dungeon_material_paint_test.dart`, and
  `test/widget/disabled_controls_test.dart`.
- Test count trail for this unit: 816 at Unit 7's close, 825 with Unit 8's
  correction round (of which one failed), 826 green after the migration split
  the roadless-node assertion in two.

### Unit 8 acceptance closure

- 2026-09-15 — **The scoped closure review returned ACCEPT WITH FINDINGS, zero
  must-fix**, over the uncommitted correction round. Full text:
  `agent://U8Closure`. It ran every mutation probe in a disposable `rsync` copy
  and left the repository byte-identical to the state it reviewed.
- **U8-AR-1 is closed and Red-backed.** Reverting only
  `world_route_diagram.dart` to `c85c7f9` fails the new test with `Bad state:
  The given node does not support SemanticsAction.tap`. The reviewer's semantics
  dump of a fully discovered world is the useful artifact: `Town Northgate.
  Reachable.` and `Dungeon The Crypt. Reachable.` carry tap; `No road from
  here.`, `Here.`, all three `Travel in progress.` nodes and all three
  `Unknown location. Not discovered.` slots do not. One node per label, so no
  duplicate announcement.
- **U8-AR-2 is closed as "renders the live component", and the wording matters
  (U8-CR-3).** Instrumenting `adopt` past its identity guard produced exactly
  two calls in the whole of `world_screen_test.dart`, neither in a test that
  calls `_navigationMaterialBytes`. So those six tests prove the live scene
  component's own output matches the plan-derived expectation — strictly
  stronger than the reconstruction they replaced — but **adoption/cache
  behaviour is owned by `dungeon_material_paint_test.dart`**, whose `refresh
  cached material light only for a new projection` test is killed by a mutant
  that strips `_rebuildRenderPlan()` from `adopt`, while all 52 world-screen
  tests survive it. Do not claim the navigation tests prove adoption.
- **U8-AR-4 is closed as a containment conformance pin, Green-before by
  design (U8-CR-4).** The reviewer hashed raw RGBA of a full arena per palette
  and of 40 maximal-decoration renders (5 pattern phases x 4 palettes x wall/
  floor) against the pre-clip source: bit-identical. The clip changes no pixel
  today. The new test keeps real teeth anyway, because `_drawCellBase` and
  `_drawVisibleLight` sit outside any per-cell clip, so a mask or base-rect
  regression still turns the ring non-void, and a future decoration pass added
  outside the `save`/`restore` block would be caught.
- **Residual risk accepted:** the clip makes leakage unobservable, so the
  geometry-inset reasoning recorded above is no longer independently checked by
  any test. That is the intended meaning of the invariant — contain first — but
  it means a future escaping decoration will be silently clipped rather than
  caught.
- **Pre-existing Task 01 geometry the device gate must confirm:** at the default
  800x600 test surface the semantics dump shows `Dungeon The Crypt. Reachable.`
  and `Town Stonebridge. Here.` flagged `isHidden`, because the 430-pixel
  diagram sits inside `world_screen.dart`'s `ListView` and those nodes fall
  below the viewport. The flag is identical at `c85c7f9`, so the correction
  round did not cause it, and standard viewport semantics restore the nodes
  after a scroll. Whether a real screen reader reaches the below-fold nodes is
  exactly what the deferred device gate is for.
- 2026-09-15 — Optional craft findings U8-CR-1 (one activation closure instead
  of two identical ones), U8-CR-2 (decide decoration presence once in
  `_PreparedMaterialCell` instead of five null tests per cell per frame) and the
  duplicated label regex half of U8-CR-5 are folded into the same change through
  `U8Craft`. The reviewer's suggested test split in U8-CR-5 is **declined**: it
  would duplicate the one `ensureSemantics` handle for no proof gained, and the
  reviewer agreed it is not materially better.
- 2026-09-15 — **The craft round is in** (`agent://U8Craft`): one `activate`
  local feeds both `GestureDetector.onTap` and `Semantics.onTap`;
  `_PreparedMaterialCell` carries `hasDecoration`, computed once per plan, and
  `_drawCellDecoration` opens with `if (!cell.hasDecoration) return;`; the
  Crypt label regex is one `cryptLabel` local. Two architect corrections
  followed: the worker had deleted the blank line before the field list, and its
  first `hasSpeck` re-derived `paint.speck && mark.speck` a third time — the
  exact hand-sync hazard U8-CR-2 existed to remove — so that conjunction is now
  one `speck` local feeding `speckCenter`, `speckPaint` and `hasDecoration`.
- 2026-09-15 — **Unit 8 is locally complete and accepted on code.** Final
  architect-run gates from `packages/app` over the uncommitted worktree: full
  `flutter test` **826 passing**, `dart format --set-exit-if-changed` over `lib`
  and `test` 100 files 0 changed, `flutter analyze` no issues. Scope audit: zero
  changes under `packages/core` and `packages/content`; five files touched this
  session, all under `packages/app` (`lib/world/world_route_diagram.dart`,
  `lib/game/dungeon_scene_material.dart`, `test/widget/world_screen_test.dart`,
  `test/game/dungeon_material_paint_test.dart`,
  `test/widget/disabled_controls_test.dart`).
- **The one criterion still open is acceptance criterion 9, the device gate**,
  deferred by explicit user decision: `Medium_Phone` colour evidence for a
  fresh/discovery-gated world, a fully discovered world, an active journey, the
  Sea-Cave and Ruined Keep delves, and road fights on the lowland, Sea-Cave and
  Ruined Keep routes, with greyscale twins for every non-neutral regional frame.
  Two specific questions are waiting for it: whether a real screen reader
  reaches the below-fold diagram nodes, and whether the Sea-Cave strata and
  Ruined Keep fracture strokes read at phone density. Back up both device save
  slots first and read `app_flutter/save.json`, never `files/save.json`.
- 2026-09-15 — **The user authorized the commit, the push and the PR.** The
  session's work is one commit, `54d6b4b` `fix: close unit eight review
  findings`, pushed to `origin/residuum-visual-reboot-8`, and PR **#18**
  `feat: reboot the world map and regional material` is open against `main`.
  Its body records the deferred device evidence explicitly, so a reviewer is not
  led to believe the unit was validated on hardware.
- Today's journal entry for the unit is logged under `[[Residuum]]` in
  `journals/2026_09_15.md` with the device gate carried as a fresh TODO.

### Unit 8 integration

- 2026-09-16 — **PR #18 is MERGED.** Verified at source after `git fetch`:
  `main` is `2b0e0a4` (`Merge pull request #18 from
  fiatcode-gh/residuum-visual-reboot-8`), clean and in sync with `origin/main`,
  carrying `c85c7f9` plus the correction `54d6b4b` and the docs checkpoint
  `bb1d572`. The previous RESUME snapshot predated the merge and said to
  integrate it; the epic status table also still called Unit 8 paused and had no
  Unit 7 row at all. Both are corrected.
- **Unit 8's acceptance criterion 9 remains open after integration.** It is the
  only criterion outstanding for that unit.

### Unit 9 opening

- 2026-09-16 — **Unit 9 recon is complete and recorded** at
  `units/unit-9/recon.md`, from three read-only scouts (`agent://CrawlHudScout`,
  `agent://CrawlStateScout`, `agent://GrammarScout`) with every load-bearing
  reference re-read by the architect. `CrawlHudScout`'s own line numbers drift by
  roughly twenty lines and were not trusted directly.
- **Correction to the epic's own framing: Unit 9 is a presentation unit, not a
  missing-information unit.** `_HitPoints` (`game_screen.dart:197-329`) already
  carries every fact handoff section 3.2 requires — dungeon name, depth/deepest,
  HP, mana where meaningful, Ward when present — but as one
  `FittedBox(scaleDown)` string beside a 56-pixel unlabelled bar. The gap Unit 9
  closes is that the facts are crammed into a shrinking line and Mana has no bar.
- **The mock's shape was already built once and beaten by hardware.**
  `game_screen.dart:246-258` records a stretched bar plus three fixed labels that
  fitted only until the dungeon was named, then overflowed a phone by sixty-four
  pixels, invisible to widget tests because their surface is wider than a phone.
  `:569-593` records two more device passes that killed ellipsised control
  labels. This is why Unit 9 keeps scale-down discipline while adopting the
  mock's structure.
- **Unit 9 is app-only.** Every value the rows need is already on
  `GameViewState` (`game_bloc.dart:328, 336, 339, 436, 495, 500, 503, 506, 575`)
  and the node name is already reachable the way `_whereabouts` reaches it.
  `packages/core` and `packages/content` must not change.
- 2026-09-16 — **Locked by the user: the two-row split with text controls
  kept.** A header row (place name left, `depth / deepest` right, battle glyph
  and word between) plus one resource row of two labelled monochrome meters
  replaces the single status line. **The mock's red HP and blue Mana fills are
  rejected** — first hue-only resource state in the epic, and the author is
  deuteranomalous. **The mock's icon control chips are deferred** to the
  post-Unit-8 art pass: only two Material icons ship in the whole app
  (`Icons.center_focus_strong`, `Icons.close`), neither carries game meaning,
  the control labels carry live counts, and one label is the data-driven
  `node!.verb`.
- The meters reuse the grammar already shipped in `_SkillRow`
  (`skills_screen.dart:38-60`): word label, numbers, monochrome
  `LinearProgressIndicator` on the `rule` track. No second style module.
- 2026-09-16 — **Locked by the user: Unit 8's criterion 9 folds into Unit 9's
  device pass.** One `Medium_Phone` session covers both units' frames; Unit 8
  stays formally open until it passes. Unit 8's two waiting questions — the
  below-fold world-diagram nodes under a real screen reader, and whether the
  Sea-Cave strata and Ruined Keep fracture strokes read at phone density — are
  carried into Unit 9's acceptance criterion 9.
- **Trap recorded for planning: fourteen tests across five files pin the
  concatenated `<name> — depth <n>/<n>` string** —
  `test/widget/world_screen_test.dart` (7), `hud_depth_test.dart` (3),
  `suspend_door_test.dart` (2), `roster_session_test.dart` (1),
  `boot_wiring_test.dart` (1) — and `battle_characterization_test.dart:115-148`
  pins `Engaged n`/`Watched n` through `textContaining` on the same line.
  `world_screen_test.dart:1752-1754` asserts one `line` contains `20 / 20`,
  `Steady` and `The Sea-Cave — depth 1/4` together. Splitting the row breaks all
  of them; the ones pinning composition rather than behaviour are rewritten, not
  re-pinned to new text.
- **The map is `Expanded` (`game_screen.dart:76`), so new chrome never
  overflows the crawl — it silently shrinks the play surface.** The contract caps
  the cost at one extra text row, measured on device, against the handoff's
  map-first rule.
- The contract is drafted at `units/unit-9/CONTRACT.md` and **awaits explicit
  user approval**; planning and implementation are separate authorizations.
- 2026-09-16 — **The user approved the Unit 9 contract as the WHAT.**
  `units/unit-9/CONTRACT.md` is the governing authority for the unit. Planning
  is dispatched to a dedicated `flow-planner`; implementation remains
  unauthorized until the user approves the execution-grade plan.

### Unit 9 planning

- 2026-09-16 — **The execution-grade plan is written and architect-validated**:
  `units/unit-9/PLAN.md` plus the single brief
  `units/unit-9/plan-tasks/01-two-row-crawl-status.md`, by `agent://U9Planner`
  against base `2b0e0a4`. Quality gate COR/TTC/CRF PASS, SEC SKIP (local
  presentation over in-process state; no new trust boundary). The planner left
  `packages/` untouched: `git status` still shows only the architect-owned
  `LEDGER.md`, `RESUME.md` and untracked `units/unit-9/`.
- **One task, deliberately.** `_line`'s deletion and the 25 dependent assertion
  sites are one Red→Green cluster; any partition would ship a throwaway third
  composition and leave `flutter test` red between halves.
- **Architecture locked:** new `packages/app/lib/game/crawl_status.dart` owns
  both rows, public `CrawlStatus({state, dungeon})` plus `hpMeterKey`,
  `manaMeterKey`, `depthPairKey`; `game_screen.dart` loses 133 lines and gains
  one call at `:124`; the file imports no `flutter_bloc` and the node id arrives
  as a constructor input rather than a second bloc read. `_condition` and
  `_battleWord` survive verbatim, `_BattleGlyph` moves, and `_line`, `_magic`
  and `_whereabouts` are deleted with no formatter, fallback or compatibility
  getter left behind.
- **Scale boundary locked per cell, never per row**, because a `Row` of
  `Expanded` bars cannot live inside a `FittedBox` and row-wide scaling would
  shrink the live numbers to pay for the static proper noun. Overflow is
  structural-impossible rather than arithmetically unlikely, and no `Text` on
  either row sets `overflow`/`maxLines`/`softWrap`.
- **Recon trap 3 is half superseded, verified at source.**
  `test/support/phone.dart:9-13` gives a real 411.4 x 923.4 surface and
  `world_screen_test.dart:1665-1689` already uses it with
  `tester.takeException()`. Layout arithmetic and `RenderFlex` overflow are
  widget-provable; font metrics, scaled-cell legibility and viewport height are
  device-only. Criteria 5 and 9 stay device-only and are not proxied.
- **The migration sweep found eleven sites beyond the recon's fourteen**, all
  re-read by the architect: three `The road` pins
  (`world_screen_test.dart:1022/1051/1080`), six `textContaining('Depth')`
  negatives that go vacuous once nothing renders `Depth`
  (`world_screen_test.dart:1023/1052/1081`, `boot_wiring_test.dart:145/161`,
  `suspend_door_test.dart:189`), and two battle-word pins worth tightening.
  `world_screen_test.dart:1746-1754` is named as a pure composition pin and
  rewritten to four independent finders with the `.data` extraction deleted.
- **The ward rule is safe at source:** `warded` is written only by
  `SpellKind.ward` (`packages/core/lib/src/engine/step.dart:302-303`), so a
  warded hero with no known spell is unreachable; the plan makes finding
  otherwise an escalation rather than a layout decision.
- Two deliberate small visual deltas the device gate will see: the crawl's local
  `#DDE1E7` literal is retired in favour of `ink` `#E6EAF0`, and the numeric
  grammar is unified to `HP 20 / 20` / `Mana 3 / 5` (no test pins `Mana 3/5`).
- Residual risks accepted into implementation/device evidence: the two-meter
  worst case scales text cells to about 0.8 (~11-px glyph); the ~18-px height
  delta is computed from default monospace metrics; the harness font is not the
  device's; and `RenderParagraph.getMaxIntrinsicWidth` is the one unusual
  assertion, whose weakening must be reported rather than silently dropped.
- The plan **awaits explicit user approval**. No branch exists; implementation
  stays unauthorized.
- 2026-09-16 — **The user approved the execution-grade plan.** Local
  implementation is authorized within the approved plan envelope only;
  publication and integration remain separately gated. The feature checkout
  `residuum-visual-reboot-9` is branched from `2b0e0a4`, carrying the
  architect-owned dirty LDD records forward, and task 01 is dispatched to one
  fresh non-isolated `flow-plan-executor`.

### Unit 9 task 01 receipt

- 2026-09-16 — **Task 01 is landed and architect-verified** on
  `residuum-visual-reboot-9`, uncommitted. Worker receipt:
  `agent://U9Task01`. No seam differed from the plan, so nothing was escalated.
- **Architect-run integrated gate from `packages/app`**, independent of the
  worker's own run: `dart format --set-exit-if-changed --output=none lib test`
  101 files 0 changed, `flutter analyze` no issues, full `flutter test`
  **834 passing** (826 at Unit 8's close, plus eleven new focused tests less the
  three the renamed `hud_depth_test.dart` carried).
- **Scope audit clean.** `git diff --stat` touches only
  `packages/app/lib/game/game_screen.dart` (916 → 750 lines) and six test files,
  with `packages/app/lib/game/crawl_status.dart` untracked and new;
  `hud_depth_test.dart` → `crawl_status_test.dart` is recorded as a rename.
  Zero changes under `packages/core` and `packages/content`.
- **Patch inspected at source, not merely reported.** `crawl_status.dart`
  matches the plan: per-cell `FittedBox(scaleDown)` with no `overflow`/
  `maxLines`/`softWrap` anywhere, the depth-pair `SizedBox` absent rather than
  empty on the road, the Mana cell gated structurally on
  `knownSpells.isNotEmpty`, the ward note only inside that cell, monochrome
  `rule`/`ink` meters at `minHeight: 8`, and `ceiling`/`fraction`/`shown`
  carried over verbatim from the deleted `_HitPoints`. The new suite is
  behavioural: both gates have a positive and a negative case and the two
  meters are proved to read different values through
  `isNot(hpIndicator.value)`.
- One deviation from the brief, harmless and reported by the worker: the
  now-unused `package:residuum_content/content.dart` import was dropped from
  `game_screen.dart` because `residuumWorld`/`NodeId` use moved wholly into the
  new file; `flutter analyze` caught it. The brief's instruction to add a
  `GameScreen` import to `suspend_door_test.dart` was a no-op — the file
  already imported it for `doneControl`/`doneAtTheBottom`.
- The no-squeeze `RenderParagraph`/`getMaxIntrinsicWidth` proof landed
  unmodified; no fallback and no weakened proof were reported.
- One integrated `flow-acceptance-reviewer` pass is dispatched
  (`agent://U9Acceptance`). It is a dependency barrier: no device evidence
  begins until it closes.
- 2026-09-16 — **Integrated acceptance review PASS**:
  `agent://U9AcceptanceResume` re-reviewed the actual uncommitted patch,
  including untracked `packages/app/lib/game/crawl_status.dart`, against the
  approved contract and plan. It found no Critical or Important defect and made
  no tree mutation. The reviewer independently confirmed every status fact,
  deletion of the old formatter/composition, monochrome meters, migrated
  behavioural tests, height-budget structure and app-only scope. The
  `RenderParagraph` no-squeeze check is meaningful alongside static inspection
  and `tester.takeException()`, but device-font legibility and physical height
  remain device-only as planned. No correction round is required; the accepted
  integrated format/analyze/test proof remains fresh because the review was
  read-only.
- **The acceptance-review barrier is closed.** Before the next device/emulator
  action, write the durable device checkpoint, ask the user to start
  `Medium_Phone`, then dispatch the contracted evidence-verifier capsules.
- 2026-09-16 — **Device-evidence recovery checkpoint written before any device
  action.** HEAD is `2b0e0a49acbf76c7394335cc07a624ca6ead5937` on
  `residuum-visual-reboot-9`, with no commit or remote branch. The dirty tree is
  exactly the Unit 9 app patch (`game_screen.dart`, six changed tests, renamed
  `hud_depth_test.dart` → `crawl_status_test.dart`, and untracked
  `crawl_status.dart`) plus architect-owned `LEDGER.md`, `RESUME.md` and
  untracked `units/unit-9/`; `core` and `content` remain unchanged. Accepted
  evidence is the exact-tree format/analyze/full-suite gate (834 passing) and
  the read-only acceptance-review PASS. No emulator, ADB, install, screenshot
  or manual-device action has occurred in this controller session.
- **Remaining device acceptance:** all Unit 9 criterion 9 frames — fresh
  no-spell crawl; warded casting fight; critical health; bottom floor with
  underfoot and five controls; road fight; plus Unit 8's fresh/discovery-gated
  world, discovered world, journey, Sea-Cave and Ruined Keep delves, and each
  regional road fight — with required greyscale twins, screen-reader reachability
  and Sea-Cave/Keep readability answers. Before any install, both
  `app_flutter/save.json` slots must be copied aside and SHA-256-proved restored
  byte-identical afterward. `Medium_Phone` is not started; it must be
  user-started because tool-shell launch segfaults. Next action: ask the user
  to start it, then dispatch bounded evidence capsules.
- 2026-09-16 — **Device capsule `U9-crawl-status` returned partial evidence**:
  `agent://U9CrawlDeviceEvidence` built and installed the current debug APK on
  user-started `Medium_Phone` (`emulator-5554`, Android 17, 1080×2400, APK
  SHA-256 `224add…ea1a9b`). Its report and colour/greyscale artifacts are under
  `.flow/evidence/visual-reboot/unit-9-device/`. Fresh no-spell and
  critical/engaged scenes prove the dungeon header/depth, labelled HP, condition,
  no-spell Mana gate, Engaged/Watched glyph language, monochrome greyscale
  reading and no observed clipping. This verifier restored both original device
  save slots exactly: `save.json` SHA-256 `18995c…2b46d3` MATCH and
  `save-previous.json` SHA-256 `8909f7…f8a9b11` MATCH; the app is stopped and
  temporary device files are removed.
- **Residual Unit 9 evidence is explicit, not waived:** casting/warded Mana,
  bottom-floor underfoot with five controls, road fight, their required
  greyscale coverage and a precise same-device height comparison remain UNKNOWN.
  The preserved save had no spellbook, and no sanctioned deterministic fixture
  was available in that capsule. Route these to a fresh verifier using a
  temporary valid save or safe real-app staging, with the same backup/restore
  obligation. Unit 8's world/regional evidence remains untouched.
- 2026-09-16 — **Device capsule `U9-residual-crawl` closed every residual Unit
  9 status-row fact**: `agent://U9ResidualDeviceEvidence` generated
  codec-valid temporary fixtures, installed baseline/current APKs on the same
  `Medium_Phone`, and retained its report, frames, fixture hashes and backups in
  `.flow/evidence/visual-reboot/unit-9-device/residual-crawl-report.txt`.
  Colour/greyscale evidence shows Ward/Mana in an engaged casting fight, the
  bottom-floor underfoot/five-control scene, and the road's absent depth pair.
  The same warded fixture measured the current scene background as exactly
  **52 px**, one status text row, shorter than `2b0e0a4` (within the contract
  cap). Both slots were restored again with byte-for-byte SHA-256 MATCH:
  `save.json` `18995c…2b46d3`; `save-previous.json` `8909f7…f8a9b11`.
- **Scope disposition — inherited five-control ellipsis, no Unit 9 correction.**
  The bottom-frame `Drink (…)` control is visibly truncated in colour and
  greyscale, but the identical codec fixture on the same device and
  `2b0e0a4` baseline shows the same truncation. It is not introduced by the
  status change; invariant 6's frozen control surface is therefore preserved.
  Unit 9's literal no-ellipsis rule applies to its two status rows, which the
  current and baseline comparison proves complete. Record the inherited control
  defect for a separately authorized controls unit; do not expand Unit 9.
- **Unit 9's own device conditions are accepted.** Its folded criterion 9 still
  cannot close the unit until fresh Unit 8 world/regional evidence answers the
  remaining inherited frames, greyscale checks and real screen-reader question.
- 2026-09-16 — **Device capsule `U8-world-diagram` returned accepted world
  evidence** at `.flow/evidence/visual-reboot/unit-8-device/`: fresh world
  shows three inert non-leaking `?` nodes; full world shows all five labelled
  nodes, routes, costs and danger; active journey shows its road/context and
  `Walk on`; colour/greyscale twins preserve the word/shape/value reading.
  Selecting the Crypt displayed confirmation before spending and cancel kept
  Day 4 with no journey. Both app save slots restored byte-identically MATCH
  (`18995c…2b46d3` and `8909f7…f8a9b11`), and baseline Android accessibility
  settings were restored.
- **The real-screen-reader question remains UNKNOWN, not passed by proxy.**
  TalkBack 17 and TTS were enabled and the service reached RESIDUUM, Heroes,
  Enter Stonebridge and a travel-dialog title, but injected ADB input cannot
  drive real touch-exploration/virtual focus to the below-fold graph nodes.
  UIAutomator evidence is corroboration only. A physical user TalkBack gesture
  is needed to answer this criterion after the regional evidence closes.
- 2026-09-16 — **Device capsule `U8-regional-delves` accepted the delve half
  of Unit 8 criterion 9.** The Sea-Cave's water-worn horizontal tide strata and
  the Ruined Keep's squared ashlar/V-fracture treatment both read beyond hue in
  colour and greyscale, with actors, stairs, grid, controls and light boundary
  legible. The verifier also exercised a legal Sea-Cave move/pan without
  revealing unknown geometry. Its codec-valid fixtures, frames and report are
  under `.flow/evidence/visual-reboot/unit-8-device/`; both user save slots
  restored byte-identically MATCH (`18995c…2b46d3`, `8909f7…f8a9b11`), and the
  app/device staging paths are clean.
- 2026-09-16 — **Device capsule `U8-regional-roads` accepted the road half of
  Unit 8 criterion 9.** Lowland's neutral angled wear, Sea-Cave's tide strata
  and Ruined Keep's ashlar/fractures are distinct beyond hue and remain so in
  greyscale. All road fights retain `THE ROAD`, the exact edge-escape sentence,
  no depth/stairs, and the existing Drink/Pack/Wait control set. The verifier
  reached an outer edge, pressed Flee, and observed the resumed road finish at
  the Crypt on Day 5. Fixtures/frames/report live under
  `.flow/evidence/visual-reboot/unit-8-device/`; both device save slots restored
  byte-identically MATCH (`18995c…2b46d3`, `8909f7…f8a9b11`).
- **All automated Unit 8/9 device frames are accepted.** The only remaining
  acceptance criterion is the deliberately non-proxied real TalkBack traversal
  to below-fold world nodes. A fresh evidence capsule must stage the full-world
  screen and real service, then wait for the user's physical gesture outcome
  before it restores state.
- 2026-09-16 — **Physical TalkBack device evidence PASS**:
  `agent://U8TalkBackManualEvidence` staged a codec-valid fully discovered world
  with TalkBack 17 and Google TTS active. The user physically swiped right and
  heard both below-fold node controls exactly: `DUNGEON The Sea-Cave. NO ROAD
  FROM HERE.` and `DUNGEON The Ruined Keep. NO ROAD FROM HERE.` The report and
  ready/post-traversal artifacts are in
  `.flow/evidence/visual-reboot/unit-8-device/u8-talkback-physical-report.txt`.
  Both save slots restored byte-identically MATCH (`18995c…2b46d3`,
  `8909f7…f8a9b11`); every changed Android accessibility/TTS/input/font setting
  returned to its recorded baseline, TalkBack/app are stopped, and staging paths
  are absent.
- **Unit 8 criterion 9 is accepted and Unit 8 is formally closed.** Fresh,
  discovered and journey world frames; Sea-Cave/Keep delves; lowland/Sea-Cave/
  Keep road fights; required greyscale evidence; save restoration; and
  below-fold real screen-reader reachability are all now evidenced.
- **Unit 9 criterion 9 is consequently accepted and Unit 9 is complete.**
  Combined evidence proves every two-row status case, its greyscale reading and
  exact one-row height cost; Unit 8's folded frames are now closed. The only
  inherited observation is the unchanged base/current five-control `Drink (…)`
  truncation, deliberately outside Unit 9's frozen control scope.
- **Final local acceptance:** the source tree is still only the approved Unit 9
  app patch plus architect-owned LDD records; `core`/`content` remain untouched.
  The format/analyze/full-suite proof (101 formatted files, analyzer clean, 834
  passing) and acceptance-review PASS remain fresh because all later changes
  were evidence/LDD records only. No commit, push, pull request or other remote
  action has been performed or authorized. Next gate is the user's integration
  decision.

### Unit 9 integration

- 2026-09-16 — **Unit 9 is merged.** The user integrated the accepted branch;
  PR #19 merged at `4bf865c` with code `92fd4aa`. `main` is in sync with
  `origin/main` and the worktree carries no app changes. The locked order
  1 → … → 9 is complete.

### Unit 10 intake — authored art integration

- 2026-09-16 — **An external ChatGPT LDD bundle proposing Unit 10 arrived**
  together with 31 approved authored PNG assets. Both are evidence; neither
  carries authorization.
- **The bundle fails the shipped planning-handoff validator** (`exit 2`): its
  `artifacts` paths are repository-root-relative where schema v1 requires
  bundle-root-relative paths. It was **not repaired**. It is reconciled here as
  unvalidated external evidence, and its internal cross-references
  (`proposed-units/unit-10.md`, `asset-inventory.md`) do not match its own
  filenames either. `design_status` and `implementation_strategy` are both
  `partial`; no execution-grade plan was supplied.
- **Freshness is confirmed at source.** The bundle's `observed_ref` `92fd4aa`
  is an ancestor of `main`, and `git diff 92fd4aa..HEAD -- packages/` is empty,
  so every source claim it made was checked against an unchanged app tree.
- **Restructuring, authorized by the user in-session.** Authored masters moved
  `packages/app/assets/visual/` → `art/visual-reboot/`: they are 1254 x 1254
  production masters, and leaving them there would have pointed the app's first
  `assets:` declaration at 48.1 MB of source art with bundle provenance text
  mixed into a runtime asset root. The external bundle moved
  `units/unit-10/` → `external/unit-10-chatgpt-handoff/`, matching the
  `external/unit-2-chatgpt-handoff/` precedent; `units/unit-10/` now holds only
  architect-owned records. Nothing under `packages/` was touched. All 31 PNGs
  plus `MANIFEST.txt` re-verified byte-identical to `SHA256SUMS.txt` after the
  move (the checksum file's `wave1/`/`wave2/` prefixes are flattened by the
  extraction; suffix matching is unambiguous).
- **Recon is recorded at `units/unit-10/recon.md`** from three bounded scouts
  plus architect verification. The bundle's three renderer claims and its town
  and control claims are confirmed, with four corrections that change scope:
  1. **Size is a contract constraint.** One master decodes to 6.0 MB; the set is
     ~186 MB resident and 48.1 MB on disk. Shipped assets must be derived.
     Environment masters are square, so every placement crops deliberately.
  2. **There are two towns.** Only Stonebridge has authored environment art, and
     no town gate exists in any screen today.
  3. **Forge and Tavern exist in both towns**, so ungated room art appears in
     Northgate.
  4. **The crawl control row is not a safe icon seam.** Equal `Expanded` cells
     already ellipsise `Drink (…)` at five controls; an icon makes it strictly
     worse. The battle shelf is a `Wrap` and is the one safe icon surface.
     Melee is a map tap and back is the platform `AppBar` affordance across
     fourteen files, so both assets stay unused.
- **The draft contract is written** at `units/unit-10/CONTRACT.md` with three
  decisions requested at the approval gate: whether the masters are tracked in
  git; whether the crawl control row stays out of Unit 10; and whether room
  illustrations appear in Northgate. Implementation stays unauthorized until the
  contract is approved and an execution-grade plan is approved after it.
- 2026-09-16 — **The user approved the Unit 10 contract** and resolved all
  three decisions, amending scope in the process:
  - **D1 — Git LFS.** `art/visual-reboot/**/*.png` is tracked through a new root
    `.gitattributes`; `git-lfs 3.7.1` is installed and `origin` is GitHub. The
    derived shipped assets stay ordinary git objects so a checkout without LFS
    still builds. This is the repository's first LFS configuration.
  - **D2 — the crawl control row is in scope.** Unit 10 re-lays-out the row so
    icon-plus-label fits without ellipsis at 411.4 dp, retiring the inherited
    device-proved `Drink (…)` truncation. The control set stays frozen: no
    control is added, removed, renamed, reordered or rewired. This reopens a
    geometry frozen since Unit 3 by the user's explicit decision, and pulls the
    `pack`/`ascend`/`descend` icons into the unit.
  - **D3 — room art is room-typed.** Forge and Tavern illustrations appear in
    both towns; only the Stonebridge environment is gated on
    `TownViewState.town == stonebridge`.
- Approval authorizes **execution-grade planning only**. One dedicated
  `flow-planner` is dispatched to own plan recon and writing; Main owns plan
  acceptance. No production-writing worker may run until the plan is separately
  approved, and publication stays separately gated after that.

### Unit 10 planning

- 2026-09-16 — **The execution-grade plan is written and architect-validated**:
  `units/unit-10/PLAN.md` (1321 lines) plus four briefs under
  `units/unit-10/plan-tasks/`, by `agent://U10Planner`. Dependency shape is
  strictly sequential 01 → 02 → 03 → 04, then Main's integrated gate, then one
  `flow-acceptance-reviewer` barrier, then five device capsules.
- **The planner left the tree untouched**: `git status` shows only the
  architect-owned LDD records, the untracked `art/` masters and no `tool/` or
  `packages/app/assets/`; derivation experiments went to `/tmp/u10`.
- **Architect rechecks at source, not taken on report:**
  - The plan **corrects `recon.md`'s renderer seam, and the correction is
    right**. `MaterialComponent.render` (`dungeon_scene_material.dart:278-286`)
    fills every cell base, then `_drawVisibleLight` clips an opaque
    `stoneLitColor(1) → stoneLitColor(0)` gradient to the visible mask and fills
    the bounds, so a visible cell's base is already overpainted. The authored
    pass therefore belongs **after** the light, not in `_drawCellBase`. Recon's
    seam claim is superseded.
  - The five-control worst density is closed at source: `gatherNodesOn`
    (`gathering.dart:129-135`) draws only from `Tile.floor` that is not the hero
    spawn, so a gather node and a flight of stairs cannot share a tile, and
    `canAscend`/`canDescend`/`canLeave` (`game_screen.dart:329-346`) contribute
    one control between them.
  - CI checks out without LFS (`.github/workflows/ci.yml:18`, plain
    `actions/checkout@v4`), so the masters arriving as pointers is harmless and
    criterion 2's no-LFS-build claim is structurally sound: nothing in the build
    reads `art/`, and the shipped assets are ordinary git objects.
- **Locked decisions of consequence:** one root LFS pattern for
  `art/visual-reboot/**/*.png`; a repo-root `tool/derive-visual-assets.sh`
  producing ~2.3 MB of shipped assets (environments cropped to 2.5:1 JPEG,
  576² high-passed greyscale material sheets re-centred on mean ~0.50, 144²
  overlays, 72² icons); one `lib/art/art_assets.dart` catalogue as the only
  file holding an asset path; a world-space mirror-tiled `ui.ImageShader` field
  rather than per-cell crops, which keeps Unit 2's continuous material and makes
  the non-seamless masters seam-free by construction; `BlendMode.softLight`
  against mid-grey sheets so the authored layer adds texture with **no net
  luminance shift**, leaving the light gradient owning brightness and the
  palette owning hue; overlays gated on the existing `MaterialMark` values so
  density and determinism are inherited; and an optional const-defaulted `art`
  parameter on `MaterialComponent` that leaves every existing pixel assertion
  valid. **Zero existing test files change.**
- **Residual risks accepted into device evidence:** the control row reaches two
  runs (~44 dp of map) at five controls; boot decodes ~14.7 MB before the first
  frame; multitone icons render untinted on the light M3 container; regional cue
  survival under added texture; `overlayOpacity` 0.55 and the eight-cell mirror
  period are device-tunable within stated bounds. Each has a named bounded
  correction, and reducing an accepted regional cue stays an escalation.
- The plan **awaits explicit user approval**. No branch exists; implementation
  stays unauthorized.
- 2026-09-16 — **The user approved the execution-grade plan as written**,
  explicitly accepting its two named tradeoffs: the control row reaching two
  runs (~44 dp of map) at five controls, and the ~14.7 MB boot decode before the
  first frame. Local implementation is authorized within the approved plan
  envelope only; publication and integration remain separately gated.
- The feature checkout **`residuum-visual-reboot-10`** is branched from
  `4bf865c`, carrying the architect-owned dirty LDD records and the untracked
  `art/` masters forward, and task 01 is dispatched to one fresh non-isolated
  `flow-plan-executor` (`agent://U10Task01`).

### Unit 10 task 01 receipt

- 2026-09-16 — **Task 01 (asset pipeline and catalogue) is landed and
  architect-verified** on `residuum-visual-reboot-10`, uncommitted. Worker
  receipt: `agent://U10Task01`. Nothing was escalated; the brief matched source
  everywhere.
- **Worker proof**: RED observed twice (undefined catalogue names, then 3/8
  failing on missing assets/declaration), then `dart format` clean on the four
  touched files, `flutter analyze` clean, full `flutter test` **842 passing**
  (834 at Unit 9's close plus exactly eight new focused tests), `pubspec.lock`
  untouched.
- **Architect rechecks at source**: 29 derived assets in three directories
  totalling 2.2 MB; all 31 masters still present under `art/`; `.gitattributes`
  carries exactly `art/visual-reboot/**/*.png filter=lfs diff=lfs merge=lfs
  -text`; `pubspec.yaml` declares the three shipped directories; `main.dart:27`
  calls `await warmUpArt()` **before** `runApp` and outside `guardedBoot`;
  `assets/visual` appears in `lib/` only inside `art_assets.dart`; the icon set
  is exactly the eight legal icons with **no `melee` and no `back`**.
- Worker-measured facts worth keeping: the six material-sheet means are
  0.49909-0.50544, all inside the 0.48-0.52 band the softLight design depends
  on; two script runs produced byte-identical SHA-256 sets, so derivation is
  idempotent; `git check-attr` confirms the masters filter through LFS while the
  shipped assets are `unspecified`.
- **Known gap carried to the device gate:** warm-up decodes six material sheets
  and twelve overlays and precaches three environment JPEGs synchronously before
  `runApp`, and no wall-clock cost was measured. Capsule B must time cold boot
  against `4bf865c`.
- Task 02 (environment illustrations) is dispatched to a fresh
  `flow-plan-executor` (`agent://U10Task02`).
- 2026-09-16 — **Task 02 escalated one plan defect and the architect authorized
  a bounded in-plan correction.** The plan's `Illustration.build` recipe omitted
  `excludeFromSemantics: true` from its `Image.asset(...)`, while the brief's
  test 6 asserts no `Semantics` descendant exists in the widget tree. Verified
  at source in the Flutter 3.47.2 SDK: `image.dart:1427-1433` wraps the result
  in `Semantics(container: semanticLabel != null, image: true, label: … ?? '')`
  whenever `!excludeFromSemantics`, so the assertion could never pass and the
  recipe was building an `image: true` node solely for the outer
  `ExcludeSemantics` to suppress. For art the contract calls decorative, not
  building the node is the correct behaviour, so the one-line flag was
  authorized and the test was left exactly as specified. Height, fit, radius,
  `errorBuilder`, the outer `ExcludeSemantics` and all three insertion points
  stay locked.

### Unit 10 task 02 receipt

- 2026-09-16 — **Task 02 (environment illustrations) is landed and
  architect-verified**, uncommitted. Worker receipt: `agent://U10Task02`. RED
  was observed on all six new tests before the production edits.
- **Worker proof**: focused five-file run 52/52, `dart format` clean,
  `flutter analyze` clean, full `flutter test` **848 passing** — 842 plus
  exactly six — with zero regressions.
- **Architect rechecks at source**: `lib/town/illustration.dart` has
  `ExcludeSemantics` outermost, `BoxFit.cover`, radius 2,
  `errorBuilder → SizedBox.expand()` and the authorized
  `excludeFromSemantics: true`; `town_screen.dart:86-91` gates the Stonebridge
  illustration with a structural `if (state.town == stonebridge)` — **the widget
  is absent for Northgate, not rendered falsy** — sitting between `Notice` and
  the `Spacer`; forge and tavern insert ungated at their first-`Heading` seam
  per D3. `git diff --stat -- packages/app/test` is empty, so **no existing test
  file was touched**, and the three load-bearing layout suites stay green.
- Measured at `onAPhone`: town illustration box exactly 140.0 dp, room boxes
  exactly 120.0 dp, asserted exactly rather than approximately.
- **Carried to the device gate:** whether 140/120 dp and the 2.5:1 crop
  composition read on hardware is unverified beyond the widget harness.
  TalkBack silence is now structural — no `Semantics` widget is built at all.
- Task 03 (authored dungeon materials) is dispatched to a fresh
  `flow-plan-executor` (`agent://U10Task03`), carrying the architect's source
  correction that the authored pass goes after the light, not in
  `_drawCellBase`.

### Unit 10 task 03 receipt

- 2026-09-16 — **Task 03 (authored dungeon materials) is landed and
  architect-verified**, uncommitted. Worker receipt: `agent://U10Task03`. RED was
  observed as missing-symbol compile failures in both new test files. Nothing
  was escalated.
- **Worker proof**: twelve new tests 12/12, the three existing dungeon suites
  52/52 unchanged, `dart format` 5 files 0 changed, `flutter analyze` clean,
  full `flutter test` **860 passing** — 848 plus exactly twelve — zero
  regressions, zero skips.
- **Architect rechecks at source**: `render()` is now bases →
  `_drawVisibleLight` → `_drawAuthoredMaterial` → decorations, so the authored
  pass sits **after** the light exactly as the plan's correction required;
  `_drawAuthoredMaterial` makes two clip-and-fill calls and nothing else; the
  `ui.ImageShader` with `TileMode.mirror` on both axes is built inside
  `_rebuildRenderPlan`, once per adoption, never per frame; the paint carries
  `BlendMode.softLight`; `materialPhase` is a thin wrapper over the existing
  `_unit01(_hash(...))` and **no `Random` is reachable anywhere in either
  file**; `MaterialComponent`'s `art` is an optional named parameter with a
  const default. `git diff --name-only -- packages/app/test` is empty, so the
  three pixel-level suites (1067, 621 and 860 lines) are genuinely unedited —
  which is the real proof that no authoritative fact moved.
- Criterion coverage worth keeping: remembered-flat and unknown-void re-proved
  **with art loaded**; road byte-equality with a fully populated `DungeonArt`
  versus `DungeonArt.none()`; determinism by byte-equality across renders and
  across a plan rebuilt from the same `GameState`; and no-double-exposure by a
  near-cell-brighter-than-far-cell check under a mean-0.502 two-tone sheet, so
  the radial light still owns brightness.
- Task 04 (icons and the crawl control row) is dispatched to a fresh
  `flow-plan-executor` (`agent://U10Task04`).

### Unit 10 task 04 receipt and the integrated gate

- 2026-09-16 — **Task 04 (icons and the crawl control row) is landed and
  architect-verified**, uncommitted. Worker receipt: `agent://U10Task04`. RED was
  observed for the right reason: the no-squeeze loop caught the squeezed
  paragraph on the road scene at **rendered 63.99 dp against intrinsic
  84.70 dp** before any production edit.
- **One narrowing, reported rather than hidden.** The brief's illustrative
  no-squeeze snippet scoped the `RenderParagraph` loop to the whole
  `controlsKey` column, which produced a false failure on the bottom-floor
  ending scene: the pre-existing `doneAtTheBottom` sentence row legitimately
  wraps to two lines at phone width, and a wrapped paragraph's laid-out width is
  necessarily below its unconstrained intrinsic width. The executor scoped the
  loop to the control row's own `Wrap`, which is the plan's stated intent. The
  sentence row is untouched by this unit — `git diff` shows zero hits for
  `doneAtTheBottom`.
- **Architect rechecks at source**: the diff converts `Row`/`Expanded` to
  `Wrap(spacing: 6, runSpacing: 4, alignment: center)` with every label, gate
  and dispatch preserved verbatim; icons appear on exactly `Drink`, `Pack`,
  `Wait`, `Ascend <` and `Descend >`; **no `maxLines`, `overflow:` or
  `softWrap` survives anywhere in `game_screen.dart`** — the inherited ellipsis
  defect is gone at the source, not merely hidden.
- Measured at `onAPhone`: the two five-control scenes take two runs (167.0 dp
  and 129.0 dp of chrome, the first including the pre-existing two-line
  sentence row) and the three-control stairs-down scene stays one run at
  56.0 dp — the approved D2 consequence, to be measured against `4bf865c` on
  device.
- **Main's integrated gate, run by the architect at this exact tree**:
  `dart format --set-exit-if-changed --output=none lib test` → **111 files, 0
  changed**; `flutter analyze` → **no issues**; full `flutter test` from
  `packages/app` → **869 passing** (834 at Unit 9's close plus exactly the 35
  planned new tests), zero regressions. `git status -- packages/core
  packages/content` is **empty**; `git diff --stat -- packages/app` is 9 files,
  346 insertions, 105 deletions, plus the untracked art, catalogue, illustration,
  action-icon, asset and tooling additions.
- One integrated `flow-acceptance-reviewer` pass is dispatched
  (`agent://U10Acceptance`). It is a **dependency barrier**: no device evidence
  begins until it closes.

### Unit 10 acceptance review

- 2026-09-16 — **Integrated acceptance review returned CHANGES with no Critical
  finding**: `agent://U10Acceptance` reviewed the whole uncommitted unit,
  including every untracked file, and made no tree mutation. It verified at
  source — not by trusting the new tests — that the four safety invariants hold
  **structurally**: unknown positions have no `MaterialCell` and so cannot enter
  any mask or paint; remembered cells are overlay-free on three independent
  grounds; `_drawVisibleLight` is byte-unchanged with the authored pass additive
  under its own clip; and no `Random`, `DateTime` or `.now(` exists anywhere in
  the new presentation code. It independently confirmed the base-tracked test
  files are byte-unchanged (55 tracked at base, zero modified, zero deleted),
  `core`/`content` empty, the LFS attributes both ways, and that the derive
  script skips the melee and back masters.
- **All three Important findings are on the verification side, and the architect
  accepted every one:**
  - **I1 — the unit's activation point has no proof and cannot fail loudly.**
    `warmUpArt` swallows every failure, and nothing in the 869-test suite calls
    it; the suite in fact pins the opposite, because the const
    `DungeonArt.none()` default is what keeps the untouched dungeon suites
    valid. Total activation failure would be indistinguishable from success and
    would have spent the entire five-capsule device gate proving the procedural
    renderer.
  - **I2 — the replace-not-add rule was named by a test that additive drawing
    would satisfy identically** (`isNot` on single pixels). Production is
    correct; the invariant was unguarded.
  - **I3 — the per-region phase test re-implemented `_texturePhase` in its own
    body and never called it**, so criterion 7's per-region claim had no test
    that could fail for the right reason.
- Minor findings accepted: `ActionIconImage` needs `excludeFromSemantics: true`
  and a dartdoc that stops claiming the opposite of what it does (the shelf has
  no outer `ExcludeSemantics`, so icon buttons currently merge an unlabelled
  `isImage` annotation); a comment sits in a function body; the 18 codecs are
  never disposed and warm-up awaits serially, which inflates the very cold-boot
  number capsule B must measure; two tests pin structure rather than behaviour;
  two import lists are unsorted.
- **Architect decisions on the open calls:** take the optional hardening —
  `WidgetsFlutterBinding.ensureInitialized()` as `main()`'s first line, one line
  beyond the plan envelope, because it removes an unfalsifiable binding question
  and also hardens the inherited `guardedBoot` path; and **replace** I3's test
  with a rendering assertion rather than deleting it. `warmUpArt` keeps its
  never-throw behaviour by design.
- One batched correction round is dispatched to a fresh `flow-plan-executor`
  (`agent://U10Corrections`). The device barrier stays closed until it lands and
  the affected proof is refreshed.

### Unit 10 correction round

- 2026-09-16 — **All eight findings are closed** by `agent://U10Corrections`,
  uncommitted, with nothing escalated.
- **Each rewritten proof was demonstrated to fail, not merely to pass.** The
  worker broke production temporarily and reverted: removing the `warmUpArt()`
  call fails I1's new test with `Expected: not null, Actual: <null>,
  cryptFloor`; making the crack ternary additive fails I2; hardcoding
  `_texturePhase`'s salts fails I3. **Architect-verified restoration at source**:
  `dungeon_scene_material.dart:545` again reads
  `crackGate && overlayImage == null`, and `_texturePhase` again derives both
  axes from `palette.themeSalt ^ 0x6666 / ^ 0x7777`.
- **A hard fact about the activation point, discovered by the correction:** a
  bare `await warmUpArt()` in a widget test **hangs indefinitely** — the
  `AssetImage.resolve` listener inside `_precache` needs the real-async bridge,
  so the test must use `tester.runAsync`. Anyone testing warm-up later must know
  this.
- **I3 landed stronger than the architect specified, correctly.** A literal
  crypt-versus-Sea-Cave comparison would pass even with `_texturePhase`
  hardcoded to zero, because those palettes differ in colour independently of
  phase. The worker instead varies **only `themeSalt`** between two otherwise
  byte-identical palettes with one shared synthetic sheet, which isolates the
  phase input.
- **I4's semantics assertion is now behavioural, and proved so both ways:**
  setting `excludeFromSemantics: false` does **not** fail the new test — correct,
  because the real accessibility tree stays silent under the outer
  `ExcludeSemantics` — while removing that `ExcludeSemantics` does fail it with
  a real `SemanticsNode(flags: [isImage])`. The old widget-type assertion had it
  backwards.
- Also landed: `excludeFromSemantics: true` and an honest dartdoc on
  `ActionIconImage`; `WidgetsFlutterBinding.ensureInitialized()` as `main()`'s
  first line; the body comment deleted; `ui.Codec` disposed in a `finally` after
  `getNextFrame()`; warm-up's 18 decodes and 3 precaches batched through
  `Future.wait`; the incidental 29-count dropped; imports sorted.
- **Architect's refreshed integrated gate at this exact tree**: `dart format`
  **112 files, 0 changed**; `flutter analyze` **no issues**; full
  `flutter test` **870 passing** — 869 plus the one new activation test, with
  I2/I3 being 1:1 replacements. `git diff --name-only 4bf865c --
  packages/app/test` is **empty**, so no base-tracked test file was modified by
  the round either.
- **The device-evidence recovery checkpoint is written** at
  `units/unit-10/DEVICE-CHECKPOINT.md`: exact tree, untracked load-bearing and
  irreplaceable paths, accepted fresh evidence, device state, the save
  backup/restore obligation, and the five remaining capsules A-E with what each
  must judge. No device, emulator, ADB, install or screenshot action has
  occurred.
- One scoped closure review is dispatched (`agent://U10Closure`) over the
  correction round only. The device gate opens when it passes.
- 2026-09-16 — **Scoped closure review PASS, zero findings**:
  `agent://U10Closure` reviewed the correction round read-only and judged all
  three rewritten proofs genuinely falsifiable, tracing each discriminator
  itself rather than accepting the worker's account. It confirmed I2's probe
  pixel is live and actually covered by the opaque overlay (cell (1,1) spans
  y 36-72, the opaque half covers 36-54, the sample is y 51), and that
  `themeSalt` reaches the render through exactly one path, so I3 fails if the
  phase is dead. It verified the tracked diff moved by exactly **+1 line** — the
  `ensureInitialized` call — and that `dungeon_scene_material.dart` is unchanged
  at 189/11, so the round left no net line in the renderer. It read both probe
  sites at source itself. `warm_up_test.dart` and the deliberate
  unloaded-process pin were run in one invocation and both passed, closing the
  global-state race empirically.
- Judgments worth keeping: `tester.runAsync` is the documented bridge rather
  than a workaround, and `_precache` is correct in production (listener assigned
  before `addListener`, self-removing on both paths, completer guarded,
  `onError` supplied); M3's disposal is byte-for-byte Flutter's own
  `decodeImageFromList` shape, `Future.wait` preserves input order so the index
  mapping stays exact, and `_warmedUp = true` still precedes the first await.
- **The one-line hardening was load-bearing, not decoration.** The reviewer's
  `[INFERENCE]`, from reading `asset_bundle.dart:324-330`: `rootBundle.load`
  dereferences `ServicesBinding.instance`, so with `warmUpArt()` awaited before
  `runApp` and no binding initialized, **every decode would have thrown, been
  swallowed, and left `dungeonArt` permanently on `none()`** — exactly the silent
  total-activation failure I1 was raised against. The unit would have shipped
  rendering byte-identically to `4bf865c`, and the five-capsule device gate
  would have proved the procedural renderer. `warm_up_test.dart` now catches any
  regression of it.
- **The acceptance barrier is closed and the device gate is open.** `adb
  devices` shows no device attached: `Medium_Phone` is not started and the user
  has been asked to start it. Next action is capsule A once it is up.

### Unit 10 device evidence

- 2026-09-16 — **Capsule `U10-A-towns-and-rooms` is accepted.**
  `agent://U10CapsuleA` built and installed the current-tree debug APK
  (SHA-256 `ccd474e5…ea8c171`) on user-started `emulator-5554` (Android 17,
  1080x2400) and captured eight colour/greyscale pairs under
  `.flow/evidence/visual-reboot/unit-10-device/`.
- **The architect inspected the frames, not just the report.** Stonebridge
  carries its band between Materials and the doors, and the 2.5:1 crop lands —
  cathedral, rooftops and bridge all present. Northgate is **genuinely bare**:
  no band, no substitute, no reused art. The forge's fire and anvil and the
  tavern's hearth and bar both land. Every fact still reads: place name, descent
  sentence, Health, Carried, Banked, Materials rows, door labels and purposes,
  the forge's `2 ore makes 1 ingot` / `That takes 2 ore` / `Temper` refusal
  wording, and the tavern's `Ask 15`. The greyscale twin of the town frame is
  fully legible, art included.
- Criteria **3, 4** and the town/room clause of **16/17** pass. Criterion 5 is
  **not observable from a screenshot** — correctly flagged rather than claimed —
  and is already proved by the corrected semantics-tree test.
- **Architect observation for the user, not a defect:** the forge and tavern
  interiors are considerably brighter and warmer than anything else in the app's
  near-monochrome dark UI, so each is a strong focal element on its screen. All
  text stays primary and legible, and the art is user-approved, so this is a
  taste call rather than a contract violation.
- **Process note, disclosed by the verifier rather than hidden:** a failed `cd`
  briefly left three stray fixture files at the repository root and a mistaken
  redirect emptied a disposable post-`pm clear` device save. Both were detected
  and cleaned inside the session, the backed-up originals were never touched,
  and the architect confirmed the repository root is clean and `git status`
  matches the checkpoint inventory exactly. Save restoration is MATCH on both
  slots against the epic's recorded Unit 8/9 baseline hashes.
- Capsule B (`U10-B-crypt-and-boot-cost`) is dispatched
  (`agent://U10CapsuleB`), with a baseline `4bf865c` build authorized in a
  throwaway `.worktrees/u10-baseline` worktree so the dirty main worktree is
  never touched.
- 2026-09-16 — **Capsule `U10-B-crypt-and-boot-cost` is accepted.**
  `agent://U10CapsuleB` built the current tree (APK `50e82220…6bf3e2`) and a
  clean `4bf865c` baseline (`85bf9e2c…fc17304`) in the authorized throwaway
  worktree, now removed, with the main worktree's `git status` fingerprint
  identical before and after. Fixtures were generated by real game code
  (`startDungeonRunAt` + `step`), not hand-typed.
- **Authored art is unambiguously reaching the screen.** The architect compared
  the current and baseline frames of the identical staged scene: baseline is
  flat tonal fill, current is full masonry stone with rubble clumps. This
  **refutes the reviewer's predicted swallowed-decode failure mode**
  observationally, and `ensureInitialized` is confirmed present in the current
  tree and absent at baseline.
- **The architect's own eyeball concern was wrong, and measurement corrected
  it.** The textured frame *looks* brighter, so the softLight layer was
  suspected of lifting luminance and flattening the local-light gradient.
  ImageMagick patch means on both frames say otherwise: near the hero
  **0.7613 current versus 0.7585 baseline**, far edge **0.6271 versus 0.6261**,
  remembered corridor **0.6567 versus 0.6543** — identical within 0.003 across a
  0.13 gradient. The authored layer contributes **no net luminance shift** and
  the radial light still owns brightness, exactly as the softLight-against-
  mean-0.50 design claimed. The perceived difference is texture, not exposure.
- Unknown cells are **pure black** in the unknown-edge frame with no hint of
  geometry; remembered cells stay flat and untextured because the authored mask
  is visible-only; `@` and `r` glyphs and the potion and pack icons stay legible
  above texture, in greyscale too.
- **Cold boot cost, measured** by `am start -W` TotalTime after force-stop:
  controlled 5-versus-5 on an identical save gives current **1581 ms** mean
  (1363-1751) against baseline **1477 ms** (1387-1616), **+104 ms**; the wider
  10-versus-7 set gives +172 ms. Direction is consistent with the added
  synchronous warm-up, and the verifier reported that per-run spread
  (229-450 ms) rivals the gap rather than averaging it away. Accepted: the
  approved boot precache costs roughly a tenth of a second.
- **Two items honestly returned as UNKNOWN rather than upgraded**: stairs
  legibility (the fixtures never reached a stairwell) and the scene-entry and
  panning hitch (no reliable frame-timing tool was used). Both are routed into
  capsule C with an explicit method rather than being waived.
- Capsule C (`U10-C-regional-cues-and-stairs`) is dispatched
  (`agent://U10CapsuleC`). Its central question is the one measurement cannot
  answer: whether the Sea-Cave's tide strata and the Ruined Keep's ashlar
  fractures still read under authored texture, in colour and in greyscale.
- 2026-09-16 — **Capsule `U10-C-regional-cues-and-stairs` returned one real
  escalation.** `agent://U10CapsuleC` staged ten codec-valid `visit: 1` fixtures
  from real game code — after a 40-seed survivability scan, because a level-0
  hero cannot cross either dungeon's first floor alive — and captured 20 PNGs
  including magnified crops. Both save slots MATCH; no baseline worktree was
  needed; the main worktree fingerprint is unchanged.
- Passing in C: ashlar block grid; region distinguishability; wall edges and
  light falloff; unknown-unpainted and remembered-flat; every glyph, badge and
  HUD item legible above texture even in the busiest combat frames. **Capsule
  B's stairs UNKNOWN is closed PASS** on a Sea-Cave stairwell frame.
- **The escalation, confirmed by the architect at the frames:** the Sea-Cave
  tide-strata dashes and the Ruined Keep V-fracture chevrons are present in the
  correct ink and survive magnification and greyscale, but the authored bitmap's
  own busy natural texture **subordinates them at ordinary viewing distance**.
  The architect adds a sharper point the verifier did not make: in colour the
  strongest remaining region signal is **hue** — Sea-Cave teal against Keep tan —
  which is precisely the carrier the accessibility lock forbids. In greyscale the
  regions still separate, but by the bitmaps' texture character (mottled rock
  versus blocky ashlar) rather than by the cues Unit 2 and Unit 8 established
  and a device gate already accepted. Criterion 13 is therefore met on
  *presence* but weakened on *reading*.
- **The user decided: quieten the sheets.** Re-derive the six material sheets
  with lower high-pass amplitude so the procedural cues resurface through a
  subtler texture, then re-shoot capsule C. No Dart change; the alternatives —
  accepting the weakening, or raising `seaCaveStone`/`ruinedKeepMasonry` pattern
  strength and reopening Unit 2/8 values — were both rejected.
- **The frame-timing UNKNOWN is closed by architect decision, not by evidence
  upgrade.** Two capsules, two instruments (`gfxinfo framestats` and
  `SurfaceFlinger --latency`), both unusable in this emulator. It is closed on
  the consistent no-visible-hitch observation across 15+ launches plus the
  structural fact that decoding happens once at boot (measured at +104 ms) and
  the shader is rebuilt per plan adoption, never per frame. Criterion 17 asks
  for no **obvious** hitch, which an eye can judge. Recorded as an explicit
  judgement call so a later session can reopen it with profile-mode timeline
  evidence if it wants.
- Capsule D (`U10-D-lowland-road`) is dispatched (`agent://U10CapsuleD`) and
  must finish before the re-derivation starts: it builds and compares APKs from
  this tree, so changing the shipped sheets mid-capsule would destroy its
  artifact identity.
- 2026-09-16 — **Session paused by the user with capsule D in flight.** It was
  deliberately **not cancelled**: cancelling mid-capsule would have skipped its
  save-slot restore obligation and could have left a baseline APK installed, a
  `.worktrees/u10-baseline` worktree behind, or the device saves unrestored.
  `RESUME.md` carries the exact five-step reconciliation the next session must
  perform before any new work — read its report, check `git worktree list`,
  check `git status`, verify both device save hashes against the epic baseline,
  and confirm which APK is installed.
- State at pause: implementation complete and uncommitted, format/analyze/870
  tests green, whole-unit review PASS after one correction round, closure review
  PASS, capsules A/B/C accepted, D in flight, the approved sheet re-derivation
  and a capsule C re-shoot queued behind it, then capsule E, then the user's
  integration decision. No commit, push, pull request or other remote action has
  been performed or authorized at any point in this unit.
- 2026-09-16 — **Capsule `U10-D-lowland-road` is accepted, and it landed before
  the pause took effect.** `agent://U10CapsuleD` staged a codec-valid `visit: 1`
  journey fixture with real game code (`startDungeonRunAt` + `endRun`, then
  `beginTravel`/`travelOneDay`; world seed 10, Stonebridge-Crypt route, danger
  15, day-1 `DangerMet`) and captured the road fight on the current APK
  (`50e82220…6bf3e2`) and a fresh `4bf865c` baseline (`85bf9e2c…c17304`) from the
  identical pushed fixture.
- **Criterion 9 is proved the strong way: the map crop is pixel-identical.**
  `AE = 0`, `RMSE = 0`, `MAE = 0` at fuzz 0 over `1080x1676+0+84`, confirmed on a
  raw RGBA dump, in colour and greyscale. **The architect re-ran the comparison
  independently**: `magick compare -metric AE` on the two retained map crops
  returns `0`. The ~99.3% of full-frame difference sits below y=1760 — this
  unit's own in-scope control row.
- The verifier attached the reason rather than only the measurement: neither
  art enum has a `lowlandRoad` entry, so `surfaceFor` returns null and
  `_drawAuthoredMaterial` paints nothing for the road. `THE ROAD` with no depth
  pair, the exact edge-escape sentence, and the frozen Drink/Pack/Wait control
  set all confirmed on device.
- Restore MATCH on both slots; baseline worktree removed; main worktree status
  is the expected 25-entry inventory. **The device is left with the
  current-tree APK installed and the app force-stopped** — recorded because a
  stale baseline APK would have made every later frame misleading.
- **Four of five capsules are accepted (A, B, C, D).** Remaining before the
  integration decision: the approved sheet re-derivation, a capsule C re-shoot
  against the same fixtures, and capsule E.
- 2026-09-16 — **The approved sheet re-derivation is landed and
  architect-verified.** `agent://U10Rederive` replaced the fixed
  `-function polynomial "1.6,-0.3"` re-centring in `tool/derive-visual-assets.sh`
  with a **per-sheet normalization**: measure the high-passed intermediate's
  standard deviation, set `gain = 0.05 / measured` and
  `bias = 0.5 - 0.5 * gain`, so the mean stays pinned at 0.50 by construction
  exactly as the old constant pair did. The six pre-gain spreads ranged
  0.0545-0.1031, so no single fixed gain could have landed all six in band —
  per-sheet solving was the right shape, not six hand-tuned constants.
- **Architect-measured result, independent of the worker's report** — every
  sheet now sits at std **0.0500 ± 0.0001** with mean within 0.0031 of 0.50:
  `crypt_floor` 0.0872 → 0.0500, `crypt_wall` 0.0980 → 0.0500,
  `sea_cave_floor` 0.1182 → 0.0500, `sea_cave_wall` 0.1395 → 0.0501,
  `ruined_keep_floor` 0.1422 → 0.0500, `ruined_keep_wall` 0.1650 → 0.0500.
  Dimensions, greyscale character and the no-alpha property are unchanged.
- The two busiest sheets before this change were the Ruined Keep and Sea-Cave
  walls, and they are exactly the regions whose cues capsule C reported
  subordinated, while the quietest belonged to the Crypt, whose palette has no
  procedural pattern to compete with. That correspondence is why the fix targets
  amplitude rather than the cues themselves.
- Idempotence survives: two consecutive script runs produce byte-identical
  SHA-256 sets across all 29 assets, with the gain measured from the freshly
  computed intermediate rather than from a shipped asset, so a second run cannot
  drift. The other 23 assets are byte-unchanged, the 31 masters are intact, no
  Dart file was touched, and the suite still reads **870 passing** with format
  and analyze clean.
- The capsule C re-shoot (`U10-C2-regional-cues-after-requiet`) is dispatched
  (`agent://U10CapsuleCRedo`) on the user-restarted AVD, reusing capsule C's own
  seed-12 and seed-47 fixtures and framing so before and after compare directly.
  It is told to report a cure worse than the disease — washed-out flat material —
  as a finding in its own right.
- 2026-09-16 — **Re-shoot `U10-C2-regional-cues-after-requiet` is accepted;
  criterion 13 is resolved.** `agent://U10CapsuleCRedo` rebuilt and installed
  from the re-derived tree (APK `3d07c528…d2ea5d`, confirmed different from the
  pre-re-derivation `50e82220…6bf3e2`, so the quieter sheets are genuinely in
  the build), reused all eight capsule C fixtures verbatim with SHA-256
  verification on every push, and wrote 25 new files under `-c2` and
  `-old-comparison` names so capsule C's originals sit untouched beside them.
- **The architect compared the paired magnified greyscale crops directly.** In
  the Sea-Cave the horizontal strata dashes now stand out as a regular banded
  rhythm against calm mottled rock; in the old crop the same dashes fight heavy
  blotchy noise. In the Ruined Keep the ashlar corner brackets read as a row
  rhythm and a V-chevron is plainly visible where before it was buried. The
  material still reads as stone in both regions — the cure did not flatten it,
  which was the named failure mode.
- The verifier's two quantifications agree and add the useful detail that **the
  pattern strokes' own on-screen signal is unchanged**: the improvement came
  entirely from quieter competing bitmap noise, not from a stroke retune. That
  is exactly the outcome the user's choice was supposed to produce, and it
  leaves the accepted Unit 2/8 pattern values untouched.
- Both save slots MATCH; the main worktree fingerprint is unchanged; prior
  evidence is intact.
- Capsule E (`U10-E-control-row-and-shelf`) is dispatched
  (`agent://U10CapsuleE`) — the last outstanding capsule. It must prove no label
  or count ellipsises anywhere at five controls, that every icon reads by shape
  in greyscale, and it must quantify the approved two-run height cost against a
  `4bf865c` baseline.
- 2026-09-16 — **Capsule `U10-E-control-row-and-shelf` is accepted, and it
  produced the unit's most satisfying piece of evidence.** Staged on the same
  bottom-floor scene, the **`4bf865c` baseline reproduced the inherited defect
  live** — `Drink (…)` visibly ellipsised — while the current tree renders
  `Pick up` | `Drink (1)` | `Pack (6)` | `Ascend <` | `Finish` complete across
  two centred runs. The architect confirmed both frames directly. That is
  criterion 11 proved by before-and-after on hardware, not by assertion.
- Greyscale control-row zoom: every icon reads by shape — bottle, backpack,
  stairs-with-arrow — beside its full word and live count. Disabled `Drink`
  reads darker and flatter than the enabled `Pack` beside it in colour **and**
  greyscale, so no state depends on hue. On the shelf, word, count, mana cost,
  school marking and the `— armed` word all survive beside icons, armed still
  reads by border plus word, and the overflow sheet lists all six known spells.
- **Height cost, measured rather than argued:** map viewport 1565 physical px at
  baseline versus 1429 on the current tree — 136 px, **51.8 dp** at 2.625x. That
  is the whole cost of this unit's control change (icons plus `Wrap` plus the
  second run), slightly above the plan's ~44 dp second-run estimate and in the
  same order. Accepted as the approved D2 trade.
- Useful correction to the plan's own framing: the two-run wrap is
  **scene-dependent, not a property of "five controls"** — the road's
  five-control combination fits on a single run because its labels are shorter.
  The plan's arithmetic assumed the stairs-scene label set.
- Observations, neither a defect: the `mend` icon is the busiest of the eight
  but still legible by shape; a level-0 hero cannot survive to Crypt depth five,
  which shaped fixture staging.
- Both slots MATCH; baseline worktree removed; `git status` fingerprint
  unchanged; the current-tree APK was reinstalled after the baseline comparison
  so the device is not left on baseline.

### Unit 10 final local acceptance

- 2026-09-16 — **Unit 10 is complete and locally accepted.** All five device
  capsules (A, B, C with its C2 re-shoot, D, E) are accepted, closing criteria
  16 and 17, and criteria 1-15 were closed by implementation, the integrated
  acceptance review, the correction round and the scoped closure review.
- **Architect-run final gate at the final tree**, after the sheet
  re-derivation: `dart format --set-exit-if-changed --output=none lib test`
  **112 files, 0 changed**; `flutter analyze` **no issues**; full
  `flutter test` **870 passing**. `packages/core` and `packages/content` are
  unchanged. Device evidence remains fresh: the only change since the C2 and E
  captures is this ledger record.
- Criterion 5 (decorative art silent to screen readers) is the one criterion
  proved only by test rather than on device, deliberately: it is not observable
  in a screenshot, and the corrected semantics-tree assertion covers it.
  Criterion 17's hitch clause rests on an explicit architect judgement call
  after two instruments failed on this emulator, recorded above.
- **Nothing is committed.** The unit sits uncommitted on
  `residuum-visual-reboot-10`, including untracked load-bearing source and the
  48.1 MB of LFS-attributed masters under `art/visual-reboot/`. No push, pull
  request, merge or other remote action has been performed or authorized at any
  point in this unit. Next gate is the user's integration decision.

### Unit 10 integration

- 2026-09-16 — **The user chose commit, push and pull request, and it is done.**
  Six commits on `residuum-visual-reboot-10`, one per plan task plus the LDD
  records and the masters: `d3ddebe` pipeline and catalogue, `b7fb5d8`
  illustrations, `153d65e` authored dungeon material, `5c22e43` icons and the
  control row, `095bfb4` records, `3f828b2` the masters.
- **The repository's first LFS push succeeded**: 31 objects, 50 MB. The
  committed blob for a master is a pointer (`oid sha256:0617ccb0…`,
  `size 2247654`) and `git lfs ls-files` lists all 31, so the masters are in LFS
  and the 1.9 MB of derived assets remain ordinary git objects.
- **[PR #20](https://github.com/fiatcode-gh/residuum-rpg/pull/20) is open**
  against `main`, MERGEABLE, 101 files, +7781/-236. GitGuardian passed; the
  three `gates` legs (core, content, app) were still pending at session close —
  **CI is unconfirmed and the merge decision stays with the user.**
- Worktree is clean; nothing remains uncommitted. Merge, review response and any
  follow-up remain user-owned.
- 2026-09-16 — **CI is green on PR #20.** At head `47a19f0`: `gates (app)`
  pass in 2m8s, `gates (content)` pass in 1m14s, `gates (core)` pass in 1m26s,
  GitGuardian pass. The `app` leg is the meaningful one — it resolves, checks
  lockfile drift and runs the full suite on a checkout **without LFS**, which is
  the independent confirmation that criterion 2's no-LFS-build claim holds in a
  clean environment rather than only on this workstation.
- The only outstanding action is the user's merge decision. A later docs-only
  record commit would re-run these same gates without changing app behaviour.