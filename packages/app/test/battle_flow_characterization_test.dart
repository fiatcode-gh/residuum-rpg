import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/glyph_grid.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// Characterization for m3-battle-flow: the gestures this unit retires or
/// rebuilds, pinned against unmodified `6a1500a` before the first change and
/// flipped in the commit that moves them.
///
/// The far-card sentence, the bump on a bare stage-card tap, the turn strip's
/// words, the `Engaged` suffix, the non-caster bar and the watched refusal are
/// already pinned in their home suites; this file holds the one behavior no
/// suite pinned — the map's tap-to-attack on an adjacent monster tile — now
/// flipped: the tap is refused like watched ground, and the fight happens
/// through the dock.

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
                child: const GameScreen(),
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

/// Taps one tile of the map, through the grid's own geometry.
Future<void> _tapTile(WidgetTester tester, Position tile) async {
  final grid = find.byType(GlyphGrid);
  final size = tester.getSize(grid);
  final geometry = GridGeometry.camera(size, 7, 5, const Position(1, 1));
  final local =
      geometry.topLeftOf(tile.x, tile.y) +
      Offset(geometry.cellSize / 2, geometry.cellSize / 2);
  await tester.tapAt(tester.getTopLeft(grid) + local);
}

void main() {
  testWidgets(
    'a map tap on an adjacent monster tile refuses like watched ground',
    (tester) async {
      // arrange - the ghoul stands one step below, in sight
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);
      final bloc = await _pushGame(tester, game);

      // act - tap the monster's tile on the map itself
      await _tapTile(tester, const Position(1, 2));
      await tester.pumpAndSettle();

      // assert - the map never swings: the tap is refused, one sentence
      expect(find.textContaining('You hit the ghoul'), findsNothing);
      expect(find.text('Something is watching. You stay put.'), findsOneWidget);
      expect(bloc.state.game.monsters.single.hp, 10);
      expect(bloc.state.game.hero.hp, 20);
      expect(bloc.state.game.hero.position, const Position(1, 1));
    },
  );
}
