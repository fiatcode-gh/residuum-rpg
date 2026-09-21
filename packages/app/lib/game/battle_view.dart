import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'activation_timeline.dart';
import 'actor_presentation.dart';
import '../style/tokens.dart';

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
    final hasRemainder = queue.length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: gutter, vertical: rhythm),
      child: CrawlPanel(
        key: const Key('dock-backing'),
        padding: const EdgeInsets.all(crawlPanelPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: crawlTokenWidth,
                  child: Center(child: CrawlRegionLabel('NOW')),
                ),
                if (hasRemainder) ...[
                  // Same glyph and style as the separator in the token row
                  // below, invisible here — this is what keeps the gap
                  // exactly as wide as the chevron actually renders, on
                  // every face, rather than a guessed constant.
                  const Opacity(
                    opacity: 0,
                    child: Text('›', style: textGlyphDim),
                  ),
                  Flexible(child: CrawlRegionLabel('NEXT')),
                ],
              ],
            ),
            const SizedBox(height: rhythm),
            Row(
              children: [
                _TimelineToken(
                  token: queue[0],
                  queueIndex: 0,
                  state: state,
                  onActorSelected: onActorSelected,
                ),
                if (hasRemainder) const Text('›', style: textGlyphDim),
                if (hasRemainder)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            var queueIndex = 1;
                            queueIndex < queue.length;
                            queueIndex++
                          ) ...[
                            if (queueIndex > 1)
                              const Text('›', style: textGlyphDim),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One timeline cell: a ringed glyph over the actor's word, both fitted
/// rather than ellipsised so no label can silently truncate.
class _TimelineCell extends StatelessWidget {
  const _TimelineCell({required this.glyph, required this.word, super.key});

  final String glyph;
  final String word;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: crawlTokenWidth,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: crawlTokenCell,
          height: crawlTokenCell,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: raised,
            border: Border.all(color: rule, width: hairline),
          ),
          child: Text(glyph, style: textGlyph),
        ),
        SizedBox(
          width: crawlTokenWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(word, style: textDetailDim),
          ),
        ),
      ],
    ),
  );
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
        excludeSemantics: true,
        child: _TimelineCell(
          key: Key(
            hero.isCurrent ? 'timeline-current-hero' : 'timeline-next-hero',
          ),
          glyph: '@',
          word: 'You',
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
        child: _TimelineCell(
          glyph: presentation.glyphLabel,
          word: presentation.displayName,
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
