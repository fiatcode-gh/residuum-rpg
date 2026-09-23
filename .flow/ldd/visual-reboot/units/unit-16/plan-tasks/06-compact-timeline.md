# 06 — Compact honest combat timeline

Start: Task 05's focused Green factual-status handoff, all earlier U16 work in one suitable feature checkout; approved `../CONTRACT.md`, `../PLAN.md`, four named references. Own `packages/app/lib/game/{battle_view.dart,crawl_style.dart}` and `packages/app/test/{battle_view_test.dart,game/activation_timeline_test.dart,widget/crawl_layout_test.dart}`. No changes to `activation_timeline.dart`, `GameViewState.activationQueue`, `GameScreen` condition, combat rules, target dispatch or action shelf. Task 07 follows.

## Locked decisions

- Retain `BattleDock`'s one `NOW`/`NEXT` caption row and scrollable activation-token row. Keep `_TimelineCell` glyph and full actor word, `crawlTokenWidth == 76`, token keys `timeline-current-hero`, `timeline-next-hero`, `timeline-actor-<id>-<queueIndex>`, and the order/repetition projected by `projectActivationQueue` (which stops at the first hidden/unknown actor). Reduce only `crawlTokenCell` from 44 to 36dp and, if necessary, surrounding internal vertical gap so dock height does not grow; interactive actor token remains at least 44dp high. Current hero ring gets a visibly heavier border/raised value versus later tokens, and NOW/NEXT + glyph/name remain redundant non-hue cues. Do not replace next hero or repeated actors with summaries/countdowns.
- `onActorSelected` still opens the same info sheet at zero turn cost and selects the exact keyed actor occurrence's `actor`; no other tap target or fake menu. Hidden actor after a visible prefix hides subsequent tokens, even if the next token is known; queue[0] always current hero. Road fight timeline uses the same contract. Full names must remain accessible even if they are fitted down for limited 76dp token width; at 2x text scale use horizontal scrolling and no clipped token text.
- Token circles are **not** future-art slots. No new placeholder or supplied icon. No new battle-specific row below map; map remains `Expanded`, action shelf remains the single existing row.

## Red → Green and proof

1. First add a widget proof in `battle_view_test.dart`: current token ring differs by value/weight from next token on a real battle, its 36dp glyph cell plus >=44dp actor press surface sits above the map without increasing dock height; **Red** against current 44dp equal-weight rings. Retain `activation_timeline_test.dart` repeated/hidden/empty schedule cases and `battle_view_test.dart` token keys, NOW/NEXT alignment, sheet action, scroll overflow and 2x scale; add an explicit hidden-middle actor negative check if absent rather than exposing it for visual symmetry.
2. Implement only those geometry/value changes. `crawl_layout_test.dart` continues to prove status → dock → full-width map; compare map rect before/after a visible repeated-actor queue without adding a row. Do not force all actors into phone width; preserve horizontal scrolling.
3. From `packages/app`: `flutter test test/game/activation_timeline_test.dart test/battle_view_test.dart test/widget/crawl_layout_test.dart test/widget/crawl_action_row_test.dart`; `dart format <touched Dart paths>`; `flutter analyze`. Record Red/Green exits and dock/map height in test host; Main owns target-device density.

## Executor discretion

Within the existing `CrawlPanel` token body, precise neutral border/fill tokens and minimal gap adjustment consistent with non-hue distinction; no invented activation metadata, new model/type or bitmap art.

## Escalate when

Reducing 44 to 36 causes glyph/name clipping or tap size below 44dp; distinct NOW treatment requires hiding an actor or changing projection; a hidden queue leaks downstream names; any proposed fix grows real worst-case chrome or changes inspection semantics.

## Handoff receipt

Red failing assertion, focused Green/formatter/analyzer exits, repeated/hidden schedule and actor inspection findings, dock/map test-host heights and any hardware risk. Handoff retains one compact timeline with no altered action or projection semantics.
