import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// The world seed and visit every pin below is a reading off.
const int _pinnedSeed = 4242;
const int _pinnedVisit = 1;

/// How deep each delve at the pin runs.
///
/// **Not five, and that is the point of the numbers.** A delve rolls its own
/// bottom from the world seed, the dungeon and the visit, and at this pin the
/// cave rolls six floors and the keep seven — so the bottom-floor goldens below
/// are readings off depth six and depth seven, and the boss stands on the rolled
/// floor rather than on the crypt's fifth. Asserted rather than assumed, so a
/// roll that moved would redden here and name itself instead of quietly
/// re-pointing four goldens at other floors.
const int _seaCaveDeepest = 6;
const int _ruinedKeepDeepest = 7;

/// The sea-cave's first floor, pasted from a real run.
///
/// **A whole floor rather than a checksum**, for the reason the crypt's
/// generator goldens are whole: a hash tells the reader a floor moved and
/// nothing about how, while a map a person can look at says whether a room
/// slid, a corridor turned, or the entire layout is somebody else's.
const String _seaCaveFirst =
    '########################\n'
    '###################....#\n'
    '###################....#\n'
    '############...........#\n'
    '####.............##....#\n'
    '####...#####.....####.##\n'
    '####...########.#####.##\n'
    '####...########.#####.##\n'
    '####...########.#####.##\n'
    '#####.########...##....#\n'
    '#####.########...##....#\n'
    '##......######...##..>.#\n'
    '##......###########....#\n'
    '##......###########....#\n'
    '##......################\n'
    '########################';

/// The sea-cave's bottom floor: depth six, no way down, eight rolled creatures
/// and the captain on the last spawn.
///
/// Thirty-four tiles by twenty-one, which is the size formula read at depth six
/// rather than at five — the floor a rolled bottom deeper than the crypt's
/// actually is.
const String _seaCaveBottom =
    '##################################\n'
    '#......###...####....##...###....#\n'
    '#...<..###...####....##..........#\n'
    '#....................##...###....#\n'
    '####.#####...####....###.#########\n'
    '####.#####..#######.####.#########\n'
    '####.#####..#######.####.#########\n'
    '####.####.....####...###.#########\n'
    '##....###.....####...###.#########\n'
    '##............####...##...########\n'
    '##....###.....####...##...###....#\n'
    '###.#####.....####...##..........#\n'
    '###.######.#######.#####.####....#\n'
    '###.######.#######.#####.######.##\n'
    '##...####...####....####.######.##\n'
    '##..........####....###....####.##\n'
    '##...####...####....###.........##\n'
    '##...###########...........##....#\n'
    '##...###########....#########....#\n'
    '################....#########....#\n'
    '##################################';

/// The keep's first floor.
const String _ruinedKeepFirst =
    '########################\n'
    '#########....#####.....#\n'
    '#########....#####.....#\n'
    '#....####..............#\n'
    '#....####....#####.....#\n'
    '#............#######.###\n'
    '#....####....#######.###\n'
    '#....####....#####....##\n'
    '####.####....#####....##\n'
    '####.#######.#####....##\n'
    '####.#######.#####..>.##\n'
    '#.......####.#####....##\n'
    '#.......##....####....##\n'
    '#.............####....##\n'
    '#.......##....##########\n'
    '########################';

/// The keep's bottom floor: depth seven, ten rolled creatures and the
/// castellan.
///
/// Thirty-six by twenty-two, the deepest floor this build can lay out. The camera
/// clamps to the map edge, so a floor wider than the screen is a floor the player
/// pans across rather than a floor that breaks.
const String _ruinedKeepBottom =
    '####################################\n'
    '#.....###################....##....#\n'
    '#..<..###......###.....##....##....#\n'
    '#..............###.....##..........#\n'
    '#########......###.....##....##....#\n'
    '############.#####.....####.#####.##\n'
    '############.#####.....####.#####.##\n'
    '############.#####.....##....###...#\n'
    '############.#####.....##....###...#\n'
    '#######.......######.####..........#\n'
    '##...##.......######.####....###...#\n'
    '##............######.######.#####.##\n'
    '##............######.######.#####.##\n'
    '##..###.......######.####....####.##\n'
    '##..###.......#####...###....##....#\n'
    '#...######.########...###....##....#\n'
    '#...######.########...###..........#\n'
    '#...#####.......###..........##....#\n'
    '#...#####.......###...###....##....#\n'
    '#########.............###....#######\n'
    '#########.......####################\n'
    '####################################';

/// Who stands where, in the order the spawn list rolled them.
///
/// The order is as load-bearing as the names: an id carries its place in the
/// list, so a reshuffled draw renames every creature on the floor while leaving
/// the count and the cast identical.
const List<String> _seaCaveFirstSpawns = [
  'crab-1@19,12',
  'crab-2@7,14',
  'crab-3@14,11',
  'crab-4@20,4',
  'crab-5@20,9',
  'crab-6@3,13',
];

const List<String> _seaCaveBottomSpawns = [
  'hag-1@3,15',
  'hag-2@19,15',
  'hag-3@20,1',
  'hag-4@20,10',
  'drowned-5@29,10',
  'drowned-6@23,15',
  'drowned-7@26,15',
  'drowned-8@16,19',
  'drowned-9@18,18',
  'boss-sea-cave@24,10',
];

const List<String> _ruinedKeepFirstSpawns = [
  'hound-1@20,8',
  'hound-2@18,13',
  'deserter-3@12,5',
  'deserter-4@10,1',
];

const List<String> _ruinedKeepBottomSpawns = [
  'man-at-arms-1@33,4',
  'man-at-arms-2@27,9',
  'deserter-3@9,14',
  'deserter-4@31,15',
  'man-at-arms-5@13,2',
  'man-at-arms-6@3,10',
  'man-at-arms-7@7,9',
  'man-at-arms-8@13,14',
  'man-at-arms-9@7,14',
  'man-at-arms-10@13,17',
  'boss-ruined-keep@28,1',
];

/// What is lying on each pinned floor, in reading order across the map.
///
/// **Pinned because a mutation found the hole.** Shifting a rarity weight in the
/// keep's bottom drop table left the whole suite green: the maps, the spawn
/// lists and the trophy all come off other tables, so the ordinary litter was
/// the one thing a themed drop table decides that nothing was reading. Each
/// entry is the item's id and its whole display name, so the base item, the tier
/// and the affixes all have to hold.
/// The sea-cave's shallowest floor can now lay nothing at all, and this is the
/// seed where it does. Its drop table's floor is zero — the tide leaves the
/// shore bare as often as not — so an empty list is the pin rather than a hole
/// in one.
const List<String> _seaCaveFirstLitter = [];

const List<String> _seaCaveBottomLitter = [
  'floor-6-1 Common Healing Potion',
  'trophy-sea-cave Epic Sturdy Reinforced Iron Greaves of Swiftness',
];

const List<String> _ruinedKeepFirstLitter = [
  'floor-1-2 Common Healing Potion',
  'floor-1-1 Fine War Axe of Embers',
];

const List<String> _ruinedKeepBottomLitter = [
  'trophy-ruined-keep Rare Greatsword of Fury of Embers',
  'floor-7-2 Fine Reinforced Mail Hauberk',
  'floor-7-1 Epic Reinforced Kite Shield of Vigour of Swiftness',
];

/// What the bosses are standing over, named in full.
///
/// The whole display name rather than the rarity alone, because a trophy is
/// item, tier and affixes together and any one of them moving is the loot
/// stream having moved.
///
/// **Both moved when the dungeons learned to drop books, and neither trophy
/// table was touched.** A trophy is rolled off the bottom floor's own stream
/// after that floor's litter, so a depth table that gives up one more kind of
/// thing hands the trophy roll a different number to work from. The promise
/// these pin — rare or better, on the deepest floor, every seed — is asserted
/// separately and still holds.
const String _seaCaveTrophy =
    'Epic Sturdy Reinforced Iron Greaves of Swiftness';
const String _ruinedKeepTrophy = 'Rare Greatsword of Fury of Embers';

Floor _pinnedFloor(ThemedDungeon dungeon, int depth) => themedFloor(
  dungeon,
  depth,
  worldSeed: _pinnedSeed,
  visit: _pinnedVisit,
  deepest: delveDepth(dungeon.node, _pinnedSeed, _pinnedVisit),
);

List<String> _spawnsOf(Floor floor) => [
  for (final monster in floor.monsters)
    '${monster.id}@${monster.position.x},${monster.position.y}',
];

/// Everything lying on [floor], read across the map a row at a time.
///
/// Sorted rather than taken in map order, because a `Map` keyed on positions
/// iterates in insertion order and that is the order the generator happened to
/// draw the tiles in — a pin resting on it would be pinning the draw twice.
List<String> _litterOn(Floor floor) {
  final tiles = floor.groundItems.entries.toList()
    ..sort(
      (one, other) => (one.key.y * 1000 + one.key.x).compareTo(
        other.key.y * 1000 + other.key.x,
      ),
    );
  return [
    for (final tile in tiles)
      for (final item in tile.value) '${item.id} ${item.displayName}',
  ];
}

String _trophyOn(Floor floor, NodeId node) => floor.groundItems.values
    .expand((lying) => lying)
    .firstWhere((item) => item.id == 'trophy-${node.value}')
    .displayName;

void main() {
  group('the sea-cave, pinned', () {
    test('lays out the first floor the pin was taken on', () {
      // act
      final floor = _pinnedFloor(theSeaCave, 1);

      // assert
      expect(floor.map.toAscii(), _seaCaveFirst);
      expect(floor.heroSpawn, const Position(5, 6));
      expect(floor.stairsDown, const Position(21, 11));
      expect(_spawnsOf(floor), _seaCaveFirstSpawns);
      expect(_litterOn(floor), _seaCaveFirstLitter);
    });

    test('lays out the bottom floor, captain and trophy included', () {
      // act
      final floor = _pinnedFloor(theSeaCave, _seaCaveDeepest);

      // assert
      expect(delveDepth(seaCave, _pinnedSeed, _pinnedVisit), _seaCaveDeepest);
      expect(floor.map.toAscii(), _seaCaveBottom);
      expect(floor.heroSpawn, const Position(4, 2));
      expect(floor.stairsDown, isNull);
      expect(_spawnsOf(floor), _seaCaveBottomSpawns);
      expect(_trophyOn(floor, seaCave), _seaCaveTrophy);
      expect(_litterOn(floor), _seaCaveBottomLitter);
    });
  });

  group('the ruined keep, pinned', () {
    test('lays out the first floor the pin was taken on', () {
      // act
      final floor = _pinnedFloor(theRuinedKeep, 1);

      // assert
      expect(floor.map.toAscii(), _ruinedKeepFirst);
      expect(floor.heroSpawn, const Position(3, 5));
      expect(floor.stairsDown, const Position(20, 10));
      expect(_spawnsOf(floor), _ruinedKeepFirstSpawns);
      expect(_litterOn(floor), _ruinedKeepFirstLitter);
    });

    test('lays out the bottom floor, castellan and trophy included', () {
      // act
      final floor = _pinnedFloor(theRuinedKeep, _ruinedKeepDeepest);

      // assert
      expect(
        delveDepth(ruinedKeep, _pinnedSeed, _pinnedVisit),
        _ruinedKeepDeepest,
      );
      expect(floor.map.toAscii(), _ruinedKeepBottom);
      expect(floor.heroSpawn, const Position(3, 2));
      expect(floor.stairsDown, isNull);
      expect(_spawnsOf(floor), _ruinedKeepBottomSpawns);
      expect(_trophyOn(floor, ruinedKeep), _ruinedKeepTrophy);
      expect(_litterOn(floor), _ruinedKeepBottomLitter);
    });
  });

  group('the three dungeons at one seed', () {
    test('are three different first floors', () {
      // act
      final maps = {
        _seaCaveFirst,
        _ruinedKeepFirst,
        startDungeonRunAt(
          cryptNode,
          newProfile(worldSeed: _pinnedSeed),
        ).map.toAscii(),
      };

      // assert
      expect(maps, hasLength(3));
    });
  });
}
