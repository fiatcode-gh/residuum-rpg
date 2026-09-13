# Handoff record — M3C `m3-craft` (OPEN)

- Story: M3C — gathering nodes, materials as counters, Forge (smelt +
  temper) and Alchemist (brew) in both towns, Herbcraft + Blacksmith
  skills, saveVersion 3, bands as byte-identical controls.
- Branch: `m3-craft`. Worktree:
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-craft`
  @ base `83b5336` (created 2026-08-25 by the architect).
- Spec: `m3-craft-spec-M3C.md`. Prompt: `m3-craft-build-prompt.md`.
  Recon: `m3-craft-recon.md`. Decisions: D59 (forks + doctrine
  correction), D20.
- Baseline (architect-measured on `83b5336, D58): 1570 green
  (657/472/441); four band lines verbatim — CONTROLS this unit, must
  return byte-identical, and this time the claim survived the D56
  analysis at recon.
- Build session: `residuum-m3-craft [8d79bf]` (bg, user-created
  2026-08-25). Kickoff delivered 2026-08-25 (msg
  2812a3ed-16ab-40f3-a152-96058b518f9e). Refs go stale on session
  restart — re-list and rebind if delivery fails.
- Architect this wave: the background architect session of 2026-08-25
  (kickoff sender = reply target).

## Mid-flight questions and answers

- 2026-08-25, pre-code. Worker pre-declared nine deviations (baseline
  byte-identical, v2 fixture captured as its own pre-bump commit). All
  nine approved per **D60**: GatherKind rename (forced — NodeKind taken,
  verified at source), transactions in town.dart + rules in craft/,
  trainedIn() with a one-line step.dart fence extension, gatherSalt
  0x6A1E chosen by collision sweep (two candidates would have reddened
  the disjointness pin), gathering.dart content home, glyphs */" and
  markings ‡ ◆ ▮ ✿ checked against live widget sets, brewNumber
  confirmed. C1 attacked as instructed, no path found. Standing note
  sent: push+PR is pre-approved conditional on clean verification —
  the report must be self-sufficient.
- 2026-08-25, tenth pre-declaration: `sellPriceOf` temper term corrected
  to `temper * 2` (the spec's `* 3` was an architect arithmetic error —
  a tier adds exactly 2 to `worth` on either item kind, and `* 3` made
  a Legendary's first temper net-positive gold). Within D59's tuning
  latitude; confirmed, table in the trail.
- 2026-08-25, return. Worker reported done (12 commits, `ea6f05c,
  report + trail + 9 shots mirrored). Architect verified with own
  instruments and ACCEPTED (D61): 1790 green (my runs, matches), all
  four band lines BYTE-IDENTICAL, fences zero-diff, zero new draws, own
  sed reds five named smeltOre tests, fixture-first commit verified
  structurally, shot 07 read. Saveslot backups copied to the main
  repo's `docs/reports/device-saves/` (SHA256-verified). PR #12 opened
  on the user's conditional pre-approval. Awaiting the squash-merge —
  close-out steps listed in D61's UPDATE.


- 2026-08-29, CLOSED (D62): user squash-merged PR #12 as `54ec315`.
  Suites re-run green on `main` (762/530/498 = 1790), all four band
  lines byte-identical to the D58 baseline. Worktree and branches
  removed; saveslot backups safe in the main repo. Story closed.
  Session `residuum-m3-craft [8d79bf]` may be closed by the user.
