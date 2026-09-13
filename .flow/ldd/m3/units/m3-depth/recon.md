# Recon — m3-depth (M3X): randomized depth per delve

Date: 2026-08-24. Architect recon on `main` @ `59b91f1` (M3D merged). One
read-only agent swept the threading; the three load-bearing claims
re-verified by the architect at source (generator seam, copyWith carry, bot
win condition).

## VERDICT

The unit is real and smaller than feared: `step()` never consults
`deepestDepth` — descent is stairs-driven, so the whole "where is the
bottom" rule lives in the floor builder and validator. The per-run value can
be **derived, not stored** (a pure function of the dungeon salt and the
visit), so the save format does not move. Two traps found: depth 6 today
generates a SILENT dead-end floor (no stairs, validator content), and
`themedFloor`'s `bottom = depth >= deepestDepth` would place a boss and
trophy on EVERY floor from 5 down in a 7-deep keep. The loudest cost is
re-pinning: both themed bands and their histograms move by construction.

## State verified before measuring

- `main` = `59b91f1, suites 515/380/364 = 1259 green, all three
  survivability lines verbatim (measured this session at D45 close-out).
- No worktrees, no build sessions alive.

## The threading map (agent-swept, architect-verified at the marked sites)

- `deepestDepth` production readers — SIX sites, three files (that is all):
  `generator.dart:161` (validator ✓ read), `:245` (stairs placement
  ✓ read), `:135` (doc), `dungeons.dart:204` (themedFloor bottom check), `game_screen.dart:161` + `:163` (HUD). `step.dart`: ZERO — `_arriveBelow`
  builds whatever floor the stairs lead to.
- `GameState` construction: 5 production sites (startRun, resumeRun,
  newGame, loadRun, startRoadEncounter). `copyWith` hard-carries run
  constants (✓ read — the `worldSeed`/`visit`/`isEncounter` pattern), so an
  **optional-with-default field `deepest = deepestDepth`** costs one field +
  one copyWith line; road encounters and every fixture keep compiling.
- HUD route: `_whereabouts` reads `state.depth` + the const + the bloc's
  `dungeon`; a `GameViewState` getter (`game.deepest`) reaches the widget
  with no bloc-constructor change.
- Bot: ONE shared `won` (`depth >= deepestDepth && alive,
  survivability_test.dart:34 ✓ read) and ONE shared break (`:146`) serve
  all three bands. Themed bands enter via `startDungeonRunAt` with the
  `_kitted` fixture; pinned maps `_seaCaveDepths`/`_keepDepths` key by
  FINAL depth, so variable bottoms change the histogram keys by
  construction.
- Save: nothing stores a total anywhere; run block carries depth/worldSeed/
  visit, hero level carries `dungeon`. `floors` is a sparse map with no
  5-assumption. `deep_run.dart`'s loop is already generic.
- World layer: zero depth knowledge (core world/ and app world/town clean).
- One stale doc: `grid_geometry.dart:9-12` prose says "a depth-five floor
  is 32 by 20" — right for 5, silent about 6/7 (34×21, 36×22). The camera
  clamps to map edges; no code change, doc will read wrong.

## Traps (the reason the spec must exist)

1. **Depth 6 is a silent dead end today.** `generateFloor(seed, 6...)`
   succeeds: size formula fine, `depth < deepestDepth` false → no stairs
   down, validator's `depth >= deepestDepth` branch happily accepts the
   stairless floor. No throw, no diagnostic. Both generator sites AND the
   `FloorProblem` typedef (`(floor, depth, monsterCount)` — no room for a
   bottom flag, ✓ read) must widen to a per-floor "is this the bottom"
   input.
2. **`themedFloor`'s bottom check is >=, not ==.** With a 7-deep keep,
   floors 5, 6, 7 would EACH get a boss swap and a trophy. Must become
   "depth == the delve's deepest".
3. **Content throws first, usefully:** table helpers refuse depth 6/7
   (`no spawn table for this depth`) — the sea-cave needs `6:` entries,
   the keep `6:` and `7:` (spawn + drop, ~29 lines per drop table). The
   crypt needs nothing. `dungeons_test.dart:7` hardcodes
   `_allDepths = [1,2,3,4,5]` and the validation sweeps assume 1..5 —
   they become per-dungeon.
4. **Both themed bands re-pin by construction** (35/40 and 31/40 die with
   this unit by design — the M3R precedent, stated up front). The crypt's
   24/40 + histogram must NOT move: crypt stays fixed at 5, never passes
   the new parameter, byte-identical by construction; the promoted
   assertions are the guard.

## Where the roll should live (architect ruling material)

Derive, never store: `deepest = lowest + mix(worldSeed ^ dungeonSalt(node),
visit) % span` (a `floorSeed`-style mix in a dedicated slot, the market's
purpose-slot trick). Same save document byte-for-byte; `loadRun` recomputes
exactly as it already recomputes `buildFloor` and `dropTables`. Rolling from
the crawl's own rng instead would need a new save key (goldens move) and
would let the depth draw perturb the floor streams — rejected.

## Proposed shape of the work

One unit `m3-depth` (M3X, S/M), branch `m3-depth, sanctioned CORE edits
(unlike M3D): `generateFloor` + validator + `FloorProblem` widen by an
optional bottom input defaulting to today's behavior; `GameState.deepest`
optional-with-default; `dungeonFor`/`themedFloor` thread the rolled value;
HUD reads it; bot `won`/break read the run's own deepest; sea-cave 6: and
keep 6:/7: tables; bands re-measured and re-pinned; crypt untouched on
every path.

## What this recon did NOT check

- No device run; all app claims from code and suites.
- The agent's unquoted tails; architect re-verified the generator seam,
  copyWith carry, and bot win condition only.
- Whether depth-6/7 floors are FUN at 34×21/36×22 with a 36dp camera —
  playtest territory.
- The exact distribution feel (uniform vs weighted) — a content number.
