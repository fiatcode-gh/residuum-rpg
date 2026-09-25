import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_slot.dart';
import 'crawl_style.dart';

/// One verb the crawl action bar can offer.
///
/// `onPressed == null` renders the slot inert without hiding it — Pack's
/// always-on exception aside, the bar shows a verb exactly when the guard
/// that governs it says the verb applies, and disables it only for reasons
/// narrower than that, such as being dead.
class CrawlAction {
  const CrawlAction({
    required this.id,
    required this.label,
    required this.onPressed,
    required this.mark,
    this.metadata = '',
    this.armable = false,
    this.armed = false,
  });

  /// Stable identity for this action, independent of its display fields.
  final String id;

  /// What the slot says. Labels may change while [id] remains stable.
  final String label;

  /// Secondary changing information rendered below [label]; replaced by the
  /// armed caption while [armed] is true.
  final String metadata;

  /// What tapping the slot dispatches, or null when the verb is offered but
  /// cannot be taken right now.
  final VoidCallback? onPressed;

  /// The verb's mark (PLAN.md G9): a shipped icon or a Material glyph.
  final ActionMark mark;

  /// Whether this verb can be armed — a target spell, never a plain action.
  final bool armable;

  /// Whether this specific slot is the one currently armed.
  final bool armed;
}

/// How many slots the bar shows before it scrolls (PLAN.md G8).
const int _barSlots = 5;

/// The crawl's one action bar (PLAN.md G8): a fixed five-slot row that never
/// grows with the number of verbs on offer. Five slots or fewer render at
/// equal width with the remainder standing as empty frames; more than five
/// scroll, so the bar's own height — and the map above it — never depends on
/// how many verbs the current scene offers.
class CrawlActionBar extends StatelessWidget {
  const CrawlActionBar({required this.actions, super.key});

  /// Every verb the current scene offers, in the crawl's frozen order.
  final List<CrawlAction> actions;

  @override
  Widget build(BuildContext context) {
    assert(
      actions.map((action) => action.id).toSet().length == actions.length,
      'an action id must appear once',
    );
    final barHeight = crawlActionBarHeight * crawlScale(context);
    return SizedBox(
      height: barHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final overflow = actions.length > _barSlots;
            final width = overflow
                ? (constraints.maxWidth -
                          crawlSlotGap * _barSlots -
                          crawlSlotPeek) /
                      _barSlots
                : (constraints.maxWidth - crawlSlotGap * (_barSlots - 1)) /
                      _barSlots;
            final slots = <Widget>[
              for (final action in actions)
                CrawlSlot(
                  key: ValueKey(action.id),
                  label: action.label,
                  mark: action.mark,
                  onPressed: action.onPressed,
                  armed: action.armed,
                  metadata: action.metadata,
                  width: width,
                  height: barHeight,
                ),
              if (!overflow)
                for (var index = actions.length; index < _barSlots; index++)
                  _InertFrame(width: width, height: barHeight),
            ];
            final row = Row(
              children: [
                for (var index = 0; index < slots.length; index++) ...[
                  if (index > 0) const SizedBox(width: crawlSlotGap),
                  slots[index],
                ],
              ],
            );
            return overflow
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: row,
                  )
                : row;
          },
        ),
      ),
    );
  }
}

/// The action bar's only test handle — slots are keyed by their own stable
/// id, which [CrawlActionBar]'s assert guarantees is unique.
const actionRowKey = Key('crawl-action-row');

/// How many known spells sit readied on the bar before the overflow.
const int readiedSpellCount = 3;

/// One empty frame standing in for a verb the current scene does not offer:
/// a dim hairline outline, no fill, no ink, no semantics.
class _InertFrame extends StatelessWidget {
  const _InertFrame({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: crawlFrame.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
  );
}
