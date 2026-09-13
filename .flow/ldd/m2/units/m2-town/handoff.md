# Handoff record — m2-town (CLOSED 2026-08-21 — folded into LEDGER.md Handoff history, D15/D16)

- Story: M2T "Town" (last of three M2 units, ledger D8/D14)
- Branch: `m2-town`
- Worktree: `/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-town`
- Base commit: `69d55e4` (main, M2L squash)
- Build prompt: `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m2-town-build-prompt.md`
- Build session: not yet created. User runs:
  `cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-town && claude -n residuum-m2-town --bg`
- Fallback report path: worker mirrors its verification block to
  `<worktree>/BUILD-REPORT.md`.
- Session: `residuum-m2-town [b1dd7c]` (bg, relaunched after the interactive
  session's approval gate expired the first handoff), contacted 2026-08-21

## Mid-flight questions and answers

- 2026-08-21 worker pre-declared FOUR shape deviations before planning;
  architect approved all: (D-1) `endRun(entered, state, died)` — spec was
  self-contradictory, bank deliberately outside GameState yet demanded back;
  (D-2) FloorMemory.stairsUp nullable (floor 1); (D-3) startRun takes a
  `Dungeon` typedef, visit bump stays in core (mutation row 3 preserved);
  (D-4) dedicated salted marketTable instead of depth drop tables. Confirmed
  the Profile.hero hp annotation reads as fresh-profile-only (hp carried
  honestly; the inn is the healer). Worker's claim-checks accepted: energy
  freeze/restore banks nothing (zeroing would gift a turn — dartdoc'd);
  explored-per-floor has zero casualties; death-heal ordering safe. Rider:
  the descend-ascend bounce is harmless only while nothing regenerates —
  condition to be stated in dartdoc. QOL note logged: no equip screen in
  town.
- 2026-08-21 handoff message HELD for recipient-user approval — the session
  is interactive, and cross-session messages into an interactive session
  need the local user's nod (bg sessions receive directly). User asked to
  approve it in that terminal. This also likely explains M1's undelivered
  messages better than the stale-socket theory.
