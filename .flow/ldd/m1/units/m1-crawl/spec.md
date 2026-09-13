# Story spec — M1 "The Crawl" — unit `m1-crawl`

Canonical sources (read both before building):
- Game design spec: `/var/home/dhemas/Development/Projects/_temp/residuum/docs/superpowers/specs/2026-08-20-dungeon-game-design.md`
- Code conventions: `/var/home/dhemas/Development/Projects/_temp/residuum/CLAUDE.md`

## Goal

From an empty repository to the first playable build: a hardcoded dungeon floor
rendered as colored glyphs on a phone-shaped screen, where the player taps
adjacent tiles to move, bumps into ghouls to attack, watches HP, dies, and
restarts. Measurable effect: `dart test` green in `core` and `content, `flutter test` green in `app, and a human can play a full live-die-restart
loop in Chrome.

## Locked scope decisions (do not re-litigate; ledger D3)

- Movement is 4-way orthogonal. No diagonals.
- Turn scheduling is simple alternation: hero acts, then every living monster
  acts. The spec's speed clock is M2; do not build it.
- Fog of war IS in scope: shadowcasting field of view, radius 8, plus
  remembered "explored" tiles drawn dimmed.
- Tap input: adjacent tiles only. A tap on a non-adjacent tile does nothing.
  No pathfinding.
- One monster type (ghoul), one weapon (rusty sword, baked into hero stats).
  No inventory, no items, no skills, no saves, no sound.

## Shape

No codebase precedent exists — this story sets it. The precedent to follow is
the conventions file (`CLAUDE.md`): three packages, dependency rule
`app → content → core, feature folders, immutable state through
`step(state, action) → (state, events), value objects, no body comments,
strict TDD in core, BLoC-only tests in app.

## New files

```
packages/core/
  pubspec.yaml                      # name: residuum_core, sdk only, dev: test
  lib/core.dart                     # exports everything public below
  lib/src/engine/position.dart      # Position, Direction
  lib/src/engine/rng.dart           # Rng
  lib/src/engine/actor.dart         # Actor
  lib/src/engine/action.dart        # GameAction, MoveAction
  lib/src/engine/event.dart         # GameEvent and subtypes
  lib/src/engine/game_state.dart    # GameState
  lib/src/engine/step.dart          # step()
  lib/src/dungeon/tile.dart         # Tile
  lib/src/dungeon/floor_map.dart    # FloorMap
  lib/src/dungeon/fov.dart          # computeFov()
  test/...                          # mirrors lib/src by feature

packages/content/
  pubspec.yaml                      # name: residuum_content, dep: residuum_core (path)
  lib/content.dart
  lib/src/first_floor.dart          # firstFloorAscii, spawn positions
  lib/src/new_game.dart             # newGame()
  test/content_validation_test.dart

packages/app/                       # flutter create --platforms=android,web
  pubspec.yaml                      # name: residuum_app, deps: flutter_bloc,
                                    #   residuum_core + residuum_content (path);
                                    #   dev: bloc_test, flutter_test
  lib/main.dart
  lib/game/game_bloc.dart           # GameBloc, its events and state
  lib/game/game_screen.dart         # layout: grid, log, HP bar, death overlay
  lib/game/glyph_grid.dart          # CustomPainter + tap mapping
  test/game_bloc_test.dart
```

## Changed files

None — empty repository. Root `.gitignore` already exists; never touch
`docs/epic/` (gitignored architect ledger).

## Per-item contract

### core/engine/position.dart

```dart
enum Direction { north, south, east, west }   // dx/dy: north = (0,-1)
class Position {                              // value object
  final int x; final int y;
  const Position(this.x, this.y);
  Position step(Direction d);
  bool isOrthogonallyAdjacentTo(Position other);   // exactly distance 1, 4-way
  // == / hashCode / toString
}
```

Must not: allow diagonal adjacency to return true.

### core/engine/rng.dart

```dart
class Rng {
  Rng(int seed);
  int rollRange(int min, int maxInclusive);   // uniform, both ends inclusive
}
```

Wraps `dart:math Random(seed)`. Must not: be constructed unseeded anywhere.
Same seed + same call sequence = same values (test this).

### core/dungeon/tile.dart

```dart
enum Tile { wall, floor }
// wall: walkable=false, transparent=false; floor: true, true
```

### core/dungeon/floor_map.dart

```dart
class FloorMap {
  factory FloorMap.parse(String ascii);   // '#'=wall, '.'=floor, rectangular
  int get width; int get height;
  Tile tileAt(Position p);
  bool inBounds(Position p);
  bool isWalkable(Position p);            // false when out of bounds
  bool isTransparent(Position p);         // false when out of bounds
}
```

`parse` throws `ArgumentError` on ragged rows or characters outside `#.`
(and newline). Must not: hold actors — actors live in `GameState`.

### core/dungeon/fov.dart

```dart
Set<Position> computeFov(FloorMap map, Position origin, int radius);
```

Recursive shadowcasting over `isTransparent`. Origin always included. Walls
that border a visible floor tile are visible (so room edges render). Must not:
see through walls; must not include tiles beyond `radius` (Euclidean or
roguelike-standard distance — pick one, document it in the dartdoc, test it).

### core/engine/actor.dart

```dart
class Actor {
  final String id;          // 'hero' or 'ghoul-<n>'
  final String glyph;       // '@' or 'g'
  final Position position;
  final int hp; final int maxHp;
  final int attackMin; final int attackMax;
  bool get isAlive;         // hp > 0
  Actor copyWith({Position? position, int? hp});
}
```

### core/engine/action.dart / event.dart

```dart
sealed class GameAction {}
class MoveAction extends GameAction { final Direction direction; }

sealed class GameEvent {}
class ActorMoved   extends GameEvent { final String actorId; final Position from; final Position to; }
class MoveBlocked  extends GameEvent { final String actorId; final Position at; }
class AttackHit    extends GameEvent { final String attackerId; final String targetId; final int damage; }
class ActorDied    extends GameEvent { final String actorId; }
class GameOver     extends GameEvent {}
```

Events are value objects (== by fields) so tests can `expect(events, contains(...))`.

### core/engine/game_state.dart

```dart
class GameState {
  final FloorMap map;
  final Actor hero;
  final List<Actor> monsters;      // living monsters only
  final Rng rng;
  final Set<Position> visible;     // current FOV
  final Set<Position> explored;    // union of every FOV so far
  final bool isGameOver;
  Actor? monsterAt(Position p);
  GameState copyWith({...});
}
```

`Rng` is mutable and carried by reference — documented exception to
immutability, acceptable because determinism holds for a fixed action
sequence. Say exactly that in its dartdoc.

### core/engine/step.dart — the heart of M1

```dart
(GameState, List<GameEvent>) step(GameState state, GameAction action);
```

Resolution order for `MoveAction`:
1. If `state.isGameOver, return the state unchanged with no events.
2. Target = hero.position.step(direction).
   - Monster there → hero attacks: damage = `rng.rollRange(attackMin, attackMax)`;
     emit `AttackHit`; if target hp ≤ 0, remove it from `monsters, emit `ActorDied`.
   - Else walkable and unoccupied → hero moves; emit `ActorMoved`.
   - Else → emit `MoveBlocked`; **the turn is still consumed** (monsters act).
3. Every living monster, in list order:
   - Orthogonally adjacent to hero → attacks hero (same damage rule), emit `AttackHit`.
   - Else → one greedy step toward hero: move along the axis with the larger
     absolute delta if that tile is walkable and unoccupied (by hero or any
     monster); tie or blocked → try the other axis; both blocked → stand still
     (no event). Deterministic: on equal deltas prefer the x axis.
4. If hero hp ≤ 0: emit `ActorDied('hero')` and `GameOver, set `isGameOver`.
5. Recompute `visible` from the hero's final position (radius 8); `explored`
   grows by the new `visible`.

Must not: mutate any input; reach into Flutter; use any randomness outside
`state.rng`.

### content package

```dart
const String firstFloorAscii = ...;  // one hand-authored floor, ~20x12, at
                                     // least 2 rooms + corridor; '#' and '.' only
GameState newGame({int seed = 1});   // hero '@' 20/20 hp, attack 3-5 (the rusty
                                     // sword baked in); 3 ghouls 'g' 10 hp,
                                     // attack 2-4, at fixed walkable positions
```

Validation tests: floor parses; hero and every ghoul spawn on walkable tiles;
no two actors share a spawn tile.

### app package

```dart
// game_bloc.dart
sealed class GameBlocEvent {}
class GameStarted  extends GameBlocEvent { final int seed; }
class TileTapped   extends GameBlocEvent { final Position position; }

class GameViewState {
  final GameState game;
  final List<String> log;    // newest last, rendered messages from GameEvents
}

class GameBloc extends Bloc<GameBlocEvent, GameViewState> { ... }
```

- `TileTapped` on a tile orthogonally adjacent to the hero → the matching
  `MoveAction` through `step`; any other tile → ignored, no state emitted.
- `GameStarted` → fresh `newGame(seed)` (also used by the restart button).
- Event→message rendering lives in the bloc (e.g. `AttackHit` →
  "You hit the ghoul for 3." / "The ghoul claws you for 2.").

`glyph_grid.dart`: `CustomPainter` that draws, per cell: nothing if
unexplored; dimmed tile glyph if explored-not-visible; full-color tile glyph
if visible; actor glyphs only on visible tiles. Glyphs: `#` wall, `.` floor, `@` hero, `g` ghoul. `GestureDetector` maps tap coordinates to a `Position`
and adds `TileTapped`.

`game_screen.dart`: portrait column — grid on top, scrolling message log,
HP bar, and a game-over overlay ("You died." + Restart button).

**Accessibility (conventions, non-negotiable):** the HP bar must encode danger
by fill-fraction and a numeric label ("7 / 20"), never color alone; dimmed
explored tiles must differ from visible ones in brightness, readable in
greyscale.

## Behaviour arguments that must land in documentation (dartdoc)

- `step.dart`: why a blocked move still consumes the turn (bump-attacks and
  wall-bumps costing time is the classic roguelike rule; free wall-bumps would
  let the player scout without risk).
- `game_state.dart`: the Rng-by-reference exception to immutability, and why
  determinism survives it.
- `fov.dart`: which distance metric was chosen and why.

## Test plan

- **Characterization tests: none.** Empty repository; there is no current
  behaviour to pin. This is stated so nobody hunts for it.
- **Unit tests (core, TDD, mock-free):** position/adjacency; rng determinism
  and range bounds; floor parse (happy, ragged, bad char); fov (open room,
  wall occlusion, radius cap, origin included); step: move, blocked, bump
  attack, monster death, monster chase step, monster adjacent attack, hero
  death → GameOver, action after game over is a no-op, explored grows
  monotonically. Fixed seeds throughout; where damage variance obscures an
  assertion, use `attackMin == attackMax` actors — never mock Rng.
- **Content validation tests** as per contract above.
- **App tests (bloc-level only, `bloc_test`):** started→initial state renders
  hero at spawn; adjacent tap moves hero and appends a log line; non-adjacent
  tap emits nothing; killing-blow tap logs the death; hero death flips
  game-over; restart resets. No widget tests (conventions).

### Mutation table

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) | Why |
|---|---|---|---|---|
| 1 | `Tile.wall` made walkable | floor-map walkability, step blocked-move test | position, rng tests | proves map tests bind to tile semantics, not parse only |
| 2 | monster phase deleted from `step` | chase + monster-attack + hero-death tests | hero move/bump tests | proves hero-turn tests don't accidentally depend on monster phase |
| 3 | damage hardcoded to 0 | bump-attack, monster-attack, death tests | movement, fov, floor tests | proves combat asserts damage, not merely event presence |
| 4 | `computeFov` returns all positions | occlusion + radius tests | step movement tests | proves fov tests assert limits, not just membership |
| 5 | bloc ignores `TileTapped` entirely | adjacent-tap bloc test | non-adjacent-tap test (asserts nothing emitted) | the green half shows the ignore-path is pinned separately |

Sequencing note: mutation 2 must be run against the *finished* step
implementation (after all step tasks), not mid-build when the monster phase
does not exist yet. Run mutations at the end, one at a time, reverting each.

## Hazards (environment traps — verbatim from the ledger)

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
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as missing
  while it exists on the host — hardware probes lie under sandbox. Emulator,
  adb, and `flutter run` need unsandboxed commands (permission prompt).
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and
  `flutter emulators --create` mishandle the installed ps16k system images —
  use the `emulator` binary directly.
- No Linux desktop toolchain. Visual verification target is the Android
  emulator (`Pixel_10`); the first gradle build downloads dependencies —
  allow several minutes.
- `flutter create` should use `--platforms=android,web --project-name residuum_app`.

## Follow-ups to log (not this story)

1. Speed-clock turn scheduler replaces alternation (M2).
2. Tap-to-auto-path with interrupt rules (M2).
3. Seeded floor generation replaces the hardcoded floor (M2).
4. fvm pinning decision (ledger follow-up 1).

## Definition of done (checkable)

- [ ] `cd packages/core && dart test` — all pass
- [ ] `cd packages/content && dart test` — all pass
- [ ] `cd packages/app && flutter test` — all pass
- [ ] `flutter analyze` clean in all three packages (zero errors AND zero warnings)
- [ ] `dart format --set-exit-if-changed .` clean repo-wide
- [ ] Mutation table executed: every "fail" row failed, every control stayed
      green, all mutations reverted (quote the output in the report)
- [ ] `flutter run` on the `Pixel_10` Android emulator: a human-visible crawl —
      move, fog of war reveals, kill a ghoul, die to ghouls, restart
- [ ] Conventional commits, small, each leaving tests green
- [ ] Nothing committed under `docs/epic/`; no body comments; dartdoc carries
      the three documented behaviour arguments
