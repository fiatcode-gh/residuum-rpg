import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

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
/// labelled rows in a fixed order, every refusal is a sentence, and the way down
/// is one door or two labelled ones — never the same door meaning two things.
class TownScreen extends StatelessWidget {
  const TownScreen({
    required this.onEnterDungeon,
    required this.onResumeCrawl,
    required this.onDelveAnew,
    required this.onOpenRoster,
    super.key,
  });

  /// Starts a crawl. The session owns it, because the session owns the autosaver
  /// that has to watch it.
  final Future<void> Function() onEnterDungeon;

  /// Walks back into the crawl the hero left standing.
  final Future<void> Function() onResumeCrawl;

  /// Gives that crawl up and walks into one laid out afresh.
  final Future<void> Function() onDelveAnew;

  /// Opens the roster: every hero on this install, and the three things that can
  /// be done about them.
  ///
  /// The session owns it, because every answer the roster gives ends with the
  /// whole bloc tree being rebuilt.
  final Future<void> Function() onOpenRoster;

  /// The purse at the top, the doors at the bottom, and a scroll between them
  /// when a short screen cannot hold both.
  ///
  /// The doors sit at the bottom because that is where a thumb is, and the
  /// [Spacer] is what puts them there — so the column needs a bounded height,
  /// which is what [IntrinsicHeight] under a minimum-height [ConstrainedBox]
  /// gives it. With room to spare the screen looks exactly as it always has;
  /// without it, it scrolls instead of clipping. It has to, now that the way down
  /// can be two doors rather than one: the fork overflowed a 600-pixel screen by
  /// 45 pixels, and a door a player cannot reach is a door that is not there.
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<TownBloc, TownViewState>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, room) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: room.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
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
                      Text(
                        'Health   ${state.hp} / ${state.maxHp}',
                        style: mono,
                      ),
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
                      if (state.suspended case final GameState camp) ...[
                        _Door(
                          label: 'Resume the crawl (depth ${camp.depth})',
                          onPressed: onResumeCrawl,
                        ),
                        _Door(
                          label: 'Delve anew',
                          onPressed: () => _confirmDelveAnew(context, camp),
                        ),
                      ] else
                        _Door(
                          label: 'Enter Dungeon',
                          onPressed: onEnterDungeon,
                        ),
                      const SizedBox(height: 8),
                      _Door(label: 'Heroes', onPressed: onOpenRoster),
                    ],
                  ),
                ),
              ),
            ),
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

  /// Asks once, in words, before a crawl the hero could walk back into is given
  /// up.
  ///
  /// **Nothing the hero earned is at stake, and the sentence says so.** Walking
  /// out at the stairs already brought their hit points, gear, training, pack and
  /// purse home; what dies here is the depth reached and the floors as they
  /// stand. Saying that plainly is what stops the question reading like a threat
  /// to a hero — and the depth is named, because it is the one thing being spent
  /// and the player may well not remember it.
  ///
  /// It is asked at all because the loss is invisible until it is too late: a
  /// silent abandon looks exactly like a resume until the player is standing on
  /// floor one wondering where their dungeon went.
  ///
  /// Both answers are the outcome in words rather than Yes and No, following the
  /// roster's delete confirmation: a dialog answered by reading one word is a
  /// dialog that reads in greyscale and reads aloud.
  Future<void> _confirmDelveAnew(BuildContext context, GameState camp) async {
    final given = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text(
          'Delve anew?',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        content: Text(
          'The crawl waiting at depth ${camp.depth} is given up, and the '
          'dungeon is laid out afresh from floor one. Everything you carry, '
          'bank and know comes with you — only the floors are lost.',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text(
              'Keep the crawl',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text(
              'Give it up',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
    if (!(given ?? false) || !context.mounted) return;
    await onDelveAnew();
  }

  static void _open(BuildContext context, Widget screen) {
    final bloc = context.read<TownBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: bloc, child: screen),
      ),
    );
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
