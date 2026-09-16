# Resume Visual Reboot

**Units 1–9 are merged. Unit 10 (authored art integration) is complete, accepted
and open as [PR #20](https://github.com/fiatcode-gh/residuum-rpg/pull/20) as of
2026-09-16.** Read this file, then `LEDGER.md:2117-2156` for the final acceptance
and integration records. `units/unit-10/recon.md` is superseded on one point: the
authored dungeon pass goes after the visible light, not in `_drawCellBase`.

## Exact state

- Branch **`residuum-visual-reboot-10`**, pushed, tracking `origin`. **Worktree
  is clean** — nothing uncommitted. Six commits on top of `4bf865c`:
  `d3ddebe` pipeline and catalogue, `b7fb5d8` illustrations, `153d65e` authored
  dungeon material, `5c22e43` icons and the control row, `095bfb4` LDD records,
  `3f828b2` the masters.
- **PR #20** is open against `main`, MERGEABLE, 101 files, +7781/-236.
- The 31 masters under `art/visual-reboot/` are in **Git LFS** (the repository's
  first LFS use, 50 MB pushed); the 1.9 MB of derived assets under
  `packages/app/assets/visual/` are ordinary git objects, so a checkout without
  LFS still builds.
- `packages/core` and `packages/content` are unchanged by this unit.

## Exact next action

**CI was still pending at session close** — the three `gates` legs (core,
content, app) had not reported; GitGuardian passed. Check
`gh pr checks 20 --repo fiatcode-gh/residuum-rpg` first. If green, the merge is
the user's decision; if red, read the failing leg before touching anything.

Merge, review response and any follow-up are user-owned. Nothing else in Unit 10
is outstanding.

## Evidence on record (do not re-earn)

- Architect-run final gate at the merged-in tree: `dart format` 112 files
  0 changed, `flutter analyze` no issues, full `flutter test` 870 passing.
- Whole-unit `flow-acceptance-reviewer` pass with no Critical finding; its three
  Important findings closed by a correction round; scoped closure review PASS.
- Five device capsules on `Medium_Phone`, artifacts under
  `.flow/evidence/visual-reboot/unit-10-device/`: towns and rooms; Crypt plus
  cold-boot cost (+104 ms controlled); Sea-Cave and Ruined Keep, re-shot after
  the sheet re-derivation; lowland road (map area pixel-identical to `4bf865c`);
  control row and shelf (baseline reproduced the old `Drink (…)` truncation
  live, current tree renders every label whole across two runs at 51.8 dp of map
  cost). Greyscale twin for every frame; both device save slots restored MATCH
  after each capsule.

## Judgement calls a later session may reopen

- **Criterion 5** (art silent to screen readers) is proved by the corrected
  semantics-tree test only; a screenshot cannot show it.
- **Criterion 17's hitch clause** rests on an architect decision after
  `gfxinfo framestats` and `SurfaceFlinger --latency` both proved unusable on
  this emulator — closed on a consistent no-visible-hitch observation plus the
  structural fact that decoding happens once at boot and the shader rebuilds per
  plan adoption. Reopenable with profile-mode timeline evidence.
- **Forge and tavern illustrations are much brighter and warmer** than the rest
  of the dark UI, so each is a strong focal element on its screen. Never
  escalated to a decision; changing it is a re-derivation, not a code change.

## Traps for the next session

- `tool/derive-visual-assets.sh` normalizes each material sheet per file to
  standard deviation 0.05 around mean 0.50. **The mean is load-bearing** — it is
  the soft-light identity that keeps the authored layer luminance-neutral, which
  device evidence measured. Changing it invalidates accepted capsule B evidence.
- The masters are LFS-tracked now; a fresh clone needs LFS to regenerate derived
  assets, though the build itself does not.
- A bare `await warmUpArt()` in a widget test **hangs**; it needs
  `tester.runAsync`.
- A synthetic sheet in an authored-material test must be **two-tone**: a uniform
  mid-grey sheet is soft light's identity and turns tests green for the wrong
  reason.
- `Medium_Phone` must be user-started; tool-shell launch segfaults. Device saves
  live at `app_flutter/`, never `files/`.
- Fixtures must come from real game code at `visit: 1`. A level-0 hero cannot
  cross the Sea-Cave or Ruined Keep first floor alive; working seeds are 12 and
  47, and the road fixture uses world seed 10.
- Suites run per package directory; there is no root pubspec.

## Still open beyond Unit 10

- A controls unit for the unused `melee` and `back` icons — melee is a map tap
  and back is the platform `AppBar` affordance, so neither asset has a home.
- Portraits and room-background ratios remain unowned.
- Does old-wave m3-quests (M3Q, save v4, `../m3/LEDGER.md`) still run, and where?
- Deep history: `../legacy/LEDGER.md` (D1–D126) and `../m3/LEDGER.md`.
