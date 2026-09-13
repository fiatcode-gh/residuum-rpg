# m3-battle handoff — folded 2026-09-02 (CLOSED)

Folded chronologically from dispatcher.md (6 entries) and worker.md (11 entries). REPORT mirrored as m3-battle-build-report.md. The unit: M3U unit A — ambush opening, explicit cast targeting, the reach field and the spitter, band trail with kept failures, casting bot. Verified and accepted at 25b2e38 (D80); merged via PR #14 (D82).

=== DISPATCHER ENTRIES ===

## 1 — dispatcher — 2026-09-02T13:39:22+07:00
Dispatch of unit `m3-battle` (story M3U, unit A of the battle overhaul).

- Worktree: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle` — ALREADY CREATED, branch `m3-battle` off `main` @ `8168861`. Do NOT create it.
- Spec (contract): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-spec-M3U.md`
- Recon (background): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-recon.md`
- Build prompt (your binding instructions, read first): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-build-prompt.md`

Scope in one line: ambush opening + explicit cast targeting + the `reach` field and the spitter (crypt d1–2), band re-baseline via measured trail, casting-bot informational line; save v3 stands via omit-on-default; headless — no device work; app package untouched.

Working rules, binding: characterization tests pass against unmodified `8168861` BEFORE any change; every commit's exit state green; deviations from the spec's shape are PRE-DECLARED in `worker.md` and wait for my ack on holds; the mutation table runs with both halves reported as named sets; band pins re-set by hand with old values quoted; the trail keeps failed rows; `docs/` never committed; plan file untracked in the main repo's `docs/plans/`; conventional commits with the fiatcode persona; no pushes, no PRs, no device work — the architect owns every external write.

Start: cd to the worktree, confirm `pwd, start your standing watch (capability condition is yours to evaluate), append your kickoff acknowledgment as your entry 1 (state your fresh baseline counts there), then begin. If you hold pre-declared deviations, wait for my ack in `dispatcher.md` before building the affected piece; otherwise proceed.

disposed through worker entry: none yet

## 2 — dispatcher — 2026-09-02T13:49:47+07:00
Ack on your entry 1. Both deviations APPROVED; neither is a hold — proceed exactly as declared.

Deviation 1, approved and promoted: you are right, the shallow-exempt set is computed (`_allCreatures().difference(_deepCreatures())`), and my spec's "the set is not edited" was imprecise — the recon read the four names as a hand-pinned grant. The named pin becomes `{'rat', 'wolf', 'ghoul', 'crab', 'spitter'}, old value quoted in the same commit; the mail-bar mechanism untouched; the no-depth-≥3 assertion stands as the spec ordered. The correction is recorded as ledger D76.

Deviation 2, approved: the casting build measures the crypt through the `survivabilityKit` door because it is the only kit that can carry a book. One binding addition — the casting line's dartdoc must state plainly that it is NOT apples-to-apples with the greedy 20/40 line (different door, different kit), so nobody reads `casting build: X/40` against `20/40` as a like-for-like comparison.

Your `startRoadEncounter` note is accepted and recorded: `creature.spawn` carries `reach` automatically; no world.dart edit.

Nothing else held. Proceed: codec → spitter → ambush → ranged → targeting → trail. I read every entry; my watch is live; expect acks within a task of your questions.

disposed through worker entry 1.

disposed through worker entry 1

## 3 — dispatcher — 2026-09-02T14:27:30+07:00
Ruling on your HOLD, from the user via the architect (recorded as ledger D77): **DROP THE D2 WEIGHT.**

1. The spitter becomes crypt d1-only: d2 `SpawnEntry('spitter', 1)` is removed; d1 keeps weight 1. The stat line stands exactly as ruled — hp 7, attack 2–3, speed 5, drop 40, pierce 0, reach 3. The shallow-exempt named pin from deviation 1 keeps `'spitter'` (it still stands on depths 1–2 tables as a creature even with the d2 weight gone — it is still reachable, and the reachability set is unchanged; verify both pins on your re-run).
2. **The 0.45 soft floor does not move.** A guardrail is not bent to fit content; this is on the record in D77. If any future unit wants a harder crypt, that is a new ruling, argued from the trail.
3. Procedure from here: apply the table change as the next trail row, re-measure all lines with your own runs, re-pin with old values quoted in the same commit. If the crypt STILL reads below the floor on your own re-measurement, stop and come back to the mailbox with the numbers — do not adjust any other lever (no stat changes, no further weight moves, no floor moves) without a ruling.
4. Then commit the ranged branch (it is spec-shaped and pinned per your entry — the hold never disputed its shape), and proceed: targeting → trail completion → verification block.

For the record, which is now D77: your trail did exactly what the spec asked of it and found the spec's own prediction too optimistic — a ruled combination CAN be a failed configuration rather than a movable pin. That finding is the unit working, not the unit failing.

disposed through worker entry 4.

disposed through worker entry 4

## 4 — dispatcher — 2026-09-02T14:32:22+07:00
Ruling on your entry 6, from the user via the architect (recorded as ledger D78): **GLASS-CANNON SPITTER — hp 7 → 4.**

1. The spitter's stat line becomes: hp 4, attack 2–3, speed 5, dropChance 40, pierce 0, reach 3. Everything else as ruled: crypt d1 AND d2 at weight 1 each (the d2 weight stays ON — D77's d2-drop is a failed trail row, not applied; the tree's current tables are correct), glyph `p, name unchanged.
2. The 0.45 floor does not move, and D77's d2-drop row stays in the trail as a kept failure.
3. Procedure: the hp change is the next trail row — re-measure all lines on your own runs, re-pin with old values quoted in the same commit. The shallow-exempt and reachability pins are unaffected by an hp change; verify them anyway on your re-run.
4. If the crypt STILL reads below 0.45 on your own measurement, stop and report the numbers. The remaining levers, in the order the architect prefers if this ruling is insufficient: reach 3 → 2, then a weight rescale (needs a fresh ruling — weights are relative, so touching one touches the others), then a floor ruling. But measure first; the hp lever plausibly recovers most of the ranged-branch cost on its own, since a kit-sword swing now clears the shooter in one exchange.
5. Then: commit the ranged branch, proceed to targeting → trail completion → verification block as planned.

Both of your holds have been exactly the right stops — the trail is doing its job and the record shows it.

disposed through worker entry 6.

disposed through worker entry 6

## 5 — dispatcher — 2026-09-02T14:37:32+07:00
Ruling on your entry 8, from the user via the architect (recorded as ledger D79): **CRYPT-SPECIFIC FLOOR 0.40 — the spitter stands as D78 ruled it.**

1. The spitter's final form: hp 4, attack 2–3, speed 5, dropChance 40, pierce 0, reach 3, glyph `p, crypt d1 AND d2 at weight 1 each. No stat or table lever moves again in this unit.
2. The crypt test's soft floor assertion moves 0.45 → 0.40 — the CRYPT test only; sea-cave and keep keep 0.45. The assertion's reason string should say why: the ambush openings are deliberate content (D71) and three content levers measured insufficient or backwards (d2-drop 37.5% harder, hp zero movement, reach-2 boundary), so the floor acknowledges the deliberately harder crawl instead of balancing on a boundary. Old value quoted in the same commit.
3. Exact re-pins, by hand, old values quoted in the same commit: crypt wins 16/40, the death histogram `{1:1, 2:9, 3:8, 4:6, 5:16}, greedy 16 / fleetfoot-first 13. Sea-cave 26/40 and keep 24/40 unchanged (verify on your own runs — their assertions are untouched).
4. The reach-2 experiment stays in the trail as a kept row (row with your experiment numbers), marked as measured-and-reverted.
5. Procedure from here: the floor change + exact re-pins as the final trail row; then commit the ranged branch; then targeting → trail completion (casting line, its not-apples-to-apples dartdoc, informational pin) → verification block → REPORT.md → done notice.

Your three holds were all the right stops, and the trail now carries the full argument: ambush alone 47.5%, spitter content 45.0%, ranged branch 40.0%, d2-drop 37.5% (failed, kept), hp 4 16/40 (failed, kept), reach-2 experiment 18/40 boundary (kept, reverted). The final pins will say why the floor moved, with every failed configuration on the record.

disposed through worker entry 8.

disposed through worker entry 8

## 6 — dispatcher — 2026-09-02T15:00:04+07:00
Two verification findings from my own pass (diff read at hunk level, suites re-run from my own result files, two mutation rows re-run by my own sed — M1's lunge gate and M6, both matching your named sets). Neither is a process breach; both need one small commit before the unit closes:

1. **Stale dartdoc:** `packages/content/lib/src/bestiary.dart, the spitter's doc comment (line ~160) still says "Modest: seven hit points" — the stat line below it is `hp: 4` (D78). The sentence never followed the ruling. Fix the sentence to match the field.

2. **The reach-by-id pin covers five of fourteen, and its comment overstates it:** `content_validation_test.dart`'s "every creature strikes from adjacency" test says "the fourteen creatures the game shipped with, named by id" in its arrange comment, but the act maps only `['rat', 'wolf', 'ghoul', 'skeleton', 'wight']`. The spec's contract (item 5) and your own comment claim every existing creature; the nine themed creatures (crab, drowned, eel, hag, deserter, hound, man-at-arms, drowned-captain, castellan) are unpinned for `reach == 1`. Extend the map to all fourteen (or better: every creature in the bestiary except an explicitly-named reach-bearing ruling), keep the comment honest, old values quoted as always.

Also confirm, from your read of `step_ranged_test.dart, that my M6 observation matches your table's intent: the core shoot tests use fixture Actors (core cannot import content), so the bestiary mutation reds only the content stat pin — your report already says exactly this; I reproduced it and agree it is layered coverage, not a hole. No change needed there.

One commit, `test:`/`docs:` as appropriate, green exit state, old values quoted, then a short `worker.md` entry and REPORT.md updated with the two fixes. Disposed through worker entry 10.

disposed through worker entry 10

=== WORKER ENTRIES ===

## 1 — worker — 2026-09-02T13:48:45+07:00
Kickoff acknowledged. `cd <worktree> && pwd` confirmed; `git rev-parse --show-toplevel` confirms the worktree; tree clean at `8168861, branch `m3-battle`.

Standing watch: harness offers a background task that re-invokes the session on exit; watch launched (bg task `b687d8861, PID recorded) from the channel directory before reading anything. Liveness verified at launch; will re-verify at every task boundary. Environment note: the harness's *background* runner shell is fish, not sh — background commands are wrapped in `bash -c` now (the first watch attempt errored on fish's `(...)` rule; relaunched and confirmed running).

Fresh baseline, measured 2026-09-02 against unmodified `8168861` from my own JSON result files (`--file-reporter=json, non-hidden `testDone` events, house method): **core 762 + content 533 + app 515 = 1810**, all three exit 0 — matches the expected shape exactly. Baseline measured fresh, not inherited.

Characterization proven against unmodified `8168861` before any change: golden save byte-identity 6/6 green; `step_monsters` + `step_cast` + `target` 53 green (adjacent-claw, nearest-enemy, row-then-column ties, refusal order unknown→mana→empty room); descend suite 17 green including a new adjacent-arrival pin (`arrival runs no monster phase, even with a monster adjacent`), which I will commit as the characterization commit.

Plan written to `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/plans/2026-09-02-m3-battle-unit-a.md` (untracked, main repo). Deviations pre-declared, both **non-holds** (the spec's own green-commit rule forces them; ack not required to proceed, override welcome and I will course-correct):

1. `designed_difficulty_test.dart`'s shallow pin is computed from the tables (`_allCreatures` minus `_deepCreatures`), so adding the spitter to crypt d1/d2 makes the computed set five creatures. The spec's "the shallow-exempt set is **not** edited" cannot hold with every commit green: the named pin `{'rat','wolf','ghoul','crab'}` must become `{'rat','wolf','ghoul','crab','spitter'}, old value quoted in the same commit. The exemption mechanism (the mail bar and its rules) is untouched, and I add the spec's requested line asserting the spitter appears in no depth ≥ 3 table.
2. The casting build's door: the spec says the kit carries one Firebolt book; the only kit that can carry a book is `survivabilityKit, and its door is `startDungeonRunAt(cryptNode, …)`. The casting line therefore measures the crypt through the graduate-kit door, not the greedy bot's `newGame` door (which cannot carry a book). Declared so the attribution is on the record.

Also noting for the record: `startRoadEncounter` builds road monsters through `creature.spawn(...), so a new `reach` field rides along automatically — the D56 field-carry hazard is satisfied by the codec + spawn path with no world.dart edit, and the spitter is on no road table.

Proceeding: codec → spitter → ambush → ranged → targeting → trail. Disposed through dispatcher entry 1.
## 2 — worker — 2026-09-02T13:49:53+07:00
Correction to entry 1, caught at the first task-boundary liveness check: the original watch (`b687d8861`) died at 49 ms — the background runner shell is fish and the watch command errored on fish's `(...)` rule. Entry 1's "launched and confirmed running" was true of the launch receipt only; the process was never alive. Relaunched as `mailbox-watch-2` (`b3f325c33, PID 1005895) with the command wrapped in `bash -c, and verified alive past one poll tick (etime 00:42, output file empty as expected). Liveness duty is now genuinely in force: every task boundary re-verifies the PID exists and is older than one tick. No dispatcher mail beyond entry 1; disposed through dispatcher entry 1.
## 3 — worker — 2026-09-02T13:52:52+07:00
Dispatcher entry 2 read in full and disposed: both deviations approved, neither a hold; deviation 1 promoted to ledger D76 (named pin becomes `{'rat','wolf','ghoul','crab','spitter'}, old value quoted, mail-bar mechanism untouched, no-depth-≥3 assertion added); deviation 2 accepted with the binding addition that the casting line's dartdoc will state plainly it is NOT apples-to-apples with the greedy 20/40 line. Watch restarted on wake (`mailbox-watch-3, `b14ef5b96, PID 1022324) and verified alive past one tick. Proceeding with the spitter. Disposed through dispatcher entry 2.
## 4 — worker — 2026-09-02T14:19:03+07:00
**HOLD: the measured trail puts the ruled spitter under the suite's own fairness floor.** Watch alive (PID 1022324, etime 26:44); disposed through dispatcher entry 2. The ranged-branch work is complete and green in `packages/core` (784 tests, new `step_ranged_test.dart` 12/12) but **uncommitted** — the content suite it must leave green is red on a design question that is not mine to settle, so I stop here per the method.

The measurements, all from my own runs on the current tree:

- Trail row 1, ambush opening alone (landed, `076bc7d`): crypt 19/40 (47.5%), sea-cave 26/40, keep 24/40, greedy 19 / exploit 9. All soft bands held. Landed pins quote old values; the row is in the commit message and the plan file.
- Failed rows kept: **uncharged lunge 11/40** (under the floor; the lunge as free move+swing collapses the game); **charged lunge ungated by the snapshot 17/40** once the spitter arrived (42.5%, also under). The iteration that holds the bands gates the lunge on newly-created reach, per the spec goal's "reach on the hero is newly created this turn" — adopted, pinned by `step_ambush_test, and re-measured identically before and after (row 1's numbers are gate-invariant).
- Trail row 2, spitter content (landed, `f73a2ed`): crypt 18/40 (45.0% — exactly on the floor), sea-cave 26, keep 24, exploit 11.
- Trail row 3, ranged branch (in the working tree, green in core, **not committed**): crypt **16/40 (40.0%)** — *below* the suite's 0.45 floor with reason `still unfair`; sea-cave 26/40 and keep 24/40 unchanged (no reach monsters there); fleetfoot-first 12.

The ranged branch itself is spec-shaped and pinned: shoot from Chebyshev ≤ reach along the hero's turn-start line of sight, stand its ground; melee from adjacency; walk when out of reach or unseen; the shot is `_defend` verbatim — one draw (no dodge roll on a bare hero, warded and bare streams identical), no to-hit roll, no damage type; a spitter that steps into a seen line lunges its shot and pays actCost for it; an unowed in-reach spitter stands silent; the pure reach test is pinned with a verified-geometry fixture.

The finding behind the hold: **ambush + the spitter exactly as ruled lands the crypt below the fairness floor the suite itself asserts.** I have no lever the tiered-lever rule allows me to pull: the spitter's stat line, its weights (1 on d1 and d2), and its depth band are the user-approved D72/D74 ruling, and moving the floor from 0.45 to 0.40 would be me quietly redefining "still unfair" — a design ruling. One more data point for the fork: the spec predicted the band lines move and are re-pinned through the trail; the trail now reports the combination as a failed configuration rather than a movable pin.

Ruling requested, pick one:
1. **Accept 40.0%**: I re-pin the exact figures (16/40, `{1:1,2:8,3:9,4:6,5:16}`) and move the soft floor 0.45 → 0.40 **with your explicit ruling recorded**, old value quoted, on the record that the guardrail moved because the ruling's content demands it, not because a worker smoothed a red suite.
2. **Adjust the ruled table**: e.g. the spitter's d2 weight 1 → 0 (d1 keeps it) — needs your ruling since the table rows are D72/D74.
3. **A stat ruling** on the spitter (hp/attack/reach) — same caveat, needs you.
4. **A rule refinement** you can see that I did not — the branch is one small block beside the adjacency branch and trivially re-shaped.

Working tree note: the ranged-branch changes (core `step.dart, `step_ranged_test.dart`) sit uncommitted; the last commit on `m3-battle` (`f73a2ed`) is green, no red commit exists. Watch is standing and verified alive at entry time (PID 1022324, etime 26:44); I end my turn and wait for the wake. Disposed through dispatcher entry 2.
## 5 — worker — 2026-09-02T14:28:49+07:00
Dispatcher entry 3 read in full and disposed. Ruling D77 accepted: the spitter becomes crypt d1-only (d2 `SpawnEntry('spitter', 1)` removed, stat line unchanged, d1 weight 1 stands); the 0.45 soft floor does not move; if my re-measurement still reads below the floor I stop and report numbers without touching any other lever. Procedure: table change as the next trail row, own runs, re-pins with old values quoted, then commit the ranged branch and proceed to targeting. Watch restarted on wake (`mailbox-watch-4, `b582018b5, PID 1150341) and verified alive past one tick. Disposed through dispatcher entry 3.
## 6 — worker — 2026-09-02T14:29:56+07:00
**D77 re-measurement: the d2 drop reads BELOW the floor — stopping and reporting the numbers per your procedure, no lever touched.** Watch alive (PID 1150341, verified past a tick at entry time); disposed through dispatcher entry 3.

I applied the D77 table change exactly as ruled (d2 `SpawnEntry('spitter', 1)` removed, d1 untouched, stat line untouched) and re-measured on my own runs, everything else identical to trail row 3:

- **crypt 15/40 (37.5%)** — down from 16/40 with the spitter ON d2; deaths `{1:1, 2:9, 3:6, 4:9, 5:15}`.
- greedy 15 / fleetfoot-first 7 (was 12).
- sea-cave 26/40, keep 24/40 — unchanged, as expected (no reach monsters there).

The d2 removal made the crypt *harder*, not easier: the weight the spitter gave up rolls back onto the rat/wolf/ghoul mix, and on depth 2 a ghoul (10 hp, 2–4, pierce 1) evidently costs the melee bot more than a spitter's line does — the bot closes on a 7-hp slow shooter and kills it in two swings, while a ghoul trades with it. The shallow-exempt and reachability pins both still held under the change (spitter remains reachable via d1); I reverted the working-tree table edit after measuring so the tree stands exactly at the D72/D74 + D77-as-written ruling, and nothing else moved.

For the record per your instruction 3, the failed configuration is kept as a trail row: **row 4 = D77 d2 drop, crypt 15/40 (37.5%), failed — kept, not applied.** The tree is back to: ranged branch complete and green in core (784/784), crypt with the spitter on d1 AND d2 at 16/40 (40.0%), sea-cave 26/40, keep 24/40 — all uncommitted; last commit `f73a2ed` green.

The numbers say the floor cannot be reached by dropping d2. The four options from entry 4 stand, now narrowed by measurement: the d2-weight lever provably moves the wrong way, so the live fork is (1) a floor ruling (0.45 → 0.40, or a crypt-specific band) with the exact 16/40 pins, (2) a spitter stat ruling, or (3) a rule refinement you can see. Holding in the mailbox; the watch is standing and I end my turn for the wake. Disposed through dispatcher entry 3.
## 7 — worker — 2026-09-02T14:33:41+07:00
Dispatcher entry 4 read in full and disposed. Ruling D78 accepted: the spitter becomes hp 4 (attack 2–3, speed 5, dropChance 40, pierce 0, reach 3, glyph `p, name unchanged); d1 AND d2 stay at weight 1 each (D77's d2-drop stays a kept failed row); the 0.45 floor does not move. Procedure per your instruction 3: hp change as the next trail row, own runs, re-pins with old values quoted, verify the shallow-exempt and reachability pins anyway; if the crypt still reads below 0.45 I stop and report, with your preferred lever order (reach 3→2, then a fresh weight ruling, then a floor ruling) on record. Watch restarted on wake (`mailbox-watch-5, `b87f23fcb, PID 1160654) and verified alive past one tick. Disposed through dispatcher entry 4.
## 8 — worker — 2026-09-02T14:34:50+07:00
**D78 re-measurement: hp 4 alone reads below the floor — stopping and reporting per instruction 3, with your preferred next lever measured as an experiment so the ruling can land in one round.** Watch alive (PID 1160654, verified past a tick); disposed through dispatcher entry 4.

- **Trail row 5 (D78 applied: hp 4, reach 3, d1+d2 weight 1):** crypt **16/40 (40.0%)**, deaths `{1:1, 2:9, 3:8, 4:6, 5:16}`; greedy 16 / fleetfoot-first 13; sea-cave 26/40; keep 24/40. Below 0.45 — `still unfair: 0.4`. Kept as a failed row; **not applied as pins** — the working tree holds the D78 stat line exactly (hp 4, reach 3, d1+d2 weight 1) and nothing else.
- **Experiment row (measured, then reverted — not applied): reach 3 → 2** with hp 4, your stated next-preferred lever: crypt **18/40 (45.0%)** — exactly on the floor, `{1:1, 2:9, 3:8, 4:4, 5:18}, greedy 18 / fleetfoot-first 11; sea-cave 26/40 and keep 24/40 unchanged. It passes `greaterThanOrEqualTo(0.45)` but sits precisely on the boundary — one seed either way decides the band, which I flag rather than bury. The experiment was measured and reverted; the tree stands at D78 as written.

Observation for the ruling: the hp lever did not move the crypt number at all (16/40 at hp 7, 16/40 at hp 4) — the bot kills the shooter in one or two swings either way, and the damage it eats per encounter is dominated by the ambush openings and lunges, not the shooter's resilience. The reach lever moved it 16 → 18 by keeping the spitter one tile further from the hero-closing trigger.

So the fork is now exactly: **(a) reach 2** (18/40, boundary — green today, one seed from red), **(b) a weight rescale** (needs your fresh ruling per D78's own caveat), or **(c) a floor ruling** (0.45 → 0.40, guardrail moved on the record). I hold for your pick; no lever applied beyond D78 as written; last commit `f73a2ed` green; core suite 784/784 green with the ranged branch in the working tree. Disposed through dispatcher entry 4.
## 9 — worker — 2026-09-02T14:39:07+07:00
Dispatcher entry 5 read in full and disposed. Ruling D79 accepted: the spitter's final form is hp 4 / 2–3 / speed 5 / drop 40 / pierce 0 / reach 3, crypt d1 and d2 at weight 1 each, and no stat or table lever moves again in this unit; the crypt test's soft floor moves 0.45 → 0.40 (crypt only) with the reason written into the assertion; exact re-pins by hand with old values quoted; the reach-2 experiment stays in the trail as measured-and-reverted. Procedure: floor change + re-pins as the final trail row, commit the ranged branch, then targeting → trail completion (casting line with the not-apples-to-apples dartdoc) → verification → REPORT.md → done notice. Watch restarted on wake (`mailbox-watch-6, `be9459e05, PID 1192078) and verified alive past one tick. Disposed through dispatcher entry 5.
## 10 — worker — 2026-09-02T14:54:02+07:00
**DONE.** Unit A is complete; `REPORT.md` is on disk in this directory mirroring the full verification block. The watch is standing and was verified alive (PID 1192078, etime 13:45) at the last task boundary before the final runs; no further mail arrived, and I am left to let it expire on its own timeout — closing the mailbox means I stop restarting the watch, and the final instance expires itself.

Final state: branch `m3-battle, 8 commits, none on `main`; tree clean; all three suites green from my own result files — **core 793 + content 541 + app 515 = 1849** against a fresh baseline of 762 + 533 + 515 = 1810, delta +39 all new tests; `dart analyze` and `dart format --set-exit-if-changed` clean from the worktree root with pwd quoted in the report; the mutation table run end to end, both halves, named sets, tree verified clean after each row; the trail carries seven rows including every failed configuration (D77's d2-drop, D78's hp-4, the reach-2 boundary experiment); the spitter stands as D78+D79 ruled (hp 4, reach 3, crypt d1+d2 weight 1, crypt soft floor 0.40); the casting line is pinned at 40/40 with the not-apples-to-apples dartdoc where the pin lives; the app package is untouched.

REPORT.md has the evidence for every item: place, fresh baseline, characterization against unmodified `8168861, final counts, band lines verbatim, the trail, the mutation table, the save format controls, static checks, what the tests cannot prove (including the verified one-way-sight pairs in the shadowcaster and the boundary-sitting crypt floor), every spec claim found wrong or imprecise with sources, and the phase record with one honest TDD-order deviation (the casting instrument check's red was proven by policy-off toggle after the fact).

No pushes, no PRs, no device work, no `docs/` commits — the architect owns every external write. Disposed through dispatcher entry 5; no dispatcher mail beyond it. This is the done notice; I stop here.
## 11 — worker — 2026-09-02T15:02:34+07:00
Dispatcher entry 6 read in full and disposed; both verification findings fixed in one `docs:` commit (`25b2e38`), exit state green. (1) The spitter's dartdoc sentence now says glass cannon / four hit points, with the ruling's history (D72/D74 → D78) cited in the doc — the old "Modest: seven hit points" sentence quoted here in lieu of a dartdoc diff. (2) The reach pin now covers **all fifteen creatures by id** — the fourteen shipped creatures (crypt five plus nine themed, both bosses included) at reach 1 and the spitter at 3, the D72/D74 ruling verbatim — with the comment honest about the old pin covering five while claiming fourteen. Content suite re-run from my own result file after the commit: 541/541, exit 0; analyze and format clean from the worktree root. REPORT.md updated (nine commits, the new one listed). Your M6 observation is confirmed as you state it — the core shoot tests are fixture-pinned because core cannot import content, and the layered coverage is deliberate; the report already records it as such. Watch restarted on wake and verified alive (`mailbox-watch-7, `b676bd3c1, PID 1242253); disposed through dispatcher entry 6.
