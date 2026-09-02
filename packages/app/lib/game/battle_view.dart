import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../town/town_style.dart';
import 'game_bloc.dart';

/// The battle screen: what holds reach on the hero, played per round.
///
/// **A view over the map, not a second board.** Every fact here is a pure
/// getter over the state the crawl already shows — the stage reads
/// `monstersHoldingReach`, the strip reads the turn schedule, the bar reads
/// the known spells — so the fight the rules see is exactly the fight this
/// tree draws. The section swaps in for the map while something holds reach
/// and out again when nothing does; the vitals row, the control row, the log
/// and the death overlay never move.
///
/// Nothing is told apart by hue: a creature is its glyph and its name, its
/// wound is a bar's length and two numbers, its reach is a word, and an armed
/// spell is a word beside its own name.
class BattleView extends StatelessWidget {
  const BattleView({super.key, required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (final monster in state.monstersHoldingReach)
                  _StageCard(
                    monster: monster,
                    onTap: () => bloc.add(
                      state.armedSpellId == null
                          ? TileTapped(monster.position)
                          : CastPressed(
                              state.armedSpellId!,
                              targetId: monster.id,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _TurnStrip(state: state),
        if (state.game.knownSpells.isNotEmpty)
          _SkillBar(state: state, bloc: bloc),
      ],
    );
  }
}

/// One creature on the stage: glyph, name, wound, and how far it stands.
class _StageCard extends StatelessWidget {
  const _StageCard({required this.monster, required this.onTap});

  final Actor monster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = monster.maxHp == 0 ? 0.0 : monster.hp / monster.maxHp;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  monster.glyph,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monster.name,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: fraction.clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: rule,
                              valueColor: const AlwaysStoppedAnimation(ink),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${monster.hp} / ${monster.maxHp}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: dim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (monster.reach > 1)
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    'at range',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: dim,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line under the stage: who acts before the hero again, who walks in.
///
/// Greyscale-safe by position and word: `Next:` names the schedule's first,
/// each walker-in carries its own count of the hero actions it needs.
class _TurnStrip extends StatelessWidget {
  const _TurnStrip({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Wrap(
      spacing: 12,
      children: [
        if (state.upNext.isNotEmpty)
          Text(
            'Next: ${state.upNext.first.name}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: dim,
            ),
          ),
        for (final (monster, turns) in state.arrivals)
          Text(
            '${monster.name} — $turns turns out',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: dim,
            ),
          ),
      ],
    ),
  );
}

/// One button per known spell: marking, name, cost — wrap-flow, so a full
/// grimoire wraps instead of scrolling.
///
/// **A tap arms; it never casts at a guess.** The named cast happens when a
/// stage card is tapped, and Mend and Ward — which land on the hero — cast
/// straight from the bar without asking for one. A refusal is the rules'
/// sentence in the log, never a dimmed button: the bar does not read
/// `castRefusal` at all, because a greyed control is a guess the player has
/// to work past.
class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.state, required this.bloc});

  final GameViewState state;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final spell in state.knownSpells)
          TextButton(
            onPressed: () => bloc.add(
              spell.kind == SpellKind.mend || spell.kind == SpellKind.ward
                  ? CastPressed(spell.id)
                  : SkillArmed(spell.id),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: state.armedSpellId == spell.id
                  ? const BorderSide(color: ink)
                  : null,
            ),
            child: Text(
              state.armedSpellId == spell.id
                  ? '${spell.school.schoolMarking} ${spell.name} '
                        '${spell.manaCost} — armed'
                  : '${spell.school.schoolMarking} ${spell.name} '
                        '${spell.manaCost}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: ink,
              ),
            ),
          ),
      ],
    ),
  );
}
