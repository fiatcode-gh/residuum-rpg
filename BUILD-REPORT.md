# Build report — unit `m3-world`, story M3W "The overworld"

Every count, line of output and identifier below is pasted from a command run
in this session. Nothing is typed from memory.

## 1. Where the work is

```
$ pwd
/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-world

$ git log --oneline main..m3-world
ebe3802 fix: say Move on, because the fuller wording ellipsised to nonsense
d112d4f fix: give a journey a way to carry on after the app was killed on it
5cadaa6 fix: give the way out of a road fight a control, because a tap cannot say it
ed1ac5c test: pin what a road fight leaves behind and what it hands over
832bbd9 test: tell waking at home apart from waking where you set out
b70d7de feat: the world is the screen the game opens on
04899ae feat: the save document says where in the world the hero is
d2ab28a feat: each town keeps its own shelf, and the ids say whose
02887af feat: two towns, a crypt, and roads with something on them
ca1d25c feat: open ground to be ambushed on, and an edge to run off
8999939 docs: say why the day counter and the leg are two numbers
9abf403 docs: mirror the M3W build report as it stands at the pause
b4aafc5 feat: a world to walk around in, in days
b71f911 test: pin the crypt, the boot fork and the shelf before the world arrives
```

Branch `m3-world`, base `844376f`. The parent repository received nothing.

## 2. C1–C3 against UNMODIFIED code — commit `b71f911`

All three sets were written and run against the tree as it stood at `844376f`,
before a single production file was touched.

Baseline first, measured here:

```
core     00:02 +408: All tests passed!
content  00:05 +225: All tests passed!
app      00:10 +264: All tests passed!
```

408 + 225 + 264 = **897**, matching the architect's figure exactly.
`flutter analyze`: `No issues found! (ran in 3.7s)`.

Then with C1–C3 added, still no production change:

```
core     00:01 +413: All tests passed!     (408 + 5 from C1)
content  00:05 +234: All tests passed!     (225 + 6 from C2 + 3 from C3)
app      00:05 +264: All tests passed!     (unchanged)
```

- **C1** `core/test/dungeon/generator_characterization_test.dart`. The generator
  tests that existed checked that one seed builds the same floor *twice* — a
  statement about determinism, not about *which* floor, so a change that moved
  every layout in the game would have kept all of them green. C1 adds byte
  literals pasted from real `generateFloor` output (seed 90210 depth 2, seed 7
  depth 4), the hero/stairs/monster placements, and widens the border sweep from
  5 floors to 2000.
- **C2** `content/test/save/world_characterization_test.dart`. The M3L boot fork
  pinned at the *document* rather than at the screen, so the navigation rework
  could not move it.
- **C3** `content/test/merchant_shelf_characterization_test.dart`. Today's shelf
  for three fixed `(worldSeed, visit)` pairs, in ids and display names.

**C3's re-pin** rode the salt commit `d2ab28a`, with the old shelf written out in
full in the test's own dartdoc — same table, same weights, same number of draws,
one more term in the seed. The commit argues it.

## 3. All three suites, and the baseline

| suite | baseline @ `844376f` | now | delta |
|---|---|---|---|
| core | 408 | **515** | +107 |
| content | 225 | **300** | +75 |
| app | 264 | **338** | +74 |
| **total** | **897** | **1153** | **+256** |

```
core     00:02 +515: All tests passed!
content  00:05 +300: All tests passed!
app      00:08 +338: All tests passed!
```

### Per-file relocation audit (owed to the architect)

The unit retires the town's Enter Dungeon door, moves the M3L fork to the crypt
node, and lands boot on the world screen. Name-level diff of every file whose
assertions pressed that surface:

| file | tests before | tests after | removed | renamed | added |
|---|---|---|---|---|---|
| `widget/suspend_door_test.dart` | 13 | 15 | **0** | 0 | 2 |
| `widget/boot_wiring_test.dart` | 4 | 4 | **0** | 2 | 0 |
| `widget/roster_session_test.dart` | 9 | 9 | **0** | 0 | 0 |
| `town_bloc_test.dart` | 57 | 68 | **0** | 0 | 11 |

**No assertion was dropped.** The two renames are in `boot_wiring_test.dart`,
where "opens in the town" became "opens on the world" — the same fact, at its
new landing. Every other test kept its exact name, which is what makes it a
relocation rather than a rewrite.

## 4. Survivability — EXACTLY unchanged

Re-measured after every commit that could have touched a draw order. The final
run:

```
greedy build: 24/40 won; fleetfoot-first build: 7/40 won
survivability: 24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24
```

## 5. analyze and format

```
$ flutter analyze
No issues found! (ran in 2.8s)

$ dart format .
Formatted 138 files (0 changed)
```

Clean at every commit, not only at the end.

## 6. The mutation table

Run on COMMITTED code. Each row was applied, the affected suites run, the
failing test names recorded, and the edit reverted with `git checkout --`.

| # | Mutation | Result | What reddened |
|---|---|---|---|
| 1 | `beginTravel` ignores the discovered gate | **RED** | core `travel_test`: *a place the hero has not heard of is refused*; app `world_bloc_test`: *…refused in the rules own words*. Arrival-adjacency tests stayed green (the control). |
| 2 | travel day forgets `day++` | **RED** | core 9 tests (day-advance, arrival, traveler, determinism, *the day walked is the day rolled*); app 16 (walk-completes, journey-written-down, fight rows). |
| 3 | encounter chance short-circuited to quiet | **RED** | core 5 (*a named world and day is a fight, every time it is asked*, fight-costs-the-day, two-days-decided-apart); app 10. Quiet-day test stayed green. |
| 4 | `Fled` branch dropped | **RED** | core `step_flee_test`: *is fleeing, in every direction there is*, *costs no turn at all*; app: *pressing it closes the fight*. **Crypt border tests stayed green** — the control the spec predicted. |
| 5 | encounter-mode default flipped true | **PARTLY WEAK — see below** | core **GREEN**, content **GREEN**, app **RED (8)**. |
| 6 | arrival adjacency-reveal dropped | **RED** | core `whereabouts_test` + `travel_test`; app `world_bloc_test`. Rumor tests green. |
| 7 | tavern rumor may reveal a discovered node | **RED** | core 3, content 1 (*once the map is uncovered there is nothing left to sell*), app 1. |
| 8 | town salt dropped from `merchantStock` | **RED** | content 7 (all four C3 pins + all three shelves-differ tests); app 1 (*the other town is holding different things*). Survivability stayed green — the shelf is not a balance lever. |
| 9 | merchant block survives a town change | **RED** | app 3: *the other town forgets what this one remembered*, *a bought item stays bought while the hero is away and back*, *what one town remembers the other one does not*. The same-town keep test stayed green — the D36 pair's other half. |
| 10 | road death wakes at the current node | **GREEN, then RED — a real hole** | See below. |
| 11 | codec defaults a missing world block | **RED** | content: *a document without one is refused by name*. Goldens green (they carry it). |
| 12 | en-route legs encoded, decoder reads `at` only | **RED** | content 5 (incl. the two-hero golden); app 3. |

### Row 5 is *less* weak than the spec predicted — and that is the finding

The spec expected "nothing reddens via crawls". Core and content are indeed
**GREEN**, which is the proof it wanted: the flee branch is unreachable from a
crawl, because no crawling hero can stand on the grid edge (2000 floors swept,
zero leaks). But the **app reddened on 8 tests**, and for a reason worth
recording: the field is not invisible to the interface. It decides whether the
readout says `Depth 1/5` or `The road`, and which sentence the back button
refuses with. So:

> The flee **rule** is inert in a crawl and the crypt suite proves it. The
> **field** is not silent — flipping it is caught by the interface even though
> the rules cannot reach it.

That is a stronger position than the spec assumed, and it means the default
cannot be flipped unnoticed.

### Row 10 found a genuine gap in my own tests

Applied to committed code, row 10 came back **GREEN**. The reason: a travelling
hero's `at` is the *origin of the leg*, and every journey my tests walked began
at a town — which was also `home`. Both answers named the same node, so the
assertion could not see the difference.

The crypt is the one place a hero can set out from that is not a town, so a
journey beginning there is the only one where the two are different nodes. Fixed
in `832bbd9`; both tests now also assert the two wrong candidates are *not* the
answer. Re-run:

```
=== ROW 10 (re-run after the fix): road death wakes at the current node
   app      RED (2):
      - world_bloc_test.dart: ... dying wakes the hero at the town they slept in, not where they set out
      - world_screen_test.dart: ... dying wakes the hero at home, stripped of what they carried
```

### Extensions (9 rows) — two more holes found

| # | Mutation | Result | What reddened |
|---|---|---|---|
| E1 | **Rider 2**: road wrapper bumps the visit | **RED** | content: *does not bump the visit*; app: *never moves the visit, so a camp stays resumable*. (The app half was green until `ed1ac5c` added it.) |
| E2 | **Rider 1**: autosaver watches the road fight | **RED** | app: *writes nothing at all to disk while it is in flight*. Ruling 4 is a red test, not a comment. |
| E3 | encounter ground may wall its own border | **RED** (goldens only) | The *validator* caught it and the bounded retry re-rolled — which is the safety net working. Only the golden layouts moved. |
| E3b | …and the border check removed from the validator too | **RED** | *catches a wall sitting on the way out* + both goldens. The validator is load-bearing, not decorative. |
| E4 | hero may land on the edge | **RED** | core 4 (*never within a step or two of the way out*, the validator's own test, both goldens); content 1. |
| E5 | `roadSeed` ignores the day | **RED** | core 2 (two-days-decided-apart, day-walked-is-day-rolled); app 3. |
| E6 | discovered set encoded in reverse | **RED** | content 5 — all three golden encoders plus the roster key-order test. |
| E7 | world screen reads the camp once instead of watching it | **RED** | app: *the town then offers going back down, at the depth left*. This is the defect I actually hit while building; the row proves the fix is pinned. |
| E8 | death on the road burns the camp | **GREEN, then RED** | Nothing asserted decision 6b. Fixed in `ed1ac5c`; now reddens 3 tests. |
| E9 | road drop table keyed where nothing looks | **GREEN, then RED** | Nothing asserted a road kill drops *anything*. Fixed in `ed1ac5c`; now reddens *is sometimes something*. |

Three rows (10, E8, E9) found real gaps. All three are fixed and re-run red.

## 7. Diff scope

```
$ git diff main --name-only -- packages/core/lib
packages/core/lib/core.dart
packages/core/lib/src/dungeon/encounter_map.dart
packages/core/lib/src/engine/event.dart
packages/core/lib/src/engine/game_state.dart
packages/core/lib/src/engine/step.dart
packages/core/lib/src/world/node.dart
packages/core/lib/src/world/rumor.dart
packages/core/lib/src/world/travel.dart
packages/core/lib/src/world/whereabouts.dart
packages/core/lib/src/world/world_map.dart
```

Exactly the sanctioned list: `world/`, `dungeon/encounter_map.dart`, the flee
rule in `engine/`, and `core.dart` exports.

```
$ git diff main --numstat -- packages/core/lib/src/engine/step.dart
18	0	packages/core/lib/src/engine/step.dart
```

Eighteen lines added, none removed: one branch in the body and one documented
predicate. `step.dart` gained the flee rule and nothing else.

Forbidden files — `git diff main --name-only` over `spawn_tables`, `drop_tables`,
`bestiary`, `armory`, `affix_pool`, `new_game`, `generator.dart`,
`generator_test.dart`, `generator_items_test.dart`, and every `pubspec`:

```
(empty)
```

`new_game.dart` is byte-untouched, so `floorSeed`, `buildFloor`,
`residuumDungeon` and `startDungeonRun` are too. No pubspec change; no new
dependency; no save-version bump.

## 8. Hygiene

```
=== real body comments (// not ///) in 29 changed production files ===
(empty)
=== trailing // comments in changed production files ===
(empty)
=== unseeded Random( in core/content lib ===
(none)
=== rumor synonyms (gossip|hearsay|scuttlebutt|whisper) ===
(none)
=== British 'rumour' anywhere ===
(none)
```

Arrange/act/assert: every new test file has `// assert` on every test. `//
arrange` is absent only where there is nothing to set up (a pure-function test
over a literal), and `// act` only where the assertion *is* the act.

**Language note:** `rumor` and `traveler` are spelled as the spec spells them,
against the codebase's British `armour`/`colour`. The spec is binding on its own
nouns; existing words are untouched.

## 9. AVD acceptance — `Pixel_10`, pinned to `emulator-5554`

`adb devices -l` showed one device, `emulator-5554`; **no physical phone was
attached at any point**, and every command was pinned to the emulator serial.

Saves were pushed as real documents produced by the shipped `encodeSave`, not
hand-written, via `run-as com.example.residuum_app`. 26 screenshots plus 6
greyscale conversions are in
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-world-shots/`
(gitignored, durable, outside the worktree).

| # | Definition-of-done item | Shot | Result |
|---|---|---|---|
| 1 | boot to world | `01-boot-world` | `RESIDUUM` / `At Stonebridge` / `Day 0.`; `[T]`, `(D)`, `[?]` all present |
| 2 | town is a pushed screen, five doors | `03-town-five-doors` | titled `Stonebridge`, back arrow, Merchant/Bank/Inn/Gear/**Tavern**; no Enter Dungeon, no Heroes |
| 3 | tavern rumor reveals the second town | `05`,`06`,`07` | `Ask 15` → gold 400→**385**, `[?]` row becomes `[T] Northgate`, rumor line in the log |
| 4 | platform back button | `07` | two `keyevent 4` presses walked tavern→town→world |
| 5 | travel is confirmed before a day is spent | `08-travel-confirm` | `Walk to The Crypt?` / `One day on the road…` / Stay here / Set out |
| 6 | a combat encounter on the road | `09-road-fight` | opened over the world; readout says **`The road`**, not a depth; no stairs controls |
| 7 | **flee by edge** | `10`,`11` | `Flee` appears only at the edge; walking out cost **20→12 HP**; returned to the world, journey intact |
| 8 | a cleared fight | `24`,`25` | `Move on` appears when the ground is clear; log *The road is yours again.* |
| 9 | the fight costs the day and none of the distance | `11`,`25` | log reads, bottom-up: set out → *Day 1. Something comes out of the scrub.* → got away → *Day 2. …You reach The Crypt.* — **D40 visible in play** |
| 10 | death on the road wakes at home with the penalty | `19`,`20` | overlay button says **`Wake at home`**; woke at **Stonebridge** having set out from **the crypt**; carried 250→**0**, banked **75 kept**, health restored |
| 11 | camp fork at the crypt node | `12`,`13`,`14` | `Resume the crawl (depth 3)` + `Delve anew`; the M3L confirmation verbatim; resume lands at depth 3 |
| 12 | both towns' shelves visibly different | `21`,`23` | world 909 Stonebridge: *Rare Sturdy Reinforced Leather Cap*, *Common Kite Shield*. Northgate: *Fine Maul of Fury*, *Common Iron Sword*. **Both match the C3 unit pins exactly.** |
| 13 | app-kill en route → journey resumes | `16` | `On the road to Northgate` / `Day 7. 2 days still to walk.` |
| 14 | app-kill mid-crawl → crawl (regression) | `15` | boots into the crawl, `Depth 1/5`, *The crawl resumes.* |
| 15 | greyscale reading of every changed screen | `grey/` | see below |

### Greyscale

Six changed screens converted with `magick -colorspace Gray`. Every distinction
survives: `[T]` / `(D)` / `[?]` are bracket shapes plus a letter; "— you are
here" is a phrase; a disabled control reads `Here` / `Unknown` as a word as well
as being darker; rarity markings are `·` / `+` / `++`; on the fight screen the
hero, wolf and rat are told apart by glyph (`@`, `w`, `r`) rather than hue.

### The AVD pass found three defects that every test had missed

This is the section the pass exists for.

1. **The flee rule was unreachable by touch** (`5cadaa6`). Fleeing is a step off
   the edge; movement is tapping a tile; `GridGeometry.positionAt` returns null
   for any offset outside the grid. There is no tile to tap on the far side of an
   edge, so no player could ever flee. Twelve core tests and one app test were
   green — and the app test dispatched `TileTapped(Position(-1, 5))`, a value the
   real tap handler *cannot produce*. It was a false green about something
   nobody could do. Fixed with a `Flee` control offered on the outermost ring,
   which keeps the price the hero-inset exists to charge; the rule in `step` is
   untouched. The false-green test is gone, replaced by five that press a real
   control from all four edges and check it is absent inland, in a crawl, and
   for a dead hero.
2. **A journey could not be continued after an app-kill** (`d112d4f`). The world
   block restored correctly, and then nothing walked the hero: every Walk button
   is refused while travelling, so the screen offered no way forward at all. A
   `Walk on` control now appears exactly when the hero is on a road and nothing
   is walking them — a press rather than automatic, because continuing by itself
   would spend days the instant the app opened.
3. **Two wording flaws** (`5cadaa6`, `ebe3802`). The travel dialog opened with a
   lowercase `one day on the road.`; and `Back to the road` ellipsised to
   `Back to the ro…` with three controls sharing the row — now `Move on`.

## 10. What the tests cannot prove

- **Whether the road's pricing is any good.** Fifteen, twenty-five and thirty per
  day, one and two-day roads, and a four-day round trip to the second shelf are
  numbers with arguments behind them, not measurements. The survivability bot
  never travels, so the pin is blind to the road exactly as it is blind to the
  inn (recon finding 12). A road-survivability instrument is logged as a
  follow-up.
- **Whether an ambush is winnable often enough to be worth standing for.** I
  cleared one on the emulator with a strong hand-built hero and fled another at
  8 HP. Two data points are an anecdote.
- **Whether discovery feels like discovery** with exactly one place to find. The
  `[?]` row makes the tavern legible; whether one hidden town is enough of a
  world is a judgement the second and third dungeons (M3D) will settle.
- **Flow-field and field-of-view cost on open ground.** The recon flagged this as
  unmeasured and it still is. The encounter map is 15x11, which is smaller than
  every crawl floor, so the risk is low — but low is not measured.
- **Any device but this one.** One emulator, one API level, one screen size. The
  three-control row that ellipsised is exactly the class of thing a narrower
  screen breaks again.
- **Real play.** Every acceptance run above was driven by `adb input tap` against
  saves I wrote. Nobody has played this for fun.

## 11. Spec claims checked, and what was wrong

| Claim | Verdict |
|---|---|
| "Baseline 897 stays green" | **SPEC DEFECT**, owned by the architect. The unit is *required* to retire the surface ~20 widget tests press. Ruling: it meant no behaviour regresses and no assertion is dropped. The audit in section 3 discharges it. |
| The one-pop-home shape survives the reshape | **TRUE.** `leaveDungeon`/`suspendDungeon` read `TownBloc` off the crawl route's own provider, not by inheritance, so they needed no change at all. |
| The navigation rework is otherwise safe | **NO — worker-found defect.** A generation bump swaps the route under `home:` but does not clear routes pushed on top of it, so a roster reached through a pushed town would leave the new hero's world under the old hero's route holding closed blocs. Fix approved: Heroes moved to the world screen. Invariant stated at `_rosterChose`, pinned by a widget test. |
| The flee rule is inert in crawls because the border is solid | **TRUE and structural**, verified 2000 floors / 0 leaks — but see row 5: inert in the *rules*, not invisible to the *interface*. |
| "Flee by stepping off any map edge" is reachable | **NO — see section 9, defect 1.** A tap cannot express an off-grid position. The rule was right and unusable. |
| `(worldSeed ^ travelSalt, day)` might correlate floors with road encounters | **NO.** All four seed families — travel days, ambush ground, ambush fight, crypt floors — proved pairwise disjoint over 2000 days and 2000 visits across eight world seeds, in a committed content test. |
| C3 has an indirectly-pinned shelf somewhere | **YES**, and it would have rotted silently: `town_bloc_test.dart:181` asserted `isNot(contains('market-0-potion-1'))`, and once ids carry a town that id stops existing, so the assertion would have passed by naming nothing. Re-pinned to a real id *and* given a positive half. |

## 12. Which execution phases ran

Written plan → C1–C3 characterization against unmodified code → strict red/green
per unit of behaviour → mutation table on committed code with extensions → AVD
acceptance → this report. Every commit's exit state was green, analyze-clean and
format-clean.

**Skipped: write-capable subagents.** The D9 precedent, argued rather than
assumed — a subagent that needs a permission nobody is present to grant stalls
silently, and the mutation table plus the AVD pass carry the adversarial load
better than a reviewer reading a diff would. Between them they found six real
defects (three test gaps, three interface defects), which is the evidence for the
choice rather than a claim about it.

## 13. Decisions recorded

Nine shape decisions were pre-declared before any code and all nine approved;
two riders came back and both are discharged (E1, E2). Two further decisions were
raised at the pause and locked as **D40**: a road fight costs the day and none of
the distance, and `beginTravel` refuses a discovered-but-non-adjacent
destination. Both arguments now live in the dartdoc of each half of the pair
they constrain.

Custody, as declared: `TownBloc` is the single home of `Profile`; `WorldBloc` is
the single home of `Whereabouts`. The one transaction that moves both — a rumor
bought with coin — is one core function returning both halves, dispatched to its
two owners in one synchronous pair.

## 14. Follow-ups logged, not done

- Caravan and shrine encounter mechanics (deferred by the spec).
- A road-survivability instrument, per section 10.
- M3D: per-node floor salts, dungeon identity in the run block, themed
  bestiaries and palettes, light bottom-floor bosses and guaranteed rares.
- The three-control row on the road is one word from ellipsising again on a
  narrower screen; a wrapping or two-row control strip would end the class.
- Old documents without a `world` block demote to the corrupt fallback and then
  a fresh hero. Acceptable while unshipped, and stated here because it is the
  one migration this reshape does not do.
