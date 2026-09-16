import 'package:flutter/material.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'game_bloc.dart';
import '../town/town_style.dart';

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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderRow(state: state, dungeon: dungeon),
        const SizedBox(height: 4),
        _ResourceRow(state: state),
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
          child: Text(_placeName(state, dungeon), style: mono),
        ),
      ),
      const SizedBox(width: 8),
      _BattleGlyph(state: state),
      const SizedBox(width: 4),
      Text(_battleWord(state), style: mono),
      const SizedBox(width: 8),
      if (!state.isEncounter)
        SizedBox(
          key: depthPairKey,
          width: 64,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text('${state.depth} / ${state.deepest}', style: mono),
          ),
        ),
    ],
  );
}

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
          child: _Meter(
            key: hpMeterKey,
            label: 'HP',
            value: shown,
            ceiling: ceiling,
            note: _condition(fraction),
          ),
        ),
        if (state.game.knownSpells.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _Meter(
              key: manaMeterKey,
              label: 'Mana',
              value: state.mana,
              ceiling: state.maxMana,
              note: state.warded > 0 ? 'Ward ${state.warded}' : '',
            ),
          ),
        ],
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.value,
    required this.ceiling,
    required this.note,
    super.key,
  });

  final String label;
  final int value;
  final int ceiling;
  final String note;

  @override
  Widget build(BuildContext context) {
    final fill = ceiling == 0 ? 0.0 : (value / ceiling).clamp(0, 1).toDouble();
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('$label $value / $ceiling', style: mono),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 8,
              backgroundColor: rule,
              valueColor: const AlwaysStoppedAnimation(ink),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(note, style: mono),
          ),
        ),
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
      child: Text(glyph ?? '', textAlign: TextAlign.center, style: mono),
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
