import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// The road fight is a sixth door in everything but name: an ambush carries
/// the pack underground, and `endRun` carries it home. The counter rides both
/// ways with it — picked up inside the encounter, the item comes home
/// minted, and the next delve continues the count.
const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

Item _item(String id) => Item(id: id, base: _potion, rarity: Rarity.common);

void main() {
  group('the road fight carries the counter', () {
    test('an ambush seeds its counter from the profile', () {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(itemNumber: 4);

      // act
      final fight = startRoadEncounter(profile, day: 1);

      // assert
      expect(fight.itemNumber, 4);
    });

    test(
      'a pickup inside the encounter mints, and endRun carries both home',
      () {
        // arrange
        final profile = newProfile(worldSeed: 909);
        final fight = startRoadEncounter(profile, day: 1);
        final fought = fight.copyWith(
          groundItems: {
            ...fight.groundItems,
            fight.hero.position: [_item('drop-1')],
          },
        );

        // act
        final (after, _) = step(fought, const PickUpAction());
        final home = endRun(profile, after, died: false);

        // assert
        expect(
          home.inventory.where((item) => item.id == 'item-1'),
          hasLength(1),
        );
        expect(home.itemNumber, 2);
      },
    );
  });
}
