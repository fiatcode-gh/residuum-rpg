import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_style.dart';

class CrawlSlot extends StatelessWidget {
  const CrawlSlot({
    required this.label,
    required this.mark,
    required this.onPressed,
    this.dimmed = false,
    this.armed = false,
    required this.width,
    required this.height,
    super.key,
  });

  final String label;

  final ActionMark mark;

  final VoidCallback? onPressed;

  final bool dimmed;

  final bool armed;

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
    final frameWidth = state == CrawlSlotState.armed ? 3.0 : hairline;
    final labelStyle = switch (state) {
      CrawlSlotState.available => textSlot,
      CrawlSlotState.disabled => textSlotDisabled,
      CrawlSlotState.armed => textSlotArmed,
    };
    var semanticsLabel = label;
    if (dimmed) semanticsLabel = '$semanticsLabel, unavailable';
    if (armed) semanticsLabel = '$semanticsLabel, armed';
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
