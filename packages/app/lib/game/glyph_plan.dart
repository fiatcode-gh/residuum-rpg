import 'package:flutter/material.dart';

import 'actor_presentation.dart';

import 'package:residuum_core/core.dart';

import 'dungeon_palette.dart';
import '../style/tokens.dart' show crawlHero, crawlEnemy;

/// What every glyph paints at when the cell is remembered rather than seen.
///
/// One constant for terrain and veins alike, because the two fade together or
/// not at all — a remembered floor and the vein that stood on it are the same
/// kind of fact about the place.
const double rememberedOpacity = 0.24;

/// What a cell the hero can see right now paints at.
const double fullOpacity = 1.0;

/// One glyph the crawl draws: where, what character, in what ink, at what
/// strength.
///
/// The paint plan is the whole crawl as data, in draw order — terrain first,
/// then nodes, then litter, then monsters, then the hero — so tests hold the
/// projection to its semantics without a screenshot. Renderers consume the
/// same picture.
enum GlyphLayer { terrain, node, litter, monster, hero }

typedef GlyphRenderId = ({GlyphLayer layer, Object entity});

class GlyphCell {
  const GlyphCell(
    this.position,
    this.glyph,
    this.ink,
    this.opacity, {
    this.marked = false,
    this.layer = GlyphLayer.terrain,
    this.entity,
    this.badge,
    this.selected = false,
    Color? shade,
  }) : shade = shade ?? ink;

  final Position position;
  final String glyph;
  final Color ink;

  /// What a remembered or edge-of-sight cell fades toward — the same colour
  /// as [ink] unless the cell is terrain, which carries its own dim stone
  /// tone (PLAN.md G4). Defaulting to [ink] keeps every other layer's single
  /// colour exactly what it always was.
  final Color shade;

  /// 1.0 for everything the hero is looking at, [rememberedOpacity] for
  /// anything only the map remembers.
  final double opacity;

  /// Whether this cell is a legal target of the armed action. An outline carries
  /// the state by shape and position, never hue.
  final bool marked;

  /// An optional encounter-local identity badge, separate from [glyph].
  final String? badge;

  /// Whether this visible actor is the current presentation selection.
  final bool selected;

  /// The render layer and entity this cell represents.
  final GlyphLayer layer;
  final Object? entity;

  GlyphRenderId get renderId => (layer: layer, entity: entity ?? position);
}

/// Everything one crawl projects, in draw order.
///
/// Terrain first — every explored cell, full where the hero is looking and
/// faded where the map only remembers — then the veins and patches, then the
/// litter, then the monsters, then the hero. **The order is the grammar, not
/// an implementation detail**: an item dropped on a vein has to be the glyph
/// the player sees, and a monster standing on either has to be the glyph above
/// both.
///
/// A vein is part of the place — it is not going anywhere — so it rides the
/// terrain's rule and stays drawn on the remembered map at
/// [rememberedOpacity]. Litter and monsters are events: they exist only where
/// the hero is looking, and a remembered map says nothing about them.
List<GlyphCell> glyphPlan(
  GameState game, {
  Set<String> markedIds = const {},
  Map<String, ActorPresentation> actorPresentations = const {},
  String? selectedActorId,
}) {
  final cells = <GlyphCell>[];
  for (var y = 0; y < game.map.height; y++) {
    for (var x = 0; x < game.map.width; x++) {
      final position = Position(x, y);
      final visible = game.visible.contains(position);
      if (!visible && !game.explored.contains(position)) continue;
      final tile = game.map.tileAt(position);
      cells.add(
        GlyphCell(
          position,
          terrainGlyph(tile),
          terrainInk(tile),
          visible ? fullOpacity : rememberedOpacity,
          shade: terrainShade(tile),
          layer: GlyphLayer.terrain,
        ),
      );
    }
  }
  for (final node in game.nodes.entries) {
    final seen = game.visible.contains(node.key);
    final remembered = game.explored.contains(node.key);
    if (!seen && !remembered) continue;
    cells.add(
      GlyphCell(
        node.key,
        node.value.glyph,
        nodeInk,
        seen ? fullOpacity : rememberedOpacity,
        layer: GlyphLayer.node,
      ),
    );
  }
  for (final tile in game.groundItems.entries) {
    if (!game.visible.contains(tile.key) || tile.value.isEmpty) continue;
    cells.add(
      GlyphCell(
        tile.key,
        tile.value.last.base.glyph,
        litterInk,
        fullOpacity,
        layer: GlyphLayer.litter,
      ),
    );
  }
  for (final monster in game.monsters) {
    if (!game.visible.contains(monster.position)) continue;
    cells.add(
      GlyphCell(
        monster.position,
        monster.glyph,
        crawlEnemy,
        fullOpacity,
        marked: markedIds.contains(monster.id),
        layer: GlyphLayer.monster,
        entity: monster.id,
        badge: actorPresentations[monster.id]?.badge,
        selected: monster.id == selectedActorId,
      ),
    );
  }
  cells.add(
    GlyphCell(
      game.hero.position,
      game.hero.glyph,
      crawlHero,
      fullOpacity,
      layer: GlyphLayer.hero,
      entity: game.hero.id,
    ),
  );
  return cells;
}

/// The glyph a terrain tile draws as.
String terrainGlyph(Tile tile) => switch (tile) {
  Tile.wall => '#',
  Tile.floor => '·',
  Tile.stairsDown => '>',
  Tile.stairsUp => '<',
};

/// The lit ink a terrain tile is tinted with — warm stone, identical in
/// every region (PLAN.md G3).
Color terrainInk(Tile tile) => switch (tile) {
  Tile.wall => stoneWallLit,
  Tile.floor => stoneFloorLit,
  Tile.stairsDown => stoneStairsLit,
  Tile.stairsUp => stoneStairsLit,
};

/// The dim ink a terrain tile fades toward at the edge of sight or once
/// remembered (PLAN.md G4).
Color terrainShade(Tile tile) => switch (tile) {
  Tile.wall => stoneWallShade,
  Tile.floor => stoneFloorShade,
  Tile.stairsDown => stoneStairsShade,
  Tile.stairsUp => stoneStairsShade,
};
