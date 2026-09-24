import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../style/tokens.dart';
import 'activation_timeline.dart';
import 'actor_presentation.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';

/// The battle dock: a compact, accessible view of the upcoming activations
/// over the live map.
///
/// The dock remains a view over the map rather than a second board. Its only
/// interactive surface is timeline inspection, which cannot dispatch a game
/// action or alter the simulation.
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
    final hasNext = queue.length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
      child: SizedBox(
        key: const Key('dock-backing'),
        height: crawlTimelineHeight * crawlScale(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimelineColumn(
              label: 'NOW',
              hitRow: _TimelineToken(
                token: queue[0],
                queueIndex: 0,
                state: state,
                onActorSelected: onActorSelected,
              ),
            ),
            if (hasNext) const _TimelineDivider(),
            Expanded(
              child: !hasNext
                  ? const SizedBox.shrink()
                  : _TimelineColumn(
                      label: 'NEXT',
                      hitRow: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              var queueIndex = 1;
                              queueIndex < queue.length;
                              queueIndex++
                            ) ...[
                              if (queueIndex > 1) const SizedBox(width: 8),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// One timeline column (PLAN.md G8 "Timeline internals"): a `displayLabel`
/// caption over a fixed 44 dp hit row, so NOW and NEXT share one rhythm.
class _TimelineColumn extends StatelessWidget {
  const _TimelineColumn({required this.label, required this.hitRow});

  final String label;
  final Widget hitRow;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: displayLabel),
      const SizedBox(height: 3),
      hitRow,
    ],
  );
}

/// The rule between NOW and NEXT, aligned to the pill band rather than the
/// label above it.
class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 14),
        SizedBox(
          width: 1,
          height: crawlTokenHeight,
          child: ColoredBox(color: crawlDivider),
        ),
      ],
    ),
  );
}

/// One timeline pill: glyph and word in the actor's hue, 24 dp tall, at the
/// top of a 44 dp hit row that is the actor token's own tap target.
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
        excludeSemantics: true,
        child: SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _TimelinePill(
              key: Key(
                hero.isCurrent ? 'timeline-current-hero' : 'timeline-next-hero',
              ),
              glyph: '@',
              word: 'You',
              style: monoToken,
              current: hero.isCurrent,
            ),
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
      excludeSemantics: true,
      child: InkWell(
        key: Key('timeline-actor-${actor.id}-$queueIndex'),
        onTap: () => onActorSelected(actor),
        child: SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _TimelinePill(
              glyph: presentation.glyphLabel,
              word: presentation.displayName,
              style: monoTokenHostile,
            ),
          ),
        ),
      ),
    );
  }
}

/// The pill itself (PLAN.md G8): radius 5, 8 dp horizontal padding, gold
/// border and fill on the current activation, a plain chip border on every
/// other one.
class _TimelinePill extends StatelessWidget {
  const _TimelinePill({
    required this.glyph,
    required this.word,
    required this.style,
    this.current = false,
    super.key,
  });

  final String glyph;
  final String word;
  final TextStyle style;
  final bool current;

  @override
  Widget build(BuildContext context) => Container(
    height: crawlTokenHeight,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      color: current ? crawlGold.withValues(alpha: 0.08) : null,
      border: Border.all(
        color: current ? crawlGold : crawlChipBorder,
        width: current ? 1.5 : 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(glyph, style: style),
        const SizedBox(width: 5),
        Text(word, style: style),
      ],
    ),
  );
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
  showCrawlSheet<void>(
    context,
    children: (sheetContext) => [
      Row(
        children: [
          Text(presentation.glyphLabel, style: textGlyph),
          const SizedBox(width: 10),
          Expanded(child: Text(presentation.displayName, style: textLine)),
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
  );
}

/// One line of the enemy sheet, in the text face and dim.
class _EnemyInfoLine extends StatelessWidget {
  const _EnemyInfoLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(text, style: textLine),
  );
}
