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
  static const _hero = Color(0xFFFFFFFF);
  static const _ghoul = Color(0xFFD9A227);
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
        final tile = game.map.tileAt(position);
        final isWall = tile == Tile.wall;
        _paintGlyph(
          canvas,
          position,
          isWall ? '#' : '.',
          isWall ? _wall : _floor,
          visible,
        );
      }
    }
    for (final monster in game.monsters) {
      if (!game.visible.contains(monster.position)) continue;
      _paintGlyph(canvas, monster.position, monster.glyph, _ghoul, true);
    }
    _paintGlyph(canvas, game.hero.position, game.hero.glyph, _hero, true);
  }

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
