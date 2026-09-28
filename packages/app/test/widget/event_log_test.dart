import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/action_bar.dart';
import 'package:residuum_app/game/crawl_hud.dart';
import 'package:residuum_app/game/crawl_menu.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/event_log.dart';
import 'package:residuum_app/game/event_messages.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/log_line.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
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

GameState _game({
  Position heroAt = _heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: heroId,
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: heroHp,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

Actor _ghoul(Position at, {String id = 'ghoul-1', int attack = 3}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
  speed: 10,
  energy: actThreshold,
);

List<LogLine> _manyLines(int count) => [
  for (var i = 0; i < count; i++) LogLine('Line $i.', LogCategory.moved),
];

/// A corridor far taller than any test surface, so a hero placed near its
/// top always has real floor spanning the whole viewport below it.
String _corridorArena(int rows) => List.generate(
  rows,
  (row) => row == 0 || row == rows - 1 ? '#######' : '#.....#',
).join('\n');

const _corridorHeroAt = Position(3, 2);

GameState _corridorGame() {
  final map = FloorMap.parse(_corridorArena(80));
  final visible = computeFov(map, _corridorHeroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: heroId,
      name: 'you',
      glyph: '@',
      position: _corridorHeroAt,
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
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

Finder _inStrip(String text) =>
    find.descendant(of: find.byKey(eventsStripKey), matching: find.text(text));

Finder _inPage(String text) =>
    find.descendant(of: find.byKey(logPageKey), matching: find.text(text));

Finder _pageList() => find.descendant(
  of: find.byKey(logPageKey),
  matching: find.byType(ListView),
);

GridGeometry _geometryFor(WidgetTester tester, GameViewState state) =>
    GridGeometry.camera(
      tester.getSize(find.byKey(dungeonSceneSlotKey)),
      state.game.map.width,
      state.game.map.height,
      state.cameraFocus,
      state.pan,
    );

Future<void> _tapLocal(WidgetTester tester, Offset local) async {
  final topLeft = tester.getTopLeft(find.byKey(dungeonSceneSlotKey));
  await tester.tapAt(topLeft + local);
}

Future<void> _dragLocal(WidgetTester tester, Offset local, Offset delta) async {
  final topLeft = tester.getTopLeft(find.byKey(dungeonSceneSlotKey));
  await tester.dragFrom(topLeft + local, delta);
}

Future<void> _openViaStrip(WidgetTester tester) async {
  await tester.tap(find.byKey(eventsStripKey));
  await tester.pumpAndSettle();
}

/// Pushes the real [GameScreen] over the real [bloc], following
/// `turn_order_strip_test.dart`'s shape: `MaterialApp` → `TextButton` → a
/// pushed `MultiBlocProvider` carrying a fresh `TownBloc` alongside it.
/// [textScaler] feeds the ambient `MediaQuery` `GameScreen`'s own
/// `MediaQuery.withClampedTextScaling` clamps against, the same knob a
/// physical device's system text size would turn.
Future<void> _pushGame(
  WidgetTester tester,
  GameBloc bloc, {
  TextScaler? textScaler,
}) async {
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final app = MaterialApp(
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
  );
  await tester.pumpWidget(
    textScaler == null
        ? app
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: app,
          ),
  );
  await tester.tap(find.text('down'));
  await tester.pumpAndSettle();
}

void main() {
  group('strip geometry', () {
    testWidgets('the strip runs the map\'s full width along its bottom edge in '
        'exploration', (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final strip = tester
          .getRect(find.byKey(eventsStripKey))
          .shift(-mapRect.topLeft);
      expect(strip.left, 0);
      expect(strip.width, closeTo(mapRect.width, 0.01));
      expect(strip.bottom, closeTo(mapRect.height, 0.01));
      expect(strip.height, closeTo(55.0, 0.01));
    });

    testWidgets(
      'the strip runs the map\'s full width along its bottom edge when '
      'Watched',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(monsters: [_ghoul(const Position(4, 2))]),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
        final strip = tester
            .getRect(find.byKey(eventsStripKey))
            .shift(-mapRect.topLeft);
        expect(strip.left, 0);
        expect(strip.width, closeTo(mapRect.width, 0.01));
        expect(strip.bottom, closeTo(mapRect.height, 0.01));
        expect(strip.height, closeTo(55.0, 0.01));
      },
    );

    testWidgets('the strip runs the map\'s full width along its bottom edge in '
        'battle', (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(monsters: [_ghoul(_adjacentToHero)]),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final strip = tester
          .getRect(find.byKey(eventsStripKey))
          .shift(-mapRect.topLeft);
      expect(strip.left, 0);
      expect(strip.width, closeTo(mapRect.width, 0.01));
      expect(strip.bottom, closeTo(mapRect.height, 0.01));
      expect(strip.height, closeTo(55.0, 0.01));
    });

    testWidgets('the strip grows with the clamp at 1.3x text scale', (
      tester,
    ) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc, textScaler: const TextScaler.linear(1.3));

      expect(
        tester.getRect(find.byKey(eventsStripKey)).height,
        closeTo(68.5, 0.01),
      );
    });
  });

  group('lines', () {
    testWidgets(
      'the last three lines render oldest to newest, bottom-anchored, with '
      'the right fade and tint, and no title, count or border',
      (tester) async {
        await onTheTargetPhone(tester);
        const newest =
            'The narrow stair opens into cold air and settles '
            'shut.';
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Line one drops away.', LogCategory.moved),
            LogLine('Line two settles in the dust.', LogCategory.moved),
            LogLine('Line three echoes softly.', LogCategory.noticed),
            LogLine('Line four rattles the bones.', LogCategory.hit),
            LogLine(newest, LogCategory.hit),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        final strip = find.byKey(eventsStripKey);
        expect(
          find.descendant(of: strip, matching: find.text('RECENT EVENTS')),
          findsNothing,
        );
        expect(
          find.descendant(of: strip, matching: find.textContaining('entries')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: strip,
            matching: find.byWidgetPredicate((widget) {
              if (widget is! DecoratedBox) return false;
              final decoration = widget.decoration;
              return decoration is BoxDecoration && decoration.border != null;
            }),
          ),
          findsNothing,
        );

        expect(_inStrip('Line one drops away.'), findsNothing);
        expect(_inStrip('Line two settles in the dust.'), findsNothing);
        final shown = [
          'Line three echoes softly.',
          'Line four rattles the bones.',
          newest,
        ];
        final tops = [
          for (final sentence in shown)
            tester.getTopLeft(_inStrip(sentence)).dy,
        ];
        for (var i = 1; i < tops.length; i++) {
          expect(tops[i], greaterThan(tops[i - 1]));
        }
        Opacity opacityOf(String sentence) => tester.widget<Opacity>(
          find.ancestor(of: _inStrip(sentence), matching: find.byType(Opacity)),
        );
        expect(
          opacityOf('Line three echoes softly.').opacity,
          closeTo(0.45, 0.001),
        );
        expect(
          opacityOf('Line four rattles the bones.').opacity,
          closeTo(0.7, 0.001),
        );
        expect(opacityOf(newest).opacity, closeTo(1.0, 0.001));

        expect(
          tester.widget<Text>(_inStrip('Line three echoes softly.')).style,
          logTint(LogCategory.noticed),
        );
        expect(
          tester.widget<Text>(_inStrip('Line four rattles the bones.')).style,
          logTint(LogCategory.hit),
        );
        expect(
          tester.widget<Text>(_inStrip(newest)).style,
          logTint(LogCategory.hit),
        );
      },
    );

    testWidgets('a single line sits in the bottom slot', (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      final stripRect = tester.getRect(find.byKey(eventsStripKey));
      final lineRect = tester.getRect(_inStrip('Something is on the road.'));
      expect(lineRect.top, greaterThan(stripRect.top + stripRect.height / 2));
    });

    testWidgets('the three lines stay unclipped at 1.3x text scale', (
      tester,
    ) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: _manyLines(4),
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc, textScaler: const TextScaler.linear(1.3));

      const scaler = TextScaler.linear(1.3);
      double naturalHeight(Finder finder) {
        final text = tester.widget<Text>(finder);
        final painter = TextPainter(
          text: TextSpan(text: text.data, style: text.style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        return painter.height;
      }

      for (var i = 1; i < 4; i++) {
        final finder = _inStrip('Line $i.');
        expect(
          tester.getSize(finder).height,
          greaterThanOrEqualTo(naturalHeight(finder) - 0.5),
          reason: 'strip line $i clips at 1.3x text scale',
        );
      }
    });
  });

  group('input', () {
    testWidgets('an empty log renders no strip, and a tap at the centre of the '
        "map's bottom 55 dp band on a floor cell reaches the map", (
      tester,
    ) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(game: _corridorGame(), stepDelay: Duration.zero);
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      expect(find.byKey(eventsStripKey), findsNothing);

      final mapSize = tester.getSize(find.byKey(dungeonSceneSlotKey));
      await _tapLocal(tester, Offset(mapSize.width / 2, mapSize.height - 27.5));
      await tester.pumpAndSettle();

      expect(
        bloc.state.game.hero.position != _corridorHeroAt ||
            bloc.state.isWalking,
        isTrue,
      );
    });

    testWidgets(
      'with lines, a tap inside the strip opens the page and leaves the '
      'hero in place',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        final heroBefore = bloc.state.game.hero.position;
        await _openViaStrip(tester);

        expect(find.byKey(logPageKey), findsOneWidget);
        expect(bloc.state.game.hero.position, heroBefore);
      },
    );

    testWidgets(
      'a tap on the floor cell just above the strip, next to the hero, '
      'steps',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        final geometry = _geometryFor(tester, bloc.state);
        const north = Position(2, 1);
        final northRect = geometry.rectOf(north);
        final mapSize = tester.getSize(find.byKey(dungeonSceneSlotKey));
        expect(northRect.bottom, lessThan(mapSize.height - 55.0));

        await _tapLocal(tester, northRect.center);
        await tester.pumpAndSettle();

        expect(bloc.state.game.hero.position, north);
      },
    );

    testWidgets('a drag that starts above the strip pans', (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      final geometry = _geometryFor(tester, bloc.state);
      final heroCentre = geometry.centreOf(_heroAt);
      final mapSize = tester.getSize(find.byKey(dungeonSceneSlotKey));
      expect(heroCentre.dy, lessThan(mapSize.height - 55.0));

      await _dragLocal(tester, heroCentre, const Offset(0, -40));
      await tester.pumpAndSettle();

      expect(bloc.state.pan, isNot(Offset.zero));
    });

    testWidgets('once the game is over, the strip\'s tap is inert', (
      tester,
    ) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(heroHp: 2, monsters: [_ghoul(_adjacentToHero)]),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      bloc.add(const TileTapped(_adjacentToHero));
      await tester.pumpAndSettle();
      expect(bloc.state.game.isGameOver, isTrue);

      await tester.tap(find.byKey(eventsStripKey), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(bloc.state.logOpen, isFalse);
      expect(find.byKey(logPageKey), findsNothing);
    });
  });

  group('page', () {
    testWidgets(
      'the page fills the SafeArea body and covers the HUD, bar and menu',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        final hud = tester.getRect(find.byKey(crawlHudKey));
        final menu = tester.getRect(find.byKey(crawlMenuKey));
        final surfaceHeight =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final surfaceWidth =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;

        await _openViaStrip(tester);

        final page = tester.getRect(find.byKey(logPageKey));
        expect(page.left, 0);
        expect(page.width, closeTo(surfaceWidth, 0.01));
        expect(page.top, closeTo(34.9, 0.5));
        expect(page.bottom, closeTo(surfaceHeight - crawlGestureClear, 0.5));
        expect(page.top, lessThanOrEqualTo(hud.top));
        expect(page.bottom, greaterThanOrEqualTo(menu.bottom));
      },
    );

    testWidgets(
      'a tap on the map area while the page is open does not move the hero',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        final heroBefore = bloc.state.game.hero.position;
        await _openViaStrip(tester);

        final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
        await tester.tapAt(mapRect.center);
        await tester.pumpAndSettle();

        expect(bloc.state.game.hero.position, heroBefore);
        expect(find.byKey(logPageKey), findsOneWidget);
      },
    );

    testWidgets(
      'the close control is at least 48 dp square and closes the page',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);
        final closeRect = tester.getRect(find.byKey(logCloseKey));
        expect(closeRect.width, greaterThanOrEqualTo(48));
        expect(closeRect.height, greaterThanOrEqualTo(48));

        await tester.tap(find.byKey(logCloseKey));
        await tester.pumpAndSettle();
        expect(find.byKey(logPageKey), findsNothing);
        expect(find.byKey(eventsStripKey), findsOneWidget);
      },
    );

    testWidgets(
      'system back while the page is open closes it and appends no line',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);
        final lengthBefore = bloc.state.log.length;

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byKey(logPageKey), findsNothing);
        expect(bloc.state.log.length, lengthBefore);
      },
    );

    testWidgets('system back while the page is closed appends the refusal', (
      tester,
    ) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(game: _game(), stepDelay: Duration.zero);
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(bloc.state.log, [
        const LogLine('You can only leave at the stairs.', LogCategory.refused),
      ]);
    });

    testWidgets(
      'the map, bar and menu rects are unchanged before, during and after '
      'the page',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
        final barRect = tester.getRect(find.byKey(actionBarKey));
        final menuRect = tester.getRect(find.byKey(crawlMenuKey));

        await _openViaStrip(tester);
        expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
        expect(tester.getRect(find.byKey(actionBarKey)), barRect);
        expect(tester.getRect(find.byKey(crawlMenuKey)), menuRect);

        await tester.tap(find.byKey(logCloseKey));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
        expect(tester.getRect(find.byKey(actionBarKey)), barRect);
        expect(tester.getRect(find.byKey(crawlMenuKey)), menuRect);
      },
    );

    testWidgets(
      'the header shows the title and the true entry count, oldest to '
      'newest',
      (tester) async {
        await onTheTargetPhone(tester);
        const newest =
            'The narrow stair opens into cold air and settles '
            'shut.';
        final bloc = GameBloc(
          game: _game(),
          log: [
            const LogLine('Line one drops away.', LogCategory.moved),
            const LogLine('Line two settles in the dust.', LogCategory.moved),
            LogLine(newest, LogCategory.hit),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);
        expect(_inPage('RECENT EVENTS'), findsOneWidget);
        expect(_inPage('3 entries'), findsOneWidget);

        final pageRect = tester.getRect(find.byKey(logPageKey));
        final first = tester.getTopLeft(_inPage('Line one drops away.'));
        final last = tester.getTopLeft(_inPage(newest));
        final lastRect = tester.getRect(_inPage(newest));
        expect(first.dy, lessThan(last.dy));
        expect(lastRect.top, greaterThanOrEqualTo(pageRect.top));
        expect(lastRect.bottom, lessThanOrEqualTo(pageRect.bottom));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('every category pictogram and word appears, and the strip '
        'shows none', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await onTheTargetPhone(tester);
        final seeded = [
          for (final category in LogCategory.values)
            LogLine('${category.name} happened.', category),
        ];
        final bloc = GameBloc(
          game: _game(),
          log: seeded,
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        for (final category in LogCategory.values) {
          expect(
            find.descendant(
              of: find.byKey(eventsStripKey),
              matching: find.byIcon(logPictogram(category)),
            ),
            findsNothing,
            reason: 'no pictogram for ${category.name} in the strip',
          );
        }

        await _openViaStrip(tester);
        expect(_inPage('RECENT EVENTS'), findsOneWidget);
        expect(_inPage('${seeded.length} entries'), findsOneWidget);

        for (final category in LogCategory.values) {
          expect(
            find.descendant(
              of: find.byKey(logPageKey),
              matching: find.byIcon(logPictogram(category)),
            ),
            findsWidgets,
            reason: 'pictogram for ${category.name}',
          );
          expect(
            find.bySemanticsLabel(
              RegExp('^${RegExp.escape(category.word)}\\. '),
            ),
            findsWidgets,
            reason: 'word for ${category.name}',
          );
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      "each row's pictogram shares its sentence's tint, and only older "
      'rows dim',
      (tester) async {
        await onTheTargetPhone(tester);
        const seeded = [
          LogLine('First line.', LogCategory.moved),
          LogLine('Second line.', LogCategory.hit),
          LogLine('Third line.', LogCategory.struck),
        ];
        final bloc = GameBloc(
          game: _game(),
          log: seeded,
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);

        final newestSentence = tester.widget<Text>(_inPage('Third line.'));
        final newestIcon = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(logPageKey),
            matching: find.byIcon(logPictogram(LogCategory.struck)),
          ),
        );
        final olderSentence = tester.widget<Text>(_inPage('First line.'));
        final olderIcon = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(logPageKey),
            matching: find.byIcon(logPictogram(LogCategory.moved)),
          ),
        );

        expect(newestIcon.color, newestSentence.style!.color);
        expect(olderIcon.color, olderSentence.style!.color);

        double pageRowOpacity(String sentence) {
          final opacityAncestor = find.ancestor(
            of: _inPage(sentence),
            matching: find.byType(Opacity),
          );
          return opacityAncestor.evaluate().isEmpty
              ? 1
              : tester.widget<Opacity>(opacityAncestor).opacity;
        }

        expect(
          pageRowOpacity('First line.'),
          lessThan(pageRowOpacity('Third line.')),
        );
      },
    );

    testWidgets("a row's pictogram sits left of its sentence, inside the "
        'page', (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      await _openViaStrip(tester);

      final iconRect = tester.getRect(
        find.descendant(
          of: find.byKey(logPageKey),
          matching: find.byIcon(logPictogram(LogCategory.noticed)),
        ),
      );
      final sentenceRect = tester.getRect(_inPage('Something is on the road.'));
      final pageRect = tester.getRect(find.byKey(logPageKey));
      expect(iconRect.right, lessThanOrEqualTo(sentenceRect.left));
      expect(iconRect.left, greaterThanOrEqualTo(pageRect.left));
    });

    testWidgets('follow holds the reader at newest while active', (
      tester,
    ) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: _manyLines(60),
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      await _openViaStrip(tester);
      expect(bloc.state.logOpen, isTrue);

      bloc.add(const WaitPressed());
      await tester.pumpAndSettle();

      expect(find.byKey(logUnreadKey), findsNothing);
      expect(_inPage('You hold your ground.'), findsOneWidget);
      final pageRect = tester.getRect(find.byKey(logPageKey));
      final newestRowRect = tester.getRect(_inPage('You hold your ground.'));
      expect(newestRowRect.top, greaterThanOrEqualTo(pageRect.top - 0.5));
      expect(newestRowRect.bottom, lessThanOrEqualTo(pageRect.bottom + 0.5));
    });

    testWidgets(
      'scrolling away breaks follow, the unread count is exact, and the '
      'viewport does not move',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: _manyLines(60),
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);

        await tester.drag(_pageList(), const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(bloc.state.logFollowing, isFalse);

        final visibleLineRows = find.descendant(
          of: find.byKey(logPageKey),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text && (widget.data?.startsWith('Line ') ?? false),
          ),
        );
        final anchorText = tester.widgetList<Text>(visibleLineRows).first.data!;
        final anchor = _inPage(anchorText);
        final anchorTopBefore = tester.getTopLeft(anchor).dy;
        final lengthBefore = bloc.state.log.length;

        bloc.add(const WaitPressed());
        bloc.add(const WaitPressed());
        await tester.pumpAndSettle();
        final delta = bloc.state.log.length - lengthBefore;

        expect(tester.getTopLeft(anchor).dy, anchorTopBefore);
        expect(find.byKey(logUnreadKey), findsOneWidget);
        expect(_inPage('↓ $delta new'), findsOneWidget);
      },
    );

    testWidgets('the unread affordance returns to newest and resumes follow', (
      tester,
    ) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: _manyLines(60),
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      await _openViaStrip(tester);
      await tester.drag(_pageList(), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(bloc.state.logFollowing, isFalse);

      bloc.add(const WaitPressed());
      await tester.pumpAndSettle();
      expect(find.byKey(logUnreadKey), findsOneWidget);

      await tester.tap(find.byKey(logUnreadKey));
      await tester.pumpAndSettle();

      expect(find.byKey(logUnreadKey), findsNothing);
      expect(bloc.state.logFollowing, isTrue);
      expect(_inPage('You hold your ground.'), findsOneWidget);
    });

    testWidgets(
      'scrolling back to newest resumes follow without the affordance '
      'being used',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: _manyLines(60),
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);
        await tester.drag(_pageList(), const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(bloc.state.logFollowing, isFalse);

        bloc.add(const WaitPressed());
        await tester.pumpAndSettle();
        expect(find.byKey(logUnreadKey), findsOneWidget);

        await tester.drag(_pageList(), const Offset(0, -2000));
        await tester.pumpAndSettle();

        expect(find.byKey(logUnreadKey), findsNothing);
        expect(bloc.state.logFollowing, isTrue);
      },
    );

    testWidgets(
      'an empty log renders the page at phone size without exception, '
      'opened directly',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(game: _game(), stepDelay: Duration.zero);
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        expect(find.byKey(eventsStripKey), findsNothing);

        bloc.add(const LogOpened());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(logPageKey), findsOneWidget);
        expect(_inPage('RECENT EVENTS'), findsOneWidget);
        expect(_inPage('0 entries'), findsOneWidget);

        await tester.tap(find.byKey(logCloseKey));
        await tester.pumpAndSettle();
        expect(find.byKey(logPageKey), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a one-line log renders the page at phone size without exception',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(logPageKey), findsOneWidget);

        await tester.tap(find.byKey(logCloseKey));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'death closes the page, inerts the strip, and the death overlay '
      'stays reachable',
      (tester) async {
        await onTheTargetPhone(tester);
        final bloc = GameBloc(
          game: _game(heroHp: 2, monsters: [_ghoul(_adjacentToHero)]),
          log: const [
            LogLine('Something is on the road.', LogCategory.noticed),
          ],
          stepDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await _pushGame(tester, bloc);

        await _openViaStrip(tester);
        expect(find.byKey(logPageKey), findsOneWidget);

        bloc.add(const TileTapped(_adjacentToHero));
        await tester.pumpAndSettle();
        expect(bloc.state.game.isGameOver, isTrue);

        expect(find.byKey(logPageKey), findsNothing);
        expect(find.byKey(eventsStripKey), findsOneWidget);

        await tester.tap(find.byKey(eventsStripKey), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byKey(logPageKey), findsNothing);

        final deathButton = find.text('Return to town');
        expect(deathButton, findsOneWidget);
        await tester.tap(deathButton);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
