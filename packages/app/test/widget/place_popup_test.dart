import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_exits.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/map_overlay_layout.dart';
import 'package:residuum_app/game/place_popup.dart';
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

/// A dungeon floor at [_heroAt], staged with whatever the pop-up under test
/// needs and nothing else.
GameState _dungeon({
  Map<Position, GatherKind> nodes = const {},
  Map<Position, List<Item>> groundItems = const {},
  List<Item> inventory = const [],
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
    monsters: const [],
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

/// The outermost ring of a cleared road fight — nothing left to strike, so
/// `Move on` is the only place verb.
GameState _clearedRoad() {
  final route = residuumWorld.routeBetween(stonebridge, cryptNode)!;
  final fight = startRoadEncounter(
    newProfile(worldSeed: 5),
    day: 4,
    road: route,
  );
  return fight.copyWith(monsters: const []);
}

Future<GameBloc> _openCrawl(
  WidgetTester tester,
  GameState game, {
  NodeId? dungeon,
}) async {
  await onTheTargetPhone(tester);
  await tester.pumpWidget(const SizedBox.shrink());
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final world = WorldBloc(world: newWhereabouts(), worldSeed: 5);
  final bloc = GameBloc(game: game, dungeon: dungeon, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
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
    ),
  );
  await tester.tap(find.text('down'));
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  group('when the pop-up shows', () {
    testWidgets('nothing, on a bare floor', (tester) async {
      await _openCrawl(tester, _dungeon());
      expect(find.byKey(placePopupKey), findsNothing);
    });

    testWidgets('Pick up, over loot underfoot', (tester) async {
      await _openCrawl(tester, _dungeon(groundItems: {_heroAt: _oneSword()}));
      expect(find.byKey(placePopupKey), findsOneWidget);
      expect(find.text('Pick up'), findsOneWidget);
    });

    testWidgets('Mine, over an ore vein', (tester) async {
      await _openCrawl(tester, _dungeon(nodes: {_heroAt: GatherKind.oreVein}));
      expect(find.text('Mine'), findsOneWidget);
    });

    testWidgets('Ascend and Leave, on the stairs up mid-floor', (tester) async {
      await _openCrawl(tester, _dungeon(stairsUp: _heroAt, depth: 2));
      expect(find.text('Ascend <'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
    });

    testWidgets('Move on, when the road fight is cleared', (tester) async {
      await _openCrawl(tester, _clearedRoad());
      expect(find.text('Move on'), findsOneWidget);
    });

    testWidgets('Finish and the bottom-floor note, on the bottom stairs', (
      tester,
    ) async {
      await _openCrawl(
        tester,
        _dungeon(stairsUp: _heroAt, depth: deepestDepth),
      );
      expect(find.text(doneControl), findsOneWidget);
      expect(find.text(doneAtTheBottom), findsOneWidget);
    });

    testWidgets('doneAtTheBottom nowhere but the bottom stairs', (
      tester,
    ) async {
      await _openCrawl(tester, _dungeon(stairsUp: _heroAt, depth: 2));
      expect(find.text(doneAtTheBottom), findsNothing);
    });

    testWidgets('the Here fact without Pick up, with a full pack', (
      tester,
    ) async {
      await _openCrawl(
        tester,
        _dungeon(
          groundItems: {_heroAt: _oneSword()},
          inventory: List.generate(
            inventoryCap,
            (index) =>
                Item(id: 'held-$index', base: ironSword, rarity: Rarity.common),
          ),
        ),
      );
      expect(find.text('Pick up'), findsNothing);
      expect(find.textContaining('Here:'), findsOneWidget);
    });
  });

  group('tapping a place verb', () {
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
  });

  testWidgets('the pop-up rect never overlaps the padded hero block', (
    tester,
  ) async {
    final bloc = await _openCrawl(
      tester,
      _dungeon(
        groundItems: {_heroAt: _oneSword()},
        stairsUp: _heroAt,
        depth: 2,
      ),
    );

    final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
    final popupRect = tester
        .getRect(find.byKey(placePopupKey))
        .shift(-mapRect.topLeft);
    final geometry = GridGeometry.camera(
      mapRect.size,
      bloc.state.game.map.width,
      bloc.state.game.map.height,
      bloc.state.cameraFocus,
      bloc.state.pan,
    );
    final heroRect = geometry.rectOf(bloc.state.game.hero.position);

    expect(popupRect.overlaps(heroBlock(heroRect)), isFalse);
  });

  testWidgets('the pop-up sits directly under the hero block, centred on '
      'the hero', (tester) async {
    final bloc = await _openCrawl(
      tester,
      _dungeon(groundItems: {_heroAt: _oneSword()}),
    );

    final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
    final popupRect = tester
        .getRect(find.byKey(placePopupKey))
        .shift(-mapRect.topLeft);
    final geometry = GridGeometry.camera(
      mapRect.size,
      bloc.state.game.map.width,
      bloc.state.game.map.height,
      bloc.state.cameraFocus,
      bloc.state.pan,
    );
    final heroRect = geometry.rectOf(bloc.state.game.hero.position);
    final block = heroBlock(heroRect);

    expect(popupRect.top, closeTo(block.bottom + 6, 0.5));
    expect(popupRect.center.dx, closeTo(heroRect.center.dx, 0.5));
  });

  testWidgets('the map rect never changes for the pop-up appearing', (
    tester,
  ) async {
    await _openCrawl(tester, _dungeon());
    final withoutPopup = tester.getRect(find.byKey(dungeonSceneSlotKey));

    await _openCrawl(tester, _dungeon(groundItems: {_heroAt: _oneSword()}));
    final withPopup = tester.getRect(find.byKey(dungeonSceneSlotKey));

    expect(withPopup, withoutPopup);
  });

  testWidgets(
    'a tap on each orthogonal neighbour still steps the hero, the pop-up '
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
        expect(find.byKey(placePopupKey), findsOneWidget, reason: '$neighbour');

        final geometry = GridGeometry.camera(
          tester.getSize(find.byKey(dungeonSceneKey)),
          bloc.state.game.map.width,
          bloc.state.game.map.height,
          _heroAt,
        );
        final topLeft = tester.getTopLeft(find.byKey(dungeonSceneKey));

        await tester.tapAt(topLeft + geometry.centreOf(neighbour));
        await tester.pumpAndSettle();

        expect(bloc.state.game.hero.position, neighbour, reason: '$neighbour');
      }
    },
  );

  testWidgets('a drag outside the pop-up still pans the map', (tester) async {
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
}
