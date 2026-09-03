# m3-battle-ui Implementation Plan

> Execute test-first, task by task. Binding rules: characterization green
> against unmodified `d576d1c` before any change; the spell-row extraction
> lands as a verbatim-lift refactor commit before the battle view consumes
> it; the `castRefusal` mirror fix lands before the targeting gesture; every
> commit's exit state green; app-only — `packages/core` and
> `packages/content` untouched; all five band lines byte-identical controls;
> `docs/` never committed; conventional commits, author persona
> `.

**Goal:** the battle screen over unit A's rules — stage cards, turn strip,
skill bar with armed tap-to-target through core's `targetId, the drifted
`castRefusal` mirror fixed, ranged verb + ambush beat, riders 30/31.
**Spec:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-ui-spec-M3U.md`

## Global constraints

- Worktree `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui, branch `m3-battle-ui, baseline `d576d1c`.
- Baseline counts (measured fresh): core 793, content 541, app 515 = 1849. Core and content stay 793/541 — any movement is a leak, stop.
- Mutation table M1–M6 with both halves as NAMED SETS, tree verified clean after each row.
- `find.textContaining` case-sensitive in Flutter 3.47; `scrollUntilVisible` one-way; at least one phone-sized test (`_onAPhone` = 1080×2424 @ dpr 2.625).
- Status line stays ONE string. Greyscale doctrine: state by shape, marking, position, word — never hue alone.
- No pushes, no PRs, no `tea`. The AVD pass is mandatory with the full save-aside ritual.
- HOLD: `arrivals` waits for the architect's ruling on the turns-to-arrival formula (worker entry 2, item 6). Task 8 builds it only after the ack.

## Pre-declared decisions (worker entry 2, binding for this plan)

1. `upNext` passes `heroEnergy: game.hero.energy - actCost` — the engine's phase schedules with the hero's post-spend energy.
2. Armed-skill survival set: `MapPanned, `SystemBackPressed, `_stopWalking, `TileTapped` watched-refusal branch, `TileTapped` walk-start branch. Reset set: every handler that steps.
3. Ambush beat: `AttackHit`/`AttackDodged` with `attackerId != heroId && targetId == heroId`; at most one beat per step; lands before the first monster-attack sentence; bump-attacks never fire it.
4. Shared `SpellRow` takes styles and optionality as parameters; both existing call sites render byte-identically to today.

### Task 0: Characterization tests (against unmodified `d576d1c`)

**Files:** `packages/app/test/battle_characterization_test.dart` (new).

- [ ] Write tests pinning CURRENT behavior, quoted green against `d576d1c`:
  - Pack spell row: marking column, name, `'{schoolWord} · {manaCost} mana'` plus the effect suffix (`2-4 fire ✳` shape for Firebolt), Cast button enabled with no reason, disabled with the reason sentence rendered under the row.
  - Character screen spell row: marking, name, subtitle WITHOUT effect suffix, no Cast button.
  - Crawl structure with an adjacent monster: status line carries `Engaged 1, control row labels, log shows the monster's `claws` sentence.
- [ ] `cd packages/app && flutter test test/battle_characterization_test.dart` — green at `d576d1c`.
- [ ] No commit yet — these ride with Task 1's commit? No: commit them alone first (green at baseline), `test: pin the spell-row and crawl-screen behavior the battle unit lifts`.

### Task 1: Spell-row extraction (verbatim lift, refactor commit)

**Files:** `packages/app/lib/game/spell_row.dart` (new), `packages/app/lib/game/inventory_screen.dart, `packages/app/lib/town/character_screen.dart`.

- [ ] Move the row grammar to `SpellRow(spell, {reason, detail, trailing, style, detailStyle})`; pack passes its 13/11 styles + effect detail + Cast button; character passes town 14/12 styles, no button, no detail. Both screens render byte-identically (Task 0 pins stay green untouched).
- [ ] All three suites green, quoted; `dart analyze .` clean.
- [ ] Commit `refactor: lift the spell-row grammar into one shared piece (fourth copy forbidden)`.

### Task 2: castRefusal mirror fix (before any gesture)

**Files:** `packages/app/lib/game/game_bloc.dart, `packages/app/test/game_bloc_test.dart`.

- [ ] Red: shared-fixture test asserting the app's `castRefusal(spell, targetId: invisibleId)` returns `'you cannot see that target'` — the same sentence core's `step` refuses with for the same state; also pin the Pack path (no target → nearest fallback unchanged).
- [ ] Green: `castRefusal` gains the optional `targetId` and the target branch, order matching core's `_castRefusal` (dead → mana → target-visibility → no-enemy-in-sight).
- [] Commit `fix: mirror core's cast target refusal into the app's castRefusal`.

### Task 3: Derived state — `monstersHoldingReach, `upNext, open/close, armed selection (NO arrivals — held)

**Files:** `packages/app/lib/game/game_bloc.dart, `packages/app/test/game_bloc_test.dart`.

- [ ] Red: adjacent monster in `monstersHoldingReach`; spitter within 3 along LoS in; spitter out of LoS or beyond 3 out; empty floor empty. `upNext`: fast monster twice; ambush-charged (post-spend) energy respected; bound monster filtered. Open/close getter non-empty ⇔ battle view. Armed survives the survival-set handlers, resets on step handlers and completed casts (the M3 pin).
- [ ] Green: pure getters over `game`; armed skill as `GameViewState` field on the `hasFled` shape, named in the survival-set handlers only.
- [ ] Commit `feat: battle derived state — reach holders, turn schedule, armed skill`.

### Task 4: Ranged verb + ambush beat

**Files:** `packages/app/lib/game/event_messages.dart, `packages/app/lib/game/game_bloc.dart, tests in `packages/app/test/game_bloc_test.dart`.

- [ ] Red: spitter's attack reads `strikes you from afar for N`; ghoul keeps `claws`; ambush beat `The {name} gets the drop on you.` precedes the hit on an opening swing and never on ordinary swings (M5/M6 pins).
- [ ] Green per the pre-declared detection rule.
- [ ] Commit `feat: ranged verb and the ambush beat in the battle log`.

### Task 5: Battle view widget + gestures + CastPressed targetId

**Files:** `packages/app/lib/game/battle_view.dart` (new), `packages/app/lib/game/game_bloc.dart, `packages/app/lib/game/game_screen.dart, `packages/app/test/battle_view_test.dart` (new).

- [ ] Red: `CastPressed` carries optional `targetId` through to `CastSpellAction(spellId, targetId: …)` (M4 site); stage card content (glyph, name, HP numbers, reach word); turn strip (`Next: {name}, arrivals once unheld); skill bar (marking + name + cost, wrap-flow, armed by position + word, silent for non-casters); armed cast dispatches with target; tap without armed skill = `MoveAction` bump; Mend/Ward need no target; out-of-sight refusal lands in the log, button stays tappable; battle view opens on reach and closes when it empties (M1/M2 pins); phone-sized surface test.
- [ ] Green: the battle view swaps into the map `Expanded` slot while `monstersHoldingReach` is non-empty; `_HitPoints, `_Controls, `_MessageLog, death overlay untouched.
- [ ] Commit `feat: the battle view — stage, turn strip, skill bar, tap-to-target`.

### Task 6: Rider 31 — skills-row spacing

**Files:** `packages/app/lib/game/inventory_screen.dart, test in `packages/app/test/widget/`.

- [ ] Red: at `_onAPhone` the skills row renders `Blacksmith` and `0` with visible separation (assert the name Text's right edge < the level Text's left edge).
- [ ] Green: separation added; the row reads `Blacksmith 0`.
- [ ] Commit `fix: give the pack's skills row its missing separation (follow-up 31)`.

### Task 7: `arrivals` — UNBLOCKED only by the architect's formula ruling

**Files:** `packages/app/lib/game/game_bloc.dart, `packages/app/test/game_bloc_test.dart`.

- [ ] Implement per the ruling; red-first `arrivals` tests (flow distance ÷ speed per the ruled formula, rounded up; unreachable excluded).
- [ ] Commit `feat: turn-strip arrivals`.

### Task 8: Mutation table M1–M6

Not a commit. Run every row against the branch; record named red sets and green controls; verify `git status` clean after each revert. A row that reddens nothing is a hole.

### Task 9: AVD pass (mandatory, unsandboxed)

Full ritual: `md5` both save slots aside BEFORE any install; storage-trap resolution only after the copies verify; `run-as stdin` restore; serial pinned `-s emulator-5554`; greyscale variant of every acceptance shot into `docs/reports/shots/m3-battle-ui/` (MAIN repo, untracked). Shots: ambush opening, spitter on stage at range, skill bar + armed cast, turn strip, crawl view returning, status line at phone surface (follow-up 30). Restore saves, quote checksums.

### Task 10: Verification block and report

`flow-verification`: fresh counts from own result files (core 793, content 541, app 515+delta explained), band lines byte-identical quoted, `dart analyze .` + `dart format --set-exit-if-changed .` from the worktree root with `pwd` quoted, `git log main..HEAD --oneline, REPORT.md in the channel, done notice as a worker entry.