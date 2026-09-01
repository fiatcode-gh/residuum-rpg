import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'glyph_grid.dart';

/// What every glyph paints at when the cell is remembered rather than seen.
///
/// One constant for terrain and veins alike, because the two fade together or
/// not at all — a remembered floor and the vein that stood on it are the same
/// kind of fact about the place.
const double rememberedOpacity = 0.4;

/// What a cell the hero can see right now paints at.
const double fullOpacity = 1.0;

/// One glyph the crawl draws: where, what character, in what ink, at what
/// strength.
///
/// The paint plan is the whole crawl as data, in draw order — terrain first,
/// then nodes, then litter, then monsters, then the hero — so the tests can
/// hold the painter to what it draws without a screenshot. The painter is the
/// brush; this is the picture.
class GlyphCell {
  const GlyphCell(this.position, this.glyph, this.ink, this.opacity);

  final Position position;
  final String glyph;
  final Color ink;

  /// 1.0 for everything the hero is looking at, [rememberedOpacity] for
  /// anything only the map remembers.
  final double opacity;
}

/// What the hero's own glyph is drawn in.
const Color _heroInk = Color(0xFFFFFFFF);

/// What a monster is drawn in.
const Color _monsterInk = Color(0xFFD9A227);

/// Everything one crawl draws, in the order the painter lays it down.
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
List<GlyphCell> glyphPlan(GameState game, DungeonPalette palette) {
  final cells = <GlyphCell>[];
  for (var y = 0; y < game.map.height; y++) {
    for (var x = 0; x < game.map.width; x++) {
      final position = Position(x, y);
      final visible = game.visible.contains(position);
      if (!visible && !game.explored.contains(position)) continue;
      cells.add(
        GlyphCell(
          position,
          terrainGlyph(game.map.tileAt(position)),
          terrainInk(game.map.tileAt(position), palette),
          visible ? fullOpacity : rememberedOpacity,
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
      ),
    );
  }
  for (final tile in game.groundItems.entries) {
    if (!game.visible.contains(tile.key) || tile.value.isEmpty) continue;
    cells.add(
      GlyphCell(tile.key, tile.value.last.base.glyph, litterInk, fullOpacity),
    );
  }
  for (final monster in game.monsters) {
    if (!game.visible.contains(monster.position)) continue;
    cells.add(
      GlyphCell(monster.position, monster.glyph, _monsterInk, fullOpacity),
    );
  }
  cells.add(
    GlyphCell(game.hero.position, game.hero.glyph, _heroInk, fullOpacity),
  );
  return cells;
}

/// The glyph a terrain tile draws as.
String terrainGlyph(Tile tile) => switch (tile) {
  Tile.wall => '#',
  Tile.floor => '.',
  Tile.stairsDown => '>',
  Tile.stairsUp => '<',
};

/// The ink a terrain tile is tinted with, by this dungeon's palette.
Color terrainInk(Tile tile, DungeonPalette palette) => switch (tile) {
  Tile.wall => palette.wall,
  Tile.floor => palette.floor,
  Tile.stairsDown => palette.stairs,
  Tile.stairsUp => palette.stairs,
};
