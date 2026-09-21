import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

import 'package:residuum_app/style/tokens.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

Actor _hero(Position at) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: 20,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
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

/// An open battle with more known spells than the row readies, so the
/// overflow chip opens the spells sheet.
GameState _battleWithOverflowScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(1, 2))],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    spells: spellsById,
    knownSpells: const {'firebolt', 'mend', 'ward', 'bind'},
    mana: 10,
  );
}

/// The bottom-floor stairs scene, staged only to reach the completion
/// confirm from `Finish`.
GameState _bottomStairsScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: deepestDepth,
    stairsUp: heroAt,
  );
}

/// A game-over dungeon scene, staged only to reach the death overlay.
GameState _gameOverScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: 0,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isGameOver: true,
  );
}

/// A crawl carrying nothing, staged only to reach the pack screen.
GameState _bareScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
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

/// The outermost physical [Material] a modal route paints itself on — the
/// route's own surface, ahead of anything nested inside it.
Color? _routeSurfaceColor(WidgetTester tester, Type routeWidget) {
  final material = tester.widget<Material>(
    find
        .descendant(
          of: find.byType(routeWidget),
          matching: find.byType(Material),
        )
        .first,
  );
  return material.color;
}

/// The colour a bare Material 3 dark theme would paint a modal bottom sheet
/// with, when nothing overrides it — the surface this unit's sheets must
/// never be caught wearing.
Future<Color?> _bareBottomSheetColor(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SizedBox(height: 100),
              ),
              child: const Text('open sheet'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open sheet'));
  await tester.pumpAndSettle();
  final color = _routeSurfaceColor(tester, BottomSheet);
  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();
  return color;
}

/// The colour a bare Material 3 dark theme would paint a dialog with, when
/// nothing overrides it.
Future<Color?> _bareDialogColor(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(content: SizedBox()),
              ),
              child: const Text('open dialog'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open dialog'));
  await tester.pumpAndSettle();
  final color = _routeSurfaceColor(tester, Dialog);
  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();
  return color;
}

void main() {
  group('every crawl overlay renders on the crawl surface', () {
    testWidgets('the spells overflow sheet renders on panel', (tester) async {
      // arrange - the bare Material 3 default, for contrast
      final bareColor = await _bareBottomSheetColor(tester);

      // act - open the crawl's own overflow sheet
      await _openCrawl(tester, _battleWithOverflowScene());
      await tester.tap(find.byKey(const ValueKey('+1')));
      await tester.pumpAndSettle();

      // assert
      final sheetColor = _routeSurfaceColor(tester, BottomSheet);
      expect(sheetColor, panel);
      expect(sheetColor, isNot(bareColor));
    });

    testWidgets('the enemy info sheet renders on panel', (tester) async {
      // arrange
      final bareColor = await _bareBottomSheetColor(tester);

      // act - select the timeline token, which opens the enemy sheet
      await _openCrawl(tester, _battleWithOverflowScene());
      await tester.tap(find.byKey(const Key('timeline-actor-ghoul-1-1')));
      await tester.pumpAndSettle();

      // assert
      final sheetColor = _routeSurfaceColor(tester, BottomSheet);
      expect(sheetColor, panel);
      expect(sheetColor, isNot(bareColor));
    });

    testWidgets('the completion confirm renders on panel', (tester) async {
      // arrange
      final bareColor = await _bareDialogColor(tester);

      // act - Finish opens the completion confirm
      await _openCrawl(tester, _bottomStairsScene());
      await tester.tap(find.text(doneControl));
      await tester.pumpAndSettle();

      // assert
      final dialogColor = _routeSurfaceColor(tester, Dialog);
      expect(dialogColor, panel);
      expect(dialogColor, isNot(bareColor));
    });

    testWidgets('the death overlay renders on scrim', (tester) async {
      // act
      await _openCrawl(tester, _gameOverScene());

      // assert - found by its own content, never by the colour under test
      final overlay = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: find.text('You died.'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(overlay.color, scrim);
    });
  });

  testWidgets(
    'the pack screen still renders on the town surface, not the crawl scope',
    (tester) async {
      // act
      await _openCrawl(tester, _bareScene());
      await tester.tap(find.byKey(const ValueKey('Pack (0)')));
      await tester.pumpAndSettle();

      // assert - the pack route pushed from the crawl is inside a theme at all
      // and renders on the shared panel surface
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, panel);
      expect(appBar.foregroundColor, ink);
    },
  );
}
