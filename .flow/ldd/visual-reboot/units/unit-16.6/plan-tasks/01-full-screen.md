# 01 — Full-screen: native immersive mode and gesture clearance

Governing: `../CONTRACT.md` settled decision 10, scope §7, acceptance 11;
`../PLAN.md` §2 G1. Work from `packages/app`.

## Starting repository state

Head `4b8bd10` (or later with only `.flow/` changes) on
`residuum-visual-reboot-16.6`. `android/app/src/main/kotlin/com/example/residuum_app/MainActivity.kt`
is `class MainActivity : FlutterActivity()`. No `SystemChrome` call exists in
`lib/`. `GameScreen` body is `SafeArea(child: MediaQuery.withClampedTextScaling(...))`.
`flutter.targetSdkVersion` is 36.

## Owned files

`android/app/src/main/kotlin/com/example/residuum_app/MainActivity.kt`,
`lib/game/game_screen.dart` (the `SafeArea` line only),
`lib/game/crawl_style.dart` (add one constant), new
`test/widget/crawl_fullscreen_test.dart`.

Non-goals: any Dart `SystemChrome` call, platform channels, gesture-exclusion
rects, town/world/roster Dart code, `test/support/phone.dart`.

## Locked decisions

1. `MainActivity.kt` exactly per PLAN G1: `onCreate` (after `super`) sets
   `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES` on API ≥ 28 (`Build.VERSION_CODES.P`);
   private `hideSystemBars()` uses `window.insetsController` with
   `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE` + `hide(WindowInsets.Type.systemBars())`
   on API ≥ 30 (`Build.VERSION_CODES.R`), else the deprecated decor-view
   immersive-sticky flag set under `@Suppress("DEPRECATION")`;
   `override fun onPostResume() { super.onPostResume(); hideSystemBars() }`;
   `override fun onWindowFocusChanged(hasFocus: Boolean) { super.onWindowFocusChanged(hasFocus); if (hasFocus) hideSystemBars() }`.
   Platform APIs only — no new Gradle dependency. No comments.
2. `crawl_style.dart`: `const double crawlGestureClear = 18;`.
3. `GameScreen`: `SafeArea(minimum: const EdgeInsets.only(bottom: crawlGestureClear), child: …)`.

## Proof (Red first)

`test/widget/crawl_fullscreen_test.dart` (pump a crawl the way
`test/widget/crawl_layout_test.dart` does):
- zero view padding: the bottom of the lowest crawl control row
  (`actionRowKey` today) is ≤ `surfaceHeight − crawlGestureClear − crawlBottomGap` (± 0.5);
- `tester.view.padding` bottom = 30 dp (physical × dpr): the clearance is
  30, not 48 (minimum is a max, not a sum);
- top padding 24 dp: the first crawl region's top is ≥ 24 (content clear of
  the cut-out).
Expected Red: the first case fails (bar bottom at `height − 6`).
Green: `flutter test`, `dart format lib/game test/widget/crawl_fullscreen_test.dart`,
`flutter analyze`, and `flutter build apk --debug` exit 0 (compiles the
Kotlin).

## Executor discretion

Kotlin member order and import style; test fixture construction; which
existing test helper pumps the crawl.

## Escalate when

The Kotlin does not compile against the embedding's `FlutterActivity`
signatures; an existing test outside the crawl changes because of the
clearance; a Dart-side change seems necessary.

## Completion receipt

Red output, Green commands and exits (including the APK build), the three
measured clearances. State that system-bar hiding is **not** proved here
(device: Checkpoint A). Commit:
`feat(app): run full-screen with immersive system bars`.
