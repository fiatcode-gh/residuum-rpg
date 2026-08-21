import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/main.dart';
import 'package:residuum_app/save/boot.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_content/content.dart';

import 'memory_save_files.dart';

/// A real app over a real store, with a map standing in for the disk.
///
/// Nothing the test asserts on is a fake: the widgets are the app's own, the
/// store is the app's own, the blocs are the app's own, and only the file system
/// is a map. A widget test that injected a fake town or a fake autosaver would be
/// testing its own scaffolding — and every defect this harness exists to catch is
/// in the wiring between the real parts.
///
/// Blocs are never closed by a test that uses this. Awaiting a bloc's close
/// inside `testWidgets` hangs, because a bloc finishes closing on the event loop
/// and a widget test's clock never gets there; the blocs live as long as the test
/// process instead.
class PumpedApp {
  PumpedApp(this.document);

  /// The save the app is pumped onto.
  final SaveDocument document;

  final MemorySaveFiles files = MemorySaveFiles();

  late final SaveStore store = SaveStore(files);

  /// The document in the current slot, decoded, or null when nothing readable is
  /// there.
  SaveDocument? get saved {
    final written = files.contents[currentSlot];
    if (written == null) return null;
    return switch (decodeSave(written)) {
      SaveDocument read => read,
      SaveFailure() => null,
    };
  }

  /// Pumps the app onto [document], seeded on disk first so a relaunch would
  /// find it.
  Future<void> pump(WidgetTester tester) async {
    await store.save(document);
    await tester.pumpWidget(
      ResiduumApp(
        store: store,
        boot: Boot(document: document),
      ),
    );
    await tester.pumpAndSettle();
  }
}
