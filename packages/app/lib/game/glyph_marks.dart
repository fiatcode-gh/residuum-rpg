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
      GlyphLayer.hero => 1.08,
      GlyphLayer.monster => 1.04,
      GlyphLayer.terrain => 1.02,
      GlyphLayer.node => 1.0,
      GlyphLayer.litter => 0.94,
    },
    halo: cell.layer == GlyphLayer.hero,
    targetOutline: cell.marked ? GlyphOutlineShape.square : null,
    selectedOutline: cell.selected ? GlyphOutlineShape.circle : null,
  );
}
