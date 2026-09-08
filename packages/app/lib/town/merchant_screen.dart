import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';

import '../game/item_presentation.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// Why a counter will not take the hero's money.
///
/// One sentence for buying and for buying back, because it is one rule: the
/// purse is short. Two wordings would read as two rules.
const String cannotAfford = 'you cannot afford this';

/// The shop: what is for sale above, what was sold across the counter in the
/// middle, what the hero is carrying below.
///
/// Three lists in a fixed order, each row naming its own price on its own
/// button, so there is never a question of which price applies to which side of
/// the counter. The merchant's two lists sit together above the hero's, because
/// the position of a list is what tells them apart without colour. Buying costs
/// twice what selling pays, at every tier, which is why the two ends can sit on
/// one screen without inviting a loop — and buying back costs exactly what the
/// sale paid, because an undo is not a trade.
///
/// **All three lists stack, the pack's way.** Two identical items are noise the
/// hero cannot tell apart, so each list reads through [stacked] and a row of
/// more than one says so in `Name ×count`. Identical items are identically
/// priced — every input of a price is in the stack key — so a stacked row has
/// ONE price word, the per-item price, and every tap moves exactly one item:
/// the row acts through its first item, and the stack thins by one.
///
/// The sold list appears only while there is something on it: a heading with
/// nothing under it is the one row on this screen that would say nothing.
///
/// A row the purse cannot reach goes dead and says so. Both counters refuse for
/// the same reason and so give the same sentence, because a shop that had two
/// ways of saying "not enough" would read as two different rules.
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
          for (final stack in stacked(state.stock))
            ItemRow(
              marking: stack.item.rarity.marking,
              name: stack.label,
              action: 'Buy ${buyPriceOf(stack.item)}',
              onPressed: state.gold < buyPriceOf(stack.item)
                  ? null
                  : () => bloc.add(BuyPressed(stack.item.id)),
              reason: cannotAfford,
            ),
          if (state.merchant.sold.isNotEmpty) ...[
            const Heading('Sold this visit'),
            for (final stack in stacked(state.merchant.sold))
              ItemRow(
                marking: stack.item.rarity.marking,
                name: stack.label,
                action: 'Buy back ${sellPriceOf(stack.item)}',
                onPressed: state.gold < sellPriceOf(stack.item)
                    ? null
                    : () => bloc.add(BuyBackPressed(stack.item.id)),
                reason: cannotAfford,
              ),
          ],
          const Heading('Your pack'),
          if (state.profile.inventory.isEmpty)
            const NothingHere('You are carrying nothing.'),
          for (final stack in stacked(state.profile.inventory))
            ItemRow(
              marking: stack.item.rarity.marking,
              name: stack.label,
              action: 'Sell ${sellPriceOf(stack.item)}',
              onPressed: () => bloc.add(SellPressed(stack.item.id)),
            ),
        ],
      ),
    );
  }
}
