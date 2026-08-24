import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/bank_screen.dart';
import 'package:residuum_app/town/merchant_screen.dart';
import 'package:residuum_content/content.dart';

import '../support/pumped_app.dart';

/// A one-hero document standing at home with [gold] in the purse.
SaveDocument _inTown({int gold = 0, int hp = 20, int bankedGold = 0}) {
  final profile = newProfile(worldSeed: 909);
  return SaveDocument.one(
    id: 'hero-1',
    label: 'Hero 1',
    profile: profile.copyWith(
      gold: gold,
      bankedGold: bankedGold,
      hero: profile.hero.copyWith(hp: hp),
    ),
  );
}

/// Walks into Stonebridge and opens the room behind [door].
Future<void> _openRoom(WidgetTester tester, String door) async {
  await tester.tap(find.text('Enter Stonebridge'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(door));
  await tester.pumpAndSettle();
}

void main() {
  group('a dead control on the shelf', () {
    testWidgets('says the purse cannot reach it', (tester) async {
      // arrange
      final app = PumpedApp(_inTown());

      // act
      await app.pump(tester);
      await _openRoom(tester, 'Merchant');

      // assert
      expect(find.text(cannotAfford), findsWidgets);
    });

    testWidgets('says nothing at all once the purse can', (tester) async {
      // arrange
      final app = PumpedApp(_inTown(gold: 9999));

      // act
      await app.pump(tester);
      await _openRoom(tester, 'Merchant');

      // assert
      expect(find.text(cannotAfford), findsNothing);
    });
  });

  group('a dead bed at the inn', () {
    testWidgets('names the price and what the hero is carrying', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_inTown(hp: 4, gold: 5));

      // act
      await app.pump(tester);
      await _openRoom(tester, 'Inn');

      // assert
      expect(find.text('A night costs 12 and you carry 5.'), findsOneWidget);
    });

    testWidgets('still says so when nothing is wrong with the hero', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_inTown(gold: 5));

      // act
      await app.pump(tester);
      await _openRoom(tester, 'Inn');

      // assert
      expect(find.text('There is nothing wrong with you.'), findsOneWidget);
    });

    testWidgets('says what a bed does once the hero can pay for one', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_inTown(hp: 4, gold: 50));

      // act
      await app.pump(tester);
      await _openRoom(tester, 'Inn');

      // assert
      expect(
        find.text('A night here mends everything the dungeon did.'),
        findsOneWidget,
      );
    });
  });

  group('a dead gold button at the bank', () {
    testWidgets('says which side of the counter is short', (tester) async {
      // arrange
      final app = PumpedApp(_inTown());

      // act
      await app.pump(tester);
      await _openRoom(tester, 'Bank');

      // assert
      expect(find.text(purseIsShort), findsOneWidget);
      expect(find.text(vaultIsShort), findsOneWidget);
    });

    testWidgets('says nothing about a purse that is not short', (tester) async {
      // arrange
      final app = PumpedApp(_inTown(gold: 50));

      // act
      await app.pump(tester);
      await _openRoom(tester, 'Bank');

      // assert
      expect(find.text(purseIsShort), findsNothing);
      expect(find.text(vaultIsShort), findsOneWidget);
    });
  });

  group('a dead Walk on the world screen', () {
    testWidgets('says there is no road when there is none', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: profile,
          world: newWhereabouts()
              .hearingOf(northgate)
              .hearingOf(seaCave)
              .arrivingAt(residuumWorld, cryptNode),
        ),
      );

      // act
      await app.pump(tester);

      // assert — the crypt's roads run to the two towns and nowhere else
      expect(find.text('no road runs there from here'), findsOneWidget);
    });

    testWidgets('says nothing about the place the hero is standing on', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_inTown());

      // act
      await app.pump(tester);

      // assert
      expect(find.text('no road runs there from here'), findsNothing);
    });
  });
}
