import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';

import 'town_bloc.dart';
import 'town_style.dart';

/// The shop: what is for sale above, what the hero is carrying below.
///
/// Two lists in a fixed order, each row naming its own price on its own button,
/// so there is never a question of which price applies to which side of the
/// counter. Buying costs twice what selling pays, at every tier, which is why
/// the two lists can sit on one screen without inviting a loop.
class MerchantScreen extends StatelessWidget {
  const MerchantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) => TownRoom(
        title: 'Merchant',
        children: [
          Purse(carried: state.gold, banked: state.bankedGold),
          Notice(state.notice),
          const Heading('For sale'),
          if (state.stock.isEmpty)
            const NothingHere('The shelf is bare until you come back.'),
          for (final item in state.stock)
            ItemRow(
              marking: item.rarity.marking,
              name: item.displayName,
              action: 'Buy ${buyPriceOf(item)}',
              onPressed: state.gold < buyPriceOf(item)
                  ? null
                  : () => bloc.add(BuyPressed(item.id)),
            ),
          const Heading('Your pack'),
          if (state.profile.inventory.isEmpty)
            const NothingHere('You are carrying nothing.'),
          for (final item in state.profile.inventory)
            ItemRow(
              marking: item.rarity.marking,
              name: item.displayName,
              action: 'Sell ${sellPriceOf(item)}',
              onPressed: () => bloc.add(SellPressed(item.id)),
            ),
        ],
      ),
    );
  }
}
