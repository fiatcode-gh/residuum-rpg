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
- Unit 3 is merged to `main` at `4164741`. Its deferred AVD/greyscale pass was
  folded into Unit 4 and is now discharged; no Unit 3 code was reopened.
- **Unit 4 is accepted and published as
  [PR #13](https://github.com/fiatcode-gh/residuum-rpg/pull/13)** from
  `residuum-visual-reboot-4` at `0eb76d3` (code `0d27a18`). Merge is user-owned
  and has not happened. TTC-1A closed by a targeted review PASS; the
  final tree passes scoped `dart format` (19 files, 0 changed), `flutter
  analyze` (no issues), and full `flutter test` (765 tests) from
  `packages/app`; the combined Unit 3 + Unit 4 colour/greyscale device gate
  passed on `emulator-5554`. Full detail is in `LEDGER.md` under
  "Unit 4 acceptance receipt".
- Device evidence lives in `.flow/evidence/visual-reboot/unit-4-device/` as
  `ev-*.png` plus a `-greyscale.png` twin of each frame: hidden-actor
  truncation, duplicate badges across map/timeline/inspect/log, survivor badge
  after a death, no-turn-cost timeline selection with a byte-identical save
  snapshot, armed square targets beside the circular selection, the firebolt
  cast, and the pan → recenter path.
- The device's `save.json` and `save-previous.json` were backed up before the
  session and restored afterwards; both verify SHA-256 identical to the
  pre-session backup. The working tree is clean and no `packages/` file changed
  in this session.
- **Unit 5 is the active unit and its contract is locked** at
  `units/unit-5/CONTRACT.md`, committed on `main` at `864aa6e`. Recon
  (`units/unit-5/recon.md`) is source-verified. Three forks were settled with
  the user and are recorded in `LEDGER.md`: a structured presentation entry
  replaces `GameViewState.log`'s `List<String>` now rather than deferring
  per-line icons; Unit 5 moves the peek above the controls; and game-over
  collapses the drawer, leaving `_DeathOverlay` as the one interactive surface.
  The category set is deliberately not enumerated in the contract — the design
  spec has no log-category vocabulary, so naming must come from existing `core`
  event words, and membership is planning work.
- `flow-planner` was dispatched for the Unit 5 execution-grade plan
  (`units/unit-5/PLAN.md` + `plan-tasks/`). Its most consequential open call is
  follow-state ownership: the bloc knows when lines are appended, the widget
  knows scroll position, and the contract needs an exact unread count that is
  bloc-provable. On a READY receipt, verify the plan, then take a Unit 5 feature
  branch and dispatch one fresh `flow-plan-executor` per task, sequentially and
  non-isolated. Implementation is **not** yet authorized by the user.
- Hard invariant for every Unit 5 worker: a category comes from the `GameEvent`
  variant where `describeEvent` already switches on it, or from the app's own
  injection call site (`roadOpeningLog`, `_openingLog`, `_asSentence`, and the
  three bloc refusals). Never from matching sentence text. The migration touches
  87 `log` references across 8 test files and must not change any asserted
  sentence.
- Sequencing decided with the user: keep the original 1 → 8 order, no chrome or
  asset unit interleaved, and plan the art pass only after Unit 8. Remaining
  unowned HUD chrome is the depth header, labelled HP/Mana bars, and icon
  control chips — the peek reorder is now Unit 5's. These must be placed before
  the epic closes. `packages/app` has no asset pipeline at all today.
- Locked inherited contracts: section 18 baseline summary in `LEDGER.md`
  (Flame never authoritative game state; graphical glyphs; map-first melee;
  four-region rule; accessibility by shape/word never hue alone) plus
  everything in `../m3/LEDGER.md` (save v3, band lines as controls, house
  method D113, CI/merge flow).
- Traps that can burn the next session: the approved mock is untracked visual
  evidence at `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`;
  standalone durable specs are under `docs/specs/`; suites run per package
  directory (no root pubspec); a first delve bumps `visit` to 1, so device
  scenes must be probed at `visit: 1`, never `visit: 0`.
- Open user decisions: portrait framing / static-art composition / icon
  language before Unit 7 (dungeon-material subset is locked); whether
  m3-quests (M3Q) still runs and where.
- Full decision history: this ledger is young — the product's deep history
  is `../legacy/LEDGER.md` (D1–D126) and `../m3/LEDGER.md`.
