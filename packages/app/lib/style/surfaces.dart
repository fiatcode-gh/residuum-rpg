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
    final fillColour = switch (tint) {
      MeterTint.health => meterHealthFill,
      MeterTint.mana => meterManaFill,
    };
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
              valueColor: AlwaysStoppedAnimation(fillColour),
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
