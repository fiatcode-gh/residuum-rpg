import 'package:flutter/material.dart';

import '../style/tokens.dart';

const double crawlPanelPadding = 8;

const double crawlGestureClear = 18;

/// The recenter pill's own square: bigger than [tapTarget] because it
/// floats over the map rather than sitting in a framed row (PLAN.md G3).
const double crawlTouchTarget = 48;

const double crawlStripHeight = 48;
const double crawlStripPadding = 8;
const double crawlTokenHeight = 24;
const double crawlLogLine = 15;

/// PLAN.md G8: the log row's own fixed height, and the side controls beside
/// the log peek — [crawlSideControlWidth] wide, separated from the peek by
/// [crawlSideControlGap].
const double crawlLogRowHeight = 104;
const double crawlSideControlWidth = 64;
const double crawlSideControlGap = 6;
const double crawlLogSheetHeight = 345;
const double crawlLogSheetHeader = 40;
const double crawlLogRowPadding = 1.5;
const double crawlLogPictogram = 15;

const double crawlHudHeight = 80;

/// The opacity a disabled slot's mark renders at (PLAN.md G8).
const double crawlDisabledIconOpacity = 0.45;

/// PLAN.md G8: the crawl's fixed-chrome rhythm — the gutter around every
/// fixed region, the gaps between them, and the bottom menu's own geometry
/// (PLAN.md G9).
const double crawlGutter = 8;
const double crawlGap = 7;
const double crawlBottomGap = 6;
const double crawlMenuHeight = 56;
const double crawlSlotGap = 7;
const double crawlSlotMark = 20;

/// PLAN.md G9: `showCrawlPopup`'s own fixed geometry — the anchored width,
/// the gap kept between the popup and its anchor, the margin its edges
/// (and the maximum-height reserve above it) stay clear of the screen's
/// own edges, its internal padding, and the minimum height every row
/// inside it keeps, in the same visual family as the place pop-up.
const double crawlPopupWidth = 280;
const double crawlPopupGap = 6;
const double crawlPopupEdgeMargin = 8;
const double crawlPopupPadding = 10;
const double crawlPopupRowMinHeight = 48;

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

const double crawlCalloutWidth = 172;
const double crawlCalloutPadding = 10;
const double crawlCalloutNameRow = 17;
const double crawlCalloutGap = 4;
const double crawlCalloutHpRow = 13;
const double crawlCalloutLineHeight = 14;
const double crawlCalloutBarRow = 13;

/// The gap between a cell's edge and the card placed beside it, and the
/// margin every card edge stays clear of the map slot's own edges.
const double crawlCalloutMargin = 14;
const double crawlCalloutLeaderGap = 6;
const double crawlCalloutEdgeClamp = 8;

/// The leader line's stroke width and its dot's radius at the cell end.
const double crawlCalloutLeaderWidth = 1;
const double crawlCalloutDotRadius = 2.5;

/// PLAN.md G10: the place pop-up's own fixed geometry, in the same visual
/// family as the callout ([crawlCalloutFill], [crawlFrame], [crawlCalloutPadding]
/// and [crawlCalloutLineHeight] are shared rather than duplicated).
const double crawlPlacePopupWidth = 300;
const double crawlPlaceButtonHeight = 48;
const double crawlPlaceButtonGap = 6;

/// The margin every map overlay's edge stays clear of the map slot's own
/// edges, and the gap `placeMapOverlay`'s corner candidates sit at.
const double crawlOverlayMargin = 8;
