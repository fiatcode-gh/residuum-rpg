# Story spec — M3X `m3-depth`: randomized depth per delve

Unit `m3-depth, branch `m3-depth, base `59b91f1` (main, post-PR #8).
Scope locked by D43 and D46; recon in
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-depth-recon.md`.
Read the recon before the code. Baseline: 515 core + 380 content + 364 app =
**1259 green**; survivability lines verbatim:
`24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24` (asserted in code), `greedy build: 24/40 won; fleetfoot-first build: 7/40 won, `sea-cave: 35/40 won (87.5%), stalled 0, died at 3:5 5:35, `ruined keep: 31/40 won (77.5%), stalled 0, died at 2:6 3:3 5:31`.

## Goal

A delve's depth becomes part of its roll: entering the sea-cave lays out a
4-, 5-, or 6-floor dungeon and the ruined keep a 5-, 6-, or 7-floor one —
uniform over the range, deterministic per (world, dungeon, visit),
recomputable on load, shown in the HUD ("The Sea-Cave — depth 3/6"). The
crypt stays fixed at 5 on every path, byte-identical. The boss and trophy
land on the rolled bottom floor and ONLY there.

## Scope fence (what this unit is NOT)

- No save-format change of any kind. The roll is derived; nothing new is
  written to disk. Goldens must not move.
- No crypt change: `newGame, `buildFloor, `residuumDungeon, the global
  tables, and the crypt's figures are untouched; the crypt never passes the
  new parameters.
- No balance retune of existing tiers: the new depth-6/7 tables are new
  content (free with a trail); depths 1–5 of every dungeon stay as merged.
- No camp-expiry, no discovery change (follow-ups 24/25 still parked).
- No distribution shaping (uniform only); no per-dungeon width/height
  changes beyond what the existing size formula already does at 6/7.

## Shape — precedents to follow (read them, do not reason by analogy)

- **Optional-with-default on GameState:** `isEncounter`
  (`game_state.dart:53, `:176`) — one field, one dartdoc, one copyWith
  pass-through; road encounters and every fixture keep compiling.
- **The derived-not-stored rule:** `loadRun` already re-derives
  `buildFloor` and `dropTables` from (dungeon, worldSeed, visit)
  (`run_codec.dart:88, `:101, with the doc argument at `:66-71`). The
  delve's deepest joins that list.
- **The purpose-slot mix:** `ambushGroundSeed` (`world.dart:34-35`) and the
  market (`economy.dart:114`) — `floorSeed(worldSeed ^ salt, slot, visit)`
  with the depth argument used as a purpose, not a depth.
- **Widening a core seam without moving outputs:** `generateFloor`'s
  `itemCount` (M2L) — an optional parameter whose default reproduces the
  old behavior byte-for-byte, guarded by the characterization goldens.

## Design rulings (architect authority; the user may veto before launch)

1. **The roll:** `delveDepth(node, worldSeed, visit)` in content —
   `lowest + floorSeed(worldSeed ^ dungeonSalt(node), _depthSlot, visit) %
   span, `_depthSlot` a new purpose slot distinct from the ground/fight
   slots. Sea-cave lowest 4 span 3; keep lowest 5 span 3. The crypt never
   calls it.
2. **Core seam:** `generateFloor` gains optional `{int deepest =
   deepestDepth}` — the honest input is the bottom's depth, not a boolean
   is-this-it flag — and `FloorProblem` widens to carry it. Defaults
   reproduce today's behavior exactly; the characterization goldens are
   the proof. The validator's two branches and the stairs placement read
   the parameter; `deepestDepth` remains as the default and the crypt's
   value.
3. **GameState:** optional-with-default `deepest` (`= deepestDepth`),
   carried hard by copyWith like `worldSeed`. `startRun` gains an optional
   `deepest` it passes through; road encounters never set it (a road has
   no bottom; the field is meaningless there and stays at its default,
   which nothing on the road reads).
4. **themedFloor:** takes the delve's deepest; `bottom` becomes
   `depth == deepest` (the >= trap dies); asks `generateFloor` for
   stairs-down on every floor above it. `dungeonFor(node, worldSeed)`
   computes the roll per visit and closes over it.
5. **HUD:** `GameViewState` gains `int get deepest => game.deepest;` and
   `_whereabouts` reads it in place of the const. Encounters keep "The
   road" untouched.
6. **Bot:** `_Outcome.won` and the `_botPlay` break read the OPENING
   state's `deepest` (threaded into `_Outcome`), not the const. The crypt
   bot's behavior is provably unchanged (its deepest is the default 5).
7. **Bands re-pin, same fixture kit:** worker measures sea-cave and keep
   fresh (histograms now key by variable final depths), pins exact wins +
   histogram + the keep-harder-than-cave ordering, band 0.50–0.95 holds.
   The crypt's assertions must not move — they are the identity guard.
8. **Tables:** sea-cave gains `6:` spawn + drop; keep gains `6:` and `7:`
   of both. Tier difficulty continues each dungeon's own curve (the keep's
   two-notch loot rule from D44 extends to its new tiers). Validation
   sweeps and `_allDepths` become per-dungeon (each dungeon's tables cover
   exactly 1..its highest possible depth, refusal outside).

## New and changed files

Core (sanctioned this unit): `dungeon/generator.dart` (optional `deepest`
on `generateFloor` + `FloorProblem` + validator + stairs placement), `engine/game_state.dart` (`deepest` field + copyWith), `town/run_boundary.dart`
(`startRun` optional `deepest`; `resumeRun` carries it from the suspended
state).
Content: `dungeons.dart` (`delveDepth, `_depthSlot, threading in
`dungeonFor`/`themedFloor`), `sea_cave.dart` (+`6:` tables), `ruined_keep.dart` (+`6:`/`7:` tables), `save/run_codec.dart` (`loadRun`
recomputes and passes `deepest`).
App: `game/game_bloc.dart` (view-state getter), `game/game_screen.dart`
(HUD reads the getter).
Tests: per plan; the two themed characterization bottom-floor goldens
re-pin at each dungeon's visit-1 rolled depth (by hand, from real output).

## Per-item contracts

1. `delveDepth`: deterministic (same triple → same depth, tested); varies
   across visits (some pair of visits in a sweep differs, tested); range
   bounds inclusive and never exceeded over a sweep (tested per dungeon);
   crypt has no path into it.
2. `generateFloor(deepest: …)`: floors above the delve's deepest have
   stairs down; the deepest has none; the validator refuses the opposite
   in BOTH directions with a sentence naming the depth and the bottom —
   the silent depth-6 dead end becomes impossible by contract. Defaults:
   byte-identical outputs (existing goldens are the proof, untouched).
3. `themedFloor`: exactly one boss and one trophy on the rolled bottom,
   ZERO on every other floor — including floors 5 and 6 of a 7-deep keep
   (the trap test, named).
4. Suspend/resume/load: a camp in a 6-deep sea-cave resumes with
   `deepest == 6` after app kill (recomputed, not read); the suspend
   theorem extends (round-trip identity); goldens byte-identical (no new
   keys — assert the encoded string of a deep-delve camp contains no
   "deepest").
5. HUD: "The Sea-Cave — depth 3/6" when the roll is 6; crypt reads
   "The Crypt — depth 3/5" exactly as today; road unchanged.
6. Bands: printed lines updated; exact pins + histograms + ordering
   asserted; crypt lines and assertions character-identical to baseline.

## Behaviour arguments that must land in documentation

- Why the roll is derived and never stored (the save stays byte-stable;
  re-derivation is the codec's own precedent) — on `delveDepth`.
- Why the crypt never calls the roll (identity by construction; the
  promoted assertions are the proof) — on `dungeonFor`'s existing doc,
  extended.
- Why `deepest` defaults on GameState (a road has no bottom; fixtures
  should not have to invent one) — on the field.
- Why the bottom check is `==` not `>=` (the 7-deep keep would crown
  three bosses) — on `themedFloor`.

## Test plan

### Characterization first (must pass against UNMODIFIED code)

- The existing crypt goldens, the promoted survivability assertions, and
  the M3D themed characterization tests ARE the net. Run and quote before
  the first change. The two themed bottom-floor goldens will be RE-PINNED
  when the roll lands (their visit-1 depth moves) — re-pin by hand from
  real output, in the same commit as the roll, with the old pin quoted in
  the commit message.

### Mutation table (run on COMMITTED code; both halves; extend it)

| # | Mutation (architect re-runs at least one with own sed) | Expected |
|---|---|---|
| 1 | `delveDepth` returns `lowest` always | variance test red (content); bands red (histograms carry depths above lowest) |
| 2 | `delveDepth` drops the `% span` clamp | range-bounds sweep red |
| 3 | themedFloor bottom check back to `>=` | one-boss-only trap test red (7-deep keep) |
| 4 | generator places stairs on the deepest (`<=` for `<`) | validator refusal test red + themed determinism red |
| 5 | validator accepts a stairless floor above bottom | refusal-in-both-directions test red |
| 6 | `loadRun` passes the default instead of recomputing | resume-deep-camp test red (app or content) |
| 7 | HUD reads the const again | widget/bloc HUD test red on a 6-deep delve |
| 8 | bot `won` reads the const | keep band red (a 7-deep win at depth 6 counted as won) |
| G1 | crypt path passes `deepest: 5` explicitly | ALL crypt pins + 24/40 + goldens GREEN (proves the default IS 5 — truthful weak row, say so) |
| G2 | sea-cave depth-6 spawn weights tuned | crypt assertions + goldens GREEN; sea-cave band re-measured |

Sequencing: rows 1–2 need the roll landed; row 3 needs a keep table at 7;
G2 requires reverting the tune after measuring.

## Hazards

- Every ledger environment trap, verbatim in the build prompt.
- The themed characterization re-pins are BY HAND from real output (D29);
  quote old and new in the commit.
- `dungeons_test.dart:7` `_allDepths = [1,2,3,4,5]` and the 1..5
  validation sweeps go per-dungeon — red-first where the new tiers land.
- `grid_geometry.dart:9-12` prose ("a depth-five floor is 32 by 20") goes
  stale at 6/7 — correct the doc line, no code change.
- The bands' `_depthsReached` keys by final depth: expect new histogram
  keys (a 4-deep cave win keys at 4). The printed line format stays.
- Depth-7 floors are 36×22 with a fixed 36dp camera — nothing breaks
  (camera clamps), but the AVD pass should walk one deep floor and look.

## Must-not list

- No save key, no golden-save change, no version bump.
- No edit to `newGame, `buildFloor, `residuumDungeon, the crypt tables, `step.dart, `economy.dart, `bestiary.dart`. `spawn_tables.dart` /
  `drop_tables.dart` byte-untouched.
- The crypt's survivability assertions and printed line are
  character-frozen; any diff there is a stop-and-report.
- No hue-only signal; no tooling on golden literals; no unseeded Random;
  no body comments; nothing committed under `docs/epic/` or `docs/reports/`.

## Follow-ups to log (do not do them)

- Distribution shaping (weighted rolls) if uniform feels flat in play.
- Depth-range display on the world screen BEFORE entering (the map could
  say "4–6 floors") — UI sugar over `delveDepth`'s bounds.

## Definition of done

1. Suites green in the worktree, counts quoted (≥ 1259 + new; deletions
   only where this spec names re-pins).
2. Crypt survivability line and assertions CHARACTER-IDENTICAL to
   baseline; new themed lines printed, pinned (wins + histogram +
   ordering), inside 0.50–0.95, figures reported for ratification.
3. Diff scope: core confined to the three sanctioned files;
   `git diff main --name-only` over the must-not files empty; no pubspec
   change; goldens (save) byte-identical — quoted.
4. Mutation table run on committed code, both halves, extensions
   reported.
5. AVD pass (mandatory): enter the sea-cave on a visit that rolls ≠ 5
   (derive the visit from the roll — identifiers pasted), HUD shows the
   rolled total, walk one deep keep floor, camp in a 6-deep delve, kill
   the app, resume, confirm the same bottom; greyscale shot of the HUD.
6. Analyze from the WORKTREE ROOT (quote the pwd) and format clean,
   project-wide (D44 doctrine).
7. Report mirrored to `docs/reports/BUILD-REPORT.md`; plan in
   `docs/plans/`.
