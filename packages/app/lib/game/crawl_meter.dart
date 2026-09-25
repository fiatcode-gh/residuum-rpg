import 'package:flutter/material.dart';

import '../style/tokens.dart';

class CrawlMeter extends StatelessWidget {
  const CrawlMeter({
    required this.label,
    required this.value,
    required this.ceiling,
    required this.fill,
    this.barHeight = 6,
    super.key,
  });

  final String label;
  final int value;
  final int ceiling;
  final Color fill;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final fraction = ceiling == 0
        ? 0.0
        : (value / ceiling).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label $value/$ceiling', style: monoData),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: barHeight,
            backgroundColor: crawlMeterTrack,
            valueColor: AlwaysStoppedAnimation(fill),
          ),
        ),
      ],
    );
  }
}
