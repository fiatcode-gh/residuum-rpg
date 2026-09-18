import 'package:flutter/material.dart';

const Color crawlInk = Color(0xFFE6EAF0);
const Color crawlDim = Color(0xFF8A919E);
const Color crawlPanel = Color(0xFF15181F);
const Color crawlRule = Color(0xFF2A2E38);
const Color crawlVoid = Color(0xFF0E1014);
const Color crawlRaised = Color(0xFF1B1F27);
const Color crawlRecessed = Color(0xFF11141A);
const Color crawlArmedFill = Color(0xFF262B35);
const Color crawlDisabledRule = Color(0xFF1E222A);
const Color crawlScrim = Color(0xCC0E1014);

const double crawlGutter = 12;
const double crawlRhythm = 4;
const double crawlRadius = 6;
const double crawlHairline = 1;
const double crawlTapTarget = 44;
const double crawlPanelPadding = 8;
const double crawlTokenCell = 44;
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

const TextStyle crawlPlace = TextStyle(
  fontFamily: 'monospace',
  fontSize: 15,
  letterSpacing: 3,
  fontWeight: FontWeight.w500,
  color: crawlInk,
);
const TextStyle crawlBody = TextStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  color: crawlInk,
);
const TextStyle crawlBodyDim = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  color: crawlDim,
);
const TextStyle crawlRegionLabel = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  letterSpacing: 2,
  fontWeight: FontWeight.w600,
  color: crawlDim,
);
const TextStyle crawlPanelTitle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  letterSpacing: 2,
  fontWeight: FontWeight.w600,
  color: crawlInk,
);
const TextStyle crawlLine = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  color: crawlInk,
);
const TextStyle crawlLineOlder = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  color: crawlDim,
);
const TextStyle crawlGlyph = TextStyle(
  fontFamily: 'monospace',
  fontSize: 18,
  color: crawlInk,
);
const TextStyle crawlTokenWord = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  color: crawlDim,
);
const TextStyle crawlChevron = TextStyle(
  fontFamily: 'monospace',
  fontSize: 18,
  color: crawlDim,
);

/// `inherit: false` on every chip and caption style below: `_ActionChip`
/// renders these consts directly rather than through a `copyWith`, so the
/// object `_fitFor` measures and the object `Text` paints are identical —
/// measurement and render can never drift onto two different `TextStyle`
/// instances of the same nominal values.
const TextStyle crawlChipLabel = TextStyle(
  inherit: false,
  fontFamily: 'monospace',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: crawlInk,
);
const TextStyle crawlChipLabelDisabled = TextStyle(
  inherit: false,
  fontFamily: 'monospace',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: crawlDim,
);
const TextStyle crawlChipLabelArmed = TextStyle(
  inherit: false,
  fontFamily: 'monospace',
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: crawlInk,
);
const TextStyle crawlCaption = TextStyle(
  inherit: false,
  fontFamily: 'monospace',
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: crawlInk,
);
const TextStyle crawlDetail = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  color: crawlDim,
);
const TextStyle crawlHeadline = TextStyle(
  fontFamily: 'monospace',
  fontSize: 28,
  color: crawlInk,
);

/// The crawl's Material defaults, built from scratch rather than
/// `Theme.of(context).copyWith(…)` so it can never inherit a future global
/// change. A top-level `final`, so Dart initialises it once on first access
/// and no `build` allocates a [ThemeData].
/// Task 03's chip and overlay colours complete every field this theme
/// needs; nothing here still waits on a later unit.
final ThemeData crawlTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: crawlVoid,
  iconTheme: const IconThemeData(color: crawlInk, size: 18),
  splashColor: crawlRaised.withValues(alpha: 0.24),
  highlightColor: crawlRaised.withValues(alpha: 0.12),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: crawlInk,
    linearTrackColor: crawlRule,
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: crawlInk,
      overlayColor: crawlRaised,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: crawlPanel,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    showDragHandle: false,
    modalBarrierColor: crawlScrim,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(crawlRadius)),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: crawlPanel,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: crawlPanelTitle,
    contentTextStyle: crawlLine,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(crawlRadius)),
      side: BorderSide(color: crawlRule, width: crawlHairline),
    ),
  ),
);

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
    fill: crawlRaised,
    border: crawlRule,
    borderWidth: crawlHairline,
    label: crawlChipLabel,
    iconOpacity: 1,
  ),
  CrawlChipState.disabled => const CrawlChipSkin(
    fill: crawlRecessed,
    border: crawlDisabledRule,
    borderWidth: crawlHairline,
    label: crawlChipLabelDisabled,
    iconOpacity: crawlDisabledIconOpacity,
  ),
  CrawlChipState.armed => const CrawlChipSkin(
    fill: crawlArmedFill,
    border: crawlInk,
    borderWidth: crawlHairline * 2,
    label: crawlChipLabelArmed,
    iconOpacity: 1,
  ),
};
