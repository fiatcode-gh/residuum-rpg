# Resume Visual Reboot

**Units 1–10 are merged to `main`. Unit 11 Task 01 is accepted; Task 02 is the
next action.**

## Exact state

- Local `main` is Unit 10's PR #20 merge commit
  `0692bbcce7570df988f6daab9b357a2557e58b39`. The Unit 10 acceptance evidence
  remains current; no application source changed after it.
- The Unit 11 external LDD bundle under `units/unit-11/` validates at that
  revision and every file in `SHA256SUMS.txt` matches. It is untracked
  architect state; no Unit 11 production change exists.
- Unit 11's contract is accepted as the prior user-approved WHAT: existing
  dungeon art only, map viewport only, recomposed wall/value/light/material/
  decoration/glyph presentation, with no topology, knowledge, interaction,
  RNG, core/content, save, asset-master or crawl-UI change.
- The execution-grade plan is explicitly user-approved for local implementation
  and verification within its accepted envelope. Remote publication or
  integration is not authorized.

## Exact next action

Dispatch a fresh `flow-plan-executor` for Task 02 on the existing
`residuum-visual-reboot-11` checkout. It consumes Task 01's accepted
style/adjacency seam and implements only authored material scale plus
deterministic decoration.

## Carry-forward locks

- Authored art changes appearance only: never topology, knowledge, interaction
  or game-state meaning. `MaterialPlan` and `GlyphCell` remain authoritative.
- Do not inspect unknown cells, light remembered terrain, consume gameplay RNG,
  move image decoding into a hot path or modify `packages/core` /
  `packages/content`.
- Keep the accepted masters under `art/visual-reboot/` read-only. The
  per-file mean in `tool/derive-visual-assets.sh` is load-bearing for
  soft-light neutrality.
- `Medium_Phone` must be user-started. Before any install, back up both device
  save slots under `app_flutter/` and restore them byte-identically afterward.
- Run formatter, analyzer and tests from `packages/app`; there is no root
  pubspec.
