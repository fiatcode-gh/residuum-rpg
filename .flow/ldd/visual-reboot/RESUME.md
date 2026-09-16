# Resume Visual Reboot

**Units 1–9 are merged. Unit 10 (authored art integration) is implemented,
locally accepted by review, and four of five device capsules are accepted as of
2026-09-16.** Read this file, then `units/unit-10/CONTRACT.md`,
`units/unit-10/DEVICE-CHECKPOINT.md`, then `LEDGER.md:1878-2030`.
`units/unit-10/recon.md` is superseded on one point: the authored dungeon pass
goes after the visible light, not in `_drawCellBase`. The external bundle at
`external/unit-10-chatgpt-handoff/` is unvalidated evidence, already reconciled;
do not reopen it.

## Exact state of the working tree

- Branch **`residuum-visual-reboot-10`**, HEAD `4bf865c`. **Nothing is committed
  on this branch.** No remote branch; no push or pull request authorized.
- Modified, all Unit 10: `packages/app/lib/main.dart`,
  `packages/app/pubspec.yaml`, `packages/app/lib/town/{town_screen,forge_screen,
  tavern_screen}.dart`, `packages/app/lib/game/{game_screen,dungeon_material,
  dungeon_scene_material,dungeon_scene}.dart`.
- **Untracked and load-bearing — a `git clean` destroys the unit:**
  `.gitattributes`, `tool/derive-visual-assets.sh`,
  `packages/app/assets/visual/` (29 derived assets),
  `packages/app/lib/art/{art_assets,dungeon_art}.dart`,
  `packages/app/lib/town/illustration.dart`,
  `packages/app/lib/game/action_icon.dart`, six new test files under
  `packages/app/test/{art,game,widget}/`.
- **Untracked and irreplaceable:** `art/visual-reboot/` — 31 approved masters,
  48.1 MB, verified against `SHA256SUMS.txt`. The repository cannot regenerate
  these. They are LFS-attributed but **not yet committed**.
- `packages/core` and `packages/content`: zero changes.

## Fresh evidence accepted (do not re-earn)

Architect-run from `packages/app` at this tree: `dart format
--set-exit-if-changed --output=none lib test` 112 files 0 changed;
`flutter analyze` no issues; full `flutter test` **870 passing**.

`agent://U10Acceptance` — whole-unit review, **no Critical**, all 18 criteria
conformant, four safety invariants verified structural at source.
`agent://U10Corrections` — its three Important findings closed, each rewritten
proof demonstrated to fail when production is broken.
`agent://U10Closure` — scoped closure review **PASS, zero findings**.

Device capsules accepted, artifacts in
`.flow/evidence/visual-reboot/unit-10-device/`:

- **A towns and rooms** — Stonebridge banded, Northgate genuinely bare, forge and
  tavern art in both towns, nothing displaced, greyscale legible.
- **B Crypt and boot cost** — authored art unambiguously on screen versus a
  `4bf865c` baseline; unknown pure black; remembered flat. Architect-measured
  patch luminance current versus baseline: 0.7613/0.7585 near hero,
  0.6271/0.6261 far, 0.6567/0.6543 remembered — **no net luminance shift**, light
  still owns brightness. Cold boot +104 ms (controlled 5v5) to +172 ms, spread
  229–450 ms reported honestly.
- **C regional cues and stairs** — all PASS except the escalation below. Stairs
  UNKNOWN from B closed PASS.
- **D lowland road** — criterion 9 proved the strong way: the map crop
  (`1080x1676+0+84`) is **pixel-identical** to a `4bf865c` baseline,
  `AE = RMSE = MAE = 0` at fuzz 0, re-verified independently by the architect
  with `magick compare -metric AE` on the retained crops. The reason is
  structural: neither art enum has a `lowlandRoad` entry. All full-frame
  difference is the in-scope control row below y=1760.

## Device state at pause

Capsule D finished cleanly before the pause took effect, so **nothing is in
flight**. The device (`emulator-5554`, user-started) has the **current-tree
APK** `50e82220…6bf3e2` installed with the app force-stopped; no baseline APK is
left behind. No `.worktrees/` entry remains (`git worktree list` shows only the
main worktree). `git status --porcelain` is the expected 25-entry inventory.
Both device save slots sit at the epic baseline:
`save.json`
`18995c4ac55edc6dfb23b0b13b0e09cf2d79747e6028964b0187a2a4182b46d3` and
`save-previous.json`
`8909f70c64c633c1678b42ff90390216be2e76c29e3ff2f482219d470f8a9b11`, read from
`app_flutter/`, never `files/`. Re-verify these before trusting any new frame.

## Exact next action, in order

1. The user-approved **sheet re-derivation**; nothing blocks it now that no
   capsule is building APKs from this tree. Lower the high-pass amplitude in
   `tool/derive-visual-assets.sh` so the six material sheets keep mean ~0.50 —
   the softLight identity that preserves the measured no-luminance-shift
   property — while roughly halving standard deviation from today's 0.087–0.118
   toward ~0.045–0.060. Regenerate all assets, re-run the suite, no Dart change.
2. Re-shoot capsule C's Sea-Cave and Ruined Keep frames against the same
   fixtures so before and after compare directly.
3. Capsule **E** — control row at both enumerated five-control densities
   including the bottom-floor underfoot scene, disabled `Drink`, the shelf with
   every icon-bearing action, the open `+N` sheet, **no ellipsis anywhere**, icon
   legibility by shape in greyscale, and the crawl viewport height delta against
   `4bf865c` (two runs cost ~44 dp; quantify, do not re-litigate).
4. Then the user's integration decision. Note the masters are LFS-attributed but
   uncommitted, so the first commit must have LFS working.

## Open decisions and judgement calls on record

- **Sheet re-derivation is approved** (option: quieten the sheets). Rejected:
  accepting the weakening; raising `seaCaveStone`/`ruinedKeepMasonry` pattern
  strength, which would reopen Unit 2/8 values.
- **Frame-timing UNKNOWN is closed by architect decision, not evidence.** Two
  capsules, two instruments (`gfxinfo framestats`, `SurfaceFlinger --latency`),
  both unusable on this emulator. Closed on consistent no-visible-hitch
  observation across 15+ launches plus the structural fact that decode happens
  once at boot and the shader rebuilds per plan adoption. Reopenable with
  profile-mode timeline evidence.
- **Architect observation never escalated to a decision:** the forge and tavern
  interiors are far brighter and warmer than the rest of the dark UI, so each is
  a strong focal element. Text stays primary; the art is user-approved. If the
  user ever wants them knocked back it is a re-derivation, not a code change.

## Traps that can burn the next session

- **`art/visual-reboot/` is untracked and irreplaceable.** Never clean, checkout,
  stash or reset the main worktree. Baseline builds go in a throwaway
  `.worktrees/u10-baseline`, removed after use.
- `Medium_Phone` must be **user-started**; tool-shell launch segfaults. It was
  running at pause.
- Both save slots are backed up and restored per capsule, from `app_flutter/`,
  never `files/`, proved by SHA-256 under one scheme.
- Fixtures must be **generated by real game code** (`startDungeonRunAt` + `step`)
  and staged at `visit: 1`. A level-0 hero cannot cross the Sea-Cave or Ruined
  Keep first floor alive; capsule C found workable seeds 12 and 47.
- A bare `await warmUpArt()` in a widget test **hangs**; it needs
  `tester.runAsync`.
- The synthetic sheet in an authored-material test must be **two-tone**: a
  uniform mid-grey sheet is softLight's identity and turns tests green for the
  wrong reason.
- The base-tracked test files are byte-unchanged and must stay so; if one fails,
  the implementation is wrong.
- Suites run per package directory; there is no root pubspec.

## Still open beyond Unit 10

- A controls unit for the remaining icons (`melee`, `back`) and any further
  control-row work.
- Portraits and room-background ratios remain unowned.
- Does old-wave m3-quests (M3Q, save v4, `../m3/LEDGER.md`) still run, and where?
- Deep history: `../legacy/LEDGER.md` (D1–D126) and `../m3/LEDGER.md`.
