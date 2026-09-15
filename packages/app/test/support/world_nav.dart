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

/// Presses one of the town's doors, scrolling it into reach first.
///
/// The town column is taller than a short test surface, so the doors near its
/// foot are below the fold until the screen is scrolled — the same scroll the
/// player makes on a short phone.
Future<void> openTownDoor(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Walks the hero to [place] and waits out every day of the journey.
///
/// The days are pumped rather than settled, because a day passes on a timer
/// rather than in an animation: `pumpAndSettle` stops the moment nothing is
/// scheduling frames, which a pending delay is not. Pumping a generous span and
/// then settling is what gets the journey all the way to its end.
Future<void> walkTo(WidgetTester tester, String place) async {
  final control = find.ancestor(
    of: find.text(place),
    matching: find.byType(GestureDetector),
  );
  await tester.scrollUntilVisible(
    control,
    100,
    scrollable: find.byType(Scrollable),
  );
  await tester.drag(find.byType(ListView), const Offset(0, -120));
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Set out'));
  await tester.pumpAndSettle();
  for (var day = 0; day < 6; day++) {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }
}

/// Scrolls the world's list to the bottom, where the road log is.
///
/// The list grew when the world did: five places plus a row for each one the
/// hero has not heard of pushes the log below the fold on a test-sized screen,
/// and a lazily built list does not put an off-screen child in the tree at all.
Future<void> scrollToTheLog(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  await tester.pumpAndSettle();
}
