import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// A craft-stream state whose next percent roll lands at or above [floor].
int stateRollingAtLeast(int floor) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) >= floor) return state;
  }
  throw StateError('no state rolls at or above $floor');
}

/// A craft-stream state whose next percent roll lands below [ceiling].
int stateRollingBelow(int ceiling) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) < ceiling) return state;
  }
  throw StateError('no state rolls below $ceiling');
}

void main() {
  group('temperFailChance', () {
    test('tier 1 never fails', () {
      expect(temperFailChance(1, 0), 0);
      expect(temperFailChance(1, 100), 0);
    });

    test('tier 2 starts at twenty at its gate', () {
      expect(temperFailChance(2, 5), 20);
    });

    test('tier 3 starts at thirty-five at its gate', () {
      expect(temperFailChance(3, 10), 35);
    });

    test('every level past the gate takes two points off', () {
      expect(temperFailChance(2, 6), 18);
      expect(temperFailChance(3, 13), 29);
    });

    test('the floor clamps at five and never below', () {
      // arrange - the levels that would go under
      // act
      final clamped = [
        temperFailChance(2, 12),
        temperFailChance(2, 13),
        temperFailChance(2, 30),
        temperFailChance(3, 25),
        temperFailChance(3, 26),
        temperFailChance(3, 30),
      ];

      // assert - training tames the odds and never kills them
      expect(clamped, [6, 5, 5, 5, 5, 5]);
    });
  });

  group('brewFailChance', () {
    test('level 0 brews at twenty, and no gate stands in the way', () {
      expect(brewFailChance(0), 20);
    });

    test('every level takes two points off, floored at five', () {
      expect(brewFailChance(7), 6);
      expect(brewFailChance(8), 5);
      expect(brewFailChance(9), 5);
      expect(brewFailChance(50), 5);
    });
  });

  group('craftDraw', () {
    test('lazy-seeds off the world seed on the first draw', () {
      // arrange
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
      );

      // act
      final (after, _) = craftDraw(profile, 20);

      // assert
      final rng = Rng(5 ^ craftSeedSalt)..rollRange(0, 99);
      expect(after.craftRngState, rng.state);
    });

    test('advances from the carried state once drawn', () {
      // arrange
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: 1234,
      );

      // act
      final (after, _) = craftDraw(profile, 20);

      // assert
      final rng = Rng.fromState(1234)..rollRange(0, 99);
      expect(after.craftRngState, rng.state);
    });

    test('advances exactly once even when the tier cannot fail', () {
      // arrange
      final seed = stateRollingAtLeast(1);
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: seed,
      );

      // act
      final (after, failed) = craftDraw(profile, 0);

      // assert - stream consumption is a fact about the attempt, not the
      // outcome; skipping the draw would make it outcome-dependent
      final rng = Rng.fromState(seed)..rollRange(0, 99);
      expect(failed, isFalse);
      expect(after.craftRngState, rng.state);
    });

    test('answers failure below the odds and success at or above them', () {
      // arrange
      final fails = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: stateRollingBelow(20),
      );
      final holds = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: stateRollingAtLeast(20),
      );

      // act
      final (_, failed) = craftDraw(fails, 20);
      final (_, held) = craftDraw(holds, 20);

      // assert
      expect(failed, isTrue);
      expect(held, isFalse);
    });
  });
}