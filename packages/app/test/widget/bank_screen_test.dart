import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/bank_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_style.dart' show CountStepper;
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

Item _item(String id) => Item(id: id, base: leatherCap, rarity: Rarity.common);

Profile _hero({int gold = 0, int bankedGold = 0}) =>
    newProfile(worldSeed: 4).copyWith(gold: gold, bankedGold: bankedGold);

/// The bank room, under a real town bloc.
Future<TownBloc> _openBank(WidgetTester tester, Profile profile) async {
  final town = TownBloc(profile: profile);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<TownBloc>.value(
        value: town,
        child: const BankScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return town;
}

void main() {
  group('the bank', () {
    testWidgets("the fixed gold buttons are gone", (tester) async {
      // arrange
      await onAPhone(tester);
      await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // assert - the four fixed buttons retire; the dials carry the work
      for (final label in ['Bank 10', 'Bank all', 'Take 10', 'Take all']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.byType(CountStepper), findsNWidgets(2));
    });

    testWidgets('one dial step banks exactly one step', (tester) async {
      // arrange - the n = 1 shape
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // act
      await tester.tap(find.text('+').first);
      await tester.pump();
      await tester.tap(find.text('Bank gold'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.gold, 24);
      expect(bloc.state.bankedGold, 41);
    });

    testWidgets('the gold dial banks exactly the dialed amount', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // act - dial three, commit once, and the core moves gold once
      await tester.tap(find.text('+').first);
      await tester.pump();
      await tester.tap(find.text('+').first);
      await tester.pump();
      await tester.tap(find.text('+').first);
      await tester.pump();
      await tester.tap(find.text('Bank gold'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.gold, 22);
      expect(bloc.state.bankedGold, 43);
    });

    testWidgets('one take-dial step takes exactly one step', (tester) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // act - the second stepper is the take side
      await tester.tap(find.text('+').last);
      await tester.pump();
      await tester.tap(find.text('Take gold'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.gold, 26);
      expect(bloc.state.bankedGold, 39);
    });

    testWidgets('MAX dials the whole side and the commit moves it in one', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // act
      await tester.tap(find.text('MAX').first);
      await tester.pump();
      await tester.tap(find.text('Bank gold'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.gold, 0);
      expect(bloc.state.bankedGold, 65);
    });

    testWidgets('an empty side keeps its sentence beside its dead commit', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      await _openBank(tester, _hero());

      // assert
      expect(find.text(purseIsShort), findsOneWidget);
      expect(find.text(vaultIsShort), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Bank gold'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Take gold'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('the two zones read in order, carried then banked', (
      tester,
    ) async {
      // arrange - one item on each side, so both row groups exist
      await onAPhone(tester);
      await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(
          gold: 25,
          bankedGold: 40,
          inventory: [_item('held-1')],
          bank: [_item('vault-1')],
        ),
      );

      // assert - carried heading, its dial, its commit and its own item row
      // all sit above the banked heading and everything under it
      final positions = [
        tester.getTopLeft(find.text('CARRIED — LOST IF YOU DIE')).dy,
        tester.getTopLeft(find.byType(CountStepper).first).dy,
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Bank gold')).dy,
        tester.getTopLeft(find.text('Common Leather Cap').first).dy,
        tester.getTopLeft(find.text('BANKED — SAFE FROM DEATH')).dy,
        tester.getTopLeft(find.byType(CountStepper).last).dy,
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Take gold')).dy,
        tester.getTopLeft(find.text('Common Leather Cap').last).dy,
      ];
      for (var i = 1; i < positions.length; i++) {
        expect(positions[i], greaterThan(positions[i - 1]), reason: '$i');
      }
      expect(find.text('GOLD'), findsNothing);
    });

    testWidgets("each zone's short sentence belongs to its own zone", (
      tester,
    ) async {
      // arrange - an empty purse, a stocked vault
      await onAPhone(tester);
      await _openBank(tester, _hero(gold: 0, bankedGold: 40));

      // assert - each sentence stays with the side it is short about
      expect(find.text(purseIsShort), findsOneWidget);
      expect(find.text(vaultIsShort), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Bank gold'),
            )
            .onPressed,
        isNull,
      );

      // act - the take side has something to dial
      await tester.tap(find.text('+').last);
      await tester.pump();

      // assert - once dialled, the vault's own commit goes live
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Take gold'),
            )
            .onPressed,
        isNotNull,
      );

      // arrange - the mirror: a stocked purse and an empty vault
      await onAPhone(tester);
      await _openBank(tester, _hero(gold: 25, bankedGold: 0));

      // assert
      expect(find.text(purseIsShort), findsNothing);
      expect(find.text(vaultIsShort), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Take gold'),
            )
            .onPressed,
        isNull,
      );

      // act - the bank side has something to dial
      await tester.tap(find.text('+').first);
      await tester.pump();

      // assert - once dialled, the purse's own commit goes live
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Bank gold'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('items are never dead in either zone, even at a full pack', (
      tester,
    ) async {
      // arrange - a full-to-cap inventory and a full-to-cap vault
      await onAPhone(tester);
      await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(
          gold: 25,
          bankedGold: 40,
          inventory: [for (var n = 0; n < inventoryCap; n++) _item('held-$n')],
          bank: [for (var n = 0; n < inventoryCap; n++) _item('vault-$n')],
        ),
      );

      // assert
      for (final button in tester.widgetList<FilledButton>(
        find.widgetWithText(FilledButton, 'Bank'),
      )) {
        expect(button.onPressed, isNotNull);
      }
      for (final button in tester.widgetList<FilledButton>(
        find.widgetWithText(FilledButton, 'Take out'),
      )) {
        expect(button.onPressed, isNotNull);
      }
      expect(find.textContaining('does not have it'), findsNothing);
    });
  });
}
