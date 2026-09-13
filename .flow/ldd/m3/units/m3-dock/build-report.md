# REPORT — build session `m3-dock` (story M3V, the dock fix)

Branch `m3-dock` in worktree `.worktrees/m3-dock, seven commits, all green. The verification round (dispatcher entry 3) reproduced every number; its one finding — an orphaned duplicate of `_outOfReach`'s dartdoc — is fixed in `8cc5316` (comment-only, 7 deletions; analyze/format clean, app suite 563/0 re-run after).
Every numbered item below is the build prompt's verification block, evidenced
by command output captured in this session.

## 1. The work happened in the worktree

    $ cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dock && pwd
    /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dock
    $ git rev-parse --show-toplevel
    /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dock
    $ git log --oneline main..HEAD
    8cc5316 docs: drop the orphaned duplicate of _outOfReach's dartdoc (verification-round fix, comment-only)
    b9af82b test: retire the D90 characterization pins — their inverse now lives in the dock suite
    fbaaf58 test: the stage card's wound reads in the bar's length, not only the number
    f3e48f7 feat: a far stage-card tap tells the player to walk
    b510245 test: the docked screen fits a phone with the dock up and with it down
    64f7910 feat: the dock — the map never leaves the screen during a fight
    5db1d09 test: characterize the D90 trap — the swap and the lying far card tap

All commits follow Conventional Commits,
explicit paths only. `git status` clean except the harness's own untracked
`.pi/`. Nothing under `docs/` was committed (the plan file
`docs/plans/2026-09-02-m3-dock.md` in the MAIN repo is untracked, as
instructed).

## 2. Baseline measured FRESH in the worktree, before the first change

At `main` @ `fda107f, pwd quoted, counts from `--file-reporter` result files,
non-hidden `testDone` entries only:

    core    793 pass, 0 fail
    content 541 pass, 0 fail
    app     560 pass, 0 fail
    $ dart analyze .   (from the WORKTREE ROOT, pwd quoted)
    No issues found!

Every later count is against this baseline: core 793 and content 541 are
unchanged at the close; app ended 563 (560 − 2 swap tests + 3 dock tests
+ 2 later additions = 563; the −2+3 in commit 64f7910, +1 in b510245,
+1 in fbaaf58, +1 in f3e48f7).

## 3. C1/C2 passed against the UNMODIFIED code

- **C1** (spitter at distance 3 in LOS ⇒ the map is NOT on screen, the swap as
  shipped): green on the first run against unmodified `fda107f`.
- **C2**: the spec's original wording ("emits no state change, the silent
  no-op") FAILED against unmodified code — measured actual: the log gains
  exactly `Something is watching. You stay put.` (see item 8). C2 was re-pinned
  to the measured behaviour (hero stays, no blow, log gains exactly the
  watched-refusal line), and both C1 and C2 passed green at commit `5db1d09,
  before any production change. The pins were retired in `b9af82b` once their
  inverses (T1/T2/T3) held, per the spec's rewrite instruction.

## 4. T1–T7 passing; the D89 swap tests rewritten, not preserved

All in `packages/app/test/battle_view_test.dart` (real `GameScreen` over a
real `GameBloc`):

- **T1** `the map stays on screen while the dock is up` — map and stage card in
  one pump; red on unmodified code (compile red on the absent `BattleDock,
  with C1 having measured the swap's shape).
- **T2** `a floor tile one step toward the spitter moves the hero while the
  dock is up` — taps through `GridGeometry.camera` + `tester.tapAt`; hero at
  (2,1), dock stays up.
- **T3** `a far stage-card tap says so in the log and changes nothing else` —
  red measured against the pre-change code as exactly the watched-refusal
  line, green after (`the spitter is out of reach. Walk to it.`).
- **T4** the two rewritten D89 card tests: `tapping a card with no armed skill
  is the bump-attack` (unchanged) and `an armed cast at a stage card names the
  target` (rewritten: the named target is now the ADJACENT ghoul, not the
  two-tiles-out spitter — under contract 4 a beyond-one-step card is the walk
  sentence, so the named cast lives on the adjacent card; the "named target,
  not the nearest" nuance is preserved with two holders on stage).
- **T5** `the dock rows leave when the last reach-holder dies` — the rewritten
  swap-return test; asserts `BattleDock` absent and `GlyphGrid` present.
- **T6** the carried D89 skill-bar group (marking+name+cost, non-caster sees no
  bar, arming by word, mend without a card, refused cast speaks in the log) —
  re-pointed at the dock row, all green.
- **T7** `the screen fits a phone with the dock up and with it down` —
  1080×2424 @ 2.625; no exception, map+card+bar+HP+log findable dock-up;
  `BattleDock`/`BattleSkillBar` absent and crawl intact dock-down.

Final app suite: **563 pass, 0 fail** (`/tmp/final-app.json`).

## 5. The full mutation table — every row, NAMED red sets, greens included

Each mutation applied by sed, full `battle_view_test.dart` run, then reverted
(`git checkout --`); tree clean after every revert. M2 was run, reported, and
reverted to the dock (the sequencing trap honoured — `BattleView` no longer
exists, so the swap was re-inserted as `isBattleOpen ? SizedBox.shrink() :
GlyphGrid, which reproduces the swap's essential effect: the map hidden while
the fight holds).

| # | Mutation (actual sed) | Named RED | Named GREEN |
|---|---|---|---|
| M1 | `if (state.isBattleOpen) BattleDock(...)` → `BattleDock(...)` (gate dropped) | T5 `the dock rows leave…, T7 `the screen fits a phone…` | T1, T2, T3, T4, T6 (13 green) |
| M2 | map slot → `state.isBattleOpen ? SizedBox.shrink() : GlyphGrid(` | T1 `the map stays on screen…, T2 `a floor tile one step…, T7 | T3, T4, T5, T6 (12 green) — T6 green as predicted; **T7 red is a superset of the table's {T1, T2}**: T7 also asserts the dock-up map, which M2 removes |
| M3 | `log: [...state.log, _outOfReach(monster.name)], ` → `log: state.log, ` | T3 `a far stage-card tap says so…` | T1, T2, T4, T5, T6, T7 (14 green) |
| M4 | reach test → `if (true) {` (far card tap dispatches plain `TileTapped` ⇒ the watched-refusal line, per the amended spec) | T3 | all others (14 green) |
| C-1 | stage card `value: fraction.clamp(0, 1), ` → `value: (fraction / 2).clamp(0, 1), ` | `the stage names, numbers and marks what holds reach` (its bar-length assertion, added in fbaaf58) | all T1–T7 (14 green) |
| C-2 | `${spell.manaCost}` → `${spell.manaCost + 1}` (×2, label branches) | `the bar lists marking, name and cost, school first, `tapping a skill arms it…, `an armed cast at a stage card…, `a refused armed cast…, T7 | T1, T2, T3, T5, T6 (10 green) — the greens T1–T5 as claimed (T7 is not in C-2's green claim and reds because it asserts the cost label's text) |

No row reddened nothing; every revert left the tree clean.

## 6. Format and the band diff

    $ dart format --set-exit-if-changed packages/app   → Formatted 59 files (0 changed)
    $ dart format core, content                        → 0 changed each
    $ git diff main -- packages/core packages/content  → EMPTY (0 bytes, quoted:
    0
    )

Changed files, exactly the spec's four:
`packages/app/lib/game/game_screen.dart, `packages/app/lib/game/battle_view.dart, `packages/app/lib/game/game_bloc.dart, `packages/app/test/battle_view_test.dart`
(+ the test-only commits for the characterization pins and their retirement).

## 7. What the tests cannot prove

- Thumb reach on a phone: the widget suite taps synthetic coordinates; only
  the AVD pass shows the dock rows sit above the fold and the map stays
  reachable under them (shots 01–02 show it; the author's hand is the final
  judge).
- The log's readability dock-up on a real device, at a glance, mid-fight.
- The ambush's feel, and whether the spitter fight now feels trivial (the
  measured fight cost: two moves, one shot taken for 2, one swing for 5 —
  a balance verdict for the user's next playtest, per the spec).
- Determinism/bands: asserted by the empty band diff, not by a test.

## 8. Every spec claim checked and found wrong

1. **"The silent no-op" (original C2, and recon claim 5)** — WRONG, measured.
   The recon's premise "a monster's tile is not walkable" is false:
   `FloorMap.isWalkable` (`floor_map.dart:71-72`) is terrain-only. The far
   card tap on unmodified `fda107f` emits the watched-refusal line
   `Something is watching. You stay put.` — a state change, and a lying one
   (the spitter you can see is the "watcher"; the sentence names no walker and
   moves nobody). Accepted by the architect as D92; the spec and recon were
   amended (dispatcher entry 2), and T3/M4 were built against the amended
   wording.
2. **"Armed-cast names the target" (D89 test as written)** — the original test
   cast at a distance-2 spitter. Under contract 4 that tap is now the walk
   sentence, so the test was rewritten to the adjacent card (T4). This is the
   spec's own "the two rewritten D89 tests", not a departure — noted here
   because it retires armed-cast-at-range from the card.

## 9. Execution phases — which ran, and why any named phase was skipped

- flow-using-skills → flow-writing-plans: ran; plan at
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/plans/2026-09-02-m3-dock.md`
  (untracked per the build prompt — the skill's commit step was overridden by
  the prompt's "stays UNTRACKED"; the skill's stop-and-ask-the-user step was
  discharged through the mailbox pre-declarations to the architect, the
  worker session's standing approval channel, and were ratified as D92).
- flow-tdd: ran throughout — baseline recorded, one behaviour per test, every
  production change preceded by a red (T1/T2/T5 compile-red on the absent
  dock; T3 red as the measured watched-refusal; the C-1 bar assertion red
  under its mutation).
- flow-executing-plans (subagent orchestration): NOT used — the build prompt
  directs the worker to do the work itself ("Do the work yourself; read-only
  subagents may fan out for search, never a writer"), and the unit was small
  enough for one session. No subagent was dispatched at all.
- flow-verification: this report; every claim above carries its command output.
- flow-finishing: not mine — no push, no PR, no merge; the architect handles
  every external write.

## 10. AVD pass evidence

Emulator `Pixel_10, pinned to `emulator-5554`; no physical phone attached at
any point (`adb devices -l` showed exactly one device, the emulator).

- **Install proof:** `adb install -r` → `Success`; `dumpsys package`
  `lastUpdateTime=2026-09-02 22:56:03`. (The first install at 22:46 was lost
  when the first emulator boot died — the pass was re-run on a fresh boot;
  `lastUpdateTime` quoted as proof the pass ran on THIS build. My first boot
  was launched under a background task with a timeout, which the user
  corrected: relaunches were detached, no timeout wrapper.)
- **Save ritual, both directions:** BEFORE any install, both slots copied
  aside via `run-as … cat` — `save.json` 7440 B md5 `8affb33b8becd2fb877b774a20cc916d, `save-previous.json` 7442 B md5 `89de2d363594b40095a8342f6971be3f,
  matching the on-device md5s and the battle-ui unit's recorded values. After
  the drive, both slots restored the same way; on-device md5s after restore:
  `8affb33b…cc916d` / `89de2d36…1be3f` — byte-identical to the copies aside.
  The drive ran on a TEMPORARY acceptance save derived from the real playtest
  save (same crypt floor and hero, healed to 20/20, `firebolt` granted and
  mana set 10, the floor stripped to one spitter with `reach: 3` standing
  three tiles east of the hero with clean LOS, in the hero's visible set).
  One decode finding during staging: the actor codec REQUIRES `resists` in a
  hand-built monster document (the first acceptance save was refused whole —
  "the save file is missing \"resists\"" — and the app fell back to the older
  slot, exactly as designed; the codec never repairs). Nothing to fix in the
  app; noted as a hazard for any future hand-staged save.
- **The acceptance drive** (real taps on the device, `input tap`):
  1. boot → **shot-01-dock-up**: the D90 standoff with the dock UP — stage
     card (`p, `the spitter, bar, `4 / 4, `at range`), turn strip, the map
     rendered and tappable underneath, `✳ Firebolt 2` docked below the map,
     status line `20 / 20 Steady The Crypt — depth 2/5 Engaged 1 Mana 10/4`.
  2. tap on the floor one step east → **shot-02-walked**: `You step east.` in
     the log, hero closer, dock still up, camera recentred, `Next: the
     spitter` on the strip.
  3. tap the far stage card → **shot-03-guidance**:
     `the spitter is out of reach. Walk to it.` in the log, hero unmoved,
     nothing else changed.
  4. one more step east, then the (now adjacent) card tap →
     **shot-04-dock-down**: `The spitter strikes you from afar for 2.` (the
     watched tile-by-tile cost, visible), `You hit the spitter for 5., `The spitter dies.` — and the dock rows leave: no card, no strip, no
     bar; the screen is the crawl. The spec's measurable effect landed: two
     moves plus one swing.
- **Greyscale**: `magick -colorspace Gray` variants of all four shots beside
  them (`grey-shot-0…`). Verified legible with hue thrown away: the monster by
  glyph and name, its wound by bar length and two numbers, its reach by the
  words `at range, the armed spell by a word beside its name, the dock rows
  by position, `Engaged 1` by a word.
- Shots live in the MAIN repo's `docs/reports/shots/m3-dock/` (8 files).
- **Device findings:** none new in the app. The only device incident was my
  own tooling (the first emulator boot dying with its wrapping background
  task, and the resulting stale-build discovery via `lastUpdateTime` — the
  pass was repeated in full on the fresh boot).

## Mailbox state

Dispatcher entries 1–2 read and disposed (2 = the D92 ratifications; the
amended spec sections were re-read before building T3/M4 and match what
shipped). Worker entries 1–2 sent (acknowledgement; the D92 declarations).
The standing mailbox watch is left to expire (restarts stop at the done
notice; the last watch was verified alive at 39 s and again at the boundary
checks).