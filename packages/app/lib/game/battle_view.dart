import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../town/town_style.dart';
import 'game_bloc.dart';
import 'activation_timeline.dart';
import 'actor_presentation.dart';

/// The battle dock: a compact, accessible view of the upcoming activations
/// over the live map.
///
/// The dock remains a view over the map rather than a second board. Its only
/// interactive surface is timeline inspection, which cannot dispatch a game
/// action or alter the simulation.
const Color dockBacking = Color(0xB30E1015);

class BattleDock extends StatelessWidget {
  const BattleDock({
    super.key,
    required this.state,
    required this.onActorSelected,
  });

  final GameViewState state;
  final ValueChanged<Actor> onActorSelected;

  @override
  Widget build(BuildContext context) {
    final queue = state.activationQueue;
    return Container(
      key: const Key('dock-backing'),
      color: dockBacking,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (
                var queueIndex = 0;
                queueIndex < queue.length;
                queueIndex++
              ) ...[
                if (queueIndex > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '›',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        color: dim,
                      ),
                    ),
                  ),
                _TimelineToken(
                  token: queue[queueIndex],
                  queueIndex: queueIndex,
                  state: state,
                  onActorSelected: onActorSelected,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineToken extends StatelessWidget {
  const _TimelineToken({
    required this.token,
    required this.queueIndex,
    required this.state,
    required this.onActorSelected,
  });

  final ActivationToken token;
  final int queueIndex;
  final GameViewState state;
  final ValueChanged<Actor> onActorSelected;

  @override
  Widget build(BuildContext context) {
    if (token case final HeroActivationToken hero) {
      return Semantics(
        label: hero.isCurrent
            ? 'You, current activation'
            : 'You, next activation',
        child: Container(
          key: Key(
            hero.isCurrent ? 'timeline-current-hero' : 'timeline-next-hero',
          ),
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          alignment: Alignment.center,
          child: const Text(
            '@ YOU',
            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: ink),
          ),
        ),
      );
    }

    final actor = (token as ActorActivationToken).actor;
    final presentation = state.presentationOf(actor.id);
    if (presentation == null) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: presentation.displayName,
      child: InkWell(
        key: Key('timeline-actor-${actor.id}-$queueIndex'),
        onTap: () => onActorSelected(actor),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            presentation.glyphLabel,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the enemy's numbers over the crawl: name, glyph, wounds, attack,
/// reach, speed, and what the creature's make of.
///
/// The presentation label is supplied by the encounter-local identity context;
/// stats and resistances still come directly from [monster].
void showEnemyInfo(
  BuildContext context,
  Actor monster,
  ActorPresentation presentation,
) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    presentation.glyphLabel,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      presentation.displayName,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _EnemyInfoLine('Wounds ${monster.hp} / ${monster.maxHp}'),
              _EnemyInfoLine('${monster.attackMin}–${monster.attackMax}'),
              _EnemyInfoLine(
                monster.reach > 1
                    ? 'strikes at range ${monster.reach}'
                    : 'strikes adjacent',
              ),
              _EnemyInfoLine('Speed ${monster.speed}'),
              for (final type in monster.resists)
                _EnemyInfoLine('Resists ${type.word}'),
              for (final type in monster.vulnerableTo)
                _EnemyInfoLine('Burns at ${type.word}'),
            ],
          ),
        ),
      ),
    ),
  );
}

/// One line of the enemy sheet, monospace and dim.
class _EnemyInfoLine extends StatelessWidget {
  const _EnemyInfoLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(
      text,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: ink),
    ),
  );
}
