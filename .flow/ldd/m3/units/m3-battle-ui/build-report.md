# BUILD-REPORT — `m3-battle-ui` (story M3U, unit B)

Worker session report, 2026-09-02. Branch `m3-battle-ui` off `main` @ `d576d1c`.

## 1. Place

    $ cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui && pwd
    /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui
    $ git rev-parse --show-toplevel
    /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui

    $ git log main..HEAD --oneline
    27fa659 fix: give the pack's skills row its missing separation (follow-up 31)
    9d2758d feat: the battle view — stage, turn strip, skill bar, tap-to-target
    4ac0264 feat: ranged verb and the ambush beat in the battle log
    f080e3d feat: turn-strip arrivals — clock-correct turns to arrival (D86)
    8e04344 feat: battle derived state — reach holders, turn schedule, armed skill
    fb77918 fix: mirror core's cast target refusal into the app's castRefusal
    990546e refactor: lift the spell-row grammar into one shared piece (fourth copy forbidden)
    16772d6 test: pin the spell-row and crawl-screen behavior the battle unit lifts

Eight commits, all on `m3-battle-ui, none on `main`. Working tree clean (only
untracked `.pi/`). `packages/core` and `packages/content` untouched by any
commit; nothing under `docs/` committed.

## 2. Baseline, measured fresh

At unmodified `d576d1c, `--file-reporter=json, counts from non-hidden
`testDone` events in my own result files (`/tmp/m3ui-baseline/*.json`):

    core 793 + content 541 + app 515 = 1849 — exactly the expected shape.

## 3. Characterization first

`packages/app/test/battle_characterization_test.dart` — 5 tests, quoted green
against unmodified `d576d1c` BEFORE any change: the Pack spell row (marking,
name, `Wrath · 2 mana · 2-4 fire △, enabled Cast), the refused-cast row
(`not enough mana, disabled Cast), the character row (read-only twin), the
crawl structure (`Engaged 1, `Pack (0)`), the adjacent bump keeping `claws`.
Committed first (`16772d6`); full app suite 520 green at that commit.

## 4. Final counts (own result files, re-derived)

    core    793 pass, 0 fail   (baseline 793 — unchanged)
    content 541 pass, 0 fail   (baseline 541 — unchanged)
    app     560 pass, 0 fail   (baseline 515 + 45 new tests)

App delta +45 explained: 5 characterization, 2 castRefusal mirror, 9 derived
state, 6 armed-skill, 5 arrivals, 5 log flavor, 12 battle view, 1 rider 31.
Core and content moved not at all.

## 5. Band lines — byte-identical controls

Run on the branch and on the main repo's `d576d1c` checkout, same commands, `diff` empty (`BANDS-IDENTICAL`). The five lines, verbatim from my own run:

    survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16
    casting build: 40/40 won
    greedy build: 16/40 won; fleetfoot-first build: 13/40 won
    sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5
    ruined keep: 24/40 won (60.0%), stalled 0, died at 1:5 2:5 3:3 4:2 5:13 6:7 7:5
    sea-cave 26/40 vs ruined keep 24/40

(The probe prints six lines: the five bands plus the ordering summary.)

## 6. Mutation table — both halves, named sets

Each row: mutation applied to the branch the test pins, targeted suites run,
named reds recorded, revert, `git status` verified clean.

- **M1** open/close `isNotEmpty` → `isEmpty` inverted. RED (10): battle-view
  swap tests (`swaps in for the map while reach is held, `crawl view returns
  when nothing holds reach`), stage (`names, numbers and marks, `turn strip, `phone-sized surface`), skill bar (`bar lists marking…, `tapping a skill
  arms it, `armed cast at a stage card names the target, `bump-attack, `refused armed cast`). GREEN controls: all crawl-view characterization pins
  green; `back_guard_test` (death overlay) 3/3 green.
- **M2** `monstersHoldingReach` reach > 1 branch dropped. RED (6): `a spitter
  within reach along the line of sight holds reach, `a monster holding reach
  is on the stage, not walking in` (arrivals), `a ranged monster reads its
  shots as strikes from afar, `an armed cast at a stage card names the
  target, stage names-marks, stage phone. GREEN controls: adjacent-only tests
  green (adjacency holds, bump-attack, adjacent claws); crawl pins green.
- **M3** armed-skill reset removed (armed carried through `_act`). RED (2):
  `a completed cast disarms, `any new game state disarms`. GREEN controls:
  the armed-cast happy path and all four survival-set tests green.
- **M4** `targetId` dropped at the dispatch site. RED (1): `an armed cast at a
  stage card names the target` — the shot lands on the nearest ghoul instead
  of the named spitter. GREEN controls: the Pack's nearest-fallback path green
  (mirror pack-path test, `magic_surfaces_test` cast tests).
- **M5** ranged verb branch removed. RED (1): `a ranged monster reads its
  shots as strikes from afar`. GREEN controls: both adjacent-`claws` pins
  green (characterization + flavor test).
- **M6** ambush-beat start-state condition removed (always true on a monster
  attack). RED (2): `an ordinary swing takes no beat` (primary), plus the
  ranged-verb test (its fixture's start state holds a reach-holder, so the
  always-true beat leaks into its log). GREEN controls: both opening-swing
  beat tests green.

No row reddened nothing. Every revert left the tree clean; all 132 targeted
tests green after the final revert.

## 7. AVD evidence (mandatory pass, full ritual)

Emulator `Pixel_10` (`emulator-5554`), serial pinned on every adb command; the
emulator died once mid-pass and was booted fresh. No physical phone touched.

- Save-aside BEFORE any install: `save.json` 7440 B md5
  `8affb33b8becd2fb877b774a20cc916d`; `save-previous.json` 7442 B md5
  `89de2d363594b40095a8342f6971be3f`.
- Storage trap fired (`INSTALL_FAILED_INSUFFICIENT_STORAGE`); resolution per
  the ritual — old build uninstalled ONLY after both copies verified, fresh
  `adb install` Success. (`flutter install` was never used.)
- Saves restored via `run-as stdin`; on-device md5s after restore:
  `8affb33b…cc916d` / `89de2d36…1be3f` — identical to the copies aside. The
  acceptance drive ran on a temporary acceptance save derived from the real
  playtest save (same crypt floor; hero healed; `firebolt` + mana granted; a
  spitter placed at the edge of its own reach; the near rat pulled two tiles
  out); the playtest saves were restored over it afterwards, checksums
  re-quoted and matching.
- Shots in `docs/reports/shots/m3-battle-ui/` (MAIN repo, untracked), each
  claim naming its file, greyscale variant `grey-*` beside each:
  - `shot-01-battle-resume.png` — battle view open: spitter on stage `4 / 4`
    with `at range`; turn strip `Next: the ghoul` + five arrivals; skill bar
    `✳ Firebolt 2`; status line `20 / 20 Steady The Crypt — depth 2/5
    Engaged 3 Mana 10/4` at the phone surface (follow-up 30's read).
  - `shot-02-armed.png` — armed marked by the word `— armed` and a border.
  - `shot-03-cast.png` — named-target cast: `Firebolt burns the spitter for
    2., bar `2 / 4, the rat walks in onto the stage, mana 10→8, armed word
    cleared after the completed cast.
  - `shot-04-spitter-dies.png` — `The spitter dies.`; rat holds the stage.
  - `shot-05-crawl-returns.png` — the crawl view back (map, `Engaged 1`).
  - `shot-06-ambush-beat.png` — the ambush beat on device: `You step north.` →
    `The ghoul gets the drop on you.` → `The ghoul claws you for 2.`
  - Greyscale variants verified legible: names, bar-length + numbers, the
    range word, the strip, the armed word — no state carried by hue.

## 8. Rider 31

`test/widget/skills_row_spacing_test.dart` at `_onAPhone` (1080×2424 @ 2.625):
red measured the real defect (level digit's left edge exactly at the name's
right edge, gap 0.0), fix added the 8 px seam, green:

    00:00 +1: All tests passed!   (gap now ≥ 4.0 logical px; row reads `Blacksmith 0`)

## 9. Static

    $ pwd
    /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui
    $ dart analyze .            → No issues found!
    $ dart format --set-exit-if-changed .
                                → Formatted 207 files (0 changed), exit 0

## 10. What the tests cannot prove

- The dodged-swing branch of the ambush-beat detection (`AttackDodged` with a
  monster attacker) is pinned only by the hit-path tests; forcing a
  deterministic dodge needed a rigged dodge roll I chose not to fake. The
  branch is three lines and mirrored from the hit branch.
- The strip's "who acts next" is a forward view over the current state; an
  ambush opening triggered by the hero's OWN next move is invisible to it (a
  monster unowed but reachable-after-the-move swings first). Documented, not
  fixable without a crystal ball — the engine's snapshot rule makes the
  swing's trigger the hero's action itself.
- Greyscale legibility is verified by my own reading of the greyscale shots
  and the deuteranomalous author's standing doctrine; the author's eye is the
  final authority and has not seen these shots yet.
- The emulator's font rendering differs from device fonts; the rider 31 gap is
  measured in logical px at the phone surface, and the device pass confirmed
  the seam on the AVD only.

## 11. Spec claims checked and found wrong (or imprecise)

1. **`arrivals` formula (the hold, ruled D86):** the spec's "flow-field
   distance ÷ speed, rounded up" is clock-wrong — every actor moves one tile
   per own turn, and a monster's turns arrive every `heroSpeed / monsterSpeed`
   hero actions. The recon's "distance × speed" was also wrong. Ruled formula:
   `ceil(distance × heroSpeed ÷ monsterSpeed), pinned with the five-tiles
   counterexample and the equal-speed reduction. (The epic's seventh worker-
   caught architect claim error, per the dispatcher.)
2. **"Three private copies" of the spell-row grammar:** there are TWO widget
   copies (Pack, Character) plus one sentence grammar (the book `teaches`
   line), which stays out of the lift. Pre-declared and approved (entry 2).
3. **The engine's monster phase schedules on the hero's POST-spend energy** —
   the spec's "the exact call the engine's phase makes" omitted the spend; a
   getter passing the resting `hero.energy` returns an empty schedule every
   time. Made precise in `upNext` (entry 2, approved).
4. No other spec claim failed. The open/close getter, the stage, the strip,
   the bar, the gestures, the mirror, the verb, the beat, and both riders
   measured as specced.

## 12. Phases run

- Characterization first (green against unmodified `d576d1c, quoted). ✓
- Written plan first (`docs/plans/2026-08-24…` convention: `docs/plans/2026-09-02-m3-battle-ui.md, MAIN repo, untracked), executed test-first per task, red confirmed before each green. ✓
- Mutation table after the build, both halves, named sets. ✓
- `flow-verification` phase: every claim above from my own result files and runs. ✓
- No named phase skipped. The plan's Task 7 (arrivals) waited one round on the D86 hold before building.

## 13. Spec deviations

None beyond the pre-declared and approved set (worker entries 2 and 4). The
ambush-beat stateless mis-reads, the strip's forward-view boundary, and the
armed-skill survival enumeration are documented in the code's dartdoc and in
worker entry 2.