import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/combat_panel.dart';
import 'package:residuum_app/game/crawl_status.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/hero_panel.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// The world seed whose sea-cave rolls six floors on visit one and whose keep
/// rolls seven, so the status rows have something to say that the crypt's
/// fixed five would have hidden.
const int _pinnedSeed = 4242;

/// A [GameScreen] over a real crawl in the dungeon at [node].
///
/// The real screen over a real bloc, for the reason `back_guard_test` gives:
/// the wiring between them is the whole subject, and the status rows are
/// private widgets a bloc test cannot reach. Neither bloc is closed, also for
/// that file's reason — a widget test's clock is a fake one and awaiting a
/// bloc's close inside `testWidgets` hangs rather than fails.
Future<void> _pumpCrawlAt(
  WidgetTester tester,
  NodeId node, {
  int? hp,
  Set<String> knownSpells = const {},
  int? mana,
  int warded = 0,
}) async {
  final profile = newProfile(worldSeed: _pinnedSeed)
      .copyWith(knownSpells: knownSpells);
  final town = TownBloc(profile: profile);
  var game = startDungeonRunAt(node, profile);
  if (hp != null) game = game.copyWith(hero: game.hero.copyWith(hp: hp));
  if (mana != null) game = game.copyWith(mana: mana);
  game = game.copyWith(warded: warded);
  final bloc = GameBloc(game: game, dungeon: node, stepDelay: Duration.zero);
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
Future<void> _pumpRoadFight(WidgetTester tester) async {
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
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
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

const _worstArena = '''
###########
#.........#
#.........#
#.........#
###########''';

/// The contract's worst case: the longest name, the bottom floor, two
/// monsters in sight with one holding reach, a warded caster hurt down to
/// critical — at phone width, where nothing may squeeze.
Future<void> _pumpWorstCase(
  WidgetTester tester, {
  TextScaler? textScaler,
}) async {
  await onAPhone(tester);
  final map = FloorMap.parse(_worstArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  final game = GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: 4,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: [
      Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: const Position(2, 1),
        hp: 10,
        maxHp: 10,
        attackMin: 3,
        attackMax: 3,
        speed: 10,
        energy: actThreshold,
      ),
      Actor(
        id: 'ghoul-2',
        name: 'the ghoul',
        glyph: 'g',
        position: const Position(8, 1),
        hp: 10,
        maxHp: 10,
        attackMin: 3,
        attackMax: 3,
        speed: 10,
        energy: actThreshold,
      ),
    ],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: 7,
    deepest: 7,
    spells: spellsById,
    knownSpells: const {'firebolt'},
    mana: 2,
    warded: 2,
  );
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final bloc = GameBloc(
    game: game,
    dungeon: ruinedKeep,
    stepDelay: Duration.zero,
  );
  final app = MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: town),
        BlocProvider.value(value: bloc),
      ],
      child: const GameScreen(palette: DungeonPalette.ruinedKeep),
    ),
  );
  await tester.pumpWidget(
    textScaler == null
        ? app
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: app,
          ),
  );
}

void main() {
  group('the crawl header names the place and its depth', () {
    testWidgets('names the sea-cave and the six floors it rolled', (
      tester,
    ) async {
      // arrange
      final rolled = delveDepth(seaCave, _pinnedSeed, 1);

      // act
      await _pumpCrawlAt(tester, seaCave);

      // assert
      expect(rolled, 6);
      expect(rolled, isNot(deepestDepth));
      expect(find.text('THE SEA-CAVE'), findsOneWidget);
      expect(find.text('1 / 6'), findsOneWidget);
    });

    testWidgets('names the keep and the seven floors it rolled', (
      tester,
    ) async {
      // arrange
      final rolled = delveDepth(ruinedKeep, _pinnedSeed, 1);

      // act
      await _pumpCrawlAt(tester, ruinedKeep);

      // assert
      expect(rolled, 7);
      expect(find.text('THE RUINED KEEP'), findsOneWidget);
      expect(find.text('1 / 7'), findsOneWidget);
    });

    testWidgets('still reads one of five in the crypt', (tester) async {
      // act
      await _pumpCrawlAt(tester, cryptNode);

      // assert
      expect(find.text('THE CRYPT'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
    });

    testWidgets('a road fight names the road and shows no depth', (
      tester,
    ) async {
      // act
      await _pumpRoadFight(tester);

      // assert
      expect(find.text('THE ROAD'), findsOneWidget);
      expect(find.byKey(depthPairKey), findsNothing);
    });
  });

  group('the resource row reads the hero as labelled meters', () {
    testWidgets('the hit points read as a labelled meter with the condition', (
      tester,
    ) async {
      // act
      await _pumpCrawlAt(tester, cryptNode);

      // assert
      expect(find.text('HP 20 / 20'), findsOneWidget);
      expect(find.text('Steady'), findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(hpMeterKey),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets("a hurt hero's meter and word follow the hit points", (
      tester,
    ) async {
      // act
      await _pumpCrawlAt(tester, cryptNode, hp: 4);

      // assert
      expect(find.text('HP 4 / 20'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(hpMeterKey),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(indicator.value, 0.2);
    });
    testWidgets('a dead hero is named without changing the meter contract', (
      tester,
    ) async {
      await _pumpCrawlAt(tester, cryptNode, hp: 0);

      expect(find.byKey(hpMeterKey), findsOneWidget);
      expect(find.text('HP 0 / 20'), findsOneWidget);
      expect(find.text('Dead'), findsOneWidget);
    });

    testWidgets('no mana meter until the hero knows a spell', (tester) async {
      // act
      await _pumpCrawlAt(tester, cryptNode);

      // assert
      expect(find.byKey(manaMeterKey), findsNothing);
      expect(find.textContaining('Mana'), findsNothing);
      expect(find.byKey(hpMeterKey), findsOneWidget);
    });

    testWidgets('the mana meter reads its own pool', (tester) async {
      // act
      await _pumpCrawlAt(
        tester,
        cryptNode,
        knownSpells: const {'firebolt'},
        mana: 2,
      );

      // assert
      expect(find.text('Mana 2 / 4'), findsOneWidget);
      final hpIndicator = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(hpMeterKey),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      final manaIndicator = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(manaMeterKey),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(manaIndicator.value, 0.5);
      expect(manaIndicator.value, isNot(hpIndicator.value));
    });

    testWidgets('the ward reads beside the pool while one stands', (
      tester,
    ) async {
      // act
      await _pumpCrawlAt(
        tester,
        cryptNode,
        knownSpells: const {'firebolt'},
        warded: 2,
      );

      // assert
      expect(find.text('Ward 2'), findsOneWidget);
    });

    testWidgets('no ward when none stands', (tester) async {
      // act
      await _pumpCrawlAt(tester, cryptNode, knownSpells: const {'firebolt'});

      // assert
      expect(find.textContaining('Ward'), findsNothing);
    });
  });

  group('the worst case', () {
    testWidgets('fits a phone without squeezing anything', (tester) async {
      // act
      await _pumpWorstCase(tester);

      // assert
      expect(tester.takeException(), isNull);
      expect(find.text('THE RUINED KEEP'), findsOneWidget);
      expect(find.text('✖'), findsOneWidget);
      expect(find.text('Engaged 2'), findsOneWidget);
      expect(find.text('HP 4 / 20'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Ward 2'), findsOneWidget);

      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(CrawlStatus),
          matching: find.byType(Text),
        ),
      );
      for (final paragraph in paragraphs) {
        expect(
          paragraph.size.width + 0.5,
          greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
        );
      }
    });
    testWidgets('keeps the longest factual row legible at 1.3x text scale', (
      tester,
    ) async {
      await _pumpWorstCase(tester, textScaler: TextScaler.linear(1.3));

      expect(tester.takeException(), isNull);
      expect(find.text('THE RUINED KEEP'), findsOneWidget);
      expect(find.text('✖'), findsOneWidget);
      expect(find.text('Engaged 2'), findsOneWidget);
      expect(find.byKey(depthPairKey), findsOneWidget);
      expect(find.text('HP 4 / 20'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Mana 2 / 4'), findsOneWidget);
      expect(find.text('Ward 2'), findsOneWidget);

      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(CrawlStatus),
          matching: find.byType(Text),
        ),
      );
      for (final paragraph in paragraphs) {
        expect(
          paragraph.size.width + 0.5,
          greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
        );
      }
    });
  });

  group('the battle meter keys move to the combat panel', () {
    testWidgets('the combat panel, not the hero panel, carries hpMeterKey and '
        'manaMeterKey while a battle is open', (tester) async {
      // act - the worst case's ghoul-1 stands adjacent, so battle is open
      await _pumpWorstCase(tester);

      // assert
      expect(find.byType(HeroPanel), findsNothing);
      expect(find.byType(CombatPanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CombatPanel),
          matching: find.byKey(hpMeterKey),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CombatPanel),
          matching: find.byKey(manaMeterKey),
        ),
        findsOneWidget,
      );
    });
  });
}
