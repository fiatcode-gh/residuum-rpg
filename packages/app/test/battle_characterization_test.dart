import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/inventory_screen.dart';
import 'package:residuum_app/town/character_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// Characterization for `m3-battle-ui`: what the spell rows and the crawl
/// screen do TODAY, pinned green against unmodified `d576d1c` before the
/// battle unit lifts the row grammar and adds the battle view.
///
/// These pins are the verbatim-lift's proof: the extraction may change where
/// the grammar lives, never what it renders. The crawl pins are the
/// battle-view's absence clause — the screen's current structure, so the
/// section-swap that lands later has a documented "before".

const _arena = '''
#######
#.....#
#.....#
#######''';

final _phone = Size(1080, 2424);

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

Future<GameBloc> _openPack(WidgetTester tester, GameState game) async {
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: bloc, child: const InventoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

Future<void> _openCharacter(WidgetTester tester, Profile profile) async {
  final town = TownBloc(profile: profile);
  final world = WorldBloc(
    world: newWhereabouts(),
    worldSeed: profile.worldSeed,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: world),
        ],
        child: const CharacterScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  group('the pack spell row (the extraction source)', () {
    testWidgets('renders marking, name, school word, cost and effect', (
      tester,
    ) async {
      // arrange
      final game = _crawl(
        knownSpells: const {'firebolt'},
        mana: 10,
        monsters: [_ghoul(const Position(1, 2))],
      );

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('Firebolt'), findsOneWidget);
      expect(find.text(SkillId.wrath.schoolMarking), findsOneWidget);
      expect(find.text('Wrath · 2 mana · 2-4 fire △'), findsOneWidget);
      final cast = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cast'),
      );
      expect(cast.onPressed, isNotNull);
    });

    testWidgets('keeps the button and speaks the refusal in the row', (
      tester,
    ) async {
      // arrange
      final game = _crawl(knownSpells: const {'firebolt'}, mana: 1);

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('not enough mana'), findsOneWidget);
      final cast = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cast'),
      );
      expect(cast.onPressed, isNull);
    });
  });

  group('the character screen spell row (the read-only twin)', () {
    testWidgets('renders the same facts with no cast offered', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = newProfile(worldSeed: 4)
          .copyWith(knownSpells: const {'firebolt'});

      // act
      await _openCharacter(tester, profile);
      await tester.scrollUntilVisible(find.text('Firebolt'), 100);
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Firebolt'), findsOneWidget);
      expect(find.text('Wrath · 2 mana'), findsOneWidget);
      expect(find.text('2-4 fire △'), findsNothing);
      expect(find.text('Cast'), findsNothing);
    });
  });

  group('the crawl screen as the battle unit finds it', () {
    testWidgets('shows the map section and the engaged status line', (
      tester,
    ) async {
      // arrange
      final game = _crawl(monsters: [_ghoul(const Position(1, 2))]);

      // act
      await _pushCrawl(tester, game);

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.textContaining('Engaged 1'), findsOneWidget);
      expect(find.textContaining('Pack (0)'), findsOneWidget);
    });

    testWidgets('a bump on an adjacent monster keeps the claws verb', (
      tester,
    ) async {
      // arrange
      final game = _crawl(monsters: [_ghoul(const Position(1, 2))]);
      final bloc = await _pushCrawl(tester, game);

      // act
      bloc.add(const TileTapped(Position(1, 2)));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('You hit the ghoul for 4.'), findsOneWidget);
      expect(find.text('The ghoul claws you for 3.'), findsOneWidget);
    });
  });
}
