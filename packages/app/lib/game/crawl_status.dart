import 'package:flutter/material.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../style/surfaces.dart';
import '../style/tokens.dart';
import 'game_bloc.dart';

const hpMeterKey = Key('hp-meter');
const manaMeterKey = Key('mana-meter');
const depthPairKey = Key('crawl-depth');

/// The crawl's whereabouts header and resource meters, over one crawl state.
///
/// A pure projection, deliberately: it reads no bloc and dispatches nothing,
/// so every fact on it comes in through [state] and [dungeon].
class CrawlStatus extends StatelessWidget {
  const CrawlStatus({required this.state, required this.dungeon, super.key});

  final GameViewState state;
  final NodeId? dungeon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: gutter, vertical: rhythm),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: panel,
            border: Border.all(color: rule, width: hairline),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderRow(state: state, dungeon: dungeon),
              const SizedBox(height: rhythm),
              _ResourceRow(state: state),
            ],
          ),
        ),
        const Divider(height: hairline, thickness: hairline, color: rule),
      ],
    ),
  );
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.state, required this.dungeon});

  final GameViewState state;
  final NodeId? dungeon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(_placeName(state, dungeon), style: displayRoom),
        ),
      ),
      const SizedBox(width: 8),
      _BattleGlyph(state: state),
      const SizedBox(width: 4),
      Text(_battleWord(state), style: textBody),
      const SizedBox(width: 8),
      if (!state.isEncounter)
        SizedBox(
          key: depthPairKey,
          width: 64,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text('${state.depth} / ${state.deepest}', style: textBody),
          ),
        ),
    ],
  );
}

/// A temporary duplicate display (PLAN.md U16.5 Task 08 decision 5): the
/// hero panel now owns [hpMeterKey] and [manaMeterKey] on its own meters,
/// so these render the same facts unkeyed until Task 10 deletes this row.
class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final hero = state.game.hero;
    final ceiling = state.maxHp;
    final fraction = ceiling == 0 ? 0.0 : hero.hp / ceiling;
    final shown = hero.hp.clamp(0, ceiling);
    return Row(
      children: [
        Expanded(
          child: ResourceMeter(
            label: 'HP',
            value: shown,
            ceiling: ceiling,
            tint: MeterTint.health,
            note: _condition(fraction),
          ),
        ),
        if (state.game.knownSpells.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ResourceMeter(
              label: 'Mana',
              value: state.mana,
              ceiling: state.maxMana,
              tint: MeterTint.mana,
              note: state.warded > 0 ? 'Ward ${state.warded}' : '',
            ),
          ),
        ],
      ],
    );
  }
}

/// The fixed-size battle glyph cell in the header row: empty when nothing is
/// in sight, the eye when watched, the crossed marks when engaged.
///
/// Shape and word carry the state — never hue — and the word repeats in the
/// cell beside it, so greyscale reading has two backstops. The cell is
/// fixed-width so the place cell and the depth pair do not shift either way.
class _BattleGlyph extends StatelessWidget {
  const _BattleGlyph({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final glyph = state.isBattleOpen
        ? '✖'
        : state.enemiesInSight > 0
        ? '◉'
        : null;
    return SizedBox(
      width: 18,
      child: Text(glyph ?? '', textAlign: TextAlign.center, style: textBody),
    );
  }
}

String _placeName(GameViewState state, NodeId? dungeon) {
  if (state.isEncounter) return 'THE ROAD';
  if (dungeon == null) return '';
  return residuumWorld.nodeAt(dungeon).name.toUpperCase();
}

String _battleWord(GameViewState state) {
  if (state.isBattleOpen) return 'Engaged ${state.enemiesInSight}';
  if (state.enemiesInSight > 0) return 'Watched ${state.enemiesInSight}';
  return '';
}

String _condition(double fraction) {
  if (fraction <= 0) return 'Dead';
  if (fraction < 0.25) return 'Critical';
  if (fraction < 0.6) return 'Wounded';
  return 'Steady';
}
