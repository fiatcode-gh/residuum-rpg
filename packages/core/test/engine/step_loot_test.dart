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

const _here = Position(3, 1);

void main() {
  group('PickUpAction', () {
    test('takes the newest item on the tile and carries it', () {
      // arrange
      final older = _item('floor-1-1', _sword);
      final newer = _item('floor-1-2', _shield);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        groundItems: {
          _here: [older, newer],
        },
      );

      // act
      final (after, events) = step(game, const PickUpAction());

      // assert
      expect(after.inventory, [newer]);
      expect(after.itemsAt(_here), [older]);
      expect(events, contains(ItemPickedUp(item: newer)));
    });

    test('leaves the tile with no entry once the last item is gone', () {
      // arrange
      final only = _item('floor-1-1', _sword);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        groundItems: {
          _here: [only],
        },
      );

      // act
      final (after, _) = step(game, const PickUpAction());

      // assert
      expect(after.groundItems, isEmpty);
    });

    test('is refused with nothing underfoot, and costs no turn', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, events) = step(game, const PickUpAction());

      // assert
      expect(events.single, isA<ActionRefused>());
      expect(after.monsters.single.position, const Position(1, 1));
      expect(after.hero.energy, game.hero.energy);
    });

    test('is refused when the inventory is already full', () {
      // arrange
      final carried = [
        for (var index = 0; index < inventoryCap; index++)
          _item('kit-$index', _potion),
      ];
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: carried,
        groundItems: {
          _here: [_item('floor-1-1', _sword)],
        },
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, events) = step(game, const PickUpAction());

      // assert
      expect(events, [const InventoryFull()]);
      expect(after.inventory, hasLength(inventoryCap));
      expect(after.itemsAt(_here), hasLength(1));
      expect(after.monsters.single.position, const Position(1, 1));
    });

    test('one per turn, so a littered tile takes several turns to clear', () {
      // arrange
      var game = crawl(
        ascii: _room,
        heroAt: _here,
        groundItems: {
          _here: [
            _item('floor-1-1', _sword),
            _item('floor-1-2', _shield),
            _item('floor-1-3', _potion),
          ],
        },
      );

      // act
      final carried = <int>[];
      for (var turn = 0; turn < 3; turn++) {
        final (after, _) = step(game, const PickUpAction());
        game = after;
        carried.add(game.inventory.length);
      }

      // assert
      expect(carried, [1, 2, 3]);
    });

    test('costs the turn, so monsters act', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        groundItems: {
          _here: [_item('floor-1-1', _sword)],
        },
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, _) = step(game, const PickUpAction());

      // assert
      expect(after.monsters.single.position, isNot(const Position(1, 1)));
    });
  });

  group('EquipAction', () {
    test('moves a carried item into its slot', () {
      // arrange
      final sword = _item('kit-1', _sword);
      final game = crawl(ascii: _room, heroAt: _here, inventory: [sword]);

      // act
      final (after, events) = step(game, const EquipAction('kit-1'));

      // assert
      expect(after.equipment[EquipSlot.mainHand], sword);
      expect(after.inventory, isEmpty);
      expect(
        events,
        contains(ItemEquipped(item: sword, slot: EquipSlot.mainHand)),
      );
    });

    test('displaced gear returns to the inventory', () {
      // arrange
      final worn = _item('kit-1', _sword);
      final better = _item('floor-1-1', _sword);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: [better],
        equipment: {EquipSlot.mainHand: worn},
      );

      // act
      final (after, events) = step(game, const EquipAction('floor-1-1'));

      // assert
      expect(after.equipment[EquipSlot.mainHand], better);
      expect(after.inventory, [worn]);
      expect(
        events,
        contains(ItemUnequipped(item: worn, slot: EquipSlot.mainHand)),
      );
    });

    test('the effective attack changes with the weapon', () {
      // arrange
      final sword = _item('kit-1', _sword);
      final game = crawl(ascii: _room, heroAt: _here, inventory: [sword]);

      // act
      final (after, _) = step(game, const EquipAction('kit-1'));

      // assert
      expect(heroAttack(game.hero, game.loadout), (4, 4));
      expect(heroAttack(after.hero, after.loadout), (7, 9));
    });

    test('a two-hander displaces the shield', () {
      // arrange
      final shield = _item('kit-1', _shield);
      final maul = _item('floor-1-1', _maul);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: [maul],
        equipment: {EquipSlot.offHand: shield},
      );

      // act
      final (after, events) = step(game, const EquipAction('floor-1-1'));

      // assert
      expect(after.equipment[EquipSlot.mainHand], maul);
      expect(after.equipment.containsKey(EquipSlot.offHand), isFalse);
      expect(after.inventory, [shield]);
      expect(
        events,
        containsAllInOrder([
          ItemUnequipped(item: shield, slot: EquipSlot.offHand),
          ItemEquipped(item: maul, slot: EquipSlot.mainHand),
        ]),
      );
    });

    test(
      'a shield is refused while a two-hander is held, and costs no turn',
      () {
        // arrange
        final shield = _item('kit-1', _shield);
        final maul = _item('kit-2', _maul);
        final game = crawl(
          ascii: _room,
          heroAt: _here,
          inventory: [shield],
          equipment: {EquipSlot.mainHand: maul},
          monsters: [ghoul('ghoul-1', const Position(1, 1))],
        );

        // act
        final (after, events) = step(game, const EquipAction('kit-1'));

        // assert
        expect(events.single, isA<ActionRefused>());
        expect(after.equipment.containsKey(EquipSlot.offHand), isFalse);
        expect(after.inventory, [shield]);
        expect(after.monsters.single.position, const Position(1, 1));
      },
    );

    test('a one-handed weapon leaves the shield alone', () {
      // arrange
      final shield = _item('kit-1', _shield);
      final sword = _item('kit-2', _sword);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: [sword],
        equipment: {EquipSlot.offHand: shield},
      );

      // act
      final (after, _) = step(game, const EquipAction('kit-2'));

      // assert
      expect(after.equipment[EquipSlot.offHand], shield);
      expect(after.equipment[EquipSlot.mainHand], sword);
    });

    test('a potion is refused, because it belongs in no slot', () {
      // arrange
      final potion = _item('kit-1', _potion);
      final game = crawl(ascii: _room, heroAt: _here, inventory: [potion]);

      // act
      final (after, events) = step(game, const EquipAction('kit-1'));

      // assert
      expect(events.single, isA<ActionRefused>());
      expect(after.equipment, isEmpty);
    });

    test('an id nothing carried answers to is refused', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: _here);

      // act
      final (after, events) = step(game, const EquipAction('nothing'));

      // assert
      expect(events.single, isA<ActionRefused>());
      expect(after.inventory, isEmpty);
    });
  });

  group('UnequipAction', () {
    test('returns the piece to the inventory', () {
      // arrange
      final sword = _item('kit-1', _sword);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        equipment: {EquipSlot.mainHand: sword},
      );

      // act
      final (after, events) = step(
        game,
        const UnequipAction(EquipSlot.mainHand),
      );

      // assert
      expect(after.equipment, isEmpty);
      expect(after.inventory, [sword]);
      expect(
        events,
        contains(ItemUnequipped(item: sword, slot: EquipSlot.mainHand)),
      );
    });

    test('an empty slot is refused, and costs no turn', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, events) = step(game, const UnequipAction(EquipSlot.head));

      // assert
      expect(events.single, isA<ActionRefused>());
      expect(after.monsters.single.position, const Position(1, 1));
    });

    test('a full inventory refuses the unequip rather than dropping gear', () {
      // arrange
      final carried = [
        for (var index = 0; index < inventoryCap; index++)
          _item('kit-$index', _potion),
      ];
      final worn = _item('worn-1', _sword);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: carried,
        equipment: {EquipSlot.mainHand: worn},
      );

      // act
      final (after, events) = step(
        game,
        const UnequipAction(EquipSlot.mainHand),
      );

      // assert
      expect(events.single, isA<ActionRefused>());
      expect(after.equipment[EquipSlot.mainHand], worn);
    });

    test('clamps hit points down to the new maximum', () {
      // arrange
      final vigorous = _item('worn-1', _hauberk, affixes: const [_vigour]);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 24,
        equipment: {EquipSlot.chest: vigorous},
      );

      // act
      final (after, _) = step(game, const UnequipAction(EquipSlot.chest));

      // assert
      expect(heroMaxHp(game.hero, game.loadout), 24);
      expect(after.hero.hp, 20);
    });

    test('never kills the hero by undressing', () {
      // arrange
      final vigorous = _item('worn-1', _hauberk, affixes: const [_vigour]);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 1,
        equipment: {EquipSlot.chest: vigorous},
      );

      // act
      final (after, _) = step(game, const UnequipAction(EquipSlot.chest));

      // assert
      expect(after.hero.hp, greaterThanOrEqualTo(1));
      expect(after.isGameOver, isFalse);
    });

    test('leaves hit points alone when the maximum did not move', () {
      // arrange
      final plain = _item('worn-1', _hauberk);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 12,
        equipment: {EquipSlot.chest: plain},
      );

      // act
      final (after, _) = step(game, const UnequipAction(EquipSlot.chest));

      // assert
      expect(after.hero.hp, 12);
    });
  });

  group('DrinkAction', () {
    test('heals and consumes the potion', () {
      // arrange
      final potion = _item('kit-1', _potion);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 5,
        inventory: [potion],
      );

      // act
      final (after, events) = step(game, const DrinkAction('kit-1'));

      // assert
      expect(after.hero.hp, 13);
      expect(after.inventory, isEmpty);
      expect(events, contains(PotionDrunk(item: potion, healed: 8)));
    });

    test('heals only what is missing, never past the maximum', () {
      // arrange
      final potion = _item('kit-1', _potion);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 17,
        inventory: [potion],
      );

      // act
      final (after, events) = step(game, const DrinkAction('kit-1'));

      // assert
      expect(after.hero.hp, 20);
      expect(events, contains(PotionDrunk(item: potion, healed: 3)));
    });

    test('heals up to the geared maximum, not the hero\'s own', () {
      // arrange
      final potion = _item('kit-1', _potion);
      final vigorous = _item('worn-1', _hauberk, affixes: const [_vigour]);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        heroHp: 20,
        inventory: [potion],
        equipment: {EquipSlot.chest: vigorous},
      );

      // act
      final (after, events) = step(game, const DrinkAction('kit-1'));

      // assert
      expect(after.hero.hp, 24);
      expect(events, contains(PotionDrunk(item: potion, healed: 4)));
    });

    test('at full health it is wasted, not refused', () {
      // arrange
      final potion = _item('kit-1', _potion);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: [potion],
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, events) = step(game, const DrinkAction('kit-1'));

      // assert
      expect(events, contains(PotionDrunk(item: potion, healed: 0)));
      expect(after.inventory, isEmpty);
      expect(after.monsters.single.position, isNot(const Position(1, 1)));
    });

    test('drinking a sword is refused, and costs no turn', () {
      // arrange
      final sword = _item('kit-1', _sword);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: [sword],
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, events) = step(game, const DrinkAction('kit-1'));

      // assert
      expect(events.single, isA<ActionRefused>());
      expect(after.inventory, [sword]);
      expect(after.monsters.single.position, const Position(1, 1));
    });
  });

  group('DropAction', () {
    test('puts the item down on the hero\'s tile as the newest there', () {
      // arrange
      final older = _item('floor-1-1', _sword);
      final carried = _item('kit-1', _potion);
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        inventory: [carried],
        groundItems: {
          _here: [older],
        },
      );

      // act
      final (after, events) = step(game, const DropAction('kit-1'));

      // assert
      expect(after.itemsAt(_here), [older, carried]);
      expect(after.inventory, isEmpty);
      expect(events, contains(ItemDropped(item: carried, at: _here)));
    });

    test('an id nothing carried answers to is refused, and costs no turn', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, events) = step(game, const DropAction('nothing'));

      // assert
      expect(events.single, isA<ActionRefused>());
      expect(after.monsters.single.position, const Position(1, 1));
    });

    test('dropping then picking up is a round trip', () {
      // arrange
      final carried = _item('kit-1', _sword);
      final game = crawl(ascii: _room, heroAt: _here, inventory: [carried]);

      // act
      final (dropped, _) = step(game, const DropAction('kit-1'));
      final (again, _) = step(dropped, const PickUpAction());

      // assert
      expect(again.inventory, [carried]);
      expect(again.groundItems, isEmpty);
    });
  });

  group('a refused action changes nothing at all', () {
    test('the state that comes back is the state that went in', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: _here,
        monsters: [ghoul('ghoul-1', const Position(1, 1))],
      );

      // act
      final (after, _) = step(game, const UnequipAction(EquipSlot.feet));

      // assert
      expect(identical(after, game), isTrue);
    });
  });
}
