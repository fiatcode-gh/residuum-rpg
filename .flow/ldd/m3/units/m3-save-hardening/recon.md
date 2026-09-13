# Recon — m3-save-hardening

## VERDICT

Every audit group-1 claim about the save write path, boot guard, decode
validation, IoSaveFiles coverage, and door reentrancy HOLDS at `d2b78be` —
except two. The "huge energy hangs the scheduler" claim is wrong in mechanism
(only `speed < 1` loops forever; huge energy is unbounded work, not an
infinite loop), and the audit's proposed item-id uniqueness check CONTRADICTS
the shipped m3-itemids design (duplicate ids in legacy saves are tolerated by
ruling; the check would refuse legal saves and must be dropped). The
TownViewState rider measures MEDIUM (9 construction sites, no copyWith,
~204 test lines touching the four fields) — too large to ride honestly.

## State verified before measuring

- Repo `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg`,
  branch `main`, HEAD `d2b78be` (the D107 re-squash; tree content-identical
  to the D106-verified `bf8bcb6`). Working tree clean.
- Four read-only recon agents (write path; boot/read fallback; decode
  validation; IoSaveFiles + door + rider), each re-measuring the 2026-09-03
  audit's group-1 claims at source. The architect independently re-read the
  three load-bearing spots: `energy.dart:75–105`, `item.dart:275–281`,
  `save_store.dart:39–58`.

## The measurement

### Write path (all four facets HOLD)

- `SaveStore.save` returns `Future<bool>` (`save_store.dart:41`); all
  production callers discard it — `boot.dart:76, 99, 110, 122, 148` and
  `autosaver.dart:174`. `main.dart:_rosterChose` (~81–103) advances the
  session (`_generation++`) after `createHero`/`switchHero`/
  `replaceOnlyHero` without checking the result: a save that did not land
  still swaps the session.
- The two renames sit outside `save()`'s try (`save_store.dart:54–55`; the
  try covers only the `write`, lines 42–47). A rename-level
  `FileSystemException` escapes as a throw, contradicting the dartdoc
  ("answering whether the save landed").
- `Autosaver.saveNow` (`autosaver.dart:170–176`) chains `_queue.then(...)`
  with no error handler; one thrown save rejects `_queue` and every later
  queued save never runs; `settled()`/`close()` reject too. Autosaver has NO
  notice/error sink today — only `saveNow`, `settled`, `close`, and the
  three `watch*` methods.
- Read-back verify in `save()` returns false on mismatch (good); the store's
  verify-then-rotate logic itself is sound. The gap is entirely reporting.

### Boot and read fallback (all claims HOLD)

- `main()` (`main.dart:18–22`) awaits `bootFrom` before `runApp` with no
  guard, no zone, no `PlatformDispatcher.onError`, no `Bloc.observer`
  anywhere in the package. A boot throw = black screen; `runApp` never runs.
- `IoSaveFiles._path` awaits `getApplicationDocumentsDirectory()` outside
  any try (`save_files_io.dart:54–56`); `read` calls `_path` BEFORE its try
  (line 20). A `MissingPlatformDirectoryException` escapes every method.
- `SaveStore._readable` (`save_store.dart:83–90`) awaits `_files.read(slot)`
  with no try; `load()` falls back to the previous slot only on a RETURNED
  null. A thrown read bypasses the current→previous fallback entirely.
- No error/boot placeholder screen exists anywhere in packages/app. The
  failure-surface precedent is a plain `String? notice` field on bloc state
  (`TownViewState.notice`, `WorldViewState.notice`), set via
  `_noticed(...)`/`_settled(...)`, rendered by the `Notice` widget
  (`town_style.dart:232–243`); the boot notice also reaches the crawl log
  (`main.dart:_openingLog`). There is no sealed notice type to extend.

### Decode validation (holds, with two corrections)

- House style for decode refusals: `SaveMalformed` with a read-aloud
  sentence (`save_json.dart:5–22`), caught by `decodeSave` into
  `SaveFailure(reason)` — the codec never lets a throw escape. Existing
  range checks to copy: temper (`item_codec.dart:128–136`), unknown
  references refused by name, campDay pairing.
- `speed: intAt(from, 'speed')` with no range check
  (`actor_codec.dart:100`); `speed: 0` throws ArgumentError out of the
  unguarded `step()` on the first resumed move (`energy.dart:105`). CONFIRMED
  by my own read: the scheduler loop only advances `hero += heroSpeed`, so
  `heroSpeed: 0` never reaches `actThreshold` — an infinite loop.
- **CORRECTION — energy:** the audit's "huge energy hangs the scheduler" is
  wrong in mechanism. Each scheduler iteration drains `actCost` from a ready
  monster (`energy.dart:96–105`); a huge value yields a proportionally LONG
  schedule (unbounded work for an extreme value), not an infinite loop.
  An energy bound is still cheap defense-in-depth, but it is not the hang
  fix — `speed ≥ 1` is.
- **CORRECTION — item-id uniqueness:** NOT a defect. `item.dart:275–281`
  codifies the m3-itemids ruling: "legacy saves can hold duplicate ids — and
  removing exactly one is the honest semantics." A uniqueness check would
  refuse saves the game itself declares legal. DROPPED from the unit; the
  ledger should record the disagreement with the audit.
- `hp > maxHp` unvalidated (HOLDS): `actor_codec.dart:97`,
  `profile_codec.dart` — no check anywhere.
- Skill levels raw ints (HOLDS): `item_codec.dart:183` reads level/xp with
  no range; `SkillState` has no constructor invariant
  (`skills/skill.dart:45–46`); `maxSkillLevel = 100` exists (`skill.dart:33`)
  but is not enforced at decode. No `SkillLevel` value object exists.
- Assert-only invariants (TTC-8, HOLDS, small): only `Actor.reach`
  (`actor.dart:22`) is both save-reachable (`actor_codec.dart:104`) and
  assert-only (vanishes in release). The five `Spell` asserts are
  content-side, not save-reachable.
- Engine boundary (HOLDS): three unguarded `step(` call sites —
  `game_bloc.dart:836` (`_act`), `:866` (`_onAutoWalkAdvanced`), `:885`
  (`_afterAction`). A throw propagates as a bloc exception. The refusal
  pattern to reuse: `ActionRefused(reason: …)` events (`event.dart:212`,
  built by `_refusedBy` at `step.dart:501`); `step`'s signature has NO error
  channel — the event list is the only one.

### IoSaveFiles (HOLDS; one-param fix unlocks tests)

- Four methods over three slots (`save.json`, `save-previous.json`,
  `save.json.tmp`); implements the `SaveFiles` abstract interface
  (`save_files.dart:18–31`). 0/21 lines covered; the only platform-plugin
  call is `getApplicationDocumentsDirectory()` fetched internally
  (`_home ??= ...`, private, not injectable). One optional constructor
  parameter makes a `Directory.systemTemp` test possible under plain
  `dart test`.
- Unspecified contract per method: `read` maps `FileSystemException` → null
  (conflating corrupt with absent) but lets `_path` throws escape; `write`
  catches nothing; `rename` no-ops on missing source but lets a locked
  target throw; `delete` no-ops when absent. Rename-over-existing replaces
  the target on POSIX (undocumented).

### Door reentrancy (HOLDS)

- `_openAnswer` (`main.dart:342–351`): adds the door event, then awaits
  `_town.stream.firstWhere((state) => state.run != null)` — no in-flight
  guard, no timeout, no subscription cancel on unmount, and `_town.state
  .run!` can null-throw on a race.
- `_onResumeCrawl` (`town_bloc.dart:518–531`) returns silently on an overrun
  or missing camp — the `firstWhere` then completes on the NEXT unrelated
  `run != null` emission with stale arguments. The refusal notice has a home
  (`TownViewState.notice` via `_noticed`) but no `TownRefusal` variant for
  resume refusal exists yet.
- Door buttons (`world_screen.dart:364–411`) never disable while a push is
  pending — double-tap dispatches two openings. All four entry paths funnel
  through `_openAnswer`.
- Tests: `suspend_door_test.dart` (20 testWidgets) covers door offering and
  dialogs; NOTHING tests double-press or a refused resume from the UI.

### TownViewState rider (measurement says: do not ride)

- 9 hand-built constructor sites in `town_bloc.dart` (`_opening` L410,
  `_onEnterDungeon` L427, `_onRunEnded` L462, `_onRunSuspended` L497,
  `_onResumeCrawl` L521, `_onDelveAnew` L552, `_onArrivedInTown` L617,
  `_noticed` L770, `_settled` L805); no `copyWith` exists anywhere in the
  package; readers reach into all four fields from `world_screen.dart`,
  `autosaver.dart:157–160`, `main.dart`, `boot.dart`.
- ~204 test lines across 8 test files assert on `.run`/`.suspended`/
  `.campDay`/`.dungeon`.
- A sealed value must preserve the run-XOR-suspended distinction (the
  `_opening` dartdoc at L252–263) and the `SavedHero` document invariants —
  this is a design task, not a mechanical fold. Honest estimate: a focused
  unit of its own.
- The uncaught-async-error chain is real (`SavedHero` ArgumentError inside
  `saveNow`'s frame, called from stream-listen callbacks, `autosaver.dart:
  85–87, 115`), but the engine-boundary + queue-sink work in THIS unit
  removes the thrown path it rides on; the sealed-value collapse is
  orthogonal hardening.

### Test-hygiene riders (both confirmed)

- TTC-9: `save_codec_test.dart:254–275` "nothing throws past the codec" —
  all 12 fixtures carry `"version": 2` and stop at the version gate before
  any field decoder runs. The totality test never reaches a deep decoder.
- TTC-7: `save_read_test.dart` (3 tests) never exercises `SavedHero`'s two
  constructor throws (`save_read.dart:46–58`).

### Golden impact (critical constraint — clear)

All golden values pass every proposed check: hero speed 10, energy 100
(= actThreshold), hp 13/20; ghoul 5/12, speed 10, energy 40; ids all
distinct per document; skill levels ≤ 3, xp ≤ 4. No check proposed here
moves a pinned document or a band line.

## Findings that change the spec (vs. the audit's remedy list)

1. DROP the item-id uniqueness check — it contradicts the shipped
   m3-itemids duplicate-tolerance ruling.
2. RE-PRICE the energy cap from "hang fix" to defense-in-depth against
   unbounded schedule work; `speed ≥ 1` is the engine-lethal check.
3. The notice channel is a plain `String?` on state (no sealed type) — the
   write-failure remedy threads strings into `TownViewState.notice` /
   boot notices, or introduces the epic's first sealed notice type. Fork for
   the user.
4. IoSaveFiles tests need a one-parameter injectable base directory first.
5. The TownViewState rider does not ride — recommend its own small unit
   (D102's fallback branch).
6. `main.dart:_rosterChose` is the concrete "refuse-to-advance" site the
   audit's create-hero remedy names.

## Proposed shape of the work

One unit, `m3-save-hardening`, branch `m3-save-hardening`, app+content
packages only (core untouched — `step()` already throws correctly; the
boundary guard is app-side). Work pieces:

1. **Write path:** renames inside `save()`'s failure handling; an error sink
   on the Autosaver queue (one failure cannot poison the chain, surfaces a
   notice); the discarded bool consumed at `boot.dart` call sites and
   `_rosterChose` (refuse-to-advance on a failed create/switch).
2. **Boot guard:** guard `main()`'s boot with a real failure screen (the
   app's first); thrown reads treated as unreadable slots so the
   current→previous fallback chain runs; `_path` throws mapped.
3. **Decode validation (content, SaveMalformed style):** speed ≥ 1; hp ≤
   maxHp; skill level/xp ranges (0..maxSkillLevel); Actor.reach as a real
   check (not assert); energy bound (defense-in-depth). No version bump; no
   golden movement (verified above).
4. **Engine boundary:** wrap the three `step(` sites so ArgumentError
   becomes an `ActionRefused` sentence.
5. **IoSaveFiles:** injectable base dir + temp-dir test suite (absent file,
   unreadable file, rename over existing, rename of absent source, write
   failure), contract documented on the interface.
6. **Door reentrancy:** in-flight guard on `_openAnswer`, refusing resume
   emits a notice, buttons disable while pending.
7. **Test-hygiene riders:** deep-decoder totality fixtures (TTC-9);
   `SavedHero` invariant tests (TTC-7).

## Hazards to carry into the spec

- Save format stays v3; m3-quests brings v4. This unit must NOT bump the
  version or move any golden/band.
- The codec's "never repairs, refuses with a sentence" doctrine — new checks
  throw `SaveMalformed`, never clamp.
- Refusal fixtures as their own commit BEFORE any codec change (house
  method).
- Characterization tests must pass against the UNMODIFIED code (e.g. the
  current silent-refusal door behaviour, the queue-poison reproduction).
- Widget traps: `find.textContaining` case-sensitive;
  `scrollUntilVisible` one-way; size one test like a phone.
- No root pubspec — suites per package directory.
- Deuteranomalous author: the failure screen reads by word/shape, never hue.

## What this recon did NOT check

- The reproduce-on-device side of boot failure (a real
  MissingPlatformDirectoryException was not staged on the AVD).
- Whether `rename-over-existing` throws on any platform used in the wild
  (POSIX-only read of `File.rename` semantics).
- Whether any OTHER unguarded async error paths exist beyond the ones the
  audit named (recon scoped to group 1).
- The chore-unit items (CI, analyzer, lockfiles, README) — deliberately out
  of scope.
- The `_town.state.run!` race in `_openAnswer` was read statically, not
  reproduced.