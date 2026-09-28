# 08 — Target card over the map; reach wording; enemy sheet removed

Governing: `../CONTRACT.md` settled decision 9, scope §5 (target card),
acceptance 9; `../PLAN.md` §2 G6, G10 (target card, placement); §7 Q6. Work
from `packages/app`.

## Starting repository state

Task 07 committed. `lib/game/map_callout.dart::MapCallout` shows
`state.inspectedActor` beside its cell (right, flipped left at the edge,
above, flipped below), leader line, `GestureDetector(opaque)`, name + `HP a/b`
+ `targetFactLines`, height formula from `crawl_style.dart` callout
constants; it is a sibling of `MapOverlays` in the map slot Stack.
`target_facts.dart` words reach as `Reach r` / `Adjacent`.
`BattleDock.onActorSelected` in `game_screen.dart` dispatches
`TimelineActorSelected` and opens `showEnemyInfo` (battle_view.dart sheet).
`MapOverlays` positions the place pop-up and recenter using
`map_overlay_layout.dart`.

## Owned files

`git mv lib/game/map_callout.dart lib/game/target_card.dart` (rewritten),
`lib/game/target_facts.dart`, `lib/game/map_overlays.dart`,
`lib/game/battle_view.dart` (delete `showEnemyInfo`, `_EnemyInfoLine`),
`lib/game/game_screen.dart` (timeline callback, remove `MapCallout`),
`lib/game/crawl_style.dart`; `git mv test/widget/map_callout_test.dart test/widget/target_card_test.dart`
(rewritten); migrate `battle_view_test`, `map_touch_wiring_test`,
`crawl_layout_test`, `crawl_surfaces_test` where they reference the callout
key, `Adjacent`, `Reach 3`, `strikes adjacent` or the sheet.

Non-goals: the strip (Task 09), selection/camera semantics, bloc.

## Locked decisions

1. `TargetCard` (key `targetCardKey`, replacing `mapCalloutKey`) exactly per
   PLAN G10: actor rule, visibility rule, content (name `displayName` role,
   `CrawlMeter('HP', …, barHeight: 5, fill: crawlEnemy)`, fact lines),
   width 172, height formula (`crawlCalloutBarRow = 12` covers the 3 + 5 + 4
   between HP text and facts, or equivalent constants), four preferred
   positions, avoid list (target cell, place pop-up rect when shown,
   recenter rect when shown; the strip rect joins in Task 09), leader line
   and dot from the cell corner facing the card to the card's nearest
   corner, taps absorbed inside the card.
2. The card is built and positioned inside `MapOverlays`, after the place
   pop-up so it can avoid it; `GameScreen` no longer mounts `MapCallout`.
3. `targetFactLines`: reach line `target.reach > 1 ? 'Ranged, reach ${target.reach}' : 'Melee only'`;
   all other lines unchanged.
4. Timeline token tap dispatches `TimelineActorSelected(actor.id)` only; the
   card then shows the selected actor (via `targetActor`). `showEnemyInfo`
   and `_EnemyInfoLine` are deleted. Camera focus on selection is
   unchanged (Q6 default).

## Proof (Red first)

`target_card_test.dart` at `onTheTargetPhone` (rewrite; delete tests that
pin the old right/left/above/below flip literals):
- exploration: a tap on a distant known monster shows the card; a step or
  pan or tap-to-nothing removes it (existing dismissal rules);
- battle: with no inspect/selection, the card names the nearest known
  visible monster (`targetActor`); after a timeline token tap it names that
  monster; no sheet opens;
- the card shows name, `HP a/b` with a bar, `ATK a–b  SPD s`, `Melee only`
  for reach 1, `Ranged, reach 3` for reach 3, resist/burn lines; the word
  `Adjacent` appears nowhere;
- hero avoidance: target adjacent north, east, south, west and diagonal of
  a centred hero, and at the map edges — the card rect never overlaps the
  hero block, never overlaps the target cell, and never overlaps the place
  pop-up when both show (hero standing on an item while engaged);
- the map rect is identical with and without the card;
- hidden monsters: no card for a monster outside sight (secrecy).
Expected Red: no card in battle without an inspect; `Adjacent` found; the
card overlaps the hero when the target is adjacent west of the hero.
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Leader-painter reuse vs rewrite; constant naming for the new height rows;
fixture staging.

## Escalate when

A secrecy test fails; the card cannot avoid both the hero block and the
pop-up at the target size (report the rects); a test depends on the enemy
sheet for information the card does not show.

## Completion receipt

Red output, Green command/exit, format/analyze exits, avoidance sweep
result, migrated/deleted tests. Commit:
`feat(app): float the target card beside the target on the map`.
