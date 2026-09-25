import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_exits.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/place_actions.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

const _roadArena = '''
.......
.......
.......''';

const _heroAt = Position(1, 1);

Actor _hero({int hp = 20}) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: _heroAt,
  hp: hp,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

/// A dungeon floor at [_heroAt], staged with whatever the place actions
/// under test need — loot, a node, stairs, a live monster — and nothing
/// else.
GameState _dungeon({
  List<Actor> monsters = const [],
  Map<Position, GatherKind> nodes = const {},
  Map<Position, List<Item>> groundItems = const {},
  List<Item> inventory = const [],
  Position? stairsUp,
  Position? stairsDown,
  int depth = 1,
  bool isGameOver = false,
}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(hp: isGameOver ? 0 : 20),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    nodes: nodes,
    groundItems: groundItems,
    inventory: inventory,
    stairsUp: stairsUp,
    stairsDown: stairsDown,
    depth: depth,
    isGameOver: isGameOver,
  );
}

/// The outermost-ring road, live or cleared depending on [monsters].
GameState _road({List<Actor> monsters = const []}) {
  final map = FloorMap.parse(_roadArena);
  const heroAt = Position(0, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: 20,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isEncounter: true,
  );
}

Actor _ghoul(Position at) => Actor(
  id: 'ghoul-1',
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: 10,
  energy: actThreshold,
);

GameViewState _view(GameState game) => GameViewState(game: game, log: const []);

List<Item> _oneSword() => const [
  Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
];

void main() {
  group('placeVerbsFor', () {
    test('a bare floor offers nothing', () {
      expect(placeVerbsFor(_view(_dungeon())), isEmpty);
    });

    test(
      'pick up appears exactly when the pack has room for loot underfoot',
      () {
        final withRoom = _dungeon(groundItems: {_heroAt: _oneSword()});
        final noLoot = _dungeon();
        expect(placeVerbsFor(_view(withRoom)), contains(PlaceVerb.pickUp));
        expect(placeVerbsFor(_view(noLoot)), isNot(contains(PlaceVerb.pickUp)));
      },
    );

    test('a full pack withholds pick up but keeps the fact', () {
      final full = _dungeon(
        groundItems: {_heroAt: _oneSword()},
        inventory: List.generate(
          inventoryCap,
          (index) =>
              Item(id: 'held-$index', base: ironSword, rarity: Rarity.common),
        ),
      );
      expect(placeVerbsFor(_view(full)), isNot(contains(PlaceVerb.pickUp)));
      expect(placeFacts(_view(full)), contains('Here: Common Iron Sword'));
    });

    test('gather appears over an ore vein and over an herb patch alike', () {
      final ore = _dungeon(nodes: {_heroAt: GatherKind.oreVein});
      final herb = _dungeon(nodes: {_heroAt: GatherKind.herbPatch});
      final bare = _dungeon();
      expect(placeVerbsFor(_view(ore)), contains(PlaceVerb.gather));
      expect(placeVerbsFor(_view(herb)), contains(PlaceVerb.gather));
      expect(placeVerbsFor(_view(bare)), isNot(contains(PlaceVerb.gather)));
    });

    test('move on appears exactly when the road fight is cleared', () {
      final cleared = _road();
      final live = _road(monsters: [_ghoul(const Position(5, 1))]);
      expect(placeVerbsFor(_view(cleared)), contains(PlaceVerb.moveOn));
      expect(placeVerbsFor(_view(live)), isNot(contains(PlaceVerb.moveOn)));
    });

    test('ascend appears exactly on the stairs up', () {
      final onStairs = _dungeon(stairsUp: _heroAt);
      final elsewhere = _dungeon(stairsUp: const Position(3, 2));
      expect(placeVerbsFor(_view(onStairs)), contains(PlaceVerb.ascend));
      expect(
        placeVerbsFor(_view(elsewhere)),
        isNot(contains(PlaceVerb.ascend)),
      );
    });

    test('descend appears exactly on the stairs down', () {
      final onStairs = _dungeon(stairsDown: _heroAt);
      final elsewhere = _dungeon(stairsDown: const Position(3, 2));
      expect(placeVerbsFor(_view(onStairs)), contains(PlaceVerb.descend));
      expect(
        placeVerbsFor(_view(elsewhere)),
        isNot(contains(PlaceVerb.descend)),
      );
    });

    test('leave appears wherever ascend or descend does, and the bottom stairs '
        'carry its own note', () {
      final mid = _dungeon(stairsUp: _heroAt, depth: 2);
      final bottom = _dungeon(stairsUp: _heroAt, depth: deepestDepth);
      expect(placeVerbsFor(_view(mid)), contains(PlaceVerb.leave));
      expect(placeFacts(_view(mid)), isNot(contains(doneAtTheBottom)));
      expect(placeVerbsFor(_view(bottom)), contains(PlaceVerb.leave));
      expect(placeFacts(_view(bottom)), contains(doneAtTheBottom));
    });

    test('game over offers nothing, whatever else is underfoot', () {
      final over = _dungeon(
        stairsUp: _heroAt,
        nodes: {_heroAt: GatherKind.oreVein},
        groundItems: {_heroAt: _oneSword()},
        isGameOver: true,
      );
      expect(placeVerbsFor(_view(over)), isEmpty);
    });
  });

  group('placeFacts', () {
    test('names the node underfoot by its marking and word', () {
      final herb = _dungeon(nodes: {_heroAt: GatherKind.herbPatch});
      expect(
        placeFacts(_view(herb)),
        contains(
          'Underfoot: ${GatherKind.herbPatch.marking} '
          '${GatherKind.herbPatch.word}',
        ),
      );
    });

    test(
      'names the single item alone and the newest of several with a count',
      () {
        final one = _dungeon(groundItems: {_heroAt: _oneSword()});
        final two = _dungeon(
          groundItems: {
            _heroAt: const [
              Item(id: 'floor-1', base: ironSword, rarity: Rarity.common),
              Item(id: 'floor-2', base: maul, rarity: Rarity.common),
            ],
          },
        );
        expect(placeFacts(_view(one)), ['Here: Common Iron Sword']);
        expect(placeFacts(_view(two)), ['Here: Common Maul and 1 more']);
      },
    );

    test('a bare floor names nothing', () {
      expect(placeFacts(_view(_dungeon())), isEmpty);
    });
  });
}
