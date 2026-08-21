# Build report — unit `m3-saves`, story M3S "Saves"

Build session, 2026-08-21. Branch `m3-saves`, base `0656eb1`.
Spec: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-saves-spec-M3S.md`
Plan: `docs/superpowers/plans/2026-08-21-m3s-saves.md` (committed)

**Headline for the architect. The unit does what it exists to do: force-stop
mid-fight on the AVD, relaunch, and the same fight continues on the same rolls —
verified twice from the same document, byte-identical outcomes. Survivability is
untouched at exactly 24/40, stalled 0. `packages/core` diff is empty.**

**Addendum 1, after the architect's verification pass.** A user-found defect was
fixed on this branch before the PR: the system back button popped the crawl
route with no `RunEnded`, losing a suspended run silently. Two commits
(`41de2e0`, `a92bc79`), app suite 166 → 170, four more mutation rows, and five
more AVD scenarios. Marked **[addendum]** wherever it changed a section below.

**Addendum 2 — the save document holds a roster.** The user chose it while this
unit was closing, and it lands here because the format is being born here: the
document is now `{version, active, heroes: {id: {label, profile, run}}}`, still
version 1 because version 1 never shipped. Shape, codec and wiring only — no
roster screen; create, switch and delete are a follow-up unit. One commit
(`ebe6d4a`), total 745 → **768**, five more mutation rows, three more AVD
checks. Marked **[roster]** wherever it changed a section below.

**Three things you should read before merging.** (1) The spec's mutation row 6
could not have failed as written — 64-bit ints DO survive `dart:convert` on this
platform, proved below; the string format is kept on a corrected argument and
re-armed with a strict decoder. (2) Three real defects were found on the
emulator that no unit test in this architecture could reach, one of them severe:
the autosaver was never attached, so town saves were silently not written at
all. (3) The fallback report was invisible in exactly the case that matters most
— a corrupt save holding a suspended crawl. All three are fixed, with the
reasoning committed.

---

## 1. Worktree and commits

```
$ git rev-parse --show-toplevel
/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-saves

$ git log --oneline main..HEAD
ebe6d4a feat: the save document holds a roster, not a hero
a92bc79 docs: amend the build report with the back-button addition
41de2e0 fix: the system back button is not a door out of the dungeon
794f10b docs: M3S build report and implementation plan
71cff0a fix: three boot defects the unit tests could not reach
a0f5ae0 test: make the autosave stream test able to fail
21a9f9a feat: boot from disk, resume a suspended crawl, autosave every change
b70da98 feat: two save slots, written pending-first and verified before rotating
d30815b feat: the save document — version gate, suspend theorem, golden pins
a6a2fa5 feat: the run codec — a crawl frozen whole, streams and all
0eb0ae5 feat: the profile codec — earned fields, body rebuilt from content
23b34b3 feat: actor and item codecs — whole actors, items by reference
2d5abc3 feat: save field readers that name what is wrong
1cbd72a feat: the save read outcome — a document or a sentence
04e8ab5 feat: registry lookups that answer with nothing instead of throwing
67946d5 test: characterize boot before the save layer exists
```

Nothing under `docs/epic/` is committed. Nothing pushed, no pull request.

## 2. Test counts, re-measured at base by me before the first commit

**I re-measured the baseline myself rather than taking it on trust, as asked.**
At `0656eb1`, clean tree:

```
$ (core)    dart test -r failures-only    →  +395: All tests passed!
$ (content) dart test -r failures-only    →  +95:  All tests passed!
$ (app)     flutter test -r failures-only →  +129: All tests passed!
```

395 + 95 + 129 = **619. Matches the architect's figure exactly.**
Survivability at base: `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24`.

At HEAD:

```
$ (core)    dart test -r failures-only    →  +395: All tests passed!
$ (content) dart test -r failures-only    →  +197: All tests passed!
$ (app)     flutter test -r failures-only →  +176: All tests passed!
```

| Package | Base | HEAD | Change |
|---|---|---|---|
| core | 395 | 395 | 0 — core is untouched |
| content | 95 | 197 | +102 |
| app | 129 | 176 | +49 new, −2 (C1 deleted), −1 (`wipe` removed) |
| **total** | **619** | **768** | **+149** |

**[addendum]** The app figure was 166 before the back-button fix; those four
tests are in `game_bloc_test.dart` under *the system back button*.
**[roster]** Content 180 → 197 (fifteen in `roster_test.dart`, two more golden
pins); app 170 → 176 (two roster autosave tests, five roster boot tests, minus
the `wipe` test that went with the method).

## 3. C1, quoted at base, and the argument for deleting it

Run at base against unmodified code, commit `67946d5`:

```
$ flutter test test/boot_characterization_test.dart
00:01 +1: C1 — boot before there is a save layer every install begins on world seed one
00:01 +2: C1 — boot before there is a save layer boot has no crawl to resume and nothing to report
00:01 +2: All tests passed!
```

The half a bloc-level test cannot reach, quoted by grep at base as you flagged
it might be:

```
$ grep -n "newProfile" packages/app/lib/main.dart
23:      create: (_) => TownBloc(profile: newProfile()),
```

**The argument for deletion.** C1 asserted three things: every install begins on
world seed 1; there is no crawl to resume; there is nothing to report. All three
are now false *by design* — that is the entire story. A characterization whose
every clause the story inverts cannot be weakened into passing without asserting
the opposite of what it was written to pin, so it is deleted and replaced clause
for clause by three named tests in `boot_test.dart`:

| C1 clause | Replacement |
|---|---|
| every install begins on world seed one | *a fresh install rolls its own world and is not seed one* |
| no crawl to resume | *a saved crawl boots with the crawl to resume* |
| nothing to report | *a corrupt save boots the older one and carries the report* |

Deleted in `21a9f9a`, the boot commit, with that argument in the commit message.

## 4. The mutation table — every row, both halves

Every row is one line, applied, run, and reverted; `git diff --stat` was empty
after the last one. **core is never affected by any row** — core does not depend
on content, and no row touches core — so the core column is omitted rather than
repeated as 395 twelve times.

### The spec's rows

| # | Mutation | Content | App | Verdict |
|---|---|---|---|---|
| 1 | `loadRun` seeds fresh from `worldSeed` instead of `Rng.fromState` | **9 red** | **1 red** (after the fix in item 4a) | as spec predicted, plus more |
| 2 | item codec drops the affix list | **13 red** | 0 | as spec predicted, much wider |
| 3 | version check removed | **3 red** | **1 red** | as spec predicted |
| 4 | rotation swapped to rotate-then-write | 0 | **3 red** | as spec predicted |
| 5 | run codec omits `floors` | **5 red** | 0 | as spec predicted |
| 6 | 64-bit fields encoded as JSON numbers | **36 red** | **18 red** | **only because I re-armed it — see item 4b** |
| 7 | `loadRun` bumps visit like `startRun` | **6 red** | **3 red** | as spec predicted |
| 8 | monster energy zeroed in the actor codec | **8 red** | **1 red** | as spec predicted |
| 9 | CONTROL — no mutation | `+180 All tests passed!` · `survivability: 24/40 won (60.0%), stalled 0` · both golden pins green | `+170 All tests passed!` | green — proves rows 1–8 reverted |

Row-by-row test names:

**Row 1** — content: *run codec both streams resume where they stopped*; *run
codec a full-width stream state is written as text and survives exactly*; *the
save document a full-width seed and both stream states survive exactly*; *the
save document a suspended crawl round-trips beside its profile*; *the save
document a run's stream state written as a number is refused*; *the golden save,
crawl suspended the committed document decodes to the pinned crawl*; *the
suspend theorem a resumed crawl plays out exactly as the one it resumed*; *the
suspend theorem a resumed crawl on a revisited floor plays out the same*; *the
suspend theorem a stream restored by seed instead of state would diverge*. App:
*autosaving a crawl every settled step is on disk, streams and all*.

**Row 2** — content: *item codec an affixed item keeps its affixes in order*;
*item codec an item is written as registry references, not copied stats*; *item
codec a pack round-trips in the order it was carried*; *item codec worn gear
round-trips by slot*; *item codec litter round-trips by tile, in a stable
order*; *profile codec a lived-in profile round-trips whole*; *run codec every
plain field of a deep run round-trips*; *run codec every floor left behind comes
back, field for field*; *the golden save, hero in town the encoder reproduces it
byte for byte*; *the golden save, crawl suspended the encoder reproduces it byte
for byte*; all three floor-touching suspend theorem tests. The spec predicted
"affixed round-trip + golden fixture" and the control "plain-item round-trip" —
both correct; *a plain item round-trips* stayed green.

**Row 3** — content: *a version this build does not know is refused by number*;
*a document with no version at all is refused*; *the version is checked before
any other field is touched*. App: *loading a save from a version this build
cannot read falls back*. Control *a hero in town round-trips with no run block*
green, as specced.

**Row 4** — app: *saving a failed write leaves both existing slots exactly as
they were*; *saving a write that cannot be read back does not rotate either*;
*saving a half-written pending file does not rotate either*. Control *saving a
first save lands in the current slot and nowhere else* and *a second save
rotates the first one into the previous slot* both green, as specced.

**Row 5** — content: *run codec every floor left behind comes back, field for
field*; *the save document a suspended crawl round-trips beside its profile*;
*the golden save, crawl suspended the encoder reproduces it byte for byte*; *the
suspend theorem a resumed crawl walks back onto the floor it left, unchanged*;
*the suspend theorem a resumed crawl on a revisited floor plays out the same*.
Control *a single-floor run round-trips with no floors behind it* green, as
specced — the spec called both halves of this row correctly.

**Row 6** — 36 content and 18 app tests. Named in full would be most of the
suite; the shape is that the encoder can no longer read its own output, so every
round-trip, both goldens, all six suspend theorem tests, and every app test that
reads a document back go red. **Read item 4b before crediting this row.**

**Row 7** — content: *run codec resuming does not bump the visit*; *run codec
every plain field of a deep run round-trips*; *run codec the floor builder comes
back, laying out the same next floor*; *run codec the floor builder is laid out
for the run's own visit*; *the golden save, crawl suspended the committed
document decodes to the pinned crawl*; *the suspend theorem a resumed crawl
descends onto the same next floor*. App: *booting a saved crawl boots with the
crawl to resume*; *loading a suspended crawl comes back out of the current
slot*; *autosaving a crawl the profile on disk mid-crawl is the one that walked
in*. Control — the profile's own visit round-trip — green: *profile codec a
lived-in profile round-trips whole* passes, so the two visits are independently
pinned exactly as the spec wanted.

**Row 8** — content: *actor codec a held turn is carried over rather than
zeroed*; *actor codec all twelve fields survive a round trip*; *run codec a
monster's held turn is not zeroed*; *run codec the hero and every monster come
back whole and in order*; *run codec every floor left behind comes back, field
for field*; *the golden save, crawl suspended the encoder reproduces it byte for
byte*; *the suspend theorem a resumed crawl plays out exactly as the one it
resumed*; *the suspend theorem a resumed crawl walks back onto the floor it
left, unchanged*. App: *autosaving a crawl every settled step is on disk,
streams and all*. Controls (position, hp) green — those fields are asserted in
the same tests and did not move.

### Extensions I added — eleven rows

| # | Extension | Content | App | Note |
|---|---|---|---|---|
| 10 | run drops `nextDropNumber` (writes 1) | 4 red | 0 | caught |
| 11 | active floor's `explored` set emptied | 3 red | 0 | caught — this is the "active floor is not in `floors`" hazard |
| 12 | active floor's litter emptied | 3 red | 0 | caught — same hazard |
| 13 | `decodeProfile` rebuilds the hero at full health | 3 red | 0 | caught |
| 14 | `encodePositions` keeps iteration order instead of sorting | 1 red | 0 | caught, narrowly — see below |
| 15 | `decodeSave` silently repairs a bad document into a fresh hero | 8 red | 0 | caught — the "never repairs" contract is real |
| 16 | `save` writes straight to the current slot, no pending file | 0 | 10 red | caught |
| 17 | `load` reads the previous slot first | 0 | 9 red | caught |
| 18 | `bootFrom` does not save the fresh profile | 0 | 1 red | caught |
| 19 | `watchGame` stops writing after each step | 0 | 1 red | caught |
| 20 | `wideAt` also accepts a JSON number | 3 red | 0 | **the row that proves the strictness is load-bearing** |
| 21 | back handler forgets the log line **[addendum]** | 0 | 2 red | caught |
| 22 | `canPop: true` — back pops the crawl again **[addendum]** | 0 | **0 — invisible** | see below |
| 23 | back handler talks over the death overlay **[addendum]** | 0 | 1 red | caught |
| 24 | `didPop` guard dropped **[addendum]** | 0 | **0 — invisible** | see below |
| 25 | decoder ignores `active`, takes the first hero **[roster]** | 3 red | 2 red | caught |
| 26 | autosaver writes only the active hero **[roster]** | 0 | 2 red | caught — the other hero vanishes |
| 27 | empty `heroes` map accepted **[roster]** | 1 red | 0 | caught |
| 28 | abandoning keeps the old entry (a rename, not a deletion) **[roster]** | 1 red | 2 red | caught |
| 29 | CONTROL after the roster rows **[roster]** | `+197 All tests passed!` · `24/40, stalled 0` | `+176 All tests passed!` | green — proves 25–28 reverted |

Row 20 reddens *wide values a wide field given as a JSON number is refused*,
*the save document a wide field written as a number is refused*, and *the save
document a run's stream state written as a number is refused* — and nothing
else. The strictness has exactly three tests holding it up, and they are the
three that make row 6 fail. Reported as it landed.

**Row 14 is the weakest row in the table and I am flagging it rather than hiding
it.** Only one test notices that position sets stop being sorted: *actor codec a
set of positions is written in a stable order*. Both goldens survive, because
the sets in the golden documents happen to be written in an order that is
already sorted. That is luck, not coverage. The sort exists to make the format
byte-stable, and one assertion is all that defends it — worth knowing if
somebody later "simplifies" it away.

### 4a-bis. Rows 21–24, the back-button addition **[addendum]**

**Row 21** — app: *the system back button is refused, and the log says where the
way out is*; *the system back button stops a walk in progress rather than being
swallowed by it*. **Row 23** — app: *the system back button says nothing over a
death overlay that already says what to do*.

**Rows 22 and 24 are completely invisible to all 745 tests.** I ran them rather
than predicting it, and both came back `+170: All tests passed!`. That is the
same blind spot as the three boot defects: `canPop` and the `didPop` guard are
widget wiring, and this package has no widget tests by convention. Both are
verified on the AVD instead (item 9) — but the honest statement is that a future
edit flipping `canPop` back to true would reintroduce the exact defect this
commit fixes and **no test would say a word**. If any single line in this unit
deserves a comment telling a future reader not to touch it, it is that one; it
has a dartdoc instead, which is the best this convention allows.

Row 24's real consequence is subtler than a wrong log line: without the guard, a
legitimate exit at the stairs or from the death overlay dispatches an event into
a `GameBloc` that `_openCrawl` is about to close. Verified working on device —
the programmatic pop path was exercised and `logcat` shows no exception — but
that is the shipped code being right, not the mutation being caught.

### 4a-ter. Rows 25–29, the roster **[roster]**

**Row 25** — content: *the roster the active hero is the one the game opens on*;
*the roster an active id that names no hero is refused by name*; *the golden
save, two heroes the committed document decodes to both heroes*. App: *booting a
roster the active hero is the one the game opens on*; *autosaving with more than
one hero the hero nobody is playing is written back out untouched*.

**Row 26**, the one the contract named — app: *autosaving with more than one hero
the hero nobody is playing is written back out untouched*; *autosaving with more
than one hero a crawl is suspended on the active hero only*. This is the row that
matters most in the addition: without it a save would delete every hero the
player is not playing, once per turn, and nothing on screen would say so.

**Row 27** — content: *the roster a document with no heroes at all is refused*.
**Row 28** — content: *the roster a hero given up takes their slot with them and
nothing else*. App: *booting a roster giving a hero up keeps every other hero*;
*booting a roster a hero given up is written down before being played*.

All four are caught by tests, which is the useful contrast with rows 22 and 24:
the roster's rules live in the codec and in `SaveDocument`, where tests reach
them. Only the widget wiring is dark.

### 4a. Row 1 found a defect in my own test, not in the code

On the first pass, row 1 reddened nine content tests and left the **app suite
entirely green** — including *autosaving a crawl every settled step is on disk,
streams and all*, which compares the saved stream state against the live one and
should have been the app's guard for exactly this.

The reason was in the test. At world seed 5, depth 1, nothing is within reach of
the spawn tile: the hero walked, never swung, and the generator never advanced —
so `Rng(worldSeed)` and the live resumed stream were bit-for-bit identical and
the comparison was vacuous. I confirmed the hypothesis by reading the state off
the device (`rng` unchanged after six auto-walks) rather than guessing.

Fixed in `a0f5ae0`: the test now places a monster in arm's reach, swings three
times, and asserts the stream actually moved before comparing it. Re-running row
1 afterwards reddens the app suite too. **A mutation that cannot fail is not a
test — and this was one of mine, not one of the spec's.**

### 4b. Mutation row 6 as specced CANNOT FAIL. Proved, not argued.

The spec says row 6 reddens "precision round-trip", with a sequencing trap that
the test value must exceed 2^53 or the row is unfailable. The trap is right in
spirit and insufficient in fact: **the row is unfailable on this platform for a
different reason.**

`dart:convert` on the Dart VM and in AOT Android builds round-trips full-width
integers through JSON *as numbers, exactly*. Its parser yields `int`, not
`double`. Measured before writing any code:

```
9007199254740993     -> number:9007199254740993     same:true (int)
2420599403871909411  -> number:2420599403871909411  same:true (int)
-8613303245920329199 -> number:-8613303245920329199 same:true (int)
jsonEncode({'v': 9007199254740993}) == {"v":9007199254740993}
```

So D24's stated reason — "full-width ints do not survive double semantics" — is
true only under `dart2js`, which `Rng`'s own dartdoc already puts out of scope
("Residuum targets Android, so the constraint holds").

**The decisive experiment.** I ran row 6 the way the spec wrote it — numbers on
the encode side *and* a lenient decoder that accepts them, which is what a
codec drifting to numbers would actually look like:

```
ROW 6-AS-SPECCED (numbers on both sides, lenient decoder)
content: +172 -8
  RED: profile codec the world seed is written as a quoted string
  RED: run codec a full-width stream state is written as text and survives exactly
  RED: the golden save, hero in town the encoder reproduces it byte for byte
  RED: the golden save, crawl suspended the encoder reproduces it byte for byte
  RED: the save document a wide field written as a number is refused
  RED: the save document a run's stream state written as a number is refused
  RED: wide values a full-width value is written as a quoted string
  RED: wide values a wide field given as a JSON number is refused
app: +166: All tests passed!
```

**Every precision round-trip stayed green.** *profile codec a full-width world
seed survives exactly* and *the save document a full-width seed and both stream
states survive exactly* both pass with numbers on both sides, because the values
genuinely do survive. Only the format assertions and the golden byte pins caught
it, and both of those are tests I added for this reason.

**What I did instead, approved by the architect before I wrote it.** Kept the
string encoding, on a corrected argument, and made it self-enforcing:

- The reason recorded at the encoding site (`save_json.dart`, `encodeWide`) is
  not precision on this substrate. It is that a save file outlives the build
  that wrote it, and JSON's number is only as wide as whoever reads it decides —
  `dart2js`, `jq`, any harness someone debugs a save with. One document should
  mean one thing to every reader. The false precision claim is not in the code.
- `wideAt` accepts **nothing but text**. A JSON number where a wide value
  belongs is a structured failure. That makes the format self-enforcing: an
  encoder that drifted to numbers cannot read its own output, which is why row 6
  now reddens 54 tests instead of 8.
- Row 20 exists to show the strictness is itself load-bearing, and it is:
  three tests, no more.

## 5. Survivability — untouched

```
survivability: 24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24
greedy build: 24/40 won; fleetfoot-first build: 7/40 won
```

Identical to base in every figure, including the death histogram. Exactly 24/40,
stalled 0.

```
$ git diff main --stat -- packages/content/lib/src/bestiary.dart \
    packages/content/lib/src/spawn_tables.dart \
    packages/content/lib/src/drop_tables.dart packages/content/lib/src/economy.dart
(empty)
```

No forbidden lever touched. No seeded-outcome literal anywhere in the repository
was re-pinned.

## 6. The autosave cadence — measured on the AVD, default shipped

Measured with a throwaway probe in `main()` on the Pixel_10 emulator, release
build, 50 passes per figure, then reverted entirely (never committed; tree
confirmed clean afterwards). Deep states built with every shallower floor fully
explored — the worst case a save has to carry.

```
CADENCE depth=4 bytes=13929 floors=3 exploredTiles=518 monsters=6
CADENCE depth=4 encodeUs=812  encodeAndWriteUs=15746
CADENCE depth=5 bytes=18623 floors=4 exploredTiles=726 monsters=8
CADENCE depth=5 encodeUs=716  encodeAndWriteUs=3017
CADENCE done
```

**The number that decides the cadence is the synchronous encode, because that is
the only part that blocks the interface isolate: 0.81 ms at depth 4, 0.72 ms at
depth 5.** That is under 5% of a 16.7 ms frame, and comfortably under the 4 ms
bar I set in the plan before seeing the numbers.

The write is asynchronous and off the interface isolate. Steady state for the
whole operation — encode, write the pending file, read it back to verify, two
renames — is **3.0 ms** at depth 5. The depth-4 figure of 15.7 ms is the
first-write warm-up (the `path_provider` channel, a cold file system) and not a
per-step cost; depth 5 ran immediately after and is the honest steady state.

**Shipped: the spec's default — a save after every settled game-state change.**
The named fallback is not used, so no lifecycle observer was added and no
message about it was needed. Writes are queued rather than overlapped, so a
burst of auto-walk steps (90 ms apart) cannot back up behind 3 ms writes.

Encode cost falls slightly from depth 4 to depth 5 despite a larger document,
which reads as ahead-of-time warm-up dominating a sub-millisecond measurement.
Not investigated further: both numbers are an order of magnitude inside budget,
and chasing the difference would not change the decision.

## 7. Static checks and diffs

```
$ flutter analyze
No issues found! (ran in 2.5s)

$ dart format --set-exit-if-changed .
Formatted 114 files (0 changed) in 0.24 seconds.

$ git diff main --stat -- packages/core
(empty)
```

**`packages/core` is empty, as promised.** The field audit found every field the
codec needs already public and every constructor it calls already public —
`GameState`, `FloorMemory`, `Actor`, `Item`, `Profile`, `SkillState` — so no core
getter was needed and no pre-declared core deviation was spent.

Content diff — only the save feature and the registry lookups:

```
 packages/content/lib/content.dart                  |   2 +   (two exports)
 packages/content/lib/src/affix_pool.dart           |  16 +-  (affixOrNull)
 packages/content/lib/src/armory.dart               |  19 +-  (baseItemOrNull)
 packages/content/lib/src/save/actor_codec.dart     | 110 +
 packages/content/lib/src/save/item_codec.dart      | 158 +
 packages/content/lib/src/save/profile_codec.dart   |  52 +
 packages/content/lib/src/save/run_codec.dart       | 125 +
 packages/content/lib/src/save/save_codec.dart      |  66 +
 packages/content/lib/src/save/save_json.dart       |  77 +
 packages/content/lib/src/save/save_read.dart       |  47 +
 packages/content/pubspec.yaml                      |   1 +   (equatable, see below)
 + eleven test files
```

`equatable` was added to content's `pubspec.yaml` as a direct dependency.
`SaveFailure` uses it, and content was already importing it transitively through
core — an undeclared import that would break the day core dropped it. One line,
same version core pins.

## 8. Hygiene greps

```
$ grep -rn "dart:io\|DateTime" packages/content/lib
(empty)

$ grep -rn "Random(\|Random.secure\|math.Random" packages/core/lib packages/content/lib packages/app/lib
packages/core/lib/src/engine/rng.dart:5:/// same game. The generator is hand-rolled rather than `dart:math.Random`
```

The single hit is a dartdoc sentence in `Rng` explaining why `dart:math.Random`
is *not* used. **There is no `dart:math.Random` construction anywhere in the
repository.**

The one sanctioned unseeded roll, quoted whole:

```dart
// packages/app/lib/save/boot.dart:51
int rollWorldSeedFromClock() => DateTime.now().millisecondsSinceEpoch;
```

`grep -rn "DateTime" packages/app/lib` returns that line and nothing else.

```
$ grep -rn "^\s*//" packages/content/lib/src/save packages/app/lib/save packages/app/lib/main.dart | grep -v "///"
(empty)
```

No body comments. Dartdoc only.

**All five required behaviour arguments are in documentation**, at the site each
one belongs to:

| Argument | Where |
|---|---|
| why one document, not two files | `save_read.dart`, `SaveDocument` |
| earned fields vs frozen actors, both halves | `profile_codec.dart`, `encodeProfile` |
| why 64-bit values are text | `save_json.dart`, `encodeWide` |
| why `loadRun` must not bump visit | `run_codec.dart`, `loadRun` |
| why verify-then-rotate | `save_store.dart`, `SaveStore.save` |

## 9. AVD acceptance — every scenario, on `emulator-5554` only

A physical phone (`10DF1Q03JJ000HK`) was attached throughout. **Every `adb` and
`flutter` command was pinned to `emulator-5554`. Nothing was installed on the
phone.**

Screenshots in `/var/home/dhemas/.claude/jobs/7b96deb1/tmp/`.

**Fresh install rolls a non-1 world seed and survives an immediate kill.** After
`pm clear`, `save.json` alone (no previous slot — correct for a first write):

```
{"version":1,"profile":{"hp":20,...,"worldSeed":"1787295487788","visit":0,...
before kill: "worldSeed":"1787295487788"
after  kill: "worldSeed":"1787295487788"
```

**Kill mid-fight, resume roll-for-roll** — the scenario this unit exists for.
Walked to a fight on depth 1 (hero bitten to 19, rat adjacent, stream advanced),
captured the document, then `am force-stop` and relaunch:

| | pre-kill | after relaunch |
|---|---|---|
| hero | (4,8) hp 19 energy 100 | (4,8) hp 19 energy 100 |
| rat-1 | (5,8) hp 4 energy 100 | (5,8) hp 4 energy 100 |
| rat-2 / rat-3 | (14,9) / (19,7) | (14,9) / (19,7) |
| depth / visit | 1 / 1 | 1 / 1 |
| explored | 96 tiles | 96 tiles |
| rngState | 5157434200230410074 | 5157434200230410074 |
| lootRngState | 1426961671866288674 | 1426961671866288674 |
| map | — | identical |

Screenshot pair `06-prekill.png` / `07-resumed.png`; the resumed screen shows the
same tile, 19/20, Engaged 1, and "The crawl resumes."

**The same next roll.** I did not eyeball this — I ran it twice from the same
document. Attacked once from the resumed state (run A); then force-stopped,
pushed the pre-kill document back into the current slot, relaunched, and made
the same attack (run B):

```
RUN A  hero (4,8,17,100)  rat-1 (5,8,1,100)  rng -8934624308542296188
RUN B  hero (4,8,17,100)  rat-1 (5,8,1,100)  rng -8934624308542296188
SAME hero · SAME mons · SAME rng · SAME loot · SAME nextDrop · SAME ground
```

The same damage on both sides of the kill (rat 4→1, hero 19→17) and the same
resulting stream state. **Roll-for-roll, on device.**

**Corrupt-file fallback with a visible notice.** Truncated `save.json` to 400 of
3861 bytes by hand, relaunched. The previous slot was restored (17/20, rat at 1
hp) and the log reads (`10-fallback-notice.png`):

```
Your last save could not be read; an older one was restored.
The crawl resumes.
```

**Both slots corrupt begins a fresh hero, and says so.** Overwrote both slots
with junk (`11-fresh-hero.png`):

```
— your last save could not be read; a new hero begins.
old world: "worldSeed":"1787296540334"
new world: "worldSeed":"1787296901084"
```

**Death-overlay resume** (`14-death-resume.png`). Built from the *real* pre-kill
document with two fields edited — `hero.hp` to 0 and `isGameOver` to true —
rather than grinding a death on depth 1; stated plainly because it matters that
the rest of the document is genuine codec output. Relaunching opens the crawl
with the overlay up: "You died.", 0/20, "Dead", Depth 1/5. Pressing "Return to
town" then clears the run block and applies the death penalty correctly:

```
run: null
hp 20  gold 0  visit 1  worldSeed 1787296540334
inventory 0   equipment ['mainHand']
```

Carried pack burned, worn gear kept, hero woken whole, visit kept — `endRun`'s
contract, reached through a resume.

**Abandon-hero confirm flow** (`12-abandon-dialog.png`, `13-abandoned.png`).
Pressing the door opens a dialog whose two actions are words. "Keep this hero"
left the world seed untouched and both slots in place. "Abandon" then:

```
before: "worldSeed":"1787296901084"   files: save-previous.json save.json
after:  "worldSeed":"1787296951594"   files: save.json
```

Both slots wiped, a new world rolled, and written immediately.

**[roster] This evidence no longer describes the shipped behaviour, and the
change is deliberate.** Abandoning used to wipe both save files, which was right
while a document could hold only one hero and became wrong the moment it could
hold several: wiping would delete every hero the player did not ask about. It now
replaces the active hero's slot and saves normally, so the previous slot survives
as an ordinary rotation. Re-verified on device below.

**The system back button is refused, and the crawl survives it. [addendum]**
Entered the dungeon, pressed `KEYCODE_BACK`:

```
focused window after back: mCurrentFocus=Window{... com.example.residuum_app/...MainActivity}
```

Still in the crawl, log reads `You can only leave at the stairs.`
(`16-back-refused.png`). Then force-stopped and relaunched — the run resumes
untouched, which is the point of refusing the pop rather than confirming it:

| | before back + kill | after relaunch |
|---|---|---|
| hero | (5,4) hp 20 | (5,4) hp 20 |
| depth / visit | 1 / 1 | 1 / 1 |
| rngState | 4270889501288079823 | 4270889501288079823 |
| explored | 76 tiles | 76 tiles |

**The pack still closes on back. [addendum]** Opened the pack, pressed back:
returned to the crawl (not to town) with no refusal line added to the log
(`18-pack-open.png` / `19-pack-closed.png`). The pack's route carries no
`PopScope`, so the crawl's refusal does not reach it — the contract's
"inventory route keeps popping normally" holds.

**Back on the death overlay is refused and says nothing. [addendum]** Resumed
into a game-over document, pressed back: the app stayed foregrounded, the overlay
stayed up, and the log still showed only `The crawl resumes.` — no stairs line
(`20-back-on-death.png`). Advice about stairs is advice a dead hero cannot take.

**The programmatic pop still works, with no exception. [addendum]** Pressed
"Return to town" from that overlay — the same `leaveDungeon` call the stairs
control uses:

```
run block cleared, town reached
--- any Flutter exception during the programmatic pop? ---
[end of exception scan]
run: None | hp 20 gold 0 visit 1 inventory 0
```

`logcat` scanned for `EXCEPTION|Bad state|Cannot add new events|StateError`:
nothing. The `didPop` guard means a real exit says nothing and does not dispatch
into a bloc being torn down.

**The roster shape on a fresh install. [roster]** After `pm clear`:

```
{"version":1,"active":"hero-1787301318322","heroes":{"hero-1787301318322":
{"label":"Hero 1","profile":{"hp":20,...,"worldSeed":"1787301318322",...
```

The hero's id and their world are two halves of one clock reading, and the
default label is written down rather than left for the roster screen to invent.

**Kill mid-crawl, on the roster document. [roster]** Entered, walked four steps
to depth 1 (hero (4,11), rng -4175017804035792185, 108 explored tiles, 4
monsters), force-stopped, relaunched, and compared the **entire document**
normalised and sorted:

```
DOCUMENT IDENTICAL ACROSS THE KILL
```

Not a field-by-field comparison this time but the whole file, which is the
stronger assertion and the one the roster made easy.

**Abandoning replaces one slot, on device. [roster]**

```
old active: hero-1787301318322
new active: hero-1787301386296
heroes now: ['hero-1787301386296']
old entry deleted: True
new world seed: 1787301386296 | label Hero 1
files: ... save-previous.json  save.json
```

The old entry is gone rather than renamed, the new hero is filed and labelled,
and the previous slot survives as a rotation — the corrected behaviour, with the
dialog and both its buttons unchanged (`24-roster-abandon-dialog.png`).

**A second hero survives a whole session by the first. [roster]** Pushed a real
two-hero document — one hero suspended in a crawl, the other in town and active
— launched, entered the dungeon as the active hero and walked three steps:

```
active: hero-played
heroes: ['hero-idle', 'hero-played']
idle hero untouched: True
  idle label: Ilse | idle still suspended at depth 1 rng -4175017804035792185
played hero now in a crawl: True | depth 1 | rng -4175017804035792185
```

The idle hero's entire entry compared equal after a full crawl session by the
other, which is mutation row 26's defect verified absent on hardware.

**One limit of that fixture, stated because the output invites the wrong
reading. [roster]** I built the two-hero document by cloning one real hero twice,
so both entries carry the same `worldSeed` and the same stream state, and the
printed lines agree for that reason rather than because the code kept them
together. The check therefore proves **preservation** of the idle entry and not
**separation** of the two worlds. Separation is unit-tested instead — *the roster
each hero keeps their own world*, seeds 111 and 222 — and I chose not to
hand-edit one clone's seed on device, because a profile seed that disagreed with
its own run's seed would be a document the game could never have produced, which
is the fixture mistake recorded in item 11h.

**Greyscale check.** The four changed screens converted to true greyscale
(`grey-*.png`) and read: every element this unit added is a word — the
"Abandon Hero" door, "Keep this hero" / "Abandon", the town notice sentence, and
both new log lines. Nothing new depends on hue. Legible.

## 10. What the tests cannot prove

- **That a real Android kill is as clean as `am force-stop`.** Force-stop is the
  harshest kill a user can cause and the one I tested. A low-memory kill mid-`write`,
  or a kernel panic between the two renames, is not reachable from adb. The
  verify-then-rotate ordering is designed for it and the pure tests cover the
  ordering, but the ordering has not been observed failing on real hardware.
- **That the `IoSaveFiles` adapter is right.** It is deliberately decision-free
  and verified only by running the game, which exercised read, write, rename and
  delete on the emulator. Its error paths — a read that throws
  `FileSystemException`, a rename onto a locked file — were not provoked.
- **The abandon-hero guard itself.** The dialog is the whole guard, and this
  package has no widget tests by convention. The bloc test proves only that no
  other event ever sets the flag. The guard was verified by hand on the AVD, both
  branches. A future refactor that wires the door straight to
  `AbandonHeroConfirmed` would delete a hero without asking and no test would say
  so.
- **Boot wiring in general.** All three defects in item 11d were in
  `main.dart`'s widget lifecycle, which no bloc-level test can reach. The same
  class of bug can recur. This is the sharpest limit in the unit — and the
  back-button defect found after my report is a fourth instance of exactly it.
- **`canPop: false` and the `didPop` guard are untested. [addendum]** Mutation
  rows 22 and 24 prove it: flipping either leaves all 745 tests green. The
  back-button refusal is held up by nothing but a dartdoc and one AVD press. A
  widget test would close this, and the convention forbids one; if any single
  exception to "no widget tests in app" is ever worth making, this is the
  candidate, and that is a call for the architect rather than for me.
- **hp is carried verbatim with no clamp.** The real ceiling needs the loadout,
  and clamping to the bare body would eat gear-granted hit points, so the codec
  holds no rule at all. A future rebalance that *lowers* a hero's ceiling can
  therefore leave an old save briefly reading above it. No test covers that,
  because it would be a test of a rule I deliberately did not write.
- **Format compatibility with any version but 1.** There is one version and one
  reader. The migration path the version field exists for has never been walked —
  and the roster shape was introduced by rewriting version 1 rather than by
  migrating to version 2, which is only sound because version 1 has never
  shipped. **The first shipped build closes that door**: after it, a shape change
  is a version bump and a migration, and nothing in the code enforces that rule
  today. **[roster]**
- **No test covers switching hero, because nothing switches yet. [roster]** The
  document holds a roster and the codec round-trips it, but the only hero the app
  can reach is `active`, and the only thing that changes `active` is abandoning.
  `SaveDocument.replacingActive` and the label are exercised by tests and by
  nothing the player can press. That is the follow-up unit's job, and until it
  lands the roster is a format with one door into it.
- **That the golden documents are the only stable encoding.** The goldens pin
  what the encoder does today. Row 14 shows one of the properties that makes them
  stable rests on a single assertion.
- **Two `SaveStore` instances over one directory fight over the pending file** —
  I found this while writing a bad test. Both fail and write nothing rather than
  interleaving a corrupt document, which is the right failure, but it is
  incidental rather than designed. The app builds exactly one store, so it cannot
  happen today.

## 11. Every spec claim I checked and found wrong

**11a. `FloorMap.toAscii()` already exists.** The recon says "`FloorMap` has
`parse` (ASCII in) but no inverse; the codec needs an ASCII renderer". It has
one, at `packages/core/lib/src/dungeon/floor_map.dart`, dartdoc "The exact
inverse of `FloorMap.parse`", added for M3R's golden pin. The codec uses it and
no renderer was written. The architect confirmed the recon error (a head-limited
read of the file).

**11b. `baseItemById` and `affixById` already exist.** The recon says "No by-id
lookup exists — the codec adds them". They are at `armory.dart:163` and
`affix_pool.dart:80`, and `content_validation_test.dart:604` and
`economy_test.dart:158` already exercise them. They throw `ArgumentError` on a
miss, which is right for a drop-table typo and wrong for the codec. Adding the
nullable behaviour under the spec's names would have re-pinned existing tests, so
`baseItemOrNull` and `affixOrNull` were added beside them with the throwing pair
delegating. Confirmed by the architect (a case-sensitive grep that could not
match).

**11c. Mutation row 6 could not fail as written, and D24's reason is false on
this platform.** Fully evidenced in item 4b. This is the most consequential of
the three.

**11d. Three claims the spec makes about the app that were wrong in my own
implementation, found on the emulator.** Not spec errors — implementation errors
the spec's test plan could not catch, recorded here because the spec asserts the
behaviour and the behaviour was absent:

- *"Town: save after every `TownBloc` emission."* It was not. The autosaver was
  a `late final` field that nothing on the town screen ever read, so it stayed
  unbuilt and watched nothing until the first crawl opened. Every town
  transaction before that went unwritten, and entering the dungeon left **no run
  block on disk at all** — `visit 0`, no rotation, no previous slot. The whole
  point of the unit was silently absent while all 166 app tests passed. Fixed by
  attaching in `initState`.
- *"one line 'the crawl resumes' is emitted instead."* It was emitted on a fresh
  entry too, because the resume line was hardcoded into the door both paths
  share. A first entry now opens on an empty log.
- *"Every fallback step produces a report the town screen shows once."* It does
  not reach the player in the case that matters most. When the restored save
  holds a suspended crawl, the player is put straight into the dungeon and never
  sees the town — and by the time they walk out, `RunEnded` has built a fresh
  town state with no notice on it. The report was lost entirely on that path. A
  resumed crawl now opens its log with the report as well as the resume line.

**11d-bis. A fourth boot-wiring defect, found by the user after my report.
[addendum]** The crawl route was a plain pushed `MaterialPageRoute`, so Android's
back button popped it with no `RunEnded`: the town showed the profile that walked
in while the save on disk still held the suspended crawl, and the next descent
bumped the visit and wrote over it. Silent progress loss through a door the
design never opened — the spec's own "exits are the stairs or death" was not
enforced anywhere in the app. Same class as the three in 11d, same blind spot,
and I did not find it: I tested the paths the spec named and never pressed the
system back button. **The lesson is mine to carry: "verify on the AVD" has to
mean pressing the buttons the platform provides, not only the ones the app
draws.**

**11e. Minor citation slips**, flagged and not touched:
- The build prompt cites "section 13 on saves". Saves are section 11 ("Saves and
  offline"); section 13 is "Error handling and robustness", which does hold the
  corrupt-save-falls-back rule.
- Design spec section 11 says "Three manual slots" and "Autosave on floor change,
  town arrival, and app pause". M3S deliberately supersedes both. The architect
  will record this as a ledger decision at story close rather than edit the spec.

**11f. One claim I said I would add that was already there.** I told the
architect I would pin affix-id uniqueness across both pools, which the recon
listed as unverified. It is already asserted: `content_validation_test.dart`'s
*every affix id is unique* runs over `affixPool`, which is
`[...weaponAffixes, ...armourAffixes]` — so it already spans both pools. **No
test was added.** Correcting my own message rather than leaving it to be assumed.

**11g. One spec test I built differently.** The spec allows the hero-rebuild test
to use "a resolver seam if the codec has one, or document why untestable". No
seam was needed: `decodeProfile` calls `newProfile` itself, so encoding a hero
with an inflated body and decoding it observes the rebuild directly —
*profile codec the hero rebuilds on this build's own base body* asserts hp 11
survives while maxHp, attackMin, attackMax and speed all come back as content's.

**11h. One test-helper bug worth recording,** because it nearly became a false
pass. My `deepRun` helper synthesized a state at depth > 1 with `stairsUp: null`,
because `content.buildFloor` never sets it — but `step`'s `_built` sets
`stairsUp: floor.stairsUp ?? floor.heroSpawn`, so no real descent can produce
what my helper produced. Two suspend theorem tests failed on a state the game
cannot reach. The helper was corrected to follow `_built`'s rule, with the reason
in its dartdoc. **A test built on an impossible state proves nothing**, and this
one would have quietly stopped exercising the revisited-floor path.

## 12. Which execution phases ran, and why any named phase was skipped

| Phase | Ran | Note |
|---|---|---|
| Read spec, recon, design spec, CLAUDE.md in full | yes | before planning |
| Field audit against the `GameState` constructor and every `copyWith` site | yes | found the enumeration complete — see below |
| `writing-plans` | yes | `docs/superpowers/plans/2026-08-21-m3s-saves.md`, committed |
| Pre-declaration message to the architect | yes | before the first line of production code; answered and approved on every point |
| C1 characterization at base | yes | item 3 |
| Strict TDD, red then green, per task | yes, with one exception | `boot.dart` — see below |
| Cadence measurement on device before choosing | yes | item 6 |
| Mutation table, all 9 rows plus 11 extensions | yes | item 4 |
| AVD acceptance, all six scenarios | yes | item 9 |
| Greyscale check | yes | item 9 |
| Per-task reviewer subagents | **skipped** | argued below |
| Back-button fix: bloc test red, then green, then 4 mutation rows, then AVD **[addendum]** | yes | one process slip, below |
| Roster: 15 codec tests red first, then shape, then goldens regenerated, then 7 app tests, 5 mutation rows, 3 AVD checks **[roster]** | yes | goldens regenerated deliberately, sanctioned |

**The field enumeration held up.** The spec's run-block field list was written
from reading `game_state.dart` once, and you asked me to distrust it. I diffed it
against the constructor and every `copyWith` site: `GameState` has 22
constructor parameters, of which `buildFloor` and `dropTables` are the two
re-injected collaborators. The spec's list covers all 20 remaining fields with
nothing missing. `copyWith` exposes no field the constructor does not, and it
notably cannot change `gold`, `worldSeed`, `visit`, `rng` or `lootRng` — so no
field can be mutated behind the codec's back. **The one claim in the spec I was
told to attack hardest turned out to be exactly right.** Extension rows 10–12
were written specifically to catch a missed field anyway, and all three redden.

**The one TDD exception, stated plainly.** For `boot.dart` I wrote the test and
the implementation in the same step rather than red-then-green. I noticed, and
rather than assert the discipline I verified it: I moved `boot.dart` aside and
re-ran `boot_test.dart`, which failed, then restored it. Extension row 18
independently shows a boot test is load-bearing. Every other task was strict
red-then-green, with the failing run recorded before implementing.

**One process slip worth recording. [addendum]** Running the first back-button
mutation, I reverted it with `git checkout <file>` — and since the fix itself was
not yet committed, that discarded the implementation rather than the mutation.
The next row then failed to compile and reported a meaningless red. Caught it in
one step (`git status` showed the file unmodified), re-applied, and committed
before running any further rows. **The mutation-table method quietly assumes the
code under test is committed**; every earlier row in this unit happened to
satisfy that and this one did not. Worth knowing for the next unit.

**Two notes on the roster addition. [roster]** First, `SaveStore.wipe` was
deleted rather than left unused: once abandoning replaces a slot, nothing wipes
the file, and a tested method that deletes both save slots and has no caller is
worse to leave lying around than to write again when the roster unit needs a
delete. Its test went with it, which is the −1 in the app count. Second, the
golden fixtures were regenerated rather than migrated. That is only legitimate
because version 1 has never shipped, which the contract said explicitly; I
re-read each regenerated document before pinning it, and the profile and run
blocks inside are byte-identical to the old goldens, so the only drift is the
roster wrapper.

**A second process slip, of the same family as the last one. [roster]** My
patch script rewrote the golden literals through `re.sub`, which interprets
backslash escapes in the *replacement* string — so `\\n` in the JSON became a
real newline in the Dart literal and the byte-for-byte test failed on a
difference the test output could barely render. Fixed by passing a function as
the replacement. Both slips this session were tooling doing something reasonable
that I had not checked; the pattern is mine to watch.

**Why per-task reviewer subagents were skipped** (ledger D9 precedent, and the
prompt asks me to argue it rather than assume it). The adversarial load in this
unit is carried by things a reviewer subagent could not have carried:

- **The mutation table is a stronger reviewer than a reading.** Twenty rows, each
  one asking "if this were wrong, would anything go red?" — and it caught a real
  defect in my own test suite (item 4a) that a code reviewer reading the same
  test would very likely have called adequate, because the assertion *looks*
  right and is only vacuous given a fact about world seed 5's first floor.
- **The three defects that mattered were not visible in the diff at all.** A
  `late final` field that nothing reads is correct Dart, reviews clean, and
  passes 166 tests. It was found by running the game and looking at the file on
  disk. No amount of subagent review substitutes for that, and the AVD pass is
  where the budget went.
- **The spec claims needed running, not reading.** Row 6's unfailability was
  settled by executing `dart:convert`, not by reasoning about it. A subagent
  asked to review the codec would have inherited the same false premise from the
  spec.
- **Scale.** Twelve commits, roughly 2,500 lines mostly of small pure functions
  with dense dartdoc, each covered by its own tests before the next commit.

The honest cost of the skip: no independent reader checked the dartdoc prose for
accuracy, and no second pair of eyes reviewed the seven-file codec split for
whether the boundaries are the right ones. If you want one review pass, the
codec's file boundaries and the five documentation arguments are where I would
point it.

---

*`BUILD-REPORT.md` mirrors the verification block, as the prompt requires, in
case the reply to the architect is held.*
