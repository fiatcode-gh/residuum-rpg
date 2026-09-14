import 'glyph_plan.dart';

/// How one glyph cell renders as a deliberate graphical mark.
///
/// The treatment decorates the cell's own glyph — it never replaces the
/// semantic character, never invents ink, and never encodes state by hue.
/// Value, outline, and halo come from these decisions; actor identity stays
/// with the glyph and its shape.
class GlyphMarkTreatment {
  const GlyphMarkTreatment({required this.scale, required this.halo});

  /// Relative draw scale for the subtle hierarchy between layers.
  final double scale;

  /// Whether a very small halo backs the glyph (hero and significant marks).
  final bool halo;

  @override
  bool operator ==(Object other) =>
      other is GlyphMarkTreatment && other.scale == scale && other.halo == halo;

  @override
  int get hashCode => Object.hash(scale, halo);
}

/// Decides the graphical treatment for one glyph cell.
///
/// Actors (nodes, litter, monsters, the hero) render as crisp marks with a
/// subtle scale hierarchy — the hero carries the only halo, as the most
/// significant mark on the floor. A caller may mark
/// explicit terrain facts (such as stairs from the material plan) as semantic
/// features so they remain findable above the stone. Wall and floor glyphs get
/// no treatment here — the material layer owns them, and this function never
/// parses glyph characters back into terrain semantics.
GlyphMarkTreatment glyphMarkTreatment(
  GlyphCell cell, {
  bool semanticTerrain = false,
}) {
  if (cell.layer == GlyphLayer.terrain && !semanticTerrain) {
    return const GlyphMarkTreatment(scale: 1.0, halo: false);
  }

  return GlyphMarkTreatment(
    scale: switch (cell.layer) {
      GlyphLayer.hero => 1.16,
      GlyphLayer.monster => 1.08,
      GlyphLayer.terrain => 1.04,
      GlyphLayer.node => 1.0,
      GlyphLayer.litter => 0.92,
    },
    halo: cell.layer == GlyphLayer.hero,
  );
}
