import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'support/memory_save_files.dart';

Profile _hero({int gold = 0}) => newProfile(worldSeed: 5).copyWith(gold: gold);

/// A one-hero document, which every slot-rotation test here is about.
SaveDocument _one(Profile profile, {GameState? run}) => SaveDocument.one(
  id: 'hero-1',
  label: 'Hero 1',
  profile: profile,
  run: run,
  dungeon: run == null ? null : cryptNode,
  campDay: run == null ? null : 0,
);

void main() {
  group('saving', () {
    test('a first save lands in the current slot and nowhere else', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);

      // act
      final wrote = await store.save(_one(_hero()));

      // assert
      expect(wrote, isTrue);
      expect(files.contents.keys, [currentSlot]);
      expect(decodeSave(files.contents[currentSlot]!), isA<SaveDocument>());
    });

    test(
      'a second save rotates the first one into the previous slot',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        await store.save(_one(_hero()));
        final first = files.contents[currentSlot];

        // act
        await store.save(_one(_hero(gold: 99)));

        // assert
        expect(files.contents[previousSlot], first);
        expect(files.contents[currentSlot], isNot(first));
        expect(files.contents.containsKey(pendingSlot), isFalse);
      },
    );

    test(
      'a failed write leaves both existing slots exactly as they were',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        await store.save(_one(_hero()));
        await store.save(_one(_hero(gold: 1)));
        final current = files.contents[currentSlot];
        final previous = files.contents[previousSlot];
        files.failWritesTo.add(pendingSlot);

        // act
        final wrote = await store.save(_one(_hero(gold: 2)));

        // assert
        expect(wrote, isFalse);
        expect(files.contents[currentSlot], current);
        expect(files.contents[previousSlot], previous);
      },
    );

    test('a write that cannot be read back does not rotate either', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(_hero()));
      final current = files.contents[currentSlot];
      files.failReadsTo.add(pendingSlot);

      // act
      final wrote = await store.save(_one(_hero(gold: 3)));

      // assert
      expect(wrote, isFalse);
      expect(files.contents[currentSlot], current);
      expect(files.contents.containsKey(previousSlot), isFalse);
    });

    test('a half-written pending file does not rotate either', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(_hero()));
      final current = files.contents[currentSlot];
      final truncating = _TruncatingSaveFiles(files);

      // act
      final wrote = await SaveStore(truncating).save(_one(_hero(gold: 4)));

      // assert
      expect(wrote, isFalse);
      expect(files.contents[currentSlot], current);
      expect(files.contents.containsKey(previousSlot), isFalse);
    });

    test('a suspended crawl is written into the same document', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final profile = newProfile(worldSeed: 8);

      // act
      await store.save(
        _one(profile, run: startDungeonRunAt(cryptNode, profile)),
      );

      // assert
      final read = decodeSave(files.contents[currentSlot]!) as SaveDocument;
      expect(read.run, isNotNull);
      expect(read.run!.depth, 1);
    });

    test('the pending file is cleaned up after a failed write', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      files.failWritesTo.add(pendingSlot);

      // act
      await store.save(_one(_hero()));

      // assert
      expect(files.contents, isEmpty);
    });
  });

  group('loading', () {
    test('a fresh install has nothing to load and nothing to report', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);

      // act
      final loaded = await store.load();

      // assert
      expect(loaded.document, isNull);
      expect(loaded.report, isNull);
    });

    test('a good current slot loads with nothing to report', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(_hero(gold: 12)));

      // act
      final loaded = await store.load();

      // assert
      expect(loaded.document, isNotNull);
      expect(loaded.document!.profile.gold, 12);
      expect(loaded.report, isNull);
    });

    test(
      'a corrupt current slot falls back to the previous one, and says so',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        await store.save(_one(_hero(gold: 7)));
        await store.save(_one(_hero(gold: 8)));
        files.contents[currentSlot] = '{"version": 1, "prof';

        // act
        final loaded = await store.load();

        // assert
        expect(loaded.document!.profile.gold, 7);
        expect(
          loaded.report,
          'your last save could not be read; an older one was restored',
        );
      },
    );

    test('both slots corrupt begins a new hero, and says so', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(_hero()));
      await store.save(_one(_hero(gold: 8)));
      files.contents[currentSlot] = 'not json';
      files.contents[previousSlot] = 'also not json';

      // act
      final loaded = await store.load();

      // assert
      expect(loaded.document, isNull);
      expect(
        loaded.report,
        'your last save could not be read; a new hero begins',
      );
    });

    test(
      'a current slot lost mid-rotation falls back to the previous one',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        await store.save(_one(_hero(gold: 7)));
        await store.save(_one(_hero(gold: 8)));
        files.contents.remove(currentSlot);

        // act
        final loaded = await store.load();

        // assert
        expect(loaded.document!.profile.gold, 7);
        expect(loaded.report, isNotNull);
      },
    );

    test('a save from a version this build cannot read falls back', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(_hero(gold: 7)));
      await store.save(_one(_hero(gold: 8)));
      files.contents[currentSlot] = files.contents[currentSlot]!.replaceFirst(
        '"version":1',
        '"version":2',
      );

      // act
      final loaded = await store.load();

      // assert
      expect(loaded.document!.profile.gold, 7);
      expect(loaded.report, isNotNull);
    });

    test('a suspended crawl comes back out of the current slot', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final profile = newProfile(worldSeed: 8);
      final run = startDungeonRunAt(cryptNode, profile);
      await store.save(_one(profile, run: run));

      // act
      final loaded = await store.load();

      // assert
      expect(loaded.document!.run, isNotNull);
      expect(loaded.document!.run!.rng.state, run.rng.state);
      expect(loaded.document!.run!.visit, run.visit);
    });

    test('an unreadable current slot with no previous one begins fresh, and '
        'says so', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(_hero()));
      files.contents[currentSlot] = 'broken';

      // act
      final loaded = await store.load();

      // assert
      expect(loaded.document, isNull);
      expect(
        loaded.report,
        'your last save could not be read; a new hero begins',
      );
    });
  });
}

/// A disk that accepts a write and keeps only half of it.
///
/// The one failure a `write` that returns without throwing can still be: the
/// bytes are short. Only reading the file back catches it.
class _TruncatingSaveFiles implements SaveFiles {
  _TruncatingSaveFiles(this._real);

  final SaveFiles _real;

  @override
  Future<String?> read(String name) => _real.read(name);

  @override
  Future<void> write(String name, String contents) =>
      _real.write(name, contents.substring(0, contents.length ~/ 2));

  @override
  Future<void> rename(String from, String to) => _real.rename(from, to);

  @override
  Future<void> delete(String name) => _real.delete(name);
}
