import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';

import 'town_bloc.dart';
import 'town_style.dart';

/// The inn: one bed, one price, one button.
///
/// The button goes dead rather than disappearing when the hero has nothing
/// wrong with it, because a control that vanishes teaches nothing — a hero at
/// full health should be able to see what a bed would have cost.
///
/// **The dead button covers two cases and used to explain one.** A hero with
/// nothing wrong with them was told so; a hero who simply could not pay was
/// shown a bed's price and a dead button and left to work out which of the two
/// it was. Both now get their sentence, and the short purse gets the arithmetic
/// with it.
class InnScreen extends StatelessWidget {
  const InnScreen({super.key});

  /// Why the bed is not available, or what a night in it does.
  ///
  /// Health first: a hero at full health has nothing to buy whatever their purse
  /// says, and telling them the price is short would be answering a question
  /// they did not ask.
  static String _why(TownViewState state) {
    if (!state.canRest) return 'There is nothing wrong with you.';
    if (state.gold < innPrice) {
      return 'A night costs $innPrice and you carry ${state.gold}.';
    }
    return 'A night here mends everything the dungeon did.';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) => TownRoom(
        title: 'Inn',
        children: [
          Purse(carried: state.gold, banked: state.bankedGold),
          Notice(state.notice),
          const Heading('A bed for the night'),
          Text('Health   ${state.hp} / ${state.maxHp}', style: mono),
          Text('Price    $innPrice gold', style: mono),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.canRest && state.gold >= innPrice
                ? () => bloc.add(const RestPressed())
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Rest',
              style: TextStyle(fontFamily: 'monospace', fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          Text(_why(state), style: monoDim),
        ],
      ),
    );
  }
}
