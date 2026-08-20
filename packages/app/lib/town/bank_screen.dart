import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'town_bloc.dart';
import 'town_style.dart';

/// How much gold one button moves. Ten is a nudge, all is the whole purse.
const int _handful = 10;

/// The vault: what death can reach above, what it cannot below.
///
/// Carried always sits above banked, on this screen and on the town menu, so
/// the position of a row says which side of the death penalty it is on. Gold
/// moves in fixed amounts rather than through a text field, because a number
/// pad on a phone is three taps to do what one button already says.
class BankScreen extends StatelessWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) => TownRoom(
        title: 'Bank',
        children: [
          Purse(carried: state.gold, banked: state.bankedGold),
          Notice(state.notice),
          const Heading('Gold'),
          Row(
            children: [
              _Coin(
                label: 'Bank $_handful',
                onPressed: state.gold < _handful
                    ? null
                    : () => bloc.add(const DepositGoldPressed(_handful)),
              ),
              _Coin(
                label: 'Bank all',
                onPressed: state.gold <= 0
                    ? null
                    : () => bloc.add(DepositGoldPressed(state.gold)),
              ),
              _Coin(
                label: 'Take $_handful',
                onPressed: state.bankedGold < _handful
                    ? null
                    : () => bloc.add(const WithdrawGoldPressed(_handful)),
              ),
              _Coin(
                label: 'Take all',
                onPressed: state.bankedGold <= 0
                    ? null
                    : () => bloc.add(WithdrawGoldPressed(state.bankedGold)),
              ),
            ],
          ),
          const Heading('Carried — lost if you die'),
          if (state.profile.inventory.isEmpty)
            const NothingHere('You are carrying nothing.'),
          for (final item in state.profile.inventory)
            ItemRow(
              marking: item.rarity.marking,
              name: item.displayName,
              action: 'Bank',
              onPressed: () => bloc.add(DepositItemPressed(item.id)),
            ),
          const Heading('Banked — safe from death'),
          if (state.profile.bank.isEmpty)
            const NothingHere('The vault is empty.'),
          for (final item in state.profile.bank)
            ItemRow(
              marking: item.rarity.marking,
              name: item.displayName,
              action: 'Take out',
              onPressed: () => bloc.add(WithdrawItemPressed(item.id)),
            ),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
      ),
    ),
  );
}
