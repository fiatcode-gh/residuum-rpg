# Recon — m3-saves (M3S), 2026-08-21

## VERDICT

Full suspend-save is buildable now that Rng exports state (M3R). Everything
in a GameState is either plain data or rebuildable from content given
worldSeed + visit + depth. The codec belongs in content (it needs both core
types and the content registries); file I/O belongs in app. The registries
need small by-id lookups that do not exist yet.

## State verified before measuring

- `main` @ `0656eb1` (M3R merge, PR #2), clean, in sync with origin.
  619 tests (395 core + 95 content + 129 app) green, measured this session
  after the merge. Exact survivability baseline: 24/40 (D24).

## The measurement

- **GameState fields** (`game_state.dart, read in full this session):
  serializable plain data — map, hero, monsters, visible, explored, depth,
  worldSeed, visit, stairsDown/Up, gold, isGameOver, floors (FloorMemory by
  depth), groundItems, inventory, equipment, skills, nextDropNumber; live
  streams `rng`/`lootRng` (now exportable via `state, M3R); NOT data —
  `buildFloor` (closure) and `dropTables, both re-injectable exactly as
  `startRun` does: `residuumDungeon(worldSeed)(visit)` and content's
  drop tables (`run_boundary.dart:54, `new_game.dart`).
- **FloorMemory** is deliberately self-contained: terrain kept so a restore
  never runs the generator ("a restore that cannot regenerate cannot
  accidentally reshuffle" — its dartdoc), monster energy snapshotted and
  not zeroed. A save codec inherits both arguments wholesale.
- **FloorMap** has `parse` (ASCII in) but no inverse; the codec needs an
  ASCII renderer (`#`/`.`/`>`/`<` — four tiles total).
- **Actor** is 12 plain fields including position and energy.
- **Profile** (read earlier this session): hero, equipment, skills,
  inventory, bank, gold, bankedGold, worldSeed, visit. Profile is Equatable
  → round-trip tests can use `==`. GameState is NOT Equatable → run
  round-trips need field comparison plus behavioral equivalence.
- **Registries**: `armory` is a `const List<BaseItem>`; affixes are two
  const lists (`weaponAffixes, `armourAffixes`). No by-id lookup exists —
  the codec adds them. Content validation tests already exercise these
  lists; id uniqueness across the affix pools is asserted there (worker
  verifies rather than trusts this line).
- **App boot** (`main.dart`): `TownBloc(profile: newProfile())` —
  `newProfile({int worldSeed = 1}), so every install plays world seed 1
  today. `GameBloc` already accepts an initial `game` — resume has a door.
- **App deps**: flutter_bloc + content only; no path_provider yet.
- **64-bit JSON hazard** (from the M3R worker, D24): exported Rng state is
  full-width signed 64-bit (e.g. 2420599403871909411 > 2^53) and does not
  survive JSON-number round-trips through double semantics. Seeds are also
  full-width once xored with salts.

## Is each inherited gate real?

- "Rng state is exportable" — real since `0656eb1` (`state`/`fromState,
  equivalence-tested).
- "Floors are rebuildable so need not be saved" — TRUE but IRRELEVANT by
  design: FloorMemory already keeps terrain to guarantee restores never
  regenerate; the codec follows the same doctrine and saves it.

## Findings that change the spec

1. **One save document, not two.** Mid-run, the profile on disk is the
   as-at-entry profile and the run references it. Two files can desync
   under a kill between writes; one document with an optional `run` block
   cannot.
2. **Two actor codecs are correct, not one.** A run snapshot serializes
   actors fully (frozen mid-fight state — position, hp, energy; same
   honesty argument as FloorMemory's terrain). The profile's hero instead
   rebuilds from content's fresh hero plus the earned field (hp): a
   long-lived save must inherit future content rebalances, and hero base
   stats are a forbidden lever that must not fossilize inside saves.
3. **Items serialize as references** (base id + rarity name + affix ids +
   item id) per D23 — content patches apply on load; an unknown id is a
   structured load failure, not a crash.
4. **The seed roll needs an app-side randomness source.** Core/content
   forbid unseeded randomness; the app layer rolling
   `DateTime.now().millisecondsSinceEpoch` for a NEW hero's worldSeed is
   the sanctioned home.

## Proposed shape of the work

One unit, branch `m3-saves, story M3S (L). Content: a `save` feature
(codec, version field, structured failures, registry lookups). App: storage
with two-slot rotation and atomic writes (path_provider), autosave wiring,
boot-time load with corrupt fallback and report, resume-into-crawl, seed
roll, and a guarded "abandon hero" door so a rolled world is not forever.

## Hazards to carry into the spec

- JSON 64-bit precision (strings, never numbers, for seeds and rng states).
- Save cadence vs jank: encoding a full run snapshot every step must be
  measured on device, with a coarser fallback named.
- The active floor is NOT in `floors` — the codec must capture map/monsters/
  groundItems/explored from the state's own fields for the current depth.
- Atomic write ordering: verify-then-rotate, never rotate-then-fail.
- A game-over run is saved like any run; endRun is what clears it.

## What this recon did NOT check

- Whether affix ids are unique ACROSS the weapon and armour pools (content
  test presumed; worker verifies).
- Real encode/decode cost of a five-floor late-run state on the AVD.
- path_provider behavior on the emulator (assumed standard).
- Whether any existing test constructs GameState in ways the codec's field
  enumeration would miss (worker diffs constructor sites).
