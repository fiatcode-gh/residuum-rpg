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
