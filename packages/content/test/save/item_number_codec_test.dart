import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/profile_codec.dart';
import 'package:residuum_content/src/save/run_codec.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Profile _reread(Profile profile) =>
    decodeProfile({'profile': encodeProfile(profile)}, 'profile');

GameState _rereadRun(GameState run) =>
    loadRun({'run': encodeRun(run)}, 'run', dungeon: cryptNode);

GameState _camp() => startDungeonRunAt(cryptNode, newProfile(worldSeed: 909));

void main() {
  group('itemNumber rides the profile codec omit-on-default', () {
    test('a default profile writes no key at all', () {
      // arrange
      final fresh = newProfile(worldSeed: 9007199254740993);

      // act
      final written = encodeProfile(fresh);

      // assert
      expect(
        written.containsKey('itemNumber'),
        isFalse,
        reason: 'an unconditional encode would rewrite every golden document',
      );
    });

    test('an advanced counter is written', () {
      // arrange
      final advanced = newProfile(
        worldSeed: 9007199254740993,
      ).copyWith(itemNumber: 7);

      // act
      final written = encodeProfile(advanced);

      // assert
      expect(written['itemNumber'], 7);
    });

    test('an absent key reads as one — the legacy-shape save loads', () {
      // arrange
      final fresh = newProfile(worldSeed: 9007199254740993);
      final written = encodeProfile(fresh)..remove('itemNumber');

      // act
      final back = decodeProfile({'profile': written}, 'profile');

      // assert
      expect(back.itemNumber, 1);
      expect(back, fresh);
    });

    test('a written counter round-trips', () {
      // arrange
      final advanced = newProfile(
        worldSeed: 9007199254740993,
      ).copyWith(itemNumber: 7);

      // act
      final back = _reread(advanced);

      // assert
      expect(back.itemNumber, 7);
      expect(back, advanced);
    });
  });

  group('itemNumber rides the run codec omit-on-default', () {
    test('a default run writes no key at all', () {
      // arrange
      final camped = _camp();

      // act
      final written = encodeRun(camped);

      // assert
      expect(
        written.containsKey('itemNumber'),
        isFalse,
        reason: 'the run goldens must stay byte-identical',
      );
    });

    test('an advanced counter round-trips', () {
      // arrange
      final camped = _camp().copyWith(itemNumber: 3);

      // act
      final back = _rereadRun(camped);

      // assert
      expect(back.itemNumber, 3);
    });

    test('an absent key reads as one', () {
      // arrange
      final camped = _camp();
      final written = encodeRun(camped)..remove('itemNumber');

      // act
      final back = loadRun({'run': written}, 'run', dungeon: cryptNode);

      // assert
      expect(back.itemNumber, 1);
    });
  });
}
