import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A deterministic, map-independent atmosphere confined to the map viewport.
class DungeonDepthPainter extends CustomPainter {
  const DungeonDepthPainter();

  static const _base = Color(0xFF101318);
  static const _cool = Color(0xFF263747);
  static const _warm = Color(0xFF49352B);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = _base);

    final coolCenter = Offset(size.width * 0.27, size.height * 0.32);
    final coolRadius = size.longestSide * 0.9;
    final coolShader = ui.Gradient.radial(
      coolCenter,
      coolRadius,
      [_cool.withValues(alpha: 0.42), _cool.withValues(alpha: 0)],
      const [0, 1],
    );
    canvas.drawRect(bounds, Paint()..shader = coolShader);

    final warmCenter = Offset(size.width * 0.78, size.height * 0.76);
    final warmRadius = size.longestSide * 0.78;
    final warmShader = ui.Gradient.radial(
      warmCenter,
      warmRadius,
      [_warm.withValues(alpha: 0.24), _warm.withValues(alpha: 0)],
      const [0, 1],
    );
    canvas.drawRect(bounds, Paint()..shader = warmShader);
  }

  @override
  bool shouldRepaint(covariant DungeonDepthPainter oldDelegate) => false;
}
