# Resume Visual Reboot

- Unit 0 completed (2026-09-13): source-verified behavior matrix, seam
  inventory, inherited-assumption corrections, and execution order are in
  `units/unit-0/recon.md`. No production code was written.
- Unit 1 is accepted on `visual-reboot-unit-1`: final COR/TTC/CRF were clean,
  `packages/app` passed 682 tests and analyzer, and Pixel_10 AVD/greyscale
  evidence is under `.flow/evidence/visual-reboot/`.
- Unit 2 is accepted on `visual-reboot-unit-2`: graphical Crypt material,
  visible-only continuous light, material-derived stair glyphs, and
  known-wall face continuity are verified by the app suite/analyzer and
  Pixel_10 colour/greyscale evidence.
- Unit 3 contract approved (2026-09-14); execution-grade plan at
  `units/unit-3/PLAN.md` + three task briefs. Next action: user implementation
  authorization, then dispatch one sequential `flow-plan-executor` on a fresh
  `residuum-visual-reboot-3` branch from `affc138`. No production code written.

## Unit 3 execution state (paused 2026-09-14, session limit)

- Branch `residuum-visual-reboot-3` from base `ebf9c62` (which is `affc138` +
  the `docs:` ledger/plan commit). Executor `Unit3Executor` was dispatched
  non-isolated as sole writer.
- **All three tasks complete.** Implementation commit `a8eacf1` (733 tests,
  analyzer clean); review correction `0156a0b` (visible-cast test + inspect
  visibility gate; 736 tests, analyzer clean). Full `flutter test` and
  `flutter analyze` from `packages/app` verified by Main at `0156a0b`.
- Acceptance review (single `flow-acceptance-reviewer`, `Unit3AcceptReview`)
  verdict CHANGES → corrected and re-verified; contract satisfaction, plan
  conformance, correctness all PASS. SEC skip.
- Remaining gate: Pixel_10 AVD + greyscale device acceptance (contract
  criterion 10) — **BLOCKED on this host** (14 GiB RAM, AVD wants 16 GiB; two
  launches died before `adb` registration). Must be captured on a capable host
  before Unit 3 is accepted for merge. Then integration (user-owned;
  `flow-integrating`).
- Locked inherited contracts: section 18 baseline summary in `LEDGER.md`
  (Flame never authoritative game state; graphical glyphs; map-first melee;
  four-region rule; accessibility by shape/word never hue alone) plus
  everything in `../m3/LEDGER.md` (save v3, band lines as controls, house
  method D113, CI/merge flow).
- Traps that can burn the next session: the approved mock is untracked visual
  evidence at `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`;
  standalone durable specs are under `docs/specs/`; suites run per package
  directory (no root pubspec).
- Open user decisions: portrait framing / static-art composition / icon
  language before Unit 7 (dungeon-material subset is locked); whether
  m3-quests (M3Q) still runs and where.
- Full decision history: this ledger is young — the product's deep history
  is `../legacy/LEDGER.md` (D1–D126) and `../m3/LEDGER.md`.