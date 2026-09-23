import 'package:flutter/material.dart';

const String textFace = 'Spectral';
const String displayFace = 'EB Garamond';
const String monoFace = 'IBM Plex Mono';

const Color ground = Color(0xFF0E1014);
const Color recessed = Color(0xFF11141A);
const Color panel = Color(0xFF15181F);
const Color raised = Color(0xFF1B1F27);
const Color disabledRule = Color(0xFF1E222A);
const Color armedFill = Color(0xFF262B35);
const Color rule = Color(0xFF2A2E38);
const Color dim = Color(0xFF8A919E);
const Color ink = Color(0xFFE6EAF0);
const Color scrim = Color(0xCC0E1014);

/// The epic's first permitted hue, reserved for the two resource fills and
/// nothing else. Warm amber for health and cold blue for mana carry no
/// meaning on their own — the label, the number, the ceiling and the fill
/// fraction each already say what the meter reads, so removing the hue
/// loses nothing. The pair is chosen so neither reads as fuller than the
/// other in a greyscale capture at equal fraction: relative luminance
/// 0.3820 and 0.3753, `|ΔL| = 0.0067` against a 0.02 ceiling, while each
/// still clears 4.5 : 1 WCAG contrast against [rule] with room to spare.
/// Red is deliberately avoided — `VISUAL-SYSTEM.md` §2 reserves hot red for
/// mortal danger and the armed target reticle, and warm amber is the
/// permitted register for light, fire and gold instead.
const Color meterHealthFill = Color(0xFFD99A3D);
const Color meterManaFill = Color(0xFF7FA8D9);

/// Unit 16.5's crawl palette (contract "In scope" item 1, PLAN.md G3): the
/// art bible's colours, bundled as tokens rather than inlined per call site.
const Color crawlTorch = Color(0xFFFFD27A);
const Color crawlHero = Color(0xFFFFF4D6);
const Color crawlEnemy = Color(0xFFFF5B5B);
const Color crawlEnemyHigh = Color(0xFFFF3B3B);
const Color crawlCold = Color(0xFF4FC3FF);
const Color crawlGold = Color(0xFFD6C280);
const Color crawlText = Color(0xFFE6E1D6);
const Color crawlTextDim = Color(0xFF9CA3AF);
const Color crawlBackground = Color(0xFF0A0F14);
const Color crawlFog = Color(0xFF1A2430);
const Color crawlPanelFill = Color(0xFF0B1215);
const Color crawlSlotFill = Color(0xFF10181B);
const Color crawlFrame = Color(0xFF2E3A3F);
const Color crawlDivider = Color(0xFF1F272C);
const Color crawlChipBorder = Color(0xFF4A5054);
const Color crawlMeterTrack = Color(0xFF131C1E);
const Color crawlGoldRule = Color(0x47D6C280);
const Color crawlCalloutFill = Color(0xF00B1215);

const double gutter = 12;
const double rhythm = 4;
const double radius = 6;
const double hairline = 1;
const double tapTarget = 44;

/// The width of the leading word cell in a [LabelledValue] row.
///
/// A fixed-width slot, not a padded string: the town's own space-padded
/// columns aligned only in a fixed-width face, and the text face is no
/// longer fixed-width. The widest label in the set is `Skills trained` at 14
/// characters; measured directly in `textLineDim` with the bundled face it
/// comes to a little over 76 dp, so 96 dp clears it with room for the gap
/// before the value cell starts.
const double labelColumn = 96;

/// Every display role requests weight 500 three ways: [FontWeight.w500] for
/// hosts that resolve weight through the family match, and
/// `fontVariations: [FontVariation('wght', 500)]` for the variable font
/// itself — EB Garamond ships only as a single variable file, so the request
/// has to land on whichever mechanism the host actually honours.
const TextStyle displayTitle = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 22,
  letterSpacing: 6,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.15,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);
const TextStyle displayPlace = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 20,
  letterSpacing: 4,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.15,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);
const TextStyle displayRoom = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 15,
  letterSpacing: 3,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.20,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);
const TextStyle displayPanel = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 13,
  letterSpacing: 2,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.20,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);
const TextStyle displayCaption = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 11,
  letterSpacing: 2,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.25,
  textBaseline: TextBaseline.alphabetic,
  color: dim,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);

/// PLAN.md G2 display roles (recent events and the expanded log, Task 07):
/// Task 01 added every G2 role with no consumer yet except the mono roles
/// (Task 06's slot labels); these are the first two G2 display roles this
/// unit actually draws.
const TextStyle displaySection = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 12.5,
  letterSpacing: 3,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.12,
  textBaseline: TextBaseline.alphabetic,
  color: crawlGold,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);
const TextStyle displaySheetTitle = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 15,
  letterSpacing: 4,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.1,
  textBaseline: TextBaseline.alphabetic,
  color: crawlGold,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);

/// PLAN.md G2 display role added on demand (Task 08): the hero panel's
/// column captions (`WEAPON`, `ARMOUR`, `QUICK`, `PACK`) are this unit's
/// first consumer.
const TextStyle displayLabel = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 9.5,
  letterSpacing: 2,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.16,
  textBaseline: TextBaseline.alphabetic,
  color: crawlTextDim,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);

/// PLAN.md G2 display role added on demand (Task 09): the combat panel's
/// target name, warm for the common case and cold for the callout Task 12
/// gives an inspected-but-not-selected actor.
const TextStyle displayName = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 15,
  letterSpacing: 0.3,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.13,
  textBaseline: TextBaseline.alphabetic,
  color: crawlEnemy,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);
const TextStyle displayNameCold = TextStyle(
  inherit: false,
  fontFamily: displayFace,
  fontSize: 15,
  letterSpacing: 0.3,
  fontWeight: FontWeight.w500,
  fontVariations: [FontVariation('wght', 500)],
  height: 1.13,
  textBaseline: TextBaseline.alphabetic,
  color: crawlCold,
  fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
);

/// Every role's `height` is explicit because Spectral's own line box is
/// 1.522 em — inherited, that is +15% on every text row in the application,
/// enough on its own to put worst-legal-combat chrome over the 600 dp
/// ceiling. Dropping a role's `height` to "simplify" it reopens that budget.
const TextStyle textHeadline = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 26,
  fontWeight: FontWeight.w400,
  height: 1.15,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textAction = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.25,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textBody = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.30,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLine = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.35,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLineDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.35,
  textBaseline: TextBaseline.alphabetic,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLabel = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.20,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLabelDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.20,
  textBaseline: TextBaseline.alphabetic,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLabelStrong = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w600,
  height: 1.20,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textCaption = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.20,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// PLAN.md G2 slot roles (action bar, Task 06): Task 01 added every G2 role
/// with no consumer yet except these three, whose only consumer is the
/// action bar's own slot label. Same invariants as every role above.
const TextStyle textSlot = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 12.5,
  fontWeight: FontWeight.w400,
  height: 1.12,
  textBaseline: TextBaseline.alphabetic,
  color: crawlText,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textSlotArmed = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  height: 1.12,
  textBaseline: TextBaseline.alphabetic,
  color: crawlText,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textSlotDisabled = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 12.5,
  fontWeight: FontWeight.w400,
  height: 1.12,
  textBaseline: TextBaseline.alphabetic,
  color: crawlTextDim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textDetail = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.30,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textDetailDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.30,
  textBaseline: TextBaseline.alphabetic,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textGlyph = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 18,
  fontWeight: FontWeight.w400,
  height: 1.00,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textGlyphDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 18,
  fontWeight: FontWeight.w400,
  height: 1.00,
  textBaseline: TextBaseline.alphabetic,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textMicro = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 9,
  fontWeight: FontWeight.w400,
  height: 1.15,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textMicroDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 9,
  fontWeight: FontWeight.w400,
  height: 1.15,
  textBaseline: TextBaseline.alphabetic,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// The mono roles (PLAN.md G2): map glyphs, log sentences, numbers and data
/// values. Unlike the display and text roles, none of these carry
/// [FontFeature.liningFigures] or `fontVariations` — IBM Plex Mono ships as
/// two static weights, matching how the text role above already handles
/// Spectral's two static weights.
const TextStyle monoMeta = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 11,
  letterSpacing: 0.3,
  fontWeight: FontWeight.w400,
  height: 1.27,
  textBaseline: TextBaseline.alphabetic,
  color: crawlTextDim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoMetaCold = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 11,
  letterSpacing: 0.3,
  fontWeight: FontWeight.w400,
  height: 1.27,
  textBaseline: TextBaseline.alphabetic,
  color: crawlCold,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoChip = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 11,
  letterSpacing: 0.2,
  fontWeight: FontWeight.w400,
  height: 1.0,
  textBaseline: TextBaseline.alphabetic,
  color: crawlText,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoData = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 11.5,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.13,
  textBaseline: TextBaseline.alphabetic,
  color: crawlText,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoDataDim = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 11.5,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.13,
  textBaseline: TextBaseline.alphabetic,
  color: crawlTextDim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoItem = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 10.5,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.24,
  textBaseline: TextBaseline.alphabetic,
  color: crawlText,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoLog = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 10.5,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.43,
  textBaseline: TextBaseline.alphabetic,
  color: crawlText,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoLogHostile = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 10.5,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.43,
  textBaseline: TextBaseline.alphabetic,
  color: crawlEnemy,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoLogCold = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 10.5,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.43,
  textBaseline: TextBaseline.alphabetic,
  color: crawlCold,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoLogTorch = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 10.5,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.43,
  textBaseline: TextBaseline.alphabetic,
  color: crawlTorch,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoFigure = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 20,
  letterSpacing: 0,
  fontWeight: FontWeight.w600,
  height: 1.1,
  textBaseline: TextBaseline.alphabetic,
  color: crawlHero,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoFigureCold = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 20,
  letterSpacing: 0,
  fontWeight: FontWeight.w600,
  height: 1.1,
  textBaseline: TextBaseline.alphabetic,
  color: crawlCold,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoToken = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 11,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.0,
  textBaseline: TextBaseline.alphabetic,
  color: crawlHero,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoTokenHostile = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 11,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.0,
  textBaseline: TextBaseline.alphabetic,
  color: crawlEnemy,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle monoSlotMeta = TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 9,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.11,
  textBaseline: TextBaseline.alphabetic,
  color: crawlTextDim,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// The only two non-`const` styles: map glyph ink is continuous (light and
/// value falloff, G4), so it cannot be a fixed token. Same invariants as
/// every role above; `color` is the caller's [ink] instead of a token.
TextStyle mapGlyphStyle(Color ink) => TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 21,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.0,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
TextStyle mapBadgeStyle(Color ink) => TextStyle(
  inherit: false,
  fontFamily: monoFace,
  fontSize: 10,
  letterSpacing: 0,
  fontWeight: FontWeight.w400,
  height: 1.0,
  textBaseline: TextBaseline.alphabetic,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// `error: ink` is deliberate: nothing in the application renders an M3
/// error surface today, and this design may not carry a state by hue alone
/// — if something ever needs to, it will carry it with a word, not with
/// `error`'s stock red.
const ColorScheme _scheme = ColorScheme(
  brightness: Brightness.dark,
  primary: ink,
  onPrimary: ground,
  secondary: ink,
  onSecondary: ground,
  error: ink,
  onError: ground,
  surface: panel,
  onSurface: ink,
);

/// The application's Material defaults, built from scratch rather than
/// `Theme.of(context).copyWith(…)` so it can never inherit a future global
/// change. A top-level `final`, so Dart initialises it once on first access
/// and no `build` allocates a [ThemeData]. Applied explicitly at each screen
/// root — never through `MaterialApp.theme`, which would restyle every stock
/// control application-wide.
final ThemeData residuumTheme = ThemeData(
  colorScheme: _scheme,
  scaffoldBackgroundColor: ground,
  canvasColor: ground,
  splashColor: raised.withValues(alpha: 0.24),
  highlightColor: raised.withValues(alpha: 0.12),
  iconTheme: const IconThemeData(color: ink, size: 18),
  dividerTheme: const DividerThemeData(color: rule, thickness: hairline),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: ink,
    linearTrackColor: rule,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: displayPanel,
    iconTheme: IconThemeData(color: ink, size: 20),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ink,
      disabledForegroundColor: dim,
      overlayColor: raised,
      textStyle: textLabel,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: raised,
      foregroundColor: ink,
      disabledBackgroundColor: recessed,
      disabledForegroundColor: dim,
      elevation: 0,
      textStyle: textAction,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: rule, width: hairline),
      ),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: raised,
    selectedColor: armedFill,
    disabledColor: recessed,
    side: const BorderSide(color: rule, width: hairline),
    labelStyle: textLabel,
    secondaryLabelStyle: textLabelStrong,
    checkmarkColor: ink,
    showCheckmark: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    pressElevation: 0,
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: panel,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    showDragHandle: false,
    modalBarrierColor: scrim,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: panel,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    barrierColor: scrim,
    titleTextStyle: textBody,
    contentTextStyle: textLine,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: rule, width: hairline),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: const OutlineInputBorder(
      borderSide: BorderSide(color: rule, width: hairline),
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: rule, width: hairline),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: ink, width: hairline * 2),
    ),
    labelStyle: textLineDim,
    hintStyle: textLineDim,
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: ink,
    selectionColor: armedFill,
    selectionHandleColor: ink,
  ),
);
