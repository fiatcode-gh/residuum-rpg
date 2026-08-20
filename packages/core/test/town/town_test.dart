import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _cap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 6,
);

Item _item(String id) => Item(id: id, base: _cap, rarity: Rarity.common);

Profile _townie({
  int hp = 20,
  int gold = 0,
  int bankedGold = 0,
  List<Item> inventory = const [],
  List<Item> bank = const [],
  Equipment equipment = const {},
}) => Profile(
  hero: hero(const Position(0, 0), hp: hp),
  worldSeed: 1,
  gold: gold,
  bankedGold: bankedGold,
  inventory: inventory,
  bank: bank,
  equipment: equipment,
);

void main() {
  group('buyItem', () {
    test('takes the gold and hands over the goods', () {
      // arrange
      final profile = _townie(gold: 30);

      // act
      final (after, refusal) = buyItem(profile, _item('market-1'), 12);

      // assert
      expect((after.gold, after.inventory.single.id), (18, 'market-1'));
      expect(refusal, isNull);
    });

    test('refuses when the purse is short and changes nothing', () {
      // arrange
      final profile = _townie(gold: 5);

      // act
      final (after, refusal) = buyItem(profile, _item('market-1'), 12);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you cannot afford that');
    });

    test('affords a price the purse matches exactly', () {
      // arrange
      final profile = _townie(gold: 12);

      // act
      final (after, refusal) = buyItem(profile, _item('market-1'), 12);

      // assert
      expect(after.gold, 0);
      expect(refusal, isNull);
    });

    test('refuses when the pack is full', () {
      // arrange
      final profile = _townie(
        gold: 500,
        inventory: [for (var n = 0; n < inventoryCap; n++) _item('held-$n')],
      );

      // act
      final (after, refusal) = buyItem(profile, _item('market-1'), 1);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you cannot carry any more');
    });
  });

  group('sellItem', () {
    test('the item leaves the pack and the gold arrives', () {
      // arrange
      final profile = _townie(gold: 4, inventory: [_item('held-1')]);

      // act
      final (after, refusal) = sellItem(profile, 'held-1', 9);

      // assert
      expect(after.gold, 13);
      expect(after.inventory, isEmpty);
      expect(refusal, isNull);
    });

    test('refuses to sell what the hero is not carrying', () {
      // arrange
      final profile = _townie(inventory: [_item('held-1')]);

      // act
      final (after, refusal) = sellItem(profile, 'held-2', 9);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you are not carrying that');
    });

    test('sells one of two alike and keeps the other', () {
      // arrange
      final profile = _townie(inventory: [_item('held-1'), _item('held-2')]);

      // act
      final (after, _) = sellItem(profile, 'held-1', 9);

      // assert
      expect(after.inventory.map((item) => item.id), ['held-2']);
    });

    test('never reaches into the vault for something to sell', () {
      // arrange
      final profile = _townie(bank: [_item('vault-1')]);

      // act
      final (after, refusal) = sellItem(profile, 'vault-1', 9);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you are not carrying that');
    });
  });

  group('restAtInn', () {
    test('heals to the ceiling the gear allows and takes the fee', () {
      // arrange
      final profile = _townie(hp: 6, gold: 20);

      // act
      final (after, refusal) = restAtInn(profile, 12);

      // assert
      expect((after.hero.hp, after.gold), (20, 8));
      expect(refusal, isNull);
    });

    test('heals above the base ceiling when the gear says so', () {
      // arrange
      final profile = _townie(
        hp: 6,
        gold: 20,
        equipment: {
          EquipSlot.head: const Item(
            id: 'worn-1',
            base: _cap,
            rarity: Rarity.fine,
            affixes: [_vigour],
          ),
        },
      );

      // act
      final (after, _) = restAtInn(profile, 12);

      // assert
      expect(after.hero.hp, 26);
    });

    test('refuses when the purse is short', () {
      // arrange
      final profile = _townie(hp: 6, gold: 3);

      // act
      final (after, refusal) = restAtInn(profile, 12);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you cannot afford a bed');
    });

    test('refuses a bed to a hero with nothing wrong with it', () {
      // arrange
      final profile = _townie(hp: 20, gold: 20);

      // act
      final (after, refusal) = restAtInn(profile, 12);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'there is nothing wrong with you');
    });
  });

  group('the bank', () {
    test('depositItem moves the item out of the pack and into the vault', () {
      // arrange
      final profile = _townie(inventory: [_item('held-1')]);

      // act
      final (after, refusal) = depositItem(profile, 'held-1');

      // assert
      expect(after.inventory, isEmpty);
      expect(after.bank.single.id, 'held-1');
      expect(refusal, isNull);
    });

    test('the vault has no cap', () {
      // arrange
      final profile = _townie(
        inventory: [_item('held-1')],
        bank: [for (var n = 0; n < inventoryCap * 2; n++) _item('vault-$n')],
      );

      // act
      final (after, refusal) = depositItem(profile, 'held-1');

      // assert
      expect(after.bank.length, inventoryCap * 2 + 1);
      expect(refusal, isNull);
    });

    test('withdrawItem brings it back, and the pack cap applies', () {
      // arrange
      final profile = _townie(
        inventory: [for (var n = 0; n < inventoryCap; n++) _item('held-$n')],
        bank: [_item('vault-1')],
      );

      // act
      final (after, refusal) = withdrawItem(profile, 'vault-1');

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you cannot carry any more');
    });

    test('an item survives a deposit and a withdrawal unchanged', () {
      // arrange
      final profile = _townie(inventory: [_item('held-1')]);

      // act
      final (banked, _) = depositItem(profile, 'held-1');
      final (back, _) = withdrawItem(banked, 'held-1');

      // assert
      expect(back, profile);
    });

    test('refuses to withdraw what the vault does not hold', () {
      // arrange
      final profile = _townie(bank: [_item('vault-1')]);

      // act
      final (after, refusal) = withdrawItem(profile, 'vault-2');

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'the vault does not hold that');
    });

    test('refuses to deposit what the hero is not carrying', () {
      // arrange
      final profile = _townie();

      // act
      final (after, refusal) = depositItem(profile, 'held-1');

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you are not carrying that');
    });

    test('gold goes in and comes back out', () {
      // arrange
      final profile = _townie(gold: 50, bankedGold: 5);

      // act
      final (paid, _) = depositGold(profile, 30);
      final (drawn, _) = withdrawGold(paid, 10);

      // assert
      expect((paid.gold, paid.bankedGold), (20, 35));
      expect((drawn.gold, drawn.bankedGold), (30, 25));
    });

    test('refuses to bank gold the hero does not carry', () {
      // arrange
      final profile = _townie(gold: 5);

      // act
      final (after, refusal) = depositGold(profile, 30);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you are not carrying that much');
    });

    test('refuses to withdraw gold the vault does not hold', () {
      // arrange
      final profile = _townie(bankedGold: 5);

      // act
      final (after, refusal) = withdrawGold(profile, 30);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'the vault does not hold that much');
    });

    test('refuses a gold amount that is not a positive number', () {
      // arrange
      final profile = _townie(gold: 50, bankedGold: 50);

      // act
      final (afterIn, refusedIn) = depositGold(profile, 0);
      final (afterOut, refusedOut) = withdrawGold(profile, -5);

      // assert
      expect((afterIn, afterOut), (profile, profile));
      expect(
        (refusedIn?.reason, refusedOut?.reason),
        ('that is not an amount', 'that is not an amount'),
      );
    });

    test('a transaction never touches what it was not asked about', () {
      // arrange
      final profile = _townie(
        gold: 50,
        bankedGold: 20,
        inventory: [_item('held-1')],
        bank: [_item('vault-1')],
        equipment: {EquipSlot.head: _item('worn-1')},
      );

      // act
      final (after, _) = depositGold(profile, 10);

      // assert
      expect(after.inventory.single.id, 'held-1');
      expect(after.bank.single.id, 'vault-1');
      expect(after.equipment[EquipSlot.head]!.id, 'worn-1');
      expect(after.hero.hp, profile.hero.hp);
    });
  });
}
