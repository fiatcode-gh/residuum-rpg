import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  const TownScreen({
    required this.onEnterDungeon,
    required this.onAbandonHero,
    super.key,
  });

  /// Starts a crawl. The session owns it, because the session owns the autosaver
  /// that has to watch it.
  final Future<void> Function() onEnterDungeon;

  /// Gives the hero up, once a person has said yes.
  final VoidCallback onAbandonHero;

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
              _Door(label: 'Enter Dungeon', onPressed: onEnterDungeon),
              const SizedBox(height: 8),
              _Door(
                label: 'Abandon Hero',
                onPressed: () => _confirmAbandon(context),
              ),
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

  /// Asks once, in words, before a hero and their world are deleted.
  ///
  /// Abandoning is the only way a rolled world ends, and closing the app cannot
  /// undo it: both slots go. So the door does not do it — this does, and only
  /// after a person has read a sentence and pressed the word in it. The dialog
  /// is the whole guard, which is why it is checked on a device rather than in a
  /// test: this package has no widget tests by convention.
  Future<void> _confirmAbandon(BuildContext context) async {
    final given = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text(
          'Abandon this hero?',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        content: const Text(
          'Everything they carried, banked and learned is deleted, and their '
          'world is gone. A new hero begins in a new world. This cannot be '
          'undone.',
          style: TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text(
              'Keep this hero',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text(
              'Abandon',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
    if (given ?? false) onAbandonHero();
  }
}

class _Door extends StatelessWidget {
  const _Door({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

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
