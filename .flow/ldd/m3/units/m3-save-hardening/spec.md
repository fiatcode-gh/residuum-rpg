# Spec — m3-save-hardening (story M3SH)

Recon of record: `docs/epic/m3-save-hardening-recon.md` (measured at
`d2b78be`). Forks locked in ledger D108. Save format stays **v3**; this unit
must NOT bump the version and must NOT move a golden document or a band line.

## Goal

The save pipeline stops failing silently. A save write that does not land is
reported to the player and never poisons later saves; a boot that throws shows
a real failure screen with a fresh-start door instead of a black screen; a
thrown read runs the current→previous fallback chain instead of bypassing it;
the decoder refuses engine-lethal and rule-breaking values (`speed: 0`, `hp >
maxHp`, out-of-range skill levels, `reach < 1`, repeated item ids, unbounded
energy) with read-aloud sentences; an `ArgumentError` out of `step()` becomes
a refusal, not an unhandled bloc error; the door-opening flow cannot hang on
a silent refusal or double-fire on a double tap; `IoSaveFiles` is tested
against a real temp directory; the TownViewState crawl fields become one
sealed value; and the codec totality test reaches a deep decoder while
`SavedHero`'s invariants gain tests. Measured effect: every path that today
fails silently (seven identified) ends in a word the player can read.

## Shape (precedent read from the codebase)

- **Decode refusals:** copy the temper check — `SaveMalformed` with a
  read-aloud sentence (`item_codec.dart:128–136` is the model), caught by
  `decodeSave` into `SaveFailure(reason)`. The codec never repairs, never
  clamps, never lets a throw escape.
- **Engine refusal:** `ActionRefused(reason: …)` (`event.dart:212`, built by
  `_refusedBy` at `step.dart:501`) — the event list is `step`'s only channel;
  the app-side guard emits into it.
- **File seam fakes:** `MemorySaveFiles implements SaveFiles`
  (`test/support/memory_save_files.dart`) — a real map-backed fake with
  failure injection, "not a mock". New failure injection follows its style.
- **Notice rendering:** the `Notice` widget (`town/town_style.dart:232–243`)
  — null renders `SizedBox.shrink()`, otherwise `— <sentence>.` in monoDim.
  The sealed type replaces the `String?` payloads, not the widget grammar.
- **Value-object pairing:** `SavedHero`'s constructor invariants
  (`save_read.dart:46–58`) are the model for the sealed crawl value's legal
  shapes.
- **House test flow:** refusal fixtures as their own commit BEFORE any codec
  change; characterization tests pass against the UNMODIFIED code first.

## New files

- `packages/app/lib/notice/notice.dart` — the sealed notice type (below).
- `packages/app/test/notice/notice_test.dart` — its tests.
- `packages/app/test/save/save_files_io_test.dart` — temp-directory suite.
- `packages/app/test/widget/boot_failure_screen_test.dart` — failure screen.
- `packages/app/test/save/queue_poison_test.dart` — characterization + fixed
  autosaver queue behaviour (name freely).
- Content refusal fixtures ride existing codec test files, as their own
  commit before the codec change.

## Changed files (exact paths)

- `packages/app/lib/save/save_store.dart` — renames inside failure handling;
  thrown-read mapping in `_readable`.
- `packages/app/lib/save/autosaver.dart` — queue error sink; document build
  reads the sealed crawl value; save-write failure notice emitted.
- `packages/app/lib/save/boot.dart` — thrown paths surfaced; fresh-boot
  failure does not silently advance.
- `packages/app/lib/main.dart` — guarded `main()`; failure screen; door
  in-flight guard; `_rosterChose` refuses to advance on a failed save.
- `packages/app/lib/save/save_files_io.dart` — injectable base directory;
  `read` maps every failure to null; exception contract documented.
- `packages/app/lib/save/save_files.dart` — interface dartdoc states the
  exception contract each method now honours.
- `packages/app/lib/town/town_bloc.dart` — sealed notice type on state;
  resume refusal emits a notice; the four crawl fields become the sealed
  value; door-refusing handler emits.
- `packages/app/lib/world/world_bloc.dart` — `notice` becomes the sealed
  type.
- `packages/app/lib/town/town_style.dart` — `Notice` renders the sealed type.
- `packages/app/lib/game/game_bloc.dart` — the three `step(` call sites
  guarded.
- `packages/app/lib/world/world_screen.dart` — door buttons disable while an
  opening is pending.
- `packages/content/lib/src/save/actor_codec.dart` — speed ≥ 1, hp ≤ maxHp,
  reach ≥ 1 as real checks; energy bound.
- `packages/content/lib/src/save/item_codec.dart` — skill level/xp ranges;
  item-id uniqueness.
- `packages/content/lib/src/save/profile_codec.dart` — profile-side checks
  that mirror the actor's (hp/skills live here too).
- `packages/content/lib/src/save/save_read.dart` — `SavedHero` invariant
  doc only if the rider's design touches it (pre-declare).
- `packages/core/lib/src/loot/item.dart` — the duplicate-tolerance dartdoc
  at lines 275–281 is rewritten to state the amended ruling (decode refuses
  duplicates; remove-one stays the removal semantics for ids that are
  unique by construction).
- Test files across both packages as the work requires.

## Per-item contract

### 1. Save write path (app)

- `SaveStore.save` returns false — never throws — for every failure,
  including both renames. The try covers write, read-back verify, and both
  renames; any failure forgets the pending slot and returns false. The
  dartdoc's "answering whether the save landed" becomes true.
- `Autosaver.saveNow` chains with an error sink: one failing save emits a
  save-failure notice ONCE (the first failure of a streak; do not spam one
  sentence per queued attempt) and the queue stays alive for later saves.
  `settled()`/`close()` never reject because of a failed save.
- The discarded bool is consumed: `boot.dart`'s five call sites and
  `main.dart:_rosterChose` treat a false as the save not landing. Hero
  creation and switching REFUSE TO ADVANCE: the roster stays, a notice names
  the failure ("the new hero could not be saved; nothing was lost" — final
  wording is the worker's, keep it a sentence a player reads in one breath).
  Boot-time saves that fail keep booting (the document is in memory) with
  the notice carried on `Boot`.
- Save-write notices ride the sealed notice type (below) onto the town
  state.

### 2. Boot guard and thrown-read fallback (app)

- `main()` guards the boot: any throw renders `BootFailureScreen` — the
  app's first failure screen — whose sentence names what failed, with one
  action **Begin fresh** that retries the fresh-boot path; if that throws
  again the screen re-renders the new sentence. No hue encodes state; the
  screen reads in greyscale.
- `SaveStore._readable` treats a THROWN read as an unreadable slot: the
  current→previous→fresh chain runs exactly as it does for a returned null
  today. `IoSaveFiles.read` maps every failure (including `_path`'s
  `MissingPlatformDirectoryException`) to null, so the store sees "absent or
  unreadable", never a throw, from `read`.
- The load path's sentence contract is unchanged — the fallback chain
  already owns its words.

### 3. Decode validation (content — SaveMalformed style, no repair)

Every check throws `SaveMalformed` with a read-aloud sentence in the house
voice ("the save file has …"). Exact bounds:

- **speed ≥ 1** — `speed: 0` is engine-lethal (infinite scheduler loop);
  refuse at decode. No upper bound (a huge speed is merely fast).
- **energy** — bounded `0 ≤ energy ≤ maxSaveEnergy` where the constant
  lives beside `actThreshold`/`actCost` in core (`energy.dart`) and the
  codec imports it. Pick the bound with the arithmetic in the dartdoc:
  a monster with energy E drains `actCost` per turn, so E/actCost is its
  worst-case turn count; a bound of 1000 (= 10× actThreshold) keeps a
  forged document to ≤ 10 scheduled turns while every real value (goldens
  carry 40 and 100) passes. The check is defense-in-depth — speed ≥ 1 is
  the hang fix.
- **hp ≤ maxHp, hp ≥ 0** — refuse on both actors and profiles. Profiles
  rebuild maxHp from the baseline (as `decodeProfile` already does); check
  against that rebuilt value.
- **skill level/xp** — `0 ≤ level ≤ maxSkillLevel` (the existing constant,
  `skill.dart:33`) and `xp ≥ 0` for every skill block. No new value object;
  codec range checks only.
- **Actor.reach** — the assert (`actor.dart:22`) gains a real decode check
  (`reach ≥ 1`) so a release build refuses what it would silently accept.
  Keep the omit-on-default encoding (`reach != 1`) untouched.
- **item-id uniqueness (the D108 amended ruling)** — the document's pack
  and worn ids must be pairwise distinct; a repeat throws `SaveMalformed`
  naming the repeated id. Scope is pack + worn ONLY: litter and merchant
  stock ids are floor-scoped/visit-scoped, never compared (state this in
  the dartdoc). `withoutFirst`/remove-one semantics stay exactly as shipped.
  Every golden passes (recon verified); every pre-mint save with a repeat
  now refuses and the slot chain moves on — accepted in D108.

### 4. Engine boundary (app)

- The three `step(` call sites (`game_bloc.dart:836, 866, 885`) catch
  `ArgumentError` and emit an `ActionRefused` with a fixed safe sentence
  (do not surface the internal error text) and do not apply the action.
  Core `step` is NOT changed — its signature has no error channel and gets
  none.

### 5. IoSaveFiles (app)

- `IoSaveFiles([Directory? home])` — injectable; when null, fetch from
  path_provider as today. With a directory injected, the class is pure Dart
  and testable.
- Test suite against `Directory.systemTemp.createTemp()`: absent file reads
  null; unreadable file reads null; write then read round-trips; rename
  over an existing target replaces it; rename of an absent source no-ops;
  write failure propagates; delete absent no-ops.
- `save_files.dart` interface dartdoc gains the exception contract: read
  never throws; write/rename/delete throw on failure after their documented
  no-ops.

### 6. Door reentrancy (app)

- `_openAnswer` gains an in-flight guard: a second door event while an
  opening is pending is ignored (or refused with a notice — worker's call,
  pre-declare). The `firstWhere` subscription is cancelled on unmount.
- `_onResumeCrawl` on an overrun or missing camp emits a resume-refusal
  notice instead of returning silently, so the pending await can resolve
  against a state that names the refusal.
- Door buttons disable while an opening is pending (shape/word marks the
  disabled state — greyscale-safe).

### 7. Sealed notice type (app)

- `sealed class Notice` (name it `Notice` only if it does not collide with
  the widget — prefer `SaveNotice`/`GameNotice`; pre-declare) with exactly
  three variants at this unit: **load failure** (boot/fallback sentences),
  **save-write failure**, **resume refusal**. Existing string sentences
  become payloads. Bloc `String? notice` fields become the sealed type;
  `_noticed(...)` wraps; the `Notice` widget pattern-matches and renders the
  sentence — same grammar, null-safe.
- Existing refusal strings (e.g. `refusal?.reason` at `town_bloc.dart:813`)
  flow through a generic sentence variant or stay `String?` on the specific
  path — worker pre-declares which; do not convert every refusal site, only
  the notice channel.

### 8. TownViewState sealed crawl value (the rider)

- The four coupled fields (`run`, `suspended`, `dungeon`, `campDay`) become
  ONE sealed value with only legal shapes representable: a **camp**
  (suspended state + dungeon + campDay), an **opening run instruction**
  (run + dungeon — `run` is one-shot, "an instruction rather than a fact",
  town_bloc.dart:241–243), or none. The run-XOR-suspended dartdoc rule
  survives as the type system, not prose.
- Named convenience getters (`suspended`, `campDay`, …) may remain to keep
  reader sites readable — pre-declare.
- One table-driven test asserts EVERY handler preserves an arriving camp
  (the TTC-4 remedy).
- The autosaver's bridge (`autosaver.dart:157–160`) reads the sealed value.
- The two bloc carry conventions (town: run is an instruction; save
  document: run+dungeon+campDay) stay — the type encodes them.

### 9. Test-hygiene riders

- **TTC-9:** the totality test gains fixtures that pass the version gate
  and reach the deep decoders — at minimum one per new check (speed 0, hp >
  maxHp, bad level, bad reach, repeated id, bad energy) plus one that
  decodes fully and successfully. Totality promise: nothing throws PAST the
  codec.
- **TTC-7:** tests for both `SavedHero` constructor invariants (run/dungeon
  pairing; campDay/camped pairing) — red without the constructor, green
  with it (they already exist in code; the tests characterize them).

## Behaviour arguments that must land in documentation

- **Why refuse-not-repair at decode** — the codec never repairs; a sentence
  names the problem. New checks state this in their dartdoc (temper's is
  the model).
- **The amended item-id ruling** — `item.dart:275–281` is rewritten:
  duplicates are now refused at decode (D108); remove-one stays correct for
  ids unique by construction. Pin the change with a codec test so nobody
  "restores tolerance" silently.
- **The energy bound's arithmetic** — E/actCost worst case; why 1000; why
  the bound is not the hang fix (speed ≥ 1 is).
- **Preserved defect:** the silent-refusal door hang is FIXED, but the
  adjacent-but-unseen armed-bump and invisible-tile walk-start nuances from
  D104 remain — do not fix them here; note them as untouched.
- **The one-shot run instruction** — its "instruction not fact" semantics
  must be stated on the sealed value or nobody will preserve it.

## Test plan

Characterization tests FIRST, passing against unmodified code, then flipped
or kept as the fix lands:

1. Queue poison (real `Autosaver` + a store whose rename throws once):
   later queued saves never run today. After the fix: later saves run and
   one notice appeared.
2. Thrown read bypass (store whose read throws): today the throw escapes
   `load()`. After: previous slot consulted.
3. Door silent refusal: resume-refused leaves the `firstWhere` pending
   today (prove with a later unrelated emission completing it). After: a
   notice resolves the wait.
4. Speed-0 decode: today decodes fine. After: `SaveFailure` sentence.
   (These codec refusals are the refusal-fixtures-first commit.)

Mutation table (reds are NAMED SETS; report both halves per row):

| Mutation | Expected red | Expected green (control) | Why |
|---|---|---|---|
| Delete the speed check | new speed refusal test; totality fixture | goldens; band suite | check is decode-only |
| Delete the id-uniqueness check | uniqueness refusal test | goldens (all ids distinct); remove-one tests | golden ids never repeat |
| Delete the hp ≤ maxHp check | hp refusal test | goldens (13/20, 5/12); band suite | golden hp is sane |
| Delete the level range check | skill refusal test | goldens (max level 3) | golden levels sane |
| Move renames back outside the try | rename-throw test on `save()` | verify-then-rotate tests | only the throw path changes |
| Delete the queue error sink | poison characterization (flipped to fixed) | ordering tests; no-op emission tests | sink only touches failure path |
| Revert `_rosterChose` to ignore the bool | refuse-to-advance test | happy-path roster tests | gate only fires on false |
| Delete the boot guard try | failure-screen widget test | boot happy-path tests | guard only on throw |
| Revert `_readable` to no try | thrown-read fallback test | returned-null fallback tests | the two paths are distinct |
| Delete the step-boundary catch | engine-boundary test (bloc emits refusal) | normal action tests | catch only on ArgumentError |
| Delete the door in-flight guard | double-tap test | single-open tests | guard only on second event |
| Delete the resume-refusal emit | door-refusal test | happy resume tests | notice only on refusal |
| Make `IoSaveFiles.read` throw again | temp-dir read tests | store-level tests (they use the fake) | adapter is below the seam |
| Collapse the sealed crawl value's camp variant | table-driven carry test | boot/resume tests with legal shapes | only illegal shape becomes representable |

Sequencing traps: the poison, thrown-read, and door characterizations
describe TODAY's behaviour — write them first, watch them pass, then let
the fix flip the assertion. The codec refusal fixtures are their own commit
BEFORE the codec change. A mutation that deletes code the change itself
removes (e.g. moving the renames) runs on the WORKING TREE before that
piece lands and is reverted after — say so in the report.

## Hazards

- Save format v3 — no version bump, no field added, no golden moves. Every
  new check must pass all three goldens (recon verified the values do).
- The codec never repairs or clamps — refuse with a sentence.
- No root pubspec — suites per package directory (`cd packages/<pkg> &&
  flutter test`); analyze from the WORKTREE ROOT with pwd quoted.
- Widget traps: `find.textContaining` is case-sensitive;
  `scrollUntilVisible` scrolls one way — assertions monotonic in document
  order; size at least one widget test like a phone (`_onAPhone, 1080×2424
  @ 2.625`).
- The AVD pass is MANDATORY (failure screen, notices, disabled door buttons
  are device-visible); greyscale screenshots for every new surface; the
  author reads greyscale.
- Deuteranomalous author: the failure screen and disabled buttons encode
  state by word/shape, never hue.
- Determinism: no new randomness anywhere; the failure paths draw nothing.
- The D56 lesson inverted: this unit adds NO fields, so no omit-on-default
  treatment is needed; the omit-on-default reach encoding must stay as-is.
- Sandbox: git as `cd <repo> && git <cmd>`; background-runner shells may be
  fish — wrap suites in `bash -c`.
- Never commit anything under `docs/epic/` or `docs/reports/`.

## Follow-ups to log (not this unit's work)

- CLAUDE.md module list + comment-policy direction (D102 group 3 — needs
  the author).
- Chore unit: CI, analyzer config, lockfiles, README refresh (D102 group 2).
- CDH-3 dead-hero ambush strikes — rides the next unit that opens
  `step.dart` (this unit does not open it).
- The armed-bump/invisible-tile tap nuances (D104) — next UX unit that
  opens the tap grammar.
- Auto-backup declaration, signing config, application id (pre-ship).

## Definition of done

- All three suites green per package directory, new counts reported from
  result files; every mutation row's named red set + green controls
  reported; characterization flips shown before/after.
- All three golden documents byte-identical (`git diff` on the literals
  shows nothing); all five band lines verbatim against the D79 pins.
- `dart analyze .` and format exit 0 from the worktree root.
- The refusal-fixtures commit precedes the codec commit in history.
- AVD pass: failure screen, a save-failure notice, a resume-refusal notice,
  disabled door buttons — each read in greyscale; shots saved to the
  report.
- Report lists every pre-declared deviation; save format still reports v3;
  no `Random(` unseeded anywhere new.