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

const _hauberk = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 3,
  heavy: true,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _weaponAffixes = [
  Affix(id: 'keen', affixName: 'Keen', isPrefix: true, attackMax: 2),
  Affix(id: 'vicious', affixName: 'Vicious', isPrefix: true, attackMin: 2),
  Affix(id: 'of-embers', affixName: 'of Embers', isPrefix: false, attackMin: 1),
  Affix(id: 'of-fury', affixName: 'of Fury', isPrefix: false, speed: 1),
];

const _armourAffixes = [
  Affix(id: 'sturdy', affixName: 'Sturdy', isPrefix: true, armor: 1),
  Affix(id: 'reinforced', affixName: 'Reinforced', isPrefix: true, armor: 2),
  Affix(id: 'of-vigour', affixName: 'of Vigour', isPrefix: false, maxHp: 4),
  Affix(
    id: 'of-swiftness',
    affixName: 'of Swiftness',
    isPrefix: false,
    speed: 2,
  ),
];

DropTable _table({
  List<Weighted<BaseItem>>? items,
  List<Weighted<Rarity>>? rarities,
}) => DropTable(
  items: items ?? const [Weighted(_sword, 1)],
  rarities: rarities ?? const [Weighted(Rarity.common, 1)],
  weaponAffixes: _weaponAffixes,
  armourAffixes: _armourAffixes,
  minFloorItems: 2,
  maxFloorItems: 4,
);

void main() {
  group('rollDrop', () {
    test('takes its base item and tier from the table', () {
      // arrange
      final table = _table();

      // act
      final item = rollDrop(table, Rng(1), 'drop-1');

      // assert
      expect(item.id, 'drop-1');
      expect(item.base, _sword);
      expect(item.rarity, Rarity.common);
      expect(item.affixes, isEmpty);
    });

    test('rolls exactly as many affixes as the tier defines', () {
      // arrange
      final table = _table(rarities: const [Weighted(Rarity.epic, 1)]);

      // act
      final item = rollDrop(table, Rng(3), 'drop-2');

      // assert
      expect(item.affixes, hasLength(Rarity.epic.affixCount));
    });

    test('never rolls the same affix twice onto one item', () {
      // arrange
      final table = _table(rarities: const [Weighted(Rarity.legendary, 1)]);

      // act
      final ids = [
        for (var seed = 0; seed < 40; seed++)
          rollDrop(
            table,
            Rng(seed),
            'drop-$seed',
          ).affixes.map((affix) => affix.id).toList(),
      ];

      // assert
      expect(
        ids,
        everyElement(
          predicate<List<String>>((list) => list.toSet().length == list.length),
        ),
      );
    });

    test('draws weapon affixes for a weapon and armour affixes for armour', () {
      // arrange
      final weaponTable = _table(
        items: const [Weighted(_sword, 1)],
        rarities: const [Weighted(Rarity.legendary, 1)],
      );
      final armourTable = _table(
        items: const [Weighted(_hauberk, 1)],
        rarities: const [Weighted(Rarity.legendary, 1)],
      );

      // act
      final onWeapon = rollDrop(weaponTable, Rng(7), 'drop-3').affixes;
      final onArmour = rollDrop(armourTable, Rng(7), 'drop-4').affixes;

      // assert
      expect(onWeapon.toSet(), _weaponAffixes.toSet());
      expect(onArmour.toSet(), _armourAffixes.toSet());
    });

    test(
      'a potion is always common, because an affix on it would do nothing',
      () {
        // arrange
        final table = _table(
          items: const [Weighted(_potion, 1)],
          rarities: const [Weighted(Rarity.epic, 1)],
        );

        // act
        final item = rollDrop(table, Rng(5), 'drop-5');

        // assert
        expect(item.rarity, Rarity.common);
        expect(item.affixes, isEmpty);
      },
    );

    test('the same seed rolls the same item', () {
      // arrange
      final table = _table(
        items: const [Weighted(_sword, 1), Weighted(_hauberk, 1)],
        rarities: const [Weighted(Rarity.common, 1), Weighted(Rarity.rare, 1)],
      );

      // act
      final one = rollDrop(table, Rng(42), 'drop-6');
      final other = rollDrop(table, Rng(42), 'drop-6');

      // assert
      expect(one, other);
    });

    test('weight zero is never drawn', () {
      // arrange
      final table = _table(
        items: const [Weighted(_sword, 1), Weighted(_hauberk, 0)],
      );

      // act
      final bases = [
        for (var seed = 0; seed < 50; seed++)
          rollDrop(table, Rng(seed), 'drop-$seed').base,
      ];

      // assert
      expect(bases, everyElement(_sword));
    });
  });

  group('rollFloorItemCount', () {
    test('stays inside the table bounds', () {
      // arrange
      final table = _table();

      // act
      final counts = [
        for (var seed = 0; seed < 50; seed++)
          rollFloorItemCount(table, Rng(seed)),
      ];

      // assert
      expect(counts, everyElement(inInclusiveRange(2, 4)));
    });
  });

  group('a consumable is forced to Common', () {
    const book = BaseItem(
      id: 'book-of-firebolt',
      name: 'Book of Firebolt',
      glyph: '?',
      teaches: 'firebolt',
    );

    DropTable tableOf(BaseItem only) => _table(
      items: [Weighted(only, 1)],
      rarities: const [Weighted(Rarity.epic, 1)],
    );

    test('a spell book rolls Common off a table that says Epic', () {
      // arrange
      final table = tableOf(book);

      // act
      final rolled = rollDrop(table, Rng(1), 'drop-1');

      // assert - the potion's argument, extended: an affixed book would be a
      // bonus on a thing that is gone the moment it is used, and its tier word
      // would lie about what the table gave up
      expect(rolled.rarity, Rarity.common);
      expect(rolled.affixes, isEmpty);
    });

    test('a book costs the table exactly one roll, as a potion does', () {
      // arrange
      final bookRng = Rng(9);
      final potionRng = Rng(9);

      // act
      rollDrop(tableOf(book), bookRng, 'drop-1');
      rollDrop(tableOf(_potion), potionRng, 'drop-1');

      // assert - both stop after the base-item draw, so a table holding one
      // does not advance the stream differently from a table holding the other
      expect(bookRng.state, potionRng.state);
    });
  });
}
