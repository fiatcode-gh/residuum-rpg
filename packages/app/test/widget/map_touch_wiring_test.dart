import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

/// Widget proof for `map_touch.dart::resolveMapTap`, wired through the real
/// [GameScreen] over a real [GameBloc]: a small open room, so every axis
/// fits the test surface and the camera centres it regardless of focus.
const _arena = '''
##########
#........#
#........#
#........#
#........#
##########''';
const _columns = 10;
const _rows = 6;
const _hero = Position(1, 1);
const _farMonster = Position(7, 3);

GameState _openRoom({List<Actor> monsters = const []}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _hero, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: _hero,
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
  );
}

Future<GameBloc> _openCrawl(WidgetTester tester, GameState game) async {
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

/// The projection the rendered scene actually uses: the arena fits any test
/// surface this file pumps, so the camera centres it and ignores focus/pan.
GridGeometry _sceneGeometry(WidgetTester tester) => GridGeometry.camera(
  tester.getSize(find.byKey(dungeonSceneKey)),
  _columns,
  _rows,
  _hero,
);

Future<void> _tapLocal(WidgetTester tester, Offset local) async {
  final topLeft = tester.getTopLeft(find.byKey(dungeonSceneKey));
  await tester.tapAt(topLeft + local);
}

void main() {
  testWidgets(
    'a tap at the centre of an adjacent floor cell moves the hero one cell',
    (tester) async {
      final bloc = await _openCrawl(tester, _openRoom());
      final geometry = _sceneGeometry(tester);
      const adjacent = Position(2, 1);

      await _tapLocal(tester, geometry.centreOf(adjacent));
      await tester.pumpAndSettle();

      expect(bloc.state.game.hero.position, adjacent);
    },
  );

  testWidgets('a tap 18 dp off a far monster centre opens the enemy sheet', (
    tester,
  ) async {
    final monster = Actor(
      id: 'ghoul-1',
      name: 'the ghoul',
      glyph: 'g',
      position: _farMonster,
      hp: 10,
      maxHp: 10,
      attackMin: 3,
      attackMax: 3,
      speed: 10,
      energy: actThreshold,
    );
    final bloc = await _openCrawl(tester, _openRoom(monsters: [monster]));
    final geometry = _sceneGeometry(tester);
    final local = geometry.centreOf(_farMonster) + const Offset(18, 0);
    expect(_farMonster.isOrthogonallyAdjacentTo(_hero), isFalse);

    await _tapLocal(tester, local);
    await tester.pumpAndSettle();

    expect(find.text('strikes adjacent'), findsOneWidget);
    expect(bloc.state.game.hero.position, _hero);
  });

  testWidgets(
    'a tap in blank space off the grid changes nothing and opens no sheet',
    (tester) async {
      final bloc = await _openCrawl(tester, _openRoom());
      final geometry = _sceneGeometry(tester);
      const local = Offset(1, 1);
      expect(geometry.positionAt(local), isNull);
      expect((local - geometry.centreOf(_hero)).distance, greaterThan(24));
      final stateBefore = bloc.state;

      await _tapLocal(tester, local);
      await tester.pumpAndSettle();

      expect(find.text('strikes adjacent'), findsNothing);
      expect(identical(bloc.state, stateBefore), isTrue);
    },
  );
}
