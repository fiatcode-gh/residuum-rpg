import 'dart:math';

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
///
/// **The pending brew count is view state, not game state.** It is a dial — a
/// thing the player is about to do, not something that happened — so it lives
/// in this screen's own [State] and dies with the screen. The cap clamps at the
/// actual resources, both of them: herbs and free pack room. Committing calls
/// the one existing core transaction once per attempt, one draw each — a batch
/// is not atomic, and the craft stream advances once per unit of work.
class AlchemistScreen extends StatefulWidget {
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
  State<AlchemistScreen> createState() => _AlchemistScreenState();
}

class _AlchemistScreenState extends State<AlchemistScreen> {
  int _pending = 0;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) {
        final herbCap =
            countOf(state.profile.materials, MaterialId.herb) ~/ brewCost;
        final room = inventoryCap - state.profile.inventory.length;
        final cap = min(herbCap, room);
        final pending = _pending.clamp(0, cap);
        return TownRoom(
          title: 'Alchemist',
          children: [
            Purse(carried: state.gold, banked: state.bankedGold),
            const SizedBox(height: 10),
            MaterialsPanel(materials: state.materials),
            Notice(state.notice),
            const Heading('Brewing'),
            Text('$brewCost herbs make 1 healing potion.', style: mono),
            Text(
              'The shelf asks ${AlchemistScreen._worth()} gold for one.',
              style: monoDim,
            ),
            const SizedBox(height: 16),
            CountStepper(
              value: pending,
              cap: cap,
              onChanged: (next) => setState(() => _pending = next),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: pending <= 0
                  ? null
                  : () {
                      bloc.add(BrewPressed(pending));
                      setState(() => _pending = 0);
                    },
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
        );
      },
    );
  }
}
