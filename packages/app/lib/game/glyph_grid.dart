import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'game_bloc.dart';
import 'grid_geometry.dart';

class GlyphGrid extends StatelessWidget {
  const GlyphGrid({required this.state, required this.onTap, super.key});

  final GameViewState state;
  final ValueChanged<Position> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final geometry = GridGeometry.fit(
        size,
        state.game.map.width,
        state.game.map.height,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final position = geometry.positionAt(details.localPosition);
          if (position != null) onTap(position);
        },
        child: CustomPaint(
          size: size,
          painter: _GlyphPainter(state: state, geometry: geometry),
        ),
      );
    },
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.state, required this.geometry});

  static const _wall = Color(0xFFB9BEC6);
  static const _floor = Color(0xFF5B6270);
  static const _stairs = Color(0xFFE8ECF2);
  static const _hero = Color(0xFFFFFFFF);
  static const _monster = Color(0xFFD9A227);
  static const _item = Color(0xFF7FC8B8);
  static const _rememberedOpacity = 0.4;

  final GameViewState state;
  final GridGeometry geometry;

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

  static Color _colourFor(Tile tile) => switch (tile) {
    Tile.wall => _wall,
    Tile.floor => _floor,
    Tile.stairsDown => _stairs,
    Tile.stairsUp => _stairs,
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
      oldDelegate.state != state || oldDelegate.geometry != geometry;
}
