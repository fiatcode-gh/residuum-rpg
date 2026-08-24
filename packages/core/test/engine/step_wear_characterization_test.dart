import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
#######
#.....#
#.....#
#######''';

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
  heavy: true,
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

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 4,
);

Item _item(String id, BaseItem base, {List<Affix> affixes = const []}) => Item(
  id: id,
  base: base,
  rarity: Rarity.values[affixes.length],
  affixes: affixes,
);

List<Item> _filler(int count) => [
  for (var index = 0; index < count; index++) _item('kit-fill-$index', _potion),
];

const _here = Position(3, 1);

void main() {
  group('EquipAction displacement against the pack cap', () {
    test('a full pack refuses the swap that would displace two pieces', () {
      // arrange
      final maul = _item('kit-maul', _maul);
      final sword = _item('kit-sword', _sword);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        equipment: {
          EquipSlot.mainHand: sword,
          EquipSlot.offHand: _item('kit-shield', _shield),
        },
        inventory: [maul, ..._filler(inventoryCap - 1)],
      );

      // act
      final (after, events) = step(game, const EquipAction('kit-maul'));

      // assert
      expect(after.equipment[EquipSlot.mainHand], sword);
      expect(after.inventory, hasLength(inventoryCap));
      expect(
        events.whereType<ActionRefused>().single.reason,
        'your pack is too full for what that would displace',
      );
    });

    test('a pack one short of the cap ends exactly at the cap', () {
      // arrange
      final maul = _item('kit-maul', _maul);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        equipment: {
          EquipSlot.mainHand: _item('kit-sword', _sword),
          EquipSlot.offHand: _item('kit-shield', _shield),
        },
        inventory: [maul, ..._filler(inventoryCap - 2)],
      );

      // act
      final (after, _) = step(game, const EquipAction('kit-maul'));

      // assert
      expect(after.inventory, hasLength(inventoryCap));
    });
  });

  group('EquipAction event order with two pieces displaced', () {
    test('announces the weapon, then the shield, then what went on', () {
      // arrange
      final sword = _item('kit-sword', _sword);
      final shield = _item('kit-shield', _shield);
      final maul = _item('kit-maul', _maul);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        equipment: {EquipSlot.mainHand: sword, EquipSlot.offHand: shield},
        inventory: [maul],
      );

      // act
      final (_, events) = step(game, const EquipAction('kit-maul'));

      // assert
      expect(
        events.where(
          (event) => event is ItemUnequipped || event is ItemEquipped,
        ),
        [
          ItemUnequipped(item: sword, slot: EquipSlot.mainHand),
          ItemUnequipped(item: shield, slot: EquipSlot.offHand),
          ItemEquipped(item: maul, slot: EquipSlot.mainHand),
        ],
      );
    });
  });

  group('EquipAction against the hit point ceiling', () {
    test('clamps hit points when a swap lowers the ceiling', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 24,
        equipment: {
          EquipSlot.chest: _item('kit-vigorous', _hauberk, affixes: [_vigour]),
        },
        inventory: [_item('kit-plain', _hauberk)],
      );

      // act
      final (after, _) = step(game, const EquipAction('kit-plain'));

      // assert
      expect(heroMaxHp(after.hero, after.loadout), 20);
      expect(after.hero.hp, 20);
    });

    test('clamps hit points when the same swap is done by taking off', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 24,
        equipment: {
          EquipSlot.chest: _item('kit-vigorous', _hauberk, affixes: [_vigour]),
        },
      );

      // act
      final (after, _) = step(game, const UnequipAction(EquipSlot.chest));

      // assert
      expect(after.hero.hp, 20);
    });
  });
}
