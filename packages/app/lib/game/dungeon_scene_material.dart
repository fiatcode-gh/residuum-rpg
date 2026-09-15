import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'dungeon_material.dart';
import 'dungeon_palette.dart';
import 'glyph_plan.dart';
import 'grid_geometry.dart';

const Color dungeonVoid = Color(0xFF050607);

enum SurfacePattern { none, tideStrata, ashlarFracture, roadWear }

Color stoneLitColor(DungeonPalette palette, double light) {
  final warmed = Color.lerp(
    palette.visibleStone,
    palette.lightInk,
    palette.maxTintMix * light,
  )!;
  final hsl = HSLColor.fromColor(warmed);
  return hsl
      .withLightness(
        (hsl.lightness + palette.maxLightLift * light).clamp(0.0, 1.0),
      )
      .toColor();
}

/// One tile's material paint, decided — not drawn.
///
/// The pure decision layer between the plan and the canvas: the same
/// [MaterialCell] with the same masonry membership always yields the same
/// fill and edge response, so tests can pin the picture's decisions without
/// screenshots and the renderer cannot improvise.
class MaterialCellPaint {
  const MaterialCellPaint({
    required this.fill,
    required this.edge,
    required this.gritStrength,
    required this.speck,
    required this.crackStrength,
    required this.pattern,
    required this.patternStrength,
  });

  /// The stone surface color for the cell.
  final Color fill;

  /// 0..1 structural edge response; 0 means no edge work.
  final double edge;

  /// 0..1 strength of the fine surface grit pass.
  final double gritStrength;

  /// Whether the single small chip/pebble mark is drawn.
  final bool speck;

  /// 0..1 hairline-crack strength; 0 means no crack.
  final double crackStrength;

  final SurfacePattern pattern;

  final double patternStrength;

  @override
  bool operator ==(Object other) =>
      other is MaterialCellPaint &&
      other.fill == fill &&
      other.edge == edge &&
      other.gritStrength == gritStrength &&
      other.speck == speck &&
      other.crackStrength == crackStrength &&
      other.pattern == pattern &&
      other.patternStrength == patternStrength;

  @override
  int get hashCode => Object.hash(
    fill,
    edge,
    gritStrength,
    speck,
    crackStrength,
    pattern,
    patternStrength,
  );
}

/// Walls carry a stronger surface response than floors.
const double _wallGritFactor = 1.75;
const double _wallEdgeStrokeWidth = 1.2;
const double _wallEdgeInset = 0.7;

/// Builds the authoritative clip for the local-light pass.
///
/// It contains current visibility only: remembered terrain stays unlit, and
/// unknown positions have no material cell to add. The renderer may smooth
/// light inside this path, but it must never infer geometry beyond it.
Path visibleMaterialMask(MaterialPlan plan) {
  final mask = Path();
  for (final cell in plan.cells) {
    if (cell.knowledge != MaterialKnowledge.visible) continue;
    mask.addRect(
      Rect.fromLTWH(
        cell.position.x * cameraCellSize,
        cell.position.y * cameraCellSize,
        cameraCellSize,
        cameraCellSize,
      ),
    );
  }
  return mask;
}

/// Decides one known tile's material paint.
///
/// Remembered geometry paints flat, dark, and unlit — one value for the whole
/// remembered region. Visible geometry shares one regional stone foundation;
/// the canvas applies its local gradient in a single clipped pass.
MaterialCellPaint materialCellPaint(
  MaterialCell cell, {
  required DungeonPalette palette,
  required bool masonry,
}) {
  if (cell.knowledge == MaterialKnowledge.remembered) {
    return MaterialCellPaint(
      fill: palette.rememberedStone,
      edge: masonry ? 0.06 : 0.12,
      gritStrength: cell.kind == MaterialTileKind.wall
          ? 0.05
          : 0.05 / _wallGritFactor,
      speck: false,
      crackStrength: 0.0,
      pattern: SurfacePattern.none,
      patternStrength: 0.0,
    );
  }

  final wall = cell.kind == MaterialTileKind.wall;
  final stairs =
      cell.kind == MaterialTileKind.stairsDown ||
      cell.kind == MaterialTileKind.stairsUp;
  final (
    edge,
    grit,
    pattern,
    patternStrength,
    crackStrength,
    speck,
  ) = switch (palette.material) {
    RegionMaterial.cryptStone => (
      wall ? 0.55 : 0.0,
      wall ? 0.08 * _wallGritFactor : 0.08,
      SurfacePattern.none,
      0.0,
      wall && !masonry ? 0.5 : 0.0,
      !wall && !stairs,
    ),
    RegionMaterial.seaCaveStone => (
      wall ? 0.42 : 0.0,
      wall ? 0.10 : 0.055,
      stairs ? SurfacePattern.none : SurfacePattern.tideStrata,
      stairs
          ? 0.0
          : wall
          ? 0.36
          : 0.20,
      0.0,
      !wall && !stairs,
    ),
    RegionMaterial.ruinedKeepMasonry => (
      wall ? 0.68 : 0.0,
      wall ? 0.15 : 0.07,
      stairs ? SurfacePattern.none : SurfacePattern.ashlarFracture,
      stairs
          ? 0.0
          : wall
          ? 0.45
          : 0.28,
      wall && !masonry ? 0.70 : 0.0,
      !wall && !stairs,
    ),
    RegionMaterial.lowlandRoad => (
      wall ? 0.32 : 0.0,
      wall ? 0.07 : 0.045,
      wall || stairs ? SurfacePattern.none : SurfacePattern.roadWear,
      wall || stairs ? 0.0 : 0.24,
      0.0,
      false,
    ),
  };
  return MaterialCellPaint(
    fill: palette.visibleStone,
    edge: stairs ? 0.0 : edge,
    gritStrength: grit,
    speck: stairs ? false : speck,
    crackStrength: stairs ? 0.0 : crackStrength,
    pattern: stairs ? SurfacePattern.none : pattern,
    patternStrength: stairs ? 0.0 : patternStrength,
  );
}

/// Draws the continuous stone material for one crawl.
///
/// One canvas component for the whole layer rather than a component per
/// speck: decoration is cheap canvas work over deterministic [MaterialMark]
/// decisions, and unknown space is simply never painted — the component only
/// ever iterates the plan's known cells.
class MaterialComponent extends PositionComponent {
  MaterialComponent(MaterialPlan initialPlan)
    : plan = initialPlan,
      super(
        position: Vector2.zero(),
        size: Vector2.all(1),
        priority: GlyphLayer.terrain.index,
      ) {
    _rebuildRenderPlan();
  }

  /// The material plan currently painted.
  ///
  /// Replaced in place when the scene synchronizes a new projection, so the
  /// layer keeps its position in the component tree across pans and focus
  /// changes exactly as the glyph components do.
  MaterialPlan plan;

  late Path _visibleMask;
  late Rect _visibleLightBounds;
  late Paint _visibleLight;
  late List<_PreparedMaterialCell> _cells;

  /// Adopts a new plan, replacing the painted one.
  ///
  /// A pan-only viewport change hands back the identical plan and this is a
  /// no-op by identity; a real projection change repaints from the new plan.
  void adopt(MaterialPlan next) {
    if (identical(plan, next)) return;
    plan = next;
    _rebuildRenderPlan();
  }

  void _rebuildRenderPlan() {
    final knownWalls = {
      for (final cell in plan.cells)
        if (cell.kind == MaterialTileKind.wall) cell.position,
    };
    _cells = [
      for (final cell in plan.cells)
        _PreparedMaterialCell.from(
          mark: plan.markAt(cell.position)!,
          paint: materialCellPaint(
            cell,
            palette: plan.palette,
            masonry: plan.masonryAt(cell.position),
          ),
          palette: plan.palette,
          kind: cell.kind,
          patternPhase: plan.markAt(cell.position)!.pattern,
          rect: _cellRect(cell),
          faces: _wallFaces(cell, knownWalls),
        ),
    ];
    _visibleMask = visibleMaterialMask(plan);
    _visibleLightBounds = _visibleMask.getBounds();
    final heroCenter = Offset(
      (plan.heroPosition.x + 0.5) * cameraCellSize,
      (plan.heroPosition.y + 0.5) * cameraCellSize,
    );
    final radius = (fovRadius + 1) * cameraCellSize;
    _visibleLight = Paint()
      ..shader = RadialGradient(
        colors: [
          stoneLitColor(plan.palette, 1),
          stoneLitColor(plan.palette, 0),
        ],
      ).createShader(Rect.fromCircle(center: heroCenter, radius: radius));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final cell in _cells) {
      _drawCellBase(canvas, cell);
    }
    _drawVisibleLight(canvas);
    for (final cell in _cells) {
      _drawCellDecoration(canvas, cell);
    }
  }

  void _drawCellBase(Canvas canvas, _PreparedMaterialCell cell) {
    canvas.drawRect(cell.rect, cell.basePaint);
  }

  void _drawVisibleLight(Canvas canvas) {
    if (_visibleLightBounds.isEmpty) return;
    canvas
      ..save()
      ..clipPath(_visibleMask)
      ..drawRect(_visibleLightBounds, _visibleLight)
      ..restore();
  }

  void _drawCellDecoration(Canvas canvas, _PreparedMaterialCell cell) {
    if (cell.gritPaint != null) {
      canvas.drawRect(cell.gritRect!, cell.gritPaint!);
    }
    if (cell.patternPaint != null) {
      canvas
        ..save()
        ..clipRect(cell.rect)
        ..drawPath(cell.patternPath!, cell.patternPaint!)
        ..restore();
    }
    if (cell.speckPaint != null) {
      canvas.drawCircle(cell.speckCenter!, 1.6, cell.speckPaint!);
    }
    if (cell.crackPaint != null) {
      canvas.drawPath(cell.crackPath!, cell.crackPaint!);
    }
    if (cell.edgePaint != null) {
      canvas.drawPath(cell.edgePath, cell.edgePaint!);
    }
  }

  Rect _cellRect(MaterialCell cell) => Rect.fromLTWH(
    cell.position.x * cameraCellSize,
    cell.position.y * cameraCellSize,
    cameraCellSize,
    cameraCellSize,
  );

  _WallFaces _wallFaces(MaterialCell cell, Set<Position> knownWalls) {
    if (cell.kind != MaterialTileKind.wall) return const _WallFaces.none();
    final position = cell.position;
    return _WallFaces(
      north: !knownWalls.contains(position.step(Direction.north)),
      east: !knownWalls.contains(position.step(Direction.east)),
      south: !knownWalls.contains(position.step(Direction.south)),
      west: !knownWalls.contains(position.step(Direction.west)),
    );
  }
}

class _PreparedMaterialCell {
  _PreparedMaterialCell._({
    required this.rect,
    required this.basePaint,
    required this.gritRect,
    required this.gritPaint,
    required this.patternPath,
    required this.patternPaint,
    required this.speckCenter,
    required this.speckPaint,
    required this.crackPath,
    required this.crackPaint,
    required this.edgePath,
    required this.edgePaint,
  });

  factory _PreparedMaterialCell.from({
    required MaterialMark mark,
    required MaterialCellPaint paint,
    required DungeonPalette palette,
    required MaterialTileKind kind,
    required double patternPhase,
    required Rect rect,
    required _WallFaces faces,
  }) {
    final gritAlpha = (paint.gritStrength * mark.grit).clamp(0.0, 1.0);
    final h = mark.grit.hashCode;
    final gritRect = gritAlpha <= 0.004
        ? null
        : Rect.fromLTWH(
            rect.left + (h % 1000) / 1000 * cameraCellSize * 0.8,
            rect.top + ((h ~/ 1000) % 1000) / 1000 * cameraCellSize * 0.8,
            1.2,
            1.2,
          );
    final crackPath = paint.crackStrength > 0 && mark.crack > 0
        ? _crackPath(rect, palette.material)
        : null;
    final patternPath = _patternPath(
      rect: rect,
      kind: kind,
      pattern: paint.pattern,
      strength: paint.patternStrength,
      phase: patternPhase,
    );
    final inner = rect.deflate(_wallEdgeInset);
    final edgePath = Path();
    if (paint.edge > 0 && faces.hasAny) {
      if (faces.north) {
        edgePath
          ..moveTo(inner.left, inner.top)
          ..lineTo(inner.right, inner.top);
      }
      if (faces.east) {
        edgePath
          ..moveTo(inner.right, inner.top)
          ..lineTo(inner.right, inner.bottom);
      }
      if (faces.south) {
        edgePath
          ..moveTo(inner.right, inner.bottom)
          ..lineTo(inner.left, inner.bottom);
      }
      if (faces.west) {
        edgePath
          ..moveTo(inner.left, inner.bottom)
          ..lineTo(inner.left, inner.top);
      }
    }
    final rounded = palette.material == RegionMaterial.seaCaveStone;
    return _PreparedMaterialCell._(
      rect: rect,
      basePaint: Paint()..color = paint.fill,
      gritRect: gritRect,
      gritPaint: gritRect == null
          ? null
          : (Paint()..color = palette.detailInk.withValues(alpha: gritAlpha)),
      patternPath: patternPath,
      patternPaint: patternPath == null
          ? null
          : (Paint()
              ..color = palette.detailInk.withValues(
                alpha: (0.18 + paint.patternStrength * 0.42).clamp(0.0, 1.0),
              )
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..strokeCap = rounded ? StrokeCap.round : StrokeCap.butt),
      speckCenter: paint.speck && mark.speck
          ? Offset(
              rect.left + cameraCellSize * 0.35 + mark.grit * 10,
              rect.top + cameraCellSize * 0.6,
            )
          : null,
      speckPaint: paint.speck && mark.speck
          ? (Paint()..color = palette.edgeInk.withValues(alpha: 0.35))
          : null,
      crackPath: crackPath,
      crackPaint: crackPath == null
          ? null
          : (Paint()
              ..color = dungeonVoid.withValues(alpha: 0.5)
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke),
      edgePath: edgePath,
      edgePaint: edgePath.getBounds().isEmpty
          ? null
          : (Paint()
              ..color = palette.edgeInk.withValues(
                alpha: 0.15 + (paint.edge * mark.edge).clamp(0.0, 1.0) * 0.4,
              )
              ..style = PaintingStyle.stroke
              ..strokeWidth = _wallEdgeStrokeWidth
              ..strokeCap = rounded ? StrokeCap.round : StrokeCap.butt),
    );
  }

  final Rect rect;
  final Paint basePaint;
  final Rect? gritRect;
  final Paint? gritPaint;
  final Path? patternPath;
  final Paint? patternPaint;
  final Offset? speckCenter;
  final Paint? speckPaint;
  final Path? crackPath;
  final Paint? crackPaint;
  final Path edgePath;
  final Paint? edgePaint;
}

Path _crackPath(Rect rect, RegionMaterial material) {
  if (material == RegionMaterial.ruinedKeepMasonry) {
    return Path()
      ..moveTo(rect.left + 5, rect.top + 8)
      ..lineTo(rect.left + cameraCellSize * 0.48, rect.top + 16)
      ..lineTo(rect.right - 5, rect.top + 9);
  }
  return Path()
    ..moveTo(rect.left + 4, rect.top + 6)
    ..quadraticBezierTo(
      rect.left + cameraCellSize * 0.5,
      rect.top + cameraCellSize * 0.55,
      rect.right - 3,
      rect.top + cameraCellSize * 0.35,
    );
}

Path? _patternPath({
  required Rect rect,
  required MaterialTileKind kind,
  required SurfacePattern pattern,
  required double strength,
  required double phase,
}) {
  if (pattern == SurfacePattern.none || strength <= 0) return null;
  final safe = rect.deflate(5);
  final shift = phase.clamp(0.0, 1.0) * 5;
  switch (pattern) {
    case SurfacePattern.tideStrata:
      final path = Path()
        ..moveTo(safe.left + shift, safe.top + 6)
        ..lineTo(safe.left + safe.width * 0.43, safe.top + 6)
        ..moveTo(safe.left + safe.width * 0.57, safe.top + 6)
        ..lineTo(safe.right - shift, safe.top + 6)
        ..moveTo(safe.left + 2.5 + shift, safe.bottom - 7)
        ..lineTo(safe.left + safe.width * 0.34, safe.bottom - 7)
        ..moveTo(safe.left + safe.width * 0.50, safe.bottom - 7)
        ..lineTo(safe.right - 2.5 - shift, safe.bottom - 7);
      return path;
    case SurfacePattern.ashlarFracture:
      if (kind == MaterialTileKind.floor && phase >= 0.28) return null;
      if (kind == MaterialTileKind.wall) {
        return Path()
          ..moveTo(safe.left + 2 + shift, safe.top + 8)
          ..lineTo(safe.left + safe.width * 0.50, safe.top + 8)
          ..lineTo(safe.left + safe.width * 0.50, safe.top + 16);
      }
      return Path()
        ..moveTo(safe.left + 3 + shift, safe.top + 10)
        ..lineTo(safe.left + safe.width * 0.48, safe.top + 18)
        ..lineTo(safe.right - 3, safe.top + 11);
    case SurfacePattern.roadWear:
      if (kind != MaterialTileKind.floor) return null;
      return Path()
        ..moveTo(safe.left + 4 + shift, safe.bottom - 9)
        ..lineTo(safe.left + safe.width * 0.42 + shift, safe.top + 9)
        ..moveTo(safe.left + safe.width * 0.55 + shift, safe.bottom - 9)
        ..lineTo(safe.right - 4, safe.top + 9);
    case SurfacePattern.none:
      return null;
  }
}

class _WallFaces {
  const _WallFaces({
    required this.north,
    required this.east,
    required this.south,
    required this.west,
  });

  const _WallFaces.none()
    : north = false,
      east = false,
      south = false,
      west = false;

  final bool north;
  final bool east;
  final bool south;
  final bool west;

  bool get hasAny => north || east || south || west;
}
