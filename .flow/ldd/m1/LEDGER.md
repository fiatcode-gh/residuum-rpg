# M1 The Crawl — Decision Ledger

Build a playable glyph dungeon crawl in the empty repository, per the
canonical design spec (`../product/2026-08-20-dungeon-game-design.md`) and
`AGENTS.md` conventions. Single-unit milestone: the crawl loop end to end.

## Mode

- shared (tracked in git)

## Current state

- **closed** — the unit below is merged to `main` and accepted. No in-flight
  work. Measurements carried forward are historical; re-measure on `main`
  before relying on them.

## Epic status

| Unit | Dependencies | State | Verification | Notes |
|---|---|---|---|---|
| m1-crawl (M1) | none (empty repo) | merged — `10c1d18` | full test suite green at merge; device/Chrome visual pass | spec/recon/plan in `units/m1-crawl/` |

## Locked cross-unit contracts

- Monorepo layout `packages/{core,content,app}` with the dependency rule
  `app → content → core`; `core`/`content` never import Flutter (AGENTS.md).
- Immutable game state; the only mutation path is
  `step(state, action) → (state, events)`; events drive log/UI/quests.
- No global randomness: every random decision draws from an `Rng` in state.

## Environment traps

- Learned at M1 and still true: the toolchain scaffolds and tests Dart
  packages headlessly; visual verification needs Chrome or a device.

## Open questions

### User/product decisions

- none open — closed epic.

### External dependencies

- none.

## Decision log

Append-only. Supersede old decisions; do not rewrite history. The full
per-unit decision history (D-numbers) lives in `../legacy/LEDGER.md`; the
entries below are decisions a future architect still needs.

- 2026-08-20 — M1 built as one unit (the whole crawl loop) rather than
  split: milestone scope fit one build branch. Consequence: `units/m1-crawl/`
  is the only unit spec in this epic.
- 2026-08-20 — headless-first verification: logic verified by pure tests,
  visuals verified on Chrome/device only. Reaffirmed by every later unit.

## Verification receipts

- m1-crawl — merged as `10c1d18` ("feat: M1 The Crawl — playable glyph
  dungeon crawl"); test suite green at merge. Post-GitHub-rewrite hash; the
  original pre-rewrite PR/hash citations in the legacy ledger are stale (D96).

## Corrections to inherited assumptions

- None recorded for this epic beyond the legacy ledger's own record.