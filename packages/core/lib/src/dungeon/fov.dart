import '../engine/position.dart';
import 'floor_map.dart';

/// How far the hero sees on a dungeon floor, in tiles.
const int fovRadius = 8;

/// The positions visible from [origin] within [radius].
///
/// Recursive shadowcasting across the eight octants, testing
/// [FloorMap.isTransparent]. Distance is **Euclidean**, compared as squared
/// distance so no square roots are taken: the lit pool is a circle. Chebyshev
/// distance was rejected because a square pool of light reads as a rendering
/// bug on a glyph grid, and Manhattan distance because a diamond pool hides
/// the corners of the very room the hero is standing in.
///
/// The [origin] is always visible. A wall is lit at the moment the scan
/// reaches it, before it starts casting its shadow, so the walls bordering a
/// lit floor are lit and rooms render with edges.
Set<Position> computeFov(FloorMap map, Position origin, int radius) {
  final visible = <Position>{origin};
  for (final octant in _octants) {
    _ShadowSweep(
      map: map,
      origin: origin,
      radius: radius,
      octant: octant,
      visible: visible,
    ).cast(1, 1, 0);
  }
  return visible;
}

class _Octant {
  const _Octant(this.xx, this.xy, this.yx, this.yy);

  final int xx;
  final int xy;
  final int yx;
  final int yy;

  Position project(Position origin, int deltaX, int deltaY) {
    return Position(
      origin.x + deltaX * xx + deltaY * xy,
      origin.y + deltaX * yx + deltaY * yy,
    );
  }
}

const _octants = <_Octant>[
  _Octant(1, 0, 0, 1),
  _Octant(0, 1, 1, 0),
  _Octant(0, -1, 1, 0),
  _Octant(-1, 0, 0, 1),
  _Octant(-1, 0, 0, -1),
  _Octant(0, -1, -1, 0),
  _Octant(0, 1, -1, 0),
  _Octant(1, 0, 0, -1),
];

class _Sector {
  _Sector({required this.start, required this.end})
    : newStart = start,
      blocked = false;

  double start;
  final double end;
  double newStart;
  bool blocked;
}

class _ShadowSweep {
  _ShadowSweep({
    required this.map,
    required this.origin,
    required this.radius,
    required this.octant,
    required this.visible,
  });

  final FloorMap map;
  final Position origin;
  final int radius;
  final _Octant octant;
  final Set<Position> visible;

  void cast(int firstRow, double start, double end) {
    if (start < end) return;
    final sector = _Sector(start: start, end: end);
    for (
      var distance = firstRow;
      distance <= radius && !sector.blocked;
      distance++
    ) {
      _scanRow(distance, sector);
    }
  }

  void _scanRow(int distance, _Sector sector) {
    final deltaY = -distance;
    for (var deltaX = -distance; deltaX <= 0; deltaX++) {
      final current = octant.project(origin, deltaX, deltaY);
      final leadingSlope = _leadingSlope(deltaX, deltaY);
      final trailingSlope = _trailingSlope(deltaX, deltaY);
      if (!map.inBounds(current) || sector.start < trailingSlope) continue;
      if (sector.end > leadingSlope) break;

      if (_withinRadius(deltaX, deltaY, radius)) {
        visible.add(current);
      }
      if (sector.blocked) {
        if (!map.isTransparent(current)) {
          sector.newStart = trailingSlope;
          continue;
        }
        sector.blocked = false;
        sector.start = sector.newStart;
      } else if (!map.isTransparent(current) && distance < radius) {
        sector.blocked = true;
        cast(distance + 1, sector.start, leadingSlope);
        sector.newStart = trailingSlope;
      }
    }
  }
}

double _leadingSlope(int deltaX, int deltaY) => (deltaX - 0.5) / (deltaY + 0.5);

double _trailingSlope(int deltaX, int deltaY) =>
    (deltaX + 0.5) / (deltaY - 0.5);

bool _withinRadius(int deltaX, int deltaY, int radius) =>
    deltaX * deltaX + deltaY * deltaY <= radius * radius;
