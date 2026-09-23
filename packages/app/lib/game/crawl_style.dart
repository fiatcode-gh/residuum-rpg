import 'package:flutter/material.dart';

import '../style/tokens.dart';

const double crawlPanelPadding = 8;
const double crawlTokenCell = 36;
const double crawlTokenWidth = 76;
const double crawlEventsHeight = 96;
const double crawlLogLine = 15;
const double crawlLogSheetHeight = 345;
const double crawlLogSheetHeader = 40;
const double crawlLogRowPadding = 1.5;
const double crawlLogPictogram = 15;

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
  borderRadius: BorderRadius.all(Radius.circular(6)),
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
