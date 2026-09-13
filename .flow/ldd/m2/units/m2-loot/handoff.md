# Handoff record — m2-loot (CLOSED 2026-08-21 — folded into LEDGER.md Handoff history, D12/D13)

- Story: M2L "Loot" (second of three M2 units, ledger D8/D11)
- Branch: `m2-loot`
- Worktree: `/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-loot`
- Base commit: `961dc46` (main, M2E squash)
- Build prompt: `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m2-loot-build-prompt.md`
- Build session: not yet created. User runs:
  `cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-loot && claude -n residuum-m2-loot --bg`
- Fallback report path: worker mirrors its verification block to
  `<worktree>/BUILD-REPORT.md`.
- Session: `residuum-m2-loot [59f9a2]` (bg), contacted 2026-08-21

## Mid-flight questions and answers

- 2026-08-21 worker confirmed baseline 212 green pre-change, then flagged
  three shape deviations before writing them; architect APPROVED all three:
  (1) `Loadout` value object, derivations pure over (Actor, Loadout) — the
  spec's GameState-shaped signatures could not express mid-monster-phase
  skill training; (2) additive baseline: Actor stats are the unarmed base,
  gear additive — saves the characterization layer, exactly one existing
  assertion strengthened (content_validation:334); (3) zero-dodge skips the
  dodge roll entirely to preserve the combat rng stream (else every seeded
  fight reshuffles). Riders: (3) must be a documented dartdoc argument; the
  Fleetfoot-bare-then-heavy exploit gets measured with numbers in the
  verification block. Also accepted: drop tables as data on GameState, split
  item-id namespaces, hp-clamp kept as non-load-bearing defence in depth,
  inline execution per M2E precedent (D9).
