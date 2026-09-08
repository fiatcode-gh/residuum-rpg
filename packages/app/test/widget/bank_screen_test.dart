import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/bank_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_style.dart' show CountStepper;
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

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
  });
}
