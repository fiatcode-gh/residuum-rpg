import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_app/save/save_files_io.dart';

void main() {
  group('the real file adapter, against a real temp directory', () {
    late Directory home;
    late IoSaveFiles files;

    setUp(() async {
      home = await Directory.systemTemp.createTemp('residuum-io-');
      files = IoSaveFiles(home);
    });

    tearDown(() async {
      await home.delete(recursive: true);
    });

    test('an absent file reads null', () async {
      // act
      final contents = await files.read(currentSlot);

      // assert
      expect(contents, isNull);
    });

    test('an unreadable slot reads null', () async {
      // arrange — a directory standing where a file was expected: the read
      // is refused by the platform, which is what an unreadable slot is.
      final locked = Directory('${home.path}/$currentSlot');
      await locked.create();

      // act
      final contents = await files.read(currentSlot);

      // assert
      expect(contents, isNull);
    });

    test('a write then a read round-trips', () async {
      // act
      await files.write(currentSlot, 'the roster, whole');
      final contents = await files.read(currentSlot);

      // assert
      expect(contents, 'the roster, whole');
    });

    test('a rename over an existing target replaces it', () async {
      // arrange
      await files.write(pendingSlot, 'the new document');
      await files.write(currentSlot, 'the old one');

      // act
      await files.rename(pendingSlot, currentSlot);

      // assert
      expect(await files.read(currentSlot), 'the new document');
      expect(await files.read(pendingSlot), isNull);
    });

    test('a rename of an absent source does nothing', () async {
      // arrange
      await files.write(currentSlot, 'the old one');

      // act
      await files.rename(pendingSlot, currentSlot);

      // assert
      expect(await files.read(currentSlot), 'the old one');
    });

    test('a write failure throws', () async {
      // arrange — the write lands in a directory that is not there.
      final gone = IoSaveFiles(Directory('${home.path}/removed-before-use'));

      // act + assert
      await expectLater(
        gone.write(currentSlot, 'anything'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('a delete of an absent file does nothing', () async {
      // act
      await files.delete(previousSlot);

      // assert — nothing threw and nothing exists
      expect(await files.read(previousSlot), isNull);
    });

    test('a delete of a present file removes it', () async {
      // arrange
      await files.write(currentSlot, 'the roster, whole');

      // act
      await files.delete(currentSlot);

      // assert
      expect(await files.read(currentSlot), isNull);
    });

    test('a rename that cannot move throws', () async {
      // arrange — the source stands where a directory already does, which is
      // what a target the disk will not take looks like.
      final source = File('${home.path}/the-source');
      await source.writeAsString('content');
      final target = Directory('${home.path}/the-target');
      await target.create();

      // act + assert
      await expectLater(
        files.rename('the-source', 'the-target'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
