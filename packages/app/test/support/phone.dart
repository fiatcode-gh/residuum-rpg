import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

/// Sizes the test surface like the phone the device pass runs on.
///
/// The default surface is 800 by 600 logical pixels, which is wider than any
/// phone in portrait — so a row that overflows on a Pixel fits on it, and the
/// defect ships. Restored after the test so nothing else inherits the size.
Future<void> onAPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2424);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Sizes the test surface exactly like the phone the U16.5 device pass
/// captures on (vivo I2219: 393 x 875.6 dp, density 440), with the
/// Checkpoint A logcat `WindowInsets` reading (top 38.2 dp, bottom 17.8 dp —
/// PLAN.md assumed 37.8 / 24.0 before the reading came back).
/// `FakeViewPadding` is in physical pixels, so each dp figure is multiplied
/// by [devicePixelRatio].
Future<void> onTheTargetPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2408);
  tester.view.devicePixelRatio = 2.75;
  tester.view.padding = FakeViewPadding(top: 38.2 * 2.75, bottom: 17.8 * 2.75);
  addTearDown(tester.view.reset);
}
