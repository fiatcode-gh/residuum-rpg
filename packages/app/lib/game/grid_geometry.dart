import 'package:flutter/rendering.dart';
import 'package:residuum_core/core.dart';

/// The dense mono cell the crawl renders at, in logical pixels.
///
/// Fixed rather than fitted, because fitting the whole floor on screen made
/// the cells shrink with depth. A fixed cell means the deepest floor is
/// exactly as legible as the first one; what a bigger floor costs is
/// visibility, and visibility is what panning buys back.
const double mapCellWidth = 24;
const double mapCellHeight = 30;

/// Projects the crawl's tile grid onto the screen, and screen points back
/// onto it.
///
/// `GridGeometry` stays the single projection and hit-test authority;
/// rendering layers never install input handlers of their own.
class GridGeometry {
  const GridGeometry({
    required this.cellWidth,
    required this.cellHeight,
    required this.origin,
    required this.columns,
    required this.rows,
  });

  factory GridGeometry.camera(
    Size size,
    int columns,
    int rows,
    Position focus, [
    Offset pan = Offset.zero,
  ]) => GridGeometry(
    cellWidth: mapCellWidth,
    cellHeight: mapCellHeight,
    origin: Offset(
      _axisOrigin(size.width, columns, focus.x, pan.dx, mapCellWidth),
      _axisOrigin(size.height, rows, focus.y, pan.dy, mapCellHeight),
    ),
    columns: columns,
    rows: rows,
  );

  final double cellWidth;
  final double cellHeight;
  final Offset origin;
  final int columns;
  final int rows;

  static double _axisOrigin(
    double viewport,
    int cells,
    int focus,
    double pan,
    double cellExtent,
  ) =>
      _centred(viewport, focus, cellExtent) +
      _clampAxisPan(viewport, cells, focus, pan, cellExtent);

  static double _centred(double viewport, int focus, double cellExtent) =>
      viewport / 2 - (focus + 0.5) * cellExtent;

  static double _clampAxisPan(
    double viewport,
    int cells,
    int focus,
    double pan,
    double cellExtent,
  ) {
    final centred = _centred(viewport, focus, cellExtent);
    return pan.clamp(
      viewport / 2 - cellExtent * cells - centred,
      viewport / 2 - centred,
    );
  }

  /// The pan the camera would actually apply on [columns] × [rows] cells
  /// once bounded so the viewport's own centre stays over the floor:
  /// `_DungeonScene`'s drag tracks this, not the raw finger delta, so a
  /// reverse drag after overshooting a bound moves the camera immediately.
  static Offset clampPan(
    Size size,
    int columns,
    int rows,
    Position focus,
    Offset pan,
  ) => Offset(
    _clampAxisPan(size.width, columns, focus.x, pan.dx, mapCellWidth),
    _clampAxisPan(size.height, rows, focus.y, pan.dy, mapCellHeight),
  );

  Offset topLeftOf(int x, int y) =>
      Offset(origin.dx + x * cellWidth, origin.dy + y * cellHeight);

  /// The centre point of the cell at [position], in the same space as every
  /// touch coordinate this geometry resolves.
  Offset centreOf(Position position) =>
      topLeftOf(position.x, position.y) + Offset(cellWidth / 2, cellHeight / 2);

  /// The full rectangle of the cell at [position].
  Rect rectOf(Position position) =>
      topLeftOf(position.x, position.y) & Size(cellWidth, cellHeight);

  Position? positionAt(Offset local) {
    if (cellWidth <= 0 || cellHeight <= 0) return null;
    final x = ((local.dx - origin.dx) / cellWidth).floor();
    final y = ((local.dy - origin.dy) / cellHeight).floor();
    if (x < 0 || y < 0 || x >= columns || y >= rows) return null;
    return Position(x, y);
  }
}

/// Whether the focus cell is outside the viewport the [geometry] draws.
///
/// The origin is already the clamped camera origin, so this answers the
/// question the recenter affordance needs — has the player's pan dragged the
/// hero off the glass — without touching the camera. The cell's extent
/// counts: a hero partially on screen is on screen.
bool heroOffScreen(Size viewport, GridGeometry geometry, Position focus) {
  final topLeft = geometry.topLeftOf(focus.x, focus.y);
  return topLeft.dx < 0 ||
      topLeft.dy < 0 ||
      topLeft.dx + geometry.cellWidth > viewport.width ||
      topLeft.dy + geometry.cellHeight > viewport.height;
}
