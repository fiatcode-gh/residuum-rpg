M2Q DONE. Branch `m2-qol, 12 commits, tree clean, nothing pushed (per instruction — the repo does have an origin, I left it alone). Full verification block is mirrored to `BUILD-REPORT.md` in the worktree root, committed. Screenshots (33) are in `docs/epic/m2-qol-shots/` — gitignored, nothing committed under `docs/epic/`.

Headline: all three suites green, survivability exactly 25/40 stalled 0, content byte-identical to main, and I found four things wrong — two in the spec, one on the device, one in your sequencing trap.

=== NUMBERS ===

Baseline re-measured by me at 8596adb before the first commit: 352 core + 95 content + 67 app = 514. Matched your figure exactly.

Final at HEAD: 389 core + 95 content + 129 app = 613 (net +99).
`flutter analyze`: No issues found. `dart format --set-exit-if-changed .`: 0 changed.
`git diff main --stat -- packages/content`: empty.
`survivability: 25/40 won (62.5%), stalled 0, died at 1:2 2:6 3:6 4:1 5:25`.

Camera cell size shipped: 36dp, unchanged. Measured ~93 real px of glyph spacing on the Pixel_10 against a computed 94.5, so the constant is what reaches the screen. No reason on device to tune it — taps landed where aimed through a three-rat fight.

=== FOUR FINDINGS ===

1. C2's arrange is off by one. At `inventoryCap - 1` the pack lands exactly AT the cap; overflow needs a full pack of 20 (20-1+2=21). The two-hander must itself be carried to be equipped, so 19 carried become 18, plus two displaced, which is exactly 20. Both boundaries pinned, both passed against unmodified code. The quirk is real and preserved; only your arrange was wrong.

2. The dungeon does not clamp hit points on equip, so spec item 4 forks the rule. `step` calls `_clampedToMaxHp` only on the unequip path (step.dart:108); the EquipAction path never clamps. That is not a no-op: equipping into an OCCUPIED slot displaces the worn piece, and if that piece carried +max-hp the ceiling drops while hit points stay put. Reachable on any armour swap the survivability bot makes, since it ranks armour by `armor + maxHp`. Pinned by two characterization tests that pass against unmodified code.

   I proceeded on option (a) — town clamps on both paths, dungeon unchanged — because unifying it (c) would change dungeon behaviour this unit freezes and would almost certainly move 25/40, while mirroring the dungeon (b) would leave the town screen printing "24 / 20" at the player (TownScreen prints `state.hp` raw; the crawl screen hides the same state because game_screen.dart:54 clamps the display). The divergence is named and argued in `clampedToMaxHp`'s dartdoc rather than left silent, both sides are pinned by test, and it is logged as a follow-up ruling. If you want (b) instead it is one line on my side; (c) needs your ruling because it re-baselines 25/40.

3. NEW, found by the playthrough, not by any test: the potion count did not fit the button. Spec item 5 mandates `Drink potion (N)`. On the stairs with an item underfoot, four controls share the row and Flutter ellipsized it to `Drink poti…` — throwing away the count, which is the only part of that label a player cannot read anywhere else. Evidence in shots 16 and 25. I shortened it to `Drink (N), which fits with ~14dp spare at four controls, and verified on device (shot 29). This is a deliberate deviation from your literal string in service of your measurable ("all five D19 items visible in play") — a clipped count is not visible. Reason recorded in `_Controls`' dartdoc. Say the word if you want the wording back and the layout solved differently.

4. Your sequencing trap S1 named only C1, but a SECOND test pinned the same silence: `GameBloc auto-walk a walk does not start while a monster is already in view` asserted zero emissions, so it also broke when the refusal started emitting. Updated in the same commit to assert the surviving invariant (no walk starts) rather than the absence of emissions.

Your shared-predicate claim held up, and mutation row 5 proves it: dropping the `visible` filter reddens the Engaged count AND both walk-refusal tests through the single `enemiesInSight` getter. `_somethingIsWatching` is deleted; there is no second expression.

=== MUTATION TABLE: ROW 11 EARNED ITS KEEP ===

All ten rows run, both halves, plus four extensions — full table with test names in BUILD-REPORT.md section 4.

Extension row 11 (reverse the displacement order in `wear`) found a real gap. On its first run it reddened ONLY the rule-level test in `wear_test.dart`; the entire `step` suite stayed green. The existing two-hander test in `step_loot_test.dart` wears a shield and no weapon, so exactly one piece is displaced and the order cannot be observed. Your Hazards section calls event order the extraction's chief hazard and names those tests as the canary — they were not. Commit 216e668 adds a step-level test pinning all three events in order; row 11 now reddens at both levels.

The other three extensions: row 12 (a handler carries the pan forward) reds the snap-back test, so the by-construction claim is actually tested rather than merely asserted; row 13 (y origin computed from the x axis — the classic copy-paste bug) reds two camera tests; row 14 (`takeOff` stows at the front) reds the pack-order test.

=== PRE-DECLARED DEVIATIONS, ALL SHIPPED AS DECLARED ===

`wear.dart` hosts the take-off rule too, not just equip; refusal reasons are shared as plain strings so `step` wraps them in ActionRefused and town in TownRefusal (town therefore inherits the dungeon's exact wording, `slot.name` awkwardness included — preserved, not improved); `clampedToMaxHp` is public in `wear.dart` with three call sites; `enemiesInSight` is the single home; `cameraCellSize` is a top-level const in grid_geometry.dart.

One shape detail I decided without declaring because it is internal: `Worn` carries `taken` (pieces that came off, in announce order) and `put` (the piece that went on, null for a take-off), so `step` emits uniformly for both directions and the event order lives in the data rather than in a loop.

Two under-determined contract cases decided and tested: an extent exactly equal to the viewport counts as FITTING (centred, pan-deaf — nothing is hidden at equality); a pan carries an auto-walk through rather than cancelling it (panning is not a hero action, and the walk's next step resets the camera anyway).

=== PLAYTHROUGH ===

Pixel_10, 33 screenshots, every scene in your definition of done except two, both argued in the report: take-off-with-a-full-pack needs twenty carried items (covered by two tests plus mutation row 8 — and note the Gear screen's other refusals are unreachable by design, since it only ever offers legal actions), and buy-then-wear needs a completed run's gold, so I did the same flow with dungeon loot instead (carried gauntlets home, wore them in town, took them back down — Armour 4 in the crawl).

Worth knowing for the ledger: `adb shell input swipe` at 400ms emits too few motion samples for Flutter's pan recogniser and looks like a broken pan. At 1200ms it pans correctly. Tooling artifact, not an app bug — I chased it for three screenshots before working it out. Pan fires no tap (log unchanged across a long pan) and tap still works under the camera ("You step east" after tapping the adjacent cell).

Greyscale check done on all four changed screens with `magick -colorspace Gray`. Everything reads: words, positions, `·`/`+` markings, `▲`/`▼` shapes with signed numbers. The arrows and `×` render on the device's monospace fallback, no tofu.

=== WHAT THE TESTS CANNOT PROVE ===

Whether 36dp is the right size (tests pin that it is fixed, not that it is comfortable); that pan and tap coexist (no widget tests allowed, so the playthrough is the only evidence); the paint cost of the camera (the painter still walks every tile, off-screen glyphs are clipped not skipped — felt smooth, not profiled); and whether my refusal wording grates, since a player jabbing at a far tile stacks identical lines (visible in shot 11 — honest but slightly noisy).

Per-task reviewer subagents were skipped, per ledger D9. The argument, stated plainly: the mutation table found the event-order gap and the playthrough found the truncated label, and neither would have survived a reading-based review — one needed a mutation, the other needed a real screen. The cost is that no fresh eyes read the diff for style drift; analyze is clean and the diff follows the surrounding idiom, but that is my judgement of my own code and you should weigh it as such.

=== FOLLOW-UPS FOR THE LEDGER ===

- Unify the equip hit point clamp (finding 2) — needs your ruling, re-baselines 25/40.
- The cap-overflow-on-displacement quirk is pinned in both contexts and still wants a ruling, as you anticipated.
- Stacking for the merchant stock and bank lists — scoped out here; `packSections` and `stackKey` are ready for them.
- Consider collapsing an immediate repeat in the message log (repeated refusal lines).

=== NOTE ON THE HANDOFF CHANNEL ===

Your own handoff record warns: "always `--bg` — interactive sessions hold cross-session messages behind an approval gate that expires". Both my SendMessage attempts were held for approval and never delivered, because `ListAgents` showed two sessions named `[arch] residuum-rpg` and I picked the interactive one ([0958c2]) since the kickoff arrived with `from-mode="prompting"`. The `--bg` one was [114a3e]. Worth adding to the record that the trap bites the reply direction too, not just the kickoff, and that a build session cannot tell the two apart from the kickoff metadata alone.
