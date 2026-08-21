import 'package:residuum_content/src/save/save_json.dart';
import 'package:test/test.dart';

void main() {
  group('wide values', () {
    test('a full-width value is written as a quoted string', () {
      // arrange
      const value = 9007199254740993;

      // act
      final written = encodeWide(value);

      // assert
      expect(written, '9007199254740993');
      expect(written, isA<String>());
    });

    test('a full-width value read back from its string is exact', () {
      // arrange
      final written = {'seed': encodeWide(-8613303245920329199)};

      // act
      final read = wideAt(written, 'seed');

      // assert
      expect(read, -8613303245920329199);
    });

    test('a wide field given as a JSON number is refused', () {
      // arrange
      final document = <String, Object?>{'seed': 9007199254740993};

      // act
      void act() => wideAt(document, 'seed');

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('"seed"'),
          ),
        ),
      );
    });

    test('a wide field that is not a number at all is refused', () {
      // arrange
      final document = <String, Object?>{'seed': 'ninety'};

      // act
      void act() => wideAt(document, 'seed');

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });
  });

  group('typed fields', () {
    test('a missing field names itself', () {
      // arrange
      final document = <String, Object?>{'gold': 3};

      // act
      void act() => intAt(document, 'depth');

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('"depth"'),
          ),
        ),
      );
    });

    test('a field of the wrong type is refused rather than coerced', () {
      // arrange
      final document = <String, Object?>{'gold': '3'};

      // act
      void act() => intAt(document, 'gold');

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });

    test('a field present but null is refused', () {
      // arrange
      final document = <String, Object?>{'gold': null};

      // act
      void act() => intAt(document, 'gold');

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });

    test('each reader hands back its own type', () {
      // arrange
      final document = <String, Object?>{
        'object': <String, Object?>{'a': 1},
        'list': <Object?>[1, 2],
        'int': 4,
        'string': 'five',
        'bool': true,
      };

      // act
      final read = [
        objectAt(document, 'object'),
        listAt(document, 'list'),
        intAt(document, 'int'),
        stringAt(document, 'string'),
        boolAt(document, 'bool'),
      ];

      // assert
      expect(read, [
        {'a': 1},
        [1, 2],
        4,
        'five',
        true,
      ]);
    });
  });
}
