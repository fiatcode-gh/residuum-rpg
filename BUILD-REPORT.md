# Build report — M2Q "Quality of life" (unit `m2-qol`)

Branch `m2-qol`, base `main` @ `8596adb`. Every item below is evidenced by the
command output that produced it.

Screenshots referenced here live outside the repository, in the gitignored
ledger directory:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m2-qol-shots/`

---

## 1. Work happened in the worktree; commits are on `m2-qol`, none on `main`

```
$ git rev-parse --show-toplevel
/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m2-qol

$ git log --oneline main..HEAD
216e668 test: pin step's event order when two pieces are displaced
a3fc634 feat: a gear room in town
6da754e feat: a pack that explains what it is carrying
7c34db7 feat: say when something is watching, and count the potions
7f04974 feat: read an item's numbers, grouped and stacked
4c18926 feat: wear and take off gear in town
acfc1ea refactor: one home for the wear rule
eece689 feat: a camera that follows the hero and pans by hand
cd99108 feat: a camera origin at a fixed cell size
9ae8b2e test: characterize the wear rules and the silent refusal before changing them
```

Eleven commits including this report. Nothing was pushed, no pull request was
opened, no branch other than `m2-qol` was touched.

## 2. Test counts against the stated baseline

**Baseline re-measured by me before the first commit**, at `8596adb` with a
clean tree, and it matched the architect's figure exactly:

```
+352: All tests passed!   (core)
+95:  All tests passed!   (content)
+67:  All tests passed!   (app)
                          = 514
```

Final, measured fresh at `216e668`:

```
=== core
00:01 +389: All tests passed!
=== content
survivability: 25/40 won (62.5%), stalled 0, died at 1:2 2:6 3:6 4:1 5:25
00:04 +95: All tests passed!
=== app
00:02 +129: All tests passed!
```

**389 core + 95 content + 129 app = 613** (baseline 514, net +99). Content is
unchanged in both count and content.

## 3. C1–C3 passed against unmodified code

Run before any behaviour change landed, and committed as `9ae8b2e` — the first
commit on the branch, which contains tests only.

C2 plus the hit point characterization, against unmodified `core`:

```
$ flutter test test/engine/step_wear_characterization_test.dart
00:00 +1: EquipAction displacement against the pack cap a full pack ends over the cap when two pieces are displaced
00:00 +2: EquipAction displacement against the pack cap a pack one short of the cap ends exactly at the cap
00:00 +3: EquipAction against the hit point ceiling does not clamp hit points when a swap lowers the ceiling
00:00 +4: EquipAction against the hit point ceiling clamps hit points when the same swap is done by taking off
00:00 +4: All tests passed!
```

C1, against unmodified `app`:

```
$ flutter test test/game_bloc_test.dart --plain-name "a refused walk says nothing at all"
00:01 +1: All tests passed!
```

C3 is the existing equip and unequip suites. They pass **unchanged** in
`acfc1ea`, the commit that moves the code: that commit touches
`packages/core/lib/**` and adds `test/loot/wear_test.dart`, and modifies no
existing test file.

## 4. Mutation table — every row, both halves

Ten spec rows plus four extensions. Each mutation applied alone and reverted
immediately; the working tree was confirmed clean between rows.

| # | Mutation | Went red | Stayed green |
|---|---|---|---|
| 1 | Camera factory derives `cellSize` with `fit`'s `min()` instead of the constant | `GridGeometry.camera` — uses the fixed cell size however small the viewport · centres an axis whose whole extent fits · ignores pan on an axis whose whole extent fits · centres the focus cell on an overflowing axis · clamps at the far edges rather than showing void · shifts by the pan before clamping · holds the fixed cell size when one axis fits and one does not (7) | every `GridGeometry.fit` test; all 389 core tests |
| 2 | Camera factory: remove the edge clamp | `GridGeometry.camera` — a pan past the edge clamps instead of running off · clamps at the far edges rather than showing void · clamps at the near edges rather than showing void (3) | fitting-axis tests: centres an axis whose whole extent fits · ignores pan on an axis whose whole extent fits · treats an extent exactly filling the viewport as fitting |
| 3 | Stack key includes `item.id` | `stackKey` two items of the same make and tier share a key · `packSections` gathers items that are alike into one row with a count · `packSections` a stack acts through one item of itself (3) | all 7 `statLine` tests; all core loot tests |
| 4 | Delta emits absolute values (drops the sign) | `wornDeltas` reads an empty slot as a comparison against nothing · marks a better piece with a rising arrow · marks a worse piece with a falling arrow · says both halves of a mixed trade · collapses an attack change that moves both ends alike · splits an attack change whose ends move differently · `deltaLine` joins the markers it was given (7) | all `stackKey`, `packSections` and `ItemStack` tests |
| 5 | `enemiesInSight` drops the `visible` filter | **both halves through the one getter.** Engaged count: `GameBloc under a watching eye` counts only the monsters the hero can see. Walk refusal: `GameBloc under a watching eye` a walk starts when nothing is in sight · `GameBloc auto-walk` a monster coming into view stops the walk where it stands (3) | core field-of-view suite (`test/dungeon/fov_test.dart`) |
| 6 | `_onTileTapped` removes the refusal log append | `GameBloc under a watching eye` a refused walk says why and takes no step (1) | walk-interrupt (`ActorNoticed`) tests: a monster coming into view stops the walk where it stands · a walk stops short of its destination when something intercepts it |
| 7 | Town `equipItem` skips the refusal check before mutating | `equipItem` refuses what the hero is not carrying and changes nothing · refuses a piece that is not worn at all · refuses a shield while both hands are on the weapon (3) | the whole `core/test/engine` suite, step's equip refusal tests included — the mutation is town-side only |
| 8 | Town `unequipItem` drops the full-pack refusal | `unequipItem` refuses a full pack rather than dropping the gear (1) | `withdrawItem` cap test: the bank — withdrawItem brings it back, and the pack cap applies |
| 9 | `equipItem`/`unequipItem` drop the hp clamp | `equipItem` brings hit points inside the ceiling the new loadout allows · `unequipItem` brings hit points down with the max-hp gear it took off (2) | all four `restAtInn` tests |
| 10 | **CONTROL** — no mutation, content suite | — | `survivability: 25/40 won (62.5%), stalled 0`; 95/95 green |
| 11 | **EXTENSION** — reverse the displacement order in `wear` | `wear` a two-hander displaces the weapon then the shield, in that order · `EquipAction event order with two pieces displaced` announces the weapon, then the shield, then what went on (2) | whole app suite |
| 12 | **EXTENSION** — a handler carries the pan forward | `GameBloc panning` reaching into the pack snaps the camera back (1) | rest of the app suite |
| 13 | **EXTENSION** — the y origin is computed from the x axis (copy-paste bug) | `GridGeometry.camera` holds the fixed cell size when one axis fits and one does not · shifts by the pan before clamping (2) | rest of the app suite |
| 14 | **EXTENSION** — `takeOff` stows at the front of the pack | `takeOff` moves the piece to the end of the pack (1) | rest of the core suite |

**Row 11 caught a real gap, which is why it exists.** On its first run it
reddened only the rule-level test in `wear_test.dart`; the whole `step` suite
stayed green. The existing two-hander test in `step_loot_test.dart` wears a
shield and no weapon, so exactly one piece is displaced and the order cannot be
observed. The spec's Hazards section names event order as the extraction's chief
hazard and names those tests as the canary — they were not. Commit `216e668`
adds a step-level test that pins all three events in order; row 11 now reddens
at both levels.

Sequencing trap S1 was honoured: C1 asserted today's silence, was run and
recorded green against unmodified code, and was **deleted** — not weakened — in
`7c34db7`, the commit that adds the refusal line, replaced by `a refused walk
says why and takes no step`.

## 5. Survivability

```
survivability: 25/40 won (62.5%), stalled 0, died at 1:2 2:6 3:6 4:1 5:25
```

Exactly 25/40, stalled 0. Unchanged from the base measurement I took before
writing any code. Zero balance movement.

## 6. Analyzer and formatter

```
$ flutter analyze
Analyzing m2-qol...
No issues found! (ran in 3.1s)

$ dart format --set-exit-if-changed .
Formatted 88 files (0 changed) in 0.20 seconds.
```

## 7. Forbidden levers untouched

```
$ git diff main --stat -- packages/content
$
```

Empty. `packages/content` is byte-identical to `main`: no bestiary, no
spawn or drop table, no price, no xp curve, nothing.

## 8. Hygiene

No body comments in the diff (dartdoc `///` and the mandated
`// arrange` / `// act` / `// assert` markers excluded):

```
$ git diff main -- '*.dart' | grep -E "^\+[[:space:]]*//" \
    | grep -vE "^\+[[:space:]]*///" \
    | grep -vE "^\+[[:space:]]*// (arrange|act|assert)$"
(none)
```

No unseeded `Random()` anywhere in the diff:

```
$ git diff main -- '*.dart' | grep -E "^\+.*\bRandom\("
(none)
```

## 9. AVD playthrough — `Pixel_10`

Every scene in the spec's definition of done, with screenshots. The device is
1080×2424 at density 2.625, so a 36dp cell measures 94.5 real pixels — the
glyph spacing in the screenshots measures ~93px, confirming the fixed cell size
is what actually reaches the screen.

| Scene | Evidence | Result |
|---|---|---|
| Camera-follow viewport at the new cell size | `03-crawl-camera.png` | Cells ~36dp; hero framed; map clipped at the viewport, not shrunk to fit |
| Pan away, clamped direction | `04-panned.png` | A rightward pan at the map's left edge moves nothing — the clamp refuses to uncover void |
| Pan away, free direction | `07-slow-pan.png` | The view pans far left and clamps; the log is unchanged, so **the pan fired no tap** |
| Snap-back on the next hero action | `08-snapback.png` | The camera returns to exactly the pre-pan framing |
| Tap semantics under the camera | `06-after-tap.png` | Tapping the cell east of the hero logs "You step east" — `positionAt` inverts the camera correctly on device |
| Engaged indicator appearing | `09-explore.png`, `11-approach.png`, `12-melee.png` | `Engaged 1`, then `2`, then `3` as monsters enter sight |
| Engaged indicator vanishing | `15-fight3.png` | Gone once the last rat dies |
| A refused walk showing the log line | `10-refusal.png` | "Something is watching. You stay put." — hero did not move |
| Surrounded fight won by tapping adjacent enemies | `13-fight.png`, `14-fight2.png`, `15-fight3.png` | Three rats engaged, all killed by tapping them at the new cell size |
| Stat lines and three fixed sections | `18-pack.png` | WEAPONS / ARMOUR / POTIONS, each with `+3-5 atk`-style lines |
| Wear decision made from the delta markers | `18-pack.png`, `19-worn.png` | Iron Sword read `▲+1 atk min · ▲+2 atk max`; after wearing it the displaced Rusty Sword reads `▼-1 atk min · ▼-2 atk max`. Both delta directions and the split-range branch, on device |
| Empty-slot comparison | `18-pack.png` | Iron Helm into a bare head slot reads `▲+2 arm` |
| Stacked potion row with a count | `22-stack.png` | `Common Healing Potion ×2` — two different ids, one row |
| Potion count on the button | `03`, `08`, `23`, `29` | `Drink (2)` → `Drink (1)` after drinking → `Drink (2)` after picking one up |
| Event order preserved after the extraction | `20-explore2.png` | Log reads "You take off Common Rusty Sword (main hand)." then "You put on Common Iron Sword (main hand)." — `ItemUnequipped` before `ItemEquipped`, as before |
| Gear room reachable from town | `01-town.png`, `02-gear.png` | Gear door beside Merchant, Bank, Inn |
| Wear in town | `26-town-gear.png`, `27-worn-in-town.png` | Fine Sturdy Iron Gauntlets moved from the pack into the `hands` slot; rarity markings `·` Common and `+` Fine |
| Wear in town → enter the dungeon wearing it | `28-dungeon-wearing.png` | Armour 4 in the crawl, gauntlets in the `hands` slot |
| Take off in town | `02-gear.png`, `27-worn-in-town.png` | `Take off` offered on every occupied slot, on none of the empty ones |

**Greyscale check of each changed screen** (`magick … -colorspace Gray`):

- `grey-10-refusal.png` — crawl: `Engaged 1` is a word plus a number; the
  refusal is a sentence; fog is a brightness difference; monsters stay
  distinguishable because the glyph is a letter and walls and floors are `#`
  and `.`.
- `grey-22-stack.png` — pack: sections by heading word and position, rarity by
  the marking column, stats as labelled signed numbers, deltas as `▲`/`▼` plus
  a signed number. Nothing needs hue.
- `grey-26-town-gear.png` — gear room: same encodings; empty slots are dashes.
- `grey-01-town.png` — town: the Gear door is a word in a fixed list position.

The `▲` and `▼` arrows and the `×` render correctly on the device's monospace
fallback — no tofu.

**Two scenes were not reachable by hand, and why:**

- **Take-off refused with a full pack.** This needs twenty carried items. The
  Gear screen only ever offers legal actions, so its other refusals cannot be
  triggered at all from the interface: it lists no potions (so "is not worn" is
  unreachable), and it hides `Wear` on nothing. The full-pack case is the only
  reachable refusal and it needs a very long crawl to set up. It is covered by
  `a full pack refuses the take-off rather than dropping the gear` in the town
  bloc suite and by `unequipItem refuses a full pack rather than dropping the
  gear` in core, and mutation row 8 proves both bite. That the Gear screen's
  refusal notice is nearly unreachable is a property of the screen rather than
  a gap: the controls are gated on the rules.
- **Buy in town → wear in town.** A fresh profile carries no gold, so buying
  requires a completed run's earnings. I did the same flow with dungeon loot
  instead — carried the gauntlets home, wore them in town, took them back down
  — which exercises every line the buy path would (`buyItem` already puts the
  item in the pack, and the Gear screen reads the pack). The buy step itself is
  unchanged by this unit.

## 10. What the tests cannot prove

- **Whether 36dp is the right cell size.** The tests pin that the size is
  fixed, not that it is comfortable. On the Pixel_10 it measured 94.5 real
  pixels, which is a comfortable thumb target and clears the 48dp guideline
  with margin. On a small phone it will show fewer tiles, and how much
  visibility a player will trade for that is a judgement no test makes.
- **That pan and tap coexist.** No widget tests are allowed here, so nothing in
  the suite touches the gesture arena. The playthrough is the only evidence:
  `07-slow-pan.png` panned a long way with the log unchanged (no tap fired),
  and `06-after-tap.png` tapped and stepped without panning.
- **How much the camera costs to paint.** The painter still walks every tile;
  off-screen glyphs are clipped rather than skipped. It felt smooth on the
  emulator and the tile count is unchanged from the fitted view, but nothing
  was profiled.
- **Whether the log line reads well in play.** "Something is watching. You stay
  put." was mine to word. It appears once per refused tap, which means a player
  jabbing at a far tile during a fight will stack repeats — visible in
  `11-approach.png`, two identical lines in a row. That is honest but slightly
  noisy, and only play tells you whether it grates.
- **Whether the label fits at four controls.** See finding 3 below. Measured to
  fit with roughly 14dp to spare; verified on screen only at two controls.

## 11. Spec claims I checked and found wrong

**Finding 1 — C2's arrange is off by one (spec, "Test plan", C2).**
The spec says equipping a two-hander over weapon plus shield "with a pack at
`inventoryCap - 1` succeeds and leaves the pack over the cap". It does not: the
two-hander must itself be carried, so nineteen carried items become
eighteen, plus two displaced, which is exactly twenty — at the cap, not over
it. Overflow needs a full pack of twenty: 20 − 1 + 2 = 21. Both boundaries are
now pinned, and both passed against unmodified code. The quirk itself is real
and is preserved; only the spec's arrange was wrong.

**Finding 2 — the dungeon does not clamp hit points on equip, so spec item 4
forks the rule (spec, "Per-item contract", 4).**
The spec says town `equipItem` should "mirror `_clampedToMaxHp`". But `step`
calls that clamp only on the unequip path. Equipping into an occupied slot
displaces the worn piece, and if that piece carried +max-hp the ceiling drops
while hit points stay put — reachable on any armour swap the survivability bot
makes, since it ranks armour by `armor + maxHp`. Pinned by two passing
characterization tests against unmodified code.

I reported this to the architect with three options and proceeded on the
spec's own choice (town clamps, dungeon does not), because unifying it would
change dungeon behaviour this unit freezes and would almost certainly move
25/40, while mirroring the dungeon would leave the town screen printing
"24 / 20" at the player. The divergence is named and argued in
`clampedToMaxHp`'s dartdoc rather than left silent, both sides are pinned by
test, and unifying it is logged below as a ruling for the architect.

**Finding 3 — the potion count did not fit the button (found by playthrough,
not by the spec).**
Spec item 5 mandates the label `Drink potion (N)`. On the stairs with an item
underfoot, four controls share the row and Flutter ellipsized it to
`Drink poti…` — throwing away the count, which is the only part of that label
the player cannot read anywhere else. Evidence: `16-at-helm.png`
(`Drink potion (…)`, three controls) and `25-stairs.png` (`Drink poti…`, four
controls). I shortened the label to `Drink (N)`, which fits with roughly 14dp
to spare at four controls, and verified it on device (`29-label-fixed.png`).
This is a deliberate deviation from the spec's literal string in service of the
spec's measurable — "all five D19 items visible in play" — since a clipped
count is not visible. The reason is recorded in `_Controls`' dartdoc.

**Finding 4 — S1 named only C1, but a second test pinned the same silence.**
`GameBloc auto-walk a walk does not start while a monster is already in view`
asserted `expect: () => <GameViewState>[]`, so it also broke when the refusal
started emitting. It is updated in the same commit to assert the surviving
invariant (no walk starts) rather than the absence of emissions.

**One recon claim confirmed rather than refuted:** the shared-predicate design
works exactly as claimed. Mutation row 5 reddens the Engaged count and both
walk-refusal tests through the single `enemiesInSight` getter.

## 12. Execution phases — which ran, and why any were skipped

- **Clarify / adversarial spec read** — ran first, before any code. Produced
  findings 1 and 2, which went to the architect before implementation started.
- **Characterization (C1–C3)** — ran against unmodified code, committed alone
  as `9ae8b2e`.
- **Design and plan** — ran, via the `writing-plans` skill. Plan committed at
  `docs/superpowers/plans/2026-08-21-m2-qol.md`, nine tasks with interfaces and
  step-level test code.
- **Test-driven implementation** — ran, red then green then commit, per task.
  Every red state was observed and quoted before the implementation was written.
- **Mutation table** — ran, all ten rows plus four extensions.
- **Playthrough** — ran on `Pixel_10`, thirty-three screenshots.
- **Per-task reviewer subagents — SKIPPED, and here is the argument.** Ledger
  D9 accepts inline execution with the mutation table carrying the adversarial
  load, and that is what happened: the table is what found the event-order gap
  (row 11) that no reviewer had flagged, and the playthrough is what found the
  truncated label (finding 3). Both are defects a reading-based review would
  have missed, because one needed a mutation to expose and the other needed a
  real screen. The cost of the skip is that no fresh pair of eyes read the
  diff for style or naming drift; `flutter analyze` is clean and the diff
  follows the surrounding idiom, but that is my own judgement of my own code
  and the architect should weigh it as such.
- **Delegation to write-capable subagents — SKIPPED deliberately.** Standing
  guidance is that subagents dispatched into a worktree do not inherit cwd and
  may commit in the parent repository. Every commit here is on `m2-qol` and
  none of them came from a subagent.

## 13. The camera cell size I shipped

**36 logical dp**, the spec's suggested value, unchanged. It is defined once,
as `cameraCellSize` in `packages/app/lib/game/grid_geometry.dart`. On the
Pixel_10 that measured ~93 real pixels of glyph spacing against a computed
94.5, so the constant is what reaches the screen and it clears the 48dp touch
guideline comfortably. I saw no reason on device to tune it: taps landed where
aimed through a three-rat fight without a single mis-tap.

---

## Follow-ups for the ledger

- **Unify the equip hit point clamp** (finding 2). The dungeon clamps on
  take-off but not on wear; the town clamps on both. Unifying means changing
  frozen dungeon behaviour and re-baselining the survivability number, so it
  needs an architect ruling rather than a build decision.
- **The cap-overflow-on-displacement quirk** is pinned in both contexts and
  still wants a ruling, as the spec anticipated.
- **Stacking for the merchant stock and bank lists** — scoped out here; both
  screens still list items one row each. `packSections` and `stackKey` are
  ready for them.
- **Repeated refusal lines.** A player tapping a far tile several times during
  a fight gets the same sentence stacked. Worth considering whether the log
  should collapse an immediate repeat.
