import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// The counter ride: `itemNumber` crosses every door inventory crosses, on the
/// road dartdoc's rule — a field the profile gains later goes on the list the
/// day it lands.
const _room = '''
##########
#........#
#........#
##########''';

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _cap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

Item _item(String id) => Item(id: id, base: _potion, rarity: Rarity.common);

Dungeon _flat() =>
    (visit) =>
        (depth) => Floor(
          map: FloorMap.parse(_room),
          heroSpawn: const Position(1, 1),
          monsters: const [],
          stairsDown: depth >= deepestDepth ? null : const Position(8, 1),
          stairsUp: depth <= 1 ? null : const Position(1, 1),
        );

Profile _townie({
  int visit = 0,
  int itemNumber = 1,
  List<Item> inventory = const [],
  Equipment equipment = const {},
}) => Profile(
  hero: hero(const Position(0, 0)),
  worldSeed: 5,
  visit: visit,
  itemNumber: itemNumber,
  inventory: inventory,
  equipment: equipment,
);

void main() {
  group('the counter ride', () {
    test('startRun seeds the run from the profile', () {
      // arrange
      final profile = _townie(itemNumber: 4);

      // act
      final run = startRun(profile, dungeon: _flat());

      // assert
      expect(run.itemNumber, 4);
    });

    test('endRun, alive, writes the run counter home', () {
      // arrange
      final entered = _townie(itemNumber: 1);
      final run = startRun(entered, dungeon: _flat()).copyWith(itemNumber: 6);

      // act
      final home = endRun(entered, run, died: false);

      // assert
      expect(home.itemNumber, 6);
    });

    test(
      'endRun, dead, still writes the counter home with the pack stripped',
      () {
        // arrange
        final entered = _townie(itemNumber: 1, inventory: [_item('item-2')]);
        final run = startRun(entered, dungeon: _flat()).copyWith(itemNumber: 6);

        // act
        final home = endRun(entered, run, died: true);

        // assert
        expect(home.inventory, isEmpty);
        expect(home.itemNumber, 6);
      },
    );

    test('suspendRun copies the run counter onto the profile', () {
      // arrange
      final entered = _townie(itemNumber: 1);
      final run = startRun(entered, dungeon: _flat()).copyWith(itemNumber: 6);

      // act
      final camped = suspendRun(entered, run);

      // assert
      expect(camped.itemNumber, 6);
    });

    test('resumeRun takes the greater of the two counters', () {
      // arrange
      final camped = _townie(itemNumber: 9);
      final suspended = startRun(
        _townie(itemNumber: 1),
        dungeon: _flat(),
      ).copyWith(itemNumber: 6);

      // act
      final resumed = resumeRun(camped, suspended);

      // assert
      expect(resumed.itemNumber, 9);
    });

    test('resumeRun keeps the run counter when the profile trails', () {
      // arrange
      final camped = _townie(itemNumber: 1);
      final suspended = startRun(
        _townie(itemNumber: 1),
        dungeon: _flat(),
      ).copyWith(itemNumber: 6);

      // act
      final resumed = resumeRun(camped, suspended);

      // assert
      expect(resumed.itemNumber, 6);
    });
  });
}
