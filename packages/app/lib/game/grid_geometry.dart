import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:residuum_core/core.dart';

/// The cell size the camera always draws at, in logical pixels.
///
/// Fixed rather than fitted, because fitting the whole floor on screen made the
/// cells shrink with depth. Floors grow as the crawl deepens, so a depth-five
/// floor is 32 by 20 tiles and the deepest a delve can roll — the keep's
/// seventh — is 36 by 22, which on a phone left roughly 12dp cells against a
/// 48dp touch guideline once it was fitted, and a tap that has to be aimed is
/// not a tap. A fixed cell means the deepest floor is exactly as playable as the
/// first one. What a bigger floor costs is visibility rather than accuracy, and
/// visibility is what panning buys back.
const double cameraCellSize = 36;

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

  /// The grid framed by a camera: [cameraCellSize] throughout, [focus] centred,
  /// shifted by [pan], then held inside the map's own edges.
  ///
  /// Each axis decides for itself, because a floor is wider than it is tall and a
  /// phone is the other way round, so one axis routinely fits while the other
  /// does not. **An axis that fits ignores [pan] entirely**: it has nothing
  /// hidden to reveal, so panning it could only uncover void, and a view that
  /// can be dragged off its own content teaches the player that the controls are
  /// broken.
  ///
  /// An extent exactly equal to the viewport counts as fitting. Nothing is
  /// hidden at equality either.
  ///
  /// The cell size never shrinks to make a map fit, which is the whole
  /// difference from [GridGeometry.fit] and the reason this factory exists.
  factory GridGeometry.camera(
    Size size,
    int columns,
    int rows,
    Position focus, [
    Offset pan = Offset.zero,
  ]) => GridGeometry(
    cellSize: cameraCellSize,
    origin: Offset(
      _axisOrigin(size.width, columns, focus.x, pan.dx),
      _axisOrigin(size.height, rows, focus.y, pan.dy),
    ),
    columns: columns,
    rows: rows,
  );

  final double cellSize;
  final Offset origin;
  final int columns;
  final int rows;

  static double _axisOrigin(double viewport, int cells, int focus, double pan) {
    final extent = cameraCellSize * cells;
    if (extent <= viewport) return (viewport - extent) / 2;
    final centred = viewport / 2 - (focus + 0.5) * cameraCellSize;
    return (centred + pan).clamp(viewport - extent, 0.0);
  }

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
