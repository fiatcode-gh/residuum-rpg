import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'glyph_plan.dart';

/// Which reticle a cell's target or selection fact draws as.
enum GlyphTargetMark { ticks, brackets }

/// How one glyph cell renders as a deliberate graphical mark.
///
/// The treatment decorates the cell's own glyph — it never replaces the
/// semantic character, never invents ink, and never encodes state by hue.
/// Value and reticle come from these decisions; actor identity stays
/// with the glyph and its shape.
class GlyphMarkTreatment {
  const GlyphMarkTreatment({required this.scale, this.targetMark});

  /// Relative draw scale for the subtle hierarchy between layers.
  final double scale;

  /// Which reticle, if any, decorates this cell. Selection supersedes
  /// marking: a selected target never also carries the plain ticks.
  final GlyphTargetMark? targetMark;

  @override
  bool operator ==(Object other) =>
      other is GlyphMarkTreatment &&
      other.scale == scale &&
      other.targetMark == targetMark;

  @override
  int get hashCode => Object.hash(scale, targetMark);
}

/// Decides the graphical treatment for one glyph cell.
///
/// Actors (nodes, litter, monsters, the hero) render as crisp marks with a
/// subtle scale hierarchy; the atmosphere's hero bloom
/// (`dungeon_atmosphere.dart`) is the hero's only extra emphasis. Every
/// terrain character uses its native cell size; actor and selection
/// treatments decorate their own glyphs.
GlyphMarkTreatment glyphMarkTreatment(GlyphCell cell) => GlyphMarkTreatment(
  scale: switch (cell.layer) {
    GlyphLayer.hero => 1.08,
    GlyphLayer.monster => 1.04,
    GlyphLayer.terrain || GlyphLayer.node => 1.0,
    GlyphLayer.litter => 0.94,
  },
  targetMark: cell.selected
      ? GlyphTargetMark.brackets
      : cell.marked
      ? GlyphTargetMark.ticks
      : null,
);

/// Resolves the presentation ink for one glyph without changing its
/// projection (PLAN.md G4). The result already carries alpha.
Color glyphInk(GlyphCell cell, Position hero) {
  if (cell.layer == GlyphLayer.terrain && cell.opacity == fullOpacity) {
    final dx = cell.position.x - hero.x;
    final dy = cell.position.y - hero.y;
    final distance = math.sqrt((dx * dx + dy * dy).toDouble());
    final t = (distance / fovRadius).clamp(0.0, 1.0);
    final light = (1 - t) * (1 - t);
    return Color.lerp(
      cell.shade,
      cell.ink,
      light,
    )!.withValues(alpha: 0.55 + 0.45 * light);
  }
  if ((cell.layer == GlyphLayer.terrain || cell.layer == GlyphLayer.node) &&
      cell.opacity != fullOpacity) {
    return cell.shade.withValues(alpha: rememberedOpacity);
  }
  return cell.ink.withValues(alpha: cell.opacity);
}
