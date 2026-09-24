import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// Characterization for m3-battle-flow: the gestures this unit preserves while
/// replacing the old battle scheduling prose with the activation timeline.
///
/// The timeline interaction is view-only. This file holds the map's tap-to-
/// attack behavior — the adjacent tap remains a core bump, while distant map
/// inspection remains presentation-only.

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

Actor ghoulAt(
  Position at, {
  String id = 'ghoul-1',
  int hp = 10,
  int speed = 10,
  int energy = actThreshold,
}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: speed,
  energy: energy,
);

GameState battleGame({
  Position heroAt = const Position(1, 1),
  List<Actor> monsters = const [],
}) {
  final map = FloorMap.parse(_arena);
  final seen = computeFov(map, heroAt, fovRadius);
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
    visible: seen,
    explored: {...seen},
    buildFloor: (depth) => throw StateError('no floor below'),
    spells: spellsById,
  );
}

Future<GameBloc> _pushGame(WidgetTester tester, GameState game) async {
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: town),
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

/// Taps one tile of the map, through the scene's own geometry.
Future<void> _tapTile(WidgetTester tester, Position tile) async {
  final scene = find.byKey(dungeonSceneKey);
  final size = tester.getSize(scene);
  final geometry = GridGeometry.camera(size, 7, 5, const Position(1, 1));
  final local = geometry.centreOf(tile);
  await tester.tapAt(tester.getTopLeft(scene) + local);
}

void main() {
  testWidgets('a map tap on an adjacent monster tile is the bump attack', (
    tester,
  ) async {
    // arrange - the ghoul stands one step below, in sight
    final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);
    final bloc = await _pushGame(tester, game);

    // act - tap the monster's tile on the map itself
    await _tapTile(tester, const Position(1, 2));
    await tester.pumpAndSettle();

    // assert - the map swings now: the bump fired, one sentence
    expect(find.textContaining('You hit the ghoul'), findsOneWidget);
    expect(find.text('Something is watching. You stay put.'), findsNothing);
    expect(bloc.state.game.monsters.single.hp, lessThan(10));
    expect(bloc.state.game.hero.position, const Position(1, 1));
  });
}
