import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/pumped_app.dart';
import '../support/standing.dart';
import '../support/world_nav.dart';

SaveDocument _twoHeroes({GameState? ilseRun, bool ilseInside = true}) =>
    SaveDocument(
      active: 'hero-2',
      heroes: {
        'hero-1': SavedHero(
          label: 'Ilse',
          profile: newProfile(worldSeed: 111).copyWith(gold: 40),
          world: ilseRun == null ? null : atTheCrypt(),
          run: ilseRun,
          inside: ilseRun != null && ilseInside,
        ),
        'hero-2': SavedHero(
          label: 'Bram',
          profile: newProfile(worldSeed: 222).copyWith(gold: 7),
        ),
      },
    );

Future<void> _openRoster(WidgetTester tester) async {
  await tester.tap(find.text('Heroes'));
  await tester.pumpAndSettle();
}

void main() {
  group('the roster door', () {
    testWidgets('switching lands on the other hero and writes it down', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Carried  40 gold'), findsOneWidget);
      expect(app.saved!.active, 'hero-1');
    });

    testWidgets('switching to a hero killed mid-crawl lands in their crawl', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _twoHeroes(ilseRun: startDungeonRun(newProfile(worldSeed: 111))),
      );
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('Depth 1/'), findsOneWidget);
      expect(app.saved!.active, 'hero-1');
    });

    testWidgets('switching to a camped hero lands in their town, camp kept', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _twoHeroes(
          ilseRun: startDungeonRun(newProfile(worldSeed: 111)),
          ilseInside: false,
        ),
      );
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.textContaining('Resume the crawl'), findsOneWidget);
      expect(app.saved!.active, 'hero-1');
      expect(app.saved!.run, isNotNull);
      expect(app.saved!.inside, isFalse);
    });

    testWidgets('switching away carries what the hero spent since booting', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Bank'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank all'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.heroes['hero-2']!.profile.bankedGold, 7);
      expect(app.saved!.heroes['hero-2']!.profile.gold, 0);
    });

    testWidgets('a created hero is the one being played', (tester) async {
      // arrange
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('New hero'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cato');
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.heroes, hasLength(3));
      expect(app.saved!.hero.label, 'Cato');
      expect(find.text('Carried  0 gold'), findsOneWidget);
    });

    testWidgets('deleting the hero being played lands on the one left', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this hero'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.heroes.keys.toList(), ['hero-1']);
      expect(app.saved!.active, 'hero-1');
      expect(find.text('Carried  40 gold'), findsOneWidget);
    });

    testWidgets('the last hero deleted is replaced, never removed', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 111).copyWith(gold: 40),
        ),
      );
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this hero'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cato');
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.heroes, hasLength(1));
      expect(app.saved!.hero.label, 'Cato');
      expect(app.saved!.heroes.containsKey('hero-1'), isFalse);
      expect(find.text('Carried  0 gold'), findsOneWidget);
    });

    testWidgets('leaving the roster without choosing changes nothing', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Carried  7 gold'), findsOneWidget);
      expect(app.saved!.active, 'hero-2');
    });

    testWidgets('the town has no Abandon Hero button any more', (tester) async {
      // arrange
      final app = PumpedApp(_twoHeroes());

      // act
      await app.pump(tester);

      // assert
      expect(find.text('Abandon Hero'), findsNothing);
      expect(find.text('Heroes'), findsOneWidget);
    });
  });
}
