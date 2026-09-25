import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_style.dart';

/// One framed control: mark above word, bordered and filled by its
/// [CrawlSlotState] so available, disabled and armed read without a hue
/// (PLAN.md G8, extracted from the action bar's own `_ActionSlot`).
///
/// The action bar and the log row's Wait and Flee controls both draw from
/// this one widget, so a change to what "available", "disabled" or "armed"
/// looks like never has to be made twice.
class CrawlSlot extends StatelessWidget {
  const CrawlSlot({
    required this.label,
    required this.mark,
    required this.onPressed,
    this.dimmed = false,
    this.armed = false,
    this.metadata = '',
    required this.width,
    required this.height,
    super.key,
  });

  /// What the slot says.
  final String label;

  /// The verb's mark (PLAN.md G9): a shipped icon or a Material glyph.
  final ActionMark mark;

  /// What tapping the slot dispatches, or null when the verb is offered but
  /// cannot be taken right now.
  final VoidCallback? onPressed;

  /// Whether the slot has nothing to offer right now — dimmed rather than
  /// removed, so tapping it can still say why.
  final bool dimmed;

  /// Whether this specific slot is the one currently armed.
  final bool armed;

  /// Secondary changing information rendered below [label]; replaced by the
  /// armed caption while [armed] is true.
  final String metadata;

  final double width;
  final double height;

  CrawlSlotState get _state => armed
      ? CrawlSlotState.armed
      : (dimmed || onPressed == null)
      ? CrawlSlotState.disabled
      : CrawlSlotState.available;

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final fill = state == CrawlSlotState.disabled
        ? crawlPanelFill
        : crawlSlotFill;
    final frameColor = switch (state) {
      CrawlSlotState.available => crawlFrame,
      CrawlSlotState.disabled => crawlDivider,
      CrawlSlotState.armed => crawlCold,
    };
    final frameWidth = state == CrawlSlotState.armed ? 1.5 : hairline;
    final labelStyle = switch (state) {
      CrawlSlotState.available => textSlot,
      CrawlSlotState.disabled => textSlotDisabled,
      CrawlSlotState.armed => textSlotArmed,
    };
    final metadataText = armed ? '— armed' : metadata;
    final baseLabel = metadata.isEmpty ? label : '$label $metadata';
    final semanticsLabel = dimmed ? '$baseLabel, unavailable' : baseLabel;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: fill,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: frameColor, width: frameWidth),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Container(
              decoration: state != CrawlSlotState.armed
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: crawlCold.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(radius),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: state == CrawlSlotState.disabled
                            ? crawlDisabledIconOpacity
                            : 1,
                        child: SizedBox(
                          height: crawlSlotMark,
                          child: ActionMarkView(mark, size: crawlSlotMark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label, maxLines: 1, style: labelStyle),
                        ),
                      ),
                      if (metadataText.isNotEmpty)
                        Text(metadataText, style: monoSlotMeta),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
