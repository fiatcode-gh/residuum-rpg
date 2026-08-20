import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _keen = Affix(
  id: 'keen',
  affixName: 'Keen',
  isPrefix: true,
  attackMax: 2,
);

const _ofEmbers = Affix(
  id: 'of-embers',
  affixName: 'of Embers',
  isPrefix: false,
  attackMin: 1,
  attackMax: 2,
);

void main() {
  group('Item.displayName', () {
    test('a common item is the tier word and the base name', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);

      // act
      final name = item.displayName;

      // assert
      expect(name, 'Common Iron Sword');
    });

    test('a prefix lands before the base name and a suffix after it', () {
      // arrange
      const item = Item(
        id: 'drop-2',
        base: _sword,
        rarity: Rarity.rare,
        affixes: [_ofEmbers, _keen],
      );

      // act
      final name = item.displayName;

      // assert
      expect(name, 'Rare Keen Iron Sword of Embers');
    });
  });

  group('Item stats', () {
    test('sums the base item and every affix', () {
      // arrange
      const item = Item(
        id: 'drop-3',
        base: _sword,
        rarity: Rarity.rare,
        affixes: [_keen, _ofEmbers],
      );

      // act
      final range = (item.attackMin, item.attackMax);

      // assert
      expect(range, (4, 9));
    });
  });

  group('BaseItem kinds', () {
    test('a potion has no slot and cannot be equipped', () {
      // arrange
      const potion = BaseItem(
        id: 'healing-potion',
        name: 'Healing Potion',
        glyph: '!',
        heal: 8,
      );

      // act
      final kinds = (potion.isPotion, potion.isEquippable, potion.isWeapon);

      // assert
      expect(kinds, (true, false, false));
    });

    test('a shield is armour, not a weapon', () {
      // arrange
      const shield = BaseItem(
        id: 'kite-shield',
        name: 'Kite Shield',
        glyph: '[',
        slot: EquipSlot.offHand,
        armor: 2,
        heavy: true,
      );

      // act
      final kinds = (shield.isArmour, shield.isWeapon, shield.isEquippable);

      // assert
      expect(kinds, (true, false, true));
    });
  });

  group('Item equality', () {
    test('two rolls with the same id and contents are equal', () {
      // arrange
      const one = Item(
        id: 'drop-4',
        base: _sword,
        rarity: Rarity.fine,
        affixes: [_keen],
      );
      const other = Item(
        id: 'drop-4',
        base: _sword,
        rarity: Rarity.fine,
        affixes: [_keen],
      );

      // act
      final same = one == other;

      // assert
      expect(same, isTrue);
    });

    test('a different roll of the same base is not equal', () {
      // arrange
      const one = Item(
        id: 'drop-5',
        base: _sword,
        rarity: Rarity.fine,
        affixes: [_keen],
      );
      const other = Item(
        id: 'drop-5',
        base: _sword,
        rarity: Rarity.fine,
        affixes: [_ofEmbers],
      );

      // act
      final same = one == other;

      // assert
      expect(same, isFalse);
    });
  });
}
