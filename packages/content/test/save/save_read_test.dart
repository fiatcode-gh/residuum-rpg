import 'package:residuum_content/content.dart';
import 'package:test/test.dart';

void main() {
  group('SaveRead', () {
    test('a failure is a value with a sentence in it', () {
      // arrange
      const reason = 'the save file could not be read at all';

      // act
      const failure = SaveFailure(reason);

      // assert
      expect(failure.reason, reason);
      expect(failure, const SaveFailure(reason));
    });

    test('a document with no run block is a hero standing in town', () {
      // arrange
      final profile = newProfile(worldSeed: 7);

      // act
      final document = SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: profile,
      );

      // assert
      expect(document.run, isNull);
      expect(document.profile.worldSeed, 7);
      expect(document.active, 'hero-1');
      expect(document.hero.label, 'Hero 1');
    });

    test('either outcome switches exhaustively as one type', () {
      // arrange
      final reads = <SaveRead>[
        SaveDocument.one(id: 'hero-1', label: 'Hero 1', profile: newProfile()),
        const SaveFailure('nope'),
      ];

      // act
      final described = reads
          .map(
            (read) => switch (read) {
              SaveDocument() => 'document',
              SaveFailure() => 'failure',
            },
          )
          .toList();

      // assert
      expect(described, ['document', 'failure']);
    });
  });
}
