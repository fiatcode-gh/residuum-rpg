import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/log_drawer.dart';
import 'package:residuum_app/game/log_line.dart';
import 'package:residuum_app/game/log_row.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _dungeonArena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _roadArena = '''
.........
.........
.........''';

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

/// A quiet dungeon room with nothing nearby: neither Wait nor Flee applies.
GameState _exploringGame() {
  final map = FloorMap.parse(_dungeonArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

/// A dungeon with a visible monster two cells away, not holding reach:
/// Watched, so Wait applies and Flee does not (not an encounter).
GameState _watchedGame() {
  final map = FloorMap.parse(_dungeonArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(3, 1))],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

/// A dungeon with an adjacent monster: battle, so Wait applies and Flee does
/// not (not an encounter).
GameState _battleGame() {
  final map = FloorMap.parse(_dungeonArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(1, 2))],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

/// A road edge with a visible monster not holding reach: both Wait
/// (Watched) and Flee (the hero stands on the outermost ring) apply.
GameState _roadEdgeBothGame() {
  final map = FloorMap.parse(_roadArena);
  const heroAt = Position(0, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(4, 1))],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('no floor below'),
    visible: visible,
    explored: {...visible},
    isEncounter: true,
  );
}

/// A road edge with nothing in sight: Flee applies and Wait does not.
GameState _roadEdgeFleeOnlyGame() {
  final map = FloorMap.parse(_roadArena);
  const heroAt = Position(0, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('no floor below'),
    visible: visible,
    explored: {...visible},
    isEncounter: true,
  );
}

/// Pumps [LogRow] alone, the way the crawl screen places it, without the
/// rest of the crawl chrome around it.
Future<GameBloc> _pumpLogRow(WidgetTester tester, GameState game) async {
  await onAPhone(tester);
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<GameBloc, GameViewState>(
                builder: (context, state) =>
                    LogRow(key: logRowKey, state: state, bloc: bloc),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  testWidgets(
    'the log row rect is identical across exploration, Watched, battle and '
    'a road edge',
    (tester) async {
      await _pumpLogRow(tester, _exploringGame());
      final exploringRect = tester.getRect(find.byKey(logRowKey));

      await _pumpLogRow(tester, _watchedGame());
      expect(tester.getRect(find.byKey(logRowKey)), exploringRect);

      await _pumpLogRow(tester, _battleGame());
      expect(tester.getRect(find.byKey(logRowKey)), exploringRect);

      await _pumpLogRow(tester, _roadEdgeBothGame());
      expect(tester.getRect(find.byKey(logRowKey)), exploringRect);
    },
  );

  testWidgets('neither Wait nor Flee shows while exploring', (tester) async {
    await _pumpLogRow(tester, _exploringGame());

    expect(find.byKey(const ValueKey('wait')), findsNothing);
    expect(find.byKey(const ValueKey('flee')), findsNothing);
  });

  testWidgets('Wait shows alone while Watched', (tester) async {
    await _pumpLogRow(tester, _watchedGame());

    expect(find.byKey(const ValueKey('wait')), findsOneWidget);
    expect(find.byKey(const ValueKey('flee')), findsNothing);
  });

  testWidgets('Flee shows alone at a road edge with nothing in sight', (
    tester,
  ) async {
    await _pumpLogRow(tester, _roadEdgeFleeOnlyGame());

    expect(find.byKey(const ValueKey('wait')), findsNothing);
    expect(find.byKey(const ValueKey('flee')), findsOneWidget);
  });

  testWidgets('Wait and Flee both show at a road edge in sight, Flee below', (
    tester,
  ) async {
    await _pumpLogRow(tester, _roadEdgeBothGame());

    final wait = tester.getRect(find.byKey(const ValueKey('wait')));
    final flee = tester.getRect(find.byKey(const ValueKey('flee')));
    expect(flee.top, greaterThanOrEqualTo(wait.bottom));
  });

  testWidgets('each side control is at least 48 dp tall', (tester) async {
    await _pumpLogRow(tester, _roadEdgeBothGame());

    expect(
      tester.getSize(find.byKey(const ValueKey('wait'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('flee'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('tapping Wait appends the hold-ground sentence', (tester) async {
    final bloc = await _pumpLogRow(tester, _watchedGame());

    await tester.tap(find.byKey(const ValueKey('wait')));
    await tester.pump();

    expect(bloc.state.log.first.sentence, 'You hold your ground.');
  });

  testWidgets('tapping Flee at a road edge flees', (tester) async {
    final bloc = await _pumpLogRow(tester, _roadEdgeFleeOnlyGame());

    await tester.tap(find.byKey(const ValueKey('flee')));
    await tester.pump();

    expect(bloc.state.hasFled, isTrue);
  });

  testWidgets('the peek still opens the drawer', (tester) async {
    final bloc = await _pumpLogRow(tester, _exploringGame());

    await tester.tap(find.byKey(logPeekKey));
    await tester.pump();

    expect(bloc.state.logDrawerExtent, LogDrawerExtent.half);
  });
}
