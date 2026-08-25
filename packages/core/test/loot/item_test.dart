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

const BaseItem healingPotionForTest = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 10,
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

  group('a spell book', () {
    const book = BaseItem(
      id: 'book-of-firebolt',
      name: 'Book of Firebolt',
      glyph: '?',
      teaches: 'firebolt',
    );

    test('knows the spell it teaches', () {
      // arrange
      const page = book;

      // act
      final taught = page.teaches;

      // assert
      expect(taught, 'firebolt');
      expect(page.isSpellBook, isTrue);
    });

    test('is consumable, exactly as a potion is', () {
      // arrange
      const page = book;

      // act
      final spent = page.isConsumable;

      // assert - both are spent by using them, which is the only thing the
      // drop roller needs to know about either
      expect(spent, isTrue);
      expect(healingPotionForTest.isConsumable, isTrue);
    });

    test('is not worn, not swung, and not drunk', () {
      // arrange
      const page = book;

      // act
      // assert
      expect(page.isWeapon, isFalse);
      expect(page.isArmour, isFalse);
      expect(page.isEquippable, isFalse);
      expect(page.isPotion, isFalse);
    });

    test('anything that is not a book teaches nothing', () {
      // arrange
      const sword = BaseItem(
        id: 'iron-sword',
        name: 'Iron Sword',
        glyph: ')',
        slot: EquipSlot.mainHand,
        hands: WeaponHands.one,
      );

      // act
      final taught = sword.teaches;

      // assert
      expect(taught, isNull);
      expect(sword.isSpellBook, isFalse);
      expect(sword.isConsumable, isFalse);
    });

    test('is part of what makes two base items the same base item', () {
      // arrange
      const one = book;

      // act
      const other = BaseItem(
        id: 'book-of-firebolt',
        name: 'Book of Firebolt',
        glyph: '?',
        teaches: 'mend',
      );

      // assert
      expect(one, isNot(other));
    });
  });
}
