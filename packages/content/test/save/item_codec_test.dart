import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/item_codec.dart';
import 'package:residuum_content/src/save/save_json.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const Item _plainPotion = Item(
  id: 'kit-2',
  base: healingPotion,
  rarity: Rarity.common,
);

const Item _affixedAxe = Item(
  id: 'drop-3',
  base: warAxe,
  rarity: Rarity.rare,
  affixes: [keen, ofEmbers],
);

void main() {
  group('item codec', () {
    test('a plain item round-trips', () {
      // arrange
      const before = _plainPotion;

      // act
      final after = decodeItem(encodeItem(before));

      // assert
      expect(after, before);
    });

    test('an affixed item keeps its affixes in order', () {
      // arrange
      const before = _affixedAxe;

      // act
      final after = decodeItem(encodeItem(before));

      // assert
      expect(after, before);
      expect(after.affixes.map((affix) => affix.id), ['keen', 'of-embers']);
      expect(after.displayName, before.displayName);
    });

    test('an item is written as registry references, not copied stats', () {
      // arrange
      const before = _affixedAxe;

      // act
      final written = encodeItem(before);

      // assert
      expect(written, {
        'id': 'drop-3',
        'base': 'war-axe',
        'rarity': 'rare',
        'affixes': ['keen', 'of-embers'],
      });
    });

    test('an unknown base id is refused by name', () {
      // arrange
      final written = <String, Object?>{
        'id': 'drop-9',
        'base': 'mithril-sword',
        'rarity': 'rare',
        'affixes': <Object?>[],
      };

      // act
      void act() => decodeItem(written);

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('mithril-sword'),
          ),
        ),
      );
    });

    test('an unknown affix id is refused by name', () {
      // arrange
      final written = <String, Object?>{
        'id': 'drop-9',
        'base': 'war-axe',
        'rarity': 'fine',
        'affixes': <Object?>['of-frost'],
      };

      // act
      void act() => decodeItem(written);

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('of-frost'),
          ),
        ),
      );
    });

    test('an unknown rarity is refused by name', () {
      // arrange
      final written = <String, Object?>{
        'id': 'drop-9',
        'base': 'war-axe',
        'rarity': 'mythic',
        'affixes': <Object?>[],
      };

      // act
      void act() => decodeItem(written);

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('mythic'),
          ),
        ),
      );
    });

    test('an item that is not an object is refused', () {
      // arrange
      const written = 'war-axe';

      // act
      void act() => decodeItem(written);

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });

    test('a pack round-trips in the order it was carried', () {
      // arrange
      const pack = [_plainPotion, _affixedAxe, _plainPotion];

      // act
      final after = decodeItems({'inventory': encodeItems(pack)}, 'inventory');

      // assert
      expect(after, pack);
    });

    test('worn gear round-trips by slot', () {
      // arrange
      final worn = <EquipSlot, Item>{
        EquipSlot.mainHand: _affixedAxe,
        EquipSlot.feet: const Item(
          id: 'kit-9',
          base: leatherBoots,
          rarity: Rarity.common,
        ),
      };

      // act
      final after = decodeEquipment({
        'equipment': encodeEquipment(worn),
      }, 'equipment');

      // assert
      expect(after, worn);
    });

    test('an unknown slot is refused by name', () {
      // arrange
      final written = <String, Object?>{
        'equipment': <String, Object?>{'tail': <String, Object?>{}},
      };

      // act
      void act() => decodeEquipment(written, 'equipment');

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('tail'),
          ),
        ),
      );
    });

    test('training round-trips level and banked experience', () {
      // arrange
      const trained = <SkillId, SkillState>{
        SkillId.arms: SkillState(level: 7, xp: 3),
        SkillId.might: SkillState(),
        SkillId.bulwark: SkillState(level: 1),
        SkillId.fleetfoot: SkillState(xp: 4),
      };

      // act
      final after = decodeSkills({'skills': encodeSkills(trained)}, 'skills');

      // assert
      expect(after, trained);
    });

    test('an unknown skill is refused by name', () {
      // arrange
      final written = <String, Object?>{
        'skills': <String, Object?>{'archery': <String, Object?>{}},
      };

      // act
      void act() => decodeSkills(written, 'skills');

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('archery'),
          ),
        ),
      );
    });

    test('litter round-trips by tile, in a stable order', () {
      // arrange
      final litter = <Position, List<Item>>{
        const Position(5, 2): [_affixedAxe],
        const Position(1, 2): [_plainPotion, _affixedAxe],
      };

      // act
      final written = encodeGroundItems(litter);
      final after = decodeGroundItems({'groundItems': written}, 'groundItems');

      // assert
      expect(after, litter);
      expect(written.map((tile) => (tile! as Map<String, Object?>)['x']), [
        1,
        5,
      ]);
    });

    test('a littered tile that is not an object is refused', () {
      // arrange
      final written = <String, Object?>{
        'groundItems': <Object?>['3,4'],
      };

      // act
      void act() => decodeGroundItems(written, 'groundItems');

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });
  });
}
