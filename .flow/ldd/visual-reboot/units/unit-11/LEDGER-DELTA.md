# Visual Reboot — Ledger Delta for Unit 11

Reconcile against canonical `LEDGER.md` locally after freshness checks. Do not
blindly replace newer ledger content.

## Current state correction

Record that Unit 10 is merged:

- PR #20 `feat: authored art integration (visual reboot unit 10)` merged
  2026-09-17.
- Merge commit:
  `0692bbcce7570df988f6daab9b357a2557e58b39`.
- Unit 10 remains accepted; its authored-art integration contract is closed.

## New unit

Add:

| Unit | Dependencies | State | Verification | Notes |
| --- | --- | --- | --- | --- |
| Unit 11 — dungeon scene recomposition | Unit 10 | **contract approved; plan awaiting approval** | none yet | Existing approved dungeon art only; map viewport only; structural wall/value/light/material/decor/glyph recomposition; no new gameplay or assets |

## Decision log append

- 2026-09-17 — User reviewed post-Unit-10 device screenshots and confirmed the
  remaining gap to the approved mock is substantial. Fresh recon shows the gap
  belongs to renderer composition rather than a failure of Flame or Unit 10's
  asset pipeline.
- 2026-09-17 — User approved Unit 11 WHAT: dungeon scene recomposition, using
  existing approved dungeon art only, limited to the map viewport, preserving
  Unit 10 topology/knowledge/interaction/determinism contracts. New authored
  structural assets are deferred until device evidence proves they are needed.
- 2026-09-17 — Execution plan proposed with three sequential slices:
  structural light/wall mass -> material scale/decoration -> semantic glyph
  composition. Plan approval is still required before production execution.

## Provisional later units

Keep these directional only, not authorized:

- Unit 12 — crawl interface visual grammar;
- Unit 13 — town / room composition;
- Unit 14 — character / spells / pack composition;
- Unit 15 — integrated parity + evidence-backed remaining asset gaps.
