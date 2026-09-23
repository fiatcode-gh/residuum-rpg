import 'package:flutter/rendering.dart';
import 'package:residuum_core/core.dart';

/// The dense mono cell the crawl renders at, in logical pixels.
///
/// Fixed rather than fitted, because fitting the whole floor on screen made
/// the cells shrink with depth. A fixed cell means the deepest floor is
/// exactly as legible as the first one; what a bigger floor costs is
/// visibility, and visibility is what panning buys back.
const double mapCellWidth = 16;
const double mapCellHeight = 20;

/// Projects the crawl's tile grid onto the screen, and screen points back
/// onto it.
///
/// The map cell is dense — about 16 by 20 dp, mock density rather than a
/// touch target — so accurate aiming comes from resolving what the player
/// meant (`map_touch.dart`), not from the cell being large enough to tap
/// directly. `GridGeometry` stays the single projection and hit-test
/// authority; rendering layers never install input handlers of their own.
class GridGeometry {
  const GridGeometry({
    required this.cellWidth,
    required this.cellHeight,
    required this.origin,
    required this.columns,
    required this.rows,
  });

  /// The grid framed by a camera: the dense cell throughout, [focus]
  /// centred, shifted by [pan], then held inside the map's own edges. Each
  /// axis decides for itself, because a floor is wider than it is tall and a
  /// phone is the other way round, so one axis routinely fits while the
  /// other does not. An axis that fits ignores [pan] entirely and centres on
  /// its own extent instead — it has nothing hidden to reveal. An extent
  /// exactly equal to the viewport counts as fitting.
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
  ) {
    final extent = cellExtent * cells;
    if (extent <= viewport) return (viewport - extent) / 2;
    final centred = viewport / 2 - (focus + 0.5) * cellExtent;
    return (centred + pan).clamp(viewport - extent, 0.0);
  }

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
