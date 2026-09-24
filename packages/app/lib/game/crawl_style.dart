import 'package:flutter/material.dart';

import '../style/tokens.dart';

const double crawlPanelPadding = 8;

/// PLAN.md G8 timeline internals (Task 11): the battle dock's own fixed
/// height, and the fixed height of every pill it draws — NOW's, and each of
/// NEXT's.
const double crawlTimelineHeight = 58;
const double crawlTokenHeight = 24;
const double crawlEventsHeight = 96;
const double crawlLogLine = 15;
const double crawlLogSheetHeight = 345;
const double crawlLogSheetHeader = 40;
const double crawlLogRowPadding = 1.5;
const double crawlLogPictogram = 15;

/// PLAN.md G8 header internals (Task 10): the crawl header's own fixed
/// height, top of the fixed-chrome column.
const double crawlHeaderHeight = 88;

/// The opacity a disabled slot's mark renders at (PLAN.md G8).
const double crawlDisabledIconOpacity = 0.45;

/// PLAN.md G8: the crawl's fixed-chrome rhythm — the gutter around every
/// fixed region, the gaps between them, and the action bar's own geometry.
/// Amendment A1 does not touch G8.
const double crawlGutter = 8;
const double crawlGap = 7;
const double crawlBottomGap = 6;
const double crawlActionBarHeight = 60;
const double crawlSlotGap = 7;
const double crawlSlotPeek = 18;
const double crawlSlotMark = 22;

/// PLAN.md G8 hero panel internals (Task 08): the panel's own fixed height,
/// the gap it sits in between the map and the log peek, its corner radius,
/// and the frame every fixed-chrome panel this unit draws shares.
const double crawlHeroPanelHeight = 102;

/// PLAN.md G8 combat panel internals (Task 09): the panel's own fixed
/// height, replacing [crawlHeroPanelHeight] for exactly as long as
/// `GameViewState.isBattleOpen` holds.
const double crawlCombatPanelHeight = 124;
const double crawlPanelGap = 6;
const double crawlPanelRadius = 6;
const BoxDecoration crawlFrameDecoration = BoxDecoration(
  color: crawlPanelFill,
  border: Border.fromBorderSide(BorderSide(color: crawlFrame)),
  borderRadius: BorderRadius.all(Radius.circular(crawlPanelRadius)),
);

/// The clamp that keeps every fixed chrome region within its PLAN.md G8
/// floor even as the ambient text scale grows, matching
/// `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`: `12 sp` is the
/// smallest role any fixed region measures against, so scaling relative to
/// it and clamping at 1.3 grows a region by exactly as much as the clamp
/// already lets body text grow, never more.
double crawlScale(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 1.3);

/// available, disabled and armed: the action bar's whole slot-state
/// vocabulary (PLAN.md G8).
enum CrawlSlotState { available, disabled, armed }

/// PLAN.md Task 12 map callout internals (decision 3): the card's fixed
/// geometry in dp. [crawlCalloutWidth] stays independent of `crawlScale` —
/// the callout sits over the dense map rather than the fixed chrome
/// column, so text scale never grows the card's width. Its text-row
/// heights do scale (Unit 16.5 acceptance I3): a fixed height for a single
/// line of text clips at a larger system text size, so `crawlCalloutNameRow`,
/// `crawlCalloutHpRow` and `crawlCalloutLineHeight` each grow by
/// `crawlScale` just as the fixed-chrome regions do; the padding and gaps
/// around them do not. Height is `crawlCalloutPadding * 2 +
/// (crawlCalloutNameRow + crawlCalloutHpRow) * crawlScale(context) +
/// crawlCalloutGap * 2 + crawlCalloutLineHeight * crawlScale(context) * k`,
/// `k = 2 + resists.length + vulnerableTo.length`.
const double crawlCalloutWidth = 172;
const double crawlCalloutPadding = 10;
const double crawlCalloutNameRow = 17;
const double crawlCalloutGap = 4;
const double crawlCalloutHpRow = 13;
const double crawlCalloutLineHeight = 14;

/// The gap between a cell's edge and the card placed beside it, and the
/// margin every card edge stays clear of the map slot's own edges.
const double crawlCalloutMargin = 14;
const double crawlCalloutLeaderGap = 6;
const double crawlCalloutEdgeClamp = 8;

/// The leader line's stroke width and its dot's radius at the cell end.
const double crawlCalloutLeaderWidth = 1;
const double crawlCalloutDotRadius = 2.5;

/// The vertical rule PLAN.md G8 draws between a fixed-chrome panel's stat
/// columns — the hero panel and the combat panel both use it, sized
/// identically wherever it appears.
class ColumnDivider extends StatelessWidget {
  const ColumnDivider({super.key});

  @override
  Widget build(BuildContext context) => const VerticalDivider(
    width: 23,
    thickness: hairline,
    indent: 8,
    endIndent: 8,
    color: crawlDivider,
  );
}
