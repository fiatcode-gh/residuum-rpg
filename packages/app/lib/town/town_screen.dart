import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart' show residuumTheme;
import '../world/world_bloc.dart';
import 'alchemist_screen.dart';
import 'bank_screen.dart';
import 'forge_screen.dart';
import 'character_screen.dart';
import 'illustration.dart';
import 'inn_screen.dart';
import 'merchant_screen.dart';
import 'tavern_screen.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// One town: a header, a status block and seven doors, each saying what it
/// is for.
///
/// A menu rather than a map, which is the design's own choice and not a
/// shortcut — there is nothing to explore in a town, and a walkable one would
/// charge the player footsteps for a shop they can already see.
///
/// **The town's name is the header, not the title bar.** The `AppBar` carries
/// only the automatically inserted back button, which is the way out of town
/// now that entering a dungeon is offered at the dungeon's own node. The
/// roster moved to the world screen for a structural reason — see
/// `WorldScreen.onOpenRoster`.
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
/// number each, each door carries a purpose line rather than a mark, and every
/// refusal is a sentence.
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
  Widget build(BuildContext context) => Theme(
    data: residuumTheme,
    child: Scaffold(
      appBar: AppBar(backgroundColor: panel, foregroundColor: ink),
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
                        Text(_titleFor(state.town), style: placeName),
                        const SizedBox(height: 4),
                        Text(
                          _descentsSoFar(state.profile.visit),
                          style: monoDim,
                        ),
                        const Divider(color: rule, height: 28),
                        Text(
                          'Health   ${state.hp} / ${state.maxHp}',
                          style: mono,
                        ),
                        Text('Carried  ${state.gold} gold', style: mono),
                        Text('Banked   ${state.bankedGold} gold', style: mono),
                        const Heading('Materials'),
                        MaterialRows(materials: state.materials),
                        Notice(state.notice),
                        if (state.town == stonebridge)
                          const Illustration(
                            EnvironmentArt.stonebridge,
                            height: townIllustrationHeight,
                            key: townIllustrationKey,
                          ),
                        const Spacer(),
                        _Door(
                          key: const Key('town-door-merchant'),
                          label: 'Merchant',
                          purpose: 'Buy, sell, and buy back',
                          onPressed: () =>
                              _open(context, const MerchantScreen()),
                        ),
                        _Door(
                          key: const Key('town-door-bank'),
                          label: 'Bank',
                          purpose: 'Gold and gear, safe from death',
                          onPressed: () => _open(context, const BankScreen()),
                        ),
                        _Door(
                          key: const Key('town-door-inn'),
                          label: 'Inn',
                          purpose: 'A bed for the night',
                          onPressed: () => _open(context, const InnScreen()),
                        ),
                        _Door(
                          key: const Key('town-door-character'),
                          label: 'Character',
                          purpose: 'Gear, spells, skills, and pack',
                          onPressed: () =>
                              _open(context, const CharacterScreen()),
                        ),
                        _Door(
                          key: const Key('town-door-tavern'),
                          label: 'Tavern',
                          purpose: 'Ask about the roads',
                          onPressed: () => _open(context, const TavernScreen()),
                        ),
                        _Door(
                          key: const Key('town-door-forge'),
                          label: 'Forge',
                          purpose: 'Smelt ore, temper steel',
                          onPressed: () => _open(context, const ForgeScreen()),
                        ),
                        _Door(
                          key: const Key('town-door-alchemist'),
                          label: 'Alchemist',
                          purpose: 'Brew herbs into potions',
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
  const _Door({
    required this.label,
    required this.purpose,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String purpose;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(color: rule, height: 1),
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: mono),
            const SizedBox(height: 2),
            Text(purpose, style: monoDim),
          ],
        ),
      ),
    ],
  );
}
