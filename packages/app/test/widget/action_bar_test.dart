import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/action_bar.dart';
import 'package:residuum_app/game/action_card_verbs.dart';
import 'package:residuum_app/game/crawl_exits.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/event_messages.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// A room wide and tall enough that every orthogonal neighbour of the hero
/// at its centre is a floor cell.
const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _heroAt = Position(3, 2);

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

Floor _deeperFloor(int depth) => Floor(
  map: FloorMap.parse(_arena),
  heroSpawn: _heroAt,
  monsters: const [],
  stairsDown: null,
  stairsUp: const Position(1, 1),
);

/// A dungeon floor at [_heroAt], staged with whatever the bar under test
/// needs and nothing else.
GameState _dungeon({
  Map<Position, GatherKind> nodes = const {},
  Map<Position, List<Item>> groundItems = const {},
  List<Item> inventory = const [],
  List<Actor> monsters = const [],
  Position? stairsUp,
  Position? stairsDown,
  int depth = 1,
  Floor Function(int)? buildFloor,
}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: buildFloor ?? (depth) => throw StateError('no floor below'),
    nodes: nodes,
    groundItems: groundItems,
    inventory: inventory,
    stairsUp: stairsUp,
    stairsDown: stairsDown,
    depth: depth,
  );
}

List<Item> _oneSword() => const [
  Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
];

List<Item> _fullPack() => List.generate(
  inventoryCap,
  (index) => Item(id: 'held-$index', base: ironSword, rarity: Rarity.common),
);

Actor _ghoulAt(Position at) => Actor(
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

/// The outermost ring of a cleared road fight — nothing left to strike, so
/// `Move on` is the only verb.
GameState _clearedRoad() {
  final route = residuumWorld.routeBetween(stonebridge, cryptNode)!;
  final fight = startRoadEncounter(
    newProfile(worldSeed: 5),
    day: 4,
    road: route,
  );
  return fight.copyWith(monsters: const []);
}

const _roadArena = '''
.......
.......
.......''';

GameState _roadEdge({bool withMonster = false}) {
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
    monsters: withMonster ? [_ghoulAt(const Position(5, 1))] : const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isEncounter: true,
  );
}

/// The largest reachable fixture: loot, a gatherable node and the bottom
/// stairs share the hero's own tile while Watched — 3 fact lines (or 4 with
/// a full pack) and up to 5 buttons.
GameState _largestFixture({bool fullPack = false}) => _dungeon(
  stairsUp: _heroAt,
  depth: deepestDepth,
  nodes: {_heroAt: GatherKind.oreVein},
  groundItems: {_heroAt: _oneSword()},
  monsters: [_ghoulAt(const Position(6, 2))],
  inventory: fullPack ? _fullPack() : const [],
);

Future<GameBloc> _openCrawl(
  WidgetTester tester,
  GameState game, {
  NodeId? dungeon,
  TextScaler? textScaler,
}) async {
  await onTheTargetPhone(tester);
  await tester.pumpWidget(const SizedBox.shrink());
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final world = WorldBloc(world: newWhereabouts(), worldSeed: 5);
  final bloc = GameBloc(game: game, dungeon: dungeon, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  final app = MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: town),
                BlocProvider.value(value: world),
                BlocProvider.value(value: bloc),
              ],
              child: const GameScreen(palette: DungeonPalette.crypt),
            ),
          ),
        ),
        child: const Text('down'),
      ),
    ),
  );
  await tester.pumpWidget(
    textScaler == null
        ? app
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: app,
          ),
  );
  await tester.tap(find.text('down'));
  await tester.pumpAndSettle();
  return bloc;
}

/// No verb button ever sits inside the map slot — the bar is off the map.
void _expectNoVerbOnMap(WidgetTester tester) {
  for (final verb in CardVerb.values) {
    expect(
      find.descendant(
        of: find.byKey(dungeonSceneSlotKey),
        matching: find.byKey(ValueKey(verb.id)),
      ),
      findsNothing,
      reason: verb.id,
    );
  }
}

void main() {
  group('the action bar', () {
    testWidgets('nothing but the title and the quiet line, on a bare floor', (
      tester,
    ) async {
      await _openCrawl(tester, _dungeon());
      expect(find.byKey(actionBarKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('ACTIONS'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text(actionBarIdle),
        ),
        findsOneWidget,
      );
      _expectNoVerbOnMap(tester);
    });

    testWidgets('Pick up, over loot underfoot', (tester) async {
      await _openCrawl(tester, _dungeon(groundItems: {_heroAt: _oneSword()}));
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('ACTIONS'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('Pick up'),
        ),
        findsOneWidget,
      );
      _expectNoVerbOnMap(tester);
    });

    testWidgets('Mine, over an ore vein', (tester) async {
      await _openCrawl(tester, _dungeon(nodes: {_heroAt: GatherKind.oreVein}));
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('Mine'),
        ),
        findsOneWidget,
      );
      _expectNoVerbOnMap(tester);
    });

    testWidgets('Ascend and Leave, on the stairs up mid-floor', (tester) async {
      await _openCrawl(tester, _dungeon(stairsUp: _heroAt, depth: 2));
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('Ascend <'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('Leave'),
        ),
        findsOneWidget,
      );
      _expectNoVerbOnMap(tester);
    });

    testWidgets('Move on, when the road fight is cleared', (tester) async {
      await _openCrawl(tester, _clearedRoad());
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('Move on'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Finish and the bottom-floor note, on the bottom stairs', (
      tester,
    ) async {
      await _openCrawl(
        tester,
        _dungeon(stairsUp: _heroAt, depth: deepestDepth),
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text(doneControl),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text(doneAtTheBottom),
        ),
        findsOneWidget,
      );
    });

    testWidgets('doneAtTheBottom nowhere but the bottom stairs', (
      tester,
    ) async {
      await _openCrawl(tester, _dungeon(stairsUp: _heroAt, depth: 2));
      expect(find.text(doneAtTheBottom), findsNothing);
    });

    testWidgets('the Here fact without Pick up, with a full pack, and no '
        'quiet line', (tester) async {
      await _openCrawl(
        tester,
        _dungeon(groundItems: {_heroAt: _oneSword()}, inventory: _fullPack()),
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text('Pick up'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.textContaining('Here:'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.textContaining(inventoryFullSentence),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text(actionBarIdle),
        ),
        findsNothing,
      );
    });

    testWidgets('Wait alone while Watched, and no quiet line', (tester) async {
      await _openCrawl(
        tester,
        _dungeon(monsters: [_ghoulAt(const Position(6, 2))]),
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.byKey(const ValueKey('wait')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.byKey(const ValueKey('flee')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.text(actionBarIdle),
        ),
        findsNothing,
      );
      _expectNoVerbOnMap(tester);
    });

    testWidgets('Flee alone at a road edge with nothing in sight', (
      tester,
    ) async {
      await _openCrawl(tester, _roadEdge());
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.byKey(const ValueKey('flee')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.byKey(const ValueKey('wait')),
        ),
        findsNothing,
      );
    });

    testWidgets('Flee and Wait together at a road edge in sight', (
      tester,
    ) async {
      await _openCrawl(tester, _roadEdge(withMonster: true));
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.byKey(const ValueKey('flee')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.byKey(const ValueKey('wait')),
        ),
        findsOneWidget,
      );
    });
  });

  group('tapping a verb on the action bar', () {
    testWidgets('Pick up moves the loot into the pack', (tester) async {
      final bloc = await _openCrawl(
        tester,
        _dungeon(groundItems: {_heroAt: _oneSword()}),
      );

      await tester.tap(find.byKey(const ValueKey('pick-up')));
      await tester.pumpAndSettle();

      expect(bloc.state.game.inventory, hasLength(1));
      expect(bloc.state.itemsUnderfoot, isEmpty);
    });

    testWidgets('Descend changes the depth', (tester) async {
      final bloc = await _openCrawl(
        tester,
        _dungeon(stairsDown: _heroAt, buildFloor: _deeperFloor),
      );

      await tester.tap(find.byKey(const ValueKey('descend')));
      await tester.pumpAndSettle();

      expect(bloc.state.depth, 2);
    });

    testWidgets('Leave suspends the run and closes the crawl', (tester) async {
      await _openCrawl(
        tester,
        _dungeon(stairsUp: _heroAt, depth: 2),
        dungeon: cryptNode,
      );

      await tester.tap(find.byKey(const ValueKey('leave-dungeon')));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsNothing);
    });

    testWidgets('Finish opens the completion confirm', (tester) async {
      await _openCrawl(
        tester,
        _dungeon(stairsUp: _heroAt, depth: deepestDepth),
      );

      await tester.tap(find.byKey(const ValueKey('leave-dungeon')));
      await tester.pumpAndSettle();

      expect(
        find.text('The delve is done. Leave with your spoils?'),
        findsOneWidget,
      );
    });

    testWidgets('Move on ends the road fight and closes the crawl', (
      tester,
    ) async {
      await _openCrawl(tester, _clearedRoad());

      await tester.tap(find.byKey(const ValueKey('move-on')));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsNothing);
    });

    testWidgets('Wait holds ground for a turn', (tester) async {
      final bloc = await _openCrawl(
        tester,
        _dungeon(monsters: [_ghoulAt(const Position(6, 2))]),
      );

      await tester.tap(find.byKey(const ValueKey('wait')));
      await tester.pumpAndSettle();

      expect(bloc.state.log.first.sentence, 'You hold your ground.');
    });

    testWidgets('Flee walks the hero off the ring', (tester) async {
      final bloc = await _openCrawl(tester, _roadEdge());

      await tester.tap(find.byKey(const ValueKey('flee')));
      await tester.pumpAndSettle();

      expect(bloc.state.hasFled, isTrue);
    });
  });

  group('action bar geometry', () {
    testWidgets(
      'the bar rect is identical across every state, at s 1.0 and s 1.3, '
      'and its height matches the literal formula',
      (tester) async {
        final states = <GameState>[
          _dungeon(),
          _dungeon(groundItems: {_heroAt: _oneSword()}),
          _dungeon(monsters: [_ghoulAt(const Position(6, 2))]),
          _dungeon(monsters: [_ghoulAt(const Position(4, 2))]),
          _roadEdge(),
          _dungeon(stairsUp: _heroAt, depth: deepestDepth),
        ];

        Future<Rect> barRectFor(
          GameState game, {
          TextScaler? textScaler,
        }) async {
          await _openCrawl(tester, game, textScaler: textScaler);
          _expectNoVerbOnMap(tester);
          return tester.getRect(find.byKey(actionBarKey));
        }

        Rect? previous;
        for (final state in states) {
          final rect = await barRectFor(state);
          previous ??= rect;
          expect(rect, previous);
        }
        expect(previous!.height, closeTo(128.0, 0.01));

        previous = null;
        for (final state in states) {
          final rect = await barRectFor(
            state,
            textScaler: const TextScaler.linear(1.3),
          );
          previous ??= rect;
          expect(rect, previous);
        }
        expect(previous!.height, closeTo(145.4, 0.01));
      },
    );

    testWidgets(
      'the button row sits 6 dp under a single fact line, not pinned to '
      'the bar\'s bottom',
      (tester) async {
        await _openCrawl(
          tester,
          _dungeon(nodes: {_heroAt: GatherKind.oreVein}),
        );
        final factLine = find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.textContaining('Underfoot:'),
        );
        expect(factLine, findsOneWidget);
        final factBottom = tester.getBottomLeft(factLine).dy;
        final buttonTop = tester
            .getTopLeft(find.byKey(const ValueKey('gather')))
            .dy;
        expect(buttonTop - factBottom, closeTo(6, 0.5));
      },
    );

    testWidgets(
      'with two fact lines, the button row follows the second line, not '
      'the first',
      (tester) async {
        await _openCrawl(
          tester,
          _dungeon(
            nodes: {_heroAt: GatherKind.oreVein},
            groundItems: {_heroAt: _oneSword()},
          ),
        );
        final secondLine = find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.textContaining('Here:'),
        );
        expect(secondLine, findsOneWidget);
        final lineBottom = tester.getBottomLeft(secondLine).dy;
        final buttonTop = tester
            .getTopLeft(find.byKey(const ValueKey('pick-up')))
            .dy;
        expect(buttonTop - lineBottom, closeTo(6, 0.5));
      },
    );

    testWidgets('with Wait only and no fact line, the button row sits directly '
        'under the title zone', (tester) async {
      await _openCrawl(
        tester,
        _dungeon(monsters: [_ghoulAt(const Position(6, 2))]),
      );
      final titleBottom = tester
          .getBottomLeft(
            find.descendant(
              of: find.byKey(actionBarKey),
              matching: find.text('ACTIONS'),
            ),
          )
          .dy;
      final buttonTop = tester
          .getTopLeft(find.byKey(const ValueKey('wait')))
          .dy;
      expect(buttonTop - titleBottom, closeTo(4, 0.5));
    });

    testWidgets(
      'the bar\'s outer rect stays actionBarHeight(s) across the one-fact, '
      'two-fact and no-fact states, at s 1.0 and s 1.3',
      (tester) async {
        final states = <GameState>[
          _dungeon(nodes: {_heroAt: GatherKind.oreVein}),
          _dungeon(
            nodes: {_heroAt: GatherKind.oreVein},
            groundItems: {_heroAt: _oneSword()},
          ),
          _dungeon(monsters: [_ghoulAt(const Position(6, 2))]),
        ];
        for (final scale in [1.0, 1.3]) {
          Rect? previous;
          for (final state in states) {
            await _openCrawl(
              tester,
              state,
              textScaler: TextScaler.linear(scale),
            );
            final rect = tester.getRect(find.byKey(actionBarKey));
            previous ??= rect;
            expect(rect, previous);
            expect(rect.height, closeTo(actionBarHeight(scale), 0.01));
          }
        }
      },
    );

    testWidgets('at s 1.3, 3 fact lines and 4 buttons overflow nothing', (
      tester,
    ) async {
      await _openCrawl(
        tester,
        _dungeon(
          stairsUp: _heroAt,
          depth: deepestDepth,
          nodes: {_heroAt: GatherKind.oreVein},
          groundItems: {_heroAt: _oneSword()},
        ),
        textScaler: const TextScaler.linear(1.3),
      );
      expect(tester.takeException(), isNull);
      for (final id in ['pick-up', 'gather', 'ascend', 'leave-dungeon']) {
        expect(find.byKey(ValueKey(id)), findsOneWidget, reason: id);
      }
      expect(find.byKey(const ValueKey('wait')), findsNothing);
    });

    testWidgets(
      'at s 1.3 the largest fixture overflows nothing and every button is '
      'at least 48 dp square, inside the bar\'s frame rect',
      (tester) async {
        await _openCrawl(
          tester,
          _largestFixture(),
          textScaler: const TextScaler.linear(1.3),
        );

        expect(tester.takeException(), isNull);
        final barRect = tester.getRect(find.byKey(actionBarKey));
        for (final id in [
          'pick-up',
          'gather',
          'ascend',
          'leave-dungeon',
          'wait',
        ]) {
          final rect = tester.getRect(find.byKey(ValueKey(id)));
          expect(rect.width, greaterThanOrEqualTo(48), reason: id);
          expect(rect.height, greaterThanOrEqualTo(48), reason: id);
          expect(barRect.contains(rect.topLeft), isTrue, reason: id);
          expect(barRect.contains(rect.bottomRight), isTrue, reason: id);
        }
      },
    );

    testWidgets(
      'a 4-fact fixture (the largest, plus a full pack) folds onto a third '
      'line holding both Here: and the full-pack sentence',
      (tester) async {
        await _openCrawl(tester, _largestFixture(fullPack: true));
        final thirdLine = find.descendant(
          of: find.byKey(actionBarKey),
          matching: find.textContaining('Here:'),
        );
        expect(thirdLine, findsOneWidget);
        final text = tester.widget<Text>(thirdLine).data!;
        expect(text, contains(inventoryFullSentence));
      },
    );

    testWidgets('the map rect is identical with and without verbs shown', (
      tester,
    ) async {
      await _openCrawl(tester, _dungeon());
      final withoutVerbs = tester.getRect(find.byKey(dungeonSceneSlotKey));

      await _openCrawl(tester, _dungeon(groundItems: {_heroAt: _oneSword()}));
      final withVerbs = tester.getRect(find.byKey(dungeonSceneSlotKey));

      expect(withVerbs, withoutVerbs);
    });

    testWidgets(
      'a tap on each orthogonal neighbour still steps the hero, the bar '
      'shown and all',
      (tester) async {
        for (final neighbour in const [
          Position(2, 2),
          Position(4, 2),
          Position(3, 1),
          Position(3, 3),
        ]) {
          final bloc = await _openCrawl(
            tester,
            _dungeon(groundItems: {_heroAt: _oneSword()}),
          );
          expect(
            find.byKey(actionBarKey),
            findsOneWidget,
            reason: '$neighbour',
          );

          final geometry = GridGeometry.camera(
            tester.getSize(find.byKey(dungeonSceneKey)),
            bloc.state.game.map.width,
            bloc.state.game.map.height,
            _heroAt,
          );
          final topLeft = tester.getTopLeft(find.byKey(dungeonSceneKey));

          await tester.tapAt(topLeft + geometry.centreOf(neighbour));
          await tester.pumpAndSettle();

          expect(
            bloc.state.game.hero.position,
            neighbour,
            reason: '$neighbour',
          );
        }
      },
    );

    testWidgets('a drag on the map still pans it', (tester) async {
      final bloc = await _openCrawl(
        tester,
        _dungeon(groundItems: {_heroAt: _oneSword()}),
      );
      final slotTopLeft = tester.getTopLeft(find.byKey(dungeonSceneSlotKey));

      await tester.dragFrom(
        slotTopLeft + const Offset(4, 4),
        const Offset(-40, -30),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();

      expect(bloc.state.pan, isNot(Offset.zero));
    });
  });
}
