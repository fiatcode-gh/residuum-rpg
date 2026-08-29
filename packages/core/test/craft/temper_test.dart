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

const _mail = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 4,
  heavy: true,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _book = BaseItem(
  id: 'book-of-firebolt',
  name: 'Book of Firebolt',
  glyph: '?',
  teaches: 'firebolt',
);

Item _item(String id, BaseItem base, {int temper = 0}) =>
    Item(id: id, base: base, rarity: Rarity.common).tempered(temper);

Profile _hero({
  List<Item> inventory = const [],
  Equipment equipment = const {},
  int blacksmith = 0,
  int gold = 1000,
  Map<MaterialId, int> materials = const {MaterialId.ingot: 9},
}) => Profile(
  hero: hero(const Position(0, 0)),
  worldSeed: 5,
  inventory: inventory,
  equipment: equipment,
  gold: gold,
  materials: materials,
  skills: {
    ...untrainedSkills,
    SkillId.blacksmith: SkillState(level: blacksmith),
  },
);

void main() {
  group('the forge ceiling', () {
    test('goes to three, and the ceiling is the point', () {
      // arrange
      // act
      const ceiling = maxTemper;

      // assert - tempering is the only thing that improves an item the world
      // already handed over, so it has to stop short of making the item
      // irrelevant: crafting serves loot and never competes with it
      expect(ceiling, 3);
    });

    test('there is a price for every tier and no tier without one', () {
      // act
      final prices = temperPrices;

      // assert
      expect(prices, hasLength(maxTemper));
    });

    test('every tier costs more than the one below it', () {
      // act
      final gates = [for (final price in temperPrices) price.blacksmith];
      final ingots = [for (final price in temperPrices) price.ingots];
      final gold = [for (final price in temperPrices) price.gold];

      // assert - a later tier is a real investment and the first is nearly
      // free, which is xpToNext's shape applied to a purse
      expect(gates, [0, 5, 10]);
      expect(ingots, [1, 2, 3]);
      expect(gold, [10, 25, 50]);
    });

    test('the first tier asks for no training at all', () {
      // act
      final first = temperPriceFrom(0);

      // assert - a hero who has never mined has to be able to buy the tier that
      // teaches them what tempering is for
      expect(first.blacksmith, 0);
    });
  });

  group('temperRefusal on what cannot be worked', () {
    test('refuses an item the hero is not holding', () {
      // arrange
      final profile = _hero(inventory: [_item('kit-1', _sword)]);

      // act
      final refusal = temperRefusal(profile, 'drop-9');

      // assert
      expect(refusal, 'you are not holding that');
    });

    test('refuses a potion, in the words the forge would say', () {
      // arrange
      final profile = _hero(inventory: [_item('kit-2', _potion)]);

      // act
      final refusal = temperRefusal(profile, 'kit-2');

      // assert
      expect(refusal, 'only steel takes a temper');
    });

    test('refuses a book for the same reason', () {
      // arrange
      final profile = _hero(inventory: [_item('kit-4', _book)]);

      // act
      final refusal = temperRefusal(profile, 'kit-4');

      // assert
      expect(refusal, 'only steel takes a temper');
    });

    test('refuses a piece already worked as far as it goes', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword, temper: maxTemper)],
        blacksmith: 100,
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, 'that is worked as far as it goes');
    });
  });

  group('temperRefusal on the gate', () {
    test('names the level the next tier needs', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword, temper: 1)],
        blacksmith: 4,
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert - the sentence says the number, so a dead row on the screen
      // tells the player what to go and do
      expect(refusal, 'that needs Blacksmith 5');
    });

    test('opens the moment the level arrives', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword, temper: 1)],
        blacksmith: 5,
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, isNull);
    });

    test('gates the third tier higher than the second', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword, temper: 2)],
        blacksmith: 9,
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, 'that needs Blacksmith 10');
    });
  });

  group('temperRefusal on what it costs', () {
    test('refuses when the hero is short of iron', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword, temper: 1)],
        blacksmith: 5,
        materials: const {MaterialId.ingot: 1},
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, 'that takes 2 ingots');
    });

    test('refuses when the purse is short', () {
      // arrange
      final profile = _hero(inventory: [_item('kit-1', _sword)], gold: 9);

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, 'you cannot afford that');
    });

    test('answers the iron before the purse', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword)],
        gold: 0,
        materials: const {},
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert - the order is the contract: iron is what the forge is for, and
      // a hero told to go and find gold when they also have no ore would go and
      // do the wrong thing
      expect(refusal, 'that takes 1 ingot');
    });

    test('says one ingot in the singular', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword)],
        materials: const {},
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, 'that takes 1 ingot');
    });
  });

  group('temperRefusal on what can be worked', () {
    test('allows a carried weapon', () {
      // arrange
      final profile = _hero(inventory: [_item('kit-1', _sword)]);

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, isNull);
    });

    test('allows a worn piece of armour', () {
      // arrange
      final profile = _hero(
        equipment: {EquipSlot.chest: _item('kit-5', _mail)},
      );

      // act
      final refusal = temperRefusal(profile, 'kit-5');

      // assert - the hero does not have to undress to visit the forge
      expect(refusal, isNull);
    });

    test('answers what the hero is holding before what it costs', () {
      // arrange
      final profile = _hero(gold: 0, materials: const {});

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert
      expect(refusal, 'you are not holding that');
    });
  });
}
