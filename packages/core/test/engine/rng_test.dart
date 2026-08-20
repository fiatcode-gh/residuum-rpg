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
}
