import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/small_world.dart';

void main() {
  group('Whereabouts', () {
    test('a hero standing still is not on a road', () {
      // arrange
      final where = atHome();

      // act
      final travelling = where.isTravelling;

      // assert
      expect(travelling, isFalse);
      expect(where.journey, isNull);
    });

    test('a hero who has not heard of where they stand is refused', () {
      // act
      Whereabouts make() =>
          Whereabouts(at: ridge, home: harbour, discovered: {harbour, crypt});

      // assert
      expect(make, throwsArgumentError);
    });

    test('a hero whose home they have not heard of is refused', () {
      // act
      Whereabouts make() =>
          Whereabouts(at: harbour, home: ridge, discovered: {harbour});

      // assert
      expect(make, throwsArgumentError);
    });

    test('a day before the first one is refused', () {
      // act
      Whereabouts make() => Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour},
        day: -1,
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('a road the hero is on has to start where they last stood', () {
      // act
      Whereabouts make() => Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour, ridge, crypt},
        journey: Journey(from: ridge, to: crypt, daysLeft: 1),
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('a road with no days left on it is not a road being walked', () {
      // act
      Journey make() => Journey(from: harbour, to: crypt, daysLeft: 0);

      // assert
      expect(make, throwsArgumentError);
    });

    test('the discovered set cannot be changed from outside', () {
      // arrange
      final where = atHome();

      // act
      void mutate() => where.discovered.add(ridge);

      // assert
      expect(mutate, throwsUnsupportedError);
    });

    test('hearing of a place adds it and leaves everything else alone', () {
      // arrange
      final where = atHome();

      // act
      final after = where.hearingOf(ridge);

      // assert
      expect(after.discovered, {harbour, crypt, ridge});
      expect(after.at, where.at);
      expect(after.day, where.day);
      expect(after.home, where.home);
    });

    test('arriving reveals what the place is next to', () {
      // arrange
      final where = atHome();

      // act
      final after = where.arrivingAt(smallWorld(), crypt);

      // assert
      expect(after.at, crypt);
      expect(after.discovered, {harbour, crypt, ridge});
      expect(after.isTravelling, isFalse);
    });

    test('arriving in a town makes it the place the hero wakes at', () {
      // arrange
      final where = atHome().hearingOf(ridge);

      // act
      final after = where.arrivingAt(smallWorld(), ridge);

      // assert
      expect(after.home, ridge);
    });

    test('arriving at a dungeon leaves home where it was', () {
      // arrange
      final where = atHome();

      // act
      final after = where.arrivingAt(smallWorld(), crypt);

      // assert
      expect(after.home, harbour);
    });

    test('two whereabouts holding the same facts are the same whereabouts', () {
      // arrange
      final one = atHome();

      // act
      final other = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {crypt, harbour},
      );

      // assert
      expect(one, other);
    });
  });
}
