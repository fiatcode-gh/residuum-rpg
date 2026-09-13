# Story spec — M2E "Engine" — unit `m2-engine` (first of three M2 units)

Canonical sources (read all three before building):
- Game design spec: `/var/home/dhemas/Development/Projects/_temp/residuum/docs/superpowers/specs/2026-08-20-dungeon-game-design.md`
  (sections 3.3 determinism, 4 dungeons, 5 combat, 13 error handling)
- Code conventions: `CLAUDE.md` at the worktree root
- The existing code on `main` (`be1da0a`) — M1 is merged; this story extends
  it. Read `packages/core` in full before planning; it is small.

## Goal

The dungeon becomes real: floors are generated from the world seed instead of
hardcoded, five floors deep with stairs and depth-scaled danger; turns run on
the speed clock instead of strict alternation; monsters chase through corners
via a flow field instead of freezing (closes ledger D6); the player taps any
explored tile to auto-walk with sensible interrupts; and the bestiary grows to
five monster types with distinct speeds. Measurable effect: all suites green
(baseline this session: 66 core + 10 content + 17 app = 93, all measured
fresh), a seeded run is reproducible floor-by-floor, and a human can descend
all five floors on the AVD.

## Locked scope decisions (ledger D8 — do not re-litigate)

- Exactly 5 floors. Stairs down on floors 1–4, none on floor 5. No boss (M4).
- Speed clock replaces alternation now. Flow field replaces greedy chase now.
- Auto-path in scope. Loot, skills, town, death penalty are NOT in this unit
  (they are `m2-loot` and `m2-town`).
- Death still means restart-from-scratch in this unit; the death penalty
  arrives with `m2-town`.
- 4-way movement stays. Fog of war stays (radius 8).

## Shape

Follow the M1 precedent, read from the code: pure functions in
`core` (`computeFov` is the model — take a map, return a value, document the
metric in dartdoc), value objects with equatable, events for everything the UI
must narrate, content as consts + a `newGame` factory, bloc as the only app
brain. New logic goes in new feature files, not by fattening `step.dart` into
a god function — extract phases (`_heroPhase, monster scheduling) as the
plan sees fit, keeping `step()` the single entry point.

## New files

```
packages/core/
  lib/src/engine/energy.dart          # speed-clock scheduling primitives
  lib/src/dungeon/generator.dart      # generateFloor()
  lib/src/dungeon/flow_field.dart     # computeFlowField()
  lib/src/dungeon/path.dart           # findPath()
  test/engine/energy_test.dart
  test/dungeon/generator_test.dart
  test/dungeon/flow_field_test.dart
  test/dungeon/path_test.dart
  test/engine/step_clock_test.dart

packages/content/
  lib/src/bestiary.dart               # 5 creature specs
  lib/src/spawn_tables.dart           # per-depth spawn tables
```

## Changed files

```
packages/core/lib/src/engine/actor.dart       # + name, speed, energy
packages/core/lib/src/engine/game_state.dart  # + depth, floorsVisited/worldSeed plumbing
packages/core/lib/src/engine/action.dart      # + DescendAction
packages/core/lib/src/engine/event.dart       # + Descended, ActorNoticed (see contract)
packages/core/lib/src/engine/step.dart        # speed clock + flow-field integration
packages/core/lib/src/dungeon/tile.dart       # + stairsDown
packages/core/lib/src/dungeon/floor_map.dart  # parse/support stairsDown ('>')
packages/content/lib/src/new_game.dart        # seeded newGame(worldSeed) replaces fixed floor
packages/content/lib/src/first_floor.dart     # DELETE (or keep only as a test fixture in core tests)
packages/app/lib/game/game_bloc.dart          # auto-path loop, descend, depth in view state
packages/app/lib/game/event_messages.dart     # messages use Actor.name; new events
packages/app/lib/game/game_screen.dart        # depth indicator; HP label clamps at 0
packages/app/test/game_bloc_test.dart         # extended
```

Never touch `docs/epic/`.

## Per-item contract

### Actor (changed)

```dart
// added fields, all required:
final String name;     // display name: 'you', 'the ghoul', 'the dire wolf'
final int speed;       // energy gained per tick; baseline 10
final int energy;      // accumulated; acts at >= 100, spends 100
```

Monster ids must be unique per floor, enforced where spawns are created
(content spawn logic asserts it; a content validation test proves it).

### energy.dart — the speed clock

```dart
const int actThreshold = 100;
const int actCost = 100;

/// Returns actors in the order they act, advancing [tick]s until the hero
/// is next to act again. Pure scheduling; no combat here.
```

Semantics (document in dartdoc, test exhaustively):
- Every actor accumulates `speed` energy per tick.
- An actor with `energy >= 100` may act, spending exactly 100.
- When several reach the threshold on the same tick: hero first, then
  monsters in list order.
- The hero never acts without player input: `step()` is still the only entry
  point, and it (a) applies the hero's action + spends hero energy, then
  (b) runs monster actions until the hero is again the next actor.
- Speed 10 vs speed 10 must reproduce M1's alternation exactly (this is the
  key regression guarantee). Speed 20 monster acts twice per hero turn;
  speed 5 acts every other hero turn.

### flow_field.dart

```dart
/// Breadth-first distance field over walkable tiles from [goal].
/// Unreachable tiles carry no entry.
Map<Position, int> computeFlowField(FloorMap map, Position goal);
```

Monster movement rule (in step's monster phase): move to the orthogonal
neighbor with the strictly smallest field value that is walkable and
unoccupied; ties broken in fixed order north, east, south, west; no
improving neighbor free → stand still. This must round corners (the D6
freeze case becomes a test: wall between monster and hero on the same row,
monster reaches the hero). Field recomputed once per `step()` call, shared
by all monsters, updated for occupancy only via the "unoccupied" check.

### path.dart

```dart
/// Shortest 4-way path from [from] to [to] over walkable tiles, both
/// exclusive of [from], inclusive of [to]. Empty when unreachable.
List<Position> findPath(FloorMap map, Position from, Position to);
```

Breadth-first (uniform cost); deterministic tie-break north, east, south,
west. Used by the app for auto-walk; monsters use the flow field, not this.

### generator.dart

```dart
class GeneratedFloor {
  final FloorMap map;
  final Position heroSpawn;        // on floor 1: anywhere valid; floors 2-5: a walkable tile (stairs arrival)
  final List<Position> monsterSpawns;
  final Position? stairsDown;      // null exactly on depth 5
}

GeneratedFloor generateFloor(int floorSeed, int depth);
```

- Binary-space-partition rooms + connecting corridors, everything within a
  bounded grid (target ~24x16 up to ~32x20, scale gently with depth).
- Guarantees, each enforced by a post-hoc validation pass inside the
  generator and each pinned by a test: full connectivity (flood fill from
  heroSpawn reaches every walkable tile), stairsDown present and reachable on
  depths 1–4 and absent on 5, heroSpawn ≠ any monsterSpawn, monsterSpawns on
  walkable tiles not in the hero's starting room, monster count from the
  spawn table for that depth.
- On validation failure: regenerate with a derived retry seed (e.g.
  `floorSeed + attempt`), never loop forever (throw after a bounded number of
  attempts with a diagnostic message), never return a broken floor. (Game
  spec section 13.)
- Pure function of (floorSeed, depth): same inputs, identical output — pinned
  by a golden test on at least two seeds.

### Seed hierarchy (game spec 3.3, now real)

```dart
int floorSeed(int worldSeed, int depth, int visit);
```

Deterministic mixing (document the exact function; a simple hash combine is
fine). `visit` is 0 for now and plumbed through `newGame`; `m2-town` will bump
it on death. Layout must not depend on combat/loot rolls: the generator gets
its own `Rng(floorSeed), separate from the run's combat stream.

### GameState (changed)

```dart
final int depth;          // 1-based
final int worldSeed;
final int visit;
final Position? stairsDown;   // carried from the generated floor
```

### DescendAction / events

```dart
class DescendAction extends GameAction {}   // valid only when hero stands on stairsDown
class Descended extends GameEvent { final int newDepth; }
```

- `DescendAction` on stairs: generate floor `depth+1, hero moves to its
  heroSpawn, monsters replaced by the new floor's spawns, FOV/explored reset,
  emit `Descended`. Hero hp/energy persist across floors.
- `DescendAction` anywhere else: `MoveBlocked`-style no-op event (reuse
  `MoveBlocked` or ignore in bloc — pick one, document it, test it).
- No ascending in M2 (one-way down; the game spec's "leave or die" via town
  arrives with `m2-town`).

### Bestiary (content) — 5 creatures, distinct speeds so the clock shows

| id/name | glyph | hp | attack | speed | depths |
|---|---|---|---|---|---|
| giant rat / 'the giant rat' | r | 4 | 1–2 | 10 | 1–2 |
| dire wolf / 'the dire wolf' | w | 8 | 2–3 | 20 | 1–3 |
| ghoul / 'the ghoul' | g | 10 | 2–4 | 10 | 2–4 |
| skeleton / 'the skeleton' | s | 16 | 3–5 | 5 | 3–5 |
| wight / 'the wight' | W | 20 | 4–6 | 10 | 4–5 |

Numbers are first guesses, tunable with a report (M1 precedent). Spawn tables
map depth → (monster count range, weighted creature choices); rolled with the
generator's Rng. Hero stays 20 hp, 3–5 attack, speed 10 for this unit
(re-balance belongs to `m2-loot` when gear exists).

### App

- View state gains `depth`; screen shows "Depth 3/5" as text.
- HP label clamps at zero: "0 / 20", never negative (follow-up 6).
- Stairs glyph `>` drawn like other tiles under fog rules.
- **Auto-walk:** tapping any *explored* walkable non-adjacent tile computes
  `findPath` and walks it by issuing one `MoveAction` per step. Interrupt and
  stop when: a monster is or becomes visible, the hero takes damage, the path
  step is no longer walkable/free, or the user taps anything during the walk.
  Adjacent taps behave exactly as M1 (including bump attack). Taps on
  unexplored tiles do nothing. While standing on stairs, a dedicated Descend
  button (not a tile tap) issues `DescendAction`.
- Auto-walk pacing/animation is bloc-driven and testable at bloc level
  (e.g. drain-based stepping); no widget tests (conventions).

## Behaviour arguments that must land in documentation (dartdoc)

- energy.dart: why hero-first tie-break (player agency on simultaneous
  threshold) and why speed-10-vs-10 must equal M1 alternation.
- flow_field.dart: why monsters use a shared flow field rather than per-monster
  pathfinding (n monsters, one BFS; deterministic; no oscillation), and the
  fixed tie-break order.
- generator.dart: the regenerate-on-invalid strategy and its bounded retries.

## Test plan

- **Characterization tests: the existing 93 are the characterization layer.**
  They must stay green except where a contract deliberately changed — the
  known casualties are step tests assuming strict alternation and content
  tests assuming the hardcoded floor/3 ghouls. The plan must list which
  existing tests it expects to modify and why, before modifying them;
  everything else stays untouched and green.
- **Unit tests (core, mock-free, fixed seeds):** energy scheduling (equal
  speeds = alternation; fast monster double-acts; slow monster half-acts;
  hero-first ties); flow field (corner-rounding — the D6 case verbatim;
  unreachable tiles absent; tie-break order); findPath (shortest, exclusive/
  inclusive ends, unreachable → empty); generator (all guarantees above, two
  golden seeds, retry path exercised by a seed known to fail validation or by
  injecting a validator — worker's choice, argued); descend (state swap,
  hp persists, FOV reset, depth 5 has no stairs); id-uniqueness.
- **Content validation:** bestiary ids unique, spawn tables reference real
  creatures, every depth 1–5 has a non-empty table, table depths cover 1–5.
- **App (bloc_test):** auto-walk walks a multi-tile path; each interrupt
  condition stops it; unexplored tap ignored; descend button only on stairs;
  depth in state; HP clamp.

### Mutation table

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) |
|---|---|---|---|
| 1 | flow field: remove the "strictly smaller" comparison (allow equal) | corner-rounding / no-oscillation tests | energy scheduling tests |
| 2 | energy: hero tie-break dropped (monsters first) | hero-first tie test | flow field tests |
| 3 | generator: skip the connectivity flood-fill validation | connectivity/golden tests (on the failing-seed path) | findPath tests |
| 4 | stairsDown emitted on depth 5 | depth-5-has-no-stairs test | descend hp-persistence test |
| 5 | auto-walk: ignore monster-became-visible interrupt | that interrupt's bloc test | adjacent-tap and other interrupt tests |

Sequencing note: run the table against the finished unit, one row at a time,
reverting each. Row 3's red requires the retry/validation tests, not the happy
path — say which test reddened.

## Hazards (environment traps — verbatim from the ledger, updated 2026-08-20)

- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion patterns —
  always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils: `-newermt` takes
  ISO 8601 only; relative strings like `'15 minutes ago'` error (and read as
  empty with stderr suppressed). GNU find is at `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — never commit anything under
  `docs/epic/`; cite its files by absolute path.
- Commits use the personal persona:.
- `emulator, `adb, and device-facing `flutter` subcommands
  (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`) are
  sandbox-excluded and run without prompting. `flutter test`/`analyze`/`build`
  and `dart format` stay sandboxed. Any OTHER hardware probe still lies under
  sandbox (`/dev` is masked) — re-run it via the excluded commands before
  concluding hardware is absent.
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` mishandles
  the installed ps16k system images — use the `emulator` binary directly.

## Follow-ups to log (not this story)

1. Loot/inventory/equipment/skills → `m2-loot` (next unit).
2. Town, bank, merchant, death penalty, visit-bump on death → `m2-town`.
3. Ascending stairs / leaving mid-dungeon → `m2-town`.
4. Balance pass across 5 floors once gear exists → `m2-loot` or later.

## Definition of done (checkable)

- [ ] `cd packages/core && dart test` all pass; `cd packages/content && dart
      test` all pass; `cd packages/app && flutter test` all pass — and the
      report lists which pre-existing tests were modified, with the reason
- [ ] `flutter analyze` clean in all three packages; `dart format
      --set-exit-if-changed .` clean repo-wide
- [ ] Determinism: the same worldSeed twice produces identical floors 1–5
      (golden test), and layout is unchanged by different combat outcomes
      (separate rng streams — tested)
- [ ] Mutation table executed, all rows, greens included, mutations reverted
- [ ] AVD playthrough: descend from floor 1 to floor 5 on `Pixel_10`; a wolf
      visibly outpaces the hero (double moves); a monster rounds a corner to
      reach you; auto-walk crosses a room and stops when a monster appears;
      HP label reads "0 / 20" at death
- [ ] Conventional commits, each green, fiatcode author; nothing under
      `docs/epic/`; dartdoc carries the three documented behaviour arguments
