# Handoff record — m2-engine (CLOSED 2026-08-20 — folded into LEDGER.md Handoff history, D9/D10)

- Story: M2E "Engine" (first of three M2 units, ledger D8)
- Branch: `m2-engine`
- Worktree: `/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-engine`
- Base commit: `be1da0a` (main, M1 squash)
- Build prompt: `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m2-engine-build-prompt.md`
- Build session: not yet created. User runs:
  `cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-engine && claude -n residuum-m2-engine --bg`
  (`--bg` is viable again — device commands are sandbox-excluded since 2026-08-20, D8)
- Fallback report path if SendMessage delivery fails again (follow-up 7):
  worker mirrors its verification block to `<worktree>/BUILD-REPORT.md`.
- Session: `residuum-m2-engine [a28cac]` (bg), contacted 2026-08-20

## Mid-flight questions and answers

- 2026-08-20 worker verification block received over the channel (delivery
  worked this time; worker reports the PREVIOUS architect socket had gone
  stale — likely the M1 failure cause too). Mirrored to BUILD-REPORT.md.
- Worker asked: balance tuning now or defer? → Architect: DEFER to m2-loot;
  measured figures become binding inputs there.
- Worker asked: confirm ActorNoticed definition → confirmed (invisible at turn
  start, visible at turn end, one event per monster, list order).
- Architect asked: claimed bipartiteness dartdoc correction absent from tree —
  lost or elsewhere? Awaiting reply.
