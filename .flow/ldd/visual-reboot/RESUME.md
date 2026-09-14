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
- Unit 3 is merged to `main` at `4164741`: implementation `a8eacf1` plus
  correction `0156a0b`, 736 app tests, clean analyzer, and an acceptance-review
  pass. Its deferred AVD/greyscale pass is folded into Unit 4's final combined
  device acceptance on the recreated AVD; no Unit 3 code is reopened.
- Unit 4 implementation is complete on `residuum-visual-reboot-4`: Tasks 01–03
  landed (identity/queue/bloc lifetime; map badges/selection/focus; timeline
  legacy cutover). Acceptance-review corrections, whole-app verification, and
  the combined recreated-AVD colour/greyscale gate remain; do not claim
  acceptance yet. That device gate covers Unit 3's one-handed flow and Unit 4's
  identity/timeline flow.
- Current action: correct the two accepted Unit 4 test-coverage findings, then
  rerun the affected focused proof and acceptance review before the app-wide and
  recreated-AVD gates.
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