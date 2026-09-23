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
    await onAPhone(tester);
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
      'without ever reflowing the map', (tester) async {
    await onAPhone(tester);
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

    expect(peekRect.height, crawlLogPeekHeight);
    reportStableCrawlGeometry('closed');

    await tester.tap(find.byKey(logPeekKey));
    await tester.pumpAndSettle();
    expect(find.byKey(logDrawerKey), findsOneWidget);
    reportStableCrawlGeometry('half');
    final halfHandleTop = tester.getTopLeft(find.byKey(logHandleKey)).dy;

    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(logDrawerKey), findsOneWidget);
    reportStableCrawlGeometry('full');
    final fullHandleTop = tester.getTopLeft(find.byKey(logHandleKey)).dy;
    expect(fullHandleTop, lessThan(halfHandleTop));

    await tester.tap(find.byKey(logHandleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(logDrawerKey), findsNothing);
    reportStableCrawlGeometry('closed');
  });

  testWidgets(
    'recent events keep a real latest sentence visible and the drawer '
    'reports its chronological entry count',
    (tester) async {
      await onAPhone(tester);
      final newest =
          'The narrow stair opens into a passage where cold air stirs '
          'the dust.\nSomething moves beyond the torchlight.';
      final bloc = GameBloc(
        game: _game(),
        log: [
          const LogLine('The door settles shut.', LogCategory.moved),
          const LogLine('A distant cry echoes.', LogCategory.noticed),
          LogLine(newest, LogCategory.hit),
        ],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      final peek = find.byKey(logPeekKey);
      expect(tester.getRect(peek).height, crawlLogPeekHeight);
      expect(
        find.descendant(of: peek, matching: find.text('RECENT EVENTS')),
        findsOneWidget,
      );
      final peekSentence = find.descendant(
        of: peek,
        matching: find.text(newest),
      );
      expect(peekSentence, findsOneWidget);
      final sentenceRect = tester.getRect(peekSentence);
      final peekRect = tester.getRect(peek);
      expect(sentenceRect.top, greaterThanOrEqualTo(peekRect.top));
      expect(sentenceRect.bottom, lessThanOrEqualTo(peekRect.bottom));
      await tester.tap(peek);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(_inDrawer('RECENT EVENTS'), findsOneWidget);
      expect(_inDrawer('3 entries'), findsOneWidget);

      final drawerRect = tester.getRect(find.byKey(logDrawerKey));
      final first = tester.getTopLeft(_inDrawer('The door settles shut.'));
      final second = tester.getTopLeft(_inDrawer('A distant cry echoes.'));
      final newestFinder = _inDrawer(newest);
      final third = tester.getTopLeft(newestFinder);
      final newestRect = tester.getRect(newestFinder);
      expect(first.dy, lessThan(second.dy));
      expect(second.dy, lessThan(third.dy));
      expect(newestRect.top, greaterThanOrEqualTo(drawerRect.top));
      expect(newestRect.bottom, lessThanOrEqualTo(drawerRect.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the close affordance collapses from full', (tester) async {
    await onAPhone(tester);
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

  testWidgets('the expanded log shows every category glyph and word, and '
      'the peek shows none', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await onAPhone(tester);
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

      expect(find.text(LogCategory.struck.mark), findsNothing);

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(bloc.state.logDrawerExtent, LogDrawerExtent.full);
      expect(_inDrawer('RECENT EVENTS'), findsOneWidget);
      expect(_inDrawer('${seeded.length} entries'), findsOneWidget);

      for (final category in LogCategory.values) {
        expect(
          find.text(category.mark),
          findsWidgets,
          reason: 'mark for ${category.name}',
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
    'the newest line reads brighter than older lines, and each mark shares '
    "its sentence's colour",
    (tester) async {
      await onAPhone(tester);
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
      final newestMark = tester.widget<Text>(
        find.text(LogCategory.struck.mark),
      );
      final olderSentence = tester.widget<Text>(_inDrawer('First line.'));
      final olderMark = tester.widget<Text>(find.text(LogCategory.moved.mark));

      expect(
        newestSentence.style!.color!.computeLuminance(),
        greaterThan(olderSentence.style!.color!.computeLuminance()),
      );
      expect(newestMark.style!.color, newestSentence.style!.color);
      expect(olderMark.style!.color, olderSentence.style!.color);
    },
  );

  testWidgets(
    'the peek renders an expand affordance and shows no category mark',
    (tester) async {
      await onAPhone(tester);
      final bloc = GameBloc(
        game: _game(),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
        stepDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await _pushGame(tester, bloc);

      expect(
        find.descendant(of: find.byKey(logPeekKey), matching: find.text('›')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(logPeekKey),
          matching: find.text(LogCategory.noticed.mark),
        ),
        findsNothing,
      );
    },
  );

  testWidgets("a row's mark sits left of its sentence, inside the gutter", (
    tester,
  ) async {
    await onAPhone(tester);
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

    final markRect = tester.getRect(find.text(LogCategory.noticed.mark));
    final sentenceRect = tester.getRect(_inDrawer('Something is on the road.'));
    expect(markRect.right, lessThanOrEqualTo(sentenceRect.left));
    expect(markRect.width, lessThanOrEqualTo(crawlMarkColumn));
  });

  testWidgets('follow holds the reader at newest while active', (tester) async {
    await onAPhone(tester);
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
      await onAPhone(tester);
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
    await onAPhone(tester);
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
      await onAPhone(tester);
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
    await onAPhone(tester);
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
      findsNothing,
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
    await onAPhone(tester);
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
      await onAPhone(tester);
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
