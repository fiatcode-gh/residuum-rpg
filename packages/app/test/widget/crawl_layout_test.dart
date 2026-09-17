import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/crawl_status.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/log_drawer.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _heroAt = Position(2, 2);
const _adjacentToHero = Position(3, 2);

Actor _actor(String id, Position at, {String glyph = '@'}) => Actor(
  id: id,
  name: id,
  glyph: glyph,
  position: at,
  hp: 20,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

/// A quiet room with nothing nearby, so `isBattleOpen` is false.
GameState _exploringGame() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _actor('hero', _heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

/// The hero and one live ghoul stand adjacent, so `isBattleOpen` is true.
GameState _battleGame() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _actor('hero', _heroAt),
    monsters: [_actor('ghoul-1', _adjacentToHero, glyph: 'g')],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

Future<GameBloc> _openCrawl(WidgetTester tester, GameState game) async {
  await onAPhone(tester);
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const GameScreen(palette: DungeonPalette.crypt),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

double _surfaceWidth(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

void main() {
  testWidgets(
    'while exploring, status sits above the map, and the map meets the '
    'log and the controls in the mock order',
    (tester) async {
      await _openCrawl(tester, _exploringGame());

      final statusTop = tester.getTopLeft(find.byType(CrawlStatus)).dy;
      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final peekTop = tester.getTopLeft(find.byKey(logPeekKey)).dy;
      final controlsTop = tester.getTopLeft(find.byKey(actionRowKey)).dy;

      expect(statusTop, lessThan(mapRect.top));
      expect(mapRect.bottom, lessThanOrEqualTo(peekTop));
      expect(peekTop, lessThan(controlsTop));
      expect(mapRect.left, 0);
      expect(mapRect.right, _surfaceWidth(tester));
      expect(mapRect.height, greaterThan(0));
    },
  );

  testWidgets(
    'in an open battle, status sits above the dock and the dock above the '
    'map, which still spans the full surface width',
    (tester) async {
      await _openCrawl(tester, _battleGame());

      final statusTop = tester.getTopLeft(find.byType(CrawlStatus)).dy;
      final dockTop = tester
          .getTopLeft(find.byKey(const Key('dock-backing')))
          .dy;
      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));

      expect(statusTop, lessThan(dockTop));
      expect(dockTop, lessThan(mapRect.top));
      expect(mapRect.left, 0);
      expect(mapRect.right, _surfaceWidth(tester));
      expect(mapRect.height, greaterThan(0));
    },
  );

  testWidgets(
    'cycling the log extent peek, half, full and back leaves the map slot '
    'and the peek unchanged',
    (tester) async {
      await _openCrawl(tester, _exploringGame());

      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final peekRect = tester.getRect(find.byKey(logPeekKey));

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
      expect(tester.getRect(find.byKey(logPeekKey)), peekRect);

      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
      expect(tester.getRect(find.byKey(logPeekKey)), peekRect);

      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(find.byKey(logDrawerKey), findsNothing);
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
      expect(tester.getRect(find.byKey(logPeekKey)), peekRect);
    },
  );

  testWidgets(
    "the map's hairline border paints in front of the dungeon scene, not "
    'behind it, where an opaque child would cover it',
    (tester) async {
      await _openCrawl(tester, _exploringGame());

      // Flame's own `GameWidget` wraps its canvas in an opaque
      // `DecoratedBox(decoration: BoxDecoration(color: backgroundColor()))`
      // beneath the crawl's border — the predicate is what tells the two
      // apart, since the crawl's is the one carrying a `Border`.
      final border = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(dungeonSceneSlotKey),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                (widget.decoration as BoxDecoration).border != null,
          ),
        ),
      );
      expect(border.position, DecorationPosition.foreground);
    },
  );
}
