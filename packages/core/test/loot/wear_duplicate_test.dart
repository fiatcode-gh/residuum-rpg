import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// What a duplicate id does at the wear door, after the m3-itemids flip.
///
/// The refusal always read the first match (`_find`) and stays untouched —
/// that pin was true before the flip and stays true after it. The rebuild was
/// characterized against unmodified `a567c19` as remove-ALL, then flipped with
/// the change; the pre-flip red is on the record.
const _helmet = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

Item _twin(BaseItem base) =>
    Item(id: 'drop-1', base: base, rarity: Rarity.common);

Loadout _loadout({Equipment equipment = const {}}) =>
    Loadout(equipment: equipment, skills: untrainedSkills);

int _held(List<Item> items, String id) =>
    items.where((item) => item.id == id).length;

void main() {
  group('wearRefusal reads the first match', () {
    test('the first twin answers, whatever the second would say', () {
      // arrange
      final pack = [_twin(_potion), _twin(_helmet)];

      // act
      final refusal = wearRefusal(_loadout(), pack, 'drop-1');

      // assert
      expect(
        refusal,
        'Healing Potion is not worn',
        reason: 'the first match answers, as before the flip',
      );
    });
  });

  group('wear takes exactly one match', () {
    test('one twin goes on, the sibling survives carried', () {
      // arrange
      final pack = [_twin(_helmet), _twin(_helmet)];

      // act
      final worn = wear(const {}, pack, 'drop-1');

      // assert
      expect(_held(worn.inventory, 'drop-1'), 1);
      expect(worn.equipment[EquipSlot.head], isNotNull);
    });
  });
}
