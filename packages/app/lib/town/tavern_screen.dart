import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../world/world_bloc.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// The tavern: where the map is bought a place at a time.
///
/// **The one screen that spends from the purse to widen the world**, and so the
/// one place two owners are touched by one press. The rule is `buyRumor` in
/// core, which answers with both halves at once — the hero after paying and the
/// map after hearing — and this hands each half to the bloc that owns it. Nothing
/// is decided here; the two dispatches are one synchronous pair, so there is no
/// moment where the gold has gone and the place is still unknown.
class TavernScreen extends StatelessWidget {
  const TavernScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<WorldBloc, WorldViewState>(
    builder: (context, world) => BlocBuilder<TownBloc, TownViewState>(
      builder: (context, town) {
        final offered = world.rumorOnOffer(rumorPool);
        return TownRoom(
          title: 'Tavern',
          children: [
            Purse(carried: town.gold, banked: town.bankedGold),
            const Heading('What they are saying'),
            if (offered == null)
              const NothingHere(
                'Nobody here has anything left to tell you. '
                'You have heard of everywhere they know.',
              )
            else
              ItemRow(
                marking: '[!]',
                name: 'Ask about the roads',
                action: 'Ask $rumorPrice',
                onPressed: () => _ask(context, world, town),
              ),
            Notice(town.notice ?? world.notice),
            const Heading('What you have been told'),
            if (world.log.isEmpty)
              const NothingHere('Nothing yet.')
            else
              for (final line in world.log.reversed.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(line, style: monoDim),
                ),
          ],
        );
      },
    ),
  );

  /// Buys one rumor, and hands each half of the answer to its owner.
  static void _ask(
    BuildContext context,
    WorldViewState world,
    TownViewState town,
  ) {
    final told = buyRumor(town.profile, world.world, rumorPool, rumorPrice);
    context.read<TownBloc>().add(RumorBought(told));
    context.read<WorldBloc>().add(RumorHeard(told));
  }
}
