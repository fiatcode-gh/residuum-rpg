import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../town/town_bloc.dart';
import '../town/town_style.dart';
import 'world_bloc.dart';

/// The overworld: where the hero is, where they could go, and what is here.
///
/// **The bottom of the navigator.** Towns push over it, the crawl pushes over
/// it, and every one of them comes home with one pop — which is the shape the
/// crawl's exits were already built for.
///
/// Nothing is told apart by colour. A place carries a bracketed marker whose
/// shape and letter say what kind it is, its name in words, and a phrase saying
/// how it stands to the hero. A place nobody has heard of is a row of question
/// marks rather than a dimmer version of a name, so the map reads in greyscale
/// and reads aloud.
class WorldScreen extends StatelessWidget {
  const WorldScreen({
    required this.onEnterTown,
    required this.onEnterDungeon,
    required this.onResumeCrawl,
    required this.onDelveAnew,
    required this.onOpenRoster,
    super.key,
  });

  /// Opens the town the hero is standing in.
  final Future<void> Function() onEnterTown;

  /// Walks into a dungeon laid out afresh.
  final Future<void> Function() onEnterDungeon;

  /// Walks back into the crawl the hero left standing.
  final Future<void> Function() onResumeCrawl;

  /// Gives that crawl up and walks into one laid out afresh.
  final Future<void> Function() onDelveAnew;

  /// Opens the roster.
  ///
  /// **It lives here rather than in a town, and that is not decoration.** The
  /// roster's answers rebuild the whole session, and a rebuild swaps the
  /// navigator's bottom route without clearing anything pushed on top of it — so
  /// a roster reached through a pushed town screen would leave the new hero's
  /// world underneath the old hero's town, holding a bloc that had just been
  /// closed. Reached from here, the stack is only ever this route deep when the
  /// rebuild happens.
  final Future<void> Function() onOpenRoster;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<WorldBloc, WorldViewState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _Standing(state: state),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Heading('The world'),
                  for (final node in context.read<WorldBloc>().map.nodes)
                    _Place(
                      node: node,
                      state: state,
                      onGo: () => _confirmTravel(context, node, state),
                    ),
                  for (final unknown in _unheardOf(context, state))
                    _Unheard(key: ValueKey(unknown.value)),
                  Notice(state.notice),
                  if (state.log.isNotEmpty) ...[
                    const Heading('The road so far'),
                    for (final line in state.log.reversed.take(8))
                      Text(line, style: monoDim),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _Here(
                state: state,
                onEnterTown: onEnterTown,
                onEnterDungeon: onEnterDungeon,
                onResumeCrawl: onResumeCrawl,
                onDelveAnew: onDelveAnew,
                onOpenRoster: onOpenRoster,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// The places on the map the hero has never been told about.
  static List<NodeId> _unheardOf(BuildContext context, WorldViewState state) =>
      [
        for (final node in context.read<WorldBloc>().map.nodes)
          if (!state.world.discovered.contains(node.id)) node.id,
      ];

  /// Asks before spending days, and says how many.
  ///
  /// Asked at all because days are the road's price and the player cannot get
  /// them back — the whole point of the overworld is that walking somewhere
  /// costs something, so a mis-tap must not spend it.
  Future<void> _confirmTravel(
    BuildContext context,
    WorldNode node,
    WorldViewState state,
  ) async {
    final world = context.read<WorldBloc>();
    final road = world.map.routeBetween(state.at, node.id);
    if (road == null) return;
    final days = road.days == 1 ? 'One day' : '${road.days} days';
    final go = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          'Walk to ${node.name}?',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        content: Text(
          '$days on the road. Every day is a chance of meeting something, '
          'and the days pass whether you meet anything or not.',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text(
              'Stay here',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text(
              'Set out',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
    if (!(go ?? false)) return;
    world.add(TravelRequested(node.id));
  }
}

/// Where the hero is and how they are, in words.
class _Standing extends StatelessWidget {
  const _Standing({required this.state});

  final WorldViewState state;

  @override
  Widget build(BuildContext context) {
    final map = context.read<WorldBloc>().map;
    final journey = state.world.journey;
    final where = journey == null
        ? 'At ${map.nodeAt(state.at).name}'
        : 'On the road to ${map.nodeAt(journey.to).name}';
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, town) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 6),
          Text(where, style: mono),
          Text(_dayLine(state, journey), style: monoDim),
          const Divider(color: rule, height: 20),
          Text('Health   ${town.hp} / ${town.maxHp}', style: mono),
          Text('Carried  ${town.gold} gold', style: mono),
          Text('Banked   ${town.bankedGold} gold', style: mono),
        ],
      ),
    );
  }

  static String _dayLine(WorldViewState state, Journey? journey) {
    if (journey == null) return 'Day ${state.world.day}.';
    final left = journey.daysLeft == 1 ? 'one day' : '${journey.daysLeft} days';
    return 'Day ${state.world.day}. $left still to walk.';
  }
}

/// One place on the map, and the control that walks to it.
class _Place extends StatelessWidget {
  const _Place({required this.node, required this.state, required this.onGo});

  final WorldNode node;
  final WorldViewState state;
  final VoidCallback onGo;

  /// The marker for a kind of place: shape and letter, never a hue.
  static String markerFor(NodeKind kind) => switch (kind) {
    NodeKind.town => '[T]',
    NodeKind.dungeon => '(D)',
  };

  @override
  Widget build(BuildContext context) {
    if (!state.world.discovered.contains(node.id)) {
      return const SizedBox.shrink();
    }
    final here = node.id == state.at && !state.isTravelling;
    final reachable = state
        .destinationsFrom(context.read<WorldBloc>().map)
        .any((other) => other.id == node.id);
    return ItemRow(
      marking: markerFor(node.kind),
      name: here ? '${node.name} — you are here' : node.name,
      action: here ? 'Here' : 'Walk',
      onPressed: here || state.isTravelling || !reachable ? null : onGo,
    );
  }
}

/// A place the hero has heard nothing about.
///
/// Drawn rather than left out, because a map with nothing missing from it is a
/// menu — and a tavern that sells directions has to be visibly worth the coin.
class _Unheard extends StatelessWidget {
  const _Unheard({super.key});

  @override
  Widget build(BuildContext context) => const ItemRow(
    marking: '[?]',
    name: 'Somewhere you have not heard of',
    action: 'Unknown',
    onPressed: null,
  );
}

/// What standing here lets the hero do.
class _Here extends StatelessWidget {
  const _Here({
    required this.state,
    required this.onEnterTown,
    required this.onEnterDungeon,
    required this.onResumeCrawl,
    required this.onDelveAnew,
    required this.onOpenRoster,
  });

  final WorldViewState state;
  final Future<void> Function() onEnterTown;
  final Future<void> Function() onEnterDungeon;
  final Future<void> Function() onResumeCrawl;
  final Future<void> Function() onDelveAnew;
  final Future<void> Function() onOpenRoster;

  @override
  Widget build(BuildContext context) {
    if (state.isTravelling) {
      if (state.walking) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'You are walking. There is nothing here.',
            style: monoDim,
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'You are part way there, and nothing is walking you.',
              style: monoDim,
            ),
          ),
          WorldDoor(
            label: 'Walk on',
            onPressed: () =>
                context.read<WorldBloc>().add(const TravelResumed()),
          ),
        ],
      );
    }
    final map = context.read<WorldBloc>().map;
    final node = map.nodeAt(state.at);
    if (node.kind == NodeKind.town) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorldDoor(label: 'Enter ${node.name}', onPressed: onEnterTown),
          const SizedBox(height: 8),
          WorldDoor(label: 'Heroes', onPressed: onOpenRoster),
        ],
      );
    }
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, town) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._dungeonDoors(context, town.suspended),
          const SizedBox(height: 8),
          WorldDoor(label: 'Heroes', onPressed: onOpenRoster),
        ],
      ),
    );
  }

  /// The way down, which is one door or the M3L fork.
  ///
  /// The fork moved here from the town because entering a dungeon is only
  /// offered at the dungeon's own node now. The words and the confirmation are
  /// the town's, unchanged: what is being decided did not change, only where the
  /// hero stands while deciding it.
  ///
  /// The camp is *watched* rather than read once. It is the town's fact and it
  /// changes while this screen is on top — walking out at the stairs pops back to
  /// here and hands the town a camp in the same breath — so a screen that read it
  /// at build time would come back from a crawl still offering to enter one.
  List<Widget> _dungeonDoors(BuildContext context, GameState? camp) {
    if (camp == null) {
      return [WorldDoor(label: 'Enter Dungeon', onPressed: onEnterDungeon)];
    }
    return [
      WorldDoor(
        label: 'Resume the crawl (depth ${camp.depth})',
        onPressed: onResumeCrawl,
      ),
      WorldDoor(
        label: 'Delve anew',
        onPressed: () => _confirmDelveAnew(context, camp),
      ),
    ];
  }

  /// Asks once, in words, before a crawl the hero could walk back into is given
  /// up.
  ///
  /// Verbatim the town's question, for the reason the fork itself is: nothing
  /// about the decision changed when it moved node, and rewording it would let
  /// two copies of one sentence drift.
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
}

/// One full-width door, as the world screen draws them.
class WorldDoor extends StatelessWidget {
  const WorldDoor({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
      ),
    ),
  );
}
