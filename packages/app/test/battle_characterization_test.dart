import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/battle_view.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// Characterization for `m3-battle-ui`: what the spell rows and the crawl
/// screen do TODAY, pinned green against the pre-timeline battle surface.
///
/// These pins are the verbatim-lift's proof: the extraction may change where
/// the grammar lives, never what it renders. The crawl pins are the
/// battle-view's absence clause — the screen's current structure, so the
/// live map plus timeline has a documented "before".

const _arena = '''
#######
#.....#
#.....#
#######''';

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

GameState _crawl({
  Set<String> knownSpells = const {},
  int mana = 10,
  List<Actor> monsters = const [],
}) {
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
    spells: spellsById,
    knownSpells: knownSpells,
    mana: mana,
  );
}

/// The crawl route, pushed over a button exactly as the session pushes it.
Future<GameBloc> _pushCrawl(WidgetTester tester, GameState game) async {
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

void main() {
  group('the crawl screen as the battle unit finds it', () {
    testWidgets('shows the map section and the engaged status line', (
      tester,
    ) async {
      // arrange
      final game = _crawl(monsters: [_ghoul(const Position(1, 2))]);

      // act
      await _pushCrawl(tester, game);

      // assert - engaged: the crossed mark and the word in the line
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('✖'), findsOneWidget);
      expect(find.textContaining('Engaged 1'), findsOneWidget);
      expect(find.textContaining('Watched'), findsNothing);
      expect(find.textContaining('Pack (0)'), findsOneWidget);
    });

    testWidgets('a monster in sight beyond reach reads as watched', (
      tester,
    ) async {
      // arrange - the ghoul stands far down the corridor, in sight, out of reach
      final game = _crawl(monsters: [_ghoul(const Position(5, 1))]);

      // act
      await _pushCrawl(tester, game);

      // assert - watched: the eye mark and the word; no dock, no Engaged
      expect(find.text('◉'), findsOneWidget);
      expect(find.textContaining('Watched 1'), findsOneWidget);
      expect(find.textContaining('Engaged'), findsNothing);
      expect(find.byType(BattleDock), findsNothing);
    });

    testWidgets('nothing in sight leaves the glyph cell empty', (tester) async {
      // arrange
      final game = _crawl();

      // act
      await _pushCrawl(tester, game);

      // assert - neither mark, neither word
      expect(find.text('◉'), findsNothing);
      expect(find.text('✖'), findsNothing);
      expect(find.textContaining('Watched'), findsNothing);
      expect(find.textContaining('Engaged'), findsNothing);
    });

    testWidgets('a bump on an adjacent monster keeps the claws verb', (
      tester,
    ) async {
      // arrange
      final game = _crawl(monsters: [_ghoul(const Position(1, 2))]);
      final bloc = await _pushCrawl(tester, game);

      // act - the map tap is the bump now
      bloc.add(const TileTapped(Position(1, 2)));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('You hit the ghoul for 4.'), findsOneWidget);
      expect(find.text('The ghoul claws you for 3.'), findsOneWidget);
    });
  });
}
