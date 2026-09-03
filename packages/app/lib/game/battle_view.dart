import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../town/town_style.dart';
import 'game_bloc.dart';

/// The battle dock: what holds reach on the hero, played per round, over a map
/// that never leaves the screen.
///
/// **A view over the map, not a second board — and the map is why this is a
/// dock.** Every fact here is a pure getter over the state the crawl already
/// shows — the stage reads `monstersHoldingReach`, the strip reads the turn
/// schedule, the bar reads the known spells — so the fight the rules see is
/// exactly the fight this tree draws. The dock's rows sit above the map slot
/// while the fight holds and leave when nothing does; the map itself is drawn
/// and tappable the whole time, because a view over a live simulation shows the
/// field the simulation runs on — hiding it, as the full-screen swap once did,
/// stranded every player whose only reach-holder stood beyond arm's length.
/// **The swap stays retired on purpose:** a fight is rows docked over the
/// crawl, never a screen that replaces it, so nobody restores the full-screen
/// battle as a cleanup.
///
/// **The watched auto-path refusal during a fight is deliberate.** Closing on a
/// shooter means tile-by-tile taps while it shoots — the map below the dock
/// makes that cost visible instead of papering over it with a free auto-walk.
///
/// Nothing is told apart by hue: a creature is its glyph and its name, its
/// wound is a bar's length and two numbers, its reach is a word, and an armed
/// spell is a word beside its own name.
/// The translucent dark backing one dock header draws behind its cards and
/// chips, so every dock string reads over any map tile.
const Color dockBacking = Color(0xB30E1015);

class BattleDock extends StatelessWidget {
  const BattleDock({super.key, required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    return Container(
      key: const Key('dock-backing'),
      color: dockBacking,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final monster in state.monstersHoldingReach)
            _StageCard(
              monster: monster,
              onTap: () => bloc.add(StageCardTapped(monster)),
            ),
          _TurnChips(state: state),
        ],
      ),
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

/// One row of chips: who acts before the hero again, who walks in.
///
/// Greyscale-safe by position and word: `NOW —` names the schedule's first —
/// the monster whose turn is next — and each walker-in carries `IN n —` with
/// the hero actions it needs. The words carry the state; the row renders in
/// ink on the dock's backing, never dim over the map.
class _TurnChips extends StatelessWidget {
  const _TurnChips({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Wrap(
      spacing: 12,
      children: [
        if (state.upNext.isNotEmpty)
          Text(
            'NOW — ${state.upNext.first.name}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: ink,
            ),
          ),
        for (final (monster, turns) in state.arrivals)
          Text(
            'IN $turns — ${monster.name}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: ink,
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
class BattleSkillBar extends StatelessWidget {
  const BattleSkillBar({super.key, required this.state, required this.bloc});

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
        TextButton(
          onPressed: () => bloc.add(const WaitPressed()),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            'Wait',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: ink),
          ),
        ),
      ],
    ),
  );
}
