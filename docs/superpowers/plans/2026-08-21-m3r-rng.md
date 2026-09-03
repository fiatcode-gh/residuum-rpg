# M3R "A generator that can be saved" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `Rng`'s `dart:math.Random` core with a splitmix64 generator whose entire state is one exportable int, so a run in progress can be serialized.

**Architecture:** `Rng` keeps its public shape — `Rng(int seed)` and `rollRange(int min, int maxInclusive)` inclusive on both ends — and gains `int get state` plus `Rng.fromState(int state)`. The generator is splitmix64: one 64-bit int of state, advanced by a fixed odd increment, passed through a two-round xor-shift-multiply finalizer. Range reduction is one modulo of the top 63 bits, so one roll always advances the state exactly once. Every seeded artifact in the repository re-rolls once and is re-pinned honestly.

**Tech Stack:** Pure Dart (`packages/core`), `package:test`. No new dependencies. 64-bit wrapping integer arithmetic (Dart VM/AOT only).

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-rng-spec-M3R.md`
(the ledger directory `docs/epic/` is gitignored — cite by absolute path, never commit)

## Global Constraints

- Dependency rule: `app → content → core`; `core` and `content` never import Flutter.
- No global randomness: every random decision draws from an `Rng` carried in state.
- No `dart:math` import may remain in `packages/core/lib/src/engine/rng.dart`.
- No API additions to `Rng` beyond `state` and `Rng.fromState`; no second stream type.
- `rollRange` keeps both-ends-inclusive semantics and its `ArgumentError` on an inverted range.
- No comments in function bodies. Dartdoc `///` only, and only on public API of `core` and `content`.
- Test bodies structured as `// arrange` / `// act` / `// assert`. No mocks.
- Determinism double-run tests must pass UNCHANGED, before and after.
- No test deleted or loosened to dodge a re-pin. The survivability band assertion (rate 50–95%, stalled 0) stays byte-identical.
- `packages/content` tables are frozen unless the survivability band fails, and then only after messaging the architect, with a before/after trail.
- Forbidden levers regardless: bestiary hp/attack/speed/pierce, hero base stats.
- No new dependencies anywhere.
- Conventional Commits.
- Every commit's exit state is green across all three packages.
- Never commit anything under `docs/epic/`. Never push, never open a PR.

## File Structure

| File | Responsibility |
|---|---|
| `packages/core/lib/src/engine/rng.dart` (modify) | The generator: splitmix64 core, `state`/`fromState,`rollRange`. The only production file that changes. |
| `packages/core/test/engine/rng_test.dart` (modify) | The generator contract: existing bounds/determinism tests, plus the equivalence group and the golden stream pin. |
| Seeded-outcome tests across all three packages (modify) | Literals that pin a specific roll re-pin to the new stream. Enumerated by running the suites at the first red commit, not from a list. |
| `BUILD-REPORT.md` (create) | The verification block, mirrored for the architect. |

`packages/content` production tables are NOT in this list and must stay untouched.

---

### Task 1: The splitmix64 generator behind the unchanged contract

**Files:**

- Modify: `packages/core/lib/src/engine/rng.dart` (whole file, 26 lines)
- Test: `packages/core/test/engine/rng_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: `class Rng` with `Rng(int seed),`Rng.fromState(int state), `int get state,`int rollRange(int min, int maxInclusive)`. Every later task and all eight production construction sites use exactly these.

**Design notes the implementer needs:**

- Dart VM/AOT `int` is 64-bit two's complement and arithmetic wraps silently — `+` and `*` need no masking. This is the substrate the generator stands on, and it is VM/AOT only: `dart2js` compiles `int` to a double and would break it. The app targets Android (AOT), so the constraint holds; state it in dartdoc where the arithmetic lives.
- `>>>` is the logical (zero-filling) shift on `int`; `>>` is arithmetic. The finalizer needs `>>>`.
- Dart's `%` is Euclidean: with a positive right operand the result is never negative. Bounds tests therefore CANNOT catch a lost sign mask — the golden stream test is what pins it.
- The constructor applies one finalizer round to the seed before storing it, so that `Rng(x)` and `Rng.fromState(x)` are genuinely different starting points. Without that, "restore" and "re-seed" would be the same code path and the equivalence property would be untestable.

- [ ] **Step 1: Write the failing tests — the equivalence group and the golden stream**

Append to `packages/core/test/engine/rng_test.dart, inside`void main(), after the existing `group('Rng'...)`:

```dart
  group('Rng state export', () {
    test('a restored generator continues the same stream', () {
      // arrange
      final original = Rng(2026);
      List.generate(37, (_) => original.rollRange(1, 6));
      final restored = Rng.fromState(original.state);

      // act
      final tail = List.generate(200, (index) => original.rollRange(0, index + 1));
      final resumed = List.generate(200, (index) => restored.rollRange(0, index + 1));

      // assert
      expect(resumed, tail);
    });

    test('a restored generator matches across mixed range sizes', () {
      // arrange
      final original = Rng(-9007199254740993);
      final restored = Rng.fromState(original.state);
      const spans = [(0, 1), (1, 100), (-50, 50), (0, 999999), (7, 7)];

      // act
      final tail = [
        for (var round = 0; round < 100; round++)
          for (final (min, max) in spans) original.rollRange(min, max),
      ];
      final resumed = [
        for (var round = 0; round < 100; round++)
          for (final (min, max) in spans) restored.rollRange(min, max),
      ];

      // assert
      expect(resumed, tail);
    });

    test('the state advances with every roll', () {
      // arrange
      final rng = Rng(11);

      // act
      final states = {for (var i = 0; i < 50; i++) (rng.rollRange(0, 3), rng.state).$2};

      // assert
      expect(states, hasLength(50));
    });

    test('a seed and a state of the same value are different generators', () {
      // arrange
      final seeded = Rng(5);
      final restored = Rng.fromState(5);

      // act
      final fromSeed = rollTwenty(seeded);
      final fromState = rollTwenty(restored);

      // assert
      expect(fromSeed, isNot(fromState));
    });
  });

  group('the golden stream', () {
    test('seed 12345 rolls a pinned sequence', () {
      // arrange
      final rng = Rng(12345);

      // act
      final rolls = List.generate(10, (_) => rng.rollRange(0, 999));

      // assert
      expect(rolls, <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    });

    test('seed 12345 exports a pinned state after ten rolls', () {
      // arrange
      final rng = Rng(12345);

      // act
      List.generate(10, (_) => rng.rollRange(0, 999));

      // assert
      expect(rng.state, 0);
    });
  });
```

The two golden literals above are placeholders on purpose: they are the one place in this plan where the correct value cannot be known before the code exists. Step 4 replaces them with the values the implementation actually produces, read from the failure message — never by copying a computed constant into the test without seeing it fail first.

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/core && dart test test/engine/rng_test.dart
```

Expected: compile error — `Rng.fromState` and `Rng.state` are not defined.

- [ ] **Step 3: Write the implementation**

Replace the whole of `packages/core/lib/src/engine/rng.dart`:

```dart
/// A seeded source of random numbers whose entire state is one exportable int.
///
/// Every random decision in Residuum draws from an `Rng` carried in the game
/// state: a fixed seed plus a fixed sequence of calls must always produce the
/// same game. The generator is hand-rolled rather than `dart:math.Random`
/// because `Random` offers no way to read its internal state back out, so a
/// run in progress could not be written to a save file and resumed on the
/// stream it left off on. [state] and [Rng.fromState] are that missing pair.
///
/// The algorithm is splitmix64: the state advances by a fixed odd increment
/// and the output is that state passed through two rounds of
/// xor-shift-multiply. One roll advances the state exactly once, so a restored
/// generator resumes roll-for-roll.
///
/// The arithmetic relies on `int` being 64-bit two's complement with silent
/// wrapping, which holds on the Dart VM and in AOT builds but not under
/// `dart2js, where `int` is a double. Residuum targets Android, so the
/// constraint holds; a web target would need a different substrate.
class Rng {
  /// A generator started from [seed]. Any int is a valid seed.
  Rng(int seed) : _state = _mix(seed);

  /// A generator resumed exactly where the one that exported [state] left off.
  Rng.fromState(int state) : _state = state;

  static const int _gamma = -0x61c8864680b583eb;

  int _state;

  /// The whole generator state, enough to restore it with [Rng.fromState].
  int get state => _state;

  /// A uniform integer between [min] and [maxInclusive], both ends included.
  ///
  /// The range is reduced by one modulo of the 63 non-sign bits of the raw
  /// output. That is biased towards the low end of the range by at most
  /// `span / 2^63` — under one part in a hundred million billion for any span
  /// a dungeon rolls, and far below the noise of the generator itself.
  /// Rejection sampling would remove the bias but would make the number of
  /// draws depend on the values drawn, and the point of this class is that one
  /// roll costs exactly one advance.
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
    _state += _gamma;
    return min + (_mix(_state) >>> 1) % (maxInclusive - min + 1);
  }

  static int _mix(int value) {
    var mixed = (value ^ (value >>> 30)) * -0x40a7b892e31b1a47;
    mixed = (mixed ^ (mixed >>> 27)) * -0x6b2fb644ecceee15;
    return mixed ^ (mixed >>> 31);
  }
}
```

The three constants are splitmix64's, written as negative literals because Dart has no unsigned int literal and `0x9E3779B97F4A7C15` overflows a signed 64-bit int at parse time: `-0x61c8864680b583eb == 0x9E3779B97F4A7C15` as a bit pattern, and likewise for the two multipliers.

- [ ] **Step 4: Run the tests and re-pin the two golden literals honestly**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/core && dart test test/engine/rng_test.dart
```

Expected: everything green except the two golden-stream tests, which fail with the actual sequence and the actual state in the message. Copy those two actual values into the test literals, re-run, expect all green. Record both old (placeholder) and new values for the re-pin list in the report.

- [ ] **Step 5: Run the whole core suite and quote the count**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/core && dart test 2>&1 | tr '\r' '\n' | grep -E "All tests passed|Some tests failed" | tail -1
```

Do not commit yet if this is red — Task 2 is the re-pin, and the commit at the end of Task 2 is the first green one. If it is already all green, commit now.

- [ ] **Step 6: Commit (only if all three suites are green)**

```bash
git add packages/core && git commit -m "feat: give Rng an exportable state on a splitmix64 core"
```

---

### Task 2: Re-pin every seeded outcome the new stream moved

**Files:**

- Modify: whatever the suites report red. Candidates from recon, none trusted: `packages/core/test/loot/drop_test.dart,`packages/core/test/dungeon/generator_test.dart, `packages/core/test/dungeon/generator_items_test.dart,`packages/content/test/economy_test.dart, `packages/content/test/content_validation_test.dart,`packages/app/test/game_bloc_test.dart, `packages/app/test/support/fixtures.dart`.
- Do NOT modify: `packages/content/lib/**` (production tables), the survivability band assertion.

**Interfaces:**

- Consumes: `Rng` from Task 1.
- Produces: three green suites and the full old → new literal list for the report.

- [ ] **Step 1: Enumerate the breakage by running, not by reading**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/core && dart test 2>&1 | tr '\r' '\n' | grep -E "^\s*[0-9]{2}:[0-9]{2}.*\[31m" | sort -u
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/content && dart test 2>&1 | tr '\r' '\n' | grep -E "Expected|Actual|\[E\]" 
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/app && flutter test 2>&1 | tr '\r' '\n' | grep -E "Expected|Actual|failed"
```

Write the list down before changing anything. This list is a deliverable: the report names every re-pinned test with its old and new literal.

- [ ] **Step 2: Classify each failure before touching it**

For each red test, decide which of three it is, and record the reason:

1. **A seeded-outcome pin** — the test asserts a specific value that a specific seed produced. Re-pin to the new value, one honest literal.
2. **A property that should hold under any deterministic generator** — "both ends reachable", "never the same affix twice", "the same seed twice". If one of these is red, the generator is WRONG. Fix the generator, not the test.
3. **A property that is true in general but unlucky on this one seed** — e.g. a test that needs a rare drop and this seed no longer produces one. Change the SEED, not the assertion, and say so in the report.

A test whose assertion gets weakened, whose tolerance gets widened, or which gets deleted is a plan violation. If a test cannot be re-pinned honestly, stop and message the architect.

- [ ] **Step 3: Re-pin, one file at a time, re-running that file after each edit**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/core && dart test test/loot/drop_test.dart
```

- [ ] **Step 4: Run all three suites and compare counts to the 389/95/129 baseline**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/core && dart test 2>&1 | tr '\r' '\n' | grep -E "All tests passed|Some tests failed" | tail -1
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/content && dart test 2>&1 | tr '\r' '\n' | grep -E "survivability:|All tests passed|Some tests failed" | tail -3
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/app && flutter test 2>&1 | tr '\r' '\n' | tail -1
```

Counts must be at least the baseline (389/95/129) plus the tests Task 1 added. A count that DROPPED means a test was lost — find it.

- [ ] **Step 5: Check the survivability band before going further**

The content run prints `survivability: X/40 won (P%), stalled S, died at ...`. If `S` is not 0, or `P` is outside 50–95, STOP. Do not touch a content table, do not tune anything: message the architect with the histogram and wait. That number, once inside the band, becomes the epic's new exact baseline replacing 25/40.

- [ ] **Step 6: Re-run the C1 determinism double-run tests and confirm they are still green and still unchanged**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/core && dart test -n "the same seed produces the same sequence|the same seed and depth build a byte-identical floor|the same seed places the same items|the same seed rolls the same item|equal profiles produce identical runs"
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/content && dart test -n "the same seed produces the same crawl|the same world seed builds the same five floors, twice over|is the same stock twice for one world and one visit|the same seed plays out the same way twice"
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng && git diff main --stat -- packages/core/test/town/run_boundary_test.dart packages/core/test/dungeon/generator_test.dart
```

Expected: 5 core + 4 content green, and none of those nine test bodies edited.

- [ ] **Step 7: Analyzer, formatter, and the content-diff gate**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng && flutter analyze && dart format --set-exit-if-changed . && git diff main --stat -- packages/content
```

Expected: analyze clean, format clean, and the content diff either empty or only the survivability test's own literals if it turned out to pin a stream (the band assertion itself byte-identical).

- [ ] **Step 8: Commit**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng && git add -A && git commit -m "test: re-pin seeded outcomes onto the new generator stream"
```

---

### Task 3: Run the mutation table, both halves

**Files:**

- Temporarily modify then revert: `packages/core/lib/src/engine/rng.dart`
- No file is left changed by this task.

**Interfaces:**

- Consumes: `Rng` from Task 1 and the green suites from Task 2.
- Produces: the mutation table for the report, with test names.

Every row: apply the one-line mutation, run the named suites, record what actually went red AND what stayed green, then `git checkout -- packages/core/lib/src/engine/rng.dart` before the next row. Verify the revert with `git status --short` each time — a mutation left in place would poison every later row.

- [ ] **Step 1: Row 1 — `state` returns a constant**

Change `int get state => _state;` to `int get state => 0;`. Expect red: the `Rng state export` group. Expect green (control): the rollRange bounds tests. Record both.

- [ ] **Step 2: Row 2 — `fromState` re-seeds from scratch**

Change `Rng.fromState(int state) : _state = state;` to `Rng.fromState(int state) : _state = _mix(state);`. Expect red: the `Rng state export` group. Expect green (control): "the same seed produces the same sequence". This row is only expressible because the constructor mixes the seed — note that in the report.

- [ ] **Step 3: Row 3 — `rollRange` upper end exclusive**

Change `% (maxInclusive - min + 1)` to `% (maxInclusive - min)`. Expect red: "both ends of the range are reachable". The control is a declared unknown: report what actually happened to BOTH golden stream tests, and to "a single-value range always returns that value" (a zero span is a modulo by zero). Do not predict — quote.

- [ ] **Step 4: Row 4 — the advance never happens**

Delete the `_state += _gamma;` line. Expect red: golden stream, full-range/both-ends tests, and broadly the seeded suites. Expect green (control): "an inverted range is rejected". Run all three suites for this row and report roughly how wide the damage was.

- [ ] **Step 5: Row 5 — CONTROL, no mutation**

`git status --short` must be empty. Run the content suite. Expect green with the new X/40 recorded. This row proves the previous four were reverted.

- [ ] **Step 6: Extension rows — hazards the spec's table misses**

Run these three as well, same discipline:

- **Row 6 — the sign mask is dropped:** `(_mix(_state) >>> 1)` becomes `_mix(_state)`. Dart's `%` is Euclidean, so bounds stay legal and every bounds test stays GREEN — this row exists to show that only the golden stream pins sign handling.
- **Row 7 — the increment changes:** `_gamma` becomes `-0x61c8864680b583ea` (one bit off, and now even, which shortens the period). Expect golden red, expect every property test green.
- **Row 8 — the seed is ignored:** `Rng(int seed) : _state = _mix(0);`. Expect "a different seed produces a different sequence" red.

- [ ] **Step 7: Confirm the tree is clean and the suites are green again**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng && git status --short && git diff --stat
```

Expected: empty. Then re-run all three suites one final time.

---

### Task 4: AVD smoke run and the build report

**Files:**

- Create: `BUILD-REPORT.md` at the worktree root (committed — it is NOT under `docs/epic/`)

**Interfaces:**

- Consumes: every number produced by Tasks 1–3.
- Produces: the verification block, mirrored for the architect.

- [ ] **Step 1: Boot the AVD and run the app**

```bash
emulator -avd Pixel_10 -no-snapshot-load
```

then, once `adb devices` shows it:

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng/packages/app && flutter run -d emulator-5554
```

`emulator,`adb, and device-facing `flutter` subcommands are sandbox-excluded and need no prompt. Enter the dungeon, fight one monster, descend one floor. Note anything odd — this is a smoke run, not a playthrough. If the AVD cannot be brought up, say so plainly in the report as a skipped phase with the reason; do not claim a smoke run that did not happen.

- [ ] **Step 2: Hygiene greps**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng
grep -n "dart:math" packages/core/lib/src/engine/rng.dart
grep -rn "Random(" packages/core packages/content --include=*.dart | grep -v ".dart_tool"
git diff main -- packages/core/lib packages/content/lib | grep -nE "^\+\s*//" 
```

Expected: all three empty.

- [ ] **Step 3: Write `BUILD-REPORT.md` with all twelve verification items**

Every item evidenced with quoted command output, not asserted. Item 10 (what the tests cannot prove) must at minimum state that the pinned properties say nothing about the generator's statistical quality — no equidistribution, avalanche, or spectral testing was run, and the golden stream pins the algorithm rather than validating it. Item 11 lists every spec claim checked and found wrong, with its source. Item 12 names which execution phases ran and argues any skip.

- [ ] **Step 4: Commit the report**

```bash
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng && git add BUILD-REPORT.md docs/superpowers/plans && git commit -m "docs: record the M3R build report"
```

- [ ] **Step 5: Message the architect**

Use the SendMessage tool addressed to "[arch] residuum-rpg" with the verification block. Printing to the transcript reaches nobody. If the reply is held, `BUILD-REPORT.md` is the channel.
