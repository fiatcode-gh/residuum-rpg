import 'package:flutter/material.dart';

import 'tokens.dart';

/// A shared framed row with a stable leading medallion envelope.
///
/// The envelope remains measurable when [medallion] is null, so consumers can
/// align empty and marked rows without introducing placeholder content.
class FramedRow extends StatelessWidget {
  const FramedRow({
    required this.title,
    this.details = const [],
    this.medallion,
    this.medallionKey,
    this.trailing,
    this.onPressed,
    this.titleStyle = textBody,
    this.detailStyle = textLineDim,
    super.key,
  });

  final String title;
  final List<String> details;
  final Widget? medallion;
  final Key? medallionKey;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final TextStyle titleStyle;
  final TextStyle detailStyle;

  @override
  Widget build(BuildContext context) {
    final surface = Material(
      color: panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: rule, width: hairline),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                key: medallionKey,
                width: tapTarget,
                height: tapTarget,
                child: Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: rule, width: hairline),
                        ),
                      ),
                      child: medallion == null
                          ? null
                          : ClipOval(child: Center(child: medallion)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: titleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    for (final detail in details)
                      Text(detail, style: detailStyle),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Center(child: trailing),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: rhythm),
      child: Semantics(
        container: true,
        button: onPressed != null ? true : null,
        enabled: onPressed != null ? true : null,
        onTap: onPressed,
        child: surface,
      ),
    );
  }
}

/// Which of the two resource fills a [ResourceMeter] renders.
enum MeterTint { health, mana }

/// One resource meter: a label, a monochrome-safe track, a hue fill and the
/// number.
///
/// The hue is reinforcement only, never the carrier: the label word, the
/// value, the ceiling and the fill fraction each say what the meter reads on
/// their own, so a greyscale render loses nothing, and [meterHealthFill] and
/// [meterManaFill] are chosen to be indistinguishable from each other in
/// greyscale, so neither meter reads as fuller than the other at an equal
/// fraction.
class ResourceMeter extends StatelessWidget {
  const ResourceMeter({
    required this.label,
    required this.value,
    required this.ceiling,
    required this.tint,
    this.note = '',
    super.key,
  });

  final String label;
  final int value;
  final int ceiling;
  final MeterTint tint;
  final String note;

  @override
  Widget build(BuildContext context) {
    final fill = ceiling == 0 ? 0.0 : (value / ceiling).clamp(0, 1).toDouble();
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('$label $value / $ceiling', style: textBody),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 8,
              backgroundColor: rule,
              valueColor: switch (tint) {
                MeterTint.health => const AlwaysStoppedAnimation(
                  meterHealthFill,
                ),
                MeterTint.mana => const AlwaysStoppedAnimation(meterManaFill),
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(note, style: textBody),
          ),
        ),
      ],
    );
  }
}

/// One fact, its label at a fixed width and its value beside it.
///
/// The label cell exists because a padded string only ever aligned in a
/// fixed-width face, and the face this application draws in no longer is —
/// `town_style.dart`'s own dartdoc on `markColumn` records the same lesson
/// for its leading glyph cell. [labelColumn] is the equivalent slot for a
/// leading word, so a whole column of values holds still without spaces
/// doing the aligning. `textBody` already carries tabular figures, so the
/// value's digits cannot jitter either.
class LabelledValue extends StatelessWidget {
  const LabelledValue({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: labelColumn,
        child: Text(label, style: textLineDim),
      ),
      Expanded(child: Text(value, style: textBody)),
    ],
  );
}
