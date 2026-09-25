import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../style/tokens.dart';
import 'activation_timeline.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';

const turnOrderMoreKey = Key('turn-order-more');

int tokensThatFit(
  List<double> widths,
  double available,
  double spacing,
  double Function(int hidden) cueWidth,
) {
  final total = widths.length;
  if (total == 0) return 0;

  double sumOfFirst(int count) {
    var sum = 0.0;
    for (var index = 0; index < count; index++) {
      sum += widths[index];
    }
    return sum;
  }

  if (sumOfFirst(total) + spacing * (total - 1) <= available) return total;

  for (var visible = total - 1; visible >= 0; visible--) {
    final hidden = total - visible;
    final rowWidth = sumOfFirst(visible) + spacing * visible + cueWidth(hidden);
    if (rowWidth <= available) return visible;
  }
  return 0;
}

double _measureText(TextStyle style, TextScaler textScaler, String text) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

class _TokenPlan {
  const _TokenPlan({
    required this.key,
    required this.glyph,
    required this.word,
    required this.style,
    required this.current,
    required this.semanticsLabel,
    this.actor,
  });

  final Key key;
  final String glyph;
  final String word;
  final TextStyle style;
  final bool current;
  final String semanticsLabel;
  final Actor? actor;
}

_TokenPlan? _planFor(
  ActivationToken token,
  int queueIndex,
  GameViewState state,
) {
  if (token case final HeroActivationToken hero) {
    return _TokenPlan(
      key: Key(hero.isCurrent ? 'timeline-current-hero' : 'timeline-next-hero'),
      glyph: '@',
      word: 'You',
      style: monoToken,
      current: hero.isCurrent,
      semanticsLabel: hero.isCurrent
          ? 'You, current activation'
          : 'You, next activation',
    );
  }
  final actor = (token as ActorActivationToken).actor;
  final presentation = state.presentationOf(actor.id);
  if (presentation == null) return null;
  return _TokenPlan(
    key: Key('timeline-actor-${actor.id}-$queueIndex'),
    glyph: presentation.glyphLabel,
    word: presentation.displayName,
    style: monoTokenHostile,
    current: false,
    semanticsLabel: presentation.displayName,
    actor: actor,
  );
}

double _borderWidthOf(_TokenPlan plan) => plan.current ? 3 : 2;

double _planWidth(_TokenPlan plan, TextScaler textScaler) => math.max(
  crawlTouchTarget,
  _measureText(plan.style, textScaler, plan.glyph) +
      5 +
      _measureText(plan.style, textScaler, plan.word) +
      16 +
      _borderWidthOf(plan),
);

double _cuePillWidth(int hidden, TextScaler textScaler) => math.max(
  crawlTouchTarget,
  _measureText(monoToken, textScaler, '+$hidden') + 16 + 2,
);

class TurnOrderStrip extends StatelessWidget {
  const TurnOrderStrip({
    required this.state,
    required this.onActorSelected,
    this.flipped = false,
    super.key,
  });

  final GameViewState state;
  final ValueChanged<Actor> onActorSelected;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final queue = state.activationQueue;
    final now = _planFor(queue[0], 0, state)!;
    final next = <_TokenPlan>[
      for (var index = 1; index < queue.length; index++)
        ?_planFor(queue[index], index, state),
    ];
    final scale = crawlScale(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final nowWidth = _planWidth(now, textScaler);
    final nowLabelWidth = _measureText(displayLabel, textScaler, 'NOW');
    final hasNext = next.isNotEmpty;
    final nextLabelWidth = hasNext
        ? _measureText(displayLabel, textScaler, 'NEXT')
        : 0.0;
    const dividerWidth = 8 + 1 + 8;
    final widths = [for (final plan in next) _planWidth(plan, textScaler)];

    return SizedBox(
      height: crawlStripHeight * scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: crawlCalloutFill,
          border: Border(
            top: flipped
                ? const BorderSide(color: crawlFrame)
                : BorderSide.none,
            bottom: flipped
                ? BorderSide.none
                : const BorderSide(color: crawlFrame),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: crawlStripPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final reserved =
                  nowLabelWidth +
                  6 +
                  nowWidth +
                  (hasNext ? dividerWidth + nextLabelWidth + 6 : 0);
              final available = constraints.maxWidth - reserved;
              final visible = hasNext
                  ? tokensThatFit(
                      widths,
                      available,
                      6,
                      (hidden) => _cuePillWidth(hidden, textScaler),
                    )
                  : 0;
              final hidden = next.length - visible;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('NOW', style: displayLabel),
                  const SizedBox(width: 6),
                  _TimelineToken(
                    plan: now,
                    width: nowWidth,
                    onActorSelected: onActorSelected,
                  ),
                  if (hasNext) ...[
                    const _TimelineDivider(),
                    Text('NEXT', style: displayLabel),
                    const SizedBox(width: 6),
                    for (var index = 0; index < visible; index++) ...[
                      if (index > 0) const SizedBox(width: 6),
                      _TimelineToken(
                        plan: next[index],
                        width: widths[index],
                        onActorSelected: onActorSelected,
                      ),
                    ],
                    if (hidden > 0) ...[
                      const SizedBox(width: 6),
                      _TurnOrderCue(hidden: hidden),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: SizedBox(
      width: 1,
      height: crawlTokenHeight,
      child: ColoredBox(color: crawlDivider),
    ),
  );
}

class _TimelineToken extends StatelessWidget {
  const _TimelineToken({
    required this.plan,
    required this.width,
    required this.onActorSelected,
  });

  final _TokenPlan plan;
  final double width;
  final ValueChanged<Actor> onActorSelected;

  @override
  Widget build(BuildContext context) {
    final pill = _TimelinePill(
      key: plan.key,
      glyph: plan.glyph,
      word: plan.word,
      style: plan.style,
      current: plan.current,
    );
    final height = crawlStripHeight * crawlScale(context);
    final actor = plan.actor;
    if (actor == null) {
      return Semantics(
        label: plan.semanticsLabel,
        excludeSemantics: true,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(child: pill),
        ),
      );
    }
    return Semantics(
      button: true,
      label: plan.semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onActorSelected(actor),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(child: pill),
        ),
      ),
    );
  }
}

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

class _TurnOrderCue extends StatelessWidget {
  const _TurnOrderCue({required this.hidden});

  final int hidden;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$hidden more in the turn order',
    excludeSemantics: true,
    child: SizedBox(
      height: crawlStripHeight * crawlScale(context),
      child: Center(
        child: Container(
          key: turnOrderMoreKey,
          height: crawlTokenHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: crawlChipBorder),
          ),
          child: Text('+$hidden', style: monoToken),
        ),
      ),
    ),
  );
}
