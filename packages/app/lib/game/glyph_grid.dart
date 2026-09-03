import 'package:flutter/material.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'game_bloc.dart';
import 'glyph_plan.dart';
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

/// What the litter on a floor is drawn in.
///
/// Public so the palette tests can hold it apart from [nodeInk] in greyscale.
/// Unthemed, like the hero and the monsters: those three and the litter are read
/// against each other rather than against the place, so a colour that changed by
/// dungeon would make the glyph that matters harder to find.
const Color litterInk = Color(0xFF7FC8B8);

/// What an ore vein or a herb patch is drawn in.
///
/// **Its own constant and deliberately not a [DungeonPalette] field.** That class
/// is terrain-only by its own dartdoc, and for a stated reason: only terrain is
/// themed, because everything a player walks toward is read against the other
/// things they walk toward. A node is one of those, so it keeps one colour in
/// every dungeon.
///
/// A clear step darker than [litterInk] and a clear step lighter than every
/// floor tint, measured with the hue thrown away — the author is deuteranomalous,
/// so a colour that separated only by hue would separate by nothing. The glyphs
/// `*` and `"` carry the real signal either way, and they are outside every other
/// glyph set the game draws.
const Color nodeInk = Color(0xFFA87BC0);

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

/// Draws the crawl: terrain, then nodes, then litter, then monsters, then the
/// hero.
///
/// **Nodes go between the terrain and the litter**, which is the order of what
/// matters. A vein is part of the place — it is not going anywhere — so an item
/// dropped on top of one has to be the glyph the player sees, and a monster
/// standing on either has to be the glyph above both.
class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.state,
    required this.geometry,
    required this.palette,
  });

  final GameViewState state;
  final GridGeometry geometry;
  final DungeonPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in glyphPlan(
      state.game,
      palette,
      markedIds: state.armedTargets,
    )) {
      _paintCell(canvas, cell);
    }
  }

  void _paintCell(Canvas canvas, GlyphCell cell) {
    final origin = geometry.topLeftOf(cell.position.x, cell.position.y);
    if (cell.marked) {
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx,
          origin.dy,
          geometry.cellSize,
          geometry.cellSize,
        ).deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = cell.ink,
      );
    }
    final painter = TextPainter(
      text: TextSpan(
        text: cell.glyph,
        style: TextStyle(
          color: cell.ink.withValues(alpha: cell.opacity),
          fontSize: geometry.cellSize,
          fontFamily: 'monospace',
          height: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      origin +
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
