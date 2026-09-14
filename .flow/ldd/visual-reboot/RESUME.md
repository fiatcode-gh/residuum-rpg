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
- Unit 4 is an interrupted WIP checkpoint on `residuum-visual-reboot-4`,
  pushed at `0d27a186` (`feat(wip): visual reboot unit 4`). Tasks 01–03 are
  implemented. The first acceptance review found two Important TTC coverage
  gaps plus stale LDD status; the coverage gaps were corrected. A targeted
  re-review found one remaining second-duplicate semantics assertion gap; that
  exact test-only correction also landed with 34 `battle_view_test.dart` tests,
  scoped format, and focused analysis green. No post-correction closure review
  was completed.
- Main-owned broad proof after the first correction wave was clean:
  `flutter analyze` passed and full `flutter test` passed 765 tests. The final
  semantics assertion changed the test tree afterward, so rerun final-tree
  formatting/analyze/full-test gates before claiming acceptance.
- The recreated `Medium_Phone` AVD eventually registered in `adb`, the Flutter
  app launched, and exploratory screenshots were captured through crawl
  navigation. The 5-hour session limit terminated the session during encounter
  search before the combined Unit 3 + Unit 4 colour/greyscale criteria were
  exercised. Treat those screenshots as exploratory only. The interrupted
  session recorded no completed device acceptance or save-slot
  backup/restoration receipt.
- Current action: in a fresh session, verify local HEAD/tree against remote
  `0d27a186`, close TTC-1A with a targeted acceptance re-review, rerun final
  formatting + `packages/app` analyzer/full-test gates, then perform the
  combined current-phone Unit 3 + Unit 4 colour/greyscale device gate. Only
  after those proofs may Unit 4 be marked accepted and enter `flow-integrating`.
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