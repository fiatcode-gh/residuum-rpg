import 'package:residuum_core/core.dart';
import 'package:test/test.dart';


/// What duplicate ids do at the wear door today, pinned before m3-itemids
/// changes it.
///
/// The refusal reads the first match (`_find`), the rebuild removes every
/// match. Both lines are pinned here on a hand-built duplicate-id pack; the
/// unit flips the rebuild to first-match-only and leaves the refusal alone.
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
  group('characterization: wearRefusal reads the first match', () {
    test('the first twin answers, whatever the second would say', () {
      // arrange
      final pack = [_twin(_potion), _twin(_helmet)];

      // act
      final refusal = wearRefusal(_loadout(), pack, 'drop-1');

      // assert
      expect(
        refusal,
        'Healing Potion is not worn',
        reason: 'current behaviour: the refusal names the first match',
      );
    });
  });

  group('characterization: wear removes every match', () {
    test('both twins leave the pack, one goes on', () {
      // arrange
      final pack = [_twin(_helmet), _twin(_helmet)];

      // act
      final worn = wear(const {}, pack, 'drop-1');

      // assert
      expect(
        _held(worn.inventory, 'drop-1'),
        0,
        reason: 'current behaviour: one wear takes every match',
      );
      expect(worn.equipment[EquipSlot.head], isNotNull);
    });
  });
}
