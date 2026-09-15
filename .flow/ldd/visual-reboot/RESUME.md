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
  `residuum-visual-reboot-4` at `0eb76d3` (code `0d27a18`). **Both #13 and #14
  are now merged to `main`** (`650fa7c`, `15e737a`). TTC-1A closed by a targeted review PASS; the
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
- **Unit 5 merged as [PR #15](https://github.com/fiatcode-gh/residuum-rpg/pull/15)**
  at `55a226d` on 2026-09-15. The merged code is `0bf6da1`; all four CI gates
  passed before merge. The Unit 5 contract commit `864aa6e` reached `main`
  through the PR with the code, and `0bf6da1` is an ancestor of the current
  main head. The earlier unmerged status in this file is superseded by this
  source check.
- Corrected a stale claim that was in this file: Unit 4's PR #13 **and** #14 are
  already merged into `main` (`650fa7c`, `15e737a`), and Unit 5's base descends
  from both. Earlier RESUME text saying Unit 4's merge "has not happened" was
  out of date — verify merge state at source before repeating it.
- Final tree at `0bf6da1`: `dart format` 94 files/0 changed, `flutter analyze`
  no issues, full `packages/app` suite **797 tests** passing, all run by the
  architect. The integrated acceptance review returned ACCEPT WITH FINDINGS;
  its one must-fix plus five optional items were corrected in a single round.
  Full detail is in `LEDGER.md` under "Unit 5 acceptance receipt".
- What shipped: `GameViewState.log` is now `List<LogLine>` (sentence + one of a
  ten-member `LogCategory`), the peek sits above the controls, the drawer is a
  peek → half → full overlay that never reflows the map, and follow/unread live
  in the bloc while the widget owns only scroll position. `describeEvent` keeps
  one switch over sealed `GameEvent` and returns `LogLine?`; no category is ever
  inferred from sentence text.
- **Trap proven the hard way, worth carrying into every later unit: a mark
  codepoint can render as a colour emoji on device and no widget test will ever
  catch it.** `moved` shipped as `↕` (U+2195), which Android resolved through
  the colour emoji font — a blue-cyan box that ignored the row's text colour, so
  hue carried category and the mark lost its value contrast. It is now `⇅`
  (U+21C5). The test font resolves every codepoint and `find.text` matches
  regardless of fallback, so only the device gate sees this. U+2B65 is tofu on
  this target. When Units 6–8 add marks, measure them on device.
- Criterion 12 evidence is complete in colour and greyscale under
  `.flow/evidence/visual-reboot/unit-5-device/`, with a `-greyscale.png` twin of
  every frame. `ev-combat-glyph-rows` carries eight categories at once and is
  the single most useful frame. `ev-death-drawer-collapsed` and
  `ev-death-handle-inert` are pixel-identical below the status bar, which is how
  the inert handle is proven rather than asserted.
- Device saves were backed up before the session and restored after; both verify
  SHA-256 identical (`18995c4a…`, `8909f70c…`). The AVD here is now
  `Medium_Phone` (Android 17), not `Pixel_10`, and it segfaults when launched
  from a tool shell — ask the user to start it.
- **Unit 6 is accepted and committed locally** as `89927ef` on
  `residuum-visual-reboot-6` at source base `55a226d`, with
  [PR #16](https://github.com/fiatcode-gh/residuum-rpg/pull/16) open. It
  replaces the crawl long Pack with `CrawlPackScreen`/shared `PackContents`,
  and makes town Character a compact route hub for Gear, read-only Spells,
  Skills, and Pack.
- Acceptance review returned **ACCEPT** (COR/TTC/CRF PASS; SEC skip). A bounded
  follow-up keeps the selected Pack ChoiceChip semantically enabled while its
  no-op tap preserves game/log identity, and corrects stale known-spell
  ownership dartdoc. Final Main evidence from `packages/app`: `dart format`
  checked 97 files with 0 changes, `flutter analyze` found no issues, and full
  `flutter test` passed **789 tests**.
- The Unit 6 device gate passed on user-started `Medium_Phone` (Android 17,
  1080x2400). Evidence under
  `.flow/evidence/visual-reboot/unit-6-device/` covers the Character overview,
  Gear, empty Spells, Skills, town Pack, and corrected crawl Pack in normal
  colour and greyscale. All six filters were exercised; check mark, label, and
  position identify the active filter in greyscale. Filter Books → back leaves
  the app frame pixel-identical to its pre-filter state (`0 (0)` differing
  pixels after status-bar crop).
- Both device saves were copied before install and restored after all driving.
  Final on-device SHA-256 matches the backups: `save.json`
  `18995c4…b46d3`; `save-previous.json` `8909f70c…a9b11`. The app is stopped.
  No commit, push, pull request, or merge is authorized. Exact next action:
  obtain the user's integration decision, or begin Unit 7 only after its
  product/design contract is independently settled.
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
