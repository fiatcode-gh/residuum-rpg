# M3SH — Save pipeline stops failing silently — Implementation Plan

> Execute task by task in the worker session (flow-ldd build session; the
> plan stays UNCOMMITTED — the architect commits it when the PR opens).

**Goal:** every path that today fails silently in the save pipeline ends in a
word the player can read; the decoder refuses engine-lethal and rule-breaking
values; the door cannot double-fire; the crawl state becomes one sealed value.

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-save-hardening-spec-M3SH.md`
**Build prompt:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-save-hardening-build-prompt.md`
**Mailbox:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-save-hardening`

## Global constraints

- Save format stays **v3**. No version bump, no field added, no golden
  document or band line moves. Goldens: crypt 16/40 (40.0% BY RULING),
  casting 40/40 (informational), greedy 16 / fleetfoot 13, sea-cave 26/40,
  keep 24/40.
- The codec never repairs or clamps — every new check throws `SaveMalformed`
  with a read-aloud sentence in the house voice ("the save file has …"),
  caught by `decodeSave` into `SaveFailure(reason)`.
- Refusal fixtures are their OWN COMMIT before the codec change; the codec
  commit quotes the refusal sentences.
- Characterization tests pass against UNMODIFIED `d2b78be` first, then flip.
- Suites run per package directory (`cd packages/<pkg> && flutter test`); no
  root pubspec. `dart analyze .` + format from the WORKTREE ROOT.
- Git as `cd <worktree> && git <cmd>`; never `git -C`. Never commit anything
  under `docs/epic/` or `docs/reports/`; the plan doc stays uncommitted.
- No changes to core `step`'s signature; no new `Random(` anywhere; no
  uninstall/install on any device without the save copy-aside ritual.
- No pushing, no PR, no external writes — the architect handles those.
- Deuteranomalous author: state by word/shape/position, never hue alone.
- Pre-declared deviations P1–P8 (mailbox worker entry 1) gate their pieces:
  P1 gear-inclusive hp ceiling; P2 `Boot?` from the roster boot functions;
  P3 autosaver rewire on failed roster save; P4 `SaveNotice` with four
  variants; P5 `TownCrawl?` sealed crawl value; P6 door guard ignores a
  second event; P7 `MemorySaveFiles.throwReadsTo`; P8 `guardedBoot` +
  `BootFailureScreen` in main.dart.

## Baseline (measured fresh on d2b78be)

core 835, content 550, app 589 — 1974 green.

---

## Phase A — Characterizations (green on unmodified d2b78be)

### Task 1: The queue-poison characterization

**Files:** `packages/app/test/autosaver_poison_test.dart` (new).

Real `Autosaver` + real `SaveStore` over a `MemorySaveFiles` whose
`failWritesTo = {currentSlot}` only on the FIRST write (a subclass fake that
fails once — the injection style is the fake's own: a map-backed fake with a
one-shot failure, not a mock). `watchTown` a real `TownBloc`; fire two town
emissions; assert `settled()` completes and the second save never reached the
disk — the poison, stated as it behaves TODAY.

```dart
test('a failed save poisons the queue; later saves never run', () async {
  // arrange
  final files = MemorySaveFiles()..failWritesTo.add(currentSlot);
  final store = SaveStore(files);
  final town = TownBloc(profile: standing, town: stonebridge);
  final saver = Autosaver(store, from: Boot(document: roster));
  saver.watchTown(town);
  // act
  town.add(const RestPressed());
  town.add(const RestPressed());
  await saver.settled();
  // assert — today: the first save threw out of the queue chain, so the
  // second write never happened and the pending file is absent.
  expect(files.contents[pendingSlot], isNull);
  expect(files.contents[currentSlot], isNull);
});
```

Run green against `d2b78be`. Commit `test: M3SH characterize the autosaver queue poison`.

### Task 2: The thrown-read characterization

**Files:** `packages/app/test/save_store_test.dart` (extend), `packages/app/test/support/memory_save_files.dart` (extend with `throwReadsTo` — P7, one `Set<String>`; `read` throws `StateError` when named).

```dart
test('a thrown read escapes load() today; the fallback never runs', () async {
  // arrange
  final files = MemorySaveFiles()..throwReadsTo.add(currentSlot);
  files.contents[previousSlot] = encodeSave(previousDocument);
  final store = SaveStore(files);
  // act
  final loaded = await store.load(); // today: THROWS
  // assert (written as the flip target; commented until the fix lands)
});
```

The green-on-d2b78be form asserts the throw:

```dart
await expectLater(store.load(), throwsStateError);
```

Run green (it throws today). The fix commit flips it to "previous slot
consulted". Commit `test: M3SH characterize the thrown-read fallback bypass`.

### Task 3: The door silent-refusal characterization

**Files:** `packages/app/test/widget/door_reentrancy_test.dart` (new).

PumpedApp with a camped hero whose camp is overrun on the world's day
(`campDay` old). Dispatch `ResumeCrawlPressed` through the real app path
(`_resumeCrawl` → `_openAnswer`): tap the resume door. Today
`_onResumeCrawl` returns silently (no emission) → `_openAnswer`'s
`firstWhere((s) => s.run != null)` stays pending. Complete it with a LATER
unrelated emission (`ArrivedInTown` — the hero walks home again) and assert
`_openCrawl` fired with the stale resume (a second `GameScreen` route pushed
that no press asked for). This is the reproduction attempt (spec-attack 4):
if the route observation can't be made deterministic, pin the pending-await
by `tester.pump` + the later emission completing it.

Commit `test: M3SH characterize the door's silent refusal`.

### Task 4: The speed-0 decode characterization

**Files:** `packages/content/test/save/save_codec_test.dart` (extend).

A minimal v3 document whose hero actor carries `"speed": 0` — assert
`decodeSave` returns a `SaveDocument` (decodes fine today). This test is
REWRITTEN in the refusal-fixture commit to expect the refusal sentence, and
goes green in the codec commit.

Commit `test: M3SH characterize that speed 0 decodes today`.

---

## Phase B — Refusal fixtures (own commit, RED, named)

### Task 5: Deep-decoder refusal fixtures (TTC-9) — RED

**Files:** `packages/content/test/save/save_codec_test.dart` (extend).

Version-gated v3 fixtures that reach the deep decoders, one per new check,
each asserting the exact refusal sentence (sentences final at build time;
the codec commit quotes them):

- speed 0 → "the save file has an actor with speed 0, and the clock would
  never move them"
- energy 1001 → "the save file has an actor holding 1001 energy, and no real
  fight leaves one holding more than 1000"
- energy −1 → same bound sentence shape
- run hero hp 27 with +6-maxHp gear absent → ceiling sentence (P1 shape)
- profile hp 21 with no gear → "the save file has a hero standing at more
  hit points than they can hold"
- skill level 101 → "the save file has a skill trained past its highest
  level: 101"
- skill xp −1 → "the save file has a skill holding less than no experience"
- reach 0 → "the save file has an actor that cannot reach anything"
- repeated pack id (inventory twice) → "the save file has two items named
  "kit-2""
- repeated id across bank and inventory (scope proof)
- one fully valid v3 document decoding clean (the totality control)

Run: named reds = the refusal tests + the valid-document control stays green.
Band suite + goldens: green (controls). Commit (RED by design, named in the
message) `test: M3SH refusal fixtures for the deep decoders (red)`.

---

## Phase C — Codec (green, quotes the sentences)

### Task 6: core constant + actor checks

**Files:** `packages/core/lib/src/engine/energy.dart`,
`packages/core/lib/src/loot/item.dart` (dartdoc only),
`packages/content/lib/src/save/actor_codec.dart`,
`packages/content/test/save/actor_codec_test.dart` (if unit tests wanted).

- `energy.dart`: `const int maxSaveEnergy = 1000;` beside
  `actThreshold`/`actCost`, dartdoc carrying the arithmetic (E/actCost worst
  case; 1000 = 10× actThreshold; NOT the hang fix — speed ≥ 1 is).
- `actor_codec.dart` `decodeActor`: after reading the fields —
  `speed >= 1`, `energy >= 0 && energy <= maxSaveEnergy`,
  `hp >= 0`, `reach >= 1`; `hp <= maxHp` ONLY for non-hero actors; the hero
  actor's ceiling is checked with the run block's equipment (P1) — so the
  hero check lives in `run_codec.dart`'s run decode where equipment and hero
  meet. Never clamps.
- `item.dart:275–281`: rewrite the duplicate-tolerance dartdoc to the D108
  amended ruling (decode refuses duplicates; remove-one stays for ids unique
  by construction).

Commit `feat: M3SH the codec refuses engine-lethal and rule-breaking actors`.

### Task 7: item/profile checks

**Files:** `packages/content/lib/src/save/item_codec.dart`,
`packages/content/lib/src/save/profile_codec.dart`,
`packages/content/lib/src/save/run_codec.dart` (hero-ceiling home),
`packages/content/test/save/item_codec_test.dart`,
`packages/content/test/save/profile_codec_test.dart` (if needed).

- `_skillFrom`: `0 ≤ level ≤ maxSkillLevel`, `xp ≥ 0`, sentences naming the
  skill.
- Item-id uniqueness (D108): per hero — profile equipment + inventory + bank
  pairwise distinct; run equipment + inventory pairwise distinct; litter and
  merchant stock never compared (dartdoc states the scope). Sentence names
  the repeated id.
- Profile: `hp ≥ 0`; `hp ≤ heroMaxHp(rebuilt hero, decoded equipment)` —
  computed after equipment decodes (P1). Sentence in the house voice.
- Run hero: `hp ≥ 0`; `hp ≤ heroMaxHp(hero, run equipment)`.

Run content suite: all fixtures green; goldens + bands byte-identical.
Commit `feat: M3SH the codec refuses out-of-range skills, repeated item ids, and impossible hit points`.

---

## Phase D — App

### Task 8: SaveStore — renames inside the failure handling; thrown reads (M5, M9)

**Files:** `packages/app/lib/save/save_store.dart`,
`packages/app/lib/save/save_files.dart`,
`packages/app/test/save_store_test.dart`.

- `save()`: the try covers write, read-back verify, and BOTH renames; any
  failure forgets the pending slot and returns false. Dartdoc keeps its
  "answering whether the save landed" truth.
- `_readable`: try around `_files.read` — a thrown read is an unreadable slot
  (P7-tested via `throwReadsTo`); the flip test from Task 2 lands here.
- `save_files.dart` interface dartdoc: read never throws; write/rename/delete
  throw on failure after their documented no-ops.

Tests: rename-throw on `save()` returns false and leaves both slots; thrown
read falls back to previous; returned-null fallback still green (control).
Mutation M5 runs on the working tree here (move renames back outside, watch
the rename-throw test redden, revert). Commit
`feat: M3SH the save store treats every failure as "the save did not land"`.

### Task 9: Autosaver queue error sink (M6)

**Files:** `packages/app/lib/save/autosaver.dart`,
`packages/app/test/autosaver_poison_test.dart` (flip).

- `saveNow` chains with an error sink: one failing save emits the
  save-write-failure notice ONCE per streak (first failure; the streak ends
  at the first success) and the queue stays alive; `settled()`/`close()`
  never reject. The notice rides `SaveNotice.saveWriteFailed` through an
  injected sink (the town event it becomes lands in Task 10; the sink is
  `void Function(SaveNotice)` on the constructor, wired by `_SessionState`).
- The poison test flips: later saves run, exactly one notice.
- Ordering + no-op emission tests stay green (controls).

Commit `feat: M3SH one failing save no longer poisons the autosaver queue`.

### Task 10: Sealed notice type (P4) + notice channel

**Files:** `packages/app/lib/notice/notice.dart` (new),
`packages/app/test/notice/notice_test.dart` (new),
`packages/app/lib/town/town_bloc.dart`, `packages/app/lib/world/world_bloc.dart`,
`packages/app/lib/town/town_style.dart`,
`packages/app/lib/save/boot.dart`, `packages/app/lib/save/autosaver.dart` (bridge).

- `sealed class SaveNotice` with `load`, `saveWriteFailed`, `resumeRefused`,
  `refused` — each carrying a `sentence`. Tests: equality, exhaustive switch
  renders.
- `TownViewState.notice` / `WorldViewState.notice` / `Boot.notice` become
  `SaveNotice?`; `_noticed`/`_settled` wrap; the `Notice` widget
  pattern-matches and renders `— sentence.` (same grammar).
- Autosaver→town bridge: a new `TownBlocEvent` (`SaveWriteFailedNotice`)
  handled onto the notice field, so a save-write failure is readable in town;
  the streak logic from Task 9 feeds it exactly once per streak.

Commit `feat: M3SH the notice channel becomes a sealed SaveNotice`.

### Task 11: boot.dart failure channels (P2)

**Files:** `packages/app/lib/save/boot.dart`, `packages/app/test/boot_test.dart`.

- `createHero`/`switchHero`/`replaceOnlyHero` return `Boot?` — null when the
  save did not land. `bootFrom` composes the load report with a failed
  fresh-save notice. `deleteHero` unchanged (its null is the roster's rule).
- Tests: failed create → null; failed switch → null; failed fresh boot →
  Boot with the notice; happy paths green (controls).

Commit `feat: M3SH the boot functions answer whether the save landed`.

### Task 12: main.dart — guarded boot, failure screen, roster refusal, door guard (P3, P6, P8; M7, M8, M11)

**Files:** `packages/app/lib/main.dart`,
`packages/app/test/widget/boot_failure_screen_test.dart` (new),
`packages/app/test/widget/roster_refusal_test.dart` (new),
`packages/app/test/widget/door_reentrancy_test.dart` (extend).

- `guardedBoot(store, rollWorldSeed)` — try the boot path, return
  `ResiduumApp` or `BootFailureScreen`; `main()` awaits it. The screen: one
  sentence naming what failed (fixed safe wording), one **Begin fresh**
  action re-running the guarded boot; a second throw re-renders. Greyscale
  by word.
- `_rosterChose` returns the `Boot?`; on null — rewire the autosaver
  (P3), re-push the roster with the notice sentence; on success — rebuild
  as today. Widget tests: refused create keeps the session and shows the
  notice; refused switch ditto; happy paths green (controls; M7's red).
- `_openAnswer`: in-flight guard (second event ignored), wait on
  `run != null || notice != null`, subscription cancelled on unmount.
  Tests: double-tap pushes one crawl (M11); happy single-open green.
- Boot-time save failure (fresh install) keeps booting with the notice.

Commit `feat: M3SH boot fails onto a screen and the roster refuses to advance on a lost save`.

### Task 13: Engine boundary (M10)

**Files:** `packages/app/lib/game/game_bloc.dart`,
`packages/app/test/game/engine_boundary_test.dart` (new).

The three `step(` sites (`_act`, `_onAutoWalkAdvanced`, `_afterAction`) catch
`ArgumentError`, emit an `ActionRefused` with the fixed safe sentence
("the dungeon refused that; nothing happened"), and do not apply the action.
Test: a state whose next action throws ArgumentError (built by hand) → the
bloc emits the refusal into the log and the state is unchanged. Normal
action tests stay green. Commit
`feat: M3SH an engine ArgumentError becomes a refusal, not a crash`.

### Task 14: IoSaveFiles (M13)

**Files:** `packages/app/lib/save/save_files_io.dart`,
`packages/app/test/save/save_files_io_test.dart` (new).

- `IoSaveFiles([Directory? home])`; null fetches from path_provider as
  today. `read` maps EVERY failure (including
  `MissingPlatformDirectoryException`) to null; the exception contract sits
  on the interface dartdoc (Task 8 already wrote it).
- Temp-directory suite: absent file reads null; unreadable file reads null;
  write-then-read round-trips; rename over an existing target replaces it;
  rename of an absent source no-ops; write failure propagates; delete absent
  no-ops. Commit
`feat: M3SH IoSaveFiles takes its directory and maps every read failure to null`.

### Task 15: Door buttons disable while pending

**Files:** `packages/app/lib/world/world_screen.dart`,
`packages/app/test/widget/door_reentry_button_test.dart` (new).

The door buttons carry the pending state by word/shape (disabled + the label
dimmed — greyscale-safe). Test: press resume, before settle the buttons are
disabled; settle re-enables. Commit
`feat: M3SH the door buttons disable while an opening is pending`.

### Task 16: TownCrawl sealed value (P5; M14)

**Files:** `packages/app/lib/town/town_crawl.dart` (new),
`packages/app/lib/town/town_bloc.dart`,
`packages/app/lib/save/autosaver.dart` (bridge),
`packages/app/test/town/town_crawl_carry_test.dart` (new),
test files updated where they hand-build the four fields.

- `sealed class TownCrawl` with `CrawlOpening(run, dungeon)` and
  `CampStanding(crawl, dungeon, campDay)`; `TownCrawl?` is "none". Dartdoc:
  the run is an instruction, not a fact; the run-XOR-suspended rule is now
  the type.
- The 9 construction sites rewritten; the four named getters remain derived;
  the autosaver bridge reads the sealed value.
- Table-driven test: EVERY town handler preserves an arriving camp — one
  table row per handler event, all asserting the camp survives.
- Mutation M14: collapse the camp variant on the working tree, watch the
  carry test redden, revert. Commit
`refactor: M3SH the town's four crawl fields become one sealed value`.

### Task 17: TTC-7 — SavedHero invariant tests

**Files:** `packages/content/test/save/save_read_test.dart` (extend).

Both constructor invariants red-without/green-with: run-without-dungeon and
dungeon-without-run throw; campDay-without-camp and camp-without-campDay
throw; legal shapes stand. Commit
`test: M3SH pin SavedHero's two pairing invariants`.

---

## Phase D — Evidence

### Task 18: Mutation table, analyze, format

- All 14 rows: named red sets AND green controls, both halves reported.
  M1–M4 at fixture time (already reported); M5, M14 on the working tree with
  revert; the rest delete the landed code temporarily and re-run the named
  tests + controls.
- `dart analyze .` + `dart format --set-exit-if-changed .` from the worktree
  root (pwd quoted).
- Per-package suites: new counts from result files.

### Task 19: AVD pass

- Copy BOTH save slots aside (run-as cat) + checksums BEFORE any install;
  emulator-5554 only; check free space.
- Shots: failure screen with Begin fresh; a save-failure notice; a
  resume-refusal notice; disabled door buttons while pending — each with its
  greyscale variant, saved under /tmp.
- Staged failures: a poisoned store (injected failure) for the save notice;
  an overrun camp for the resume refusal; double-tap for the disabled state;
  boot failure staged via a store whose read throws.

### Task 20: REPORT.md mirror + final mailbox entry

Verification block mirrored to
`docs/epic/handoff/m3-save-hardening/REPORT.md` (never committed), final
`worker.md` entry with the full evidence list.