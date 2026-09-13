import 'package:flutter/material.dart';

import 'glyph_plan.dart';

/// How one glyph cell renders as a deliberate graphical mark.
///
/// The treatment decorates the cell's own glyph — it never replaces the
/// semantic character, never invents ink, and never encodes state by hue.
/// Value, outline, and halo come from these decisions; actor identity stays
/// with the glyph and its shape.
class GlyphMarkTreatment {
  const GlyphMarkTreatment({
    required this.glyph,
    required this.ink,
    required this.opacity,
    required this.scale,
    required this.halo,
    required this.shadow,
  });

  /// The cell's own semantic glyph, unchanged.
  final String glyph;

  /// The cell's own ink, unchanged.
  final Color ink;

  /// The cell's own opacity, unchanged for actors.
  final double opacity;

  /// Relative draw scale for the subtle hierarchy between layers.
  final double scale;

  /// Whether a very small halo backs the glyph (hero and significant marks).
  final bool halo;

  /// Whether a restrained shadow grounds the glyph against the stone.
  final bool shadow;

  @override
  bool operator ==(Object other) =>
      other is GlyphMarkTreatment &&
      other.glyph == glyph &&
      other.ink == ink &&
      other.opacity == opacity &&
      other.scale == scale &&
      other.halo == halo &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(glyph, ink, opacity, scale, halo, shadow);
}

/// Decides the graphical treatment for one glyph cell.
///
/// Actors (nodes, litter, monsters, the hero) render as crisp marks with a
/// restrained shadow and a subtle scale hierarchy — the hero carries the
/// only halo, as the most significant mark on the floor. Terrain is not
/// treated here: the material layer owns the visible terrain, and the glyph
/// plan's terrain entries remain the characterization boundary.
GlyphMarkTreatment glyphMarkTreatment(GlyphCell cell) {
  if (cell.layer == GlyphLayer.terrain) {
    return GlyphMarkTreatment(
      glyph: cell.glyph,
      ink: cell.ink,
      opacity: cell.opacity,
      scale: 1.0,
      halo: false,
      shadow: false,
    );
  }

  return GlyphMarkTreatment(
    glyph: cell.glyph,
    ink: cell.ink,
    opacity: cell.opacity,
    scale: switch (cell.layer) {
      GlyphLayer.hero => 1.16,
      GlyphLayer.monster => 1.08,
      GlyphLayer.node => 1.0,
      GlyphLayer.litter => 0.92,
      GlyphLayer.terrain => 1.0,
    },
    halo: cell.layer == GlyphLayer.hero,
    shadow: true,
  );
}
