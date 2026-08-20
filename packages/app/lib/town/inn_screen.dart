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
class InnScreen extends StatelessWidget {
  const InnScreen({super.key});

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
          Text(
            state.canRest
                ? 'A night here mends everything the dungeon did.'
                : 'There is nothing wrong with you.',
            style: monoDim,
          ),
        ],
      ),
    );
  }
}
