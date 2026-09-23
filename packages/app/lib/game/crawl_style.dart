import 'package:flutter/material.dart';

const double crawlPanelPadding = 8;
const double crawlTokenCell = 36;
const double crawlTokenWidth = 76;
const double crawlLogPeekHeight = 104;
const double crawlMarkColumn = 24;
const double crawlMarkWell = 20;
const double crawlLogRowRhythm = 3;

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
