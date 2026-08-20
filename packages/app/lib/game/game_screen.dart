import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import 'game_bloc.dart';
import 'glyph_grid.dart';
import 'inventory_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<GameBloc, GameViewState>(
        builder: (context, state) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GlyphGrid(
                      state: state,
                      onTap: (position) =>
                          context.read<GameBloc>().add(TileTapped(position)),
                    ),
                  ),
                ),
                _HitPoints(state: state),
                _Controls(state: state),
                _MessageLog(log: state.log),
              ],
            ),
            if (state.game.isGameOver) const _DeathOverlay(),
          ],
        ),
      ),
    ),
  );
}

class _HitPoints extends StatelessWidget {
  const _HitPoints({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final hero = state.game.hero;
    final ceiling = state.maxHp;
    final fraction = ceiling == 0 ? 0.0 : hero.hp / ceiling;
    final shown = hero.hp.clamp(0, ceiling);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1),
                minHeight: 14,
                backgroundColor: const Color(0xFF23262E),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFDDE1E7)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$shown / $ceiling  ${_condition(fraction)}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Color(0xFFDDE1E7),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Depth ${state.depth}/$deepestDepth',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Color(0xFFDDE1E7),
            ),
          ),
        ],
      ),
    );
  }

  static String _condition(double fraction) {
    if (fraction <= 0) return 'Dead';
    if (fraction < 0.25) return 'Critical';
    if (fraction < 0.6) return 'Wounded';
    return 'Steady';
  }
}

/// The one row of controls the crawl needs, each appearing only when it can do
/// something.
///
/// A control that is visible but inert teaches the player nothing; a control
/// that appears exactly when it applies is how the rules explain themselves. The
/// pack is the exception and is always reachable, because looking at what you
/// are carrying is not an action and should never be gated.
class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final underfoot = state.itemsUnderfoot;
    final potion = state.firstPotion;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          if (underfoot.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                underfoot.length == 1
                    ? 'Here: ${underfoot.last.displayName}'
                    : 'Here: ${underfoot.last.displayName} '
                          'and ${underfoot.length - 1} more',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF8A919E),
                ),
              ),
            ),
          Row(
            children: [
              if (state.canPickUp)
                Expanded(
                  child: _Control(
                    label: 'Pick up',
                    onPressed: () => bloc.add(const PickUpPressed()),
                  ),
                ),
              if (potion != null)
                Expanded(
                  child: _Control(
                    label: 'Drink potion',
                    onPressed: state.game.isGameOver
                        ? null
                        : () => bloc.add(const QuickDrinkPressed()),
                  ),
                ),
              Expanded(
                child: _Control(
                  label: 'Pack (${state.game.inventory.length})',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: bloc,
                        child: const InventoryScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.canDescend)
                Expanded(
                  child: _Control(
                    label: 'Descend >',
                    onPressed: () => bloc.add(const DescendPressed()),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    ),
  );
}

class _MessageLog extends StatelessWidget {
  const _MessageLog({required this.log});

  final List<String> log;

  @override
  Widget build(BuildContext context) => Container(
    height: 104,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    color: const Color(0xFF15181F),
    child: ListView.builder(
      reverse: true,
      itemCount: log.length,
      itemBuilder: (context, index) => Text(
        log[log.length - 1 - index],
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(index == 0 ? 0xFFE6EAF0 : 0xFF8A919E),
        ),
      ),
    ),
  );
}

class _DeathOverlay extends StatelessWidget {
  const _DeathOverlay();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xCC0E1014),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'You died.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              color: Color(0xFFE6EAF0),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<GameBloc>().add(const GameStarted()),
            child: const Text('Restart'),
          ),
        ],
      ),
    ),
  );
}
