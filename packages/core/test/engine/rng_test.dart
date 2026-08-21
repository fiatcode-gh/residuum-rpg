import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

List<int> rollTwenty(Rng rng) =>
    List.generate(20, (_) => rng.rollRange(1, 1000));

void main() {
  group('Rng', () {
    test('the same seed produces the same sequence', () {
      // arrange
      final one = Rng(42);
      final another = Rng(42);

      // act
      final first = rollTwenty(one);
      final second = rollTwenty(another);

      // assert
      expect(first, second);
    });

    test('a different seed produces a different sequence', () {
      // arrange
      final one = Rng(42);
      final another = Rng(43);

      // act
      final first = rollTwenty(one);
      final second = rollTwenty(another);

      // assert
      expect(first, isNot(second));
    });

    test('rolls stay inside the inclusive range', () {
      // arrange
      final rng = Rng(7);

      // act
      final rolls = List.generate(500, (_) => rng.rollRange(3, 5));

      // assert
      expect(rolls, everyElement(inInclusiveRange(3, 5)));
    });

    test('both ends of the range are reachable', () {
      // arrange
      final rng = Rng(7);

      // act
      final rolls = List.generate(500, (_) => rng.rollRange(3, 5));

      // assert
      expect(rolls, contains(3));
      expect(rolls, contains(5));
    });

    test('a single-value range always returns that value', () {
      // arrange
      final rng = Rng(1);

      // act
      final rolls = List.generate(10, (_) => rng.rollRange(4, 4));

      // assert
      expect(rolls, everyElement(4));
    });

    test('an inverted range is rejected', () {
      // arrange
      final rng = Rng(1);

      // act
      void roll() => rng.rollRange(5, 3);

      // assert
      expect(roll, throwsArgumentError);
    });
  });

  group('Rng state export', () {
    test('a restored generator continues the same stream', () {
      // arrange
      final original = Rng(2026);
      List.generate(37, (_) => original.rollRange(1, 6));
      final restored = Rng.fromState(original.state);

      // act
      final tail = List.generate(
        200,
        (index) => original.rollRange(0, index + 1),
      );
      final resumed = List.generate(
        200,
        (index) => restored.rollRange(0, index + 1),
      );

      // assert
      expect(resumed, tail);
    });

    test('a restored generator matches across mixed range sizes', () {
      // arrange
      final original = Rng(-9007199254740993);
      final restored = Rng.fromState(original.state);
      const spans = [(0, 1), (1, 100), (-50, 50), (0, 999999), (7, 7)];

      // act
      final tail = [
        for (var round = 0; round < 100; round++)
          for (final (min, max) in spans) original.rollRange(min, max),
      ];
      final resumed = [
        for (var round = 0; round < 100; round++)
          for (final (min, max) in spans) restored.rollRange(min, max),
      ];

      // assert
      expect(resumed, tail);
    });

    test('every roll moves the state on', () {
      // arrange
      final rng = Rng(11);
      final states = <int>{};

      // act
      for (var roll = 0; roll < 50; roll++) {
        rng.rollRange(0, 3);
        states.add(rng.state);
      }

      // assert
      expect(states, hasLength(50));
    });

    test('a seed and a state of the same value start different streams', () {
      // arrange
      final seeded = Rng(5);
      final restored = Rng.fromState(5);

      // act
      final fromSeed = rollTwenty(seeded);
      final fromState = rollTwenty(restored);

      // assert
      expect(fromSeed, isNot(fromState));
    });
  });

  group('the golden stream', () {
    test('seed 12345 rolls a pinned sequence', () {
      // arrange
      final rng = Rng(12345);

      // act
      final rolls = List.generate(10, (_) => rng.rollRange(0, 999));

      // assert
      expect(rolls, <int>[532, 31, 528, 241, 976, 115, 46, 965, 632, 353]);
    });

    test('seed 12345 exports a pinned state after ten rolls', () {
      // arrange
      final rng = Rng(12345);

      // act
      List.generate(10, (_) => rng.rollRange(0, 999));

      // assert
      expect(rng.state, 2420599403871909411);
    });
  });
}
