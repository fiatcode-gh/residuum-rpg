import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'town_bloc.dart';
import 'town_style.dart';

/// The alchemist: one pot, one recipe.
///
/// The inn's shape rather than the merchant's, because there is one thing to buy
/// and it is not bought with coin. The button goes dead with its sentence beside
/// it instead of disappearing, so a hero one herb short reads exactly that.
class AlchemistScreen extends StatelessWidget {
  const AlchemistScreen({super.key});

  /// What the pot would make, priced the way the shelf prices it.
  ///
  /// Read off the same [sellPriceOf] the merchant uses rather than written here,
  /// so a brewed potion and a bought one cannot come to be worth different
  /// things — and the number tells the player what the gathering was worth.
  static int _worth() => buyPriceOf(
    const Item(id: 'brew-0', base: healingPotion, rarity: Rarity.common),
  );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) => TownRoom(
        title: 'Alchemist',
        children: [
          Purse(carried: state.gold, banked: state.bankedGold),
          const SizedBox(height: 10),
          MaterialsPanel(materials: state.materials),
          Notice(state.notice),
          const Heading('Brewing'),
          Text('$brewCost herbs make 1 healing potion.', style: mono),
          Text('The shelf asks ${_worth()} gold for one.', style: monoDim),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.brewReason == null
                ? () => bloc.add(const BrewPressed())
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Brew',
              style: TextStyle(fontFamily: 'monospace', fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.brewReason == null
                ? 'The pot is on and you have what it takes.'
                : '${state.brewReason![0].toUpperCase()}'
                      '${state.brewReason!.substring(1)}.',
            style: monoDim,
          ),
        ],
      ),
    );
  }
}
