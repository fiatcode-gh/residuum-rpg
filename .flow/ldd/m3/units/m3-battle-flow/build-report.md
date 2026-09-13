# REPORT — m3-battle-flow (story M3BF, unit 2 of the D98 wave)

Worker session, 2026-09-03. Base `main` @ `6a1500a`, branch `m3-battle-flow`,
worktree `.worktrees/m3-battle-flow`. 11 commits, nothing pushed, nothing
under `docs/` committed (the plan doc `docs/plans/2026-09-03-m3-battle-flow.md`
is uncommitted as instructed — the architect commits it at PR time).

## 1. Worktree and commit hygiene

- `cd <worktree> && pwd` → `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-battle-flow`.
- `git rev-parse --show-toplevel` names the worktree. Verified before the
  first commit and before every commit after.
- `git log --oneline main..m3-battle-flow`: the 11 commits below exist on no
  other branch. Parent repo still at `6a1500a` on `main`, untouched.
  `5bc47c2 test: pin the map's tap-to-attack gesture m3-battle-flow retires`
  `e00f386 feat: the wait verb — WaitAction spends the turn and ticks the world`
  `404b765 feat: the wait surfaces — bar button, road row, the hold-ground sentence`
  `9ccb0fa feat: turn-order chips on a whole-header backing — the dock reads over any tile`
  `733159e refactor: the armed slot widens to ArmedAction — attack joins the bar next`
  `805fe37 feat: attack is a bar action — the armed-target flow reaches the bump`
  `e839acf feat: a bare card tap opens the enemy's numbers`
  `a287d43 feat: the map stops swinging — monster tiles refuse like watched ground`
  `fcf456d feat: armed actions mark their legal targets on cards and map`
  `fcf3989 feat: watched and engaged read apart — glyph and word, never hue`
  `12f3746 fix: the battle word's emptiness check reads the string, not a phantom null`

## 2. Test counts (from result files, suites per package directory)

Freshly measured baseline on unmodified `6a1500a` before any change: core 828,
content 550, app 563 — 1941 green, all exits 0. Final state, all exits 0:

| package | baseline | final | delta |
|---|---|---|---|
| core | 828 | 835 | +7 (the wait-verb suite) |
| content | 550 | 550 | ±0 |
| app | 563 | 589 | +26 |

## 3. Characterization proof

The one unpinned behavior — map tap-to-attack on an adjacent monster tile —
was pinned in `battle_flow_characterization_test.dart` and run GREEN against
unmodified `6a1500a` (commit `5bc47c2`), then flipped in `a287d43` with the
old behavior quoted. The other flip-pins already lived in their home suites
and were verified green on the baseline run before the first change:
far-card sentence, bump-on-bare-tap, `'Next: …'`/`'… turns out'` strip texts,
`'Engaged 1'` suffix, non-caster-no-bar, watched refusal.

## 4. Mutation table (whole table, greens included; reverts proven —
`git status` clean after the last revert, full suite re-run green)

| Row | Mutation | Named reds | Greens |
|---|---|---|---|
| M1 | wait's monster-phase fall-through removed (early return before `_monsterPhase`) | 4: `a bound monster sits out a waited turn`, `a reach-holder shoots a waiting hero — waiting is a real turn`, `a wait is legal in an encounter state`, `a wait leaves the hero standing and costs the turn` (core `step_wait_test.dart`) | `step_clock_test.dart` + `energy_test.dart` all green (they never wait), the other 3 wait tests green |
| M2 | the monster-tile map gate reverted | 1: `a map tap on an adjacent monster tile refuses like watched ground` | — |
| M3 | the stage-card target mark removed (`border: null`) | 1: `an armed attack marks the legal target card with the ink border` | 1 green in the same group (unarmed-unmarked) |
| M4 | chip order/words reverted (`NOW`→`Next:`, `IN n`→`turns out`) | 1: `the chip row names NOW first, then arrivals as IN n` | — |
| M5 | `armedTargets` collapsed to `const {}` | 2: `the armed attack marks the orthogonally adjacent, only them`, `an armed target-needing spell marks every visible enemy` | the 3 map-mark tests + nothing-armed test green in the same file |
| M6 | bare card tap reverted to dispatch (`C4` undone) | 2: `a far stage-card tap with nothing armed opens the enemy info`, `a bare card tap opens the enemy info, never the bump` | 26 others green |
| M7 | the watched/engaged conflation restored (Engaged for any sighted monster) | 1: `a monster in sight beyond reach reads as watched` | 6 others green |

Pre-flip rows (pinned OLD behavior, green against `6a1500a` before the unit
moved them): the map-tap-attack pin (row M2's test, pre-flip at `5bc47c2`) and
the home-suite pins named in section 3. A first M5 attempt mutated into a
compile error — discarded, redone as the behavioral mutation reported above.

## 5. The five band lines (verbatim from this session's content-suite run)

```
survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16
casting build: 40/40 won
greedy build: 16/40 won; fleetfoot-first build: 13/40 won
sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5
ruined keep: 24/40 won (60.0%), stalled 0, died at 1:5 2:5 3:3 4:2 5:13 6:7 7:5
```

Byte-identical to the controls (crypt 16/40 (40.0%) `{1:1,2:9,3:8,4:6,5:16}`,
casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40 (65.0%), ruined keep
24/40 (60.0%)). No movement. `golden_save_test` and
`dungeon_door_characterization_test.dart` untouched.

## 6. Static checks (from the worktree root)

`pwd` → `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-battle-flow`.
`dart analyze .` → `No issues found!`.
`dart format --output=none --set-exit-if-changed .` → exit 0, 219 files, 0 changed.

## 7. AVD pass evidence (emulator-5554, Pixel_10; no phone touched)

- Save-aside ritual BEFORE any install: both slots pulled via `run-as cat`,
  device MD5 == local MD5 — `save.json` `8affb33b8becd2fb877b774a20cc916d`,
  `save-previous.json` `89de2d363594b40095a8342f6971be3f`. Then (and only
  then) uninstall-old + install-new (APK 153,629,572 bytes; /data was at 92%,
  485M free — the ledger's known trap). After the pass BOTH saves were
  restored through `run-as stdin` and re-verified to the same MD5s. Emulator
  killed cleanly.
- Shots read in pixels (all at 1080×2424):
  - Chips + whole-header backing: `m3-shot-13.png` — `NOW — the giant rat`,
    `IN 6 — the giant rat`, `IN 14 — the giant rat` in ink monospace on the
    translucent dark backing; cards keep their opaque panel; the backing
    reads over the map.
  - Target marks, armed: `m3-shot-14-armed.png` — `Attack — armed` with the
    ink border; the adjacent rat's card bordered; the one-pixel outline
    around the rat's map glyph cell; the far monster's cell unmarked.
  - Glyph states: empty (`m3-shot-04-crawl.png`), watched `◉` + `Watched 1`
    (`m3-shot-05.png`), engaged `✖` + `Engaged 2` (`m3-shot-13.png`). Both
    codepoints render correctly in the monospace face — the CustomPaint swap
    never fired.
  - Bare card tap → enemy info sheet: `m3-shot-18-info.png` — name + glyph,
    `Wounds 4 / 4`, `1–2`, `strikes adjacent`, `Speed 10`; dismissal cost no
    turn (log unchanged, no dispatch).
  - Map tap-to-attack retired: `m3-shot-19-maprefusal.png` — a tap on the
    rat's tile read `Something is watching. You stay put.`, no swing, one
    sentence.
  - Bar Wait: `m3-shot-20-wait.png` — `You hold your ground.`, the turn spent
    (chips advanced IN 9 → IN 8, a second rat drew in — the world ticked).
  - Armed bump: `m3-shot-15-bump.png` — marked-card tap killed the 4-hp rat
    in one swing (`You hit the giant rat for 4.`).
- Greyscale variants for the author's eye: `m3-shot-13-grey.png`,
  `m3-shot-14-armed-grey.png`, `m3-shot-18-info-grey.png`,
  `m3-shot-20-wait-grey.png` — outline, borders, chips, and both glyphs all
  read with hue thrown away; the words are the backstop and all present.
- Road-row Wait surface: widget-tested (`a live road encounter offers Wait in
  its control row`, `a cleared road has no Wait control`) but not shot on
  device — this run reached no road fight. Declared honestly rather than
  staged.

## 8. What the tests cannot prove

- The greyscale judgement is the author's eye, not a test: the grey shots are
  evidence for a human, and hue-independence of the outline against every
  terrain tint is verified only for the crypt palette seen this run.
- The chip counts' clock-correctness over long fights (many waits, fast and
  slow monsters mixed) is covered by the D86 group's unit tests, not by a
  device soak.
- Long-run battery/perf of the new outline pass (one extra `drawRect` per
  marked cell, usually zero) — unmeasured, expected negligible.
- The road-row Wait on device (see section 7).

## 9. Spec claims checked and found wrong

None wrong. Two edge nuances found and left as measured, not papered over:

1. Adjacent-but-unseen monster (the recon's one-way-corner pairs): the armed
   bump still reaches it (adjacency is the attack rule, sight is not), while
   an armed spell at the same card would be refused by core's sight rule —
   unchanged from today's behavior, both surfaces agree.
2. A monster tile tapped while nothing is in sight (adjacent, invisible) does
   not hit the watched-refusal branch (its condition is `enemiesInSight > 0`);
   it falls to the walk-start branch, whose first step guard stops on the
   monster tile. No swing either way — the retirement holds; the sentence in
   that corner is silent, and the spec's "one sentence, one branch" governs
   the watched case, which is the case the sentence was written for.

## 10. Execution phases

All ran: recon/attack of the five spec claims (entry 1), plan doc
(flow-writing-plans shape, uncommitted), characterization-first TDD per
feature, mutation table both phases, band-line controls, static checks, AVD
pass with save-aside ritual. Skipped: none. One disclosed watch lapse
(worker entry 2) — restarted and stable for the rest of the unit.

## Deviations (all pre-declared in worker entry 1, approved dispatcher entry 2)

D1 sealed `ArmedAction` (`ArmedAttack` / `ArmedSpell(spellId)`) with an
`armedSpellId` spell-only getter; D2 modal bottom sheet for enemy info; D3
`GlyphCell.marked` + one-pixel painter outline (draw order unchanged); D4
codepoints first, CustomPaint swap pre-authorised (never needed).