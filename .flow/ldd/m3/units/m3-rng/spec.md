# Story spec — M3R "A generator that can be saved" (unit `m3-rng`)

Decided in ledger D23. Recon: `m3-rng-recon.md`. Base: `main` @ `472e62b,
613 tests (389 core + 95 content + 129 app), measured fresh 2026-08-21.

## Goal

`Rng` becomes a generator whose full state is one exportable value, so a run
in progress can be serialized (m3-saves needs this and nothing else from this
unit). The public behavior contract is unchanged: seeded, deterministic, `rollRange` inclusive on both ends. Every seeded artifact re-rolls once, is
re-pinned honestly, and the survivability rate lands inside 50–95% and is
recorded as the epic's new exact baseline.

## Shape — precedents to follow

- `Rng` stays in `packages/core/lib/src/engine/rng.dart, same constructor
  `Rng(int seed), same `rollRange(int min, int maxInclusive)` including the
  `ArgumentError` on an inverted range.
- The mutable-stream design is deliberate and stays: `GameState`
  (`game_state.dart:20`) documents that `rng`/`lootRng` advance statefully.
  State export is introspection, not a redesign.
- Test style: `rng_test.dart` is the precedent for generator tests.

## New files

None required; the change lives in `rng.dart` and its test.

## Changed files

- `packages/core/lib/src/engine/rng.dart` — the generator swap + state API.
- `packages/core/test/engine/rng_test.dart` — new contract tests.
- Whatever seeded-outcome tests re-roll (the worker enumerates them by
  running the suites, not from the recon's list).
- `packages/content/test/survivability_test.dart` — only if its literals
  pin the old streams; the band assertion itself must NOT change.

## Per-item contract

### The generator

- A splitmix64-class generator: 64-bit state, wrapping arithmetic, pure
  Dart, no dependencies. The exact algorithm is the worker's choice within
  that family; the choice and its range-reduction bias argument go in
  dartdoc (dartdoc only on public API, per conventions).
- `Rng(int seed)` — same signature; any int seed valid, including the
  existing salted/xored derivations.
- `int get state` and `Rng.fromState(int state)` — the entire generator
  state in one int, restorable exactly.
- `rollRange` keeps both-ends-inclusive semantics and the ArgumentError.
- What it must NOT do: no `dart:math` import remains in `rng.dart`; no
  second stream type; no API additions beyond `state`/`fromState`.

### The equivalence property (the reason this unit exists)

After any number of rolls, `Rng.fromState(a.state)` must continue with a
stream identical to `a`'s — roll-for-roll, for mixed range sizes. This is
the property m3-saves will build on; it gets its own test group.

### Re-pinning

- Determinism double-run tests: must pass UNCHANGED. If one fails, the
  generator is not deterministic — stop.
- Seeded-outcome literals (market stock, drop rolls, any layout pinned to a
  seed): re-pin to the new streams, one honest value each. No test deleted,
  no assertion loosened, no tolerance widened to dodge a re-pin. Report the
  full list of re-pinned tests.
- Survivability: the band assertion (50–95%, stalled 0) is the contract and
  stays byte-identical. Run it, record the new X/40 in the report — that
  number becomes the epic's exact-baseline replacing 25/40. If it falls
  OUTSIDE the band: stop, message the architect with the histogram before
  touching any lever; content tables are the only levers and any tuning
  ships with a before/after trail.

## Behaviour arguments that must land in documentation

- On `Rng`: why the generator is hand-rolled rather than `dart:math.Random`
  (state export for suspend-save — cite the inability, not just the
  preference), and the range-reduction bias argument.
- The 64-bit wrapping substrate is VM/AOT-only (dart2js number semantics
  would break it); the app targets Android, and this constraint is stated
  where the arithmetic lives.

## Test plan

Characterization first, against UNMODIFIED code:

- C1: the determinism double-run tests already exist and pass — run them at
  base and quote it. They are the cross-generator contract.

Then unit tests:

- rollRange bounds: min == max; full range reachable over many rolls; both
  ends observed; ArgumentError preserved.
- Same seed → identical stream; different seeds → different streams.
- The equivalence property group (snapshot mid-stream, restore, compare
  long mixed-range tails).
- A fixed-seed golden stream (first N values for one seed) — the pin that
  makes an accidental algorithm change visible.

### Mutation table

| # | Mutation (one line, revert after) | Must go red | Must stay green (control) |
|---|---|---|---|
| 1 | `state` returns a constant | equivalence group | rollRange bounds tests |
| 2 | `fromState` re-seeds from scratch instead of restoring | equivalence group | same-seed determinism test |
| 3 | `rollRange` upper end exclusive | both-ends-observed test | golden stream test (if it survives, say so — an exclusive end may shift the stream too; report what actually happens) |
| 4 | generator advance never updates state (same value forever) | golden stream + full-range tests, and broadly the seeded suites | ArgumentError test |
| 5 | CONTROL — no mutation: content suite | — | band green; new X/40 recorded |

Sequencing trap: row 3's control is a genuine unknown — the spec does not
claim to know whether the golden stream survives that mutation; the row
exists to find out, and both halves get reported either way.

## Hazards

- The band may not hold under new streams (recon hazard); the stop-and-ping
  rule above is binding.
- `game_bloc_test.dart` and `fixtures.dart` construct Rng directly — app
  tests may pin rolls transitively. Enumerate by running, not by reading.
- Do not touch `packages/content` tables unless the band fails, and then
  only with the trail + architect ping.

## Follow-ups to log

- None expected; this unit exists to unblock m3-saves.

## Definition of done

- All three suites green; baseline was 389/95/129 = 613 (fresh, 2026-08-21, `472e62b`); report new counts and the full list of re-pinned tests.
- `flutter analyze` clean; `dart format --set-exit-if-changed .` clean.
- Mutation table fully run, both halves reported.
- Survivability: band green, new X/40 + died-at histogram recorded.
- No `dart:math` in `rng.dart`; `git diff main -- packages/content` empty
  (or the argued, architect-approved tuning trail).
- A short AVD smoke run (enter dungeon, fight once, descend once) — the
  streams feed real play; no full playthrough needed.
- `BUILD-REPORT.md` mirrors the verification block.
