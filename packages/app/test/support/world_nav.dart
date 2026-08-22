import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Presses the world screen's door into the town the hero is standing in.
Future<void> enterTown(WidgetTester tester, String town) async {
  await tester.tap(find.text('Enter $town'));
  await tester.pumpAndSettle();
}

/// Comes back out of a town, or any other pushed screen, to the world.
Future<void> backToTheWorld(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

/// Walks the hero to [place] and waits out every day of the journey.
///
/// The days are pumped rather than settled, because a day passes on a timer
/// rather than in an animation: `pumpAndSettle` stops the moment nothing is
/// scheduling frames, which a pending delay is not. Pumping a generous span and
/// then settling is what gets the journey all the way to its end.
Future<void> walkTo(WidgetTester tester, String place) async {
  final row = find.ancestor(of: find.text(place), matching: find.byType(Row));
  await tester.tap(find.descendant(of: row, matching: find.text('Walk')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Set out'));
  await tester.pumpAndSettle();
  for (var day = 0; day < 6; day++) {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }
}
