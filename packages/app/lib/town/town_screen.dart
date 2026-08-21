import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../game/game_bloc.dart';
import '../game/game_screen.dart';
import 'bank_screen.dart';
import 'gear_screen.dart';
import 'inn_screen.dart';
import 'merchant_screen.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// The town: four doors and a purse.
///
/// A menu rather than a map, which is the design's own choice and not a
/// shortcut — there is nothing to explore in a town, and a walkable one would
/// charge the player footsteps for a shop they can already see.
///
/// Nothing here is told apart by colour. Carried and banked gold are two
/// labelled rows in a fixed order, and every refusal is a sentence.
class TownScreen extends StatelessWidget {
  const TownScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<TownBloc, TownViewState>(
        builder: (context, state) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'RESIDUUM',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  letterSpacing: 6,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(_descentsSoFar(state.profile.visit), style: monoDim),
              const Divider(color: rule, height: 28),
              Text('Health   ${state.hp} / ${state.maxHp}', style: mono),
              Text('Carried  ${state.gold} gold', style: mono),
              Text('Banked   ${state.bankedGold} gold', style: mono),
              Notice(state.notice),
              const Spacer(),
              _Door(
                label: 'Merchant',
                onPressed: () => _open(context, const MerchantScreen()),
              ),
              _Door(
                label: 'Bank',
                onPressed: () => _open(context, const BankScreen()),
              ),
              _Door(
                label: 'Inn',
                onPressed: () => _open(context, const InnScreen()),
              ),
              _Door(
                label: 'Gear',
                onPressed: () => _open(context, const GearScreen()),
              ),
              const SizedBox(height: 16),
              _Door(label: 'Enter Dungeon', onPressed: () => _enter(context)),
            ],
          ),
        ),
      ),
    ),
  );

  /// How many times the hero has gone down, in words that read as English.
  static String _descentsSoFar(int visit) => switch (visit) {
    0 => 'You have not gone down yet.',
    1 => 'You have gone down once.',
    2 => 'You have gone down twice.',
    _ => 'You have gone down $visit times.',
  };

  static void _open(BuildContext context, Widget screen) {
    final bloc = context.read<TownBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: bloc, child: screen),
      ),
    );
  }

  /// Starts the run, then pushes the crawl on top of the town.
  ///
  /// The town bloc travels down with the game bloc so that the stairs controls
  /// and the death overlay have something to hand the finished run back to.
  /// Popping this route is what returning to town *is*: the town was never
  /// destroyed, only covered up.
  static Future<void> _enter(BuildContext context) async {
    final town = context.read<TownBloc>();
    town.add(const EnterDungeonPressed());
    await town.stream.firstWhere((state) => state.run != null);
    if (!context.mounted) return;
    final run = town.state.run!;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: town),
            BlocProvider(create: (_) => GameBloc(game: run)),
          ],
          child: const GameScreen(),
        ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
      ),
    ),
  );
}
