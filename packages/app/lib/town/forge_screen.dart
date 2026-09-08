import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../game/item_presentation.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// The forge: a smelter and a bench.
///
/// Two things happen here and they are read top to bottom in the order the hero
/// does them — ore becomes iron, iron goes into a blade. A player who has just
/// walked out of a mine reads the screen in the order of the work.
///
/// **Nothing on it is told apart by colour.** The materials are a mark, a word
/// and a number; a row that cannot be worked carries the sentence saying why
/// rather than going quietly grey; a temper is a word and a signed number in the
/// item's own stat line. And every row's price is on the row: a refusal never
/// takes the next tier's cost down with it.
class ForgeScreen extends StatelessWidget {
  const ForgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) {
        final workable = state.temperable;
        return TownRoom(
          title: 'Forge',
          children: [
            Purse(carried: state.gold, banked: state.bankedGold),
            const SizedBox(height: 10),
            MaterialsPanel(materials: state.materials),
            Notice(state.notice),
            const Heading('Smelting'),
            Text('$smeltCost ore makes 1 ingot.', style: mono),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: state.smeltReason == null
                  ? () => bloc.add(const SmeltPressed())
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Smelt',
                style: TextStyle(fontFamily: 'monospace', fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              state.smeltReason == null
                  ? 'The fire is hot and the ore is ready.'
                  : _capitalised(state.smeltReason!),
              style: monoDim,
            ),
            const Heading('The bench'),
            if (workable.isEmpty)
              const NothingHere('You have no steel for the bench.')
            else ...[
              const Heading('Worn steel'),
              if (state.wornSteel.isEmpty)
                const NothingHere('You are wearing no steel.'),
              for (final item in state.wornSteel)
                _TemperRow(
                  item: item,
                  reason: state.temperReason(item.id),
                  onTemper: () => bloc.add(TemperPressed(item.id)),
                ),
              const Heading('Carried steel'),
              if (state.carriedSteel.isEmpty)
                const NothingHere('You are carrying no steel.'),
              for (final item in state.carriedSteel)
                _TemperRow(
                  item: item,
                  reason: state.temperReason(item.id),
                  onTemper: () => bloc.add(TemperPressed(item.id)),
                ),
            ],
          ],
        );
      },
    );
  }

  static String _capitalised(String text) =>
      '${text[0].toUpperCase()}${text.substring(1)}.';
}

/// One piece of steel the bench could work, and what the next tier costs.
///
/// **The row wears its price whether or not it can be worked.** The refusal
/// sentence and the price line are two lines, not one slot: a row gated on
/// Blacksmith still says what its next tier costs, because a hero saving up
/// for the day they reach it reads the price from exactly this row. A row at
/// the ceiling names no price, because there is no next tier to price.
///
/// The button goes dead with the sentence beside it rather than disappearing,
/// which is the inn's rule: a control that vanishes teaches nothing, and a hero
/// four Blacksmith levels short of the next tier should be able to read exactly
/// that.
class _TemperRow extends StatelessWidget {
  const _TemperRow({
    required this.item,
    required this.reason,
    required this.onTemper,
  });

  final Item item;
  final String? reason;
  final VoidCallback onTemper;

  @override
  Widget build(BuildContext context) {
    final price = item.temper < maxTemper ? temperPriceFrom(item.temper) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(item.rarity.marking, style: mono),
              ),
              Expanded(child: Text(item.displayName, style: mono)),
              TextButton(
                onPressed: reason == null ? onTemper : null,
                child: const Text(
                  'Temper',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(statLine(item), style: monoDim),
          ),
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(reason!, style: monoDim),
            ),
          if (price != null)
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                'Next tier: ${price.ingots} '
                '${price.ingots == 1 ? 'ingot' : 'ingots'}.',
                style: monoDim,
              ),
            ),
        ],
      ),
    );
  }
}
