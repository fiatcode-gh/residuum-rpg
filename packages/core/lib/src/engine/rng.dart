/// A seeded source of random numbers whose whole state is one exportable int.
///
/// Every random decision in Residuum draws from an `Rng` carried in the game
/// state: a fixed seed and a fixed sequence of calls must always produce the
/// same game. The generator is hand-rolled rather than `dart:math.Random`
/// because `Random` exposes no way to read its internal state back out, so a
/// run in progress could not be written to a save file and resumed on the
/// stream it left off on. [state] and [Rng.fromState] are that missing pair.
///
/// The algorithm is splitmix64: the state advances by a fixed odd increment
/// and the output is that state passed through two rounds of
/// xor-shift-multiply. One roll advances the state exactly once, so a
/// restored generator resumes roll for roll.
///
/// The arithmetic stands on `int` being 64-bit two's complement with silent
/// wrapping. That holds on the Dart virtual machine and in ahead-of-time
/// builds, but not under `dart2js`, where `int` is a double and the wrapping
/// would be lost. Residuum targets Android, so the constraint holds; a web
/// target would need a different substrate.
class Rng {
  /// A generator started from [seed]. Any int is a valid seed.
  Rng(int seed) : _state = _mix(seed);

  /// A generator resumed exactly where the one that exported [state] stopped.
  Rng.fromState(int state) : _state = state;

  static const int _gamma = -0x61c8864680b583eb;

  int _state;

  /// The whole generator state, enough to restore it with [Rng.fromState].
  int get state => _state;

  /// A uniform integer between [min] and [maxInclusive], both ends included.
  ///
  /// The range is reduced by one modulo of the sixty-three non-sign bits of
  /// the raw output. That leans towards the low end of the range by at most
  /// one part in `2^63 / span` — far below anything a dungeon could show,
  /// since the widest span the game rolls is a few thousand. Rejection
  /// sampling would remove the lean, but it would make the number of draws
  /// depend on the values drawn, and the point of this class is that one roll
  /// costs exactly one advance.
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
    _state += _gamma;
    return min + (_mix(_state) >>> 1) % (maxInclusive - min + 1);
  }

  static int _mix(int value) {
    var mixed = (value ^ (value >>> 30)) * -0x40a7b892e31b1a47;
    mixed = (mixed ^ (mixed >>> 27)) * -0x6b2fb644ecceee15;
    return mixed ^ (mixed >>> 31);
  }
}
