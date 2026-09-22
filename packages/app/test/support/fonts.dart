import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:residuum_app/style/tokens.dart';

/// Registers both authored faces with the widget-test host.
///
/// `flutter test` always passes `--use-test-fonts` and
/// `--disable-asset-fonts` to `flutter_tester`
/// (`flutter_tools/lib/src/test/flutter_tester_device.dart:119-120`): the
/// first defaults every unresolved family to the Ahem test font, and the
/// second switches off the engine's own consumption of the font manifest, so
/// a pubspec `fonts:` declaration alone never reaches this host. Loading the
/// bytes through `FontLoader` here is the only thing that does — this
/// registration is what the type authority test's group 1 assertion proves
/// worked.
Future<void> loadResiduumFonts() async {
  for (final (family, assets) in const [
    (
      textFace,
      [
        'assets/fonts/Spectral-Regular.ttf',
        'assets/fonts/Spectral-SemiBold.ttf',
      ],
    ),
    (displayFace, ['assets/fonts/EBGaramond-Variable.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
