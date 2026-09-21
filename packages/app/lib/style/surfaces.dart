import 'package:flutter/material.dart';

import 'tokens.dart';

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
