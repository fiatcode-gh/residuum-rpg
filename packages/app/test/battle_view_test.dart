import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/battle_view.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/glyph_grid.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// The battle view: stage cards, turn strip, skill bar, and the gestures that
/// carry an armed cast through core's `targetId`.
///
/// Every test pumps the real [GameScreen] over a real [GameBloc] — the swap
/// between crawl and battle is the unit's subject, and a fake screen would
/// test the test. Neither bloc is closed, per the suite's standing rule: the
/// widget test's clock is fake and the bloc closes itself on the event loop.

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

/// A phone-sized viewport, which is where the screen has to read.
final Size _phone = Size(1080, 2424);

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

Actor spitterAt(Position at) => Actor(
  id: 'spitter-1',
  name: 'the spitter',
  glyph: 'p',
  position: at,
  hp: 4,
  maxHp: 4,
  attackMin: 2,
  attackMax: 3,
  speed: 5,
  energy: 0,
  reach: 3,
);

GameState battleGame({
  Position heroAt = const Position(1, 1),
  List<Actor> monsters = const [],
  Set<String> knownSpells = const {},
  int mana = 0,
  Set<Position>? visible,
}) {
  final map = FloorMap.parse(_arena);
  final seen = visible ?? computeFov(map, heroAt, fovRadius);
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
    knownSpells: knownSpells,
    mana: mana,
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

void main() {
  group('the battle view swap', () {
    testWidgets('the battle view swaps in for the map while reach is held', (
      tester,
    ) async {
      // arrange - a ghoul standing right there
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

      // act
      await _pushGame(tester, game);

      // assert
      expect(find.byType(BattleView), findsOneWidget);
      expect(find.byType(GlyphGrid), findsNothing);
    });

    testWidgets('the crawl view returns when nothing holds reach', (
      tester,
    ) async {
      // arrange - three clean swings put the ten-hit ghoul down
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);
      final bloc = await _pushGame(tester, game);

      // act
      bloc.add(const TileTapped(Position(1, 2)));
      await tester.pumpAndSettle();
      bloc.add(const TileTapped(Position(1, 2)));
      await tester.pumpAndSettle();
      bloc.add(const TileTapped(Position(1, 2)));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.game.monsters, isEmpty);
      expect(find.byType(BattleView), findsNothing);
      expect(find.byType(GlyphGrid), findsOneWidget);
    });
  });

  group('the stage', () {
    testWidgets('the stage names, numbers and marks what holds reach', (
      tester,
    ) async {
      // arrange - adjacent ghoul, spitter two tiles out along the sight line
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          spitterAt(const Position(3, 1)),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(3, 1),
        },
      );

      // act
      await _pushGame(tester, game);

      // assert - name and hit points by bar and number, range by word
      expect(find.text('the ghoul'), findsOneWidget);
      expect(find.text('10 / 10'), findsOneWidget);
      expect(find.text('the spitter'), findsOneWidget);
      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('at range'), findsOneWidget);
    });

    testWidgets('the turn strip names who acts next and who walks in', (
      tester,
    ) async {
      // arrange - the adjacent ghoul owes the next turn; a second ghoul walks
      // in from four tiles down the corridor
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          ghoulAt(const Position(5, 1), id: 'ghoul-2'),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(5, 1),
        },
      );

      // act
      await _pushGame(tester, game);

      // assert
      expect(find.text('Next: the ghoul'), findsOneWidget);
      expect(find.text('the ghoul — 4 turns out'), findsOneWidget);
    });

    testWidgets('the stage reads on a phone-sized surface', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          spitterAt(const Position(3, 1)),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(3, 1),
        },
      );

      // act
      await _pushGame(tester, game);

      // assert - nothing overflows: the strip, the bar and the word all render
      expect(find.byType(BattleView), findsOneWidget);
      expect(find.text('the ghoul'), findsOneWidget);
      expect(find.text('the spitter'), findsOneWidget);
      expect(find.text('at range'), findsOneWidget);
      expect(find.text('Next: the ghoul'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the skill bar', () {
    testWidgets('the bar lists marking, name and cost, school first', (
      tester,
    ) async {
      // arrange - two known spells across two schools
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt', 'mend'},
        mana: 10,
      );

      // act
      await _pushGame(tester, game);

      // assert - school order first (Wrath before Mending), then name
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
      expect(find.text('✚ Mend 3'), findsOneWidget);
    });

    testWidgets('a non-caster sees no bar', (tester) async {
      // arrange
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

      // act
      await _pushGame(tester, game);

      // assert
      expect(find.textContaining('Firebolt'), findsNothing);
    });

    testWidgets('tapping a skill arms it, marked by a word', (tester) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.armedSpellId, 'firebolt');
      expect(find.text('✳ Firebolt 2 — armed'), findsOneWidget);
    });

    testWidgets('an armed cast at a stage card names the target', (
      tester,
    ) async {
      // arrange - the ghoul is nearer; the spitter is the named target
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          spitterAt(const Position(3, 1)),
        ],
        knownSpells: const {'firebolt'},
        mana: 10,
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(3, 1),
        },
      );
      final bloc = await _pushGame(tester, game);

      // act - arm, then tap the spitter's card
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('the spitter'));
      await tester.pumpAndSettle();

      // assert - the shot landed on the named target, not the nearest
      expect(
        bloc.state.log.where(
          (line) => line.startsWith('Firebolt burns the spitter'),
        ),
        isNotEmpty,
      );
    });

    testWidgets('tapping a card with no armed skill is the bump-attack', (
      tester,
    ) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('the ghoul'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('You hit the ghoul for 4.'), findsOneWidget);
      expect(bloc.state.armedSpellId, isNull);
    });

    testWidgets('mend casts on the hero without a card tap', (tester) async {
      // arrange
      final game = battleGame(
        heroAt: const Position(1, 1),
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'mend'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act - cast from the bar directly, no card tap
      bloc.add(const CastPressed('mend'));
      await tester.pumpAndSettle();

      // assert - the pool paid for it and no target was needed
      expect(bloc.state.game.mana, 7);
      expect(
        bloc.state.log.where((line) => line.startsWith('You mend')),
        isNotEmpty,
      );
    });

    testWidgets('a refused armed cast speaks in the log', (tester) async {
      // arrange - the pool cannot pay for the shot
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 1,
      );
      final bloc = await _pushGame(tester, game);

      // act - arm and cast anyway; the button stays tappable
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('the ghoul'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('not enough mana'), findsNothing);
      expect(
        bloc.state.log.where((line) => line.startsWith('Not enough mana')),
        isNotEmpty,
      );
    });
  });
}
