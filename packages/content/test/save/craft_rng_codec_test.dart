import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/profile_codec.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Profile _reread(Profile profile) =>
    decodeProfile({'profile': encodeProfile(profile)}, 'profile');

void main() {
  group('craftRngState rides the profile codec omit-on-default', () {
    test('a hero who has never crafted writes no key at all', () {
      // arrange
      final fresh = newProfile(worldSeed: 9007199254740993);

      // act
      final written = encodeProfile(fresh);

      // assert - an unconditional encode would rewrite every golden document
      expect(written.containsKey('craftRngState'), isFalse);
    });

    test('an advanced stream state is written as text', () {
      // arrange
      final advanced = newProfile(
        worldSeed: 9007199254740993,
      ).copyWith(craftRngState: -8613303245920329199);

      // act
      final written = encodeProfile(advanced);

      // assert - generator states are text; a number would not survive a
      // narrow reader
      expect(written['craftRngState'], '-8613303245920329199');
    });

    test('an absent key reads as never-drawn — the legacy shape loads', () {
      // arrange
      final fresh = newProfile(worldSeed: 9007199254740993);
      final written = encodeProfile(fresh)..remove('craftRngState');

      // act
      final back = decodeProfile({'profile': written}, 'profile');

      // assert
      expect(back.craftRngState, 0);
      expect(back, fresh);
    });

    test('a written state round-trips', () {
      // arrange
      final advanced = newProfile(
        worldSeed: 9007199254740993,
      ).copyWith(craftRngState: -8613303245920329199);

      // act
      final back = _reread(advanced);

      // assert
      expect(back.craftRngState, -8613303245920329199);
      expect(back, advanced);
    });
  });
}