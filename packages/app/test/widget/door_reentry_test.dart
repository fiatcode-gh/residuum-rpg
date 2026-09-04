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

/// A camp whose hero stands on the stairs up, so `Leave` is on screen in the
/// crawl without a test having to walk there.
GameState _onTheStairs(GameState camp) => camp.copyWith(
  hero: camp.hero.copyWith(position: camp.stairsUp ?? camp.stairsDown),
);

void main() {
  group('the door press while an opening is pending', () {
    testWidgets('a double tap opens the crawl once', (tester) async {
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

      // assert — the in-flight guard ignores the second press while the first
      // opening is pending.
      expect(find.byType(GameScreen, skipOffstage: false), findsOneWidget);
    });

    testWidgets('the doors work again after the crawl closes', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(
        startDungeonRunAt(seaCave, profile).copyWith(depth: 3),
      );
      final app = PumpedApp(_campedAtTheSeaCave(profile, camp));
      await app.pump(tester);

      // act — open the crawl, walk out at the stairs, press again.
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();

      // assert — the pending state cleared with the town's answer; the door
      // pressed a second time opens a second time.
      expect(find.byType(GameScreen), findsOneWidget);
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
