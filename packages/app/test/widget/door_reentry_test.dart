import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/pumped_app.dart';

/// A hero camped away from a crawl at the sea-cave, standing at the sea-cave,
/// so the resume door is on screen without a test having to walk anywhere.
SaveDocument _campedAtTheSeaCave(Profile profile, GameState camp) =>
    SaveDocument.one(
      id: 'hero-1',
      label: 'Hero 1',
      profile: suspendRun(profile, camp),
      world: newWhereabouts()
          .arrivingAt(residuumWorld, northgate)
          .arrivingAt(residuumWorld, seaCave),
      run: camp,
      dungeon: seaCave,
      campDay: 0,
    );

void main() {
  group('the door press while an opening is pending', () {
    testWidgets('today a double tap opens the crawl twice', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(seaCave, profile).copyWith(depth: 3);
      final app = PumpedApp(_campedAtTheSeaCave(profile, camp));
      await app.pump(tester);
      expect(find.textContaining('Resume the crawl'), findsOneWidget);

      // act — two full taps dispatched back to back, before any microtask
      // runs: the second press lands while the first opening is still
      // pending.
      final door = tester.getCenter(find.textContaining('Resume the crawl'));
      tester.binding.handlePointerEvent(PointerDownEvent(position: door));
      tester.binding.handlePointerEvent(PointerUpEvent(position: door));
      tester.binding.handlePointerEvent(PointerDownEvent(position: door));
      tester.binding.handlePointerEvent(PointerUpEvent(position: door));
      await tester.pumpAndSettle();

      // assert — today both pending waits resolve on the one emission and the
      // crawl is pushed twice; the in-flight guard makes this one.
      expect(find.byType(GameScreen, skipOffstage: false), findsNWidgets(2));
    });

    testWidgets('a single tap opens the crawl once', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(seaCave, profile).copyWith(depth: 3);
      final app = PumpedApp(_campedAtTheSeaCave(profile, camp));
      await app.pump(tester);

      // act
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
    });
  });
}
