# Handoff record — M3D `m3-dungeons` (CLOSED — merged `59b91f1` via PR #8, D45; folded into the ledger's Handoff history)

- Story: M3D — the sea-cave and the ruined keep (D35 split, D43 forks).
- Branch: `m3-dungeons`. Worktree:
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dungeons`
  @ base `bdb190b` (created by the architect 2026-08-22).
- Spec: `docs/epic/m3-dungeons-spec-M3D.md`. Prompt:
  `docs/epic/m3-dungeons-build-prompt.md`. Recon:
  `docs/epic/m3-dungeons-recon.md`.
- Build session: `residuum-m3-dungeons` (bg), launched by the user
  2026-08-23 as `[f509d7]`; kickoff pointer delivered by the architect
  (msg 83724010…). No ruling vetoed at launch. The session restarted near
  close-out — current ref `[dd4e6d]`; the old ref no longer resolves.
- Architect session: the 2026-08-22 background architect (this session).
- Rulings the user may veto before launch (D43 + spec rulings 1–7):
  hero-level save identity; dungeonFor with crypt pass-through; single
  ordered rumor pool; abandon-elsewhere confirmation; per-dungeon loot
  salt; fixture-kit bands; palette-as-additional-signal.

## Mid-flight exchanges

- 2026-08-23, pre-code. Worker confirmed baseline (1153; both
  survivability lines verbatim), confirmed four spec claims (trophy
  no-reshuffle proven empirically across seeds×depths×itemCounts; contract
  3 equivalence writable; ruling 1 sound — recon finding 2's "run-block"
  wording was wrong, hero-level is right; world-screen sketch correct),
  measured salts distinct + streams disjoint, and pre-declared THREE
  deviations. Architect approved all three:
  1. **DungeonSpawnTable (Weighted<CreatureSpec>) replaces Map<int,
     SpawnTable> for themed dungeons** — SpawnTable.rollCreature resolves
     via creatureById against the forbidden global bestiary; a themed
     entry would throw on first roll. ARCHITECT SPEC DEFECT (type named
     without checking the lookup coupling). Consequence accepted: the
     orphan test does NOT red on themed creatures; the generalization
     lands green-to-green with an extension mutation row (creature
     defined and placed nowhere). Architect verified the save path:
     actor_codec round-trips actors inline, no bestiary lookup on decode.
     Content-validation patterns (coverage/weights/refusal/roll-closure)
     carry onto the new type; bosses stay placed, never in tables.
  2. **HUD row, not app bar** — GameScreen has no AppBar; the dungeon
     name lands in the _HitPoints HUD row (game_screen.dart:113-115).
     ARCHITECT SPEC DEFECT (named a widget that does not exist).
  3. **Dungeon on GameBloc, not GameViewState** — every handler rebuilds
     the view state fresh, so a view-state field is the carry-landmine
     class on a run-constant value. Architect rider: the boot-resume path
     must set it too (D27 class), not only the enter path.
  Node ids locked: 'sea-cave', 'ruined-keep'. Glyphs c d e h D / b k m C.
  Worker proceeds: plan → characterization net → TDD.
- 2026-08-23, build returned (10 commits, head db066d4, 1259 tests) with
  one undeclared-but-ratifiable deviation (keep drop curve two notches
  richer, trail complete) and two ruling requests. Architect verification:
  suites re-run 515/380/364 green; all four survivability lines verbatim;
  core diff EMPTY; forbidden files untouched; row 2 re-run with own sed
  (8 red content / core green, revert clean); artifacts grepped
  (phone-size tests, litter pin, 40 shots incl. 4 greyscale).
  FOUND: analyze NOT clean project-wide — worker ran it from
  packages/app, which misses other packages' test dirs; 4 warnings
  (dead null-guards) in content test helpers, branch-introduced (main
  clean). Fix requested + report amendment. RULING 1: dangling
  [startDungeonRun] dartdoc in new_game.dart:108,127 → fix to name
  startDungeonRunAt; sanctioned second dartdoc-only change amending the
  spec must-not; content suite + survivability line re-quoted after.
  RULING 2: arrivingAt revealing adjacent dungeon nodes (verified at
  whereabouts.dart:171-176) stays — core is frozen this unit; follow-up
  logged; user told at ratification. Row-2 count reconcile asked (7 vs 8).
- 2026-08-23, fixes returned in 19ebf6b (11 commits): analyze clean from
  ROOT (architect re-ran), dartdoc repointed with strip-the-docs proof
  (architect re-ran the diff), row-2 count owned as 8 named tests (the
  count is a property of the sed — ^0x1 reds 7, ^0xFFFF reds 8). Worker
  self-flagged that ALL its earlier in-flight "analyze clean" claims were
  the narrow packages/app run. VERIFIED → D44. Worker's socket to the
  architect went stale once mid-close; report mirror on disk was the
  designed fallback and the re-sent summary matched the verified state.
  Report-only additions after verification: a follow-ups section (spec's
  four + five surfaced) and a no-deletion cross-check (test declaration
  counts: 1153 main → 1259 branch, independent of runner totals; every
  deleted test-file line audited as renames/migrations). Bands 35/40 +
  31/40 and push/PR await the user.
