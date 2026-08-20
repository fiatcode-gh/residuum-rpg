import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Rarity', () {
    test('affix count is the definition of a tier', () {
      // arrange
      const tiers = Rarity.values;

      // act
      final counts = [for (final tier in tiers) tier.affixCount];

      // assert
      expect(counts, [0, 1, 2, 3, 4]);
    });

    test('every tier carries a marking that survives greyscale', () {
      // arrange
      const tiers = Rarity.values;

      // act
      final markings = [for (final tier in tiers) tier.marking];

      // assert
      expect(markings, ['·', '+', '++', '※', '★']);
      expect(markings.toSet(), hasLength(tiers.length));
    });

    test('the tier word names the item', () {
      // arrange
      const tier = Rarity.fine;

      // act
      final word = tier.word;

      // assert
      expect(word, 'Fine');
    });
  });

  group('EquipSlot', () {
    test('is exactly the six slots the milestone locks', () {
      // arrange
      const slots = EquipSlot.values;

      // act
      final names = [for (final slot in slots) slot.name];

      // assert
      expect(names, ['mainHand', 'offHand', 'head', 'chest', 'hands', 'feet']);
    });
  });
}
