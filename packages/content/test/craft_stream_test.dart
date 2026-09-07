import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// The house sweep list — every fixture hero the pins stand on.
const List<int> _sweptSeeds = [1, 5, 77, 909, 4242, 123456, 1755800000000];

List<int> _earlyRolls(Rng rng) =>
    [for (var roll = 0; roll < 64; roll++) rng.rollRange(0, 99)];

bool _same(List<int> left, List<int> right) {
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void main() {
  group('the craft stream', () {
    test('never runs in step with the loot stream', () {
      // arrange
      final collisions = <String>[];

      // act
      for (final worldSeed in _sweptSeeds) {
        final craftRolls = _earlyRolls(Rng(worldSeed ^ craftSeedSalt));
        final lootRolls = _earlyRolls(Rng(worldSeed ^ lootStreamSalt));
        if (_same(craftRolls, lootRolls)) {
          collisions.add('world $worldSeed: craft runs with loot');
        }
      }

      // assert
      expect(collisions, isEmpty);
    });

    test('its salt is its own', () {
      expect(craftSeedSalt, isNot(lootStreamSalt));
    });
  });
}