# BUILD-REPORT — unit m3-fixes (M3F)

Branch `m3-fixes, five commits over base `54ec315, HEAD
`5dcfaa63f018237068a0d1545900421c7b6ce0ca`. Mirror of the build prompt's
section 10 verification block.

**Three worker sessions ran this unit.** Every measurement below is attributed
to the session that actually ran it. Sessions 1 and 2 were pi sessions (worker
entries 1-2 and entry 3); session 3 is this Claude Code session (worker entry
4). Sessions 1 and 2 ended on breakage and quota respectively, not on failure
of the work.

- **S1** — worker entries 1-2: baseline, C1 on the true base, the five commits.
- **S2** — worker entry 3: re-derived counts, the whole mutation table, static
  verification, the AVD install and save ritual.
- **S3** — worker entry 4 (this session): counts and band lines re-derived
  again from result files, static verification re-run, the AVD tail (device
  verification, screenshots, save restore), this report.

## 1. The work happened in the worktree, and the commits are not on main

`pwd` = `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-fixes`

```
$ git log --oneline main..m3-fixes
5dcfaa6 feat: the town Gear door becomes a Character menu
05a2296 fix: remembered gathering nodes stay on the map
be428a1 test: pin remembered-terrain paint through the glyph plan
1920a86 refactor: extract the glyph paint plan from the painter
1ae269a fix: road fights carry the profile's magic and materials

$ git status --porcelain
?? .pi/
```

The only untracked entry is the pi session directory, deliberately left and
never staged. Nothing under `docs/epic/, `docs/reports/` or `docs/plans/` is
tracked in any of the five commits (S1, every commit staged by explicit path
per D65 ruling E). Measured by S3.

## 2. Characterization tests against the unmodified base

- **C1** — the content group `walking into a road fight, 14 tests, quoted
  passing on `54ec315` **before any change** (S1, worker entry 1). On the final
  code the same group is 17 green: the base 14 plus R1/R2/R3 (S3, below).
- **C2** — could not literally run on `54ec315`: the glyph-plan seam does not
  exist there. Pre-declared as shape deviation B and **approved as ledger
  decision D65-B**, with two bindings: the extraction commit (`1920a86`) lifts
  every loop verbatim, and C2 (`be428a1`) is quoted passing *before* the node
  branch changes (`05a2296`). S1 executed that order; the commit order above is
  the evidence.

## 3. Test counts per suite, from result files, against the 1790 baseline

Baseline measured fresh on `54ec315` by S1 (not inherited from the architect):
**762 core + 530 content + 498 app = 1790 green**.

Final counts on `5dcfaa6, re-derived by **S3** from `--file-reporter=json`
result files, counting non-hidden `testDone` events:

```
core    non-hidden testDone: 762  results: {'success': 762}
content non-hidden testDone: 533  results: {'success': 533}
app     non-hidden testDone: 515  results: {'success': 515}
```

**762 + 533 + 515 = 1810 green, zero failures, +20 over the 1790 baseline.**
The +20: content +3 (R1, R2, R3), app +17 (R4, the glyph-plan characterization
and node reds, and the character-screen widget tests). S3's counts agree
exactly with S2's independent run.

C1 group on the final code, from the same result file: **17 tests, all
success** — the base 14 plus the three road-carry reds.

## 4. The four band lines, byte-identical

The central control was "no band can move". Quoted verbatim from **S3's** own
content run on `5dcfaa6, and byte-compared in-process against the S1 baseline
strings (all four `MATCH`):

```
survivability: 20/40 won (50.0%), stalled 0, died at 1:1 2:6 3:6 4:7 5:20
greedy build: 20/40 won; fleetfoot-first build: 14/40 won
sea-cave: 30/40 won (75.0%), stalled 0, died at 2:1 3:8 4:13 5:9 6:9
ruined keep: 25/40 won (62.5%), stalled 0, died at 1:4 2:5 3:4 4:2 5:13 6:6 7:6
```

No band moved. The fix adds zero rng draws, as the spec claimed.

## 5. The mutation table — all seven rows, greens included

Run by **S2** from the worktree root with `pwd` quoted, tree reverted and
`git status` verified clean between rows, HEAD still `5dcfaa6`. Accepted by the
architect (entry 6) and promoted to **ledger decision D67**, including its
three corrections to the spec's predicted-red columns. **Not re-run by S3** —
the architect's continuation brief 2 explicitly settled it.

| Row | Mutation | Named reds observed | Greens (controls) |
|---|---|---|---|
| M1 | `knownSpells: profile.knownSpells` → `const {}` | R1 "carries the schooling and the gathering home alive", R2 "opens with the magic already in hand", R3 "dying on the road keeps what was learned, burns what was gathered", R4 "brings the spells and the materials home too" | rest of C1 group; all four band lines |
| M2 | `spells: spellsById` → `const {}` | R2 only | R4 stayed green; C1; bands |
| M3 | `materials: profile.materials` → `const {}` | R1, R4 | R3 stayed green; C1; bands |
| M4 | `mana: heroMaxMana(profile.loadout)` → `0` | R2 only | C1; bands |
| M5 | visible-only node loop restored (`sed -z`) | R5b "stays on the remembered map at the remembered opacity" only | R5a, R5c, R5d, R6 (character screen 9/9) |
| M6 | remembered node opacity → `0.0` | R5b only | C2 terrain tests |
| M7 | `packSections(profile.inventory)` → `packSections(const [])` | R6 Carried cluster: "carries the whole pack in the pack four sections", "wears a carried piece through WearPressed", "reads a carried book through ReadBookPressed" | stats/spells/worn/materials/skills tests; all 106 town_bloc tests |

Three corrections to the spec's prediction, measured rather than predicted
(D67): M1 reddens wider than predicted (same root cause — spells never enter
the encounter state); M2 leaves R4 green because R4 asserts only knownSpells
and materials; M3 leaves R3 green because an empty carry already satisfies
death-clears-materials; M5 is insensitive for R5c and R5d because both loop
versions satisfy them.

Two instrument disclosures from S2, both handled before any result entered the
table: the scripted M7 substitution did not compile (`List<Never>` indexed by
`PackSection`) and was replaced with `packSections(const []), same intent —
**accepted by the architect as M7 in entry 6**; and S2's first M5 attempt
omitted `sed -i, so it tested unmutated code — caught because the pass
contradicted a previously watched red, re-run with the mutation verified by
`git diff` first, and no result from the broken attempt entered the table.

## 6. Static verification

**S3's own run**, from the worktree root:

```
$ pwd
/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-fixes
$ dart analyze .
No issues found!
$ dart format --set-exit-if-changed .
Formatted 200 files (0 changed) in 0.46 seconds.   (exit 0)
$ flutter analyze
No issues found! (ran in 2.3s)
```

S2 measured the same three clean, independently.

## 7. The AVD pass

Pinned to `-s emulator-5554` throughout. **No physical phone was attached at
any point** in S3 (`adb devices` listed the emulator alone), so none was
touched.

### The install (S2)

Ritual honored in order: both save slots copied aside **before** any install
(`save.json` 7440 B, `save-previous.json` 7442 B, v3, md5s recorded); free
space checked. The plain install failed with
`INSTALL_FAILED_INSUFFICIENT_STORAGE` (/data 92% full, 485 M free; a cache trim
freed only 6 M). The two other third-party packages on the AVD are the user's
own apps and were **not** touched; instead the old pre-fix residuum build was
uninstalled — its data was the wiped hero the spec already records, and both
save slots were already aside — and the new APK installed (153,590,984 bytes,
matching the ~153 MB trap). Saves restored, md5-verified. Disclosed by S2:
`/data/local/tmp` push plus `run-as cp` fails ENOENT under the app domain
(SELinux-shaped), so the restore streams through `run-as` stdin instead.

### The tail (S3)

No reinstall was needed. The emulator was not running at the start of this
session, so S3 booted `Pixel_10` with the `emulator` binary directly (no
`-wipe-data`), and confirmed the installed build is S2's:
`lastUpdateTime=2026-09-01 15:57:56, `versionCode=1`.

**Before touching the app**, S3 repeated the copy-aside ritual on its own
account — playing the game mutates the save exactly as an install does:

```
device md5   8affb33b8becd2fb877b774a20cc916d  app_flutter/save.json
             89de2d363594b40095a8342f6971be3f  app_flutter/save-previous.json
host copies  8affb33b8becd2fb877b774a20cc916d  save.json      (7440 B)
             89de2d363594b40095a8342f6971be3f  save-previous.json (7442 B)
```

A second durable copy was written to
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/reports/m3-fixes-avd-saves/`
(untracked, never committed) so the slots would survive this session's job
directory being cleaned. The user may delete that directory at will.

**Item 2 verified on device — remembered gathering node.** The restored save
resumes a crawl in The Crypt at depth 2/5. Its `run` holds three gathering
nodes, and exactly one of them is in `explored` but not in `visible`: the
herb patch at grid (2,5) (`oreVein` (22,1) and `oreVein` (14,10) are in
neither set). The herb-patch glyph is `", and `nodeInk` is
`Color(0xFFA87BC0)` = RGB (168,123,192).

Measured from the actual screenshot pixels rather than judged by eye:

- **Remembered** (hero at (5,15), node outside live field of view): the only
  cluster of that hue in the whole frame sits at grid column 2, row 5, and its
  glyph pixels read **RGB (76,59,89)**, 389 px. Predicted composite for
  `rememberedOpacity = 0.4` over the measured background (14,16,20) is
  (75.6, 58.8, 88.8). Zero pixels anywhere in the frame at full `nodeInk`.
- **Visible** (hero walked to the stairs at (4,6), node now in field of view):
  the same glyph at the same screen position reads **full `nodeInk`
  (168,123,192)**, 384 px, with only 29 residual antialiasing pixels at the
  0.4 tone.

Same node, same screen position, two opacities exactly as the fix specifies.
Under the pre-fix build that glyph would not have been drawn at all. The
vertical axis of this floor fits the viewport, so the camera does not scroll —
which is why the before and after frames are pixel-comparable.

Grid position was also confirmed geometrically, independent of colour: the
cell pitch is 95 px, the `<` stairs glyph sits at column 4 row 6, and the `"`
sits two columns left and one row up from it.

**Item 3 verified on device — the Character menu.** Route walked in the app:
killed the engaged giant rat, auto-walked to the stairs, `Leave, walked the
road to Stonebridge (the road was quiet — no encounter fired), `Enter
Stonebridge`. The town door list reads **Merchant, Bank, Inn, Character,
Tavern, Forge, Alchemist** — `Character` where it read `Gear, and no `Gear`
door remains. The screen opens titled `Character` and shows every section in
Pack order:

- stats — Attack 4-6, Armour 0, Dodge 6%, Speed 10, Health 5/20, Mana 4
- Spells — "You have not learned any spell yet." (this hero is unschooled)
- Worn — six `slotLabel` rows, main hand `Common Rusty Sword +2-3 atk` with
  `Take off, the other five `—`
- Carried — all four `packSections` headings present even when empty
  (Weapons, Armour, Potions, Books)
- Materials — Ore 1, Ingot 0, Herb 0, every material shown at zero, each with
  its own marking glyph
- Skills — all nine `SkillId` values with level and XP bar (Arms 2 0/8,
  Might 0 0/4, Bulwark 0 0/4, Fleetfoot 2 5/8, Wrath 0 0/4, Mending 0 0/4,
  Binding 0 0/4, Herbcraft 0 0/4, Blacksmith 0 1/4)

Actions were exercised on device and route through the existing events:
`Take off` on the sword emptied main hand and the stats panel recomputed live
**Attack 4-6 → 2-3**; the sword appeared under Carried → Weapons with a `Wear`
button and the delta line `▲+2 atk min · ▲+3 atk max`; `Wear` put it back and
Attack returned to **4-6**. `ReadBookPressed` could **not** be exercised on
device — this hero carries no book — and remains covered by the widget test
R6c and by mutation row M7, which reddens exactly that assertion.

### Screenshots

In `docs/reports/shots/m3-fixes/` (main-repo path, untracked, never
committed). Every capture has a greyscale variant, and the state each one
shows reads by shape and word in greyscale, never by hue:

```
01-town-doors.png                        (S2)
02-remembered-node.png                   (S3)  remembered node, full frame
02a-remembered-node-zoom.png             (S3)  2x crop, node legible
03-remembered-node-greyscale.png         (S3)
03a-remembered-node-zoom-greyscale.png   (S3)
04-visible-node-control.png              (S3)  same node in field of view
04a-visible-node-control-zoom.png        (S3)
05-visible-node-control-greyscale.png    (S3)
06-town-character-door.png               (S3)  the door reads Character
07-town-character-door-greyscale.png     (S3)
08-character-screen-top.png              (S3)  stats, Spells, Worn, Carried
09-character-screen-bottom.png           (S3)  Carried, Materials, Skills
10-character-screen-top-greyscale.png    (S3)
11-character-screen-bottom-greyscale.png (S3)
12-character-takeoff-then-wear.png       (S3)  sword in Carried with Wear
13-character-takeoff-then-wear-greyscale.png (S3)
```

### Saves restored

App force-stopped first so no autosave could race the restore. Restored by
streaming through `run-as` stdin (the push-plus-`cp` route fails ENOENT under
the app domain):

```
md5 before restore (mutated by S3's play):
  a4686bfb465d701d9f27c32655985601  app_flutter/save.json
  a77736702b2066b541bec59e7f55f24d  app_flutter/save-previous.json
md5 after restore:
  8affb33b8becd2fb877b774a20cc916d  app_flutter/save.json
  89de2d363594b40095a8342f6971be3f  app_flutter/save-previous.json
```

Both match the aside copies byte for byte. Sizes are back to 7440 and 7442,
and the file modes were set back to the `-rw-rw-rw-` found on arrival (the
`cat >` restore had created them `-rw-------`). Free space after: 490 M on
/data, unchanged. The emulator was shut down with `adb emu kill, since this
session had started it and none was running before.

## 8. What the tests cannot prove

The spec names one and it stands: **feel**. No instrument here measures whether
gathering now feels discoverable, or whether a road fight feels fair to a
casting hero. Both are human-judged and re-open at the HUD+cast playtest
(D63, follow-up 29's class).

Two more that this unit's evidence genuinely does not cover:

- **Casting on the road** is unproven end to end on device. The device hero is
  unschooled and owns no materials, so the road walk in section 7 exercised
  the arrival path, not the carry. Item 1's carry is proven by R1/R2/R3/R4 and
  by mutation rows M1-M4, not by the AVD pass.
- **`ReadBookPressed` from the town screen** is proven only by widget test and
  mutation, never by a human finger — no book was in the device inventory.

## 9. Spec claims checked and found wrong

1. **"A spell-less hero has max mana 0"** (spec, R2's fixture warning) —
   **wrong**. `heroMaxMana` carries `baseMana = 4` (`mana.dart:4-6`), so an
   unschooled hero observes 4. Caught by S1 (worker entry 1, claim 3), recorded
   by the architect as the fifth architect claim error of this epic (D65). No
   test change was needed: the R2 fixture is schooled, so it observes strictly
   above base either way. **S3 corroborates it on device**: the Character
   screen of the unschooled device hero reads `Mana 4`.
2. **The mutation table's predicted-red columns for M1, M2, M3 and M5** —
   partly wrong, in four specific ways. Measured by S2, promoted to D67, and
   listed in section 5 above. The spec table was a prediction; the run is the
   measurement.
3. **"endRun needs no core change"** — checked and found **correct** (S1,
   verified at `run_boundary.dart:120-121`). Recorded here because the build
   prompt asked for it to be attacked, not because it failed.
4. **The record's own description of `01-town-doors.png`** — wrong, and this is
   an S3 finding. Worker entry 3 and architect entry 8 both describe it as "the
   town screenshot". The file is in fact a **dungeon** frame: The Crypt, depth
   2/5, hero at 7/20, message "The crawl resumes." It is a legitimate capture
   of the app right after launch, but it is not a picture of the town doors and
   never evidenced the `Character` door. That is why S3 captured
   `06-town-character-door.png, which does. No file was edited or deleted —
   entry 3's claim simply stands corrected here.

## 10. Observations that are not defects, reported rather than fixed

- **Skills row crowding.** On a 360-wide phone the longest skill name touches
  its level digit: the row renders `Blacksmith0` where every shorter name has a
  gap (`Herbcraft 0`). It is legible and the spec's contract is met (all nine
  `SkillId` values, level, XP bar), so this is cosmetic and was **not** fixed —
  the brief forbids silent fixes, and nothing here contradicts expected
  behaviour. Worth a follow-up when the HUD unit touches this grammar.
- **The device hero's pack is empty of potions.** The pre-fix save's *profile*
  held two healing potions, but its *run* pack held none, so leaving the delve
  carried an empty pack home and the Potions section reads "You are carrying
  nothing you could drink." Consistent, not a regression.

## 11. Execution phases — which ran, and why any was skipped

- **Plan** — ran (S1), written to `docs/plans/2026-08-29-m3-fixes.md,
  untracked by design and never staged.
- **Pre-declaration** — ran (S1): shape deviations A-E mailed before code and
  approved as D65. One later deviation (M7's mutation script) was declared in
  the same entry as its result rather than before the run, because the code was
  frozen by then; disclosed as such and accepted by the architect.
- **Characterization first** — ran; C1 on the true base, C2 under the approved
  D65-B ordering (section 2).
- **Red → green per behaviour** — ran (S1), reds watched failing in the working
  tree before each fix, with tasks 5-7 landing as one commit so that every
  commit's exit state is green (D65-C).
- **Mutation table** — ran in full (S2), seven of seven rows.
- **Static verification** — ran twice, independently (S2, S3).
- **AVD pass** — ran across S2 (install) and S3 (verification, screenshots,
  restore).
- **Nothing was skipped.** No push, no pull request, no reviewer request, no
  merge, no external tracker write, no stakeholder-facing write — all reserved
  to the architect, per build prompt section 9.

## 12. Definition of done, against the spec's own list

| Spec requirement | State |
|---|---|
| 1790 + all new tests green, counts from result files | **met** — 1810 green (762/533/515), S3's own run |
| Four band lines byte-identical, quoted verbatim | **met** — section 4, all four `MATCH` |
| `world_test.dart` fingerprint group green untouched | **met** — C1 17/17 green |
| Full mutation table reported, greens included | **met** — section 5 (S2, D67) |
| AVD pass: door + character screen, remembered-node shot plus greyscale, saves restored, ritual honored | **met** — section 7 |
| `flutter analyze` clean, `dart format --set-exit-if-changed .` clean | **met** — section 6 |
| BUILD-REPORT.md in the handoff directory | **met** — this file |

No save-format change, no content-table change, no band pin edit, no edit to
`dungeon_door_characterization_test.dart, no new dependency, no suppression,
no `Random()`.
