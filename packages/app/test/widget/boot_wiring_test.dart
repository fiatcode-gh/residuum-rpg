import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/pumped_app.dart';
import '../support/standing.dart';
import '../support/world_nav.dart';

SaveDocument _oneHero(
  Profile profile, {
  GameState? run,
  NodeId? dungeon,
  bool inside = false,
}) => SaveDocument.one(
  id: 'hero-1',
  label: 'Hero 1',
  profile: profile,
  world: run == null ? null : atTheCrypt(),
  run: run,
  dungeon: run == null ? null : (dungeon ?? cryptNode),
  inside: inside,
);

void main() {
  group('booting the app', () {
    testWidgets('the first transaction in town is written down', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 5).copyWith(gold: 40)),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Bank'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank 10'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.profile.bankedGold, 10);
      expect(app.saved!.profile.gold, 30);
    });

    testWidgets('a document the hero is inside opens in the crawl', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(
        _oneHero(
          profile,
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        ),
      );

      // act
      await app.pump(tester);

      // assert
      expect(find.textContaining('The Crypt — depth 1/'), findsOneWidget);
      expect(find.text('The crawl resumes.'), findsOneWidget);
    });

    testWidgets('a document with a crawl the hero left opens on the world', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile);
      final app = PumpedApp(_oneHero(suspendRun(profile, camp), run: camp));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('At The Crypt'), findsOneWidget);
      expect(find.textContaining('Resume the crawl'), findsOneWidget);
      expect(find.textContaining('Depth'), findsNothing);
    });

    testWidgets('a document without one opens on the world, at home', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('At Stonebridge'), findsOneWidget);
      expect(find.text('Enter Stonebridge'), findsOneWidget);
      expect(find.textContaining('Depth'), findsNothing);
    });
  });
}
