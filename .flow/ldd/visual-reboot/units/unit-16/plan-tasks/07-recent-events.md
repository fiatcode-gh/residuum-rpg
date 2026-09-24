# 07 — Recent events and expanded log composition

Start: Task 06's tested timeline handoff plus Tasks 01–05 in same suitable feature checkout; approved `../CONTRACT.md`, `../PLAN.md`, four named references. Own `packages/app/lib/game/log_drawer.dart`, `packages/app/test/widget/{log_drawer_test.dart,crawl_layout_test.dart}`; if truly needed, only log constants in `lib/game/crawl_style.dart`. Do not alter `log_line.dart` enum/category marks, `game_bloc.dart` event/reducer, `GameScreen` overlay placement, action row, save or map. This is the final implementation capsule before Main's integrated gates.

## Locked decisions

- `LogPeek` stays exactly `crawlLogPeekHeight == 104` dp above the existing one action shelf. Inside its existing `CrawlPanel`, arrange a `Column` with compact `RECENT EVENTS` heading, hairline rule and `Expanded` reverse `ListView.builder` of **real** recent sentences; keep the trailing expand chevron in the surrounding `Row`. Newest remains the bottom visible line at scroll offset zero. Preserve `logPeekKey`, `Open the message log` semantics, single tap `LogDrawerHandlePulled`, disabled-on-death behavior and trailing expand affordance. Empty log shows heading with no invented sentence/count. At 411.4dp phone width, at least the latest one nonempty sentence remains legible without growing the envelope; use less interior padding if necessary. No fabricated timestamps or new line ordering.
- In `LogDrawer`, keep half height fraction 0.45/full 1.0, handle/close and scroll controller/follow/unread mechanics. Header becomes `RECENT EVENTS` plus accurate `${state.log.length} entries` (including `0 entries`), fit at phone width with the existing close control. `_LogRow` stays `LogCategory.mark` in its 24dp column/20×20dp well and accessible `${category.word}. ${sentence}`, newest-vs-older value distinction; preserve chronological list order and causal text. No event icons or placeholder slots.
- Drawer stays an overlay above the underlying column; opening/half/full/closing never reflows `dungeonSceneSlotKey`, `logPeekKey`, status or action row. No additional scroll target over the map and no double action row. `LogCategory` semantics must not depend on colour.

## Red → Green and proof

1. First add phone-sized widget proof in `log_drawer_test.dart`: peek presents a factual `RECENT EVENTS` heading and latest nonempty sentence within the fixed 104dp rect; full drawer presents exact live total, all category word+glyph pairs and chronological entries. **Red** is missing header/count now. Use a multi-line/wide sentence to make clipped content detectable; do not pin cosmetic text in isolation or fabricate a timestamp fixture. Keep existing empty/one-line and newest value tests.
2. Implement heading/rule/count within current geometry. Exercise peek → half → full → close and follow-breaking/unread/resume after a new event while scrolled away. At every extent compare `dungeonSceneSlotKey` and `logPeekKey` rectangles from before opening; keep their equality. Preserve log failure/death behaviour and `GameBloc` transitions as observed.
3. From `packages/app`: `flutter test test/widget/log_drawer_test.dart test/widget/crawl_layout_test.dart test/widget/crawl_action_row_test.dart test/battle_view_test.dart`; `dart format <touched Dart paths>`; `flutter analyze`. Record Red/Green outputs/exits. Main performs final full app gates, acceptance review and device comparison, not this executor.

## Executor discretion

Existing text-role choice for the small title, border colour and spacing **inside** the fixed peek/drawer header. Do not add synthetic category pictures, seconds/timestamps, truncated causal text or a new overlay state.

## Escalate when

The heading prevents one real recent line at phone width or forces peek above 104dp; count cannot fit with the close affordance under normal text scaling; chronology/follow needs a reducer change; overlay steals gestures or moves map/action geometry; reference likeness would require mock-only prose.

## Handoff receipt

Red assertion and exit, focused Green/formatter/analyzer exits, measured fixed peek/map rectangles through all extents, newest/follow/unread/category evidence and changed-file list. Integrated code handoff is ready for Main review, broad gates and target-device evidence; no production code changes after acceptance without reopening scoped closure.
