import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

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

Loadout _wearing(Equipment equipment) =>
    Loadout(equipment: equipment, skills: untrainedSkills);

List<Item> _filler(int count) => [
  for (var index = 0; index < count; index++) _item('kit-fill-$index', _potion),
];

void main() {
  group('wearRefusal', () {
    test('allows a carried piece into an empty slot', () {
      // arrange
      final sword = _item('kit-1', _sword);

      // act
      final refusal = wearRefusal(_wearing(const {}), [sword], 'kit-1');

      // assert
      expect(refusal, isNull);
    });

    test('refuses what the hero is not carrying', () {
      // arrange
      final sword = _item('kit-1', _sword);

      // act
      final refusal = wearRefusal(_wearing(const {}), [sword], 'kit-2');

      // assert
      expect(refusal, 'you are not carrying that');
    });

    test('refuses what is not worn at all, naming it', () {
      // arrange
      final potion = _item('kit-1', _potion);

      // act
      final refusal = wearRefusal(_wearing(const {}), [potion], 'kit-1');

      // assert
      expect(refusal, 'Healing Potion is not worn');
    });

    test('refuses a shield while both hands are on the weapon', () {
      // arrange
      final shield = _item('kit-1', _shield);
      final loadout = _wearing({EquipSlot.mainHand: _item('kit-0', _maul)});

      // act
      final refusal = wearRefusal(loadout, [shield], 'kit-1');

      // assert
      expect(refusal, 'both hands are on the weapon');
    });

    test('allows a two-hander while a shield is held, the other way round', () {
      // arrange
      final maul = _item('kit-1', _maul);
      final loadout = _wearing({EquipSlot.offHand: _item('kit-0', _shield)});

      // act
      final refusal = wearRefusal(loadout, [maul], 'kit-1');

      // assert
      expect(refusal, isNull);
    });
  });

  group('wear', () {
    test('puts the piece on and takes it out of the pack', () {
      // arrange
      final sword = _item('kit-1', _sword);

      // act
      final worn = wear(const {}, [sword], 'kit-1');

      // assert
      expect(worn.equipment, {EquipSlot.mainHand: sword});
      expect(worn.inventory, isEmpty);
      expect(worn.put, (sword, EquipSlot.mainHand));
      expect(worn.taken, isEmpty);
    });

    test('displaces what already held the slot into the pack', () {
      // arrange
      final held = _item('kit-0', _sword);
      final better = _item('kit-1', _sword, affixes: [_vigour]);

      // act
      final worn = wear({EquipSlot.mainHand: held}, [better], 'kit-1');

      // assert
      expect(worn.equipment, {EquipSlot.mainHand: better});
      expect(worn.inventory, [held]);
      expect(worn.taken, [(held, EquipSlot.mainHand)]);
    });

    test(
      'a two-hander displaces the weapon then the shield, in that order',
      () {
        // arrange
        final sword = _item('kit-0', _sword);
        final shield = _item('kit-1', _shield);
        final maul = _item('kit-2', _maul);

        // act
        final worn = wear(
          {EquipSlot.mainHand: sword, EquipSlot.offHand: shield},
          [maul],
          'kit-2',
        );

        // assert
        expect(worn.taken, [
          (sword, EquipSlot.mainHand),
          (shield, EquipSlot.offHand),
        ]);
        expect(worn.equipment, {EquipSlot.mainHand: maul});
      },
    );

    test('two displaced pieces fill a pack one short of the cap', () {
      // arrange
      final maul = _item('kit-2', _maul);
      final pack = [maul, ..._filler(inventoryCap - 2)];

      // act
      final worn = wear(
        {
          EquipSlot.mainHand: _item('kit-0', _sword),
          EquipSlot.offHand: _item('kit-1', _shield),
        },
        pack,
        'kit-2',
      );

      // assert
      expect(worn.inventory, hasLength(inventoryCap));
    });
  });

  test('refuses a full pack the displacement would push past the cap', () {
    // arrange
    final loadout = Loadout(
      equipment: {
        EquipSlot.mainHand: _item('kit-0', _sword),
        EquipSlot.offHand: _item('kit-1', _shield),
      },
      skills: const {},
    );
    final pack = [_item('kit-2', _maul), ..._filler(inventoryCap - 1)];

    // act
    final refusal = wearRefusal(loadout, pack, 'kit-2');

    // assert
    expect(refusal, 'your pack is too full for what that would displace');
  });

  test('allows a full pack the swap gives a slot back to', () {
    // arrange
    final loadout = Loadout(
      equipment: {EquipSlot.mainHand: _item('kit-0', _sword)},
      skills: const {},
    );
    final pack = [_item('kit-2', _maul), ..._filler(inventoryCap - 1)];

    // act
    final refusal = wearRefusal(loadout, pack, 'kit-2');

    // assert
    expect(refusal, isNull);
  });

  group('takeOffRefusal', () {
    test('allows an occupied slot with room in the pack', () {
      // arrange
      final equipment = {EquipSlot.mainHand: _item('kit-1', _sword)};

      // act
      final refusal = takeOffRefusal(equipment, const [], EquipSlot.mainHand);

      // assert
      expect(refusal, isNull);
    });

    test('refuses an empty slot, naming it', () {
      // act
      final refusal = takeOffRefusal(const {}, const [], EquipSlot.head);

      // assert
      expect(refusal, 'nothing is on your head');
    });

    test('refuses a pack with no room to stow the piece', () {
      // arrange
      final equipment = {EquipSlot.mainHand: _item('kit-1', _sword)};

      // act
      final refusal = takeOffRefusal(
        equipment,
        _filler(inventoryCap),
        EquipSlot.mainHand,
      );

      // assert
      expect(refusal, 'your hands are too full to stow it');
    });
  });

  group('takeOff', () {
    test('moves the piece to the end of the pack', () {
      // arrange
      final sword = _item('kit-1', _sword);
      final potion = _item('kit-2', _potion);

      // act
      final worn = takeOff(
        {EquipSlot.mainHand: sword},
        [potion],
        EquipSlot.mainHand,
      );

      // assert
      expect(worn.equipment, isEmpty);
      expect(worn.inventory, [potion, sword]);
      expect(worn.taken, [(sword, EquipSlot.mainHand)]);
      expect(worn.put, isNull);
    });

    test('leaves the other slots alone', () {
      // arrange
      final sword = _item('kit-1', _sword);
      final hauberk = _item('kit-2', _hauberk);

      // act
      final worn = takeOff(
        {EquipSlot.mainHand: sword, EquipSlot.chest: hauberk},
        const [],
        EquipSlot.mainHand,
      );

      // assert
      expect(worn.equipment, {EquipSlot.chest: hauberk});
    });
  });

  group('clampedToMaxHp', () {
    test('brings hit points down to the ceiling the gear allows', () {
      // arrange
      final wounded = hero(const Position(1, 1), hp: 24);

      // act
      final clamped = clampedToMaxHp(wounded, _wearing(const {}));

      // assert
      expect(clamped.hp, 20);
    });

    test('leaves hit points below the ceiling alone', () {
      // arrange
      final wounded = hero(const Position(1, 1), hp: 7);

      // act
      final clamped = clampedToMaxHp(wounded, _wearing(const {}));

      // assert
      expect(clamped.hp, 7);
    });

    test('never clamps the hero to death, whatever the ceiling says', () {
      // arrange
      final frail = Actor(
        id: 'hero',
        name: 'you',
        glyph: '@',
        position: const Position(1, 1),
        hp: 5,
        maxHp: 0,
        attackMin: 1,
        attackMax: 1,
        speed: 10,
        energy: actThreshold,
      );

      // act
      final clamped = clampedToMaxHp(frail, _wearing(const {}));

      // assert
      expect(clamped.hp, 1);
    });

    test('counts the affixes still worn towards the ceiling', () {
      // arrange
      final wounded = hero(const Position(1, 1), hp: 24);
      final loadout = _wearing({
        EquipSlot.chest: _item('kit-1', _hauberk, affixes: [_vigour]),
      });

      // act
      final clamped = clampedToMaxHp(wounded, loadout);

      // assert
      expect(clamped.hp, 24);
    });
  });
}
