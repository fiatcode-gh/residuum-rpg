import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/inventory_screen.dart';
import 'package:residuum_core/core.dart';

/// Follow-up 31: the pack's skills row keeps its name and its level digit
/// apart, at the phone surface where the device pass found them touching.
///
/// The row is a fixed-column grid — name, digit, bar, progress — and nothing
/// between the first two columns said so: the longest name's last glyph could
/// sit against the digit with no seam. The test reads the two boxes' rects
/// rather than any string, because the defect is a gap, not a word.

/// A phone-sized viewport, which is where the screen has to read.
final Size _phone = Size(1080, 2424);

GameState _crawl() {
  final map = FloorMap.parse('''
#######
#.....#
#.....#
#######''');
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
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
  );
}

void main() {
  testWidgets("the skills row keeps the level digit off the name's tail", (
    tester,
  ) async {
    // arrange
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = GameBloc(game: _crawl(), stepDelay: Duration.zero);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const InventoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // act - walk down the pack to the skills, whose rows sit at the bottom
    await tester.scrollUntilVisible(find.text('Blacksmith'), 200);
    await tester.pumpAndSettle();

    // assert - the digit's left edge clears the name's right edge
    final nameFinder = find.text('Blacksmith');
    final rowFinder = find
        .ancestor(of: nameFinder, matching: find.byType(Row))
        .first;
    final levelFinder = find
        .descendant(of: rowFinder, matching: find.text('0'))
        .first;
    final nameRect = tester.getRect(nameFinder);
    final levelRect = tester.getRect(levelFinder);
    expect(levelRect.left - nameRect.right, greaterThanOrEqualTo(4.0));
  });
}
