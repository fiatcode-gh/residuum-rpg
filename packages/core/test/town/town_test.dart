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

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _maul = BaseItem(
  id: 'maul',
  name: 'Maul',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.two,
  attackMin: 7,
  attackMax: 11,
);

const _shield = BaseItem(
  id: 'kite-shield',
  name: 'Kite Shield',
  glyph: '[',
  slot: EquipSlot.offHand,
  armor: 2,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

Item _item(String id) => Item(id: id, base: _cap, rarity: Rarity.common);

Item _gear(String id, BaseItem base, {List<Affix> affixes = const []}) => Item(
  id: id,
  base: base,
  rarity: Rarity.values[affixes.length],
  affixes: affixes,
);

List<Item> _filler(int count) => [
  for (var index = 0; index < count; index++) _item('kit-fill-$index'),
];

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

  group('equipItem', () {
    test('wears a carried piece and empties it out of the pack', () {
      // arrange
      final sword = _gear('kit-1', _sword);
      final profile = _townie(inventory: [sword]);

      // act
      final (after, refusal) = equipItem(profile, 'kit-1');

      // assert
      expect(after.equipment[EquipSlot.mainHand], sword);
      expect(after.inventory, isEmpty);
      expect(refusal, isNull);
    });

    test('refuses what the hero is not carrying and changes nothing', () {
      // arrange
      final profile = _townie(inventory: [_gear('kit-1', _sword)]);

      // act
      final (after, refusal) = equipItem(profile, 'kit-2');

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'you are not carrying that');
    });

    test('refuses a piece that is not worn at all', () {
      // arrange
      final profile = _townie(inventory: [_gear('kit-1', _potion)]);

      // act
      final (after, refusal) = equipItem(profile, 'kit-1');

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'Healing Potion is not worn');
    });

    test('refuses a shield while both hands are on the weapon', () {
      // arrange
      final profile = _townie(
        inventory: [_gear('kit-1', _shield)],
        equipment: {EquipSlot.mainHand: _gear('kit-0', _maul)},
      );

      // act
      final (after, refusal) = equipItem(profile, 'kit-1');

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'both hands are on the weapon');
    });

    test('displaces what held the slot back into the pack', () {
      // arrange
      final held = _gear('kit-0', _sword);
      final better = _gear('kit-1', _sword, affixes: [_vigour]);
      final profile = _townie(
        inventory: [better],
        equipment: {EquipSlot.mainHand: held},
      );

      // act
      final (after, _) = equipItem(profile, 'kit-1');

      // assert
      expect(after.equipment[EquipSlot.mainHand], better);
      expect(after.inventory, [held]);
    });

    test('mirrors the dungeon and refuses a displacement past the cap', () {
      // arrange
      final maul = _gear('kit-2', _maul);
      final profile = _townie(
        inventory: [maul, ..._filler(inventoryCap - 1)],
        equipment: {
          EquipSlot.mainHand: _gear('kit-0', _sword),
          EquipSlot.offHand: _gear('kit-1', _shield),
        },
      );

      // act
      final (after, refusal) = equipItem(profile, 'kit-2');

      // assert
      expect(after, profile);
      expect(
        refusal?.reason,
        'your pack is too full for what that would '
        'displace',
      );
    });

    test('brings hit points inside the ceiling the new loadout allows', () {
      // arrange
      final profile = _townie(
        hp: 26,
        inventory: [_gear('kit-1', _cap)],
        equipment: {
          EquipSlot.head: _gear('kit-0', _cap, affixes: [_vigour]),
        },
      );

      // act
      final (after, _) = equipItem(profile, 'kit-1');

      // assert
      expect(after.maxHp, 20);
      expect(after.hero.hp, 20);
    });

    test('leaves hit points alone when the ceiling rises', () {
      // arrange
      final profile = _townie(
        hp: 14,
        inventory: [
          _gear('kit-1', _cap, affixes: [_vigour]),
        ],
      );

      // act
      final (after, _) = equipItem(profile, 'kit-1');

      // assert
      expect(after.maxHp, 26);
      expect(after.hero.hp, 14);
    });
  });

  group('unequipItem', () {
    test('takes the piece off and stows it in the pack', () {
      // arrange
      final sword = _gear('kit-1', _sword);
      final profile = _townie(equipment: {EquipSlot.mainHand: sword});

      // act
      final (after, refusal) = unequipItem(profile, EquipSlot.mainHand);

      // assert
      expect(after.equipment, isEmpty);
      expect(after.inventory, [sword]);
      expect(refusal, isNull);
    });

    test('refuses an empty slot and changes nothing', () {
      // arrange
      final profile = _townie();

      // act
      final (after, refusal) = unequipItem(profile, EquipSlot.head);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'nothing is on your head');
    });

    test('refuses a full pack rather than dropping the gear', () {
      // arrange
      final profile = _townie(
        inventory: _filler(inventoryCap),
        equipment: {EquipSlot.mainHand: _gear('kit-1', _sword)},
      );

      // act
      final (after, refusal) = unequipItem(profile, EquipSlot.mainHand);

      // assert
      expect(after, profile);
      expect(refusal?.reason, 'your hands are too full to stow it');
    });

    test('brings hit points down with the max-hp gear it took off', () {
      // arrange
      final profile = _townie(
        hp: 26,
        equipment: {
          EquipSlot.head: _gear('kit-1', _cap, affixes: [_vigour]),
        },
      );

      // act
      final (after, _) = unequipItem(profile, EquipSlot.head);

      // assert
      expect(after.hero.hp, 20);
    });

    test('leaves a wounded hero where it was', () {
      // arrange
      final profile = _townie(
        hp: 9,
        equipment: {
          EquipSlot.head: _gear('kit-1', _cap, affixes: [_vigour]),
        },
      );

      // act
      final (after, _) = unequipItem(profile, EquipSlot.head);

      // assert
      expect(after.hero.hp, 9);
    });

    test('leaves the purse and the vault untouched', () {
      // arrange
      final profile = _townie(
        gold: 40,
        bankedGold: 15,
        bank: [_item('vault-1')],
        equipment: {EquipSlot.mainHand: _gear('kit-1', _sword)},
      );

      // act
      final (after, _) = unequipItem(profile, EquipSlot.mainHand);

      // assert
      expect((after.gold, after.bankedGold), (40, 15));
      expect(after.bank.single.id, 'vault-1');
    });
  });
}
