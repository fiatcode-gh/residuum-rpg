import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'glyph_plan.dart';

/// Base font size as a fraction of the owning camera cell.
const double glyphBaseFontScale = 0.73;

/// Which shape carries a target or selection fact around an actor glyph.
enum GlyphOutlineShape { square, circle }

/// How one glyph cell renders as a deliberate graphical mark.
///
/// The treatment decorates the cell's own glyph — it never replaces the
/// semantic character, never invents ink, and never encodes state by hue.
/// Value, outline, and halo come from these decisions; actor identity stays
/// with the glyph and its shape.
class GlyphMarkTreatment {
  const GlyphMarkTreatment({
    required this.scale,
    required this.halo,
    this.targetOutline,
    this.selectedOutline,
  });

  /// Relative draw scale for the subtle hierarchy between layers.
  final double scale;

  /// Whether a very small halo backs the glyph (hero and significant marks).
  final bool halo;

  final GlyphOutlineShape? targetOutline;
  final GlyphOutlineShape? selectedOutline;

  @override
  bool operator ==(Object other) =>
      other is GlyphMarkTreatment &&
      other.scale == scale &&
      other.halo == halo &&
      other.targetOutline == targetOutline &&
      other.selectedOutline == selectedOutline;

  @override
  int get hashCode => Object.hash(scale, halo, targetOutline, selectedOutline);
}

/// Decides the graphical treatment for one glyph cell.
///
/// Actors (nodes, litter, monsters, the hero) render as crisp marks with a
/// subtle scale hierarchy — the hero carries the only halo, as the most
/// significant mark on the floor. Every terrain character uses its native cell
/// size; actor and selection treatments decorate their own glyphs.
GlyphMarkTreatment glyphMarkTreatment(GlyphCell cell) => GlyphMarkTreatment(
  scale: switch (cell.layer) {
    GlyphLayer.hero => 1.08,
    GlyphLayer.monster => 1.04,
    GlyphLayer.terrain || GlyphLayer.node => 1.0,
    GlyphLayer.litter => 0.94,
  },
  halo: cell.layer == GlyphLayer.hero,
  targetOutline: cell.marked ? GlyphOutlineShape.square : null,
  selectedOutline: cell.selected ? GlyphOutlineShape.circle : null,
);

/// Resolves the presentation ink for one glyph without changing its projection.
Color terrainPresentationInk(GlyphCell cell, Position hero) {
  if (cell.layer != GlyphLayer.terrain || cell.opacity != fullOpacity) {
    return cell.ink;
  }

  final dx = cell.position.x - hero.x;
  final dy = cell.position.y - hero.y;
  final distanceSquared = dx * dx + dy * dy;
  final strength = (1 - distanceSquared / 25).clamp(0.0, 1.0);
  return Color.lerp(cell.ink, const Color(0xFFE8C58A), 0.38 * strength)!;
}
