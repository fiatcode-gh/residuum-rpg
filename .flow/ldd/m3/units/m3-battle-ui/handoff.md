# m3-battle-ui handoff — folded 2026-09-02 (CLOSED)

Folded chronologically from dispatcher.md (2 entries) and worker.md (6 entries). REPORT mirrored as m3-battle-ui-build-report.md. The unit: M3U unit B — the battle screen (stage, turn strip, skill bar, tap-to-target), the castRefusal mirror fix, the spell-row extraction, ranged verb + ambush beat, riders 30/31. Verified and accepted at 27fa659 (D87); merged via PR #15 (D89).

=== DISPATCHER ENTRIES ===

## 1 — dispatcher — 2026-09-02T16:07:38+07:00
Dispatch of unit `m3-battle-ui` (story M3U, unit B of the battle overhaul).

- Worktree: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui` — ALREADY CREATED, branch `m3-battle-ui` off `main` @ `d576d1c`. Do NOT create it.
- Spec (contract): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-ui-spec-M3U.md`
- Recon (background): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-ui-recon.md`
- Build prompt (your binding instructions, read first): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-ui-build-prompt.md`

Scope in one line: the battle screen over unit A's rules — stage cards, turn strip, skill bar with the dock grammar, armed-skill tap-to-target through core's targetId, the drifted castRefusal mirror fixed, the spell-row grammar extracted (fourth copy forbidden), ranged verb + ambush beat in the log, riders 30/31; AVD pass mandatory; app-only — core and content untouched, all five band lines byte-identical controls.

Working rules, binding: characterization tests pass against unmodified `d576d1c` BEFORE any change; the spell-row extraction lands first as a verbatim-lift refactor commit; every commit's exit state green; deviations PRE-DECLARED in `worker.md` and wait for my ack on holds; the mutation table runs with both halves as named sets; existing text pins move only in the commit that moves them, old values quoted; `docs/` never committed; plan file untracked in the main repo's `docs/plans/`; conventional commits with the fiatcode persona; no pushes, no PRs — the architect owns every external write. The AVD pass is mandatory for this unit with the full save-aside ritual.

Start: cd to the worktree, confirm `pwd, start your standing watch (capability condition is yours to evaluate; wrap in `bash -c` if the runner shell is fish), append your kickoff acknowledgment as your entry 1 (state your fresh baseline counts there), then begin. If you hold pre-declared deviations, wait for my ack in `dispatcher.md` before building the affected piece; otherwise proceed.

disposed through worker entry: none yet

## 2 — dispatcher — 2026-09-02T16:23:26+07:00
Ack on your entry 2 — all five pre-declarations APPROVED, and the HOLD is RULED in your favor (recorded as ledger D86, the epic's seventh architect claim error caught by a worker).

1. `upNext` with `heroEnergy: hero.energy − actCost` — approved. Your reading is correct and the spec's sentence is now precise by your entry: the engine schedules on the post-spend hero.
2. Strip divergence documented — approved; pin the boundary with the fixture test as declared.
3. Armed-skill reset enumeration — approved as enumerated; that is M3's attack surface.
4. Ambush beat refinements — approved: dodge counts, one beat per step, preamble placement, both stateless mis-reads accepted and documented, the bump-attack excluded by the snapshot rule.
5. Extraction — approved: two widget copies, not three; the recon's second character_screen hit is a sentence grammar and stays out of the lift. The shared piece takes styles/optionality as parameters; both call sites render byte-identically.

RULING on the arrivals HOLD (binding, D86): `turns = ceil(distance × heroSpeed ÷ monsterSpeed)`. Clock-correct: every actor moves one tile per own turn; a monster's turns arrive every `heroSpeed / monsterSpeed` hero actions; reduces to plain distance at equal speeds. Pin the formula with the five-tiles-at-speed-10 counterexample (reads 5, not the spec's 1) as the deterministic test, and pin the equal-speed reduction too.

Everything else proceeds. My watch is live; expect acks within a task of your questions.

disposed through worker entry 2.

disposed through worker entry 2

=== WORKER ENTRIES ===

## 1 — worker — 2026-09-02T16:20:43+07:00
Kickoff acknowledgment for `m3-battle-ui`.

- Worktree confirmed: `cd` + `pwd` output `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui`; `git rev-parse --show-toplevel` names the worktree, not the parent repo. HEAD is `d576d1c` on branch `m3-battle-ui`.
- Standing watch: RUNNING and verified alive past one poll tick (pid 1388756, fish → bash -c → timeout 3600 chain observed in the process list; first launch died silently, relaunch verified). Delivery marker `.worker-mail-delivered` present in the channel directory.
- Fresh baseline counts, derived from my own `--file-reporter=json` result files at unmodified `d576d1c` (non-hidden `testDone, skipped counted out): core 793, content 541, app 515 — total 1849, exactly the expected shape. Result files in /tmp/m3ui-baseline/.
- Read in full: build prompt, spec, recon, dispatcher entry 1. Disposed through dispatcher entry 1.
## 2 — worker — 2026-09-02T16:22:28+07:00
Adversarial pass on the spec, done from source before building. Pre-declarations follow; one is a HOLD.

**1. The strip agrees with the engine — one precision the spec text missed (proceeding, veto window open).**
The engine's monster phase schedules with the hero's POST-spend energy: `step` decrements `actCost` from the hero at the top of every action, and `_monsterPhase` calls `scheduleMonsterTurns(heroEnergy: hero.energy...)` with that already-spent hero. A settled state's `hero.energy` is always ≥ `actThreshold` (the scheduling loop only exits there), so a getter that passes `game.hero.energy` un-spent returns an empty `monsterTurns` — every time. My `upNext` therefore passes `heroEnergy: game.hero.energy - actCost, which is the exact call the engine's phase makes. Ambush-charged monsters and bound monsters then agree with the spec's claims by construction. Not a hold: it is the spec's own "the exact call the engine's phase makes", made precise. Flagging it because the recon's formula omits the spend.

**2. Strip divergence the schedule cannot see (documenting, not fixing).**
An ambush OPENING triggered by the hero's own next move is invisible to any schedule computed over the current state: a monster that owes nothing but gains reach from the hero's move swings before the strip's "Next" name does. The strip stays a forward view over the current state (the spec's shape); the report will pin the boundary with a deterministic fixture test and state it.

**3. Armed-skill reset, enumerated (proceeding).**
Survival set (handlers that emit the SAME game state — armed survives, field named deliberately): `_onMapPanned, `_onSystemBackPressed, `_stopWalking, `TileTapped`'s watched-refusal branch, `TileTapped`'s walk-start branch. Reset set (every handler that produces a new game state — constructor-drop does the reset): `_act` (all actions, the completed cast included), `_afterAction` (adjacent moves / stairs), `_onAutoWalkAdvanced`. Battle-view close always coincides with a new game state, so the drop covers it. This enumeration is what M3's mutation attacks.

**4. The ambush-beat detection rule — refinements pre-declared (proceeding).**
- "A monster attack on the hero" = `AttackHit` or `AttackDodged` where `attackerId != heroId` and `targetId == heroId`. A dodged opener is still the monster acting first; it counts.
- At most one beat per step, however many monsters open at once.
- The beat lands immediately before the first monster-attack sentence of that step (not appended after all sentences as `_beats` does today — the beat is a preamble, not an aside).
- Accepted, documented mis-reads of the stateless rule: (a) the hero's own closing move that creates reach takes the opening swing and the beat fires — reads true, kept; (b) a paused chase that re-catches fires the beat mid-fight — accepted; a stateful "battle already opened" flag is view state the spec's pure-getter shape does not carry, and I am not adding it without a ruling.
- The hero's bump-attack never fires the beat: `_reachedAtStart` is snapshotted at the top of `step, before the hero's action, so the adjacent defender is a start-state reach-holder.

**5. The extraction's verbatim-ness — the disagreements, enumerated (proceeding).**
I find TWO widget copies, not three: the Pack's `_SpellRow` (inventory_screen) and the Character screen's `_SpellRow`. The recon's "character_screen ×2" counts, I believe, the book "teaches" line (character_screen ~356), which is a sentence grammar, not a row — it stays out of the lift. The widget copies disagree in: (i) type sizes — pack 13/11, character 14/12 (same colors); (ii) the pack appends the `_effectOf` detail suffix, the character does not; (iii) the pack has a Cast button gated on the refusal, the character has no button; (iv) the pack has an optional reason line. The shared piece takes the styles and the optionality as parameters, so both call sites render byte-identically to today — the lift picks no width silently. The battle skill bar is a different layout (wrap-flow buttons) and consumes the shared facts (marking, name, the "schoolWord · N mana" line), not the row widget itself.

**6. HOLD — the `arrivals` formula.**
The spec says turns-to-arrival = flow-field distance ÷ speed, rounded up. The recon says distance × speed. Neither matches the clock: in this engine every actor moves ONE tile per own turn, and a monster's turns arrive every `heroSpeed / speed` hero actions — so the clock-correct reading is ceil(distance × heroSpeed ÷ monsterSpeed), which reduces to the plain field distance at equal speeds. The spec's ÷ makes a speed-10 monster five tiles away read "1 turn out". I will not build `arrivals` until you rule on the formula; everything else proceeds.

Disposed through dispatcher entry 1.
## 3 — worker — 2026-09-02T16:31:44+07:00
Progress: tasks 0–2 of the plan done, one self-caught defect along the way.

- Watch: relaunch 3 (task b577fbdca) alive and verified; your entry 2 delivered through it and is disposed — all five pre-declarations APPROVED, arrivals formula RULED per D86. Disposed through dispatcher entry 2.
- Task 0 (characterization): 5 pins green against unmodified `d576d1c` — the Pack spell row (marking, name, `Wrath · 2 mana · 2-4 fire △, enabled Cast), the refused-cast row (`not enough mana, disabled Cast), the character row (read-only, no effect suffix, no Cast), the crawl structure (`Engaged 1` in the status line, `Pack (0)`), and the adjacent bump keeping `claws`. Committed `16772d6`; app suite 520 green (515 + 5 new).
- Task 1 (extraction): `packages/app/lib/game/spell_row.dart` now carries the shared `SpellRow` (styles + optionality as parameters) and `effectOf`; both private copies deleted; both call sites byte-identical (all pre-existing pins green untouched). Committed `990546e`. All three suites re-derived: core 793, content 541, app 520.
- Task 2 (castRefusal mirror): red confirmed as the compile-fail on the missing `targetId` named parameter, then green. `castRefusal(spell, {targetId})` now mirrors core's `_castRefusal` order (dead → mana → named-target visibility → no-enemy-in-sight); the mirror-agreement test pins both sides on a shared fixture (app getter and core `step` quoted: `you cannot see that target`); the Pack path (no target → nearest fallback) pinned unchanged. Full app suite running for the commit.

Noted for the report: my first green attempt had the branch dead — a null-check (`== null`) against a bool-returning helper. The red test caught it immediately; that is the test doing its job.

Disposed through dispatcher entry 2.
## 4 — worker — 2026-09-02T16:56:06+07:00
Tasks 5–8 done; the mutation table has run in full. Task boundary watch check: running and alive.

- Task 5: `CastPressed` gained `targetId` (dispatched through to `CastSpellAction`); `battle_view.dart` — stage cards (glyph, name, HP bar + numbers, `at range` word for reach > 1), turn strip (`Next: {name}` + arrivals), skill bar (marking + name + cost, wrap-flow, armed by word + border, silent for non-casters, never gated on castRefusal); `game_screen.dart` swaps the map section for the battle view while `monstersHoldingReach` is non-empty. 12 widget tests including a phone-sized surface. Commit `9d2758d`. App 559 green.
- Task 6 (rider 31): red test measured the real defect (gap 0.0 logical px between the skills name column and the level digit at the phone surface); fixed with an 8 px seam; the row now reads `Blacksmith 0`. Commit `27fa659`. App 560 green.
- Task 7 had already landed earlier (`f080e3d`) per your D86 ruling, with the five-tiles counterexample and the equal-speed reduction pinned.
- Task 8, the mutation table, both halves as NAMED SETS (each row applied, run, reverted, `git status` clean):
  - M1 (open/close inverted): RED = the battle view swap tests (swaps in / crawl returns), the stage tests (names-numbers-marks / turn strip / phone), the skill bar tests (bar lists / tapping arms / armed cast names target / bump-attack / refused cast) — 10 named. GREEN controls: the crawl-view characterization pins all green; `back_guard_test` (death overlay) 3/3 green.
  - M2 (reach > 1 branch dropped): RED = spitter-within-LoS derived-state test, arrivals on-stage test, ranged-verb test (spitter leaves the stage), armed-cast-names-target, stage names-marks, stage phone — 6 named. GREEN: adjacent-only tests (adjacent holds reach, bump-attack, adjacent claws), crawl pins green.
  - M3 (armed reset removed): RED = `a completed cast disarms` and `any new game state disarms` — exactly the two reset pins. GREEN: the armed-cast happy path and all four survival-set tests green.
  - M4 (targetId dropped at the dispatch site): RED = `an armed cast at a stage card names the target` (the shot lands on the nearest ghoul instead) — 1 named. GREEN: the Pack's nearest-fallback tests (mirror pack-path test, magic_surfaces cast tests) green.
  - M5 (ranged verb branch removed): RED = `a ranged monster reads its shots as strikes from afar` — 1 named. GREEN: both adjacent-`claws` pins green.
  - M6 (beat condition always true): RED = `an ordinary swing takes no beat` plus the ranged-verb test (its start state holds a reach-holder, so the always-true beat leaks into it) — 2 named. GREEN: both opening-swing beat tests green.
  - Tree verified clean after every row; all 132 targeted tests green after the final revert.
- Next: the AVD pass (Task 9). Emulator, adb and device-facing flutter commands are sandbox-excluded, so they run through background tasks; results quoted as they land.

Disposed through dispatcher entry 2.
## 5 — worker — 2026-09-02T17:10:02+07:00
The AVD pass is complete; the full ritual ran, all six acceptance claims have on-device evidence.

- Watch: still running (checked at this boundary).
- Emulator: `Pixel_10` (`emulator-5554`); the first emulator died mid-pass and was booted fresh per your instruction. Serial pinned on every adb command; no phone touched.
- Save ritual: BOTH slots copied aside BEFORE any install — `save.json` 7440 B md5 `8affb33b8becd2fb877b774a20cc916d, `save-previous.json` 7442 B md5 `89de2d363594b40095a8342f6971be3f`. The storage trap then fired on `adb install -r` (`INSTALL_FAILED_INSUFFICIENT_STORAGE`); resolution per the ritual — uninstall of the old build (legal only because both copies had verified), fresh `adb install` Success, then `run-as stdin` restore of BOTH slots with md5s re-quoted: both match the pre-install values exactly. The acceptance drive then ran on a TEMPORARY acceptance save derived from the real playtest save (same crypt floor, hero healed, `firebolt` + mana granted, a spitter placed at its own reach's edge, the near rat pulled two tiles out); the playtest `save.json` and `save-previous.json` were restored over it afterwards, checksums re-quoted and matching.
- Acceptance evidence, each claim naming its file in `docs/reports/shots/m3-battle-ui/` (MAIN repo, untracked; greyscale variant `grey-*` beside each):
  - `shot-01-battle-resume.png` — the battle view open on resume: the spitter on stage `4 / 4` with the `at range` word; turn strip `Next: the ghoul` + five arrival counts; skill bar `✳ Firebolt 2`; status line `20 / 20 Steady The Crypt — depth 2/5 Engaged 3 Mana 10/4` at the phone surface (follow-up 30's read).
  - `shot-02-armed.png` — armed cast marked by the word `— armed` AND a border, never hue.
  - `shot-03-cast.png` — the armed cast landed on the NAMED target: log `Firebolt burns the spitter for 2., the spitter's bar dropped `2 / 4`; the rat walked in onto the stage; mana paid `10/… → 8/…`; the armed word cleared after the completed cast.
  - `shot-04-spitter-dies.png` — second cast kills: `Firebolt burns the spitter for 3.` + `The spitter dies.`; the rat now holds the stage alone.
  - `shot-05-crawl-returns.png` — after the bump-attack killed the rat: the crawl view back (map, `Engaged 1, log kill sentences).
  - `shot-06-ambush-beat.png` — the ambush beat on device: log `You step north.` → `The ghoul gets the drop on you.` → `The ghoul claws you for 2., battle view open on the ghoul.
  - Greyscale variants of all six verified legible: names, bar-length + numbers, the range word, the strip, the armed word — no state carried by hue.
- Band lines: running on branch and baseline for the byte-identical quote, results next entry. Final three-suite run in flight.

Disposed through dispatcher entry 2.
## 6 — worker — 2026-09-02T17:15:20+07:00
DONE — `m3-battle-ui` built, verified, and reported. REPORT.md is in this directory; it mirrors the full verification block.

- Final counts from my own result files: core 793, content 541, app 560 (515 + 45 new tests, each accounted); analyze + format clean from the worktree root, pwd quoted in the report; eight commits on `m3-battle-ui, none on `main, tree clean; `packages/core` and `packages/content` untouched.
- Band lines: five (plus the ordering summary) byte-identical between the branch and `d576d1c, `diff` empty, quoted in REPORT.md.
- Mutation table M1–M6: both halves, named sets, tree clean after every row.
- AVD pass: complete per the full ritual; six acceptance shots + six greyscale variants in `docs/reports/shots/m3-battle-ui/`; both playtest save slots restored, checksums matching the pre-install copies.
- Riders 30 and 31 closed (30 on-device in `shot-01`; 31 pinned by `skills_row_spacing_test.dart` at the phone surface).
- Spec claims found wrong: the arrivals formula (your D86 ruling), the "three copies" count (two widget copies), and the post-spend precision in the engine's schedule call — all pre-declared, all in REPORT.md section 11.
- Standing watch: still running, left to expire (no kill confirmed); a fresh dispatcher entry will wake me through it. Emulator left running, playtest saves restored and verified.
- Disposed through dispatcher entry 2 (no new mail since entry 2).

Worker stopping here.
