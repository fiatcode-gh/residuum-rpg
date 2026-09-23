import 'package:flutter/material.dart';

import '../style/tokens.dart';

const double crawlPanelPadding = 8;
const double crawlTokenCell = 36;
const double crawlTokenWidth = 76;
const double crawlLogPeekHeight = 104;
const double crawlMarkColumn = 24;
const double crawlMarkWell = 20;
const double crawlLogRowRhythm = 3;
const double crawlChipSpacing = 6;
const double crawlChipRunSpacing = 4;
const double crawlChipPadding = 8;
const double crawlChipVerticalPadding = 6;
const int crawlChipMaxColumns = 5;

/// The clipping ceiling `CrawlActionRow`'s fit search must respect: the most
/// lines a label may ever occupy before a candidate column count is
/// rejected. Not a design preference — raising it is what lets the row
/// degrade by one label line instead of collapsing into extra chip runs.
const int crawlChipMaxLabelLines = 3;
const double crawlDisabledIconOpacity = 0.45;

/// `inherit: false` on every chip and caption style below: the invariant
/// now lives in `tokens.dart` and applies to every role, so `_ActionChip`
/// renders these consts directly rather than through a `copyWith`, and the
/// object `_fitFor` measures is still the object `Text` paints —
/// measurement and render can never drift onto two different `TextStyle`
/// instances of the same nominal values.
/// `_fitFor` measures these exact objects and names the heaviest explicitly
/// (`crawl_action_row.dart:154-163`); the seam owning the names is what lets
/// U15 retune the ladder without touching a shared role.
const TextStyle crawlChipLabel = textLabel;
const TextStyle crawlChipLabelDisabled = textLabelDim;
const TextStyle crawlChipLabelArmed = textLabelStrong;
const TextStyle crawlCaption = textCaption;

/// available, disabled and armed: the crawl's whole chip-state vocabulary.
enum CrawlChipState { available, disabled, armed }

/// One chip's rendered skin: what four non-hue cues — fill, border weight,
/// border colour and label weight — separate available from disabled from
/// armed for a reader who cannot use hue.
class CrawlChipSkin {
  const CrawlChipSkin({
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.label,
    required this.iconOpacity,
  });

  final Color fill;
  final Color border;
  final double borderWidth;
  final TextStyle label;
  final double iconOpacity;
}

/// The chip-state table: binding, not a default anyone should retune without
/// re-checking the greyscale reading it protects.
CrawlChipSkin crawlChipSkin(CrawlChipState state) => switch (state) {
  CrawlChipState.available => const CrawlChipSkin(
    fill: raised,
    border: rule,
    borderWidth: hairline,
    label: crawlChipLabel,
    iconOpacity: 1,
  ),
  CrawlChipState.disabled => const CrawlChipSkin(
    fill: recessed,
    border: disabledRule,
    borderWidth: hairline,
    label: crawlChipLabelDisabled,
    iconOpacity: crawlDisabledIconOpacity,
  ),
  CrawlChipState.armed => const CrawlChipSkin(
    fill: armedFill,
    border: ink,
    borderWidth: hairline * 2,
    label: crawlChipLabelArmed,
    iconOpacity: 1,
  ),
};
