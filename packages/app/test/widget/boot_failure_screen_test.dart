import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/main.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_content/content.dart';

import '../support/memory_save_files.dart';

/// A store whose read always throws, standing in for a boot that cannot even
/// ask the disk what is there.
class _ThrowingStore extends SaveStore {
  _ThrowingStore() : super(_ThrowingSaveFiles());

  @override
  Future<LoadedSave> load() async =>
      throw StateError('the disk answered with nothing at all');
}

class _ThrowingSaveFiles implements SaveFiles {
  @override
  Future<String?> read(String name) async =>
      throw StateError('the disk answered with nothing at all');

  @override
  Future<void> write(String name, String contents) async =>
      throw StateError('the disk answered with nothing at all');

  @override
  Future<void> rename(String from, String to) async =>
      throw StateError('the disk answered with nothing at all');

  @override
  Future<void> delete(String name) async =>
      throw StateError('the disk answered with nothing at all');
}

void main() {
  group('the boot failure screen', () {
    testWidgets('a thrown boot opens on a sentence and a Begin-fresh door', (
      tester,
    ) async {
      // arrange — sized like a phone: this is a new screen, and its first
      // reading is the one a real device gives it.
      tester.view.physicalSize = const Size(1080, 2424);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final app = await guardedBoot(_ThrowingStore(), rollWorldSeed: () => 5);

      // act
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // assert — the app's first failure screen, sized like a phone: a
      // sentence a player reads, one action, nothing told apart by colour.
      expect(find.text('The crawl is unreachable.'), findsOneWidget);
      expect(
        find.text('the game could not start from your save'),
        findsOneWidget,
      );
      expect(find.text('Begin fresh'), findsOneWidget);
    });

    testWidgets('a retry that throws again re-renders the same screen', (
      tester,
    ) async {
      // arrange
      final app = await guardedBoot(_ThrowingStore(), rollWorldSeed: () => 5);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // act
      await tester.tap(find.text('Begin fresh'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Begin fresh'), findsOneWidget);
      expect(
        find.text('the game could not start from your save'),
        findsOneWidget,
      );
    });

    testWidgets('a healthy boot lands in the app, not the failure screen', (
      tester,
    ) async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 5),
        ),
      );

      // act
      final app = await guardedBoot(store, rollWorldSeed: () => 5);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('Begin fresh'), findsNothing);
    });
  });
}
