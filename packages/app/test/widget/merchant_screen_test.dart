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

Item _cap(String id) => Item(id: id, base: leatherCap, rarity: Rarity.common);

void main() {
  group('the merchant', () {
    testWidgets('the shelf stacks identical potions into one row', (
      tester,
    ) async {
      // arrange - every shelf carries three identical potions
      await onAPhone(tester);

      // act
      await _openMerchant(tester, _hero());

      // assert - one row, counted, at the per-item price
      final price = buyPriceOf(_potion('shelf-1'));
      expect(find.text('Buy $price'), findsOneWidget);
      expect(find.textContaining('×3'), findsOneWidget);
    });

    testWidgets('a stacked buy tap buys exactly one', (tester) async {
      // arrange
      await onAPhone(tester);
      final bloc = await _openMerchant(tester, _hero());
      final price = buyPriceOf(_potion('shelf-1'));

      // act
      await tester.tap(find.text('Buy $price'));
      await tester.pumpAndSettle();

      // assert - the stack thins by one, not by all of it
      expect(bloc.state.gold, 500 - price);
      expect(bloc.state.merchant.bought, hasLength(1));
      expect(
        bloc.state.stock.where((item) => item.base == healingPotion).length,
        2,
      );
      expect(find.textContaining('×2'), findsOneWidget);
    });

    testWidgets(
      'the sold list stacks and a buy-back tap buys back exactly one',
      (tester) async {
        // arrange - three caps sold across the counter this visit
        await onAPhone(tester);
        final sold = [_cap('sold-1'), _cap('sold-2'), _cap('sold-3')];
        final bloc = await _openMerchant(
          tester,
          _hero(),
          merchant: MerchantVisit(sold: sold, town: newWhereabouts().at),
        );
        final price = sellPriceOf(_cap('sold-1'));

        // act
        expect(find.textContaining('Leather Cap ×3'), findsOneWidget);
        await tester.tap(find.text('Buy back $price'));
        await tester.pumpAndSettle();

        // assert - the stack thins by one
        expect(bloc.state.gold, 500 - price);
        expect(bloc.state.merchant.sold.length, 2);
        expect(find.textContaining('Leather Cap ×2'), findsOneWidget);
      },
    );

    testWidgets('the pack stacks and a sell tap sells exactly one', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final pack = [_cap('kit-1'), _cap('kit-2'), _cap('kit-3')];
      final bloc = await _openMerchant(tester, _hero(inventory: pack));
      final price = sellPriceOf(_cap('kit-1'));

      // act
      expect(find.textContaining('Leather Cap ×3'), findsOneWidget);
      await tester.tap(find.text('Sell $price'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.profile.inventory.length, 2);
      expect(bloc.state.merchant.sold.length, 1);
      expect(find.textContaining('Leather Cap ×2'), findsOneWidget);
    });

    testWidgets('different steel keeps its own row at the per-item price', (
      tester,
    ) async {
      // arrange - the temper is in the stack key, so a tempered sword is a
      // different row at a different price
      await onAPhone(tester);
      final pack = [
        Item(id: 'kit-1', base: ironSword, rarity: Rarity.common),
        Item(id: 'kit-2', base: ironSword, rarity: Rarity.common).tempered(1),
      ];

      // act
      await _openMerchant(tester, _hero(inventory: pack));

      // assert - two rows, two price words, no counting anywhere
      expect(find.textContaining('×2'), findsNothing);
      final plain = sellPriceOf(pack[0]);
      final tempered = sellPriceOf(pack[1]);
      expect(plain, isNot(tempered));
      expect(find.text('Sell $plain'), findsOneWidget);
      expect(find.text('Sell $tempered'), findsOneWidget);
    });
  });
}
