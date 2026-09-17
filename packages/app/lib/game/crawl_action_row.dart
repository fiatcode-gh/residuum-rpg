import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art/art_assets.dart';
import 'action_icon.dart';
import 'crawl_style.dart';

/// One verb the crawl action row can offer.
///
/// `onPressed == null` renders the chip inert without hiding it — Pack's
/// always-on exception aside, the row shows a verb exactly when the guard
/// that governs it says the verb applies, and disables it only for reasons
/// narrower than that, such as being dead.
class CrawlAction {
  const CrawlAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.armable = false,
    this.armed = false,
  });

  /// What the chip says. Every action in one row must carry a distinct
  /// label — [CrawlActionRow] asserts it.
  final String label;

  /// What tapping the chip dispatches, or null when the verb is offered but
  /// cannot be taken right now.
  final VoidCallback? onPressed;

  /// The chip's icon slot, or null for a word-only verb.
  final ActionIcon? icon;

  /// Whether this verb can be armed — a target spell, never a plain action.
  final bool armable;

  /// Whether this specific chip is the one currently armed.
  final bool armed;
}

/// The crawl's one action row: every verb that applies, each visible exactly
/// once, laid out as even-width chips that read available, disabled and
/// armed without a hue.
///
/// One column count serves the whole row — chosen once, from the longest
/// label at every candidate width — so no chip is ever narrower than its
/// neighbour and no chip alone decides how many share the line.
class CrawlActionRow extends StatelessWidget {
  const CrawlActionRow({required this.notes, required this.actions, super.key});

  /// The crawl's conditional sentences — bottom-floor notice, what is
  /// underfoot — rendered above the chips, in the order they are given.
  final List<String> notes;

  /// Every verb the current scene offers, in the crawl's frozen order.
  final List<CrawlAction> actions;

  @override
  Widget build(BuildContext context) {
    assert(
      actions.map((action) => action.label).toSet().length == actions.length,
      'a verb must appear once',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: crawlGutter,
        vertical: crawlRhythm,
      ),
      child: Column(
        children: [
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: crawlRhythm),
              child: Text(note, style: crawlBodyDim),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final fit = _fitFor(
                constraints.maxWidth,
                actions,
                MediaQuery.textScalerOf(context),
              );
              return Wrap(
                spacing: crawlChipSpacing,
                runSpacing: crawlChipRunSpacing,
                alignment: WrapAlignment.center,
                children: [
                  for (final action in actions)
                    _ActionChip(
                      key: ValueKey(action.label),
                      action: action,
                      width: fit.width,
                      height: fit.chipHeight,
                      captionHeight: fit.captionHeight,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The action row's only test handle — chips are keyed by their own label,
/// which [CrawlActionRow]'s assert guarantees is unique.
const actionRowKey = Key('crawl-action-row');

/// How many known spells sit readied on the row before the overflow.
const int readiedSpellCount = 3;

/// The reserved caption an armed chip renders below its word, and every
/// other chip in an armable row reserves the height of. Shared by the
/// measuring pass and the render so the two can never drift.
const String _armedCaption = '— armed';

/// One candidate layout: the width every chip in the row takes, the height
/// every chip must stand — measured, never guessed — and the reserve the
/// armed word needs.
class _RowFit {
  const _RowFit({
    required this.width,
    required this.chipHeight,
    required this.captionHeight,
  });

  final double width;
  final double chipHeight;

  /// 0 when no action in the row is armable.
  final double captionHeight;
}

/// Measures every label once — in the heaviest style it can ever render,
/// with the ambient text scale — then minimises: the survivor is the
/// candidate column count whose measured total row height is least, among
/// every count that keeps every label within [crawlChipMaxLabelLines] and
/// never breaks a word or wraps the armed caption.
///
/// Wrap count is not monotonic in a chip's width — a wider chip can need
/// *more* lines than a narrower one — so the first legal candidate is not
/// the shortest row; every candidate has to be measured. Each label is
/// measured in the style its own state can ever reach rather than the style
/// it renders right now, because the latter would make the row's height a
/// function of which chip happens to be armed and reflow the map under the
/// player's thumb — the defect the reserved caption line exists to prevent.
_RowFit _fitFor(
  double available,
  List<CrawlAction> actions,
  TextScaler textScaler,
) {
  final labelPainters = [
    for (final action in actions)
      TextPainter(
        text: TextSpan(
          text: action.label,
          style: action.armable ? crawlChipLabelArmed : crawlChipLabel,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(),
  ];
  final anyArmable = actions.any((action) => action.armable);
  final captionPainter = anyArmable
      ? (TextPainter(
          text: const TextSpan(text: _armedCaption, style: crawlCaption),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout())
      : null;
  try {
    // Only trustworthy from this unbounded pass: after a bounded break-all
    // layout, `minIntrinsicWidth` reports the widest rendered fragment, not
    // the widest whole word.
    final widestWord = [
      for (final painter in labelPainters) painter.minIntrinsicWidth,
      if (captionPainter != null) captionPainter.width,
    ].reduce(math.max);
    final captionHeight = captionPainter?.height ?? 0.0;

    _RowFit? best;
    var bestTotal = double.infinity;
    for (var columns = crawlChipMaxColumns; columns >= 1; columns--) {
      final width = (available - crawlChipSpacing * (columns - 1)) / columns;
      final content = width - crawlChipPadding * 2;
      if (content <= 0) continue;
      // A candidate that would break a word or wrap the caption is not a
      // candidate.
      if (content + 0.5 < widestWord) continue;
      var labelBlock = 0.0;
      var everyLabelFits = true;
      for (final painter in labelPainters) {
        painter.layout(maxWidth: content);
        if (painter.computeLineMetrics().length > crawlChipMaxLabelLines) {
          everyLabelFits = false;
          break;
        }
        labelBlock = math.max(labelBlock, painter.height);
      }
      if (!everyLabelFits) continue;
      final chipHeight =
          crawlChipVerticalPadding * 2 +
          actionIconSize +
          crawlRhythm +
          labelBlock +
          captionHeight;
      final runs = (actions.length / columns).ceil();
      final total = runs * chipHeight + (runs - 1) * crawlChipRunSpacing;
      // Iterating columns descending plus a strict improvement means a tie
      // keeps the larger column count.
      if (total < bestTotal) {
        bestTotal = total;
        best = _RowFit(
          width: width,
          chipHeight: chipHeight,
          captionHeight: captionHeight,
        );
      }
    }
    if (best != null) return best;

    // Degenerate case: no candidate passed the word guard. One column at the
    // full available width rather than clip; a label that still cannot fit
    // here is an escalation, not a layout bug.
    final content = available - crawlChipPadding * 2;
    var labelBlock = 0.0;
    for (final painter in labelPainters) {
      if (content > 0) painter.layout(maxWidth: content);
      labelBlock = math.max(labelBlock, painter.height);
    }
    final chipHeight =
        crawlChipVerticalPadding * 2 +
        actionIconSize +
        crawlRhythm +
        labelBlock +
        captionHeight;
    return _RowFit(
      width: available,
      chipHeight: chipHeight,
      captionHeight: captionHeight,
    );
  } finally {
    for (final painter in labelPainters) {
      painter.dispose();
    }
    captionPainter?.dispose();
  }
}

/// One chip: icon above word, even width and height, bordered and filled by
/// [crawlChipSkin] so available, disabled and armed read without a hue.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.action,
    required this.width,
    required this.height,
    required this.captionHeight,
    super.key,
  });

  final CrawlAction action;
  final double width;
  final double height;

  /// 0 when no action in the row is armable.
  final double captionHeight;

  CrawlChipState get _state => action.armed
      ? CrawlChipState.armed
      : action.onPressed == null
      ? CrawlChipState.disabled
      : CrawlChipState.available;

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final skin = crawlChipSkin(state);
    final iconSlot = action.icon == null
        ? const SizedBox(height: actionIconSize)
        : ActionIconImage(action.icon!);
    final icon = state == CrawlChipState.disabled
        ? Opacity(opacity: skin.iconOpacity, child: iconSlot)
        : iconSlot;
    return Semantics(
      button: true,
      enabled: action.onPressed != null,
      label: action.label,
      onTap: action.onPressed,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: skin.fill,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: skin.border, width: skin.borderWidth),
              borderRadius: BorderRadius.circular(crawlRadius),
            ),
            child: InkWell(
              onTap: action.onPressed,
              borderRadius: BorderRadius.circular(crawlRadius),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(height: crawlRhythm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: crawlChipPadding,
                    ),
                    child: Text(
                      action.label,
                      textAlign: TextAlign.center,
                      maxLines: crawlChipMaxLabelLines,
                      style: skin.label,
                    ),
                  ),
                  if (captionHeight > 0)
                    action.armed
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: crawlChipPadding,
                            ),
                            child: Text(_armedCaption, style: crawlCaption),
                          )
                        : SizedBox(height: captionHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
