import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/quick_popup.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

void main() {
  group('potionKinds', () {
    test('groups same-named potions by display name and counts them', () {
      // arrange - three carried potions, two answering to the same name
      final inventory = [
        const Item(id: 'kit-1', base: healingPotion, rarity: Rarity.common),
        const Item(id: 'kit-2', base: healingPotion, rarity: Rarity.common),
        const Item(id: 'kit-3', base: healingPotion, rarity: Rarity.fine),
      ];

      // act
      final kinds = potionKinds(inventory);

      // assert - first-appearance order, and each kind picks its first item
      expect(kinds, hasLength(2));
      expect(kinds[0].item.id, 'kit-1');
      expect(kinds[0].count, 2);
      expect(kinds[1].item.id, 'kit-3');
      expect(kinds[1].count, 1);
    });

    test('ignores books and gear carried alongside potions', () {
      // arrange
      final inventory = [
        const Item(id: 'sword-1', base: ironSword, rarity: Rarity.common),
        const Item(id: 'book-1', base: bookOfMend, rarity: Rarity.common),
        const Item(id: 'kit-1', base: healingPotion, rarity: Rarity.common),
      ];

      // act
      final kinds = potionKinds(inventory);

      // assert
      expect(kinds, hasLength(1));
      expect(kinds.single.item.id, 'kit-1');
    });

    test('is empty when nothing carried is a potion', () {
      // arrange
      final inventory = [
        const Item(id: 'sword-1', base: ironSword, rarity: Rarity.common),
      ];

      // act
      final kinds = potionKinds(inventory);

      // assert
      expect(kinds, isEmpty);
    });

    test('is empty with an empty pack', () {
      expect(potionKinds(const []), isEmpty);
    });
  });
}
