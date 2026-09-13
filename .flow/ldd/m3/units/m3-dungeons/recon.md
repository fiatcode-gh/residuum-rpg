# Recon — m3-dungeons (M3D): sea-cave + ruined keep, per-node salts, light bosses, per-dungeon bands

Date: 2026-08-22. Architect recon for the M3D spec, per D35 scope and the
`m3-leave-recon.md` seeds (findings 5–6, 8–10). Three read-only agents fanned
out (generation/salts, content tables/theming, survivability harness); every
load-bearing claim below re-verified by the architect at source.

## VERDICT

The D35 scope is real and buildable as one unit. Two findings reshape the
spec: **the exact 24/40 crypt pin exists nowhere in code** (the only coded
guard is the 50–95% band; the figure and histogram are print-only), and **a
camped hero's dungeon is unrecoverable today** — the run block carries no
dungeon identity and `world.at` for a camped hero is a town, so the identity
MUST be written into the run block (one more sanctioned v1 reshape).

## State verified before measuring

- `main` @ `bdb190b` (chore PR #7 merged this session; BUILD-REPORT.md
  confirmed untracked, `.gitignore` carries `docs/reports/`).
- Nothing in flight; no build sessions alive (peer list checked).
- Flutter 3.47.0, no fvm (unchanged).

## The measurement

- Suites re-run by the architect on `bdb190b`: **515 core + 300 content +
  338 app = 1153 green**.
- The survivability suite ran green inside the content run — the band
  assertion (0.50–0.95) held. The exact figure was NOT re-read from stdout
  this session; the spec's verification block must require the printed line
  `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24` verbatim.
- Survivability cost: the whole content suite is ~5 s; the bot is most of
  it (~200 crawls). Two more dungeons' bands roughly triple that — still
  cheap, stays in the normal run.

## Is each inherited gate real?

Seeds from `m3-leave-recon.md, re-checked at source on `bdb190b`:

- **Finding 5 (floorSeed has no dungeon slot): TRUE.**
  `floorSeed(int worldSeed, int depth, int visit)` —
  `packages/core/lib/src/dungeon/generator.dart:20-27, architect-read.
  Callers fold identity into `worldSeed` by XOR before the call (market,
  travel, ambush all do); that is the convention, not a fourth parameter.
- **Finding 6 (one-dungeon assumptions): TRUE, sharpened.**
  `loadRun` still hardcodes `buildFloor: residuumDungeon(worldSeed)(visit)`
  (`packages/content/lib/src/save/run_codec.dart:78, architect-read).
  `deepestDepth = 5` is a core const with exactly four production readers
  (generator validator ×2, generator placement, app HUD
  `game_screen.dart:113-115`); spawn/drop tables bound depth by map lookup
  (throw outside 1..5), not by the const. The node identity is DROPPED at
  the bloc: `_townFor` (`app/lib/main.dart:164-167`) maps a dungeon node to
  `world.home, and `EnterDungeonPressed` carries no payload — the world
  screen (`world_screen.dart:302`) is the last place that knows the node.
- **Finding 8 (Tile is four values, toAscii is the save format): TRUE,
  worse.** The Tile→char mapping now exists at FIVE sites (floor_map ×2,
  generator `_render, encounter_map `_render, glyph_grid), all exhaustive
  switches. A new tile character changes on-disk documents. M3D adds no
  tiles — themed terrain stays out of scope.
- **Finding 9 (the 24/40 depends on the crypt's draw order): TRUE.** The
  bot enters via `newGame` at `visit: 0` (`survivability_test.dart:56-57`),
  a door no real player uses. Byte-identity survives anything that leaves
  `newGame`/`buildFloor`'s draw order and depths 1–5 tables untouched.
- **Finding 10 (no boss machinery): TRUE.** Architect grep for `boss|Boss`
  over all three packages' `lib/`: zero hits. No victory event, no unique
  creature path, no distinguished spawn slot.

## Findings that change the spec

1. **The exact 24/40 pin is not code.** `survivability_test.dart:201-207`
   (architect-read): a `print` plus `expect(stalled, 0)` plus the 50–95%
   band. The histogram is print-only; `grep -rn "24/40" packages/` is
   empty. The honest move: the same commit that adds per-dungeon bands
   promotes the crypt's exact figure (24/40 and the histogram) into a real
   assertion — otherwise the crypt's guard remains a plan document.
2. **Run-block dungeon identity is load-bearing, not optional.** A camped
   hero (`inside == false`) stands in a town, so `world.at` cannot name the
   camp's dungeon; nothing else on disk can either. The run block needs a
   REQUIRED dungeon field (v1 reshape: goldens by hand, same commit,
   missing-field refusal test per the `world_characterization_test.dart`
   pattern). `loadRun` then picks the builder from it.
3. **The salt precedent is `_townSalt`.** `economy.dart:140-147`
   (architect-read): FNV over the node id's own text, XORed into worldSeed
   before `floorSeed` — "a town added to the world needs no second edit to
   get a shelf." A `dungeonSalt(NodeId)` of the same shape gives per-node
   floor streams. **The crypt must bypass it entirely** (identity = no XOR,
   not "salt of value 0"): the clean shape is a content factory
   `dungeonFor(node, worldSeed)` that returns `residuumDungeon(worldSeed)`
   for the crypt and salted builders for the new nodes — the crypt's path
   stays byte-identical by construction, and the characterization goldens
   (`generator_characterization_test.dart`) plus the printed 24/40 line
   stay the proof.
4. **The bestiary orphan test will fail on themed creatures.**
   `content_validation_test.dart:156` asserts exact set equality between
   the flat `bestiary` and the union of depth tables 1–5. Sea-cave-only
   creatures break it; the test generalizes to the union across all
   dungeons' tables (a red-first edit, named in the spec).
5. **Per-dungeon tables have a shipped precedent: the road.**
   `roadSpawnTable` lives outside the global map; `startRoadEncounter`
   passes `dropTables: const {roadDepth: roadDropTable}` inline through
   `startRun`'s existing `dropTables` parameter. New dungeons follow the
   same shape: their own `Map<int, SpawnTable>` / `Map<int, DropTable>`
   threaded through their own `buildFloor`-like function — the global
   crypt maps stay untouched. `world.dart:162-165` names this unit as
   where "a second table will have something to say."
6. **A light boss is content-only.** Content constructs `Floor(monsters:
   ...)` itself in its floor builder, so placing exactly one named
   creature on the bottom floor (swapping one rolled spawn) needs no core
   change. Guaranteed rare likewise: the bottom-floor drop table can weight
   rarities to rare-or-better (`rollDrop` forces nothing, but a table whose
   `rarities` carry zero weight below rare gets there through the existing
   weight-zero idiom), or the floor litter can pre-place it. No core
   changes, no crypt changes.
7. **Kill drops flow through an existing seam.** `startRun` already takes
   `dropTables` and `step.dart` reads `state.dropTables[state.depth]` —
   per-dungeon drop tables reach combat with no core edit.
8. **Glyph namespace is tight and hue may not carry theme.** Taken glyphs:
   `r w g s W` (case is load-bearing: `w` wolf vs `W` wight). The painter
   has ONE hard-coded palette (`glyph_grid.dart:49-55`), no theme
   parameter. Per-theme colors are additional signal only — themes must
   differ by glyph, name, and word first (CLAUDE.md accessibility rule);
   every screen must read in greyscale.
9. **App plumbing: the node must travel.** `EnterDungeonPressed` /
   `DelveAnewPressed` need to carry the `NodeId` (or `TownBloc` a second
   field) because `_townFor` throws the dungeon node away today. The world
   screen has the node in hand at `world_screen.dart:302`.
10. **World map edits touch pinned literals.** Two new nodes + routes edit
    `residuumWorld` and the topology tests (`world_test.dart:19-33`
    exact-set neighbour assertions). New nodes start undiscovered
    (M3W's discovery ruling: fresh saves know home town + crypt), so the
    discovery goldens move only where fixtures discover them. Rumors are
    the discovery door and need entries for both new nodes.

## Proposed shape of the work

One unit, `m3-dungeons` (M3D), effort M — but with an internal order the
spec should stage as commits:

1. **Identity plumbing first** (the risky half): run-block dungeon field
   (v1 reshape + goldens + refusal tests), `dungeonFor(node, worldSeed)`
   factory with the crypt as pass-through, node carried through
   `EnterDungeonPressed`/`DelveAnewPressed, `loadRun` reads the field.
   Gate: crypt goldens byte-identical, printed 24/40 line verbatim.
2. **Crypt pin promoted to assertion** — exact wins + histogram become
   `expect`s beside the band.
3. **The two themed dungeons** (additive content): bestiaries, spawn/drop
   tables, world nodes + routes + rumors, bottom-floor boss + guaranteed
   rare via the content seams, per-theme palette as additional signal.
4. **Per-dungeon bands**: bot parameterized by dungeon, figures measured
   by the worker, exact pins + bands ratified by the architect.

No split into multiple units: the plumbing half is unshippable alone (a
factory with one caller), and the content half cannot land without the
plumbing. D35's single-M verdict stands.

## Hazards to carry into the spec

- **Never edit the crypt's path.** `newGame, `buildFloor, the global
  `spawnTables`/`dropTables` maps, and the draw order are all
  byte-identity-bearing. New dungeons are NEW functions beside them (M3R
  precedent; D35 restated).
- The v1 reshape rules: new fields REQUIRED, goldens regenerated BY HAND
  in the same commit, no tooling on golden literals (the re.sub burn,
  D29). Save-version stays 1 (follow-up 20: freeze at first ship).
- The bot must keep entering at `visit: 0` via `newGame`; routing it
  through `startDungeonRun` (visit 1) moves the pin.
- `content_validation_test.dart:156` (orphan test) reds on new creatures
  until generalized — sequencing: generalize red-first with the first
  themed bestiary.
- Glyph collisions: `r w g s W` taken; case matters on a phone screen.
- `buildFloor` omits `stairsUp` when constructing `Floor` and
  `step.dart:484` compensates (`?? floor.heroSpawn`) — a new builder that
  copies the omission inherits a latent quirk; the spec should say which
  way the new builders go and why, without touching the crypt's.
- Balance levers: the CRYPT bestiary and tables are forbidden files (the
  M3W verification list extends). New creatures' stats are new content —
  free with a trail, per the tiered-lever rule.
- Merchant-validity invariant (D36/D39): entering any dungeon bumps the
  visit exactly as the crypt door does — the new door must answer the
  "did it move the visit or the town" question in its tests.
- The AVD pass is MANDATORY and presses platform buttons (three
  device-only defect classes so far); the new world routes and dungeon
  doors are exactly cross-screen state.

## Follow-ups this recon surfaces (for the ledger at spec time)

- The dormant "depth range per dungeon" spec promise (design spec section
  4) — M3D keeps 5 floors everywhere unless the user forks otherwise.
- `spawnTableFor`/`dropTableFor` docs say "one to five" as prose while the
  bound is the map keyset — latent coupling if `deepestDepth` ever moves.
- Set pieces / spell books "drop only in specific dungeons" (spec section
  7) — M4 / m3-magic scope; the per-dungeon drop-table shape M3D builds is
  their landing pad.

## What this recon did NOT check

- No AVD/device run this session; all app claims are from code and suites.
- The three agents' own unquoted tails; the architect re-verified the
  load-bearing claims (floorSeed, loadRun, _townSalt, the band-only
  assertion, the boss grep, the orphan test) but not every quoted line.
- `step.dart` combat internals beyond the drop path; nothing here depends
  on them.
- The exact printed survivability line was not re-read from stdout this
  session (the suite ran green, which proves only the band).
- Whether a fresh-kit bot can survive the harder themed dungeons at all —
  the per-dungeon band values are unknowable before a worker measures.
- Rumor economy details (prices, tavern flow) beyond "rumors are the
  discovery door".
