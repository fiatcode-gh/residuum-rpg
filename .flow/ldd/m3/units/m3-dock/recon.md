# Recon — `m3-dock` (the fight/map dock fix)

## VERDICT

The spitter standoff is a UI defect, not a rules defect: the battle view
replaces the map, a spitter holds reach from three tiles without ever
walking adjacent, and in the battle view every door back to the map is
closed — so a melee hero is trapped on screen with a card that does
nothing. The fix is the dock ruling (D91): the map never leaves the
screen; the battle pieces dock over it. App-only; no core or content
changes are expected and all five band lines must hold.

## State verified before measuring

`main` = `fda107f` (PRs #1–#15 merged), clean tree, no worktree, no
open unit. Measured 2026-09-02 by the architect session, immediately
after the user's first post-battle playtest (D90 verdicts).

## The measurement — the root-cause chain, verified in code

1. **The swap.** `game_screen.dart:51-68`: one `Expanded` slot renders
   `state.isBattleOpen ? BattleView(state: state) : GlyphGrid(...)`.
   While the fight holds, the map is not on screen at all.
2. **The trigger has no hysteresis and includes ranged reach.**
   `game_bloc.dart:315-318`: `isBattleOpen => monstersHoldingReach
   .isNotEmpty`; the mirror of engine `_holdsReach` (`step.dart:747-751`)
   — orthogonally adjacent OR within the monster's reach along the
   HERO's line of sight. A spitter standing at Chebyshev distance 3 in
   LOS therefore holds the battle view open indefinitely.
3. **The spitter never closes.** `step.dart:660-679` (`_monsterPhase`):
   adjacent → swing; holding reach → stand and shoot (the code comment
   says exactly that); otherwise → flow-field step TOWARD the hero.
   There is no retreat/kite branch anywhere — and also no branch that
   walks it adjacent while it can shoot from where it stands. With speed
   5 and reach 3 it is a passive turret: it never becomes adjacent on
   its own.
4. **The battle view offers no movement.** `battle_view.dart:27-56`:
   stage cards + turn strip + (for casters) the skill bar. The ONLY
   tappable surface is a stage card.
5. **And that card tap is worse than silent — it lies.** CORRECTED by
   the worker's measurement (D92), superseding this document's original
   claim of a silent no-op: `FloorMap.isWalkable` (`floor_map.dart:
   71-72`) is terrain-only, so the tap reaches the `enemiesInSight > 0`
   branch (`game_bloc.dart`) and emits the watched-refusal "Something
   is watching. You stay put." — forever, nameless, advising the
   player to stand still while the correct move is to walk in. The
   silent no-op premise was inherited from the recon agent without
   re-checking `isWalkable` at source; the worker's measurement stands.

The rules layer is sound: the hero walks two tiles to adjacency (eating
2–3 damage per owed spitter turn) and one swing kills at hp 4 — this is
the D78/D79 glass-cannon as ruled. The UI removed every door. The user
could not walk (no map), could not approach (no verb), could not cast
(no book — a fresh melee hero has zero ranged options; Firebolt exists
only via a Book of Firebolt, `armory.dart:147-151`).

## Is each inherited gate real?

- **"Walk away and the crawl view returns" (unit B's claim)** — TRUE in
  the rules, unreachable in the UI: the only movement input during the
  battle view is stage-card taps. The widget suite tested the swap
  (`battle_view_test.dart:127-163`) but never the view whose only
  reach-holder stands beyond one step. That exact surface is what the
  spec must pin.
- **App-only fix** — confirmed: `isBattleOpen, the derived reach list,
  and the swap are all app-side. Nothing in core needs to move.
- **Bands untouched** — the change renders state; it moves no rule, no
  table. All five band lines are controls.

## Findings that change the spec

- The swap test at `battle_view_test.dart:127-163` pins the OLD swap
  behaviour by name. The dock change must rewrite those two tests, not
  preserve them — the spec says so explicitly.
- The silent no-op card tap was half the trap. With the map visible it
  is less lethal, but a tap that does nothing and says nothing is still
  a defect-shaped surface; the spec gives it a refusal sentence.
- Auto-path while watched is refused (`_onTileTapped, the
  `enemiesInSight > 0` branch) — so closing on a spitter means
  tile-by-tile taps while it shoots. That is the existing crawl rule
  (deliberate, D6-era chase teeth) and stays. It also means the dock
  makes the ambush FEEL the way the rules already were.

## Proposed shape of the work

One small app-side unit. `game_screen.dart` always renders `GlyphGrid`
in the map slot; the battle pieces become docked rows — stage cards +
turn strip above the map slot, skill bar below it — present exactly
while `isBattleOpen`. `battle_view.dart` becomes the dock (or is
absorbed; worker's call, pre-declare). A guidance refusal lands in the
log when a stage card is tapped beyond one step. Greyscale doctrine and
the phone-sized surface carry over unchanged. AVD pass mandatory.

## Hazards to carry into the spec

- The swap test rewrite (above) is a characterization flip, not an
  addition — run it against unmodified code first.
- Widget traps verbatim: `find.textContaining` is case-sensitive;
  `scrollUntilVisible` is one-way; size at least one test like a phone
  (`_onAPhone, 1080×2424 @ 2.625).
- The dock shrinks the map's vertical space on a phone — the AVD pass
  must check the crawl view still fits and the dock doesn't overflow
  (the 8th device catch was a glyph-width column; the 10th was this
  trap; neither class of catch is visible to the widget suite).
- Greyscale: the dock panels keep the D89 grammar (shape/marking/word);
  fresh greyscale shots are a deliverable for the author's eye.

## What this recon did NOT check

- No AVD run happened (architect recon is headless) — the dock's
  on-device fit, scroll of the log, and tap targets on a phone are the
  build session's AVD pass.
- No re-run of the full suites this session; the 1894 figure is the
  D89 close-out number carried, and the build prompt requires the
  worker to measure the baseline fresh in the worktree.
- The physical-phone read (follow-up 30's standing note) remains
  open for whenever the user next plays on theirs.