import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/event_messages.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/log_drawer.dart';
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

Finder _inDrawer(String text) =>
    find.descendant(of: find.byKey(logDrawerKey), matching: find.text(text));

Finder _inPeek(String text) =>
    find.descendant(of: find.byKey(logPeekKey), matching: find.text(text));

Finder _drawerList() => find.descendant(
  of: find.byKey(logDrawerKey),
  matching: find.byType(ListView),
);

/// Pushes the real [GameScreen] over the real [bloc], following
/// `battle_view_test.dart`'s shape: `MaterialApp` → `TextButton` → a pushed
/// `MultiBlocProvider` carrying a fresh `TownBloc` alongside it.
Future<void> _pushGame(WidgetTester tester, GameBloc bloc) async {
  final town = TownBloc(profile: newProfile(worldSeed: 5));
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
}

void main() {
  testWidgets('the peek renders above the controls', (tester) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(
      game: _game(),
      log: const [LogLine('Something is on the road.', LogCategory.noticed)],
      stepDelay: Duration.zero,
    );
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);

    final peekTop = tester.getTopLeft(find.byKey(logPeekKey)).dy;
    final controlsTop = tester.getTopLeft(find.byKey(actionRowKey)).dy;
    expect(peekTop, lessThan(controlsTop));
  });

  testWidgets('the handle takes the drawer through peek, half, full, and back, '
      'never reflowing the map, and the drawer keeps to the fixed chrome', (
    tester,
  ) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(
      game: _game(),
      log: _manyLines(2),
      stepDelay: Duration.zero,
    );
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);

    final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
    final peekRect = tester.getRect(find.byKey(logPeekKey));
    final actionRect = tester.getRect(find.byKey(actionRowKey));
    void reportStableCrawlGeometry(String extent) {
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
      expect(tester.getRect(find.byKey(logPeekKey)), peekRect);
      expect(tester.getRect(find.byKey(actionRowKey)), actionRect);
      debugPrint(
        'U16 log $extent map=$mapRect peek=$peekRect action=$actionRect',
      );
    }

    expect(peekRect.height, crawlEventsHeight);
    reportStableCrawlGeometry('closed');
    // The inner Stack's own height: the map, both gaps and the peek fill
    // it exactly at the peek extent, before any drawer overlay exists.
    final overlayHeight = mapRect.height + 2 * crawlGap + peekRect.height;

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    expect(find.byKey(logDrawerKey), findsOneWidget);
    reportStableCrawlGeometry('half');
    final halfRect = tester.getRect(find.byKey(logDrawerKey));
    expect(
      halfRect.height,
      closeTo(math.min(crawlLogSheetHeight, overlayHeight), 0.5),
    );
    expect(halfRect.bottom, closeTo(actionRect.top, 0.5));

    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(logDrawerKey), findsOneWidget);
    reportStableCrawlGeometry('full');
    final fullRect = tester.getRect(find.byKey(logDrawerKey));
    expect(fullRect.top, closeTo(mapRect.top, 0.5));
    expect(fullRect.bottom, closeTo(actionRect.top, 0.5));
    expect(fullRect.top, lessThan(halfRect.top));

    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(logDrawerKey), findsNothing);
    reportStableCrawlGeometry('closed');
  });

  testWidgets(
    'recent events keep a real latest sentence visible, oldest to newest, '
    'and both the peek and the drawer report the true entry count',
    (tester) async {
      await onTheTargetPhone(tester);
      const newest = 'The narrow stair opens into cold air and settles shut.';
      expect(newest.length, 54);
      final bloc = GameBloc(
        game: _game(),
        log: const [
          LogLine('Line one drops away.', LogCategory.moved),
          LogLine('Line two settles in the dust.', LogCategory.moved),
          LogLine('Line three echoes softly.', LogCategory.noticed),
          LogLine('Line four rattles the bones.', LogCategory.hit),
          LogLine('Line five: a distant cry.', LogCategory.noticed),
          LogLine(newest, LogCategory.hit),
        ],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      final peek = find.byKey(logPeekKey);
      expect(tester.getRect(peek).height, crawlEventsHeight);
      expect(
        find.descendant(of: peek, matching: find.text('RECENT EVENTS')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: peek, matching: find.text('6 entries')),
        findsOneWidget,
      );

      // Only the last four lines show, oldest to newest top to bottom.
      expect(_inPeek('Line one drops away.'), findsNothing);
      expect(_inPeek('Line two settles in the dust.'), findsNothing);
      final shown = [
        'Line three echoes softly.',
        'Line four rattles the bones.',
        'Line five: a distant cry.',
        newest,
      ];
      final tops = [
        for (final sentence in shown) tester.getTopLeft(_inPeek(sentence)).dy,
      ];
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i], greaterThan(tops[i - 1]));
      }
      final peekRect = tester.getRect(peek);
      for (final sentence in shown) {
        final text = tester.widget<Text>(_inPeek(sentence));
        expect(text.maxLines, 1);
        final rect = tester.getRect(_inPeek(sentence));
        expect(rect.top, greaterThanOrEqualTo(peekRect.top));
        expect(rect.bottom, lessThanOrEqualTo(peekRect.bottom));
      }
      Opacity opacityOf(String sentence) => tester.widget<Opacity>(
        find.ancestor(of: _inPeek(sentence), matching: find.byType(Opacity)),
      );
      expect(opacityOf(newest).opacity, 1);
      expect(opacityOf('Line three echoes softly.').opacity, 0.72);
      expect(opacityOf('Line four rattles the bones.').opacity, 0.72);
      expect(opacityOf('Line five: a distant cry.').opacity, 0.72);

      await tester.tap(peek);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(_inDrawer('RECENT EVENTS'), findsOneWidget);
      expect(_inDrawer('6 entries'), findsOneWidget);

      final drawerRect = tester.getRect(find.byKey(logDrawerKey));
      final first = tester.getTopLeft(_inDrawer('Line one drops away.'));
      final last = tester.getTopLeft(_inDrawer(newest));
      final lastRect = tester.getRect(_inDrawer(newest));
      expect(first.dy, lessThan(last.dy));
      expect(lastRect.top, greaterThanOrEqualTo(drawerRect.top));
      expect(lastRect.bottom, lessThanOrEqualTo(drawerRect.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the close affordance collapses from full', (tester) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(game: _game(), stepDelay: Duration.zero);
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();
    expect(bloc.state.logDrawerExtent, LogDrawerExtent.full);

    await tester.tap(find.byKey(logCloseKey));
    await tester.pumpAndSettle();
    expect(find.byKey(logDrawerKey), findsNothing);
    expect(find.byKey(logPeekKey), findsOneWidget);
  });

  testWidgets('the expanded log shows every category pictogram and word, '
      'and the peek shows none', (tester) async {
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
            of: find.byKey(logPeekKey),
            matching: find.byIcon(logPictogram(category)),
          ),
          findsNothing,
          reason: 'no pictogram for ${category.name} in the peek',
        );
      }

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(bloc.state.logDrawerExtent, LogDrawerExtent.full);
      expect(_inDrawer('RECENT EVENTS'), findsOneWidget);
      expect(_inDrawer('${seeded.length} entries'), findsOneWidget);

      for (final category in LogCategory.values) {
        expect(
          find.descendant(
            of: find.byKey(logDrawerKey),
            matching: find.byIcon(logPictogram(category)),
          ),
          findsWidgets,
          reason: 'pictogram for ${category.name}',
        );
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(category.word)}\\. ')),
          findsWidgets,
          reason: 'word for ${category.name}',
        );
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    "each row's pictogram shares its sentence's tint, and only older rows "
    'dim',
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

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();

      final newestSentence = tester.widget<Text>(_inDrawer('Third line.'));
      final newestIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(logDrawerKey),
          matching: find.byIcon(logPictogram(LogCategory.struck)),
        ),
      );
      final olderSentence = tester.widget<Text>(_inDrawer('First line.'));
      final olderIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(logDrawerKey),
          matching: find.byIcon(logPictogram(LogCategory.moved)),
        ),
      );

      expect(newestIcon.color, newestSentence.style!.color);
      expect(olderIcon.color, olderSentence.style!.color);

      final olderOpacity = tester.widget<Opacity>(
        find.ancestor(
          of: _inDrawer('First line.'),
          matching: find.byType(Opacity),
        ),
      );
      expect(olderOpacity.opacity, 0.78);
      expect(
        find.ancestor(
          of: _inDrawer('Third line.'),
          matching: find.byWidgetPredicate(
            (widget) => widget is Opacity && widget.opacity == 0.78,
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'the peek renders an expand affordance and shows no category pictogram',
    (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      expect(
        find.descendant(
          of: find.byKey(logPeekKey),
          matching: find.byIcon(Icons.unfold_more),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(logPeekKey),
          matching: find.byIcon(logPictogram(LogCategory.noticed)),
        ),
        findsNothing,
      );
    },
  );

  testWidgets("a row's pictogram sits left of its sentence, inside the "
      'sheet', (tester) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(
      game: _game(),
      log: const [LogLine('Something is on the road.', LogCategory.noticed)],
      stepDelay: Duration.zero,
    );
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();

    final iconRect = tester.getRect(
      find.descendant(
        of: find.byKey(logDrawerKey),
        matching: find.byIcon(logPictogram(LogCategory.noticed)),
      ),
    );
    final sentenceRect = tester.getRect(_inDrawer('Something is on the road.'));
    final drawerRect = tester.getRect(find.byKey(logDrawerKey));
    expect(iconRect.right, lessThanOrEqualTo(sentenceRect.left));
    expect(iconRect.left, greaterThanOrEqualTo(drawerRect.left));
  });

  testWidgets('the action bar stays hit-testable while the drawer is open', (
    tester,
  ) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(
      game: _game(monsters: [_ghoul(_adjacentToHero)]),
      stepDelay: Duration.zero,
    );
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);
    expect(find.text('Wait'), findsOneWidget);

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    expect(bloc.state.logDrawerExtent, LogDrawerExtent.half);

    await tester.tap(find.text('Wait'));
    await tester.pumpAndSettle();

    expect(_inDrawer('You hold your ground.'), findsOneWidget);
  });

  testWidgets('follow holds the reader at newest while active', (tester) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(
      game: _game(),
      log: _manyLines(60),
      stepDelay: Duration.zero,
    );
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    expect(bloc.state.logDrawerExtent, LogDrawerExtent.half);

    bloc.add(const WaitPressed());
    await tester.pumpAndSettle();

    expect(find.byKey(logUnreadKey), findsNothing);
    expect(_inDrawer('You hold your ground.'), findsOneWidget);
    final drawerRect = tester.getRect(find.byKey(logDrawerKey));
    final newestRowRect = tester.getRect(_inDrawer('You hold your ground.'));
    expect(newestRowRect.top, greaterThanOrEqualTo(drawerRect.top - 0.5));
    expect(newestRowRect.bottom, lessThanOrEqualTo(drawerRect.bottom + 0.5));
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

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();

      await tester.drag(_drawerList(), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(bloc.state.logFollowing, isFalse);

      final visibleLineRows = find.descendant(
        of: find.byKey(logDrawerKey),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data?.startsWith('Line ') ?? false),
        ),
      );
      final anchorText = tester.widgetList<Text>(visibleLineRows).first.data!;
      final anchor = _inDrawer(anchorText);
      final anchorTopBefore = tester.getTopLeft(anchor).dy;
      final lengthBefore = bloc.state.log.length;

      bloc.add(const WaitPressed());
      bloc.add(const WaitPressed());
      await tester.pumpAndSettle();
      final delta = bloc.state.log.length - lengthBefore;

      expect(tester.getTopLeft(anchor).dy, anchorTopBefore);
      expect(find.byKey(logUnreadKey), findsOneWidget);
      expect(_inDrawer('↓ $delta new'), findsOneWidget);
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

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    await tester.drag(_drawerList(), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(bloc.state.logFollowing, isFalse);

    bloc.add(const WaitPressed());
    await tester.pumpAndSettle();
    expect(find.byKey(logUnreadKey), findsOneWidget);

    await tester.tap(find.byKey(logUnreadKey));
    await tester.pumpAndSettle();

    expect(find.byKey(logUnreadKey), findsNothing);
    expect(bloc.state.logFollowing, isTrue);
    expect(_inDrawer('You hold your ground.'), findsOneWidget);
  });

  testWidgets(
    'scrolling back to newest resumes follow without the affordance being '
    'used',
    (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: _manyLines(60),
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();
      await tester.drag(_drawerList(), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(bloc.state.logFollowing, isFalse);

      bloc.add(const WaitPressed());
      await tester.pumpAndSettle();
      expect(find.byKey(logUnreadKey), findsOneWidget);

      await tester.drag(_drawerList(), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.byKey(logUnreadKey), findsNothing);
      expect(bloc.state.logFollowing, isTrue);
    },
  );

  testWidgets('an empty log renders at phone size without exception', (
    tester,
  ) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(game: _game(), stepDelay: Duration.zero);
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);

    final peek = find.byKey(logPeekKey);
    expect(
      find.descendant(of: peek, matching: find.text('RECENT EVENTS')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: peek, matching: find.text('0 entries')),
      findsOneWidget,
    );
    await tester.tap(peek);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(logHandleKey), findsOneWidget);
    expect(find.byKey(logDrawerKey), findsOneWidget);
    expect(_inDrawer('RECENT EVENTS'), findsOneWidget);

    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();
    expect(_inDrawer('0 entries'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a one-line log renders at phone size without exception', (
    tester,
  ) async {
    await onTheTargetPhone(tester);
    final bloc = GameBloc(
      game: _game(),
      log: const [LogLine('Something is on the road.', LogCategory.noticed)],
      stepDelay: Duration.zero,
    );
    addTearDown(bloc.close);
    await _pushGame(tester, bloc);

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(logHandleKey), findsOneWidget);
    expect(find.byKey(logDrawerKey), findsOneWidget);

    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(logHandleKey), findsOneWidget);
    expect(find.byKey(logDrawerKey), findsOneWidget);
  });

  testWidgets(
    'death collapses the drawer, inerts the peek, and the death overlay '
    'stays reachable',
    (tester) async {
      await onTheTargetPhone(tester);
      final bloc = GameBloc(
        game: _game(heroHp: 2, monsters: [_ghoul(_adjacentToHero)]),
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(bloc.state.logDrawerExtent, LogDrawerExtent.full);

      bloc.add(const TileTapped(_adjacentToHero));
      await tester.pumpAndSettle();
      expect(bloc.state.game.isGameOver, isTrue);

      expect(find.byKey(logDrawerKey), findsNothing);
      expect(find.byKey(logPeekKey), findsOneWidget);

      await tester.tap(find.byKey(logPeekKey), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(logDrawerKey), findsNothing);

      final deathButton = find.text('Return to town');
      expect(deathButton, findsOneWidget);
      await tester.tap(deathButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
