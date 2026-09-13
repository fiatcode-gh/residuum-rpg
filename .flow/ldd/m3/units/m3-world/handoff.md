# Handoff record — M3W `m3-world` (CLOSED — merged `958ef98` via PR #6, D42)

- Story: M3W, branch `m3-world, worktree
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-world,
  base `844376f`.
- Spec: `m3-world-spec-M3W.md`. Prompt: `m3-world-build-prompt.md`.
  Recon: `m3-leave-recon.md` (findings 5–9). Absolute under `docs/epic/`.
- Build session: `residuum-m3-world` — launch:
  `cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-world && claude -n residuum-m3-world --bg`
  Ref: `residuum-m3-world [9758de]` — user-launched; kickoff sent
  2026-08-22.
- Baseline: 897 (408/225/264), 24/40 exact, histogram 1:1 2:9 3:6 5:24,
  fleetfoot 7/40 — architect-measured 2026-08-22 on `main` @ `844376f`.

## Mid-flight Q&A

- 2026-08-22, worker pre-declaration (before code); baseline reproduced
  exactly (897; 24/40 + histogram; 7/40; analyze clean). Nine items, ALL
  APPROVED:
  1. SPEC DEFECT (architect's): "897 stays green" is unachievable
     literally — the unit relocates the fork/door surfaces, so ~20 widget
     tests move with them (suspend_door 13, boot_wiring 2, roster_session
     ~8). Ruling: relocate not delete; per-file before/after audit in the
     report.
  2. WORKER-FOUND DESIGN DEFECT: `_rosterChose`'s generation bump does not
     clear pushed routes — with the town on a pushed route, choosing from
     the roster would leave a stale town route holding a closed TownBloc
     over the new session. Fix approved: the Heroes door moves to the
     WORLD screen (roster only ever pushes over `/`); invariant dartdoc'd
     at the bump site + widget-pinned. Promote to ledger at verification.
  3. Custody: TownBloc keeps Profile; WorldBloc owns Whereabouts;
     autosaver gains watchWorld; tavern = one core function returning both
     halves, screens move values only.
  4. Encounter rides a THIRD TownViewState field (never `run, never
     `suspended`); the encounter GameBloc is never watched. RIDER 1:
     explicit negative pin — encounter emissions write NOTHING to disk.
  5. Road encounters carry profile.visit through (no bump — a bump would
     reshuffle the crypt, clear the shelf, and silently break the camped
     hero's resume precondition). RIDER 2: extension mutation row — a
     visit-bumping wrapper must redden the camped-resume/shelf tests.
  6. (a) Road death wakes at home; crypt death unchanged (world at crypt
     node). (b) Road death KEEPS a standing camp — the penalty is pack and
     purse, the camp is dungeon progress; precondition survives (endRun
     keeps the unbumped visit), argued in dartdoc/test.
  7. Attack rows closed with sweeps: border leak 0/2000 floors (row 5
     truthfully weak, row 4's control real; encounter map border walkable
     BY DESIGN); travel-seed collisions 0 vs floors and market.
  8. C3 re-pin sites found pre-salt, incl. the vacuous
     `isNot(contains('market-0-potion-1'))` that would have gone
     green-and-blind.
  9. `world` block required on disk, defaulted in Dart (merchant
     precedent).
- 2026-08-22, PAUSE (user quota, worker-side): branch parked green at
  `9abf403` (b71f911 characterization → b4aafc5 core world/ → 9abf403
  report mirror); 476/234/264; diff = core world/ + exports only. C1–C3
  passed at base first; C1 exposed relation-only generator tests → byte
  literals added. Resume point: BUILD-REPORT.md section 8 (encounter map
  generator → flee rule → content → save reshape → app rework → mutation
  table → AVD).
- 2026-08-22, mid-flight rulings (D40): a fight costs the day and none of
  the distance (flee is never progress); beginTravel refuses non-adjacent
  destinations — travel is chosen leg by leg. Both approved as built.
