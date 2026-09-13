# Story spec — M3S "Saves" (unit `m3-saves`)

Decided in ledger D23 (full suspend-save, rolled world seeds) with inputs
from D24 (64-bit JSON hazard) and the recon (`m3-saves-recon.md`). Base:
`main` @ `0656eb1, 619 tests (395 core + 95 content + 129 app), measured
fresh 2026-08-21. Exact survivability baseline: 24/40.

## Goal

Closing the app stops losing the game. The profile persists across launches;
a run in progress is suspended exactly — same tile, same hit points, same
monster energies, same random streams — and resumes on relaunch; a corrupt
save falls back to the previous snapshot and says so; a brand-new hero rolls
their own world seed. Measurable: kill the app mid-fight on the AVD,
relaunch, and the same fight continues roll-for-roll; 24/40 unchanged.

## Shape — precedents to follow

- **Codec home**: content package, new feature folder
  `packages/content/lib/src/save/` — the codec needs core types AND the
  content registries (app → content → core holds; core stays pure).
- **Structured failure**: `TownRefusal` (`town.dart`) is the precedent — a
  load failure is a value with a readable sentence, never an exception
  escaping to the UI.
- **Self-contained snapshots**: `FloorMemory`'s dartdoc argument (terrain
  kept so a restore can never regenerate) governs the run codec too.
- **Re-injection at the boundary**: `startRun` (`run_boundary.dart`) shows
  exactly what content supplies (`buildFloor, `dropTables`); `loadRun`
  re-injects the same way.
- **Golden pin**: M3R's golden stream test — the save format gets a golden
  fixture for the same reason.

## New files

- `packages/content/lib/src/save/save_codec.dart` (+ split as it grows) —
  encode/decode for the single save document.
- `packages/content/lib/src/save/save_failure.dart` — the structured
  failure value.
- Registry lookups (in `armory.dart` / `affix_pool.dart` or a small
  `registry.dart`): `BaseItem? baseItemById(String), `Affix? affixById(String)`.
- `packages/app/lib/save/save_store.dart` — file I/O: two-slot rotation,
  atomic write, pure rotation/fallback logic separated from the I/O edge.
- `packages/app/lib/save/autosaver.dart` — the wiring that watches both
  blocs and writes.
- Tests mirroring each (content: codec tests + golden fixture; app:
  pure-logic and bloc tests).

## Changed files

- `packages/app/lib/main.dart` — boot: load → fallback → fresh; resume
  into the crawl when a run block exists; seed roll for a fresh hero.
- `packages/app/lib/town/town_bloc.dart` / `town_screen.dart` — abandon-
  hero door; surfacing the fallback report via the existing `notice`.
- `packages/content/lib/content.dart, exports.
- `packages/app/pubspec.yaml` — `path_provider` (allowed; the cap is on
  core).

## Per-item contract

### 1. The save document (version 1)

One JSON document holding everything:

- `version`: the integer 1, first field, checked before anything else.
  Unknown version → structured failure (the fallback chain handles it).
- `profile`: hero as **earned fields only** (hp — the base body rebuilds
  from content's fresh hero, so future rebalances reach old saves and hero
  base stats never fossilize), equipment/inventory/bank as item references,
  skills as `{id: {level, xp}}, gold, bankedGold, worldSeed, visit.
- `run` (optional, null when the hero is in town): depth, worldSeed, visit,
  gold, isGameOver, hero and monsters as **full actors** (all 12 fields —
  a run is frozen mid-fight state, same honesty as FloorMemory's terrain),
  map as the ASCII the parser already reads (the codec adds the inverse
  renderer), visible/explored, stairs, groundItems, inventory, equipment,
  skills, nextDropNumber, `rngState, `lootRngState, and `floors` (each
  FloorMemory with the same field treatment).
- **Every 64-bit-wide integer — seeds, rng states — is encoded as a JSON
  string**, never a number (D24: full-width ints do not survive double
  semantics). Small counted ints (hp, gold, depth, level) stay numbers.
- Item reference: `{id, base, rarity, affixes: [ids]}`. Unknown base or
  affix id at load → structured failure naming the id.

### 2. The codec (content)

- `encodeSave(Profile, {GameState? run}) → String` and
  `decodeSave(String) → (SaveDocument | SaveFailure)` — total functions:
  malformed JSON, wrong version, missing field, unknown id all return a
  `SaveFailure` with a readable sentence; nothing throws past the codec.
- `loadRun` rebuilds `buildFloor` via `residuumDungeon(worldSeed)(visit)`
  and re-injects content's drop tables, exactly as `startRun` does — and
  must NOT bump the visit (resuming is not entering).
- Restored streams: `Rng.fromState, roll-for-roll.
- What it must not do: no file I/O in content; no `dart:io` import; no
  DateTime anywhere; the codec never silently repairs a bad document.

### 3. Storage (app)

- Files in the app documents directory (path_provider): `save.json` and
  `save-previous.json`.
- Atomic write: write to a temp file, flush, rename over `save.json`;
  rotate the old current to `save-previous.json` ONLY after the new write
  has fully succeeded (verify-then-rotate — a failed write must leave both
  existing slots untouched).
- Load chain: `save.json` → on failure `save-previous.json` → on failure a
  fresh hero. Every fallback step produces a report the town screen shows
  once via its existing `notice` mechanism ("your last save could not be
  read; an older one was restored" / "...; a new hero begins").
- Rotation/fallback decisions are pure functions over injected
  read/write/rename operations, unit-tested without real files; the real
  I/O edge is a thin adapter verified on device.

### 4. Autosave

- Town: save after every `TownBloc` emission (transactions are rare;
  always-save is simplest and safest).
- Run: save after every settled `GameBloc` game-state change (a suspend
  save that lags even one step returns the player to a fight they already
  won or lost differently). **Measure the real cost on the AVD at depth 4–5
  with full floor memories**; if a full encode per step visibly janks, the
  approved fallback is: encode every step but write every Nth step AND on
  every floor transition, death, and app-lifecycle pause
  (`AppLifecycleState.paused/inactive`), with N named and the measurement
  in the report. Do not invent a different scheme without pre-declaring.
- A game-over run saves like any other (relaunch shows the death overlay);
  `RunEnded` (endRun) clears the run block. The document is written with
  `run: null` at that moment — town re-entry is what un-suspends.

### 5. Boot and resume (app)

- No readable save → fresh hero with `worldSeed` rolled from
  `DateTime.now().millisecondsSinceEpoch` (app layer is the sanctioned home
  for unseeded randomness; core/content stay forbidden), then save
  immediately so the world outlives the first crash.
- Save with `run: null` → town, as today.
- Save with a run → restore straight into the crawl: town screen under,
  game screen pushed (the architecture `leaveDungeon` documents), GameBloc
  constructed with the restored state. The message log does not persist
  (accepted loss — the log is app view-state; one line "the crawl resumes"
  is emitted instead).
- Abandon hero: a town control, guarded by an explicit confirmation, that
  deletes both save slots and boots a fresh hero (new rolled world). This
  is the only way a rolled world ends. **Scope addition flagged to the
  user in the handoff message — remove if vetoed.**

## Behaviour arguments that must land in documentation

- Why one document rather than a profile file and a run file (desync under
  kill-between-writes).
- Why the profile's hero saves earned fields only while a run saves full
  actors (rebalance reach vs frozen honesty) — both halves of the argument,
  at the codec.
- Why 64-bit values are strings (double semantics), at the encoding site.
- Why `loadRun` must not bump visit (resuming is not entering), beside the
  `startRun` contrast.
- Why verify-then-rotate, at the rotation function.

## Test plan

Characterization first, against UNMODIFIED code:

- C1 (app): boot today constructs `newProfile()` with worldSeed 1 and shows
  the town — pin it, then replace it deliberately in the boot commit (the
  characterization is deleted with argument, not weakened).

Then unit tests (content unless said otherwise):

- Profile round-trip: `decode(encode(p)) == p` for a profile with affixed
  gear, banked items, trained skills, wounded hero (Profile is Equatable).
- Hero-rebuild semantics: a saved profile whose content hero later changes
  rebuilds on the NEW base (test by encoding, then decoding with a resolver
  seam if the codec has one, or document why untestable and pin the earned-
  fields list instead).
- Run round-trip: field-by-field equality on every data field (GameState is
  not Equatable), including per-floor FloorMemory fields, both stream
  states, and the ASCII map surviving parse(render(map)).
- **The suspend theorem** (the unit's reason): take a mid-run state, apply
  a fixed action list; separately encode→decode the same state and apply
  the same list; every emitted event and every resulting field identical —
  including combat rolls and drops (exercises `Rng.fromState` end to end).
- Precision: a state and seed above 2^53 round-trip exactly.
- Failures: malformed JSON; version 2; missing field; unknown base id;
  unknown affix id — each returns the structured failure naming the cause.
- Golden fixture: a committed v1 document decodes to a pinned profile; the
  encoder reproduces it byte-for-byte (format drift becomes a red test).
- App (pure logic): rotation happy path; failed write leaves both slots;
  fallback chain current→previous→fresh with the right report at each step.
- App (bloc): boot with a run block resumes into the crawl state; RunEnded
  writes `run: null`; abandon-hero requires the confirmation event.

### Mutation table

| # | Mutation (one line, revert after) | Must go red | Must stay green (control) |
|---|---|---|---|
| 1 | `loadRun` seeds streams fresh from worldSeed instead of `fromState` | suspend theorem (rolls diverge) | non-rng field round-trips |
| 2 | item codec drops the affix list | affixed round-trip + golden fixture | plain-item round-trip |
| 3 | version check removed (any version accepted) | version-2 failure test | valid-document test |
| 4 | rotation swapped to rotate-then-write | failed-write-preserves-slots test | happy-path save test |
| 5 | run codec omits `floors` | multi-floor round-trip + suspend theorem on a revisited floor | single-floor round-trip |
| 6 | 64-bit fields encoded as JSON numbers | precision round-trip | small-int fields |
| 7 | `loadRun` bumps visit like `startRun` | visit round-trip test | profile visit test |
| 8 | monster energy zeroed in the actor codec | energy field in run round-trip | position/hp fields |
| 9 | CONTROL — no mutation: content suite | — | survivability exactly 24/40; golden fixture green |

Sequencing traps: C1 is deleted (with argument) in the boot commit — run
and record it at base first. Row 6 requires the precision test to use a
value above 2^53 — a small test value would make the row unfailable
(doctrine rule: a mutation that cannot fail is not a test).

## Hazards

- The active floor is not in `floors` — the codec captures it from the
  state's own fields; forgetting it loses the floor the player is standing
  on and no round-trip of `floors` alone will notice.
- Encode-per-step cost is unmeasured (recon gap) — measure before choosing
  the cadence; the fallback is named in the contract.
- `Set<Position>`/`Map<Position...>` keys need a stable position encoding.
- Emulator file paths differ from device paths — path_provider handles it;
  do not hardcode.
- The app suite has no widget tests (convention) — resume navigation is
  verified on the AVD, and the kill-mid-fight scenario is the acceptance
  test: `adb shell am force-stop, relaunch, same tile, same hp, same
  monster positions, then the SAME next roll (provoke one attack and
  compare against a pre-kill screenshot pair).
- Do not touch core. If the codec is missing a getter it needs, that is a
  pre-declared deviation, not a quiet core edit.

## Follow-ups to log

- Multiple heroes / named save slots (M5 territory).
- Message-log persistence across suspend (deliberately dropped here).

## Definition of done

- All three suites green; baseline was 395/95/129 = 619 (fresh, 2026-08-21, `0656eb1`); report new counts.
- `flutter analyze` clean; `dart format --set-exit-if-changed .` clean.
- Mutation table fully run, both halves reported.
- Survivability: exactly 24/40, stalled 0; `git diff main -- ` on bestiary/
  spawn/drop/xp levers empty (content gains ONLY the save feature and
  registry lookups).
- No `dart:io`/DateTime in content; no unseeded randomness outside the one
  boot-time seed roll; hygiene greps quoted.
- AVD acceptance: kill-mid-fight resume (screenshot pair), corrupt-file
  fallback (truncate save.json by hand, relaunch, previous restored +
  notice shown), both-corrupt fresh-hero path, death-overlay resume,
  abandon-hero confirm flow, fresh install rolls a non-1 world seed and
  survives an immediate kill.
- Greyscale check of any changed screen.
- `BUILD-REPORT.md` mirrors the verification block.
