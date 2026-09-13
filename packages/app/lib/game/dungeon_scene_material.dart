import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'dungeon_material.dart';
import 'glyph_plan.dart';
import 'grid_geometry.dart';

/// The art-bible material anchors for the Crypt baseline.
///
/// These are the 2026-09-13 approved anchors from
/// `.flow/ldd/visual-reboot/units/unit-2/ART-BIBLE.md`. Exact values may tune
/// during device acceptance without reopening the direction.
const Color dungeonVoid = Color(0xFF050607);
const Color rememberedStoneColor = Color(0xFF1A1E20);
const Color _visibleStone = Color(0xFF292A27);
const Color _stoneEdge = Color(0xFF48463F);
const Color _warmInk = Color(0xFFD4B77B);
const Color _hotLight = Color(0xFFE8C58A);

/// How far the warm light lifts stone value at full presentation light.
///
/// Light alters value first, hue second, so the lift is capped well below a
/// game-like glow: lit stone stays charcoal with warmth, not amber.
const double _maxLightLift = 0.30;

/// How much of the lift may go into warmth once the value step is paid.
const double _maxWarmth = 0.12;

/// The warm light color mixed onto lit stone, by presentation light value.
Color stoneLitColor(double light) {
  final warmed = Color.lerp(_visibleStone, _hotLight, _maxWarmth * light)!;
  final hsl = HSLColor.fromColor(warmed);
  return hsl
      .withLightness((hsl.lightness + _maxLightLift * light).clamp(0.0, 1.0))
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

  @override
  bool operator ==(Object other) =>
      other is MaterialCellPaint &&
      other.fill == fill &&
      other.edge == edge &&
      other.gritStrength == gritStrength &&
      other.speck == speck &&
      other.crackStrength == crackStrength;

  @override
  int get hashCode =>
      Object.hash(fill, edge, gritStrength, speck, crackStrength);
}

/// Decides one known tile's material paint.
///
/// Remembered geometry paints flat, dark, and unlit — one value for the whole
/// remembered region, no light lift. Visible geometry takes the warm
/// presentation light the plan already clipped to authoritative visibility,
/// and masonry walls share one continuous surface treatment while exposed
/// faces carry their own edge.
MaterialCellPaint materialCellPaint(
  MaterialCell cell, {
  required bool masonry,
}) {
  if (cell.knowledge == MaterialKnowledge.remembered) {
    return MaterialCellPaint(
      fill: rememberedStoneColor,
      edge: masonry ? 0.06 : 0.12,
      gritStrength: cell.kind == MaterialTileKind.wall ? 0.05 : 0.03,
      speck: false,
      crackStrength: 0.0,
    );
  }

  final wall = cell.kind == MaterialTileKind.wall;
  return MaterialCellPaint(
    fill: stoneLitColor(cell.light),
    edge: wall ? (masonry ? 0.0 : 0.55) : 0.0,
    gritStrength: wall ? 0.14 : 0.08,
    speck: !wall,
    crackStrength: wall && !masonry ? 0.5 : 0.0,
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
      );

  /// The material plan currently painted.
  ///
  /// Replaced in place when the scene synchronizes a new projection, so the
  /// layer keeps its position in the component tree across pans and focus
  /// changes exactly as the glyph components do.
  MaterialPlan plan;

  /// Adopts a new plan, replacing the painted one.
  ///
  /// A pan-only viewport change hands back the identical plan and this is a
  /// no-op by identity; a real projection change repaints from the new plan.
  void adopt(MaterialPlan next) {
    if (identical(plan, next)) return;
    plan = next;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final cell in plan.cells) {
      _drawCell(canvas, cell);
    }
  }

  void _drawCell(Canvas canvas, MaterialCell cell) {
    final mark = plan.markAt(cell.position);
    if (mark == null) return;
    final masonry = plan.masonryAt(cell.position);
    final paint = materialCellPaint(cell, masonry: masonry);
    final rect = Rect.fromLTWH(
      cell.position.x * cameraCellSize,
      cell.position.y * cameraCellSize,
      cameraCellSize,
      cameraCellSize,
    );

    canvas.drawRect(rect, Paint()..color = paint.fill);

    if (paint.gritStrength > 0) _drawGrit(canvas, rect, mark, paint);

    if (paint.speck && mark.speck) _drawSpeck(canvas, rect, mark);

    if (paint.crackStrength > 0 && mark.crack > 0) {
      _drawCrack(canvas, rect, mark);
    }
    if (paint.edge > 0) _drawMasonryEdge(canvas, rect, mark, paint);
  }

  void _drawGrit(
    Canvas canvas,
    Rect rect,
    MaterialMark mark,
    MaterialCellPaint paint,
  ) {
    final alpha = (paint.gritStrength * mark.grit).clamp(0.0, 1.0);
    if (alpha <= 0.004) return;
    final brush = Paint()..color = _warmInk.withValues(alpha: alpha);
    final h = mark.grit.hashCode;
    final ox = (h % 1000) / 1000 * cameraCellSize * 0.8;
    final oy = ((h ~/ 1000) % 1000) / 1000 * cameraCellSize * 0.8;
    canvas.drawRect(
      Rect.fromLTWH(rect.left + ox, rect.top + oy, 1.2, 1.2),
      brush,
    );
  }

  void _drawSpeck(Canvas canvas, Rect rect, MaterialMark mark) {
    final chip = Paint()..color = _stoneEdge.withValues(alpha: 0.35);
    final cx = rect.left + cameraCellSize * 0.35 + mark.grit * 10;
    final cy = rect.top + cameraCellSize * 0.6;
    canvas.drawCircle(Offset(cx, cy), 1.6, chip);
  }

  void _drawCrack(Canvas canvas, Rect rect, MaterialMark mark) {
    final hairline = Paint()
      ..color = dungeonVoid.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final start = Offset(rect.left + 4, rect.top + 6);
    final mid = Offset(
      rect.left + cameraCellSize * 0.5,
      rect.top + cameraCellSize * 0.55,
    );
    final end = Offset(rect.right - 3, rect.top + cameraCellSize * 0.35);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    canvas.drawPath(path, hairline);
  }

  void _drawMasonryEdge(
    Canvas canvas,
    Rect rect,
    MaterialMark mark,
    MaterialCellPaint paint,
  ) {
    final strength = (paint.edge * mark.edge).clamp(0.0, 1.0);
    final brush = Paint()
      ..color = _stoneEdge.withValues(alpha: 0.15 + strength * 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect.deflate(0.6), brush);
  }
}
