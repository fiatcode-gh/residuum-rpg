import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/action_card_verbs.dart';
import 'package:residuum_app/game/crawl_exits.dart';
import 'package:residuum_app/game/game_bloc.dart';
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

/// A dungeon floor at [_heroAt], staged with whatever the action card
/// under test needs — loot, a node, stairs, a live monster — and nothing
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

GameState _roadInland({List<Actor> monsters = const []}) {
  final map = FloorMap.parse(_roadArena);
  const heroAt = Position(3, 1);
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
  group('cardVerbsFor', () {
    test('a bare floor offers nothing', () {
      expect(cardVerbsFor(_view(_dungeon())), isEmpty);
    });

    test(
      'pick up appears exactly when the pack has room for loot underfoot',
      () {
        final withRoom = _dungeon(groundItems: {_heroAt: _oneSword()});
        final noLoot = _dungeon();
        expect(cardVerbsFor(_view(withRoom)), contains(CardVerb.pickUp));
        expect(cardVerbsFor(_view(noLoot)), isNot(contains(CardVerb.pickUp)));
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
      expect(cardVerbsFor(_view(full)), isNot(contains(CardVerb.pickUp)));
      expect(placeFacts(_view(full)), contains('Here: Common Iron Sword'));
    });

    test('gather appears over an ore vein and over an herb patch alike', () {
      final ore = _dungeon(nodes: {_heroAt: GatherKind.oreVein});
      final herb = _dungeon(nodes: {_heroAt: GatherKind.herbPatch});
      final bare = _dungeon();
      expect(cardVerbsFor(_view(ore)), contains(CardVerb.gather));
      expect(cardVerbsFor(_view(herb)), contains(CardVerb.gather));
      expect(cardVerbsFor(_view(bare)), isNot(contains(CardVerb.gather)));
    });

    test('move on appears exactly when the road fight is cleared', () {
      final cleared = _road();
      final live = _road(monsters: [_ghoul(const Position(5, 1))]);
      expect(cardVerbsFor(_view(cleared)), contains(CardVerb.moveOn));
      expect(cardVerbsFor(_view(live)), isNot(contains(CardVerb.moveOn)));
    });

    test('ascend appears exactly on the stairs up', () {
      final onStairs = _dungeon(stairsUp: _heroAt);
      final elsewhere = _dungeon(stairsUp: const Position(3, 2));
      expect(cardVerbsFor(_view(onStairs)), contains(CardVerb.ascend));
      expect(cardVerbsFor(_view(elsewhere)), isNot(contains(CardVerb.ascend)));
    });

    test('descend appears exactly on the stairs down', () {
      final onStairs = _dungeon(stairsDown: _heroAt);
      final elsewhere = _dungeon(stairsDown: const Position(3, 2));
      expect(cardVerbsFor(_view(onStairs)), contains(CardVerb.descend));
      expect(cardVerbsFor(_view(elsewhere)), isNot(contains(CardVerb.descend)));
    });

    test('leave appears wherever ascend or descend does, and the bottom stairs '
        'carry its own note', () {
      final mid = _dungeon(stairsUp: _heroAt, depth: 2);
      final bottom = _dungeon(stairsUp: _heroAt, depth: deepestDepth);
      expect(cardVerbsFor(_view(mid)), contains(CardVerb.leave));
      expect(placeFacts(_view(mid)), isNot(contains(doneAtTheBottom)));
      expect(cardVerbsFor(_view(bottom)), contains(CardVerb.leave));
      expect(placeFacts(_view(bottom)), contains(doneAtTheBottom));
    });

    test('game over offers nothing, whatever else is underfoot', () {
      final over = _dungeon(
        stairsUp: _heroAt,
        nodes: {_heroAt: GatherKind.oreVein},
        groundItems: {_heroAt: _oneSword()},
        isGameOver: true,
      );
      expect(cardVerbsFor(_view(over)), isEmpty);
    });

    test('flee appears exactly when canFlee: yes at a road edge, no inland '
        'on the same road, no in a dungeon', () {
      final edge = _road(monsters: [_ghoul(const Position(5, 1))]);
      final inland = _roadInland(monsters: [_ghoul(const Position(5, 1))]);
      final dungeon = _dungeon();
      expect(cardVerbsFor(_view(edge)), contains(CardVerb.flee));
      expect(cardVerbsFor(_view(inland)), isNot(contains(CardVerb.flee)));
      expect(cardVerbsFor(_view(dungeon)), isNot(contains(CardVerb.flee)));
    });

    test('wait appears exactly when offersWait: Watched, battle, never while '
        'exploring or once the game is over', () {
      final watched = _dungeon(monsters: [_ghoul(const Position(4, 1))]);
      final battle = _dungeon(monsters: [_ghoul(const Position(2, 1))]);
      final exploring = _dungeon();
      final over = _dungeon(
        monsters: [_ghoul(const Position(2, 1))],
        isGameOver: true,
      );
      expect(_view(watched).offersWait, isTrue);
      expect(cardVerbsFor(_view(watched)), contains(CardVerb.wait));
      expect(_view(battle).isBattleOpen, isTrue);
      expect(cardVerbsFor(_view(battle)), contains(CardVerb.wait));
      expect(cardVerbsFor(_view(exploring)), isNot(contains(CardVerb.wait)));
      expect(cardVerbsFor(_view(over)), isNot(contains(CardVerb.wait)));
    });

    test(
      'a road edge with a distant monster in sight orders flee then wait',
      () {
        final state = _view(_road(monsters: [_ghoul(const Position(5, 1))]));
        expect(state.canFlee, isTrue);
        expect(state.offersWait, isTrue);
        expect(cardVerbsFor(state), [CardVerb.flee, CardVerb.wait]);
      },
    );

    test(
      'a landing with loot while Watched orders pick up first and wait last',
      () {
        final state = _view(
          _dungeon(
            groundItems: {_heroAt: _oneSword()},
            monsters: [_ghoul(const Position(4, 1))],
          ),
        );
        expect(state.offersWait, isTrue);
        final verbs = cardVerbsFor(state);
        expect(verbs.first, CardVerb.pickUp);
        expect(verbs.last, CardVerb.wait);
      },
    );
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

    test('a full pack on an item adds the cannot-carry sentence; one free '
        'slot leaves it out', () {
      final full = _dungeon(
        groundItems: {_heroAt: _oneSword()},
        inventory: List.generate(
          inventoryCap,
          (index) =>
              Item(id: 'held-$index', base: ironSword, rarity: Rarity.common),
        ),
      );
      final oneFree = _dungeon(
        groundItems: {_heroAt: _oneSword()},
        inventory: List.generate(
          inventoryCap - 1,
          (index) =>
              Item(id: 'held-$index', base: ironSword, rarity: Rarity.common),
        ),
      );
      expect(placeFacts(_view(full)), contains('You cannot carry any more.'));
      expect(
        placeFacts(_view(oneFree)),
        isNot(contains('You cannot carry any more.')),
      );
    });
  });
}
