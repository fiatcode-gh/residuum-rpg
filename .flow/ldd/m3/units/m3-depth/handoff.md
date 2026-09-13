# Handoff record — M3X `m3-depth` (CLOSED — merged `b9d7c21` via PR #9, D48; folded into the ledger's Handoff history)

- Story: M3X — randomized depth per delve (D43 split, D46 forks).
- Branch: `m3-depth`. Worktree:
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-depth`
  @ base `59b91f1` (created by the architect 2026-08-24).
- Spec: `docs/epic/m3-depth-spec-M3X.md`. Prompt:
  `docs/epic/m3-depth-build-prompt.md`. Recon: `docs/epic/m3-depth-recon.md`.
- Build session: `residuum-m3-depth [857d3b]` (bg), launched by the user
  2026-08-24; kickoff pointer delivered by the architect (msg 509f8fb5…).
  No ruling vetoed at launch.
- Architect session: the 2026-08-22 background architect (this session).
- Rulings the user may veto before launch (D46 + spec rulings 1–8):
  derived-not-stored roll; core seam as optional deepest; GameState
  optional field; == bottom check; HUD getter route; bot threading;
  band re-pins with the same kit; per-dungeon table tiers (keep's
  two-notch loot rule extends).
- Known-in-advance: both themed bands and the two themed bottom-floor
  goldens re-pin by design; the crypt's line and assertions are
  character-frozen.

## Mid-flight exchanges

- 2026-08-24, pre-code. Worker confirmed the characterization net on
  unmodified code (1259; all four survivability lines verbatim;
  declaration counts match run counts exactly) and pre-declared FIVE
  deviations, all approved:
  1. `startRun` takes `DelveDepth = int Function(int visit)` not a bare
     int — the visit bump has ONE home; an int would smuggle a second
     copy of the rule into the caller (the `Dungeon` typedef's own
     shape).
  2. `delveDepth` answers `deepestDepth` for the crypt on an early
     return instead of the crypt never calling it — "never calls" became
     "never reaches the mix", the property that matters; one door for
     loadRun/startDungeonRunAt instead of two crypt branches. Architect
     rider: its own pin test (crypt → 5 across worlds × visits).
  3. `themedFloor`'s deepest REQUIRED (no silent-wrong-bottom).
  4. `FloorProblem` gains a REQUIRED fourth positional (an optional
     would let a custom validator ignore the exact hole this unit
     closes); cost test-only.
  5. `ThemedDungeon` carries inclusive `shallowestDelve`/`deepestDelve`.
  Plus public `depthSlot = 0x0DEE` (disjointness proof needs it from
  tests; road slots 1/2, market 0). Architect rider 2: a coherence test —
  stairs vanish exactly at delveDepth's answer, boss stands exactly
  there, GameState.deepest equals it.
  Worker's measured findings: mix uniform (∼1000/1000/1000 over 3000
  visits, six worlds); coverage all-values-by-visit-7 worst case, zero
  misses over 2000 worlds × 40 visits; ONLY TWO goldens move (both
  bottoms; first-floor goldens stable since 1 < deepest for 5/6/7 alike —
  the spec's four-golden reading was the architect's overcount); band
  directions predicted (cave 35/40 rises — 18/40 visit-1 delves get
  shallower; keep 31/40 falls — 24/40 get deeper; ordering gets easier).
  resumeRun's isEncounter non-carry confirmed correct and left alone.
- 2026-08-24, build returned (6 commits, 1296 tests). Architect
  verification: suites re-run 529/396/371 green (declaration counts
  match); crypt line character-identical; bands sea-cave 34/40
  (3:5 4:15 5:9 6:11), keep 31/40 (2:6 3:3 5:14 6:8 7:9), ordering held;
  core diff exactly the three sanctioned files; must-nots untouched;
  golden saves byte-identical; analyze/format clean from root (architect
  runs); architect sed on the crypt early return (constant → 4) reds
  THREE tests vs the worker's E5 one (sed-specific red sets — both
  recorded). Worker's mutation rows found two real defects mid-build
  (bot stall on short delves — 15 stalls before threading; copyWith
  deepest carry lost on descend — "depth 2/6" → "depth 2/5") and one
  harness hole (PumpedApp never reached loadRun; fixed by
  encode/decode-before-pump). Three spec claims corrected (row 3 no-op
  as written — real trap is vs the constant; G2's goldens-green now
  includes a themed-bottom red, better coverage; four goldens → two).
  ONE GAP raised: no screenshots on disk despite section-10 greyscale
  claims — retake/pull requested. CLOSED same day: 19 shots landed in
  docs/reports/shots/ (3 greyscale), section 10 carries the table;
  architect spot-read 17-grey-hud-cave.png. Worker also withdrew its E5
  "single guard" claim after re-running the architect's sed: its E5a
  mutant's replacement range CONTAINED the original value at the fixture
  seed (returned 5 at worldSeed 4242, where two of three guards look),
  so it under-reported the red set — coincidence-capable mutants are
  weak instruments; prefer constant shifts that cannot coincide.
  NEW MISMATCH from the spot-read: shot 17 shows 99976/100000 hp — a
  god-mode fixture, contradicting the disclosure "the state is exactly
  what a player would have; what is synthetic is the thumb".
  Reconciliation requested (report-accuracy fix; the load-bearing
  observations do not depend on hit points). DISCLOSURE to surface: the AVD pass
  overwrote the emulator's 2026-08-23 save.json + save-previous.json
  (user playtest state), unrecoverable — new ledger trap: copy device
  saves aside before pushing acceptance state.
