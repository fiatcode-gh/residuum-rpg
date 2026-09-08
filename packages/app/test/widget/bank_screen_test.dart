import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/bank_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
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
    testWidgets('moves gold through four fixed buttons', (tester) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // assert - four buttons, a handful and the whole purse each way
      for (final label in ['Bank 10', 'Bank all', 'Take 10', 'Take all']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('one press of Bank 10 banks exactly ten', (tester) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // act
      await tester.tap(find.text('Bank 10'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.gold, 15);
      expect(bloc.state.bankedGold, 50);
    });

    testWidgets('one press of Take 10 takes exactly ten', (tester) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // act
      await tester.tap(find.text('Take 10'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.gold, 35);
      expect(bloc.state.bankedGold, 30);
    });

    testWidgets('Bank all banks the whole purse in one press', (tester) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openBank(
        tester,
        newProfile(worldSeed: 4).copyWith(gold: 25, bankedGold: 40),
      );

      // act
      await tester.tap(find.text('Bank all'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.gold, 0);
      expect(bloc.state.bankedGold, 65);
    });
  });
}
