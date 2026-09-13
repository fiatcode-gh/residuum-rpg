# Handoff record — M3L `m3-leave` (VERIFIED D37 — awaiting user PR/merge)

- Story: M3L, branch `m3-leave, worktree
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-leave,
  base `f7bd6b1`.
- Spec: `m3-leave-spec-M3L.md`. Prompt: `m3-leave-build-prompt.md`.
  Recon: `m3-leave-recon.md`. All absolute under `docs/epic/` (local mode).
- Build session: `residuum-m3-leave` — LAUNCHED BY THE ARCHITECT this round
  on the user's advance authorization (D35 session note); `--bg`.
  Ref: `residuum-m3-leave [7aba1c]` — kickoff sent 2026-08-22
  (msg d673ea8e-fac1-4705-83a8-b160b82e1ff9).
- Architect session: the background job that sent the kickoff (user away;
  reply-to-sender is the binding).
- Baseline for the unit: 829 (395/212/222), survivability 24/40 exact,
  histogram 1:1 2:9 3:6 5:24, fleetfoot 7/40 — architect-measured
  2026-08-22 on `main` @ `f7bd6b1`.

## Mid-flight Q&A

- 2026-08-22, worker pre-declaration (before any code), baseline re-measured
  in the worktree and identical to the architect's (829; 24/40; 7/40;
  analyze/format clean). Seven items, ALL APPROVED:
  1. SPEC DEFECT (architect's): the endRun carry is the whole Actor
     (`hero: state.hero`), not "hp" — position and energy come home too and
     always have. Verified by the architect at run_boundary.dart:90-96.
     resumeRun injects `suspended.hero.copyWith(hp: profile.hero.hp)`.
  2. SPEC DEFECT (architect's): `GameState.copyWith` has no gold parameter
     (verified :170/:202) — resumeRun constructs a full GameState (~25
     lines), core diff still confined to run_boundary.dart.
  3. `TownViewState.suspended` separate from transient `run, mutually
     exclusive — architect rider: pin the exclusivity with a named test.
  4. `inside` as named-required param at the update seams; constructor
     default `false` (MerchantVisit.none precedent); strictness at decode.
  5. Doors document preconditions in dartdoc, no asserts (endRun precedent,
     one assert in 123 files).
  6. `RunEnded` keeps `died`; alive branch unreachable from UI; M3W
     follow-up: the overworld reintroduces an alive end.
  7. Autosaver learns `inside` from town emissions
     (`_run = state.run ?? state.suspended, `_inside = state.run != null`;
     watchGame sets true; seeded from boot). Worker claims no wrong window
     across all six transitions and will MEASURE it — architect rider:
     also measure that leave→resume→leave produces no double-write
     (watchGame subscription stacking).
  - Worker also verified the identity theorem is feasible (codec iterates
    enum values, insertion order cannot leak) and the visit invariant has
    no violating path. Roster "below (depth N)" wording kept for camped
    heroes, device-checked.
- 2026-08-22, mid-flight: worker device-found that the spec's unconditional
  merchant clear on suspend resurrects stock on resume→leave (visit did not
  move). SPEC DEFECT (architect's, D35 ruling). Fix accepted as built
  (3a0c890, conditional clear + stillOnTheShelf on the kept path, two
  red-first tests). PROMOTED to ledger decision D36 before the worker
  continued; invariant recorded for every future door.
