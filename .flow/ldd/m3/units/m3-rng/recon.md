# Recon — m3-rng (M3R), 2026-08-21

## VERDICT

The PRNG swap is contained: `Rng` is one 26-line class with one consumer
method (`rollRange`), eight production construction sites, and six test
files that construct it directly. The determinism tests compare double-runs
and survive unchanged; the artifacts that re-roll are the seeded-outcome
pins, chiefly the survivability rate.

## State verified before measuring

- `main` @ `472e62b` (M2Q merge, PR #1), clean, in sync with origin.
  613 tests (389 core + 95 content + 129 app) green on it, measured this
  session after the merge.

## The measurement

- `Rng` (`packages/core/lib/src/engine/rng.dart`): wraps
  `dart:math.Random(seed)`; sole method `rollRange(min, maxInclusive)`.
  `Random`'s internal state cannot be exported — the reason this unit
  exists (D23).
- Production construction sites (8): `rng.dart` itself; `generator.dart:214`
  (fresh Rng per floor build — rebuilt from seed, never needs saving);
  `run_boundary.dart:54-55` (the run's two live streams, `rng` and
  `lootRng, seeded `worldSeed` and `worldSeed ^ lootSeedSalt`);
  `economy.dart:99` (market stock, fresh per visit);
  `new_game.dart:71,147,148` (test/bot door).
- `GameState` carries `rng` and `lootRng` as deliberately mutable streams
  (`game_state.dart:20` documents the exception). These two are the ONLY
  streams that must be serializable for m3-saves; floor and market rngs are
  reconstructed from derived seeds.
- Test surface: 32 `Rng(` constructions across 6 files (`rng_test, `support/fixtures, `drop_test, `game_bloc_test, `game_state_test, `content_validation_test`). Determinism-style tests (same seed → same
  outcome twice) exist across ~10 files but compare two fresh runs, so they
  pass under ANY deterministic generator.
- Seeded-outcome pins that WILL re-roll: the survivability rate (25/40 —
  becomes a new number; the 50–95% band is the contract), market stock
  expectations, any drop/roll literal in the direct-construction tests.

## Is each inherited gate real?

- "Dart `Random` state cannot be exported" — confirmed by reading the class:
  it holds no state accessor, and `dart:math` offers none.

## Findings that change the spec

1. Only the run's two live streams need state export; every other Rng is
   throwaway (rebuilt from a derived seed). The API change is small:
   `state` out, `fromState` in.
2. Dart VM/AOT ints are 64-bit two's complement with wrapping arithmetic —
   a splitmix64-class generator is a handful of lines with a single int of
   state. The app targets Android (AOT); dart2js number semantics would
   break 64-bit wrapping, but no web target exists (D5 moved verification
   to the AVD).
3. The new baseline replaces 25/40 permanently: every future "exactly X/40"
   verification check pins to the number this unit measures and records.

## Proposed shape of the work

One unit, branch `m3-rng, story M3R: reimplement `Rng` on a
state-exportable generator behind the same constructor and `rollRange`
signature, add `state`/`Rng.fromState, prove suspend-resume equivalence,
re-pin the seeded-outcome tests honestly, re-baseline survivability inside
the band.

## Hazards to carry into the spec

- The survivability band (50–95%) may not hold under re-rolled streams; if
  it falls outside, free levers only (content tables), with a before/after
  trail and an architect ping BEFORE tuning.
- No test may be deleted or loosened to dodge a re-pin.
- The 64-bit wrapping substrate is VM/AOT-only; document the constraint.

## What this recon did NOT check

- The statistical quality of any specific generator (the spec names the
  family; the worker documents the choice and its bias argument).
- Whether any app-layer test pins a specific roll outcome transitively
  (game_bloc_test constructs Rng — the worker enumerates what actually
  reddens rather than trusting this list).
- Market/economy literal expectations were not read one by one.
