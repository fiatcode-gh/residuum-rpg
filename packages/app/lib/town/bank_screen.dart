import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'town_bloc.dart';
import 'town_style.dart';

/// How much gold one button moves. Ten is a nudge, all is the whole purse.
const int _handful = 10;

/// Why a Bank button is dead.
///
/// Under the row rather than on the buttons, because four columns on a phone
/// have no room for a second line each — and the four share exactly two
/// reasons, so two sentences say everything four would.
const String purseIsShort = 'Your purse does not have it.';

/// Why a Take button is dead.
const String vaultIsShort = 'Your vault does not have it.';

/// The vault: what death can reach above, what it cannot below.
///
/// Carried always sits above banked, on this screen and on the town menu, so
/// the position of a row says which side of the death penalty it is on. Gold
/// moves in fixed amounts rather than through a text field, because a number
/// pad on a phone is three taps to do what one button already says.
///
/// **The item rows are never dead, and the gold buttons are.** Banking and
/// taking out an item always work — the pack cap refuses in a notice when it
/// has to — while a purse or a vault that cannot cover a handful leaves two
/// buttons inert with nothing to say. So the reasons are two dim lines under
/// the row rather than a second line on each of four columns, which on a phone
/// would be four columns of ellipsis.
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
          if (state.gold < _handful) Text(purseIsShort, style: monoDim),
          if (state.bankedGold < _handful) Text(vaultIsShort, style: monoDim),
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
