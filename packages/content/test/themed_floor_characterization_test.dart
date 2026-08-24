import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// The world seed and visit every pin below is a reading off.
const int _pinnedSeed = 4242;
const int _pinnedVisit = 1;

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

/// The sea-cave's bottom floor: no way down, seven rolled creatures and the
/// captain on the last spawn.
const String _seaCaveBottom =
    '################################\n'
    '###################....#########\n'
    '##.....############....#########\n'
    '##.....############....#########\n'
    '##.....##..............####...##\n'
    '##..<..##....#####............##\n'
    '##...........#####.....####...##\n'
    '##.....##....#####.#############\n'
    '#########....#####.#############\n'
    '###########.######.#############\n'
    '###########.######.#############\n'
    '###########.####....##........##\n'
    '#########.....##..............##\n'
    '###....##.....##....##........##\n'
    '###....##.....########........##\n'
    '###....##.....########........##\n'
    '###...........########........##\n'
    '###....##.....########........##\n'
    '###....##.....########........##\n'
    '################################';

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

/// The keep's bottom floor: eight rolled creatures and the castellan.
const String _ruinedKeepBottom =
    '################################\n'
    '######################...##....#\n'
    '#############.....####...##....#\n'
    '#####...#####.....####...##....#\n'
    '#####.<.#####..................#\n'
    '#####...#####.....####...##....#\n'
    '#####.#######.....####...##....#\n'
    '#####.#######.....#####.########\n'
    '#####.#########..######.########\n'
    '#####.#########..#####...#######\n'
    '#####.#########..#####...##...##\n'
    '#####.#########..#####........##\n'
    '#####.#########..#####...##...##\n'
    '#........######..#####.######.##\n'
    '#........####......###.######.##\n'
    '#........####......##...#####.##\n'
    '#..................##...###....#\n'
    '#........####......##...###....#\n'
    '#........####......##...###....#\n'
    '################################';

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
];

const List<String> _seaCaveBottomSpawns = [
  'hag-1@24,15',
  'drowned-2@13,17',
  'hag-3@18,13',
  'hag-4@11,17',
  'hag-5@21,3',
  'hag-6@11,16',
  'hag-7@13,13',
  'boss-sea-cave@23,12',
];

const List<String> _ruinedKeepFirstSpawns = [
  'hound-1@20,8',
  'hound-2@18,13',
  'deserter-3@12,5',
  'deserter-4@10,1',
];

const List<String> _ruinedKeepBottomSpawns = [
  'man-at-arms-1@22,3',
  'deserter-2@23,5',
  'man-at-arms-3@17,4',
  'deserter-4@4,14',
  'man-at-arms-5@28,18',
  'deserter-6@23,11',
  'man-at-arms-7@28,6',
  'man-at-arms-8@2,15',
  'boss-ruined-keep@30,18',
];

/// What is lying on each pinned floor, in reading order across the map.
///
/// **Pinned because a mutation found the hole.** Shifting a rarity weight in the
/// keep's bottom drop table left the whole suite green: the maps, the spawn
/// lists and the trophy all come off other tables, so the ordinary litter was
/// the one thing a themed drop table decides that nothing was reading. Each
/// entry is the item's id and its whole display name, so the base item, the tier
/// and the affixes all have to hold.
const List<String> _seaCaveFirstLitter = [
  'floor-1-3 Common Leather Cap',
  'floor-1-1 Rare Reinforced Leather Boots of Swiftness',
  'floor-1-2 Common Leather Cap',
];

const List<String> _seaCaveBottomLitter = [
  'floor-5-2 Fine Reinforced Leather Cap',
  'floor-5-3 Common Iron Greaves',
  'floor-5-4 Common Iron Greaves',
  'floor-5-1 Fine Iron Helm of Vigour',
  'trophy-sea-cave Rare Keen War Axe of Fury',
];

const List<String> _ruinedKeepFirstLitter = [
  'floor-1-2 Fine War Axe of Embers',
  'floor-1-6 Common Iron Greaves',
  'floor-1-5 Common Healing Potion',
  'floor-1-4 Fine Sturdy Leather Jerkin',
  'floor-1-3 Rare Sturdy Iron Helm of Swiftness',
  'floor-1-1 Fine Iron Gauntlets of Vigour',
];

const List<String> _ruinedKeepBottomLitter = [
  'floor-5-1 Rare Sturdy Mail Hauberk of Swiftness',
  'floor-5-5 Rare Sturdy Reinforced Iron Greaves',
  'floor-5-2 Epic Sturdy Reinforced Mail Hauberk of Vigour',
  'floor-5-3 Common Healing Potion',
  'floor-5-4 Epic Reinforced Sturdy Iron Helm of Vigour',
  'trophy-ruined-keep Epic Reinforced Sturdy Mail Hauberk of Swiftness',
];

/// What the bosses are standing over, named in full.
///
/// The whole display name rather than the rarity alone, because a trophy is
/// item, tier and affixes together and any one of them moving is the loot
/// stream having moved.
const String _seaCaveTrophy = 'Rare Keen War Axe of Fury';
const String _ruinedKeepTrophy =
    'Epic Reinforced Sturdy Mail Hauberk of Swiftness';

Floor _pinnedFloor(ThemedDungeon dungeon, int depth) =>
    themedFloor(dungeon, depth, worldSeed: _pinnedSeed, visit: _pinnedVisit);

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
      final floor = _pinnedFloor(theSeaCave, deepestDepth);

      // assert
      expect(floor.map.toAscii(), _seaCaveBottom);
      expect(floor.heroSpawn, const Position(4, 5));
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
      final floor = _pinnedFloor(theRuinedKeep, deepestDepth);

      // assert
      expect(floor.map.toAscii(), _ruinedKeepBottom);
      expect(floor.heroSpawn, const Position(6, 4));
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
