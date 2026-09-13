# M1 "The Crawl" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** From an empty repository to a playable turn-based crawl on one hardcoded dungeon floor — colored glyphs, fog of war, tap-adjacent to move, bump to attack, three chasing ghouls, HP, death, restart.

**Architecture:** Three Dart packages with a one-way dependency rule `app → content → core`. All game rules live in `core` as pure functions over immutable state, driven by a single entry point `(GameState, List<GameEvent>) step(GameState, GameAction)`. `content` holds the hand-authored floor and the starting state. `app` is a Flutter shell: one BLoC turns taps into `step` calls and `GameEvent`s into log lines, one `CustomPainter` draws glyphs.

**Tech Stack:** Dart 3.13.0, Flutter 3.47.0 (system, no fvm), `package:test` for core/content, `flutter_bloc` + `bloc_test` for app.

**Spec:** `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m1-crawl-spec-M1.md` (story spec, the contract). Context: `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`. Conventions: `CLAUDE.md` at the worktree root.

## Global Constraints

Every task's requirements implicitly include this section.

- Working directory is the worktree `/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl, branch`m1-crawl`. Never touch the parent checkout at`.../residuum`.
- Write every git command as `cd <worktree> && git <cmd>`. `git -C` does not match the sandbox exclusion patterns.
- Commits: Conventional Commits. Commit signing is on (SSH key), so `git commit` needs an unsandboxed Bash call. **Only the orchestrating session commits; subagents write code and run tests, never git.**
- Never commit anything under `docs/epic/` — it is the architect's gitignored ledger.
- Allowed dependencies, nothing else: `flutter_bloc` (app), `bloc_test` + `flutter_test` (app dev), `test` (core/content dev). `flutter_lints` is accepted only because `flutter create` generates it.
- `core` and `content` must never import Flutter. A game rule in a widget is a bug.
- No body comments anywhere. Dartdoc `///` only, and only on public API of `core` and `content`.
- Ubiquitous language: the spec's words exactly (`temper,`affix, `beat,`rumor, `residue`). No abbreviations.
- No global randomness: every roll draws from `state.rng`. An unseeded `Random()` in `core` or `content` is a bug.
- Movement is 4-way orthogonal. No diagonals anywhere, including monster chase.
- Accessibility (non-negotiable, author is deuteranomalous): state, rarity and category are encoded by glyph shape, brightness, position, or a word — never hue alone. Every screen must read in greyscale.
- Test bodies are structured `// arrange` / `// act` / `// assert`. Those three are the only comments allowed in test files.
- Every commit's exit state is green: `dart test` in core/content, `flutter test` in app, `flutter analyze` with zero errors and zero warnings, `dart format --set-exit-if-changed .` clean.
- `dart format` uses the default 80-column page width. Write narrow code.

---

## File Structure

```
docs/superpowers/plans/2026-08-20-m1-the-crawl.md   this plan

packages/core/                       pure Dart, zero Flutter
  pubspec.yaml                       name: residuum_core; dev: test
  lib/core.dart                      the package's public surface
  lib/src/engine/position.dart       Direction, Position
  lib/src/engine/rng.dart            Rng
  lib/src/engine/actor.dart          Actor
  lib/src/engine/action.dart         GameAction, MoveAction
  lib/src/engine/event.dart          GameEvent + 5 subtypes
  lib/src/engine/game_state.dart     GameState
  lib/src/engine/step.dart           step()
  lib/src/dungeon/tile.dart          Tile
  lib/src/dungeon/floor_map.dart     FloorMap
  lib/src/dungeon/fov.dart           fovRadius, computeFov()
  test/support/fixtures.dart         shared test builders
  test/engine/position_test.dart
  test/engine/rng_test.dart
  test/engine/game_state_test.dart
  test/engine/step_hero_test.dart
  test/engine/step_monsters_test.dart
  test/dungeon/tile_test.dart
  test/dungeon/floor_map_test.dart
  test/dungeon/fov_test.dart

packages/content/                    pure Dart, depends on core
  pubspec.yaml                       name: residuum_content; dev: test
  lib/content.dart
  lib/src/first_floor.dart           firstFloorAscii, heroSpawn, ghoulSpawns
  lib/src/new_game.dart              newGame()
  test/content_validation_test.dart

packages/app/                        flutter create --platforms=android,web
  pubspec.yaml                       flutter_bloc + path deps; dev: bloc_test
  lib/main.dart                      runApp, theme, BlocProvider
  lib/game/game_bloc.dart            GameBloc, GameBlocEvent, GameViewState
  lib/game/event_messages.dart       describeEvent(): GameEvent -> log line
  lib/game/grid_geometry.dart        GridGeometry: cells <-> screen offsets
  lib/game/glyph_grid.dart           CustomPainter + GestureDetector
  lib/game/game_screen.dart          column: grid, hp bar, log, death overlay
  test/game_bloc_test.dart
  test/grid_geometry_test.dart
```

Two files exist that the story spec's file list does not name, both deliberate:

- `lib/game/event_messages.dart` — the spec says event-to-message rendering "lives in the bloc". It lives in the bloc layer, in its own file, because a `switch` over six event types plus the bloc's own wiring makes one unwieldy file, and conventions say a large file means a concept wants splitting.
- `lib/game/grid_geometry.dart` — the build prompt requires that if tap-coordinate-to-`Position` mapping holds real logic, it is extracted into a plain testable function. It does (fit, centre, floor-divide, reject out-of-grid), so it is extracted and unit-tested.

---

## Task 1: Core package scaffold, Direction and Position

**Files:**

- Create: `packages/core/pubspec.yaml`
- Create: `packages/core/lib/core.dart`
- Create: `packages/core/lib/src/engine/position.dart`
- Create: `.gitignore` (modify: add Dart build artifacts)
- Test: `packages/core/test/engine/position_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: `enum Direction { north, south, east, west }` with `int dx,`int dy`.`class Position` with `const Position(int x, int y), `int x,`int y, `Position step(Direction),`bool isOrthogonallyAdjacentTo(Position), `Direction? directionTo(Position), value equality.

`directionTo` is an addition to the spec's `position.dart` contract. Rationale: without it the app would have to reconstruct a `Direction` from two positions, which is grid rule logic, and rules may not live in the app. It is defined in terms of `isOrthogonallyAdjacentTo` so the spec's member stays load-bearing.

- [ ] **Step 1: Create the package scaffold**

`packages/core/pubspec.yaml`:

```yaml
name: residuum_core
description: Pure Dart game rules for Residuum — turn resolution, dungeon
  geometry, combat.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.9.0

dev_dependencies:
  test: ^1.25.0
```

`packages/core/lib/core.dart`:

```dart
export 'src/engine/position.dart';
```

Append to the root `.gitignore` (it currently contains only `docs/epic/`):

```
.dart_tool/
build/
.superpowers/
packages/core/pubspec.lock
packages/content/pubspec.lock
```

`.superpowers/` holds this execution's scratch ledger and review packages. It is
process state, not the product, so it never enters a commit.

`packages/app/pubspec.lock` stays committed: app is a deployable application, core and content are libraries.

- [ ] **Step 2: Write the failing test**

`packages/core/test/engine/position_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Direction', () {
    test('north is one step up the screen', () {
      // arrange
      const direction = Direction.north;

      // act
      final delta = (direction.dx, direction.dy);

      // assert
      expect(delta, (0, -1));
    });

    test('every direction moves exactly one orthogonal tile', () {
      // arrange
      const origin = Position(4, 4);

      // act
      final steps = Direction.values.map(origin.step).toList();

      // assert
      expect(
        steps,
        containsAll(const [
          Position(4, 3),
          Position(4, 5),
          Position(5, 4),
          Position(3, 4),
        ]),
      );
    });
  });

  group('Position', () {
    test('is a value object', () {
      // arrange
      const one = Position(2, 3);
      const another = Position(2, 3);

      // act
      final same = one == another;

      // assert
      expect(same, isTrue);
      expect(one.hashCode, another.hashCode);
      expect(one.toString(), 'Position(2, 3)');
    });

    test('orthogonal neighbours are adjacent', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final adjacency =
          Direction.values.map(origin.step).map(origin.isOrthogonallyAdjacentTo);

      // assert
      expect(adjacency, everyElement(isTrue));
    });

    test('diagonal neighbours are not adjacent', () {
      // arrange
      const origin = Position(5, 5);
      const diagonals = [
        Position(4, 4),
        Position(6, 4),
        Position(4, 6),
        Position(6, 6),
      ];

      // act
      final adjacency = diagonals.map(origin.isOrthogonallyAdjacentTo);

      // assert
      expect(adjacency, everyElement(isFalse));
    });

    test('a tile is not adjacent to itself, nor to a tile two steps away', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final self = origin.isOrthogonallyAdjacentTo(origin);
      final far = origin.isOrthogonallyAdjacentTo(const Position(7, 5));

      // assert
      expect(self, isFalse);
      expect(far, isFalse);
    });

    test('directionTo names the step to an orthogonal neighbour', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final directions = [
        origin.directionTo(const Position(5, 4)),
        origin.directionTo(const Position(5, 6)),
        origin.directionTo(const Position(6, 5)),
        origin.directionTo(const Position(4, 5)),
      ];

      // assert
      expect(directions, [
        Direction.north,
        Direction.south,
        Direction.east,
        Direction.west,
      ]);
    });

    test('directionTo is null for diagonal, distant and identical tiles', () {
      // arrange
      const origin = Position(5, 5);

      // act
      final diagonal = origin.directionTo(const Position(6, 6));
      final distant = origin.directionTo(const Position(5, 9));
      final self = origin.directionTo(origin);

      // assert
      expect(diagonal, isNull);
      expect(distant, isNull);
      expect(self, isNull);
    });
  });
}
```

- [ ] **Step 3: Run the test and confirm it fails**

Run: `cd packages/core && dart pub get && dart test`
Expected: compile failure — `Direction` and `Position` are not defined.

- [ ] **Step 4: Write the implementation**

`packages/core/lib/src/engine/position.dart`:

```dart
/// The four orthogonal directions on the dungeon grid.
///
/// Screen coordinates: y grows downward, so north is negative y.
enum Direction {
  north(0, -1),
  south(0, 1),
  east(1, 0),
  west(-1, 0);

  const Direction(this.dx, this.dy);

  /// The horizontal component of one step in this direction.
  final int dx;

  /// The vertical component of one step in this direction.
  final int dy;
}

/// An immutable tile coordinate on a dungeon floor.
class Position {
  const Position(this.x, this.y);

  final int x;
  final int y;

  /// The neighbouring position one step in [direction].
  Position step(Direction direction) =>
      Position(x + direction.dx, y + direction.dy);

  /// Whether [other] is exactly one orthogonal step away.
  ///
  /// Diagonal neighbours are never adjacent: movement in Residuum is 4-way.
  bool isOrthogonallyAdjacentTo(Position other) =>
      (x - other.x).abs() + (y - other.y).abs() == 1;

  /// The direction of the single step from here to [other], or null when
  /// [other] is not orthogonally adjacent.
  Direction? directionTo(Position other) {
    if (!isOrthogonallyAdjacentTo(other)) return null;
    if (other.x > x) return Direction.east;
    if (other.x < x) return Direction.west;
    return other.y > y ? Direction.south : Direction.north;
  }

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Position($x, $y)';
}
```

- [ ] **Step 5: Run the test and confirm it passes**

Run: `cd packages/core && dart test`
Expected: all tests pass.

- [ ] **Step 6: Verify formatting and analysis**

Run: `cd packages/core && flutter analyze && dart format --set-exit-if-changed .`
Expected: "No issues found!" and exit status 0.

- [ ] **Step 7: Commit (orchestrator only)**

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add .gitignore packages/core && \
  git commit \
    -m "feat(core): add Position and Direction"
```

---

## Task 2: Seeded Rng

**Files:**

- Create: `packages/core/lib/src/engine/rng.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/engine/rng_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: `class Rng` with `Rng(int seed)` and `int rollRange(int min, int maxInclusive)`.

- [ ] **Step 1: Write the failing test**

`packages/core/test/engine/rng_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

List<int> rollTwenty(Rng rng) =>
    List.generate(20, (_) => rng.rollRange(1, 1000));

void main() {
  group('Rng', () {
    test('the same seed produces the same sequence', () {
      // arrange
      final one = Rng(42);
      final another = Rng(42);

      // act
      final first = rollTwenty(one);
      final second = rollTwenty(another);

      // assert
      expect(first, second);
    });

    test('a different seed produces a different sequence', () {
      // arrange
      final one = Rng(42);
      final another = Rng(43);

      // act
      final first = rollTwenty(one);
      final second = rollTwenty(another);

      // assert
      expect(first, isNot(second));
    });

    test('rolls stay inside the inclusive range', () {
      // arrange
      final rng = Rng(7);

      // act
      final rolls = List.generate(500, (_) => rng.rollRange(3, 5));

      // assert
      expect(rolls, everyElement(inInclusiveRange(3, 5)));
    });

    test('both ends of the range are reachable', () {
      // arrange
      final rng = Rng(7);

      // act
      final rolls = List.generate(500, (_) => rng.rollRange(3, 5));

      // assert
      expect(rolls, contains(3));
      expect(rolls, contains(5));
    });

    test('a single-value range always returns that value', () {
      // arrange
      final rng = Rng(1);

      // act
      final rolls = List.generate(10, (_) => rng.rollRange(4, 4));

      // assert
      expect(rolls, everyElement(4));
    });

    test('an inverted range is rejected', () {
      // arrange
      final rng = Rng(1);

      // act
      void roll() => rng.rollRange(5, 3);

      // assert
      expect(roll, throwsArgumentError);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd packages/core && dart test test/engine/rng_test.dart`
Expected: compile failure — `Rng` is not defined.

- [ ] **Step 3: Write the implementation**

`packages/core/lib/src/engine/rng.dart`:

```dart
import 'dart:math';

/// A seeded source of random numbers.
///
/// Every random decision in Residuum draws from an `Rng` carried in the game
/// state. Core and content never construct an unseeded [Random]: a fixed seed
/// plus a fixed sequence of calls must always produce the same game.
class Rng {
  Rng(int seed) : _random = Random(seed);

  final Random _random;

  /// A uniform integer between [min] and [maxInclusive], both ends included.
  ///
  /// Throws [ArgumentError] when [maxInclusive] is below [min].
  int rollRange(int min, int maxInclusive) {
    if (maxInclusive < min) {
      throw ArgumentError.value(
        maxInclusive,
        'maxInclusive',
        'must not be below min ($min)',
      );
    }
    return min + _random.nextInt(maxInclusive - min + 1);
  }
}
```

Add to `packages/core/lib/core.dart`:

```dart
export 'src/engine/rng.dart';
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd packages/core && dart test`
Expected: all tests pass.

- [ ] **Step 5: Verify and commit (orchestrator commits)**

Run: `cd packages/core && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/core && \
  git commit \
    -m "feat(core): add seeded Rng"
```

---

## Task 3: Tile and FloorMap

**Files:**

- Create: `packages/core/lib/src/dungeon/tile.dart`
- Create: `packages/core/lib/src/dungeon/floor_map.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/dungeon/tile_test.dart`
- Test: `packages/core/test/dungeon/floor_map_test.dart`

**Interfaces:**

- Consumes: `Position` (Task 1).
- Produces: `enum Tile { wall, floor }` with `bool walkable,`bool transparent`.`class FloorMap` with `factory FloorMap.parse(String ascii), `int width,`int height, `Tile tileAt(Position),`bool inBounds(Position), `bool isWalkable(Position),`bool isTransparent(Position)`.

- [ ] **Step 1: Write the failing tests**

`packages/core/test/dungeon/tile_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Tile', () {
    test('a wall blocks movement and sight', () {
      // arrange
      const tile = Tile.wall;

      // act
      final properties = (tile.walkable, tile.transparent);

      // assert
      expect(properties, (false, false));
    });

    test('a floor allows movement and sight', () {
      // arrange
      const tile = Tile.floor;

      // act
      final properties = (tile.walkable, tile.transparent);

      // assert
      expect(properties, (true, true));
    });
  });
}
```

`packages/core/test/dungeon/floor_map_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const twoByThree = '''
###
#.#
###''';

void main() {
  group('FloorMap.parse', () {
    test('reads the grid dimensions', () {
      // arrange
      const ascii = twoByThree;

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect((map.width, map.height), (3, 3));
    });

    test('maps # to wall and . to floor', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final centre = map.tileAt(const Position(1, 1));
      final corner = map.tileAt(const Position(0, 0));

      // assert
      expect(centre, Tile.floor);
      expect(corner, Tile.wall);
    });

    test('ignores the leading and trailing newlines of a literal', () {
      // arrange
      const ascii = '\n##\n##\n';

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect((map.width, map.height), (2, 2));
    });

    test('rejects a ragged grid', () {
      // arrange
      const ascii = '###\n##\n###';

      // act
      FloorMap parse() => FloorMap.parse(ascii);

      // assert
      expect(parse, throwsArgumentError);
    });

    test('rejects an unknown character', () {
      // arrange
      const ascii = '###\n#x#\n###';

      // act
      FloorMap parse() => FloorMap.parse(ascii);

      // assert
      expect(parse, throwsArgumentError);
    });

    test('rejects an empty floor', () {
      // arrange
      const ascii = '   ';

      // act
      FloorMap parse() => FloorMap.parse(ascii);

      // assert
      expect(parse, throwsArgumentError);
    });
  });

  group('FloorMap queries', () {
    test('a floor tile is walkable and transparent', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final centre = const Position(1, 1);

      // assert
      expect(map.isWalkable(centre), isTrue);
      expect(map.isTransparent(centre), isTrue);
    });

    test('a wall tile is neither walkable nor transparent', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final wall = const Position(0, 1);

      // assert
      expect(map.isWalkable(wall), isFalse);
      expect(map.isTransparent(wall), isFalse);
    });

    test('inBounds covers the whole grid and nothing outside it', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final inside = map.inBounds(const Position(2, 2));
      final beyond = map.inBounds(const Position(3, 2));
      final negative = map.inBounds(const Position(0, -1));

      // assert
      expect(inside, isTrue);
      expect(beyond, isFalse);
      expect(negative, isFalse);
    });

    test('positions outside the grid are neither walkable nor transparent', () {
      // arrange
      final map = FloorMap.parse(twoByThree);

      // act
      final outside = const Position(-1, 1);

      // assert
      expect(map.isWalkable(outside), isFalse);
      expect(map.isTransparent(outside), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd packages/core && dart test test/dungeon`
Expected: compile failure — `Tile` and `FloorMap` are not defined.

- [ ] **Step 3: Write the implementation**

`packages/core/lib/src/dungeon/tile.dart`:

```dart
/// One cell of dungeon terrain.
enum Tile {
  wall(walkable: false, transparent: false),
  floor(walkable: true, transparent: true);

  const Tile({required this.walkable, required this.transparent});

  /// Whether an actor may occupy this tile.
  final bool walkable;

  /// Whether sight passes through this tile.
  final bool transparent;
}
```

`packages/core/lib/src/dungeon/floor_map.dart`:

```dart
import '../engine/position.dart';
import 'tile.dart';

/// An immutable rectangular grid of dungeon terrain.
///
/// A floor map holds terrain only. Actors live in the game state, so the same
/// map can be shared by every turn of a crawl.
class FloorMap {
  const FloorMap._(this._rows);

  /// Parses a rectangular ASCII floor: `#` is wall, `.` is floor.
  ///
  /// Leading and trailing blank lines are ignored so multi-line string
  /// literals read naturally. Throws [ArgumentError] on an empty floor, a
  /// ragged row, or any other character.
  factory FloorMap.parse(String ascii) {
    final lines = ascii.trim().split('\n');
    if (lines.length < 2 || lines.first.isEmpty) {
      throw ArgumentError.value(ascii, 'ascii', 'a floor needs rows of tiles');
    }
    final width = lines.first.length;
    final rows = <List<Tile>>[];
    for (final line in lines) {
      if (line.length != width) {
        throw ArgumentError.value(
          ascii,
          'ascii',
          'ragged floor: row "$line" is not $width tiles wide',
        );
      }
      rows.add(List.unmodifiable(line.split('').map(_tileFor)));
    }
    return FloorMap._(List.unmodifiable(rows));
  }

  static Tile _tileFor(String character) => switch (character) {
    '#' => Tile.wall,
    '.' => Tile.floor,
    _ => throw ArgumentError.value(character, 'character', 'not a tile'),
  };

  final List<List<Tile>> _rows;

  /// The number of tiles across.
  int get width => _rows.first.length;

  /// The number of tiles down.
  int get height => _rows.length;

  /// Whether [position] lies on the grid.
  bool inBounds(Position position) =>
      position.x >= 0 &&
      position.y >= 0 &&
      position.x < width &&
      position.y < height;

  /// The terrain at [position], which must be [inBounds].
  Tile tileAt(Position position) => _rows[position.y][position.x];

  /// Whether an actor may stand at [position]. False outside the grid.
  bool isWalkable(Position position) =>
      inBounds(position) && tileAt(position).walkable;

  /// Whether sight passes through [position]. False outside the grid.
  bool isTransparent(Position position) =>
      inBounds(position) && tileAt(position).transparent;
}
```

Add to `packages/core/lib/core.dart`:

```dart
export 'src/dungeon/floor_map.dart';
export 'src/dungeon/tile.dart';
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd packages/core && dart test`
Expected: all tests pass.

- [ ] **Step 5: Verify and commit (orchestrator commits)**

Run: `cd packages/core && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/core && \
  git commit \
    -m "feat(core): add Tile and FloorMap"
```

---

## Task 4: Shadowcasting field of view

**Files:**

- Create: `packages/core/lib/src/dungeon/fov.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/dungeon/fov_test.dart`

**Interfaces:**

- Consumes: `Position,`FloorMap` (Tasks 1, 3).
- Produces: `const int fovRadius = 8;` and `Set<Position> computeFov(FloorMap map, Position origin, int radius)`.

**Design decisions this task locks in, both required to be argued in dartdoc:**

1. **Distance metric: Euclidean**, compared as squared distance to keep it in integers. A Chebyshev (square) light pool reads as a rendering bug on a glyph grid; a Manhattan (diamond) pool hides the corners of the room the hero is standing in. Euclidean is the roguelike default for exactly that reason.
2. **Wall visibility.** The story spec asks that "walls bordering a visible floor tile are visible". Recursive shadowcasting lights a wall at the moment it scans it, before treating it as a blocker, so lit rooms get lit edges for free. Task step 2 below tests that claim directly rather than assuming it. If the closed-room test passes with plain shadowcasting, no extra pass is added and the dartdoc records that the rule holds naturally. If it fails, add exactly this narrow post-pass and no more, then report the deviation to the architect:

```dart
    for (final lit in visible.toList()) {
      if (!map.isTransparent(lit)) continue;
      for (final direction in Direction.values) {
        final neighbour = lit.step(direction);
        if (map.inBounds(neighbour) && !map.isTransparent(neighbour)) {
          visible.add(neighbour);
        }
      }
    }
```

That post-pass can only ever add walls next to already-visible floor, never floor, so occlusion is unaffected — a wall on the far side of another wall is not next to any visible floor.

- [ ] **Step 1: Write the failing test**

`packages/core/test/dungeon/fov_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

FloorMap openField(int width, int height) => FloorMap.parse(
  List.generate(height, (_) => '.' * width).join('\n'),
);

const occluded = '''
.......
.......
..###..
.......
.......''';

const closedRoom = '''
#####
#...#
#...#
#...#
#####''';

void main() {
  group('computeFov', () {
    test('always includes the origin, even inside a wall', () {
      // arrange
      final map = FloorMap.parse(closedRoom);
      const origin = Position(0, 0);

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, contains(origin));
    });

    test('lights an open field out to the radius', () {
      // arrange
      final map = openField(15, 15);
      const origin = Position(7, 7);

      // act
      final visible = computeFov(map, origin, 3);

      // assert
      expect(visible, contains(const Position(10, 7)));
      expect(visible, contains(const Position(7, 4)));
      expect(visible, contains(const Position(4, 7)));
      expect(visible, contains(const Position(7, 10)));
    });

    test('stops at the radius', () {
      // arrange
      final map = openField(15, 15);
      const origin = Position(7, 7);

      // act
      final visible = computeFov(map, origin, 3);

      // assert
      expect(visible, isNot(contains(const Position(11, 7))));
      expect(visible, isNot(contains(const Position(7, 11))));
    });

    test('the lit area is a circle, not a square', () {
      // arrange
      final map = openField(15, 15);
      const origin = Position(7, 7);

      // act
      final visible = computeFov(map, origin, 3);

      // assert
      expect(visible, contains(const Position(9, 9)));
      expect(visible, isNot(contains(const Position(10, 10))));
    });

    test('does not see past a wall', () {
      // arrange
      final map = FloorMap.parse(occluded);
      const origin = Position(3, 4);

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, contains(const Position(3, 3)));
      expect(visible, isNot(contains(const Position(3, 1))));
      expect(visible, isNot(contains(const Position(3, 0))));
    });

    test('lights the wall that blocks the view', () {
      // arrange
      final map = FloorMap.parse(occluded);
      const origin = Position(3, 4);

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, contains(const Position(3, 2)));
    });

    test('lights every wall of the room the hero stands in', () {
      // arrange
      final map = FloorMap.parse(closedRoom);
      const origin = Position(2, 2);
      final walls = <Position>{
        for (var x = 0; x < 5; x++) Position(x, 0),
        for (var x = 0; x < 5; x++) Position(x, 4),
        for (var y = 0; y < 5; y++) Position(0, y),
        for (var y = 0; y < 5; y++) Position(4, y),
      };

      // act
      final visible = computeFov(map, origin, 8);

      // assert
      expect(visible, containsAll(walls));
    });

    test('is deterministic', () {
      // arrange
      final map = FloorMap.parse(occluded);
      const origin = Position(3, 4);

      // act
      final first = computeFov(map, origin, 8);
      final second = computeFov(map, origin, 8);

      // assert
      expect(first, second);
    });

    test('the hero sight radius is eight tiles', () {
      // arrange
      const expected = 8;

      // act
      final actual = fovRadius;

      // assert
      expect(actual, expected);
    });
  });
}
```

Note on the "lights every wall" test: the four corners of `closedRoom` are the
interesting ones — a corner wall touches visible floor only diagonally. The
expectation is a **set** literal, not a list: the two comprehension loops overlap
at the corners, and `containsAll` matches one-to-one, so a list would demand each
corner appear twice in a `Set` and could never pass. Keep all 16 positions
required.

Measured result: plain recursive shadowcasting lights all 16 wall tiles,
corners included, so **no post-pass is needed** and the story spec's
"walls bordering a visible floor tile are visible" rule holds naturally.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd packages/core && dart test test/dungeon/fov_test.dart`
Expected: compile failure — `computeFov` and `fovRadius` are not defined.

- [ ] **Step 3: Write the implementation**

`packages/core/lib/src/dungeon/fov.dart`:

```dart
import '../engine/position.dart';
import 'floor_map.dart';

/// How far the hero sees on a dungeon floor, in tiles.
const int fovRadius = 8;

/// The positions visible from [origin] within [radius].
///
/// Recursive shadowcasting across the eight octants, testing
/// [FloorMap.isTransparent]. Distance is **Euclidean**, compared as squared
/// distance so no square roots are taken: the lit pool is a circle. Chebyshev
/// distance was rejected because a square pool of light reads as a rendering
/// bug on a glyph grid, and Manhattan distance because a diamond pool hides
/// the corners of the very room the hero is standing in.
///
/// The [origin] is always visible. A wall is lit at the moment the scan
/// reaches it, before it starts casting its shadow, so the walls bordering a
/// lit floor are lit and rooms render with edges.
Set<Position> computeFov(FloorMap map, Position origin, int radius) {
  final visible = <Position>{origin};
  for (final octant in _octants) {
    _castLight(map, origin, radius, 1, 1, 0, octant, visible);
  }
  return visible;
}

const _octants = <(int, int, int, int)>[
  (1, 0, 0, 1),
  (0, 1, 1, 0),
  (0, -1, 1, 0),
  (-1, 0, 0, 1),
  (-1, 0, 0, -1),
  (0, -1, -1, 0),
  (0, 1, -1, 0),
  (1, 0, 0, -1),
];

void _castLight(
  FloorMap map,
  Position origin,
  int radius,
  int row,
  double start,
  double end,
  (int, int, int, int) octant,
  Set<Position> visible,
) {
  if (start < end) return;
  final (xx, xy, yx, yy) = octant;
  var newStart = start;
  var blocked = false;
  for (var distance = row; distance <= radius && !blocked; distance++) {
    final deltaY = -distance;
    for (var deltaX = -distance; deltaX <= 0; deltaX++) {
      final current = Position(
        origin.x + deltaX * xx + deltaY * xy,
        origin.y + deltaX * yx + deltaY * yy,
      );
      final leftSlope = (deltaX - 0.5) / (deltaY + 0.5);
      final rightSlope = (deltaX + 0.5) / (deltaY - 0.5);
      if (!map.inBounds(current) || start < rightSlope) continue;
      if (end > leftSlope) break;

      if (deltaX * deltaX + deltaY * deltaY <= radius * radius) {
        visible.add(current);
      }
      if (blocked) {
        if (!map.isTransparent(current)) {
          newStart = rightSlope;
          continue;
        }
        blocked = false;
        start = newStart;
      } else if (!map.isTransparent(current) && distance < radius) {
        blocked = true;
        _castLight(
          map,
          origin,
          radius,
          distance + 1,
          start,
          leftSlope,
          octant,
          visible,
        );
        newStart = rightSlope;
      }
    }
  }
}
```

Add to `packages/core/lib/core.dart`:

```dart
export 'src/dungeon/fov.dart';
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd packages/core && dart test`
Expected: all tests pass. If only the "lights every wall of the room" test fails, apply the post-pass from the design note, re-run, and record the deviation for the final report.

- [ ] **Step 5: Verify and commit (orchestrator commits)**

Run: `cd packages/core && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/core && \
  git commit \
    -m "feat(core): add shadowcasting field of view"
```

---

## Task 5: Actor, actions, events, game state

**Files:**

- Create: `packages/core/lib/src/engine/actor.dart`
- Create: `packages/core/lib/src/engine/action.dart`
- Create: `packages/core/lib/src/engine/event.dart`
- Create: `packages/core/lib/src/engine/game_state.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/engine/game_state_test.dart`

**Interfaces:**

- Consumes: `Position,`Rng, `FloorMap` (Tasks 1–3).
- Produces:
  - `class Actor` — `Actor({required String id, required String glyph, required Position position, required int hp, required int maxHp, required int attackMin, required int attackMax}),`bool get isAlive, `Actor copyWith({Position? position, int? hp})`.
  - `sealed class GameAction`; `final class MoveAction extends GameAction` with `MoveAction(Direction direction)`.
  - `sealed class GameEvent`; `ActorMoved({required String actorId, required Position from, required Position to}),`MoveBlocked({required String actorId, required Position at}), `AttackHit({required String attackerId, required String targetId, required int damage}),`ActorDied({required String actorId}), `GameOver()`. All with value equality.
  - `class GameState` — `GameState({required FloorMap map, required Actor hero, required List<Actor> monsters, required Rng rng, required Set<Position> visible, required Set<Position> explored, bool isGameOver = false}),`Actor? monsterAt(Position), `GameState copyWith({Actor? hero, List<Actor>? monsters, Set<Position>? visible, Set<Position>? explored, bool? isGameOver})`.

- [ ] **Step 1: Write the failing test**

`packages/core/test/engine/game_state_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Actor', () {
    test('is alive while it has hit points', () {
      // arrange
      const actor = Actor(
        id: 'hero',
        glyph: '@',
        position: Position(1, 1),
        hp: 1,
        maxHp: 20,
        attackMin: 3,
        attackMax: 5,
      );

      // act
      final alive = actor.isAlive;
      final dead = actor.copyWith(hp: 0).isAlive;

      // assert
      expect(alive, isTrue);
      expect(dead, isFalse);
    });

    test('copyWith keeps every untouched field', () {
      // arrange
      const actor = Actor(
        id: 'ghoul-1',
        glyph: 'g',
        position: Position(4, 4),
        hp: 10,
        maxHp: 10,
        attackMin: 2,
        attackMax: 4,
      );

      // act
      final moved = actor.copyWith(position: const Position(5, 4));

      // assert
      expect(moved.id, 'ghoul-1');
      expect(moved.glyph, 'g');
      expect(moved.hp, 10);
      expect(moved.maxHp, 10);
      expect(moved.attackMin, 2);
      expect(moved.attackMax, 4);
      expect(moved.position, const Position(5, 4));
    });
  });

  group('GameEvent', () {
    test('events are value objects', () {
      // arrange
      const moved = ActorMoved(
        actorId: 'hero',
        from: Position(1, 1),
        to: Position(1, 2),
      );

      // act
      final events = <GameEvent>[
        const ActorMoved(
          actorId: 'hero',
          from: Position(1, 1),
          to: Position(1, 2),
        ),
        const AttackHit(attackerId: 'hero', targetId: 'ghoul-1', damage: 4),
        const MoveBlocked(actorId: 'hero', at: Position(0, 1)),
        const ActorDied(actorId: 'ghoul-1'),
        const GameOver(),
      ];

      // assert
      expect(events, contains(moved));
      expect(
        events,
        contains(
          const AttackHit(attackerId: 'hero', targetId: 'ghoul-1', damage: 4),
        ),
      );
      expect(events, contains(const MoveBlocked(actorId: 'hero', at: Position(0, 1))));
      expect(events, contains(const ActorDied(actorId: 'ghoul-1')));
      expect(events, contains(const GameOver()));
      expect(moved.hashCode, events.first.hashCode);
    });

    test('events with different fields are not equal', () {
      // arrange
      const one = AttackHit(
        attackerId: 'hero',
        targetId: 'ghoul-1',
        damage: 4,
      );

      // act
      const another = AttackHit(
        attackerId: 'hero',
        targetId: 'ghoul-1',
        damage: 5,
      );

      // assert
      expect(one, isNot(another));
    });
  });

  group('GameState', () {
    test('finds the monster standing on a tile', () {
      // arrange
      final state = GameState(
        map: FloorMap.parse('###\n#.#\n###'),
        hero: const Actor(
          id: 'hero',
          glyph: '@',
          position: Position(1, 1),
          hp: 20,
          maxHp: 20,
          attackMin: 3,
          attackMax: 5,
        ),
        monsters: const [
          Actor(
            id: 'ghoul-1',
            glyph: 'g',
            position: Position(2, 1),
            hp: 10,
            maxHp: 10,
            attackMin: 2,
            attackMax: 4,
          ),
        ],
        rng: Rng(1),
        visible: const {Position(1, 1)},
        explored: const {Position(1, 1)},
      );

      // act
      final found = state.monsterAt(const Position(2, 1));
      final empty = state.monsterAt(const Position(1, 1));

      // assert
      expect(found?.id, 'ghoul-1');
      expect(empty, isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd packages/core && dart test test/engine/game_state_test.dart`
Expected: compile failure — `Actor, the events and`GameState` are not defined.

- [ ] **Step 3: Write the implementation**

`packages/core/lib/src/engine/actor.dart`:

```dart
import 'position.dart';

/// One living thing on a dungeon floor: the hero, or a monster.
class Actor {
  const Actor({
    required this.id,
    required this.glyph,
    required this.position,
    required this.hp,
    required this.maxHp,
    required this.attackMin,
    required this.attackMax,
  });

  /// Unique within a crawl: `hero, or `ghoul-1`.
  final String id;

  /// The single character this actor draws as.
  final String glyph;

  final Position position;
  final int hp;
  final int maxHp;

  /// The lowest damage a hit from this actor deals.
  final int attackMin;

  /// The highest damage a hit from this actor deals.
  final int attackMax;

  /// Whether this actor still has hit points.
  bool get isAlive => hp > 0;

  /// A copy with a new [position] or [hp]; everything else is carried over.
  Actor copyWith({Position? position, int? hp}) => Actor(
    id: id,
    glyph: glyph,
    position: position ?? this.position,
    hp: hp ?? this.hp,
    maxHp: maxHp,
    attackMin: attackMin,
    attackMax: attackMax,
  );

  @override
  String toString() => 'Actor($id at $position, $hp/$maxHp hp)';
}
```

`packages/core/lib/src/engine/action.dart`:

```dart
import 'position.dart';

/// Something the player asks the game to do. One action is one turn.
sealed class GameAction {
  const GameAction();
}

/// Step the hero one tile, or attack whatever stands there.
final class MoveAction extends GameAction {
  const MoveAction(this.direction);

  final Direction direction;
}
```

`packages/core/lib/src/engine/event.dart`:

```dart
import 'position.dart';

/// Something that happened during a turn.
///
/// Events are value objects so tests can assert on them directly, and they are
/// the only channel by which the message log, the renderer and later the quest
/// triggers learn what the rules did.
sealed class GameEvent {
  const GameEvent();
}

/// An actor walked from one tile to another.
final class ActorMoved extends GameEvent {
  const ActorMoved({
    required this.actorId,
    required this.from,
    required this.to,
  });

  final String actorId;
  final Position from;
  final Position to;

  @override
  bool operator ==(Object other) =>
      other is ActorMoved &&
      other.actorId == actorId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(actorId, from, to);

  @override
  String toString() => 'ActorMoved($actorId, $from -> $to)';
}

/// An actor tried to walk into something it could not enter.
final class MoveBlocked extends GameEvent {
  const MoveBlocked({required this.actorId, required this.at});

  final String actorId;
  final Position at;

  @override
  bool operator ==(Object other) =>
      other is MoveBlocked && other.actorId == actorId && other.at == at;

  @override
  int get hashCode => Object.hash(actorId, at);

  @override
  String toString() => 'MoveBlocked($actorId, at $at)';
}

/// An attack landed for [damage] hit points.
final class AttackHit extends GameEvent {
  const AttackHit({
    required this.attackerId,
    required this.targetId,
    required this.damage,
  });

  final String attackerId;
  final String targetId;
  final int damage;

  @override
  bool operator ==(Object other) =>
      other is AttackHit &&
      other.attackerId == attackerId &&
      other.targetId == targetId &&
      other.damage == damage;

  @override
  int get hashCode => Object.hash(attackerId, targetId, damage);

  @override
  String toString() => 'AttackHit($attackerId -> $targetId, $damage)';
}

/// An actor ran out of hit points.
final class ActorDied extends GameEvent {
  const ActorDied({required this.actorId});

  final String actorId;

  @override
  bool operator ==(Object other) =>
      other is ActorDied && other.actorId == actorId;

  @override
  int get hashCode => actorId.hashCode;

  @override
  String toString() => 'ActorDied($actorId)';
}

/// The crawl is over: the hero is dead.
final class GameOver extends GameEvent {
  const GameOver();

  @override
  bool operator ==(Object other) => other is GameOver;

  @override
  int get hashCode => (GameOver).hashCode;

  @override
  String toString() => 'GameOver()';
}
```

`packages/core/lib/src/engine/game_state.dart`:

```dart
import '../dungeon/floor_map.dart';
import 'actor.dart';
import 'position.dart';
import 'rng.dart';

/// The whole state of one crawl.
///
/// Every field is immutable except [rng], which is carried by reference and
/// advances as rolls are drawn. That is a deliberate, documented exception to
/// the immutable-state rule: threading a fresh generator out of every combat
/// roll would put a return value on every rule function for no gain in
/// testability. Determinism survives it, because determinism here means "the
/// same seed plus the same sequence of actions produces the same game" — the
/// generator advances once per roll, in rule order, so a replayed action
/// sequence draws the same numbers. Nothing relies on re-reading an earlier
/// roll after a *different* action sequence, and nothing may start to.
class GameState {
  const GameState({
    required this.map,
    required this.hero,
    required this.monsters,
    required this.rng,
    required this.visible,
    required this.explored,
    this.isGameOver = false,
  });

  final FloorMap map;
  final Actor hero;

  /// Living monsters only. The dead are removed, not flagged.
  final List<Actor> monsters;

  final Rng rng;

  /// What the hero can see from where it now stands.
  final Set<Position> visible;

  /// Every tile the hero has ever seen, drawn dimmed when out of sight.
  final Set<Position> explored;

  final bool isGameOver;

  /// The living monster standing on [position], or null when none does.
  Actor? monsterAt(Position position) {
    for (final monster in monsters) {
      if (monster.position == position) return monster;
    }
    return null;
  }

  GameState copyWith({
    Actor? hero,
    List<Actor>? monsters,
    Set<Position>? visible,
    Set<Position>? explored,
    bool? isGameOver,
  }) => GameState(
    map: map,
    hero: hero ?? this.hero,
    monsters: monsters ?? this.monsters,
    rng: rng,
    visible: visible ?? this.visible,
    explored: explored ?? this.explored,
    isGameOver: isGameOver ?? this.isGameOver,
  );
}
```

Add to `packages/core/lib/core.dart`:

```dart
export 'src/engine/action.dart';
export 'src/engine/actor.dart';
export 'src/engine/event.dart';
export 'src/engine/game_state.dart';
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd packages/core && dart test`
Expected: all tests pass.

- [ ] **Step 5: Verify and commit (orchestrator commits)**

Run: `cd packages/core && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/core && \
  git commit \
    -m "feat(core): add actors, actions, events and game state"
```

---

## Task 6: step() — the hero's turn

**Files:**

- Create: `packages/core/lib/src/engine/step.dart`
- Create: `packages/core/test/support/fixtures.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/engine/step_hero_test.dart`

**Interfaces:**

- Consumes: everything from Tasks 1–5.
- Produces: `(GameState, List<GameEvent>) step(GameState state, GameAction action)`.
- Produces (test-only): `fixtures.dart` with `GameState crawl({required String ascii, required Position heroAt, List<Actor> monsters = const [], int heroHp = 20, int heroAttack = 4, int seed = 1})` and `Actor ghoul(String id, Position at, {int hp = 10, int attack = 3})`.

This task builds only the hero half of the contract (steps 1, 2 and 5 of the spec's resolution order). Task 7 adds the monster phase and the death check. Splitting there is deliberate: the hero phase is independently testable, and the spec's own mutation table wants proof that hero-turn tests do not lean on the monster phase.

The fixtures give actors `attackMin == attackMax` so damage assertions are exact without mocking `Rng` — the spec forbids mocking it.

- [ ] **Step 1: Write the shared fixtures**

`packages/core/test/support/fixtures.dart`:

```dart
import 'package:residuum_core/core.dart';

Actor hero(Position at, {int hp = 20, int attack = 4, int? attackMax}) => Actor(
  id: 'hero',
  glyph: '@',
  position: at,
  hp: hp,
  maxHp: 20,
  attackMin: attack,
  attackMax: attackMax ?? attack,
);

Actor ghoul(String id, Position at, {int hp = 10, int attack = 3}) => Actor(
  id: id,
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
);

GameState crawl({
  required String ascii,
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
  int heroAttack = 4,
  int? heroAttackMax,
  int seed = 1,
}) {
  final map = FloorMap.parse(ascii);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: hero(
      heroAt,
      hp: heroHp,
      attack: heroAttack,
      attackMax: heroAttackMax,
    ),
    monsters: monsters,
    rng: Rng(seed),
    visible: visible,
    explored: {...visible},
  );
}
```

Damage assertions elsewhere rely on `attackMin == attackMax, which is the
default.`heroAttackMax` exists only for the determinism test, which needs
damage that genuinely varies — the spec forbids mocking `Rng, so the only way
to test a random roll is to let it roll.

- [ ] **Step 2: Write the failing test**

`packages/core/test/engine/step_hero_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const room = '''
#######
#.....#
#.....#
#.....#
#######''';

void main() {
  group('step, hero movement', () {
    test('walks into open floor', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(3, 2));

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.hero.position, const Position(4, 2));
      expect(
        events,
        contains(
          const ActorMoved(
            actorId: 'hero',
            from: Position(3, 2),
            to: Position(4, 2),
          ),
        ),
      );
    });

    test('is blocked by a wall and does not move', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(1, 2));

      // act
      final (next, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(next.hero.position, const Position(1, 2));
      expect(
        events,
        contains(const MoveBlocked(actorId: 'hero', at: Position(0, 2))),
      );
    });

    test('leaves the input state untouched', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(3, 2));

      // act
      step(state, const MoveAction(Direction.east));

      // assert
      expect(state.hero.position, const Position(3, 2));
    });

    test('grows the explored set and never shrinks it', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(1, 1));
      final before = state.explored;

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.explored, containsAll(before));
      expect(next.explored, containsAll(next.visible));
    });

    test('recomputes what is visible from where the hero lands', () {
      // arrange
      final state = crawl(ascii: room, heroAt: const Position(1, 1));

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.visible, computeFov(next.map, const Position(2, 1), fovRadius));
    });
  });

  group('step, hero attacks', () {
    test('bumping a monster attacks it instead of moving', () {
      // arrange
      final state = crawl(
        ascii: room,
        heroAt: const Position(3, 2),
        heroAttack: 4,
        monsters: [ghoul('ghoul-1', const Position(4, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.hero.position, const Position(3, 2));
      expect(
        events,
        contains(
          const AttackHit(
            attackerId: 'hero',
            targetId: 'ghoul-1',
            damage: 4,
          ),
        ),
      );
      expect(next.monsters.single.hp, 6);
    });

    test('a killing blow removes the monster and reports the death', () {
      // arrange
      final state = crawl(
        ascii: room,
        heroAt: const Position(3, 2),
        heroAttack: 4,
        monsters: [ghoul('ghoul-1', const Position(4, 2), hp: 3)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters, isEmpty);
      expect(events, contains(const ActorDied(actorId: 'ghoul-1')));
    });

    test('damage comes from the seeded rng, so a seed replays exactly', () {
      // arrange
      GameState fresh() => crawl(
        ascii: room,
        heroAt: const Position(3, 2),
        heroAttack: 3,
        heroAttackMax: 5,
        monsters: [ghoul('ghoul-1', const Position(4, 2), hp: 200)],
        seed: 99,
      );

      // act
      final first = _damageSequence(fresh());
      final second = _damageSequence(fresh());

      // assert
      expect(first, second);
      expect(first, everyElement(inInclusiveRange(3, 5)));
      expect(first.toSet().length, greaterThan(1));
    });
  });
}

List<int> _damageSequence(GameState state) {
  final damage = <int>[];
  var current = state;
  for (var turn = 0; turn < 5; turn++) {
    final (next, events) = step(current, const MoveAction(Direction.east));
    damage.addAll(
      events
          .whereType<AttackHit>()
          .where((event) => event.attackerId == 'hero')
          .map((event) => event.damage),
    );
    current = next;
  }
  return damage;
}
```

The determinism test is the one place a hero rolls 3–5 rather than a fixed
number, because a replay assertion over a constant sequence proves nothing. If
seed 99 happens to draw five identical values, the
`first.toSet().length` assertion fails — change the seed until the sequence
varies, and do not weaken the assertion. The ghoul is given 200 hit points so
it survives all five bumps and the sequence is five hero rolls long.

- [ ] **Step 3: Run the test and confirm it fails**

Run: `cd packages/core && dart test test/engine/step_hero_test.dart`
Expected: compile failure — `step` is not defined.

- [ ] **Step 4: Write the implementation**

`packages/core/lib/src/engine/step.dart`:

```dart
import '../dungeon/fov.dart';
import 'action.dart';
import 'actor.dart';
import 'event.dart';
import 'game_state.dart';

/// Advances the crawl by one hero [action].
///
/// A blocked move still consumes the turn. Bumping a wall costs exactly as
/// much time as bumping a ghoul, which is the classic roguelike rule and a
/// deliberate balance decision: if wall-bumps were free the player could probe
/// the dark edges of a room, learn its shape and re-plan without the dungeon
/// ever acting, which turns fog of war from a risk into a free scouting tool.
(GameState, List<GameEvent>) step(GameState state, GameAction action) {
  if (state.isGameOver) return (state, const []);

  final events = <GameEvent>[];
  final monsters = [...state.monsters];
  var hero = state.hero;

  switch (action) {
    case MoveAction(:final direction):
      final target = hero.position.step(direction);
      final defending = monsters.indexWhere(
        (monster) => monster.position == target,
      );
      if (defending >= 0) {
        final damage = state.rng.rollRange(hero.attackMin, hero.attackMax);
        final defender = monsters[defending];
        events.add(
          AttackHit(
            attackerId: hero.id,
            targetId: defender.id,
            damage: damage,
          ),
        );
        final wounded = defender.copyWith(hp: defender.hp - damage);
        if (wounded.isAlive) {
          monsters[defending] = wounded;
        } else {
          monsters.removeAt(defending);
          events.add(ActorDied(actorId: defender.id));
        }
      } else if (state.map.isWalkable(target)) {
        events.add(
          ActorMoved(actorId: hero.id, from: hero.position, to: target),
        );
        hero = hero.copyWith(position: target);
      } else {
        events.add(MoveBlocked(actorId: hero.id, at: target));
      }
  }

  final visible = computeFov(state.map, hero.position, fovRadius);
  return (
    state.copyWith(
      hero: hero,
      monsters: monsters,
      visible: visible,
      explored: {...state.explored...visible},
    ),
    events,
  );
}
```

Add to `packages/core/lib/core.dart`:

```dart
export 'src/engine/step.dart';
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `cd packages/core && dart test`
Expected: all tests pass.

- [ ] **Step 6: Verify and commit (orchestrator commits)**

Run: `cd packages/core && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/core && \
  git commit \
    -m "feat(core): resolve the hero's turn in step"
```

---

## Task 7: step() — monster turns, hero death, game over

**Files:**

- Modify: `packages/core/lib/src/engine/step.dart`
- Test: `packages/core/test/engine/step_monsters_test.dart`

**Interfaces:**

- Consumes: everything from Tasks 1–6.
- Produces: no new public names. `step` gains the monster phase, the hero death check and `isGameOver`.

Chase rule, from the spec, implemented exactly: each monster either attacks an orthogonally adjacent hero, or takes one greedy step — the axis with the larger absolute delta first, x on a tie, falling back to the other axis when the first is blocked, standing still when both are. Occupancy is checked against the hero and the *working* monster list, so a monster that has already moved this turn blocks the one behind it.

**Two properties to verify while implementing, both flagged by the build prompt as suspect:**

- *Oscillation:* a successful greedy step always reduces the Manhattan distance to the hero by one and never increases the other axis, so a monster cannot oscillate while the hero stands still. Confirm this holds in the code and pin it with the "closes distance every turn" test below.
- *Monster-on-monster:* the occupancy check must include monsters already moved this turn. The "does not step onto another monster" test pins it.

- [ ] **Step 1: Write the failing test**

`packages/core/test/engine/step_monsters_test.dart`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const hall = '''
##########
#........#
#........#
#........#
##########''';

const corridor = '''
#####
#...#
###.#
#...#
#####''';

const pocket = '''
#####
#.#.#
#.###
#...#
#####''';

void main() {
  group('step, monster turns', () {
    test('a distant monster takes one step toward the hero', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(7, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, const Position(6, 2));
      expect(
        events,
        contains(
          const ActorMoved(
            actorId: 'ghoul-1',
            from: Position(7, 2),
            to: Position(6, 2),
          ),
        ),
      );
    });

    test('an adjacent monster claws the hero instead of moving', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters.single.position, const Position(3, 2));
      expect(
        events,
        contains(
          const AttackHit(
            attackerId: 'ghoul-1',
            targetId: 'hero',
            damage: 3,
          ),
        ),
      );
      expect(next.hero.hp, 17);
    });

    test('a blocked move still costs the turn: monsters act anyway', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [ghoul('ghoul-1', const Position(7, 2))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.west));

      // assert
      expect(next.hero.position, const Position(1, 2));
      expect(next.monsters.single.position, const Position(6, 2));
      expect(events, contains(const MoveBlocked(actorId: 'hero', at: Position(0, 2))));
    });

    test('on equal deltas the monster prefers the x axis', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(4, 3))],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, const Position(3, 3));
    });

    test('a monster blocked on its preferred axis tries the other one', () {
      // arrange
      final state = crawl(
        ascii: corridor,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(1, 3))],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters.single.position, const Position(2, 3));
    });

    test('a monster with no open step stands still and says nothing', () {
      // arrange
      final state = crawl(
        ascii: pocket,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1))],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.south));

      // assert
      expect(next.monsters.single.position, const Position(3, 1));
      expect(
        events.whereType<ActorMoved>().map((event) => event.actorId),
        isNot(contains('ghoul-1')),
      );
    });

    test('a monster does not step onto a monster that already moved', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(1, 2),
        monsters: [
          ghoul('ghoul-1', const Position(2, 2)),
          ghoul('ghoul-2', const Position(3, 2)),
        ],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.monsters[0].position, const Position(2, 2));
      expect(next.monsters[1].position, const Position(3, 2));
    });

    test('two chasing monsters never share a tile', () {
      // arrange
      var state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [
          ghoul('ghoul-1', const Position(7, 3)),
          ghoul('ghoul-2', const Position(8, 3)),
        ],
      );

      // act
      for (var turn = 0; turn < 8; turn++) {
        final (next, _) = step(state, const MoveAction(Direction.west));
        state = next;
      }

      // assert
      final positions = state.monsters.map((m) => m.position).toList();
      expect(positions.toSet(), hasLength(positions.length));
    });

    test('a chasing monster closes the distance every turn', () {
      // arrange
      var state = crawl(
        ascii: hall,
        heroAt: const Position(1, 1),
        monsters: [ghoul('ghoul-1', const Position(8, 3))],
      );
      final distances = <int>[];

      // act
      for (var turn = 0; turn < 6; turn++) {
        final monster = state.monsters.single.position;
        distances.add(
          (monster.x - state.hero.position.x).abs() +
              (monster.y - state.hero.position.y).abs(),
        );
        final (next, _) = step(state, const MoveAction(Direction.west));
        state = next;
      }

      // assert
      expect(distances, orderedEquals(<int>[9, 8, 7, 6, 5, 4]));
    });

    test('a monster never walks onto the hero', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [ghoul('ghoul-1', const Position(4, 2))],
      );

      // act
      final (next, _) = step(state, const MoveAction(Direction.north));

      // assert
      expect(next.monsters.single.position, isNot(next.hero.position));
    });
  });

  group('step, the hero dies', () {
    test('a lethal claw reports the death and ends the game', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        heroHp: 3,
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );

      // act
      final (next, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(next.hero.isAlive, isFalse);
      expect(next.isGameOver, isTrue);
      expect(events, contains(const ActorDied(actorId: 'hero')));
      expect(events, contains(const GameOver()));
    });

    test('the game over event comes after the death', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        heroHp: 2,
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );

      // act
      final (_, events) = step(state, const MoveAction(Direction.east));

      // assert
      expect(
        events.indexOf(const ActorDied(actorId: 'hero')),
        lessThan(events.indexOf(const GameOver())),
      );
    });

    test('an action after game over changes nothing', () {
      // arrange
      final state = crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        heroHp: 2,
        monsters: [ghoul('ghoul-1', const Position(3, 2), attack: 3)],
      );
      final (dead, _) = step(state, const MoveAction(Direction.east));

      // act
      final (after, events) = step(dead, const MoveAction(Direction.west));

      // assert
      expect(events, isEmpty);
      expect(after.hero.position, dead.hero.position);
      expect(after.hero.hp, dead.hero.hp);
      expect(after.monsters.length, dead.monsters.length);
      expect(after.isGameOver, isTrue);
    });

    test('monster damage is drawn from the seeded rng', () {
      // arrange
      GameState fresh() => crawl(
        ascii: hall,
        heroAt: const Position(2, 2),
        monsters: [
          Actor(
            id: 'ghoul-1',
            glyph: 'g',
            position: const Position(3, 2),
            hp: 10,
            maxHp: 10,
            attackMin: 2,
            attackMax: 4,
          ),
        ],
        seed: 5,
      );

      // act
      final (_, first) = step(fresh(), const MoveAction(Direction.east));
      final (_, second) = step(fresh(), const MoveAction(Direction.east));
      final damage = first
          .whereType<AttackHit>()
          .where((event) => event.attackerId == 'ghoul-1')
          .map((event) => event.damage)
          .toList();

      // assert
      expect(first, second);
      expect(damage.single, inInclusiveRange(2, 4));
    });
  });
}
```

**Why each test's action direction matters.** The monster phase runs *after*
the hero has moved, so adjacency is judged against the hero's **final**
position. Every test above that wants a monster to attack therefore makes the
hero bump the monster (attack in place) or bump a wall, never step away — a
hero that walks west from `Position(2, 2)` leaves a ghoul at `Position(3, 2)`
two tiles behind, and the ghoul walks instead of clawing. The same reasoning
fixes the equal-deltas test: the hero ends at `Position(2, 1), which is where
the deltas to`Position(4, 3)` come out equal.

In the `pocket` map, the ghoul at `Position(3, 1)` is sealed in a one-tile
alcove: its only horizontal candidate, `Position(2, 1), is wall, and after the
hero steps south to`Position(1, 2)` its vertical candidate, `Position(3, 2),
is wall too. Both axes blocked, so it stands still and emits nothing.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd packages/core && dart test test/engine/step_monsters_test.dart`
Expected: failures — no monster ever moves or attacks, and `isGameOver` stays false.

- [ ] **Step 3: Write the implementation**

In `packages/core/lib/src/engine/step.dart, insert the monster phase and death check between the hero`switch` and the field-of-view recompute, and add the private chase helper:

```dart
  for (var index = 0; index < monsters.length; index++) {
    final monster = monsters[index];
    if (monster.position.isOrthogonallyAdjacentTo(hero.position)) {
      final damage = state.rng.rollRange(monster.attackMin, monster.attackMax);
      events.add(
        AttackHit(
          attackerId: monster.id,
          targetId: hero.id,
          damage: damage,
        ),
      );
      hero = hero.copyWith(hp: hero.hp - damage);
      continue;
    }
    final target = _chaseStep(state.map, monster, hero, monsters);
    if (target == null) continue;
    events.add(
      ActorMoved(actorId: monster.id, from: monster.position, to: target),
    );
    monsters[index] = monster.copyWith(position: target);
  }

  if (!hero.isAlive) {
    events.add(ActorDied(actorId: hero.id));
    events.add(const GameOver());
  }
```

and pass `isGameOver: !hero.isAlive` in the returned `copyWith`. The helper:

```dart
Position? _chaseStep(
  FloorMap map,
  Actor monster,
  Actor hero,
  List<Actor> monsters,
) {
  final deltaX = hero.position.x - monster.position.x;
  final deltaY = hero.position.y - monster.position.y;
  final horizontal = deltaX == 0
      ? null
      : (deltaX > 0 ? Direction.east : Direction.west);
  final vertical = deltaY == 0
      ? null
      : (deltaY > 0 ? Direction.south : Direction.north);
  final candidates = deltaX.abs() >= deltaY.abs()
      ? [horizontal, vertical]
      : [vertical, horizontal];
  final occupied = <Position>{
    hero.position,
    for (final other in monsters)
      if (other.id != monster.id) other.position,
  };
  for (final direction in candidates) {
    if (direction == null) continue;
    final target = monster.position.step(direction);
    if (!map.isWalkable(target) || occupied.contains(target)) continue;
    return target;
  }
  return null;
}
```

`step.dart` now needs `import '../dungeon/floor_map.dart';` and `import 'position.dart';`.

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd packages/core && dart test`
Expected: all tests pass.

- [ ] **Step 5: Verify and commit (orchestrator commits)**

Run: `cd packages/core && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/core && \
  git commit \
    -m "feat(core): add monster turns and hero death to step"
```

---

## Task 8: content package — the first floor and newGame

**Files:**

- Create: `packages/content/pubspec.yaml`
- Create: `packages/content/lib/content.dart`
- Create: `packages/content/lib/src/first_floor.dart`
- Create: `packages/content/lib/src/new_game.dart`
- Test: `packages/content/test/content_validation_test.dart`

**Interfaces:**

- Consumes: `residuum_core` (Tasks 1–7).
- Produces: `const String firstFloorAscii,`const Position heroSpawn, `const List<Position> ghoulSpawns,`GameState newGame({int seed = 1})`.

The floor: 20 wide, 12 tall, two 7-by-10 rooms joined by a four-tile corridor at `y == 5`. The hero starts in the west room at `Position(2, 9)`; three ghouls wait in the east room at `Position(13, 2),`Position(17, 3)` and `Position(15, 5)`. All three are outside the hero's radius-8 sight at the start, so the crawl opens dark and fog of war has something to reveal.

Ghoul spawn placement is load-bearing, not arbitrary. The spec's greedy chase has no pathfinding, so a ghoul reaches the hero only when sliding along a wall happens to deliver it to the corridor mouth. Spawning all three at `y <= 5` means their first blocked step falls back to the vertical axis and walks them onto row 5, into the corridor, and through it. Verify this by hand-tracing at least one spawn before writing the test, and report any spawn that cannot reach the hero.

- [ ] **Step 1: Create the package scaffold**

`packages/content/pubspec.yaml`:

```yaml
name: residuum_content
description: Declarative game data for Residuum — floors, creatures, and the
  starting state.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.9.0

dependencies:
  residuum_core:
    path: ../core

dev_dependencies:
  test: ^1.25.0
```

`packages/content/lib/content.dart`:

```dart
export 'src/first_floor.dart';
export 'src/new_game.dart';
```

- [ ] **Step 2: Write the failing test**

`packages/content/test/content_validation_test.dart`:

```dart
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('the first floor', () {
    test('parses and is twenty by twelve', () {
      // arrange
      const ascii = firstFloorAscii;

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect((map.width, map.height), (20, 12));
    });

    test('every spawn stands on walkable ground', () {
      // arrange
      final map = FloorMap.parse(firstFloorAscii);
      final spawns = [heroSpawn...ghoulSpawns];

      // act
      final walkable = spawns.map(map.isWalkable);

      // assert
      expect(walkable, everyElement(isTrue));
    });

    test('no two actors share a spawn tile', () {
      // arrange
      final spawns = [heroSpawn...ghoulSpawns];

      // act
      final unique = spawns.toSet();

      // assert
      expect(unique, hasLength(spawns.length));
    });

    test('has two rooms joined by a corridor, not one open cave', () {
      // arrange
      final map = FloorMap.parse(firstFloorAscii);

      // act
      final corridor = map.isWalkable(const Position(10, 5));
      final aboveCorridor = map.isWalkable(const Position(10, 4));
      final belowCorridor = map.isWalkable(const Position(10, 6));

      // assert
      expect(corridor, isTrue);
      expect(aboveCorridor, isFalse);
      expect(belowCorridor, isFalse);
    });
  });

  group('newGame', () {
    test('arms the hero with the rusty sword', () {
      // arrange
      final game = newGame();

      // act
      final hero = game.hero;

      // assert
      expect(hero.id, 'hero');
      expect(hero.glyph, '@');
      expect(hero.position, heroSpawn);
      expect((hero.hp, hero.maxHp), (20, 20));
      expect((hero.attackMin, hero.attackMax), (3, 5));
    });

    test('places three ghouls with distinct ids', () {
      // arrange
      final game = newGame();

      // act
      final monsters = game.monsters;

      // assert
      expect(monsters, hasLength(3));
      expect(monsters.map((m) => m.id).toSet(), hasLength(3));
      expect(monsters.map((m) => m.glyph).toSet(), {'g'});
      expect(monsters.map((m) => m.hp).toSet(), {10});
      expect(monsters.map((m) => (m.attackMin, m.attackMax)).toSet(), {(2, 4)});
    });

    test('starts with the hero seeing its own tile and nothing more explored',
        () {
      // arrange
      final game = newGame();

      // act
      final visible = game.visible;

      // assert
      expect(visible, contains(heroSpawn));
      expect(game.explored, visible);
      expect(game.isGameOver, isFalse);
    });

    test('hides every ghoul at the start, so the dark has something in it', () {
      // arrange
      final game = newGame();

      // act
      final seen = ghoulSpawns.where(game.visible.contains);

      // assert
      expect(seen, isEmpty);
    });

    test('a ghoul reaches the hero and draws blood', () {
      // arrange
      var game = newGame();

      // act
      for (var turn = 0; turn < 60; turn++) {
        final (next, _) = step(game, const MoveAction(Direction.north));
        game = next;
        if (game.isGameOver) break;
      }

      // assert
      expect(game.hero.hp, lessThan(20));
    });

    test('the same seed produces the same crawl', () {
      // arrange
      final one = newGame(seed: 7);
      final another = newGame(seed: 7);

      // act
      final first = _play(one, 12);
      final second = _play(another, 12);

      // assert
      expect(first, second);
    });
  });
}

List<String> _play(GameState start, int turns) {
  final log = <String>[];
  var game = start;
  for (var turn = 0; turn < turns; turn++) {
    final (next, events) = step(game, const MoveAction(Direction.east));
    log.addAll(events.map((event) => event.toString()));
    game = next;
  }
  return log;
}
```

The "a ghoul reaches the hero and draws blood" test pins the chase-and-spawn
interaction: the hero walks north until the wall stops it, and something must
eventually claw it. The test asserts only what it can honestly assert — that at
least one ghoul arrives. It deliberately does **not** claim all three do,
because under the spec's greedy chase they may not: a ghoul whose row already
matches the hero's while a wall stands between them has no candidate step left
and freezes. After the test is green, count how many of the three actually
arrive and report the number to the architect — that count is a spec finding
about the chase rule, not a test to weaken.

- [ ] **Step 3: Run the test and confirm it fails**

Run: `cd packages/content && dart pub get && dart test`
Expected: compile failure — `firstFloorAscii,`heroSpawn, `ghoulSpawns` and `newGame` are not defined.

- [ ] **Step 4: Write the implementation**

`packages/content/lib/src/first_floor.dart`:

```dart
import 'package:residuum_core/core.dart';

/// The single hand-authored floor of Milestone 1.
///
/// Two rooms, each seven by ten, joined by a four-tile corridor on row five.
/// The corridor is the tactical point of the floor: it is the only place the
/// hero can meet the ghouls one at a time.
const String firstFloorAscii = '''
####################
#.......####.......#
#.......####.......#
#.......####.......#
#.......####.......#
#..................#
#.......####.......#
#.......####.......#
#.......####.......#
#.......####.......#
#.......####.......#
####################''';

/// Where the hero starts: the far corner of the west room.
const Position heroSpawn = Position(2, 9);

/// Where the three ghouls wait, all in the east room and all out of sight.
const List<Position> ghoulSpawns = [
  Position(13, 2),
  Position(17, 3),
  Position(15, 5),
];
```

`packages/content/lib/src/new_game.dart`:

```dart
import 'package:residuum_core/core.dart';

import 'first_floor.dart';

/// A fresh crawl on the first floor.
///
/// The hero carries the rusty sword, folded straight into its attack range —
/// Milestone 1 has no inventory to hang a weapon on.
GameState newGame({int seed = 1}) {
  final map = FloorMap.parse(firstFloorAscii);
  const hero = Actor(
    id: 'hero',
    glyph: '@',
    position: heroSpawn,
    hp: 20,
    maxHp: 20,
    attackMin: 3,
    attackMax: 5,
  );
  final monsters = <Actor>[
    for (var index = 0; index < ghoulSpawns.length; index++)
      Actor(
        id: 'ghoul-${index + 1}',
        glyph: 'g',
        position: ghoulSpawns[index],
        hp: 10,
        maxHp: 10,
        attackMin: 2,
        attackMax: 4,
      ),
  ];
  final visible = computeFov(map, hero.position, fovRadius);
  return GameState(
    map: map,
    hero: hero,
    monsters: monsters,
    rng: Rng(seed),
    visible: visible,
    explored: {...visible},
  );
}
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `cd packages/content && dart test`
Expected: all tests pass.

- [ ] **Step 6: Verify and commit (orchestrator commits)**

Run: `cd packages/content && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/content && \
  git commit \
    -m "feat(content): add the first floor and newGame"
```

---

## Task 9: Flutter app scaffold

**Files:**

- Create: `packages/app/**` via `flutter create`
- Modify: `packages/app/pubspec.yaml`
- Modify: `packages/app/lib/main.dart`
- Delete: `packages/app/test/widget_test.dart`

**Interfaces:**

- Consumes: `residuum_core,`residuum_content`.
- Produces: a Flutter app that builds and shows a placeholder, so later tasks have somewhere to land.

- [ ] **Step 1: Generate the scaffold**

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl/packages && \
  flutter create --platforms=android,web --project-name residuum_app app
```

Delete the generated `packages/app/test/widget_test.dart`: conventions forbid widget tests, and Task 10 replaces it with bloc tests.

- [ ] **Step 2: Add the dependencies**

Edit `packages/app/pubspec.yaml` so `dependencies` and `dev_dependencies` read:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.0.0
  residuum_content:
    path: ../content
  residuum_core:
    path: ../core

dev_dependencies:
  bloc_test: ^10.0.0
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
```

Drop the generated `cupertino_icons` dependency: nothing uses it, and the allowed-dependency list does not include it. Keep `flutter_lints` (generated, and it is what makes `flutter analyze` strict). Resolve the exact `flutter_bloc` and `bloc_test` versions with `flutter pub add` rather than trusting the numbers above — if the resolved major version differs, use the resolved one.

Run: `cd packages/app && flutter pub get`

- [ ] **Step 3: Replace the generated counter app**

`packages/app/lib/main.dart`:

```dart
import 'package:flutter/material.dart';

void main() => runApp(const ResiduumApp());

class ResiduumApp extends StatelessWidget {
  const ResiduumApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Residuum',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E1014),
      useMaterial3: true,
    ),
    home: const Scaffold(body: Center(child: Text('Residuum'))),
  );
}
```

- [ ] **Step 4: Verify the app builds and analyses clean**

Run: `cd packages/app && flutter analyze && dart format --set-exit-if-changed .`
Expected: "No issues found!" and exit status 0. `flutter test` reports no tests, which is expected at this point.

- [ ] **Step 5: Commit (orchestrator commits)**

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/app && \
  git commit \
    -m "chore(app): scaffold the Flutter app"
```

---

## Task 10: GameBloc and event messages

**Files:**

- Create: `packages/app/lib/game/event_messages.dart`
- Create: `packages/app/lib/game/game_bloc.dart`
- Test: `packages/app/test/game_bloc_test.dart`

**Interfaces:**

- Consumes: `residuum_core,`residuum_content`.
- Produces:
  - `String? describeEvent(GameEvent event)`.
  - `sealed class GameBlocEvent`; `GameStarted({int seed = 1}),`TileTapped(Position position)`.
  - `class GameViewState` — `GameViewState({required GameState game, required List<String> log})`.
  - `class GameBloc extends Bloc<GameBlocEvent, GameViewState>` — `GameBloc({GameState? game, int seed = 1})`.

The optional `game` argument exists so tests can start a crawl mid-fight without playing twenty turns to get there. It is not a test-only hack: loading a save in M2 needs exactly this seam.

- [ ] **Step 1: Write the failing test**

`packages/app/test/game_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

const arena = '''
#######
#.....#
#.....#
#.....#
#######''';

GameState arenaGame({
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
}) {
  final map = FloorMap.parse(arena);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      glyph: '@',
      position: heroAt,
      hp: heroHp,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
    ),
    monsters: monsters,
    rng: Rng(1),
    visible: visible,
    explored: {...visible},
  );
}

Actor ghoul(Position at, {int hp = 10, int attack = 3}) => Actor(
  id: 'ghoul-1',
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
);

void main() {
  group('GameBloc', () {
    test('starts a fresh crawl with the hero at its spawn and an empty log',
        () {
      // arrange
      final bloc = GameBloc();

      // act
      final state = bloc.state;

      // assert
      expect(state.game.hero.position, heroSpawn);
      expect(state.log, isEmpty);
      addTearDown(bloc.close);
    });

    blocTest<GameBloc, GameViewState>(
      'a tap on an adjacent tile moves the hero and writes to the log',
      build: () => GameBloc(game: arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.hero.position, 'hero', const Position(4, 2))
            .having((s) => s.log, 'log', ['You step east.']),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a tap on a distant tile is ignored',
      build: () => GameBloc(game: arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(1, 1))),
      expect: () => <GameViewState>[],
    );

    blocTest<GameBloc, GameViewState>(
      'a tap on a diagonal neighbour is ignored',
      build: () => GameBloc(game: arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 3))),
      expect: () => <GameViewState>[],
    );

    blocTest<GameBloc, GameViewState>(
      'bumping a wall logs the block and still costs the turn',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(1, 2),
          monsters: [ghoul(const Position(5, 2))],
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(0, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.log, 'log', ['The way is blocked.'])
            .having(
              (s) => s.game.monsters.single.position,
              'ghoul',
              const Position(4, 2),
            ),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a killing blow logs the hit and the death',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          monsters: [ghoul(const Position(4, 2), hp: 4)],
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.monsters, 'monsters', isEmpty)
            .having(
              (s) => s.log,
              'log',
              ['You hit the ghoul for 4.', 'The ghoul dies.'],
            ),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a lethal claw ends the game and logs the death',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          heroHp: 2,
          monsters: [ghoul(const Position(4, 2), attack: 3)],
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.isGameOver, 'isGameOver', isTrue)
            .having((s) => s.log, 'log', contains('You die.'))
            .having(
              (s) => s.log,
              'log',
              contains('The ghoul claws you for 3.'),
            ),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'taps after death do nothing',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          heroHp: 2,
          monsters: [ghoul(const Position(4, 2), attack: 3)],
        ),
      ),
      act: (bloc) => bloc
        ..add(const TileTapped(Position(4, 2)))
        ..add(const TileTapped(Position(2, 2))),
      expect: () => [
        isA<GameViewState>().having((s) => s.game.isGameOver, 'over', isTrue),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'restarting clears the log and puts the hero back at the spawn',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          heroHp: 2,
          monsters: [ghoul(const Position(4, 2), attack: 3)],
        ),
      ),
      act: (bloc) => bloc
        ..add(const TileTapped(Position(4, 2)))
        ..add(const GameStarted()),
      skip: 1,
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.isGameOver, 'isGameOver', isFalse)
            .having((s) => s.game.hero.position, 'hero', heroSpawn)
            .having((s) => s.game.hero.hp, 'hp', 20)
            .having((s) => s.log, 'log', isEmpty),
      ],
    );
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd packages/app && flutter test`
Expected: compile failure — `GameBloc` and friends are not defined.

- [ ] **Step 3: Write the implementation**

`packages/app/lib/game/event_messages.dart`:

```dart
import 'package:residuum_core/core.dart';

String? describeEvent(GameEvent event) => switch (event) {
  ActorMoved(:final actorId, :final from, :final to) when actorId == 'hero' =>
    'You step ${_bearing(from, to)}.',
  ActorMoved() => null,
  MoveBlocked(:final actorId) when actorId == 'hero' => 'The way is blocked.',
  MoveBlocked() => null,
  AttackHit(:final attackerId, :final damage) when attackerId == 'hero' =>
    'You hit the ghoul for $damage.',
  AttackHit(:final damage) => 'The ghoul claws you for $damage.',
  ActorDied(:final actorId) when actorId == 'hero' => 'You die.',
  ActorDied() => 'The ghoul dies.',
  GameOver() => null,
};

String _bearing(Position from, Position to) =>
    from.directionTo(to)?.name ?? 'aside';
```

Naming a monster "the ghoul" from its id is honest for M1, which has exactly one monster type. When M2 adds a second, `Actor` gains a display name and this switch reads it. Log that as a follow-up.

`packages/app/lib/game/game_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'event_messages.dart';

sealed class GameBlocEvent {
  const GameBlocEvent();
}

final class GameStarted extends GameBlocEvent {
  const GameStarted({this.seed = 1});

  final int seed;
}

final class TileTapped extends GameBlocEvent {
  const TileTapped(this.position);

  final Position position;
}

class GameViewState {
  const GameViewState({required this.game, required this.log});

  final GameState game;
  final List<String> log;
}

class GameBloc extends Bloc<GameBlocEvent, GameViewState> {
  GameBloc({GameState? game, int seed = 1})
    : super(
        GameViewState(game: game ?? newGame(seed: seed), log: const []),
      ) {
    on<GameStarted>(_onGameStarted);
    on<TileTapped>(_onTileTapped);
  }

  void _onGameStarted(GameStarted event, Emitter<GameViewState> emit) {
    emit(GameViewState(game: newGame(seed: event.seed), log: const []));
  }

  void _onTileTapped(TileTapped event, Emitter<GameViewState> emit) {
    final game = state.game;
    if (game.isGameOver) return;
    final direction = game.hero.position.directionTo(event.position);
    if (direction == null) return;
    final (next, events) = step(game, MoveAction(direction));
    emit(
      GameViewState(
        game: next,
        log: [
          ...state.log...events.map(describeEvent).whereType<String>(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd packages/app && flutter test`
Expected: all tests pass.

- [ ] **Step 5: Verify and commit (orchestrator commits)**

Run: `cd packages/app && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/app && \
  git commit \
    -m "feat(app): add GameBloc and event messages"
```

---

## Task 11: Grid geometry and glyph rendering

**Files:**

- Create: `packages/app/lib/game/grid_geometry.dart`
- Create: `packages/app/lib/game/glyph_grid.dart`
- Test: `packages/app/test/grid_geometry_test.dart`

**Interfaces:**

- Consumes: `GameViewState` (Task 10), `residuum_core`.
- Produces:
  - `class GridGeometry` — `GridGeometry.fit(Size size, int columns, int rows),`double cellSize, `Offset origin,`int columns, `int rows,`Offset topLeftOf(int x, int y), `Position? positionAt(Offset local)`.
  - `class GlyphGrid extends StatelessWidget` — `GlyphGrid({required GameViewState state, required ValueChanged<Position> onTap})`.

Tap mapping holds real logic — fit, centre, floor-divide, reject out-of-grid — so it is a plain unit-tested class rather than arithmetic buried in a callback. The tests here are unit tests of a value object that happens to use `dart:ui` types; they are not widget tests, so conventions are satisfied.

**Accessibility.** Every glyph is distinguished by its character first (`#,`., `@,`g`) and by brightness second. Explored-but-unseen tiles are drawn at 40 percent opacity of the same colour, so the visible/remembered distinction survives greyscale. No two categories differ by hue alone.

- [ ] **Step 1: Write the failing test**

`packages/app/test/grid_geometry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

void main() {
  group('GridGeometry.fit', () {
    test('sizes cells by the tighter dimension', () {
      // arrange
      const size = Size(200, 400);

      // act
      final geometry = GridGeometry.fit(size, 20, 12);

      // assert
      expect(geometry.cellSize, 10);
    });

    test('centres the grid inside the available space', () {
      // arrange
      const size = Size(200, 400);

      // act
      final geometry = GridGeometry.fit(size, 20, 12);

      // assert
      expect(geometry.origin, const Offset(0, 140));
    });
  });

  group('GridGeometry.topLeftOf', () {
    test('walks cells by one cell size from the origin', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final corner = geometry.topLeftOf(3, 2);

      // assert
      expect(corner, const Offset(30, 160));
    });
  });

  group('GridGeometry.positionAt', () {
    test('maps a tap inside a cell to that cell', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final position = geometry.positionAt(const Offset(35, 165));

      // assert
      expect(position, const Position(3, 2));
    });

    test('maps the exact top-left corner of a cell to that cell', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final position = geometry.positionAt(const Offset(30, 160));

      // assert
      expect(position, const Position(3, 2));
    });

    test('rejects a tap in the letterbox above the grid', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final position = geometry.positionAt(const Offset(100, 10));

      // assert
      expect(position, isNull);
    });

    test('rejects a tap past the last column and row', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final beyondX = geometry.positionAt(const Offset(205, 200));
      final beyondY = geometry.positionAt(const Offset(100, 395));

      // assert
      expect(beyondX, isNull);
      expect(beyondY, isNull);
    });

    test('rejects a tap on a collapsed layout', () {
      // arrange
      final geometry = GridGeometry.fit(Size.zero, 20, 12);

      // act
      final position = geometry.positionAt(Offset.zero);

      // assert
      expect(position, isNull);
    });
  });
}
```

Check the arithmetic of the expectations before implementing: 200/20 is 10, 400/12 is 33.3, so `cellSize` is 10; the grid is then 200 by 120, leaving 280 of vertical slack, so the origin is `(0, 140)`. Cell (3, 2) starts at `(0 + 30, 140 + 20)` which is `(30, 160)`. A tap at `(100, 395)` is below `140 + 120, so it misses.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd packages/app && flutter test test/grid_geometry_test.dart`
Expected: compile failure — `GridGeometry` is not defined.

- [ ] **Step 3: Write the implementation**

`packages/app/lib/game/grid_geometry.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:residuum_core/core.dart';

class GridGeometry {
  const GridGeometry({
    required this.cellSize,
    required this.origin,
    required this.columns,
    required this.rows,
  });

  factory GridGeometry.fit(Size size, int columns, int rows) {
    final cellSize = math.min(size.width / columns, size.height / rows);
    return GridGeometry(
      cellSize: cellSize,
      origin: Offset(
        (size.width - cellSize * columns) / 2,
        (size.height - cellSize * rows) / 2,
      ),
      columns: columns,
      rows: rows,
    );
  }

  final double cellSize;
  final Offset origin;
  final int columns;
  final int rows;

  Offset topLeftOf(int x, int y) =>
      Offset(origin.dx + x * cellSize, origin.dy + y * cellSize);

  Position? positionAt(Offset local) {
    if (cellSize <= 0) return null;
    final x = ((local.dx - origin.dx) / cellSize).floor();
    final y = ((local.dy - origin.dy) / cellSize).floor();
    if (x < 0 || y < 0 || x >= columns || y >= rows) return null;
    return Position(x, y);
  }
}
```

`packages/app/lib/game/glyph_grid.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'game_bloc.dart';
import 'grid_geometry.dart';

class GlyphGrid extends StatelessWidget {
  const GlyphGrid({required this.state, required this.onTap, super.key});

  final GameViewState state;
  final ValueChanged<Position> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final geometry = GridGeometry.fit(
        size,
        state.game.map.width,
        state.game.map.height,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final position = geometry.positionAt(details.localPosition);
          if (position != null) onTap(position);
        },
        child: CustomPaint(
          size: size,
          painter: _GlyphPainter(state: state, geometry: geometry),
        ),
      );
    },
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.state, required this.geometry});

  static const _wall = Color(0xFFB9BEC6);
  static const _floor = Color(0xFF5B6270);
  static const _hero = Color(0xFFFFFFFF);
  static const _ghoul = Color(0xFFD9A227);
  static const _rememberedOpacity = 0.4;

  final GameViewState state;
  final GridGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final game = state.game;
    for (var y = 0; y < game.map.height; y++) {
      for (var x = 0; x < game.map.width; x++) {
        final position = Position(x, y);
        final visible = game.visible.contains(position);
        if (!visible && !game.explored.contains(position)) continue;
        final tile = game.map.tileAt(position);
        final isWall = tile == Tile.wall;
        _paintGlyph(
          canvas,
          position,
          isWall ? '#' : '.',
          isWall ? _wall : _floor,
          visible,
        );
      }
    }
    for (final monster in game.monsters) {
      if (!game.visible.contains(monster.position)) continue;
      _paintGlyph(canvas, monster.position, monster.glyph, _ghoul, true);
    }
    _paintGlyph(canvas, game.hero.position, game.hero.glyph, _hero, true);
  }

  void _paintGlyph(
    Canvas canvas,
    Position position,
    String glyph,
    Color color,
    bool visible,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          color: visible ? color : color.withValues(alpha: _rememberedOpacity),
          fontSize: geometry.cellSize,
          fontFamily: 'monospace',
          height: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final cell = geometry.topLeftOf(position.x, position.y);
    painter.paint(
      canvas,
      cell +
          Offset(
            (geometry.cellSize - painter.width) / 2,
            (geometry.cellSize - painter.height) / 2,
          ),
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.geometry != geometry;
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `cd packages/app && flutter test`
Expected: all tests pass.

- [ ] **Step 5: Verify and commit (orchestrator commits)**

Run: `cd packages/app && flutter analyze && dart format --set-exit-if-changed .`

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/app && \
  git commit \
    -m "feat(app): draw the glyph grid and map taps to tiles"
```

---

## Task 12: The game screen

**Files:**

- Create: `packages/app/lib/game/game_screen.dart`
- Modify: `packages/app/lib/main.dart`

**Interfaces:**

- Consumes: `GameBloc,`GameViewState, `GlyphGrid`.
- Produces: `class GameScreen extends StatelessWidget`.

**Accessibility, non-negotiable.** The hit-point bar encodes danger three ways at once: the fill fraction, the numeric label "7 / 20", and a word ("Steady", "Wounded", "Critical"). Never hue alone. The death overlay is a word, not a colour.

- [ ] **Step 1: Write the screen**

`packages/app/lib/game/game_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'game_bloc.dart';
import 'glyph_grid.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<GameBloc, GameViewState>(
        builder: (context, state) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GlyphGrid(
                      state: state,
                      onTap: (position) =>
                          context.read<GameBloc>().add(TileTapped(position)),
                    ),
                  ),
                ),
                _HitPoints(state: state),
                _MessageLog(log: state.log),
              ],
            ),
            if (state.game.isGameOver) const _DeathOverlay(),
          ],
        ),
      ),
    ),
  );
}

class _HitPoints extends StatelessWidget {
  const _HitPoints({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final hero = state.game.hero;
    final fraction = hero.maxHp == 0 ? 0.0 : hero.hp / hero.maxHp;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1),
                minHeight: 14,
                backgroundColor: const Color(0xFF23262E),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFDDE1E7)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${hero.hp} / ${hero.maxHp}  ${_condition(fraction)}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Color(0xFFDDE1E7),
            ),
          ),
        ],
      ),
    );
  }

  static String _condition(double fraction) {
    if (fraction <= 0) return 'Dead';
    if (fraction < 0.25) return 'Critical';
    if (fraction < 0.6) return 'Wounded';
    return 'Steady';
  }
}

class _MessageLog extends StatelessWidget {
  const _MessageLog({required this.log});

  final List<String> log;

  @override
  Widget build(BuildContext context) => Container(
    height: 104,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    color: const Color(0xFF15181F),
    child: ListView.builder(
      reverse: true,
      itemCount: log.length,
      itemBuilder: (context, index) => Text(
        log[log.length - 1 - index],
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(index == 0 ? 0xFFE6EAF0 : 0xFF8A919E),
        ),
      ),
    ),
  );
}

class _DeathOverlay extends StatelessWidget {
  const _DeathOverlay();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xCC0E1014),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'You died.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              color: Color(0xFFE6EAF0),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                context.read<GameBloc>().add(const GameStarted()),
            child: const Text('Restart'),
          ),
        ],
      ),
    ),
  );
}
```

The log uses `reverse: true` with a reversed index so the newest line sits at the bottom and the list opens scrolled to it, without a `ScrollController` to manage.

- [ ] **Step 2: Wire it into main.dart**

Replace the placeholder `home:` in `packages/app/lib/main.dart`:

```dart
    home: BlocProvider(
      create: (_) => GameBloc(),
      child: const GameScreen(),
    ), ```

and add `import 'package:flutter_bloc/flutter_bloc.dart';` plus `import 'game/game_bloc.dart';` and `import 'game/game_screen.dart';`.

- [ ] **Step 3: Verify**

Run: `cd packages/app && flutter test && flutter analyze && dart format --set-exit-if-changed .`
Expected: tests pass, "No issues found!", exit status 0.

- [ ] **Step 4: Commit (orchestrator commits)**

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/app && \
  git commit \
    -m "feat(app): add the game screen with hit points, log and death overlay"
```

---

## Task 13: Balance check on the hero stat line

**Files:** possibly `packages/content/lib/src/new_game.dart` and its test.

The build prompt calls the stat line a first guess: hero 20 hp attacking 3–5, three ghouls of 10 hp attacking 2–4. Rough arithmetic says a corridor fight is a knife-edge — the hero averages 4 damage a turn and needs about three turns per ghoul, taking about two claws of about 3 each, so roughly 18 damage across three ghouls against 20 hit points — and an open-room fight against all three at once is a certain death. That is the intended shape (corridor rewarded, open room punished), but it is too tight to survive variance.

- [ ] **Step 1: Measure it instead of guessing**

Write a throwaway simulator **outside the repository** at `$CLAUDE_JOB_DIR/tmp/balance.dart` that imports the packages by path, plays the "fight them one at a time in the corridor" policy — hero always attacks an adjacent ghoul, otherwise stands still — over 200 seeds, and reports the win rate and the median hit points remaining on a win.

- [ ] **Step 2: Decide from the number**

- Win rate between roughly 55 and 85 percent: leave the spec's numbers alone and report the measurement.
- Win rate below that: raise hero hit points to 26 (the smallest change that buys one extra claw of slack) and re-measure. Do not touch ghoul damage — the claw needs to feel dangerous.
- Win rate above that: leave it. A first playable that the author can win is the right failure direction for a milestone whose question is "is walking a dungeon fun".

- [ ] **Step 3: If numbers changed, update the content test and commit**

The content validation test asserts `(hero.hp, hero.maxHp)` and the attack range, so it must move with any change. Report the change and the measurement to the architect either way.

```bash
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && \
  git add packages/content && \
  git commit \
    -m "balance(content): tune the hero stat line from measured win rate"
```

---

## Task 14: Mutation table

**Files:** none committed. Every mutation is reverted with `git checkout --` before the next.

Run only against the finished implementation — mutation 2 is meaningless before Task 7 exists. One at a time. Record the actual test names that reddened, and record the controls that stayed green; a control that also reddens is a finding about test coupling and must be reported.

- [ ] **Row 1: `Tile.wall` made walkable**

Edit `packages/core/lib/src/dungeon/tile.dart, set`wall(walkable: true...)`. Run`cd packages/core && dart test`.
Expected red:`tile_test` "a wall blocks movement and sight", `floor_map_test` "a wall tile is neither walkable nor transparent", `step_hero_test` "is blocked by a wall and does not move".
Expected green: `position_test, `rng_test`.
Revert: `git checkout -- packages/core/lib/src/dungeon/tile.dart`

- [ ] **Row 2: monster phase deleted from `step`**

Comment out the monster `for` loop in `step.dart`. Run `cd packages/core && dart test`.
Expected red: the chase, adjacent-attack and hero-death tests in `step_monsters_test`.
Expected green: `step_hero_test` movement and bump-attack tests.
Revert: `git checkout -- packages/core/lib/src/engine/step.dart`

- [ ] **Row 3: damage hardcoded to 0**

In `step.dart, replace both`state.rng.rollRange(...)` calls with `0`. Run`cd packages/core && dart test`.
Expected red: bump-attack, killing-blow, monster-attack and hero-death tests.
Expected green: movement tests,`fov_test, `floor_map_test`.
Revert: `git checkout -- packages/core/lib/src/engine/step.dart`

- [ ] **Row 4: `computeFov` returns all positions**

Replace the body of `computeFov` with a full-grid set. Run `cd packages/core && dart test`.
Expected red: the occlusion, radius and circle tests in `fov_test`.
Expected green: `step_hero_test` movement tests.
Revert: `git checkout -- packages/core/lib/src/dungeon/fov.dart`

- [ ] **Row 5: bloc ignores `TileTapped`**

In `game_bloc.dart, make`_onTileTapped` return immediately. Run `cd packages/app && flutter test`.
Expected red: the adjacent-tap, wall-bump, killing-blow, death and restart bloc tests.
Expected green: "a tap on a distant tile is ignored", "a tap on a diagonal neighbour is ignored".
Revert:`git checkout -- packages/app/lib/game/game_bloc.dart`

- [ ] **Row 6: confirm the tree is clean again**

Run: `cd <worktree> && git status --porcelain` — expect empty output — then the full suite one more time.

---

## Task 15: Play it on the emulator

- [ ] **Step 1: Launch the Pixel_10 AVD**

`emulator` and `adb` need unsandboxed Bash: device nodes are hidden under the sandbox and `/dev/kvm` reads as missing. `flutter emulators` mishandles the installed ps16k system images, so use the binary directly:

```bash
~/.local/share/sdks/android/emulator/emulator -avd Pixel_10 -no-snapshot-load
```

Then `adb devices` to get the device id. If launching is refused, message the architect and ask the user to start it.

- [ ] **Step 2: Run the app**

```bash
cd packages/app && flutter run -d <device-id>
```

The first gradle build downloads dependencies: allow several minutes and do not read the wait as a hang. The build prompt forbids attempting a standalone Android or gradle build; this is `flutter run, which is the sanctioned path.

- [ ] **Step 3: Observe the whole loop**

Drive it with `adb shell input tap <x> <y>` and capture what happened with `adb exec-out screencap -p > $CLAUDE_JOB_DIR/tmp/shot-N.png, then read each screenshot. Confirm, with a screenshot each: the floor renders as glyphs; walking reveals new tiles and leaves dimmed remembered ones behind; a ghoul appears and closes; a bump attack logs a hit; a ghoul dies; the hero dies and the overlay appears; Restart returns a full-health hero to the spawn.

- [ ] **Step 4: Check it in greyscale**

Convert one screenshot to greyscale and read it. Hero, ghoul, wall, floor, visible and remembered must all still be distinguishable. If any pair collapses, fix the brightness values, not the hues.

---

## Task 16: Final verification and report

- [ ] **Step 1: Run everything and keep the output**

```bash
cd packages/core && dart test
cd packages/content && dart test
cd packages/app && flutter test
cd packages/core && flutter analyze
cd packages/content && flutter analyze
cd packages/app && flutter analyze
cd <worktree> && dart format --set-exit-if-changed .
cd <worktree> && git log --oneline main..m1-crawl
cd <worktree> && git branch --show-current
cd <worktree> && git status --porcelain
```

- [ ] **Step 2: Use superpowers:verification-before-completion**

Quote the output, then claim. No claim without the command output that proves it.

- [ ] **Step 3: Send the verification block to the architect via SendMessage**

The eight items the build prompt lists, each evidenced: branch proof, test counts, analyze and format, the full mutation table including greens, the emulator playthrough with what was observed, what the tests cannot prove (visual rendering correctness, touch ergonomics, whether it is fun), every spec claim checked and found wrong with its source, and which execution phases ran with an argument for any skipped.

---

## Self-Review

**Spec coverage.** Every file in the story spec's "New files" list has a task: core engine and dungeon files in Tasks 1–7, content in Task 8, app in Tasks 9–12. Both spec sections that are not files are covered too: the three required dartdoc arguments (blocked-move-consumes-turn in Task 6, Rng-by-reference in Task 5, fov distance metric in Task 4), and the mutation table in Task 14. The definition-of-done checklist maps to Tasks 14–16. Two files were added beyond the spec's list, both argued in the File Structure section.

**Placeholders.** None: every code step carries the actual code, every test step the actual test, every command the actual command.

**Type consistency.** `Position,`Direction, `Actor,`Tile, `FloorMap,`GameState, `GameEvent` subtypes, `step,`computeFov, `fovRadius,`newGame, `firstFloorAscii,`heroSpawn, `ghoulSpawns,`GameBloc, `GameViewState,`GameStarted, `TileTapped,`describeEvent, `GridGeometry,`GlyphGrid, `GameScreen` are each defined once and referenced with the same names and signatures downstream. The test fixture helper is named `crawl` in core tests and `arenaGame` in app tests because they build different things; both are declared where they are used.

**Known risks carried into execution.**

1. The greedy chase cannot round a corner. A ghoul that ends up wall-blocked at the hero's own row or column freezes permanently. Task 8 places spawns so this does not happen at the start, and Task 8's "every ghoul can actually reach the hero" test pins reachability, but the player can still create the situation deliberately. Report it with coordinates; recommend a breadth-first flow field for M2.
2. `flutter_bloc` and `bloc_test` version numbers in Task 9 are guesses; resolve them with `flutter pub add` and use what pub picks.
3. The balance numbers are first guesses by the spec's own admission; Task 13 measures before touching them.
