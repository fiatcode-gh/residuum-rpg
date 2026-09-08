import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/merchant_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

Profile _hero({List<Item> inventory = const []}) =>
    newProfile(worldSeed: 4).copyWith(gold: 500, inventory: inventory);

/// The merchant room, under a real town bloc.
Future<TownBloc> _openMerchant(
  WidgetTester tester,
  Profile profile, {
  MerchantVisit merchant = MerchantVisit.none,
}) async {
  final town = TownBloc(profile: profile, merchant: merchant);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<TownBloc>.value(
        value: town,
        child: const MerchantScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return town;
}

Item _potion(String id) =>
    Item(id: id, base: healingPotion, rarity: Rarity.common);

void main() {
  group('the merchant', () {
    testWidgets('lists each shelf potion as its own row', (tester) async {
      // arrange - every shelf carries three identical potions
      await onAPhone(tester);

      // act
      await _openMerchant(tester, _hero());

      // assert - three of the same thing are three rows today, each naming
      // the same per-item price
      final price = buyPriceOf(_potion('shelf-1'));
      expect(find.text('Buy $price'), findsNWidgets(3));
      expect(find.textContaining('×'), findsNothing);
    });

    testWidgets('lists each sold item as its own row', (tester) async {
      // arrange - three potions sold across the counter this visit
      await onAPhone(tester);
      final sold = [_potion('sold-1'), _potion('sold-2'), _potion('sold-3')];

      // act
      await _openMerchant(
        tester,
        _hero(),
        merchant: MerchantVisit(sold: sold, town: newWhereabouts().at),
      );

      // assert
      final price = sellPriceOf(_potion('sold-1'));
      expect(find.text('Buy back $price'), findsNWidgets(3));
      expect(find.textContaining('×'), findsNothing);
    });

    testWidgets('lists each carried item as its own row', (tester) async {
      // arrange
      await onAPhone(tester);
      final pack = [_potion('kit-1'), _potion('kit-2'), _potion('kit-3')];

      // act
      await _openMerchant(tester, _hero(inventory: pack));

      // assert
      final price = sellPriceOf(_potion('kit-1'));
      expect(find.text('Sell $price'), findsNWidgets(3));
      expect(find.textContaining('×'), findsNothing);
    });
  });
}
