import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../world/world_bloc.dart';
import 'alchemist_screen.dart';
import 'bank_screen.dart';
import 'forge_screen.dart';
import 'character_screen.dart';
import 'inn_screen.dart';
import 'merchant_screen.dart';
import 'tavern_screen.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// One town: seven doors, a purse and what the hero has gathered.
///
/// A menu rather than a map, which is the design's own choice and not a
/// shortcut — there is nothing to explore in a town, and a walkable one would
/// charge the player footsteps for a shop they can already see.
///
/// **Pushed over the world screen, and named in its own title bar.** The way
/// down is not here any more: entering a dungeon is offered at the dungeon's own
/// node, so leaving town is the back button and nothing else. The roster moved
/// to the world screen for a structural reason — see `WorldScreen.onOpenRoster`.
///
/// **The forge and the alchemist are in both towns, like the inn.** A one-town
/// forge has real friction either way round: Northgate starts undiscovered, so a
/// fresh hero could not temper at all, and a Stonebridge-only forge would park
/// it at the cheap end of the world. Per-town difference stays the shelf's job.
///
/// Seven doors is two more than the column was written for, which is why the
/// scroll wrapper below matters rather than being decoration — the device pass
/// checks that the last door is reachable on a phone.
///
/// Nothing here is told apart by colour. Carried and banked gold are two
/// labelled rows in a fixed order, the materials are a mark and a word and a
/// number each, and every refusal is a sentence.
class TownScreen extends StatelessWidget {
  const TownScreen({super.key});

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
    appBar: AppBar(
      title: BlocBuilder<TownBloc, TownViewState>(
        builder: (context, state) => Text(
          _titleFor(state.town),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
      backgroundColor: panel,
      foregroundColor: ink,
    ),
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
                      Text(_descentsSoFar(state.profile.visit), style: monoDim),
                      const Divider(color: rule, height: 28),
                      Text(
                        'Health   ${state.hp} / ${state.maxHp}',
                        style: mono,
                      ),
                      Text('Carried  ${state.gold} gold', style: mono),
                      Text('Banked   ${state.bankedGold} gold', style: mono),
                      const Divider(color: rule, height: 28),
                      MaterialRows(materials: state.materials),
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
                        label: 'Character',
                        onPressed: () =>
                            _open(context, const CharacterScreen()),
                      ),
                      _Door(
                        label: 'Tavern',
                        onPressed: () => _open(context, const TavernScreen()),
                      ),
                      _Door(
                        label: 'Forge',
                        onPressed: () => _open(context, const ForgeScreen()),
                      ),
                      _Door(
                        label: 'Alchemist',
                        onPressed: () =>
                            _open(context, const AlchemistScreen()),
                      ),
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

  /// What the title bar calls this town.
  ///
  /// Read off the world map rather than stored, so a town renamed in content is
  /// renamed on the screen that draws it and nowhere else has to be told.
  static String _titleFor(NodeId town) => residuumWorld.nodeAt(town).name;

  /// Pushes one of the town's rooms with both blocs above it.
  ///
  /// Both, because the tavern is the one room that touches the world as well as
  /// the hero — it spends coin to widen the map — and a room that could only
  /// reach one of them would have to work the other half out for itself.
  static void _open(BuildContext context, Widget screen) {
    final town = context.read<TownBloc>();
    final world = context.read<WorldBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: town),
            BlocProvider.value(value: world),
          ],
          child: screen,
        ),
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
