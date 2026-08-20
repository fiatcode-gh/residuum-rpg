import 'dart:math';

/// A seeded source of random numbers.
///
/// Every random decision in Residuum draws from an `Rng` carried in the game
/// state. Core and content never construct an unseeded [Random]: a fixed seed
/// plus a fixed sequence of calls must always produce the same game.
class Rng {
  Rng(int seed) : _random = Random(seed);

  final Random _random;

  /// A uniform integer between [min] and [maxInclusive], both ends included.
  ///
  /// Throws [ArgumentError] when [maxInclusive] is below [min].
  int rollRange(int min, int maxInclusive) {
    if (maxInclusive < min) {
      throw ArgumentError.value(
        maxInclusive,
        'maxInclusive',
        'must not be below min ($min)',
      );
    }
    return min + _random.nextInt(maxInclusive - min + 1);
  }
}
