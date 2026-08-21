# Build report — unit `m3-rng`, story M3R "A generator that can be saved"

Build session, 2026-08-21. Branch `m3-rng`, base `472e62b`.
Spec: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-rng-spec-M3R.md`

**Headline for the architect: the band holds at 24/40 (60.0%), stalled 0.
That is the epic's new exact baseline, replacing 25/40. No content table was
touched. But the recon's central prediction was wrong — see item 11.**

---

## 1. Worktree and commits

```
$ git rev-parse --show-toplevel
/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng

$ git log --oneline main..HEAD
b919e41 feat: give Rng an exportable state on a splitmix64 core
```

```
$ git diff main --stat
 docs/superpowers/plans/2026-08-21-m3r-rng.md  | 428 ++++++++++++++++++++++++++
 packages/core/lib/src/engine/rng.dart         |  52 +++-
 packages/core/test/engine/rng_test.dart       |  94 ++++++
 packages/core/test/engine/step_drop_test.dart |   5 +-
 4 files changed, 567 insertions(+), 12 deletions(-)
```

Nothing under `docs/epic/` is committed. No push, no pull request, no merge.

## 2. Test counts, re-measured fresh before the first commit

I re-measured the baseline myself at `472e62b` before touching anything,
rather than taking 389/95/129 on trust. It matched exactly.

| Package | Baseline (my own measurement at `472e62b`) | At HEAD | Delta |
|---|---|---|---|
| core | 389 | 395 | +6 (the new tests) |
| content | 95 | 95 | 0 |
| app | 129 | 129 | 0 |
| **total** | **613** | **619** | **+6** |

```
$ (packages/core) dart test
00:01 +389: All tests passed!      <- baseline
00:00 +395: All tests passed!      <- HEAD

$ (packages/content) dart test
00:04 +95: All tests passed!       <- baseline
00:04 +95: All tests passed!       <- HEAD

$ (packages/app) flutter test
00:07 +129: All tests passed!      <- baseline
00:02 +129: All tests passed!      <- HEAD
```

## 3. C1 — the determinism double-run tests, at base and at HEAD

The cross-generator contract. Nine tests, enumerated by grepping for
double-run shapes across all three packages rather than from a supplied list:

- core `rng_test.dart` — the same seed produces the same sequence
- core `generator_test.dart` — the same seed and depth build a byte-identical floor
- core `generator_items_test.dart` — the same seed places the same items
- core `drop_test.dart` — the same seed rolls the same item
- core `run_boundary_test.dart` — equal profiles produce identical runs
- content `content_validation_test.dart` — the same seed produces the same crawl
- content `content_validation_test.dart` — the same world seed builds the same five floors, twice over
- content `economy_test.dart` — is the same stock twice for one world and one visit
- content `survivability_test.dart` — the same seed plays out the same way twice

**At base, against unmodified code:**

```
$ (core)    dart test -n "<the five core names>"
00:00 +5: All tests passed!
$ (content) dart test -n "<the four content names>"
00:00 +4: All tests passed!
```

**At HEAD:**

```
$ (core)    dart test -n "<the five core names>"
00:00 +5: All tests passed!
$ (content) dart test -n "<the four content names>"
00:00 +4: All tests passed!
```

All nine test bodies are byte-identical to `main` — none appears in
`git diff main --stat`.

## 4. Mutation table — every row, both halves

Rows 1–5 are the spec's. Rows 6–8 are extensions I added; row 6 found a real
hazard. Each mutation was applied alone, run, then reverted with
`git checkout --` and the revert verified with `git status --short` before the
next row.

| # | Mutation | Went RED | Stayed GREEN (control) | Verdict |
|---|---|---|---|---|
| 1 | `int get state => 0;` | 3 of the 4 `Rng state export` tests: *a restored generator continues the same stream*, *a restored generator matches across mixed range sizes*, *every roll moves the state on* | all three rollRange bounds tests: *rolls stay inside the inclusive range*, *both ends of the range are reachable*, *a single-value range always returns that value* | as spec predicted |
| 2 | `Rng.fromState` re-seeds: `_state = _mix(state)` | 3 of 4 equivalence tests: the two restore tests, plus *a seed and a state of the same value start different streams* | *the same seed produces the same sequence* | as spec predicted — **but only because of a design choice, see item 11** |
| 3 | upper end exclusive: `% (maxInclusive - min)` | *both ends of the range are reachable*; **also** *a single-value range always returns that value*, which throws `IntegerDivisionByZeroException` rather than returning a wrong value; 66 of 395 core tests overall | **the declared unknown, answered: the golden stream SPLITS.** *seed 12345 rolls a pinned sequence* goes RED (the modulus changes from 1000 to 999). *seed 12345 exports a pinned state after ten rolls* stays GREEN | unknown resolved — see below |
| 4 | advance deleted (`_state += _gamma;` removed) | golden stream **both halves**; *both ends of the range are reachable*; *every roll moves the state on*; core `step_combat_test` ×2, `step_hero_test` ×1; content `content_validation_test` ×1, `survivability_test` ×2; app `game_bloc_test` ×1 — **11 tests across 619** | *an inverted range is rejected* | red, but far narrower than the spec expected — see item 11 |
| 5 | CONTROL — no mutation | — | content suite `+95: All tests passed!`, `survivability: 24/40 won (60.0%), stalled 0` | green; proves rows 1–4 were reverted |
| 6 | **EXTENSION** — sign mask dropped: `(_mix(_state) >>> 1)` → `_mix(_state)` | *seed 12345 rolls a pinned sequence* — and nothing else | **every** property test: all three bounds tests, the ArgumentError test, both same-seed/different-seed tests, and all four `Rng state export` tests | **the hazard this row was written to find** — see below |
| 7 | **EXTENSION** — `_gamma` changed one bit (`…83eb` → `…83ea`, now even, shortening the period) | golden stream both halves | every property test, including *a different seed produces a different sequence* | golden is the only algorithm pin |
| 8 | **EXTENSION** — seed ignored: `Rng(int seed) : _state = _mix(0);` | *a different seed produces a different sequence*, golden stream both halves; 4 core tests total | *the same seed produces the same sequence*, all bounds tests, all four `Rng state export` tests | as designed |

**Row 3's declared unknown, answered.** The golden stream does not survive
intact and does not fail intact — it splits. The sequence pin reddens because
the modulus changes. The state pin survives, because in this design the state
advance (`_state += _gamma`) does not depend on the span at all: range
reduction happens after the advance and cannot influence it. That
independence is exactly what makes `state`/`fromState` cheap, and it is why
one of the two golden tests is blind to this mutation. Reported rather than
predicted, as the spec asked.

**Row 6 is the row that earns its place.** Dart's `%` is Euclidean — with a
positive right operand the result is never negative — so dropping the
`>>> 1` sign mask produces legal, in-range, plausible-looking rolls from a
different stream. Every bounds test, every determinism test and the entire
equivalence group stay green. Only the pinned golden sequence catches it. If
this unit had shipped without a golden stream test, a future refactor could
silently change every roll in the game and the 619-test suite would stay
green. That is the concrete argument for the golden stream pin existing.

**Row 4's damage is narrow, and that is a finding.** A generator that returns
the same value forever reddens 11 tests out of 619. See item 11.

After the last row: `git status --short` empty, `git diff --stat` empty, and
all three suites re-run green (395 / 95 / 129).

## 5. Survivability — the new exact baseline

```
survivability: 24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24
greedy build: 24/40 won; fleetfoot-first build: 7/40 won
```

- Rate 60.0% — inside the 50–95% band. **Band green.**
- Stalled 0 — contract met.
- **24/40 is the epic's new exact baseline, replacing 25/40.** Every future
  "exactly X/40" check pins to 24.
- For comparison, base at `472e62b`: `25/40 won (62.5%), stalled 0, died at
  1:2 2:6 3:6 4:1 5:25`, fleetfoot-first 8/40.

The shift is one run — well inside what a re-rolled stream can move. The
death histogram redistributes (depth 4 empties, depth 2 gains) but the shape
is the same. No lever was touched: no content table, no bestiary value, no
hero base stat. `git diff main -- packages/content` is empty. The band
assertion in `survivability_test.dart` is byte-identical to `main`.

## 6. Re-pinned tests — the full list

**No pre-existing seeded-outcome literal in the repository re-rolled.** The
complete list of changed assertions is three lines in two tests, and only two
of them are pins:

| Test | Old | New | Kind |
|---|---|---|---|
| `core/test/engine/rng_test.dart` — *the golden stream seed 12345 rolls a pinned sequence* | `[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]` | `[532, 31, 528, 241, 976, 115, 46, 965, 632, 353]` | new test; the zeros were a deliberate placeholder written to force a watched failure, replaced with the value read out of the failure message |
| `core/test/engine/rng_test.dart` — *the golden stream seed 12345 exports a pinned state after ten rolls* | `0` | `2420599403871909411` | same |
| `core/test/engine/step_drop_test.dart` — *a different combat seed cannot change what dropped* | `drops.map((item) => (item.base.id, item.rarity, item.affixes)).toSet()` | `drops.toSet()` | **not a re-pin — an assertion repair.** See item 11 |

No test was deleted. No assertion was loosened. No tolerance was widened. The
one assertion that changed shape got strictly stronger (it now compares the
drop id and every affix field, which the old form did not).

I checked the two golden values against an independent reference
implementation of splitmix64 written in Python with explicit 64-bit masking,
before pinning them. It reproduces the Dart output exactly — so the pinned
literals are textbook splitmix64, not "whatever my code happened to emit".

## 7. Analyzer, formatter, content diff

```
$ flutter analyze
No issues found! (ran in 3.3s)

$ dart format --set-exit-if-changed .
Formatted 88 files (0 changed) in 0.18 seconds.

$ git diff main --stat -- packages/content
(empty)
```

## 8. Hygiene greps

```
$ grep -nE "^import .*dart:math" packages/core/lib/src/engine/rng.dart
(empty)

$ grep -rn "Random(" packages/core packages/content --include=*.dart
(empty)

$ git diff main -- packages/core/lib packages/content/lib packages/app/lib \
    | grep -E "^\+" | grep "//" | grep -vE "^\+\s*///" | grep -vE "^\+\+\+"
(empty — every added comment is dartdoc)

$ grep -rn "package:flutter" packages/core/lib packages/content/lib --include=*.dart
(empty — the dependency rule holds)
```

`rng.dart` mentions `dart:math.Random` only inside a dartdoc sentence
explaining why it is no longer used. There is no import.

## 9. Device smoke run

Run on the `Pixel_10` AVD (`emulator-5554`), debug APK, driven by `adb`
taps with a screenshot read after each step. **Note:** a physical device was
also attached; the user asked me to leave it alone, so every `adb` and
`flutter` command in this run was pinned to `-s emulator-5554`. Nothing was
installed on the physical device.

What happened, in order:

1. Town screen renders — Health 20/20, Merchant / Bank / Inn / Gear / Enter Dungeon.
2. Enter Dungeon → floor generated, Depth 1/5, hero placed, an item glyph in view.
3. Walked east; `The giant rat comes into view.` — auto-walk correctly
   stopped and refused to path while engaged (`Something is watching. You
   stay put.`), which is the M2Q behaviour, not a regression.
4. Fought: `You hit the giant rat for 3.` / `The giant rat claws you for 2.`
   Damage rolls varied across swings — the seeded stream is feeding combat.
5. A second rat spawned, chased, fled, and was killed:
   `You hit the giant rat for 3. / The giant rat claws you for 2. / You hit
   the giant rat for 3. / The giant rat dies.` Health 20 → 14 over the two
   fights.
6. Explored, found `>`, auto-walked onto it; the `Descend >` control
   appeared. Descended: `You descend to depth 2.` — new floor generated,
   Depth 2/5, health and pack carried down, `Ascend <` offered.

Nothing odd. No visual glitch, no stall, no wrong glyph.
`adb logcat | grep -iE "flutter.*(exception|error)|E/flutter"` was empty for
the whole session.

## 10. What the tests cannot prove

- **The statistical quality of the generator.** Nothing here runs
  equidistribution, avalanche, spectral, birthday-spacing or any
  TestU01-class battery. The suite pins *properties* (in-range, both ends
  reachable, deterministic, restorable) and one *golden stream*. The golden
  stream pins that the algorithm has not changed; it says nothing about
  whether the algorithm is good. The argument for quality is entirely
  by-reference — splitmix64 is a published, widely-analysed generator and
  the constants are its published constants — not by measurement in this
  repository.
- **That the range-reduction bias is harmless in play.** The dartdoc argues
  it from arithmetic (at most `span / 2^63`). No test measures the
  distribution of `rollRange` output over a large sample, so a bias large
  enough to matter would not be caught by this suite.
- **64-bit wrapping under any compiler other than the Dart VM and AOT.** The
  suite runs on the VM only. If a web target is ever added, every test here
  would still pass on the VM while the game silently broke under `dart2js`.
  The constraint is documented, not enforced.
- **That `state`/`fromState` survive serialization.** The equivalence tests
  restore from an in-memory int. Writing that int to JSON and reading it back
  is m3-saves' problem; nothing here proves the round trip through a file.
  Note the exported state is a full-width signed 64-bit int — values like
  `2420599403871909411` are fine in Dart but do not survive a JSON parser
  that reads numbers as doubles.
- **That the survivability shift from 25 to 24 is noise rather than a real
  difficulty change.** One sample of 40 seeds cannot distinguish those.

## 11. Spec and recon claims I checked and found wrong

**(a) The recon's central prediction was wrong.** Recon,
`m3-rng-recon.md`, "The measurement": *"Seeded-outcome pins that WILL
re-roll: the survivability rate (25/40 …), market stock expectations, any
drop/roll literal in the direct-construction tests."* The spec inherits this
in "Changed files": *"Whatever seeded-outcome tests re-roll"*, and in
"Re-pinning": *"Seeded-outcome literals (market stock, drop rolls, any layout
pinned to a seed): re-pin to the new streams."*

Enumerated by running the suites at the first red commit, as instructed:
**exactly one test reddened across all 613, and it was not a seeded-outcome
pin.** Market stock did not re-roll. No drop literal re-rolled. No layout
literal re-rolled. `game_bloc_test.dart` and `fixtures.dart` — the named
transitive-pin hazard — did not redden at all. The only literals I re-pinned
are the two I introduced myself.

The reason is that this codebase almost never asserts *what* a seed produced;
it asserts that two runs of the same seed agree, or that a value is in range.
That is good test design, but it has a consequence worth carrying forward:
**the suite was, before this unit, almost blind to the identity of the
generator.** Mutation row 4 makes the size of the blind spot concrete — a
generator returning the same value forever reddens 11 tests out of 619, and
4 of those 11 are the tests this unit just added. The spec's row 4 expectation
("and broadly the seeded suites") overstates it by a wide margin.

**(b) The one test that did redden was already broken, and base was hiding
it.** `packages/core/test/engine/step_drop_test.dart`, *a different combat
seed cannot change what dropped*, built `(item.base.id, item.rarity,
item.affixes)` records and put them in a `Set`. The third field is a raw
`List<Affix>`, and `List` compares by identity in Dart — so six
value-identical drops produce six distinct set entries unless the lists are
literally the same object.

It passed on `main` by luck. `rollDrop` returns early for a potion with
`Item(id:, base:, rarity: Rarity.common)`, taking the `affixes = const []`
default — a canonicalized, shared instance. The old stream happened to drop a
potion on that seed, so all six records shared one `const []` and the set
collapsed to one. The new stream drops an `iron-sword`, which takes the
non-potion path and builds a fresh `<Affix>[]` each time, so the set had six
entries — while all six drops were, in fact, identical: `(iron-sword,
Rarity.common, [])` six times over.

So the property under test held perfectly; the comparison never worked. This
is not a re-pin and I did not treat it as one. I replaced the tuple with
`drops.toSet()`, comparing whole `Item`s — `Item` extends `Equatable` with
`props => [id, base, rarity, affixes]`, and Equatable compares lists by value.
That is strictly stronger than the old form: it now also compares the drop id
and every affix field.

I checked the repaired assertion is not vacuous before accepting it: with
`lootSeed: combatSeed` substituted so the six runs genuinely differ, it fails.
Reverted after the check.

Worth the architect's attention: **any test in this repository that puts a
record containing a `List` into a `Set`, or compares such records with `==`,
has the same latent defect.** This one was caught only because a stream change
flipped which branch of `rollDrop` ran.

**(c) Mutation row 2 is only expressible because of a design choice I made,
and the spec did not notice the dependency.** The spec's table asks for
"`fromState` re-seeds from scratch instead of restoring". Under the most
obvious implementation — `Rng(seed) : _state = seed` and
`Rng.fromState(state) : _state = state` — those two constructors are the same
code, "re-seeding from scratch" *is* restoring, and the mutation is a literal
no-op that could not redden anything.

I made `Rng(int seed) : _state = _mix(seed)` apply one finalizer round to the
seed, so that a seed and a state of the same numeric value are genuinely
different starting points. That makes row 2 a real mutation, and it adds a
fourth equivalence test (*a seed and a state of the same value start
different streams*) that pins the distinction. `_mix` is a bijection, so this
costs nothing in generator quality — it is a relabelling of the seed space.

This is an internal seeding detail, not an API change: the contract is still
exactly `Rng(int seed)`, `state`, `Rng.fromState(int)`, `rollRange`. I did not
treat it as a shape deviation needing a pre-declaration, but I am flagging it
because the spec's mutation table silently depends on it.

**(d) Nothing else in the spec was wrong.** The API contract, the inclusive
semantics, the ArgumentError, the VM/AOT constraint, the "no `dart:math` may
remain" rule and the band's stop-and-ping rule were all accurate and all
held.

## 12. Execution phases — what ran, what was skipped

**Ran:**

- **Clarify / read.** Spec, recon and root `CLAUDE.md` read in full before planning.
- **Characterization.** Baseline re-measured myself at `472e62b` (389/95/129,
  matching), and C1 run and quoted against unmodified code before any edit.
- **Plan.** `writing-plans` skill, saved to
  `docs/superpowers/plans/2026-08-21-m3r-rng.md` and committed. Four tasks,
  bite-sized steps, self-reviewed against the spec.
- **Implement.** `test-driven-development` skill, strict red → green. The
  equivalence group and both golden tests were written first and watched fail
  (`Member not found: 'Rng.fromState'`, `The getter 'state' isn't defined`),
  then the generator was written, then the two golden literals were replaced
  with values read out of the failure message — never computed into the test
  ahead of the failure.
- **Mutation table.** All five spec rows plus three extensions, both halves,
  each reverted and the revert verified.
- **Verification.** Three suites, analyzer, formatter, hygiene greps, content
  diff gate, AVD smoke run.

**Skipped, with the argument:**

- **Per-task reviewer subagents.** Ledger D9 accepts inline execution with the
  mutation table carrying the adversarial load, and the build prompt permits
  the skip if argued. The argument: the production diff is 24 non-dartdoc
  lines in one file with one public method, and the adversarial work that a
  reviewer would do — "does this test actually catch a wrong implementation?"
  — was done mechanically by eight mutations rather than by opinion. Row 6 in
  particular found a hazard (Euclidean `%` hiding a lost sign mask) that a
  reading review would very likely have missed, because the mutated code
  looks correct and passes every property test. A reviewer's added value here
  would have been below what the mutation table already delivered.
- **A `git log` regression bisect.** Not applicable — this is new work, not a
  "this used to work" bug.
- **Content tuning and its before/after trail.** Not needed: the band held at
  60.0% on the first run. No lever was touched.

**Not skipped but worth naming:** the smoke run used the AVD only. The
attached physical device was excluded at the user's request mid-session.
