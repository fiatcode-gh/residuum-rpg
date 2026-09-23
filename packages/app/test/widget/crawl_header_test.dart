import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_header.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// The world seed whose sea-cave rolls six floors on visit one and whose
/// keep rolls seven, so the depth pair has something to say that the
/// crypt's fixed five would have hidden.
const int _pinnedSeed = 4242;

/// A [GameScreen] over a real crawl in the dungeon at [node].
///
/// The real screen over a real bloc, for the reason `back_guard_test`
/// gives: the wiring between them is the whole subject, and the header is a
/// private widget in `game_screen.dart`'s tree that a bloc test cannot
/// reach. Neither bloc is closed, also for that file's reason — a widget
/// test's clock is a fake one and awaiting a bloc's close inside
/// `testWidgets` hangs rather than fails.
Future<void> _pumpCrawlAt(
  WidgetTester tester,
  NodeId node, {
  int? day,
  int? hp,
  int warded = 0,
}) async {
  final profile = newProfile(worldSeed: _pinnedSeed);
  final town = TownBloc(profile: profile);
  var game = startDungeonRunAt(node, profile);
  if (hp != null) game = game.copyWith(hero: game.hero.copyWith(hp: hp));
  game = game.copyWith(warded: warded);
  final bloc = GameBloc(
    game: game,
    dungeon: node,
    day: day,
    stepDelay: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: bloc),
        ],
        child: const GameScreen(palette: DungeonPalette.crypt),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _roadArena = '''
#####
#...#
#####''';

/// A road fight: no dungeon, no floor, only the encounter.
Future<void> _pumpRoadFight(WidgetTester tester, {int? day}) async {
  final map = FloorMap.parse(_roadArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  final game = GameState(
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
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isEncounter: true,
  );
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final bloc = GameBloc(game: game, day: day, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: bloc),
        ],
        child: const GameScreen(palette: DungeonPalette.lowlandRoad),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _arena = '''
###########
#.........#
#.........#
#.........#
###########''';
const _heroAt = Position(1, 1);

Actor _ghoul(String id, Position at) => Actor(
  id: id,
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

/// A crawl over a hand-built arena rather than a rolled floor, for tests
/// that need control over what stands beside the hero: the chip row's
/// battle, condition and ward facts. Always the crypt, since none of these
/// tests are about the place.
Future<void> _pumpArena(
  WidgetTester tester, {
  List<Actor> monsters = const [],
  int hp = 20,
  int warded = 0,
}) async {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  final game = GameState(
    map: map,
    hero: Actor(
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
    ),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    warded: warded,
  );
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final bloc = GameBloc(
    game: game,
    dungeon: cryptNode,
    stepDelay: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: bloc),
        ],
        child: const GameScreen(palette: DungeonPalette.crypt),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the meta line names the place, its depth and the day', () {
    testWidgets('the crypt reads its depth, name and the day', (tester) async {
      await _pumpCrawlAt(tester, cryptNode, day: 3);

      expect(find.text('Depth 1/5'), findsOneWidget);
      expect(find.byKey(depthPairKey), findsOneWidget);
      expect(find.text('The Crypt'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
    });

    testWidgets('the sea-cave reads the six floors it rolled', (tester) async {
      final rolled = delveDepth(seaCave, _pinnedSeed, 1);

      await _pumpCrawlAt(tester, seaCave, day: 3);

      expect(rolled, 6);
      expect(find.text('Depth 1/6'), findsOneWidget);
      expect(find.text('The Sea-Cave'), findsOneWidget);
    });

    testWidgets('the ruined keep reads the seven floors it rolled', (
      tester,
    ) async {
      final rolled = delveDepth(ruinedKeep, _pinnedSeed, 1);

      await _pumpCrawlAt(tester, ruinedKeep, day: 3);

      expect(rolled, 7);
      expect(find.text('Depth 1/7'), findsOneWidget);
      expect(find.text('The Ruined Keep'), findsOneWidget);
    });

    testWidgets('a road fight names the road, the day, and shows no depth', (
      tester,
    ) async {
      await _pumpRoadFight(tester, day: 3);

      expect(find.text('The Road'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
      expect(find.byKey(depthPairKey), findsNothing);
    });

    testWidgets('a null day leaves the day segment off entirely', (
      tester,
    ) async {
      await _pumpCrawlAt(tester, cryptNode);

      expect(find.text('The Crypt'), findsOneWidget);
      expect(find.textContaining('Day'), findsNothing);
    });
  });

  group('the battle chip reads engagement, in shape and word', () {
    testWidgets('engaged reads the diamond and every monster in sight', (
      tester,
    ) async {
      await _pumpArena(
        tester,
        monsters: [
          _ghoul('ghoul-1', const Position(2, 1)),
          _ghoul('ghoul-2', const Position(1, 2)),
        ],
      );

      expect(find.text('Engaged 2'), findsOneWidget);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byKey(crawlChipBattleKey),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter
              as ChipMarkPainter;
      expect(painter.mark, ChipMark.diamond);
    });

    testWidgets('watched reads the ring and the word alone', (tester) async {
      await _pumpArena(
        tester,
        monsters: [_ghoul('ghoul-1', const Position(4, 1))],
      );

      expect(find.text('Watched 1'), findsOneWidget);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byKey(crawlChipBattleKey),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter
              as ChipMarkPainter;
      expect(painter.mark, ChipMark.ring);
    });

    testWidgets('nothing in sight leaves no battle chip at all', (
      tester,
    ) async {
      await _pumpArena(tester);

      expect(find.byKey(crawlChipBattleKey), findsNothing);
      expect(find.textContaining('Engaged'), findsNothing);
      expect(find.textContaining('Watched'), findsNothing);
    });
  });

  group("the condition chip reads the hero's hit points", () {
    testWidgets('full hit points read as steady', (tester) async {
      await _pumpArena(tester, hp: 20);

      expect(find.text('Steady'), findsOneWidget);
    });

    testWidgets('half hit points read as wounded', (tester) async {
      await _pumpArena(tester, hp: 10);

      expect(find.text('Wounded'), findsOneWidget);
    });

    testWidgets('a quarter hit points read as critical', (tester) async {
      await _pumpArena(tester, hp: 4);

      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('no hit points read as dead', (tester) async {
      await _pumpArena(tester, hp: 0);

      expect(find.text('Dead'), findsOneWidget);
    });
  });

  group('the ward chip reads the standing ward', () {
    testWidgets('a ward reads its own count', (tester) async {
      await _pumpArena(tester, warded: 3);

      expect(find.text('Ward 3'), findsOneWidget);
    });

    testWidgets('no ward leaves no ward chip at all', (tester) async {
      await _pumpArena(tester);

      expect(find.byKey(crawlChipWardKey), findsNothing);
      expect(find.textContaining('Ward'), findsNothing);
    });
  });

  group('the header holds its fixed height', () {
    testWidgets('88 dp while exploring', (tester) async {
      await _pumpArena(tester);

      expect(tester.getRect(find.byType(CrawlHeader)).height, 88);
    });

    testWidgets('88 dp with a battle open', (tester) async {
      await _pumpArena(
        tester,
        monsters: [_ghoul('ghoul-1', const Position(2, 1))],
      );

      expect(tester.getRect(find.byType(CrawlHeader)).height, 88);
    });

    testWidgets('114.4 dp at 1.3x text scale, with nothing overflowing', (
      tester,
    ) async {
      await onAPhone(tester);
      final profile = newProfile(worldSeed: _pinnedSeed);
      final town = TownBloc(profile: profile);
      final bloc = GameBloc(
        game: startDungeonRunAt(ruinedKeep, profile),
        dungeon: ruinedKeep,
        day: 3,
        stepDelay: Duration.zero,
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: town),
                BlocProvider.value(value: bloc),
              ],
              child: const GameScreen(palette: DungeonPalette.ruinedKeep),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('The Ruined Keep'), findsOneWidget);
      expect(
        tester.getRect(find.byType(CrawlHeader)).height,
        closeTo(114.4, 0.1),
      );
    });
  });

  group('what the mock keeps that the crawl never brought', () {
    testWidgets('no seed, torch, hunger, weather or menu affordance', (
      tester,
    ) async {
      await _pumpCrawlAt(tester, cryptNode, day: 3);

      final header = find.byType(CrawlHeader);
      for (final word in ['Seed', 'Torch', 'Hungry', 'Clear']) {
        expect(
          find.descendant(of: header, matching: find.textContaining(word)),
          findsNothing,
        );
      }
      expect(
        find.descendant(of: header, matching: find.byIcon(Icons.menu)),
        findsNothing,
      );
      expect(
        find.descendant(of: header, matching: find.byIcon(Icons.settings)),
        findsNothing,
      );
    });
  });
}
