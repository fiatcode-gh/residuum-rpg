# M2 Engine / Loot / Town / QoL — Decision Ledger

Complete the playable loop beyond the M1 crawl: the engine beneath it
(speed clock, flow-field chase, seeded floors), loot (items, affixes,
equipment, skills, potions), the town that closes the loop, and quality-of-life
(camera viewport, pack presentation, town gear). Governed by the canonical
design spec (`../../../docs/specs/2026-08-20-dungeon-game-design.md`) and `AGENTS.md`.

## Mode

- shared (tracked in git)

## Current state

- **closed** — all four units merged to `main` and accepted.

## Epic status

| Unit | Dependencies | State | Verification | Notes |
|---|---|---|---|---|
| m2-engine (M2E) | m1-crawl | merged — `618b13f` | suite green at merge | speed clock, flow-field chase, seeded floors |
| m2-loot (M2L) | m2-engine | merged — `d5dfe29` | suite green at merge | items, affixes, equipment, skills, potions |
| m2-town (M2T) | m2-loot | merged — `b0aea88` | suite green at merge | the town loop closes |
| m2-qol (M2Q) | m2-town | merged — `8719fc3` | suite green at merge; device playtest pending at close (follow-up 13) | viewport, pack presentation, town gear |

## Locked cross-unit contracts

- Everything M1 locked (state model, dependency rule, injected `Rng`) holds
  and binds all later units.
- Seeded floor generation: same seed → identical floors (determinism tested).

## Environment traps

- `flutter test` runs per package directory; this monorepo has NO root
  pubspec (proven later at M3I/D101, first hit during the M3 era — carried
  here because it binds every unit).

## Open questions

### User/product decisions

- M2Q viewport playtest verdict was still outstanding when M3 began
  (legacy follow-up 13). Any revival goes through the active epic's ledger.

### External dependencies

- none.

## Decision log

Append-only. Full D-number history: `../legacy/LEDGER.md`.

- 2026-08-20 — M2 split into engine/loot/town units (E/L/T) plus a later
  QoL unit: each milestone-sized story got its own build branch.
  Consequence: four unit dirs, sequential dependency chain.
- 2026-08-21 — QoL unit added from playtest feedback rather than folding
  into m2-town: viewport, pack presentation, town gear screens.

## Verification receipts

- All four merges verified at their time by the architect's own suite runs
  (see `../legacy/LEDGER.md`, D-numbers for M2E/M2L/M2T/M2Q). Current hashes
  above are post-GitHub-rewrite; pre-rewrite PR citations are stale (D96).

## Corrections to inherited assumptions

- See `../legacy/LEDGER.md` — M2-era corrections are recorded there with
  their evidence.