# Build report — unit `m3-leave`, story M3L "The suspend door"

Every identifier, count and line of output below is pasted from a command run in
this session. Nothing here is typed from memory.

## 1. Where the work is

```
$ pwd
/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-leave

$ git log --oneline main..m3-leave
3a0c890 fix: walking out of a resumed crawl keeps the shelf it was shopping at
a02e058 test: a crawl laid out afresh does not claim to be resumed
34b40ff test: the purse the hero spent in town goes back down with them
f45dbd5 test: the carry test can see the gold it names
0f35caf feat: a way out of the crawl, and two ways back in
4caa81c feat: the autosaver writes down which side of the stairs the hero is on
6c8247a feat: the town holds the crawl the hero camped in
3ba0422 feat: the save document says whether a hero is in their crawl
9b1e706 test: the identity theorem, byte for byte through the codec
f79837d feat: walking back into the crawl the hero left
4638bf0 feat: a door out of the dungeon that leaves the dungeon standing
b94f63a test: characterize what leaving a crawl alive carries home (C1)

$ git status --porcelain
(clean)
```

Base `f7bd6b1`. Nothing under `docs/epic/` is committed:

```
$ git log main..HEAD --name-only --pretty=format: | grep "docs/epic"
(nothing under docs/epic)
```

Screenshots for the AVD run are left outside git at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-leave-shots/`.
This file replaces M3H's build report, which stays in git history at `f7bd6b1`.

## 2. The characterization tests passed against UNMODIFIED code

Run before the first change to any production file.

**C1** — new, `packages/core/test/town/suspend_run_test.dart`, group
`characterization: what leaving alive carries (C1)`. The existing
`run_boundary_test.dart` already pins hp, inventory, bank, gold, skills and
visit for `endRun(died: false)`; what it did **not** pin is the two facts this
unit's design turns on. Added only those:

```
$ cd packages/core && flutter test test/town/suspend_run_test.dart
00:00 +2: All tests passed!
```

The two tests are `the hero that comes home is the one that stood in the dungeon`
(position and energy travel, not just hp) and `gear worn in the dungeon comes
home worn`.

**C2** — the machinery being reused, unmodified:

```
$ cd packages/content && flutter test test/save/suspend_theorem_test.dart
00:00 +6: All tests passed!

$ cd packages/app && flutter test test/widget/boot_wiring_test.dart
00:03 +3: All tests passed!
```

No characterization test failed at base, so nothing was worked around.

## 3. The three suites against the baseline

**The baseline was re-measured in this worktree before the first change**, at
`f7bd6b1`, and it matched the architect's fresh 2026-08-22 measurement exactly:

```
core:    00:02 +395: All tests passed!
content: 00:05 +212: All tests passed!
app:     00:09 +222: All tests passed!
```

395 + 212 + 222 = **829**, as stated in the spec.

At `3a0c890`:

```
core:    +408: All tests passed!
content: +225: All tests passed!
app:     +264: All tests passed!
```

408 + 225 + 264 = **897**. Net **+68** (+13 core, +13 content, +42 app). No test
was deleted anywhere in this unit — section 13.

## 4. Survivability

```
$ cd packages/content && flutter test test/survivability_test.dart
survivability: 24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24
greedy build: 24/40 won; fleetfoot-first build: 7/40 won
00:07 +5: All tests passed!
```

Exactly the required lines, and identical to the pre-change measurement in this
worktree. The bot never suspends, so the band is blind to this unit by design
(D15/D35) — see mutation row 2, where dropping a carry leaves it at 24/40.

## 5. Analyzer, formatter

```
$ flutter analyze
No issues found! (ran in 3.7s)

$ dart format --set-exit-if-changed .
Formatted 125 files (0 changed) in 0.34 seconds.
```

## 6. The full mutation table

Every row applied to **committed** code, run, reverted; the tree was verified
clean before and after each row by the harness, which aborts on either failure
(`TREE NOT CLEAN` / `REVERT CLEAN`). Rows are the spec's 1–8 plus thirteen
extensions.

| # | Mutation | Went RED | Stayed GREEN (control) |
|---|---|---|---|
| 1 | `resumeRun` keeps the suspended inventory | core `the town business the hero did while camped comes down too`; widget `a potion bought while camped is in the resumed pack` (`+5 -1`) | identity theorem `+10: All tests passed!` — **the theorem alone cannot guard injection**, exactly as the spec predicted |
| 2 | `suspendRun` stops carrying gold home | core `the town business…`, `banked gold stays in the vault rather than going down` (`+11 -2`); content theorem 3 tests red (`+7 -3`) | **survivability stays `24/40 won (60.0%)… 1:1 2:9 3:6 5:24`** and `7/40`. See the finding in section 11 — the spec's "core carry test" cannot redden this row even in principle |
| 3 | revert the `_settled` carry (the landmine) | app bloc `shopping while camped does not lose the camp`, `selling while camped keeps the camp, streams and all`, `a refused transaction does not lose the camp either`, `resuming hands back the crawl with the town business in it` (`+45 -4`); autosaver `a purchase while camped keeps the camp on disk`; widget `a potion bought while camped…`, `a night at the inn while camped…` | `core +408`, `content +225` — both suites entirely green; the pin lives in the app layer |
| 4 | boot treats `inside: false` as true | ten widget tests, led by `a document with a crawl the hero left opens in the town`, `switching to a camped hero lands in their town, camp kept`, `a camped hero boots into the town, camp and all` (`+33 -10`) | `a document the hero is inside opens in the crawl` stayed green — **the app-kill-mid-crawl path did not regress** |
| 5 | codec defaults a missing `inside` to false | `a hero entry missing its inside field is refused by name`, `an inside that is not true or false is refused by name` (`+126 -2`) | all three golden decode tests green |
| 6 | codec accepts `inside: true` with `run: null` | `a hero inside a crawl that is not there is refused by name` (`+127 -1`) | rest of the content save suite green |
| 7 | `RunSuspended` keeps the merchant block | `suspending forgets the visit the merchant remembered` (`+54 -1`) | rest of the town bloc suite green |
| 8 | delve-anew resumes instead of entering fresh | bloc `delving anew gives the camp up and reshuffles`; widget `confirming reshuffles into a fresh crawl on floor one` | the resume-path tests stayed green |
| 9 (ext) | `resumeRun` takes the profile's hero whole, position and all | core `the dungeon is exactly where it was left` (`+12 -1`) | theorem `+10` green, widget `+13` green — **one test guards this choice, deliberately**: it is only observable the day something in town moves a hero |
| 10 (ext) | `resumeRun` keeps the suspended gold | core `the town business…`, `a night at the inn shows in the hit points that go back down`; theorem `town business is the one thing the theorem does not cover` | **widget `+13` green — a real gap.** Closed in `34b40ff`; the row then reddens `a potion bought while camped is in the resumed pack` too |
| 11 (ext) | the autosaver calls every hero inside their crawl | **17 tests** across `autosaver_test.dart` (`+10 -13`) and `widget/` (`+39 -4`) — the malformed `inside: true` + `run: null` pair makes the codec refuse the document outright | — |
| 12 (ext) | the autosaver never learns the camp (`_run = state.run`) | autosaver `a camp is written as a crawl the hero is not in`, `a purchase while camped keeps the camp on disk`, `leaving and going back down twice writes one document per change`; widget `leaving lands in town with the crawl left standing` | **town bloc suite `+55` entirely green** — the landmine has two independent layers and each needs its own row (row 3 is the bloc carry, this is the saver's read) |
| 13 (ext) | delving anew is silent, no confirmation | `delving anew asks first, and a refusal keeps the camp`, `the question says what is lost and what is not`, `confirming reshuffles…` (`+10 -3`) | — |
| 14 (ext) | the stairs `Leave` control ends the run again | widget `leaving lands in town with the crawl left standing`, `the town then offers going back down, at the depth left` (`+41 -2`) | `game_bloc_test.dart +55` green — the back-button guard is untouched |
| 15 (ext) | a fresh delve claims to be a resume in its log | **NOTHING — `+43: All tests passed!`** Reported as a gap, closed in `a02e058`; the row then reddens `confirming reshuffles into a fresh crawl on floor one` |
| 16 (ext) | suspending goes through `endRun(died: false)` instead of `suspendRun` | **NOTHING — bloc `+55`, widget `+43`, autosaver `+23` all green.** A truthful weak row; see section 11 | — |
| 17 (ext) | `watchGame` stops skipping unchanged states | `a change that is not a game-state change writes nothing` (`+22 -1`) | the write-count test stayed green |
| 18 (ext) | `watchGame` stacks a second writer | `a change that is not a game-state change writes nothing` only | **the write-count test stayed green** — and that is the mechanism finding: a stacked writer is neutralised by the identity skip, because the first listener has already updated `_run` |
| 19 (ext) | a stacked writer **and** no identity skip | `a change that is not a game-state change writes nothing` **and** `leaving and going back down twice writes one document per change` (`+21 -2`) | — proves the write-count instrument has teeth |
| 20 (ext) | suspending clears the merchant block unconditionally — the D36 defect | `walking out of a resumed crawl keeps the visit the merchant remembers`, `… keeps what is on the counter too` (`+54 -2`) | `suspending forgets the visit the merchant remembered` green, and `autosaver_test.dart +23` green |
| 21 (ext) | suspending never clears the merchant block | `suspending forgets the visit the merchant remembered` (`+56 -1`) | the two new tests green |

Rows 20 and 21 are the pair the architect asked for after D36: each half of the
conditional is pinned by its own row, and neither test can cover for the other.

## 7. The scope of the diff

```
$ git diff main --stat -- packages/core/lib
 packages/core/lib/src/town/run_boundary.dart | 93 ++++++++++++++++++++++++++++
 1 file changed, 93 insertions(+)

$ git diff main --stat -- packages/content/lib
 packages/content/lib/src/save/save_codec.dart | 20 ++++++-
 packages/content/lib/src/save/save_read.dart  | 76 +++++++++++++++++++++++----
 2 files changed, 83 insertions(+), 13 deletions(-)

$ git diff main --stat -- '**/pubspec.yaml'
(none)

$ git diff main --stat -- packages/app/lib
 packages/app/lib/game/game_screen.dart |  43 ++++++--
 packages/app/lib/main.dart             |  82 ++++++++++++---
 packages/app/lib/save/autosaver.dart   |  39 +++++--
 packages/app/lib/save/boot.dart        |  11 +-
 packages/app/lib/town/town_bloc.dart   | 132 +++++++++++++++++++++++-
 packages/app/lib/town/town_screen.dart | 182 +++++++++++++++++++++++++--------
 6 files changed, 408 insertions(+), 81 deletions(-)

$ git diff main --name-only -- '*bestiary*' '*spawn_tables*' '*drop_tables*' \
    '*armory*' '*affix_pool*' '*economy*' '*new_game*' '*generator*' \
    '*step.dart' '*floor*'
(none touched)
```

Core is one file — `town/run_boundary.dart` — and needed no export change, because
`core.dart:25` already exports that file wholesale. Content is confined to
`src/save/`. No dependency added or moved. No save-version bump: this is the
sanctioned in-place v1 reshape, and **the first shipped build freezes v1.**

## 8. Hygiene greps

```
$ git diff main --name-only -- 'packages/*/lib/*' | xargs grep -n "^\s*//[^/]" | grep -v "// ignore"
(none)

$ grep -rn "Random(" packages/*/lib packages/*/test
(none)

$ grep -rn "dart:io\|DateTime" packages/core/lib packages/content/lib
(none)

$ grep -rn "DateTime.now" packages/app/lib
packages/app/lib/save/boot.dart:151:int rollWorldSeedFromClock() => DateTime.now().millisecondsSinceEpoch;
```

The one clock read is unchanged from M3S and is the sanctioned unseeded roll. Both
new test files are arrange/act/assert throughout, one of each per test:

```
packages/core/test/town/suspend_run_test.dart: 13 arrange / 13 act / 13 assert / 13 tests
packages/app/test/widget/suspend_door_test.dart: 13 arrange / 13 act / 13 assert / 13 tests
```

## 9. AVD acceptance on `Pixel_10`

Pinned to `emulator-5554` throughout. **No physical device was attached** —
`adb devices -l` listed nothing before the emulator was launched, and
`emulator -list-avds` printed only `Pixel_10`. Debug APK installed with
`adb -s emulator-5554 install -r`, storage cleared with `pm clear` at the start,
killed between relaunches with `am force-stop`, every tap sent with
`adb -s emulator-5554 shell input tap`. Screen `1080x2424`. 53 screenshots in
`docs/epic/m3-leave-shots/`.

| Definition-of-done item | Shot | What it shows |
|---|---|---|
| Platform back button in the crawl | `03` | Declined, log reads `You can only leave at the stairs.` |
| Leave at the stairs on device | `14`, `17` | `Descend >` and `Leave` on the landing; pressing Leave lands in town at `Health 12 / 20` — the wound came home, nothing healed |
| The town door forks | `17` | `Resume the crawl (depth 2)` and `Delve anew` replace `Enter Dungeon` |
| App-kill mid-crawl → the crawl | `15`, `16` | `inside: true` on disk; relaunch opens `Depth 2/5` with `The crawl resumes.` — unchanged behaviour |
| App-kill while camped → town, camp intact | `18` | `inside: false` with the run block present; relaunch opens the town with the fork |
| Shop while camped | `19`–`24` | Sold two potions, bought one back at the price paid; the camp survived every transaction |
| Inn while camped | `26`, `27` | Rested 12/20 → 20/20 for 12 gold; the camp's own hero stayed at 12 hp |
| Resume, verify depth and position | `29` | `Depth 2/5`, `20 / 20` — the inn heal flowed in — position `(3,3)` and `rngState` unchanged |
| Delve-anew confirmation | `34`, `35` | The question names depth 2 and what is not lost; `Keep the crawl` leaves the camp at depth 2 |
| Delve anew confirmed | `36` | Fresh `Depth 1/5`, run visit `1 → 2`, gold and gear carried in, empty log |
| Die → camp cleared, penalty as today | `46`, `47`, `48` | `You died.`; after `Return to town` the disk has `run: null`, `inside: false`, pack burned, carried gold `10 → 0`, worn `mainHand` kept, woken at `20 / 20` |
| Greyscale | `g1`–`g5` | Town fork, delve dialog, stairs controls, merchant while camped, town after death |

The document on disk was read back at each step with
`adb -s emulator-5554 shell run-as com.example.residuum_app cat …/app_flutter/save.json`.
Two pasted states, before and after pressing Leave:

```
inside: True
run depth: 2   run visit: 1
profile visit: 0   profile hp: 20   run hero hp: 12
```

```
inside: False
run present: True  depth: 2  visit: 1
run hero pos: (3, 3)
profile visit: 1  profile hp: 12
run rngState: -1755059432890562300
```

The second is the whole unit in six lines: the hero came home wounded, the crawl
stayed where it was, and `profile visit` became equal to `run visit` — the
invariant `resumeRun` needs, established by the act of leaving.

**Greyscale verdict.** All five changed screens read. On the town the two dungeon
doors are told apart by their words and by a number (`Resume the crawl (depth 2)`
against `Delve anew`), separated from the shop doors by a gap. The delve-anew
dialog is a sentence, and its two answers are the outcomes in words — `Keep the
crawl` and `Give it up` — never Yes and No. On the merchant the three lists are
told apart by their headings and their fixed order, rarity is a glyph (`·`, `※`),
and a price the purse cannot cover is a dim button, which survives the conversion
as value contrast rather than hue.

**One setup step was not ordinary play, and it is small.** To reach the death
with a bounded number of taps I force-stopped the app and edited the real save
file twice: once to emulate pressing Leave (copying the run's carry set into the
profile exactly as `suspendRun` does, plus a wound), and once to set the hero to
1 hit point and place a dire wolf on the walkable tile beside them. Both are
states ordinary play produces; what was authored is the *situation*, and the
death, the overlay, the penalty and the clearing of the camp are all real play
through the real code path. Everything else in the table above was played.

## 10. What the tests cannot prove

- **The defect in section 11 item 1 was found by the device pass, not by any
  test.** That is the most important line in this report. 895 tests were green,
  the mutation table was complete, and a hero who walked out of a resumed crawl
  still got their purchase resurrected. Two bloc tests now cover it and two
  mutation rows pin it, but nothing in the suite pointed at it first — a person
  pressing buttons did.
- **Look and feel.** Golden images are forbidden, so nothing asserts layout,
  spacing, or legibility at a real font scale. The widget tests did catch a
  hard layout failure — the fork overflowed a 600-pixel column by 45 pixels —
  but only because overflow throws. A screen that merely read badly would pass.
- **A real disk.** Every save test uses `MemorySaveFiles`. The AVD run exercised
  the real `IoSaveFiles` path, but only in the happy case.
- **The write race.** Still the open hazard M3H recorded: with a map for a disk
  every write completes effectively instantly, so no test forces the interleaving
  that would lose a switch. Follow-up 21 (a stallable fake save-files) is what
  would pin it, and it is still not this unit.
- **Repeated in-session cycles beyond two.** The write count was measured over
  two full leave-and-resume cycles (six documents for six changes). Nothing says
  the twentieth cycle behaves the same, though rows 18 and 19 explain *why* it
  does: the identity skip, not the closing of blocs, is what makes a stale
  subscription harmless.
- **`resumeRun`'s hero choice.** Taking the position from the suspended block
  rather than the profile is guarded by exactly one test, because today nothing
  in town moves a hero. It is a guard against a future change, and row 9 is the
  proof that it is a guard at all.
- **The gold carry in both doors is unobservable.** See section 11 item 3.
- **Two heroes camped at once.** The document supports it and the codec
  round-trips it, but no device run had two camped heroes, because switching
  away from a camped hero and back is several minutes of tapping.

## 11. Every spec claim I checked and found wrong

1. **"`RunSuspended` … clears the merchant visit block (the visit id changed)."**
   Wrong in half the cases, and destructively so. The visit changes only when the
   hero entered by the door that bumps it. Resuming bumps nothing, so a hero who
   walks back into a camp and out again comes home to the same shelf with the
   record of it wiped — `merchantStock(worldSeed, visit)` rolls the identical
   shelf and the purchase is for sale again while it sits in the pack. Measured
   on the device: bought `market-1-gear-1`, resumed, left, and the merchant
   screen showed `Common Iron Helm  Buy 8` under FOR SALE with
   `Common Iron Helm  Sell 4` under YOUR PACK (shot `31`). Buying it twice would
   put two rows under one id, where M3H established that a sale pays for one and
   destroys both. Fixed in `3a0c890`, pre-declared, accepted as **D36**. Rows 20
   and 21 pin both halves.
2. **"Carries … hp, equipment, skills, inventory, gold, visit."** The carry is
   the whole `Actor`, not hp: `endRun` does `hero: state.hero`, so position and
   energy come home too and always have. `suspendRun` copies the same six fields
   for exactness; `resumeRun` therefore injects
   `suspended.hero.copyWith(hp: profile.hero.hp)`. Verified by the architect at
   `run_boundary.dart:90-96`.
3. **Mutation row 2's expected red is unreachable.** The spec expects "core carry
   test" to redden when `suspendRun` stops carrying gold. It cannot, and the
   reason is a finding in its own right: **a run's gold is always exactly what
   walked in.** `GameState.copyWith` has no gold parameter, and `gold` appears
   nowhere in `engine/`, `dungeon/`, `loot/` or `skills/` except as a field and a
   passthrough. So `gold: state.gold` in both `endRun` and `suspendRun` is
   correct, defensive, and unobservable in any reachable state. The row does go
   red — through the identity theorem and the `resumeRun` tests, where a
   synthesized `deepRun` has a gold that differs from its profile's — but never
   through a carry test. My own carry test passed the row by arithmetic at first
   (fixture gold was zero); strengthened in `f45dbd5` and reported rather than
   quietly fixed.
4. **`GameState.copyWith` has no gold slot**, so `resumeRun` constructs a full
   `GameState`. Pre-declared; verified by the architect at `:170`/`:202`.
5. **The identity theorem is feasible, and for a reason worth writing down.**
   `encodeEquipment` and `encodeSkills` iterate `EquipSlot.values` and
   `SkillId.values`, so map insertion order cannot leak into the bytes. Only
   `inventory` is order-bearing, and it is copied wholesale.
6. **`resumeRun` carries the generators by reference**, exactly as `copyWith`
   does and for the documented reason. A theorem test that plays the original
   crawl before the resumed one therefore has to build the crawl twice — the
   first play advances the very stream the second is about to draw from. Caught
   by the theorem going red on its first run; the reason is recorded in the test
   file so the next reader does not diagnose it as a broken resume.
7. **The visit invariant has no violating path**, checked rather than assumed.
   Town transactions never touch the visit; delve-anew clears the camp in the
   same emission that bumps it; a hero switch moves profile, run and visit as one
   entry. My own widget fixtures violated it before I noticed, which is how I
   learned it is load-bearing: delve-anew's reshuffle counts from
   `profile.visit`, so a hand-built camp with a stale profile visit made a fresh
   delve fail to bump. The fixture helper now builds camps through `suspendRun`.
8. **The autosaver transition claim, measured rather than predicted.** The spec
   allows "either value for at most one emission". With `inside` read off the
   town's two crawl fields there is no wrong window at all: every one of the six
   transitions — enter, leave, resume, delve anew, death, transaction while
   camped — writes the correct pair on its own emission. Rows 11 and 12 are the
   pins.
9. **The stacked-writer hazard is real but already neutralised, and not by what
   the recon supposed.** The recon points at `close()` clearing subscriptions
   wholesale. Rows 18 and 19 show the actual mechanism: a second listener on the
   same bloc is suppressed by the `state.game == _run` identity skip, because the
   first has already updated `_run`. Removing the skip alone does not double-write
   either; only removing both does. Measured: two full leave-and-resume cycles
   produce **6 documents for 6 changes**.
10. **Row 16 is a weak row, flagged not hidden.** Making `RunSuspended` call
    `endRun(died: false)` instead of `suspendRun` reddens nothing anywhere,
    because the spec is right that the two carry identical sets — they are the
    same six lines. Nothing at the bloc layer can tell the doors apart, and that
    is correct: the whole difference is what *else* the handler does, which rows
    3 and 7 pin.
11. **The town screen overflowed once the door forked** — 45 pixels on a
    600-pixel column, thrown by the rendering library and caught by the new
    widget test. The column now scrolls when it does not fit and keeps the doors
    at the bottom when it does. Not in the spec; a door a player cannot reach is
    a door that is not there.
12. **Delve-anew carries the merchant block forward while bumping the visit**,
    and that is left alone on purpose. It is exactly what `EnterDungeonPressed`
    has always done, and coming home always clears when the visit moved, so the
    stale block is never readable by a player. Making delve-anew differ from the
    entering door for no observable gain would be the worse choice.

## 12. Which execution phases ran, and which were skipped

Ran: recon reading (spec, recon, build prompt and every file they name, read in
full); a written plan via the `writing-plans` skill, committed at
`docs/superpowers/plans/2026-08-22-m3l-leave.md`; pre-declaration of nine shape
items and two spec corrections to the architect **before any code**, all
approved; strict test-first execution of twelve commits; the 21-row mutation
table against committed code; the AVD acceptance; a second pre-declaration
mid-flight when the device run found a defect; this report.

**Skipped: per-task reviewer subagents.** The build prompt permits the skip and
asks for the argument. The D9 precedent is that the mutation table carries the
adversarial load, and it did: 21 rows ran, thirteen of them extensions I added
where I thought the spec's eight were blind, and three of those thirteen (rows
10, 15, 18) changed the code or the tests. But the honest addition this unit
makes to that precedent is that **the table was not enough**. The defect in
section 11 item 1 survived 895 green tests and a complete table, and only the
device pass found it — because it needed a sequence no test author had thought
to write down. A reading reviewer would not have found it either; what found it
was pressing the buttons in an order the spec did not anticipate. That is an
argument for keeping the AVD pass mandatory, not for adding reviewers.

Also skipped: `superpowers:brainstorming`, because the design was settled in
ledger entries D34 and D35 and written into the spec; there was nothing to
explore, only shape to pre-declare and two claims to correct.

## 13. Deleted tests

**None.** No test was deleted or weakened in this unit. Two existing widget
fixtures changed meaning rather than being removed — `boot_wiring_test.dart`'s
crawl document and `roster_session_test.dart`'s Ilse both now say `inside: true`,
which is what they always meant (a hero killed mid-crawl), and each gained a
camped counterpart beside it so the pair pins both answers. One existing test was
strengthened, not weakened (`f45dbd5`, section 11 item 3).

## Follow-ups to log

- Hero rename after creation (carried from M3H).
- Roster ordering, most-recently-played first (carried from M3H).
- A way out of a crawl that suspends rather than ends it — **resolved by this
  unit.** M3H recorded that switching to a suspended hero had no in-game route
  to it; the stairs `Leave` control is that route, and shot `18` is a camped hero
  reached by ordinary play.
- Follow-up 19, the message log dropping on resume: now highly visible, since an
  in-session resume shows `The crawl resumes.` on every return. Left alone as the
  recorded design choice, and the boot notice is no longer repeated on every
  resume (it is a fact about the launch, said once).
- Follow-up 20 restated: no version bump here, and **the first shipped build
  freezes v1.**
- Follow-up 21, a stallable fake save-files, still open and still the only way to
  pin the close-before-rebuild await.
- **New:** the interim inn-heal easing is now reachable and was exercised on the
  device — suspend, rest for 12 gold, resume at full health, with no travel cost
  and no risk. Accepted per D34; M3W's travel days are what price it.
- **New:** nothing bounds the sold-back list within a visit, and a camped hero can
  now shop repeatedly without the visit ever rolling over. It still clears when
  the visit moves, so it cannot grow without bound, but the ceiling is higher
  than it was before this unit.
- **New (D36 consequence):** the merchant visit block is valid exactly as long as
  the visit is. Every future door between town and dungeon must answer whether it
  moved the visit. M3W's travel doors are the next place this class would bite.
