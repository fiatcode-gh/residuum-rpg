import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// The world seed this pin is taken at.
///
/// Named rather than inlined, because every literal below is a reading off
/// this one number and a reader has to be able to see that.
const int _pinnedSeed = 4242;

/// The first floor the town's door lays out, pasted from a real run.
///
/// **This pin outlives the door it was taken through.** `startDungeonRun` is
/// deleted this unit and `startDungeonRunAt(cryptNode, …)` takes its place;
/// the whole point of writing the floor down first is that the successor has
/// to reproduce it character for character, so the crypt's path is proven
/// unmoved rather than asserted to be.
const String _firstFloor =
    '########################\n'
    '#.......##.......#######\n'
    '#.......##.......###...#\n'
    '#......................#\n'
    '#.......##.......###...#\n'
    '####.######.############\n'
    '####.######.############\n'
    '####.######.#####....###\n'
    '#......####.#####..>.###\n'
    '#......###...####....###\n'
    '#......###..........####\n'
    '##########...###########\n'
    '########################\n'
    '########################\n'
    '########################\n'
    '########################';

/// Who is standing on it, in the order the spawn list rolled them.
///
/// The order is as load-bearing as the names: monster ids carry their place in
/// the list, and a reshuffled draw would rename every creature on the floor
/// while leaving the count and the cast identical.
const List<String> _openingMonsters = ['rat-1', 'wolf-2', 'rat-3'];

void main() {
  group('the town door into the crypt', () {
    test('lays out the pinned first floor', () {
      // arrange
      final profile = newProfile(worldSeed: _pinnedSeed);

      // act
      final run = startDungeonRunAt(cryptNode, profile);

      // assert
      expect(run.map.toAscii(), _firstFloor);
      expect(run.hero.position, const Position(4, 3));
      expect(run.stairsDown, const Position(19, 8));
    });

    test('stands the pinned monsters on it, in the pinned order', () {
      // arrange
      final profile = newProfile(worldSeed: _pinnedSeed);

      // act
      final run = startDungeonRunAt(cryptNode, profile);

      // assert
      expect(run.monsters.map((monster) => monster.id), _openingMonsters);
      expect(run.monsters.map((monster) => monster.position), const [
        Position(21, 3),
        Position(16, 3),
        Position(13, 2),
      ]);
    });

    test('opens both streams and the visit at the pinned numbers', () {
      // arrange
      final profile = newProfile(worldSeed: _pinnedSeed);

      // act
      final run = startDungeonRunAt(cryptNode, profile);

      // assert
      expect(run.visit, 1);
      expect(run.depth, 1);
      expect(run.rng.state, -220922450277408979);
      expect(run.lootRng.state, 2851109081598412326);
      expect(run.groundItems, hasLength(4));
      expect(run.dropTables, dropTables);
    });
  });
}
