import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/action_card.dart';
import 'package:residuum_app/game/event_messages.dart';
import 'package:residuum_app/game/crawl_exits.dart';
import 'package:residuum_app/game/crawl_surfaces.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/map_overlay_layout.dart';
import 'package:residuum_app/game/map_overlays.dart';
import 'package:residuum_app/game/turn_order_strip.dart';
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

/// A dungeon floor at [_heroAt], staged with whatever the card under test
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

String _tallArena(int rows) => List.generate(rows, (_) => '.......').join('\n');

GameState _tallDungeon({
  List<Actor> monsters = const [],
  Map<Position, List<Item>> groundItems = const {},
  int rows = 60,
}) {
  final map = FloorMap.parse(_tallArena(rows));
  const heroAt = Position(3, 30);
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
    groundItems: groundItems,
  );
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
  group('when the action card shows', () {
    testWidgets('nothing, on a bare floor', (tester) async {
      await _openCrawl(tester, _dungeon());
      expect(find.byKey(actionCardKey), findsNothing);
    });

    testWidgets('Pick up, over loot underfoot', (tester) async {
      await _openCrawl(tester, _dungeon(groundItems: {_heroAt: _oneSword()}));
      expect(find.byKey(actionCardKey), findsOneWidget);
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
      expect(
        find.descendant(
          of: find.byKey(actionCardKey),
          matching: find.text('Pick up'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(actionCardKey),
          matching: find.textContaining('Here:'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionCardKey),
          matching: find.text(inventoryFullSentence),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Wait alone while Watched', (tester) async {
      await _openCrawl(
        tester,
        _dungeon(monsters: [_ghoulAt(const Position(6, 2))]),
      );
      expect(find.byKey(const ValueKey('wait')), findsOneWidget);
      expect(find.byKey(const ValueKey('flee')), findsNothing);
    });

    testWidgets('Flee alone at a road edge with nothing in sight', (
      tester,
    ) async {
      await _openCrawl(tester, _roadEdge());
      expect(find.byKey(const ValueKey('flee')), findsOneWidget);
      expect(find.byKey(const ValueKey('wait')), findsNothing);
    });

    testWidgets('Flee and Wait together at a road edge in sight', (
      tester,
    ) async {
      await _openCrawl(tester, _roadEdge(withMonster: true));
      expect(find.byKey(const ValueKey('flee')), findsOneWidget);
      expect(find.byKey(const ValueKey('wait')), findsOneWidget);
    });
  });

  group('tapping a verb on the action card', () {
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

  group('action card geometry', () {
    testWidgets(
      'the card rect sits at the map edges, centred on the hero, clear of '
      'its block',
      (tester) async {
        final bloc = await _openCrawl(
          tester,
          _dungeon(groundItems: {_heroAt: _oneSword()}),
        );

        final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
        final cardRect = tester
            .getRect(find.byKey(actionCardKey))
            .shift(-mapRect.topLeft);
        final geometry = GridGeometry.camera(
          mapRect.size,
          bloc.state.game.map.width,
          bloc.state.game.map.height,
          bloc.state.cameraFocus,
          bloc.state.pan,
        );
        final heroRect = geometry.rectOf(bloc.state.game.hero.position);

        expect(cardRect.left, closeTo(8, 0.5));
        expect(cardRect.right, closeTo(mapRect.width - 8, 0.5));
        expect(cardRect.bottom, closeTo(mapRect.height - 8, 0.5));
        expect(cardRect.overlaps(heroBlock(heroRect)), isFalse);
      },
    );

    testWidgets(
      'the card falls back to the top edge when the hero pans low enough '
      'to block the bottom edge',
      (tester) async {
        final bloc = await _openCrawl(
          tester,
          _tallDungeon(groundItems: {const Position(3, 30): _oneSword()}),
        );

        final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
        bloc.add(MapPanned(Offset(0, mapRect.height / 2 - 30)));
        await tester.pumpAndSettle();

        final geometry = GridGeometry.camera(
          mapRect.size,
          bloc.state.game.map.width,
          bloc.state.game.map.height,
          bloc.state.cameraFocus,
          bloc.state.pan,
        );
        final localHero = geometry.rectOf(bloc.state.game.hero.position);
        final localCard = tester
            .getRect(find.byKey(actionCardKey))
            .shift(-mapRect.topLeft);
        final height = localCard.height;
        final bottomCandidate = Rect.fromLTRB(
          8,
          mapRect.height - 8 - height,
          mapRect.width - 8,
          mapRect.height - 8,
        );

        expect(bottomCandidate.overlaps(heroBlock(localHero)), isTrue);

        expect(localCard.top, closeTo(8, 0.5));
        expect(localCard.overlaps(heroBlock(localHero)), isFalse);
      },
    );

    testWidgets(
      'the same fallback lands below the turn-order strip in battle',
      (tester) async {
        final bloc = await _openCrawl(
          tester,
          _tallDungeon(monsters: [_ghoulAt(const Position(3, 31))]),
        );
        expect(bloc.state.isBattleOpen, isTrue);

        final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
        bloc.add(MapPanned(Offset(0, mapRect.height / 2 - 30)));
        await tester.pumpAndSettle();

        final cardRect = tester
            .getRect(find.byKey(actionCardKey))
            .shift(-mapRect.topLeft);
        final stripRect = tester
            .getRect(find.byType(TurnOrderStrip))
            .shift(-mapRect.topLeft);
        expect(cardRect.top, closeTo(stripRect.bottom + 8, 0.5));
      },
    );

    testWidgets('the leader runs from the hero cell to the facing card edge', (
      tester,
    ) async {
      final bloc = await _openCrawl(
        tester,
        _dungeon(groundItems: {_heroAt: _oneSword()}),
      );

      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final cardRect = tester
          .getRect(find.byKey(actionCardKey))
          .shift(-mapRect.topLeft);
      final geometry = GridGeometry.camera(
        mapRect.size,
        bloc.state.game.map.width,
        bloc.state.game.map.height,
        bloc.state.cameraFocus,
        bloc.state.pan,
      );
      final heroRect = geometry.rectOf(bloc.state.game.hero.position);

      final paint = tester.widget<CustomPaint>(find.byKey(actionCardLeaderKey));
      final painter = paint.painter! as LeaderPainter;

      final x = heroRect.center.dx;
      final tx = x.clamp(cardRect.left + 6, cardRect.right - 6);
      final below = cardRect.center.dy >= heroRect.center.dy;
      final expectedFrom = below
          ? Offset(x, heroRect.bottom)
          : Offset(x, heroRect.top);
      final expectedTo = below
          ? Offset(tx, cardRect.top)
          : Offset(tx, cardRect.bottom);
      expect(painter.from, expectedFrom);
      expect(painter.to, expectedTo);
    });

    testWidgets(
      'at text scale 1.3 the largest fixture overflows nothing and every '
      'button is at least 48 dp square',
      (tester) async {
        await onTheTargetPhone(tester);
        final town = TownBloc(profile: newProfile(worldSeed: 5));
        final world = WorldBloc(world: newWhereabouts(), worldSeed: 5);
        final bloc = GameBloc(
          game: _dungeon(
            stairsUp: _heroAt,
            depth: deepestDepth,
            nodes: {_heroAt: GatherKind.oreVein},
            groundItems: {_heroAt: _oneSword()},
            monsters: [_ghoulAt(const Position(6, 2))],
          ),
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.3)),
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: town),
                    BlocProvider.value(value: world),
                    BlocProvider.value(value: bloc),
                  ],
                  child: const GameScreen(palette: DungeonPalette.crypt),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final id in [
          'pick-up',
          'gather',
          'ascend',
          'leave-dungeon',
          'wait',
        ]) {
          final size = tester.getSize(find.byKey(ValueKey(id)));
          expect(size.width, greaterThanOrEqualTo(48), reason: id);
          expect(size.height, greaterThanOrEqualTo(48), reason: id);
        }
      },
    );

    testWidgets(
      'a tap on each orthogonal neighbour still steps the hero, the card '
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
            find.byKey(actionCardKey),
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

    testWidgets('a tap inside the card leaves the hero in place', (
      tester,
    ) async {
      final bloc = await _openCrawl(
        tester,
        _dungeon(groundItems: {_heroAt: _oneSword()}),
      );
      final before = bloc.state.game.hero.position;
      final cardCentre = tester.getCenter(find.byKey(actionCardKey));

      await tester.tapAt(cardCentre);
      await tester.pumpAndSettle();

      expect(bloc.state.game.hero.position, before);
    });

    testWidgets('a drag outside the card still pans the map', (tester) async {
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

    testWidgets('the map rect never changes for the card appearing', (
      tester,
    ) async {
      await _openCrawl(tester, _dungeon());
      final withoutCard = tester.getRect(find.byKey(dungeonSceneSlotKey));

      await _openCrawl(tester, _dungeon(groundItems: {_heroAt: _oneSword()}));
      final withCard = tester.getRect(find.byKey(dungeonSceneSlotKey));

      expect(withCard, withoutCard);
    });

    testWidgets(
      'the recenter pill never overlaps the card and still recentres',
      (tester) async {
        final bloc = await _openCrawl(
          tester,
          _tallDungeon(groundItems: {const Position(3, 30): _oneSword()}),
        );

        bloc.add(const MapPanned(Offset(0, 100000)));
        await tester.pumpAndSettle();

        final cardRect = tester.getRect(find.byKey(actionCardKey));
        final pillRect = tester.getRect(find.byKey(recenterKey));
        expect(pillRect.overlaps(cardRect), isFalse);

        await tester.tap(find.byKey(recenterKey));
        await tester.pumpAndSettle();

        expect(bloc.state.pan, Offset.zero);
      },
    );
  });
}
