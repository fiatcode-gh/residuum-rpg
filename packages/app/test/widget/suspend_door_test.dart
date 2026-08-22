import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/pumped_app.dart';

SaveDocument _oneHero(Profile profile, {GameState? run, bool inside = false}) =>
    SaveDocument.one(
      id: 'hero-1',
      label: 'Hero 1',
      profile: profile,
      run: run,
      inside: inside,
    );

/// A crawl with the hero standing on the stairs down, so the `Leave` control is
/// on screen without a test having to walk there.
GameState _onTheStairs(Profile profile) {
  final run = startDungeonRun(profile);
  return run.copyWith(hero: run.hero.copyWith(position: run.stairsDown));
}

/// A camp two floors down, standing on the stairs, so the depth the door offers
/// is a number a test can tell apart from the depth a fresh delve opens on.
GameState _twoDown(Profile profile) => _onTheStairs(profile).copyWith(depth: 2);

/// A document with the hero camped away from [camp].
///
/// The profile is the one the crawl would actually have sent home, which means
/// the visit as well as the purse — a hand-built camp whose profile still held
/// the older visit would be a document no play could produce, and delving anew
/// counts its reshuffle from exactly that number.
SaveDocument _camped(Profile profile, GameState camp) =>
    _oneHero(suspendRun(profile, camp), run: camp);

void main() {
  group('walking out at the stairs', () {
    testWidgets('leaving lands in town with the crawl left standing', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(gold: 40);
      final app = PumpedApp(
        _oneHero(profile, run: _onTheStairs(profile), inside: true),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('Carried  40 gold'), findsOneWidget);
      expect(app.saved!.run, isNotNull);
      expect(app.saved!.inside, isFalse);
    });

    testWidgets('the hero who walks out is the one who was down there', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final wounded = _onTheStairs(profile);
      final app = PumpedApp(
        _oneHero(
          profile,
          run: wounded.copyWith(hero: wounded.hero.copyWith(hp: 6)),
          inside: true,
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('Health   6 /'), findsOneWidget);
      expect(app.saved!.profile.hero.hp, 6);
    });

    testWidgets('the town then offers going back down, at the depth left', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(
        _oneHero(profile, run: _twoDown(profile), inside: true),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Resume the crawl (depth 2)'), findsOneWidget);
      expect(find.text('Enter Dungeon'), findsNothing);
    });
  });

  group('the door out of town while a crawl waits', () {
    testWidgets('a hero with no crawl sees one door, not a fork', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('Enter Dungeon'), findsOneWidget);
      expect(find.textContaining('Resume the crawl'), findsNothing);
      expect(find.text('Delve anew'), findsNothing);
    });

    testWidgets('a camped hero boots into the town, camp and all', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(_camped(profile, _twoDown(profile)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('Resume the crawl (depth 2)'), findsOneWidget);
      expect(find.textContaining('Depth'), findsNothing);
    });

    testWidgets('a potion bought while camped is in the resumed pack', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(gold: 500);
      final app = PumpedApp(_camped(profile, _onTheStairs(profile)));
      await app.pump(tester);
      final carried = profile.inventory.length;

      // act
      await tester.tap(find.text('Merchant'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Buy ').first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Pack (${carried + 1})'), findsOneWidget);
      expect(app.saved!.inside, isTrue);
      expect(app.saved!.run!.inventory, hasLength(carried + 1));
      expect(app.saved!.run!.gold, lessThan(500));
      expect(app.saved!.run!.gold, app.saved!.profile.gold);
    });

    testWidgets('a night at the inn while camped shows in the resumed hero', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(gold: 50);
      final camp = _onTheStairs(profile);
      final wounded = camp.copyWith(hero: camp.hero.copyWith(hp: 5));
      final app = PumpedApp(_camped(profile, wounded));
      await app.pump(tester);

      // act
      await tester.tap(find.text('Inn'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Rest'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('20 / 20'), findsOneWidget);
      expect(app.saved!.run!.hero.hp, 20);
    });

    testWidgets('resuming puts the hero back where they were standing', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _twoDown(profile);
      final app = PumpedApp(_camped(profile, camp));
      await app.pump(tester);

      // act
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('Depth 2/'), findsOneWidget);
      expect(app.saved!.run!.hero.position, camp.hero.position);
      expect(app.saved!.run!.visit, camp.visit);
    });

    testWidgets('the resumed crawl says so in its log', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(_camped(profile, _twoDown(profile)));
      await app.pump(tester);

      // act
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('The crawl resumes.'), findsOneWidget);
    });
  });

  group('giving the crawl up', () {
    testWidgets('delving anew asks first, and a refusal keeps the camp', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(_camped(profile, _twoDown(profile)));
      await app.pump(tester);

      // act
      await tester.tap(find.text('Delve anew'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep the crawl'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('Resume the crawl (depth 2)'), findsOneWidget);
      expect(app.saved!.run!.depth, 2);
    });

    testWidgets('the question says what is lost and what is not', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(_camped(profile, _twoDown(profile)));
      await app.pump(tester);

      // act
      await tester.tap(find.text('Delve anew'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('depth 2'), findsWidgets);
      expect(find.textContaining('carry, bank and know'), findsOneWidget);
    });

    testWidgets('confirming reshuffles into a fresh crawl on floor one', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _twoDown(profile);
      final app = PumpedApp(_camped(profile, camp));
      await app.pump(tester);

      // act
      await tester.tap(find.text('Delve anew'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Give it up'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('Depth 1/'), findsOneWidget);
      expect(app.saved!.run!.visit, camp.visit + 1);
      expect(app.saved!.run!.depth, 1);
      expect(app.saved!.inside, isTrue);
      expect(find.text('The crawl resumes.'), findsNothing);
    });
  });

  group('dying in a crawl that was resumed', () {
    testWidgets('leaves no camp behind to go back to', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _twoDown(profile);
      final app = PumpedApp(
        _oneHero(
          profile,
          run: camp.copyWith(hero: camp.hero.copyWith(hp: 0), isGameOver: true),
          inside: true,
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Return to town'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Enter Dungeon'), findsOneWidget);
      expect(find.textContaining('Resume the crawl'), findsNothing);
      expect(app.saved!.run, isNull);
      expect(app.saved!.inside, isFalse);
    });
  });
}
