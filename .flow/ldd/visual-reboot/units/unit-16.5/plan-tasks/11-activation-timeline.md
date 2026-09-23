# 11 — Activation timeline pills and the final fixed-layout proof

Governing: `../CONTRACT.md` scope item 4 (Battle: timeline), settled
decision 3, acceptance 5–6; `../PLAN.md` §2 G8 (timeline internals, region
tables). Work from `packages/app`.

## Starting repository state

Task 10 committed: `CrawlHeader` (88), map, panel, peek (96), action bar
(60) are final. `battle_view.dart::BattleDock` (keyed `dock-backing`) still
renders the U16 36 dp circle tokens with NOW/NEXT labels, a `›` separator
and a horizontal scroll; tokens keyed `timeline-current-hero`,
`timeline-next-hero`, `timeline-actor-<id>-<index>`; tapping an actor token
calls `onActorSelected` (→ `TimelineActorSelected` + `showEnemyInfo`).

## Owned files

`lib/game/battle_view.dart` (dock/timeline widgets only; `showEnemyInfo`
untouched), `lib/game/crawl_style.dart` (`crawlTimelineHeight = 58`,
`crawlTokenHeight = 24`, remove `crawlTokenCell`/`crawlTokenWidth` if
unused), `lib/game/game_screen.dart` (no change expected beyond the dock
slot), tests `test/battle_view_test.dart`,
`test/game/activation_timeline_test.dart` (only if presentation-coupled),
`test/widget/crawl_layout_test.dart` (rewritten as the final layout proof).

Non-goals: `projectActivationQueue`, `GameViewState.activationQueue`,
selection semantics, secrecy — unchanged.

## Locked decisions

1. `BattleDock` keeps its name, key `dock-backing`, inputs and
   `onActorSelected`; renders PLAN G8 "Timeline internals": height
   `58 × crawlScale`, margin h `crawlGutter`, no frame. NOW column: label
   `NOW` `displayLabel`, then `queue[0]` pill. Divider (only when
   `queue.length > 1`). NEXT column (only when `queue.length > 1`): label
   `NEXT`, then pills for `queue[1..]` in a horizontal
   `SingleChildScrollView`, spacing 8. Each pill: 24 dp high at the top of a
   44 dp hit row; glyph (`@` or `presentation.glyphLabel`) + 5 + word
   (`You` or `presentation.displayName`) in `monoToken` (hero) /
   `monoTokenHostile` (monsters); current pill border 1.5 `crawlGold` and
   fill `crawlGold` α 0.08; others border 1 `crawlChipBorder`. Keys,
   semantics labels (`You, current activation`, `You, next activation`,
   actor display names as buttons) and `InkWell` tap targets (full 44 dp
   row height × pill width) unchanged. No numbers.
2. `crawl_layout_test.dart` becomes the unit's fixed-chrome proof (below);
   delete its U16 pins (49 dp status, 758.4 bottom, frame predicates,
   map-border test).

## Proof (Red first)

`test/battle_view_test.dart`: pill heights 24, hit rows 44; current pill
has the gold border, the next pills do not; repeated ordinal tokens keep
their keys; a hidden actor stops the queue as before; tapping an actor pill
dispatches `TimelineActorSelected`; no digit characters in the dock.
`crawl_layout_test.dart` on `onTheTargetPhone` (scale 1.0):
- exploration order and heights: header 88 → map → hero panel 102 →
  peek 96 → bar 60, gaps 6/7/7/6; map height ≥ 0.45 × 875.6 (=394.0);
- battle: header 88 → timeline 58 → map → combat 124 → peek 96 → bar 60;
  map height ≥ 0.35 × 875.6 (=306.5);
- map rect identical: unarmed vs armed; 1 legal action vs 12; log peek vs
  half vs full; with vs without a note; with vs without a callout-worthy
  inspect (tap a far monster; sheet or callout present);
- every region spans `crawlGutter`…`width − crawlGutter` (map spans full
  width).
Record the measured rects in the receipt (Main compares with PLAN G8).
Expected Red: dock tokens are 36 dp circles; U16 pins fail against the new
chrome.
Green: `flutter test test/battle_view_test.dart test/widget/crawl_layout_test.dart test/game test/widget`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Column/pill widget split; how the divider aligns to the pill row.

## Escalate when

Any measured region differs from PLAN G8 by more than 1 dp at scale 1.0;
either floor fails; the map rect changes with actions/arming/log/notes; a
timeline key or semantics label must change.

## Completion receipt

Red output, Green command/exit, analyzer/format exits, measured rects for
exploration and battle. Commit:
`feat(app): restyle the activation timeline and prove fixed crawl chrome`.
