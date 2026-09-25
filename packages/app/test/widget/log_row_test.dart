import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_style.dart';
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
.......
.......
.......''';

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
/// Watched, so Wait applies.
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

/// A dungeon with an adjacent monster: battle.
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
/// (Watched) and Flee (the hero stands on the outermost ring) would once
/// have applied, so this is the case that most stressed the old side
/// column's width.
GameState _roadEdgeGame() {
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
    'the row rect is identical across exploration, Watched, battle and a '
    'road edge',
    (tester) async {
      await _pumpLogRow(tester, _exploringGame());
      final exploringRect = tester.getRect(find.byKey(logRowKey));

      await _pumpLogRow(tester, _watchedGame());
      expect(tester.getRect(find.byKey(logRowKey)), exploringRect);

      await _pumpLogRow(tester, _battleGame());
      expect(tester.getRect(find.byKey(logRowKey)), exploringRect);

      await _pumpLogRow(tester, _roadEdgeGame());
      expect(tester.getRect(find.byKey(logRowKey)), exploringRect);
    },
  );

  testWidgets(
    'the peek fills the row less the gutter on both sides, in all four '
    'states',
    (tester) async {
      for (final game in [
        _exploringGame(),
        _watchedGame(),
        _battleGame(),
        _roadEdgeGame(),
      ]) {
        await _pumpLogRow(tester, game);
        final rowRect = tester.getRect(find.byKey(logRowKey));
        final peekRect = tester.getRect(find.byKey(logPeekKey));
        expect(peekRect.width, closeTo(rowRect.width - 2 * crawlGutter, 0.5));
      }
    },
  );

  testWidgets(
    'no Wait or Flee key sits inside the log row, in any of the four states',
    (tester) async {
      for (final game in [
        _exploringGame(),
        _watchedGame(),
        _battleGame(),
        _roadEdgeGame(),
      ]) {
        await _pumpLogRow(tester, game);
        expect(
          find.descendant(
            of: find.byKey(logRowKey),
            matching: find.byKey(const ValueKey('wait')),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(logRowKey),
            matching: find.byKey(const ValueKey('flee')),
          ),
          findsNothing,
        );
      }
    },
  );

  testWidgets('the peek still opens the drawer', (tester) async {
    final bloc = await _pumpLogRow(tester, _exploringGame());

    await tester.tap(find.byKey(logPeekKey));
    await tester.pump();

    expect(bloc.state.logDrawerExtent, LogDrawerExtent.half);
  });
}
