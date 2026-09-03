import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// The mint: an item entering the pack leaves its ground id behind and takes
/// `item-<n>` off the run's counter, once per item.
const _room = '''
#######
#.....#
#.....#
#######''';

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _here = Position(3, 1);

GameState _crawl(Map<Position, List<Item>> groundItems) =>
    crawl(ascii: _room, heroAt: _here, groundItems: groundItems);

void main() {
  group('the mint at pickup', () {
    test('the first pickup becomes item-1', () {
      // arrange
      final litter = Item(
        id: 'floor-3-2',
        base: _potion,
        rarity: Rarity.common,
      );
      final game = _crawl({
        _here: [litter],
      });

      // act
      final (after, events) = step(game, const PickUpAction());

      // assert
      expect(after.inventory.single.id, 'item-1');
      expect(events.whereType<ItemPickedUp>().single.item.id, 'item-1');
      expect(after.itemNumber, 2);
    });

    test('the next pickup becomes item-2, once per item', () {
      // arrange
      final first = Item(id: 'floor-3-1', base: _potion, rarity: Rarity.common);
      final second = Item(
        id: 'floor-3-2',
        base: _potion,
        rarity: Rarity.common,
      );
      final game = _crawl({
        _here: [first, second],
      });

      // act
      final (afterOne, one) = step(game, const PickUpAction());
      final (afterTwo, two) = step(afterOne, const PickUpAction());

      // assert
      expect(one.whereType<ItemPickedUp>().single.item.id, 'item-1');
      expect(two.whereType<ItemPickedUp>().single.item.id, 'item-2');
      expect(afterTwo.inventory.map((item) => item.id), ['item-1', 'item-2']);
      expect(afterTwo.itemNumber, 3, reason: 'once per item, not per tap');
    });

    test('the ground keeps its litter id on the tile', () {
      // arrange
      final left = Item(id: 'floor-3-2', base: _potion, rarity: Rarity.common);
      final taken = Item(id: 'floor-3-3', base: _potion, rarity: Rarity.common);
      final game = _crawl({
        _here: [left, taken],
      });

      // act
      final (after, _) = step(game, const PickUpAction());

      // assert
      expect(
        after.groundItems[_here]!.single.id,
        'floor-3-2',
        reason: 'floor content is byte-frozen; the ground never re-ids',
      );
    });
  });
}
