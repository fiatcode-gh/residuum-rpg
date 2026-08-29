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
/// item's own stat line.
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
              const NothingHere('You have no steel for the bench.'),
            for (final item in workable)
              _TemperRow(
                item: item,
                worn: _isWorn(state, item),
                reason: state.temperReason(item.id),
                onTemper: () => bloc.add(TemperPressed(item.id)),
              ),
          ],
        );
      },
    );
  }

  static bool _isWorn(TownViewState state, Item item) =>
      state.profile.equipment.values.any((worn) => worn.id == item.id);

  static String _capitalised(String text) =>
      '${text[0].toUpperCase()}${text.substring(1)}.';
}

/// One piece of steel the bench could work, and what the next tier costs.
///
/// **Worn pieces say so in a word.** A hero looking at two Iron Swords needs to
/// know which one is on their hip, and the marking column is already spoken for
/// by the tier.
///
/// The button goes dead with the sentence beside it rather than disappearing,
/// which is the inn's rule: a control that vanishes teaches nothing, and a hero
/// four Blacksmith levels short of the next tier should be able to read exactly
/// that.
class _TemperRow extends StatelessWidget {
  const _TemperRow({
    required this.item,
    required this.worn,
    required this.reason,
    required this.onTemper,
  });

  final Item item;
  final bool worn;
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
              Expanded(
                child: Text(
                  worn ? '${item.displayName} (worn)' : item.displayName,
                  style: mono,
                ),
              ),
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
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              reason ??
                  'Next tier: ${price!.ingots} '
                      '${price.ingots == 1 ? 'ingot' : 'ingots'} and '
                      '${price.gold} gold.',
              style: monoDim,
            ),
          ),
        ],
      ),
    );
  }
}
