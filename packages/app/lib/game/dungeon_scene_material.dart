import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../art/dungeon_art.dart';
import 'dungeon_material.dart';
import 'dungeon_palette.dart';
import 'dungeon_render_style.dart';
import 'glyph_plan.dart';
import 'grid_geometry.dart';

const Color dungeonVoid = Color(0xFF050607);

enum SurfacePattern { none, tideStrata, ashlarFracture, roadWear }

Color stoneLitColor(
  DungeonPalette palette,
  DungeonSurfaceTreatment treatment,
  double light,
) {
  final foundation = Color.lerp(
    palette.visibleStone,
    dungeonVoid,
    treatment.foundationDarken,
  )!;
  if (light <= 0) return foundation;
  final warmed = Color.lerp(
    foundation,
    palette.lightInk,
    palette.maxTintMix * treatment.tintScale * light,
  )!;
  final hsl = HSLColor.fromColor(warmed);
  return hsl
      .withLightness(
        (hsl.lightness +
                palette.maxLightLift * treatment.lightLiftScale * light)
            .clamp(0.0, 1.0),
      )
      .toColor();
}

Color _valueShadow(Color color, double strength) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness * (1 - strength)).clamp(0.0, 1.0))
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

/// The visible-only clip for one authored material surface.
///
/// Floors, both flights of stairs and unknown space are decided exactly as
/// [visibleMaterialMask] decides them: unknown cells are absent from the
/// plan, and remembered cells are absent from this mask.
Path visibleSurfaceMask(MaterialPlan plan, MaterialSurface surface) {
  final accepted = switch (surface) {
    MaterialSurface.floor => const {
      MaterialTileKind.floor,
      MaterialTileKind.stairsDown,
      MaterialTileKind.stairsUp,
    },
    MaterialSurface.wall => const {MaterialTileKind.wall},
  };
  final mask = Path();
  for (final cell in plan.cells) {
    if (cell.knowledge != MaterialKnowledge.visible) continue;
    if (!accepted.contains(cell.kind)) continue;
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
      edge: 0.0,
      gritStrength: 0.0,
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
  final treatment = dungeonSurfaceTreatment(
    palette,
    wall ? MaterialSurface.wall : MaterialSurface.floor,
  );
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
    fill: Color.lerp(
      palette.visibleStone,
      dungeonVoid,
      treatment.foundationDarken,
    )!,
    edge: stairs ? 0.0 : edge,
    gritStrength: grit,
    speck: stairs ? false : speck,
    crackStrength: stairs ? 0.0 : crackStrength,
    pattern: stairs ? SurfacePattern.none : pattern,
    patternStrength: stairs ? 0.0 : patternStrength,
  );
}

/// World-space period of the authored material's mirror-tiled window, in
/// world units — 576 source px at the Task 02 scale `0.32`.
const double _texturePeriod = 576 * 0.32;

/// The world-space offset one region's authored field is sampled from.
///
/// A pure function of the palette's [DungeonPalette.themeSalt] and the
/// surface: every floor of a region therefore shares one continuous field.
/// [MaterialPlan] carries no floor identity to vary it by, and inventing one
/// would change a projection this layer may not touch.
Offset _texturePhase(DungeonPalette palette, MaterialSurface surface) => Offset(
  materialPhase(
        const Position(0, 0),
        palette.themeSalt ^ 0x6666,
        surface.index,
      ) *
      _texturePeriod,
  materialPhase(
        const Position(0, 0),
        palette.themeSalt ^ 0x7777,
        surface.index,
      ) *
      _texturePeriod,
);

/// One authored surface's whole-layer clip-and-fill, built once per plan
/// adoption.
///
/// Nothing here is recomputed per frame: rendering only ever clips to [mask]
/// and fills [bounds] with [paint].
class _AuthoredSurfacePass {
  const _AuthoredSurfacePass({
    required this.mask,
    required this.bounds,
    required this.paint,
  });

  final Path mask;
  final Rect bounds;
  final Paint paint;
}

class _VisibleLightPass {
  const _VisibleLightPass({
    required this.mask,
    required this.bounds,
    required this.paint,
  });

  final Path mask;
  final Rect bounds;
  final Paint paint;
}

/// Draws the continuous stone material for one crawl.
///
/// One canvas component for the whole layer rather than a component per
/// speck: decoration is cheap canvas work over deterministic [MaterialMark]
/// decisions, and unknown space is simply never painted — the component only
/// ever iterates the plan's known cells.
class MaterialComponent extends PositionComponent {
  MaterialComponent(
    MaterialPlan initialPlan, {
    this.art = const DungeonArt.none(),
  }) : plan = initialPlan,
       super(
         position: Vector2.zero(),
         size: Vector2.all(1),
         priority: GlyphLayer.terrain.index,
       ) {
    _rebuildRenderPlan();
  }

  /// The authored art this component paints with, or none.
  final DungeonArt art;

  /// The material plan currently painted.
  ///
  /// Replaced in place when the scene synchronizes a new projection, so the
  /// layer keeps its position in the component tree across pans and focus
  /// changes exactly as the glyph components do.
  MaterialPlan plan;
  late List<_PreparedMaterialCell> _cells;
  _VisibleLightPass? _visibleFloorLight;
  _VisibleLightPass? _visibleWallLight;
  _AuthoredSurfacePass? _authoredFloor;
  _AuthoredSurfacePass? _authoredWall;

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
    final knownCells = {for (final cell in plan.cells) cell.position: cell};
    final prepared = <_PreparedMaterialCell>[];
    for (final cell in plan.cells) {
      final neighbours = knownMaterialNeighbours(cell.position, knownCells);
      prepared.add(
        _PreparedMaterialCell.from(
          cell: cell,
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
          neighbours: neighbours,
          faces: dungeonWallFaces(cell, neighbours),
          treatment: dungeonSurfaceTreatment(
            plan.palette,
            cell.kind == MaterialTileKind.wall
                ? MaterialSurface.wall
                : MaterialSurface.floor,
          ),
          art: art,
        ),
      );
    }
    _cells = prepared;
    final heroCenter = Offset(
      (plan.heroPosition.x + 0.5) * cameraCellSize,
      (plan.heroPosition.y + 0.5) * cameraCellSize,
    );
    final radius = (fovRadius + 1) * cameraCellSize;
    _visibleFloorLight = _visibleLightPass(
      MaterialSurface.floor,
      heroCenter,
      radius,
    );
    _visibleWallLight = _visibleLightPass(
      MaterialSurface.wall,
      heroCenter,
      radius,
    );
    _authoredFloor = _authoredSurfacePass(MaterialSurface.floor);
    _authoredWall = _authoredSurfacePass(MaterialSurface.wall);
  }

  _VisibleLightPass? _visibleLightPass(
    MaterialSurface surface,
    Offset heroCenter,
    double radius,
  ) {
    final mask = visibleSurfaceMask(plan, surface);
    final bounds = mask.getBounds();
    if (bounds.isEmpty) return null;
    final treatment = dungeonSurfaceTreatment(plan.palette, surface);
    return _VisibleLightPass(
      mask: mask,
      bounds: bounds,
      paint: Paint()
        ..shader = RadialGradient(
          colors: [
            stoneLitColor(plan.palette, treatment, 1),
            stoneLitColor(plan.palette, treatment, 0),
          ],
        ).createShader(Rect.fromCircle(center: heroCenter, radius: radius)),
    );
  }

  _AuthoredSurfacePass? _authoredSurfacePass(MaterialSurface surface) {
    final image = art.surfaceFor(plan.palette.material, surface);
    if (image == null) return null;
    final mask = visibleSurfaceMask(plan, surface);
    final bounds = mask.getBounds();
    if (bounds.isEmpty) return null;
    final phase = _texturePhase(plan.palette, surface);
    final treatment = dungeonSurfaceTreatment(plan.palette, surface);
    return _AuthoredSurfacePass(
      mask: mask,
      bounds: bounds,
      paint: Paint()
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: treatment.authoredStrength)
        ..blendMode = BlendMode.softLight
        ..filterQuality = FilterQuality.medium
        ..shader = ui.ImageShader(
          image,
          TileMode.mirror,
          TileMode.mirror,
          (Matrix4.identity()
                ..translateByDouble(phase.dx, phase.dy, 0, 1)
                ..scaleByDouble(
                  treatment.authoredScale,
                  treatment.authoredScale,
                  treatment.authoredScale,
                  1,
                ))
              .storage,
        ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final cell in _cells) {
      _drawCellBase(canvas, cell);
    }
    _drawVisibleLight(canvas);
    _drawAuthoredMaterial(canvas);
    for (final cell in _cells) {
      _drawCellDecoration(canvas, cell);
    }
  }

  void _drawCellBase(Canvas canvas, _PreparedMaterialCell cell) {
    canvas.drawRect(cell.rect, cell.basePaint);
  }

  void _drawVisibleLight(Canvas canvas) {
    _drawVisibleLightPass(canvas, _visibleFloorLight);
    _drawVisibleLightPass(canvas, _visibleWallLight);
  }

  void _drawVisibleLightPass(Canvas canvas, _VisibleLightPass? pass) {
    if (pass == null) return;
    canvas
      ..save()
      ..clipPath(pass.mask)
      ..drawRect(pass.bounds, pass.paint)
      ..restore();
  }

  void _drawAuthoredMaterial(Canvas canvas) {
    _drawAuthoredSurface(canvas, _authoredFloor);
    _drawAuthoredSurface(canvas, _authoredWall);
  }

  void _drawAuthoredSurface(Canvas canvas, _AuthoredSurfacePass? pass) {
    if (pass == null) return;
    canvas
      ..save()
      ..clipPath(pass.mask)
      ..drawRect(pass.bounds, pass.paint)
      ..restore();
  }

  void _drawOverlay(Canvas canvas, _PreparedMaterialCell cell) {
    final destination = cell.overlayRect!;
    final centerX = destination.left + destination.width / 2;
    final centerY = destination.top + destination.height / 2;
    canvas
      ..save()
      ..translate(centerX, centerY);
    if (cell.overlayMirrorX) canvas.scale(-1, 1);
    final turns = cell.overlayQuarterTurns;
    if (turns == 1) {
      canvas.rotate(math.pi / 2);
    } else if (turns == 2) {
      canvas.rotate(math.pi);
    } else if (turns == 3) {
      canvas.rotate(math.pi * 1.5);
    }
    canvas
      ..translate(-centerX, -centerY)
      ..clipRect(cell.rect);
    if (cell.overlayShadowPaint != null) {
      canvas.drawImageRect(
        cell.overlayImage!,
        cell.overlaySrc!,
        destination,
        cell.overlayShadowPaint!,
      );
    }
    canvas.drawImageRect(
      cell.overlayImage!,
      cell.overlaySrc!,
      destination,
      cell.overlayPaint!,
    );
    canvas.restore();
  }

  void _drawCellDecoration(Canvas canvas, _PreparedMaterialCell cell) {
    if (!cell.hasDecoration) return;
    canvas
      ..save()
      ..clipRect(cell.rect);
    if (cell.overlayImage != null) {
      _drawOverlay(canvas, cell);
    }
    if (cell.gritPaint != null) {
      canvas.drawRect(cell.gritRect!, cell.gritPaint!);
    }
    if (cell.patternPaint != null) {
      canvas.drawPath(cell.patternPath!, cell.patternPaint!);
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
    canvas.restore();
  }

  Rect _cellRect(MaterialCell cell) => Rect.fromLTWH(
    cell.position.x * cameraCellSize,
    cell.position.y * cameraCellSize,
    cameraCellSize,
    cameraCellSize,
  );
}

class _PreparedMaterialCell {
  _PreparedMaterialCell._({
    required this.rect,
    required this.basePaint,
    required this.hasDecoration,
    required this.overlayImage,
    required this.overlayRect,
    required this.overlayQuarterTurns,
    required this.overlayMirrorX,
    required this.overlayShadowPaint,

    required this.overlaySrc,
    required this.overlayPaint,
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
    required this.neighbours,
  });
  factory _PreparedMaterialCell.from({
    required MaterialCell cell,
    required MaterialMark mark,
    required MaterialCellPaint paint,
    required DungeonPalette palette,
    required MaterialTileKind kind,
    required double patternPhase,
    required Rect rect,
    required KnownMaterialNeighbours neighbours,
    required DungeonWallFaces faces,
    required DungeonSurfaceTreatment treatment,
    required DungeonArt art,
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
    final crackGate = paint.crackStrength > 0 && mark.crack > 0;
    final speckGate = paint.speck && mark.speck;
    final OverlayKind? candidate = crackGate
        ? (mark.crack >= 0.3 ? OverlayKind.crackB : OverlayKind.crackA)
        : speckGate
        ? (mark.grit >= 0.2
              ? OverlayKind.rubbleMedium
              : OverlayKind.rubbleSmall)
        : null;
    final placement = decorationPlacement(
      cell: cell,
      mark: mark,
      candidate: candidate,
      palette: palette,
      neighbours: neighbours,
      faces: faces,
    );
    final overlayImage = placement.draw && candidate != null
        ? art.overlayFor(palette.material, candidate)
        : null;
    final overlayRect = overlayImage == null
        ? null
        : Rect.fromLTWH(
            rect.left + placement.destination.left * rect.width,
            rect.top + placement.destination.top * rect.height,
            placement.destination.width * rect.width,
            placement.destination.height * rect.height,
          );
    final overlaySrc = overlayImage == null
        ? null
        : Rect.fromLTWH(
            0,
            0,
            overlayImage.width.toDouble(),
            overlayImage.height.toDouble(),
          );

    final crackPath = crackGate && placement.draw && overlayImage == null
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
    final hasGrit = gritRect != null;
    final hasPattern = patternPath != null;
    final speck = speckGate && placement.draw && overlayImage == null;
    final hasCrack = crackPath != null;
    final hasEdge = !edgePath.getBounds().isEmpty;
    final hasOverlay = overlayImage != null;
    final hasDecoration =
        hasGrit || hasPattern || speck || hasCrack || hasEdge || hasOverlay;
    return _PreparedMaterialCell._(
      rect: rect,
      neighbours: neighbours,
      basePaint: Paint()..color = paint.fill,
      hasDecoration: hasDecoration,
      overlayImage: overlayImage,
      overlayRect: overlayRect,
      overlayQuarterTurns: placement.quarterTurns,
      overlayMirrorX: placement.mirrorX,
      overlayShadowPaint:
          overlayImage == null || placement.groundShadowOpacity <= 0
          ? null
          : (Paint()
              ..color = dungeonVoid.withValues(
                alpha: placement.groundShadowOpacity,
              )
              ..filterQuality = FilterQuality.medium),
      overlaySrc: overlaySrc,
      overlayPaint: overlayImage == null
          ? null
          : (Paint()
              ..color = const Color(0xFFFFFFFF)
                  .withValues(alpha: placement.opacity)
              ..filterQuality = FilterQuality.medium),
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
      speckCenter: speck
          ? Offset(
              rect.left + cameraCellSize * 0.35 + mark.grit * 10,
              rect.top + cameraCellSize * 0.6,
            )
          : null,
      speckPaint: speck
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
              ..color = _valueShadow(palette.edgeInk, treatment.boundaryShadow)
                  .withValues(
                    alpha:
                        0.15 + (paint.edge * mark.edge).clamp(0.0, 1.0) * 0.4,
                  )
              ..style = PaintingStyle.stroke
              ..strokeWidth = _wallEdgeStrokeWidth
              ..strokeCap = rounded ? StrokeCap.round : StrokeCap.butt),
    );
  }

  final Rect rect;
  final Paint basePaint;
  final bool hasDecoration;
  final ui.Image? overlayImage;
  final Rect? overlayRect;
  final int overlayQuarterTurns;
  final bool overlayMirrorX;
  final Paint? overlayShadowPaint;
  final Rect? overlaySrc;
  final Paint? overlayPaint;
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
  final KnownMaterialNeighbours neighbours;
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
