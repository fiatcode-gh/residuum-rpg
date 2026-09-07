import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
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

  group('the SavedHero pairings', () {
    Profile base() => newProfile(worldSeed: 7);

    SavedHero hero() => SavedHero(label: 'Hero 1', profile: base());

    test('a crawl without its dungeon is refused at construction', () {
      // arrange
      final run = startDungeonRunAt(cryptNode, newProfile(worldSeed: 7));

      // act + assert
      expect(
        () => SavedHero(label: 'Hero 1', profile: base(), run: run),
        throwsArgumentError,
      );
    });

    test('a dungeon without a crawl is refused at construction', () {
      // act + assert
      expect(
        () => SavedHero(label: 'Hero 1', profile: base(), dungeon: cryptNode),
        throwsArgumentError,
      );
    });

    test('a camp day without a camp is refused at construction', () {
      // act + assert
      expect(
        () => SavedHero(label: 'Hero 1', profile: base(), campDay: 4),
        throwsArgumentError,
      );
    });

    test(
      'a camp without the day it was pitched is refused at construction',
      () {
        // arrange
        final run = startDungeonRunAt(cryptNode, newProfile(worldSeed: 7));

        // act + assert
        expect(
          () => SavedHero(
            label: 'Hero 1',
            profile: base(),
            run: run,
            dungeon: cryptNode,
          ),
          throwsArgumentError,
        );
      },
    );

    test('a hero standing inside their crawl carries no camp day', () {
      // arrange
      final run = startDungeonRunAt(cryptNode, newProfile(worldSeed: 7));

      // act + assert
      expect(
        () => SavedHero(
          label: 'Hero 1',
          profile: base(),
          run: run,
          dungeon: cryptNode,
          inside: true,
          campDay: 4,
        ),
        throwsArgumentError,
      );
    });

    test('the legal shapes stand', () {
      // arrange
      final run = startDungeonRunAt(cryptNode, newProfile(worldSeed: 7));

      // act + assert — in town with nothing waiting; standing inside a crawl;
      // camped away from one, day written down.
      final inTown = hero();
      expect(inTown.run, isNull);
      expect(inTown.campDay, isNull);
      final inside = SavedHero(
        label: 'Hero 1',
        profile: base(),
        run: run,
        dungeon: cryptNode,
        inside: true,
      );
      expect(inside.run, same(run));
      expect(inside.campDay, isNull);
      final camped = SavedHero(
        label: 'Hero 1',
        profile: base(),
        run: run,
        dungeon: cryptNode,
        campDay: 4,
      );
      expect(camped.run, same(run));
      expect(camped.campDay, 4);
    });
  });
}
