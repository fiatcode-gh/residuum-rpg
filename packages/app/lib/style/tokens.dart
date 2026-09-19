import 'package:flutter/material.dart';

const String textFace = 'Spectral';
const String displayFace = 'EB Garamond';

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

const double gutter = 12;
const double rhythm = 4;
const double radius = 6;
const double hairline = 1;
const double tapTarget = 44;

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
  color: dim,
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
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textAction = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 15,
  fontWeight: FontWeight.w400,
  height: 1.25,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textBody = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.30,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLine = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.35,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLineDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.35,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLabel = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.20,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLabelDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.20,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textLabelStrong = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 13,
  fontWeight: FontWeight.w600,
  height: 1.20,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textCaption = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.20,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textDetail = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.30,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textDetailDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.30,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textGlyph = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 18,
  fontWeight: FontWeight.w400,
  height: 1.00,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textGlyphDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 18,
  fontWeight: FontWeight.w400,
  height: 1.00,
  color: dim,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textMicro = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 9,
  fontWeight: FontWeight.w400,
  height: 1.15,
  color: ink,
  fontFeatures: [FontFeature.tabularFigures()],
);
const TextStyle textMicroDim = TextStyle(
  inherit: false,
  fontFamily: textFace,
  fontSize: 9,
  fontWeight: FontWeight.w400,
  height: 1.15,
  color: dim,
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
