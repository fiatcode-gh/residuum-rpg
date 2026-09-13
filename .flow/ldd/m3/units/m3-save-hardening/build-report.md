# M3SH — build report (worker mirror)

The unit is complete: 14 commits on `m3-save-hardening`
(`d2b78be..44c85cd`), all three suites green, the full mutation table run,
the AVD pass done with the save ritual honoured both directions. This file
mirrors the evidence; the mailbox holds the running narrative.

## 1. Proof of place

- `pwd` names `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-save-hardening`.
- `git rev-parse --show-toplevel` names the same worktree — no commit landed
  in the parent repo.
- `git log --oneline d2b78be..HEAD` (14 commits):
  3157225 characterize today's silent failures · 5bc32e8 refusal fixtures
  (red) · bd4eba6 the codec refuses · c9de157 the store · 3cb6e93
  IoSaveFiles · c165ba1 the boot functions answer · a398c9c the sealed
  values · 4dfa0a9 the doors stand down · 686a1e2 the engine boundary ·
  a7fbbe2 failure screen + refusing roster tests · 677f381 camp carry +
  SavedHero pairings · e4081ce the boundary test measures its premise ·
  44c85cd the town's notice reads at the doors it answers.
- `git log d2b78be..HEAD -- docs/` is EMPTY — nothing under `docs/` was
  committed. The plan doc (`docs/plans/2026-09-03-m3-save-hardening.md`)
  is UNCOMMITTED, as instructed.

## 2. Counts (final, from result files; baseline measured fresh at kickoff)

- core: **835** passed (baseline 835).
- content: **573** passed (baseline 550; +14 refusal fixtures +1 speed
  characterization +6 SavedHero pairings +1 premise test − net as shown).
- app: **637** passed (baseline 589).
- Baseline was measured fresh on unmodified `d2b78be` at session start
  (1974 green; matched the architect's count).

## 3. Characterizations (green on unmodified `d2b78be`, commit 3157225)

- Queue poison: `MemorySaveFiles.failRenamesFrom` + a real `Autosaver` —
  the rename throw escaped the queue chain; the second queued save never
  ran; `settled()`/`close()` rejected. Pinned, then flipped by the fix.
- Thrown-read bypass: `MemorySaveFiles.throwReadsTo` — the throw escaped
  `load()` and the previous slot was never consulted. Flipped.
- Door double-fire: two raw taps before the first emission → TWO
  GameScreens — reproduced at the widget level, no longer only verified
  statically. Flipped (one crawl).
- Speed 0 decodes today → flipped in the refusal-fixture commit.

## 4. The refusal fixtures precede the codec change

`5bc32e8 test: M3SH refusal fixtures for the deep decoders — red` (14
named reds, quoted sentences in the message) precedes
`bd4eba6 feat: M3SH the codec refuses engine-lethal and rule-breaking
values` (the commit that quotes the refusal sentences). `git log`
ordering is the proof; the reds were reported at fixture time in the
run output and the commit message.

## 5. The mutation table — every row, reds AND greens

| Row | Named reds observed | Green controls observed |
|---|---|---|
| M1 speed check deleted | 'a hero at speed zero…' + 'a monster at speed zero…' | goldens (7), band suite |
| M2 id-uniqueness deleted | 'two pack items…' + 'an id repeated across the bank…' | goldens; 24 remove-one/duplicate-id tests (core) |
| M3 hp checks deleted | 'a monster holding more…', 'a hero holding more…', '…one over their gear…', 'a profile above its ceiling…', 'an actor at negative hit points…' | 'a hero holding what their gear allows' + profile control; goldens; band suite |
| M4 level ranges deleted | 'a skill past the highest level…' + 'a skill holding negative experience…' | goldens |
| M5 renames moved back out (working tree, before the piece landed, reverted after) | 'a rename the disk refuses answers false' + both thrown-read tests | 15 verify-then-rotate / returned-null controls |
| M6 queue error sink deleted | 'a failing save is survived…' + 'a save that lands ends the streak…' | 23 ordering tests + the no-sink quiet test |
| M7 _rosterChose ignores the bool | all three refusal tests | 23 happy-path roster/session tests |
| M8 boot guard try deleted | both failure-screen tests | 30 boot happy-path tests |
| M9 _readable reverted to no try | both thrown-read tests | 15 returned-null fallback controls |
| M10 step-boundary catch deleted | the bloc refusal test | the premise test (direct step throws) + 120 normal action tests |
| M11 door in-flight guard deleted | 'a double tap opens the crawl once' | 20 suspend-door tests |
| M12 resume-refusal emit deleted | 'a camp three days old is overrun…' + 'resuming a crawl nobody camped in…' | 3 door reentry tests (happy resume) |
| M13 IoSaveFiles.read throws again | 'an unreadable slot reads null' | 8 remaining temp-dir tests; 44 store-level tests (they run on the fake) |
| M14 camp carry collapsed | 14 of 15 table rows | 20 suspend-door + 26 boot tests (legal shapes) |

## 6. Goldens and bands

- `git diff d2b78be HEAD -- packages/content/test/save/golden_save_test.dart`
  is EMPTY — all three golden documents byte-identical.
- Band lines verbatim from this unit's own content-suite run:
  - `survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16` (crypt — 40.0% BY RULING)
  - `casting build: 40/40 won` (informational)
  - `greedy build: 16/40 won; fleetfoot-first build: 13/40 won`
  - `sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5`
  - `sea-cave 26/40 vs ruined keep 24/40`

## 7. Analyze and format

- `dart analyze .` from the worktree root (pwd above): **No issues found!**
- `dart format --set-exit-if-changed .`: 229 files, **0 changed**, exit 0.

## 8. What the tests cannot prove — stated plainly

- **The disabled door buttons are not photographable on device.** The
  press→answer window closes inside one frame cycle; a `--bugreport`
  screenrecord at 217 frames shows no frame where the disabled state is
  painted. The behavior is pinned by the widget tests (the doors stand
  down on press, clear on the town stream) and by M11's named red; the
  on-device visibility claim is withdrawn — on a fast device the player
  likely never sees the disabled state either, and the guard is the real
  protection.
- **Real path_provider failure behavior was not staged on the AVD.** The
  failure screen was reached with a forced-throw staging build (temporary,
  uncommitted hooks: one forced `guardedBoot` throw for the failure-shot
  build; one inverted resume gate for the refusal-shot build). Both
  staging builds were rebuilt and reverted; the committed tree contains no
  staging code (`git status` clean).
- The resume-refusal notice is only reachable from the UI in the timing
  race (the screen refuses to offer a resume on an overrun camp); the
  device shot used the staging gate. The bloc-level path is pinned by
  tests; the on-device race reachability remains statically argued, as
  the audit left it.
- The store-side `_readable` guard is defense-in-depth: with the adapter
  mapping every failure to null, no production path throws from `read`.
  The P7 ruling (dispatcher entry 1) stands: the guard is tested via the
  throwing fake.

## 9. Spec claims checked and found wrong

- **The spec's blanket `hp ≤ maxHp` would have refused legal saves.** Gear
  lifts the hero's ceiling above its body (`heroMaxHp` = baseline + worn
  maxHp affixes; `affix_pool.dart` carries `maxHp: 6`; an inn night heals
  to exactly that ceiling). Pre-declared as P1, dispatcher-acked (entry 1),
  and promoted to the ledger by the architect. The landed check is
  three-part: monsters plain, run-hero and profile gear-inclusive.
- **The spec's "exactly three variants" needed the generic sentence
  variant** (its own text offered it); the variant is named
  `SentenceNotice`, not `RefusedNotice`, because the forge's level-up
  announcement rides the same channel. Accepted (dispatcher entry 3).
- **The TownViewState rider's "dungeon without a crawl" shape was load
  bearing in the old model only for the inside-boot suspend** —
  `RunSuspended` now carries the dungeon on the press and the town never
  holds a crawlless dungeon. Within P5's acked shape.
- **The resume-refusal notice had no visible surface**: it lands on the
  town state while the door lives on the world screen, which rendered only
  the world's notice. Found by the AVD pass; fixed in 44c85cd (the door
  column renders the town's notice).

## 10. Execution phases

All ran: plan (uncommitted doc), characterizations (green on `d2b78be`),
refusal fixtures (red, own commit), build (test-first per piece), the full
mutation sweep (all 14 rows, above), and the AVD pass (below). Nothing was
skipped. Read-only subagents were not needed — the work was done in this
session per the build prompt's worker rule (never a writer).

## 11. AVD pass evidence

Emulator `Pixel_10` pinned to `emulator-5554`; no phone attached at any
point (`adb devices` showed exactly one device). `flutter build apk
--debug` → `adb install` (one storage round-trip: the first install failed
`INSTALL_FAILED_INSUFFICIENT_STORAGE`; the old build was uninstalled only
after both slots were verified copied aside; a second storage failure was
cleared by an emulator reboot, after which the install succeeded).

- **Save ritual, both directions:** BEFORE any install both slots copied
  aside via `run-as … cat` — `save.json` 7440 B md5 `8affb33b8becd2fb877b774a20cc916d`,
  `save-previous.json` 7442 B md5 `89de2d363594b40095a8342f6971be3f`,
  matching the on-device md5s and the m3-dock unit's recorded values.
  AFTER the drive, both slots restored the same way; on-device md5s after
  restore byte-identical, and the app relaunched into the real playtest
  crawl (Wounded 7/20, The Crypt depth 2/5, `The crawl resumes.`).
- **Shots under `/tmp/m3sh-avd/`** (each with a `magick -colorspace Gray`
  greyscale variant):
  - `shot-failure-screen.png` (+`-grey`): the failure screen on a phone —
    'The crawl is unreachable.', 'the game could not start from your
    save', one **Begin fresh** action; reached with a forced-throw
    staging build (disclosed above).
  - `shot-resume-refused.png` (+`-grey`): '— the camp at the crypt has
    been taken back by the residue.' rendered AT the doors (the 44c85cd
    surface), the camp door still standing; reached with a staging gate
    refusing every resume (disclosed above).
  - `shot-save-failed2.png` (+`-grey`): '— the new hero could not be
    saved; nothing was lost.' on the town screen, staged with a REAL
    failure injection: both slot names replaced by directories, so every
    rotate fails through the app's own pipeline (no code hook). The
    fresh-boot save failed and the notice carried onto the town state.
  - The disabled-door-buttons shot: NOT CAPTURED — see section 8. The
    pending window does not paint on device.
- **Acceptance drive notes:** the codec accepted the real playtest save
  whole (all new checks pass on real data); a hand-staged camped variant
  (the playtest save with `inside: false`, `campDay: 1` set) drove the
  door and refusal screens. The directory trick is real disk state, not
  an app change.

## 12. Pre-declared deviations

P1–P8 as pre-declared (worker entry 1) and acked (dispatcher entry 2),
plus the in-flight naming note (P4's fourth variant → `SentenceNotice`,
dispatcher entry 3). Two further deviations surfaced mid-build and are
disclosed in this report rather than held: `RunSuspended` now carries the
dungeon (the crawlless-dungeon shape is gone), and the town's notice
renders at the world screen's doors (44c85cd). No other deviations.

## 13. Follow-ups logged (not this unit's work)

- The disabled-door state may be worth a longer-lived visual mark if a
  future unit ever makes the door answer asynchronous beyond one frame.
- The AVD /data sits at ~89% after the pass; the next unit's install will
  need the same uninstall dance.