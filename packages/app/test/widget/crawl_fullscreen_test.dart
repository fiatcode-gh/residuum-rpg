import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/crawl_header.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _heroAt = Position(2, 2);

GameState _exploringGame() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'hero',
      glyph: '@',
      position: _heroAt,
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

Future<void> _openCrawl(WidgetTester tester) async {
  final bloc = GameBloc(game: _exploringGame(), stepDelay: Duration.zero);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const GameScreen(palette: DungeonPalette.crypt),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _surfaceHeight(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio;

void main() {
  testWidgets('clears the gesture handle with zero device bottom padding', (
    tester,
  ) async {
    await onTheTargetPhone(tester);
    tester.view.padding = FakeViewPadding.zero;
    await _openCrawl(tester);

    final barBottom = tester.getBottomLeft(find.byKey(actionRowKey)).dy;
    final threshold =
        _surfaceHeight(tester) - crawlGestureClear - crawlBottomGap;
    expect(barBottom, lessThanOrEqualTo(threshold + 0.5));
  });

  testWidgets(
    'takes the device bottom inset over the gesture clearance when it is wider',
    (tester) async {
      await onTheTargetPhone(tester);
      const insetDp = 30.0;
      tester.view.padding = FakeViewPadding(
        bottom: insetDp * tester.view.devicePixelRatio,
      );
      await _openCrawl(tester);

      final barBottom = tester.getBottomLeft(find.byKey(actionRowKey)).dy;
      final clearance = _surfaceHeight(tester) - barBottom - crawlBottomGap;
      expect(clearance, closeTo(insetDp, 0.5));
    },
  );

  testWidgets('keeps the header clear of a top cut-out inset', (tester) async {
    await onTheTargetPhone(tester);
    const insetDp = 24.0;
    tester.view.padding = FakeViewPadding(
      top: insetDp * tester.view.devicePixelRatio,
    );
    await _openCrawl(tester);

    final headerTop = tester.getTopLeft(find.byKey(crawlHeaderKey)).dy;
    expect(headerTop, greaterThanOrEqualTo(insetDp - 0.5));
  });
}
