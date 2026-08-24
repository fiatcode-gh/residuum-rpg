import 'package:flutter/material.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'game_bloc.dart';
import 'grid_geometry.dart';

/// The tints one dungeon's terrain is drawn in.
///
/// **Additional signal, never the signal.** Every tile already says what it is
/// by glyph — `#` wall, `.` floor, `>` and `<` stairs — and the crawl says where
/// it is in words above the map. The tints exist so the sea-cave does not look
/// like the crypt at a glance; they are not how anything is told apart, and the
/// author is deuteranomalous, so each palette has to separate by *value* as well
/// as hue and read in greyscale with the colour thrown away.
///
/// Only terrain is themed. The hero, the monsters and the litter keep one set of
/// colours everywhere, because those three are read against each other rather
/// than against the place — a monster that changed colour by dungeon would make
/// the one glyph that matters harder to find, not easier.
class DungeonPalette {
  const DungeonPalette({
    required this.wall,
    required this.floor,
    required this.stairs,
  });

  /// The crypt's, byte for byte what the game has always drawn.
  ///
  /// Frozen rather than restyled: the crypt is the dungeon every screenshot and
  /// every device pass so far was taken in, and a theme sweep that quietly
  /// repainted it would make those unusable as a baseline.
  static const DungeonPalette crypt = DungeonPalette(
    wall: Color(0xFFB9BEC6),
    floor: Color(0xFF5B6270),
    stairs: Color(0xFFE8ECF2),
  );

  /// The sea-cave: wet stone, darker underfoot than the crypt.
  static const DungeonPalette seaCave = DungeonPalette(
    wall: Color(0xFF9FC2C6),
    floor: Color(0xFF44575E),
    stairs: Color(0xFFE4F1F2),
  );

  /// The ruined keep: rusted stone, and the palest walls of the three.
  static const DungeonPalette ruinedKeep = DungeonPalette(
    wall: Color(0xFFC8B79C),
    floor: Color(0xFF64594A),
    stairs: Color(0xFFF2EDE2),
  );

  final Color wall;
  final Color floor;
  final Color stairs;
}

/// The palette the dungeon at [node] is drawn in.
///
/// The crypt's is also the fallback, because a road fight has no node and the
/// ground under one is the ground the game has always drawn.
DungeonPalette paletteFor(NodeId? node) {
  if (node == seaCave) return DungeonPalette.seaCave;
  if (node == ruinedKeep) return DungeonPalette.ruinedKeep;
  return DungeonPalette.crypt;
}

class GlyphGrid extends StatelessWidget {
  const GlyphGrid({
    required this.state,
    required this.onTap,
    required this.onPan,
    this.palette = DungeonPalette.crypt,
    super.key,
  });

  final GameViewState state;
  final ValueChanged<Position> onTap;
  final ValueChanged<Offset> onPan;

  /// What this dungeon's terrain is tinted with.
  final DungeonPalette palette;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final geometry = GridGeometry.camera(
        size,
        state.game.map.width,
        state.game.map.height,
        state.game.hero.position,
        state.pan,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final position = geometry.positionAt(details.localPosition);
          if (position != null) onTap(position);
        },
        onPanUpdate: (details) => onPan(details.delta),
        child: CustomPaint(
          size: size,
          painter: _GlyphPainter(
            state: state,
            geometry: geometry,
            palette: palette,
          ),
        ),
      );
    },
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.state,
    required this.geometry,
    required this.palette,
  });

  static const _hero = Color(0xFFFFFFFF);
  static const _monster = Color(0xFFD9A227);
  static const _item = Color(0xFF7FC8B8);
  static const _rememberedOpacity = 0.4;

  final GameViewState state;
  final GridGeometry geometry;
  final DungeonPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final game = state.game;
    for (var y = 0; y < game.map.height; y++) {
      for (var x = 0; x < game.map.width; x++) {
        final position = Position(x, y);
        final visible = game.visible.contains(position);
        if (!visible && !game.explored.contains(position)) continue;
        _paintGlyph(
          canvas,
          position,
          _glyphFor(game.map.tileAt(position)),
          _colourFor(game.map.tileAt(position)),
          visible,
        );
      }
    }
    for (final tile in game.groundItems.entries) {
      if (!game.visible.contains(tile.key) || tile.value.isEmpty) continue;
      _paintGlyph(canvas, tile.key, tile.value.last.base.glyph, _item, true);
    }
    for (final monster in game.monsters) {
      if (!game.visible.contains(monster.position)) continue;
      _paintGlyph(canvas, monster.position, monster.glyph, _monster, true);
    }
    _paintGlyph(canvas, game.hero.position, game.hero.glyph, _hero, true);
  }

  static String _glyphFor(Tile tile) => switch (tile) {
    Tile.wall => '#',
    Tile.floor => '.',
    Tile.stairsDown => '>',
    Tile.stairsUp => '<',
  };

  Color _colourFor(Tile tile) => switch (tile) {
    Tile.wall => palette.wall,
    Tile.floor => palette.floor,
    Tile.stairsDown => palette.stairs,
    Tile.stairsUp => palette.stairs,
  };

  void _paintGlyph(
    Canvas canvas,
    Position position,
    String glyph,
    Color color,
    bool visible,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          color: visible ? color : color.withValues(alpha: _rememberedOpacity),
          fontSize: geometry.cellSize,
          fontFamily: 'monospace',
          height: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final cell = geometry.topLeftOf(position.x, position.y);
    painter.paint(
      canvas,
      cell +
          Offset(
            (geometry.cellSize - painter.width) / 2,
            (geometry.cellSize - painter.height) / 2,
          ),
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.geometry != geometry ||
      oldDelegate.palette != palette;
}
