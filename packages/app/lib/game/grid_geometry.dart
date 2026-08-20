import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:residuum_core/core.dart';

class GridGeometry {
  const GridGeometry({
    required this.cellSize,
    required this.origin,
    required this.columns,
    required this.rows,
  });

  factory GridGeometry.fit(Size size, int columns, int rows) {
    final cellSize = math.min(size.width / columns, size.height / rows);
    return GridGeometry(
      cellSize: cellSize,
      origin: Offset(
        (size.width - cellSize * columns) / 2,
        (size.height - cellSize * rows) / 2,
      ),
      columns: columns,
      rows: rows,
    );
  }

  final double cellSize;
  final Offset origin;
  final int columns;
  final int rows;

  Offset topLeftOf(int x, int y) =>
      Offset(origin.dx + x * cellSize, origin.dy + y * cellSize);

  Position? positionAt(Offset local) {
    if (cellSize <= 0) return null;
    final x = ((local.dx - origin.dx) / cellSize).floor();
    final y = ((local.dy - origin.dy) / cellSize).floor();
    if (x < 0 || y < 0 || x >= columns || y >= rows) return null;
    return Position(x, y);
  }
}
