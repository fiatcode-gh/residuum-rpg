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
- **Unit 3 contract proposed** at `units/unit-3/CONTRACT.md` (2026-09-14):
  map-first melee, map-targeted casts, inspect via long-press or non-adjacent
  tap, one contextual shelf with readied + overflow, recenter affordance.
  User review required before code; two open decisions (camera ease-back
  scope, readied-slot model) are unresolved.

## Epic status

| Unit | Dependencies | State | Verification | Notes |
|---|---|---|---|---|
| Unit 0 — design baseline + recon | none | complete | source recon and approved mock inspection; no code | matrix, seam inventory, corrections: `units/unit-0/recon.md` |
| Unit 1 — dungeon scene foundation | Unit 0 | accepted | 682 app tests, analyzer, final COR/TTC/CRF, Pixel_10 AVD and greyscale pass | contract: `units/unit-1/CONTRACT.md`; Flame only in `packages/app` |
| Unit 2 — graphical dungeon language | Unit 1 | accepted | 721 app tests, analyzer, corrective COR/TTC/CRF, Pixel_10 AVD and greyscale pass | cold-charcoal continuous material, warm clipped light, strict no-geometry-leak fog |
| Unit 3 — crawl interaction reboot | Unit 2 | planned | one-handed movement/melee/targeting/wait/pack without the old dock | map-first melee; favorites + overflow |
| Unit 4 — turn timeline + duplicate identity | Unit 3 | pending | next activation sequence readable with duplicates + fast actors | encounter-local labels, timeline→map highlight |
| Unit 5 — log drawer | Unit 3 | pending | history reviewable during combat without shrinking the map | 3-line peek, half/full overlay, auto-follow |
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