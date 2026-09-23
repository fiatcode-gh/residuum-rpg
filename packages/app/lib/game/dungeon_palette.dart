import 'package:flutter/material.dart' show Color;
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../style/tokens.dart' show crawlCold;

class DungeonPalette {
  const DungeonPalette({required this.fog});

  static const DungeonPalette crypt = DungeonPalette(fog: Color(0xFF1A2430));

  static const DungeonPalette seaCave = DungeonPalette(fog: Color(0xFF152A3A));

  static const DungeonPalette ruinedKeep = DungeonPalette(
    fog: Color(0xFF221F2A),
  );

  static const DungeonPalette lowlandRoad = DungeonPalette(
    fog: Color(0xFF1D2327),
  );

  /// The region's fog tint (PLAN.md G5). Terrain ink no longer varies by
  /// region — only the backdrop's fog hue distinguishes one place from
  /// another now (PLAN.md G3).
  final Color fog;
}

DungeonPalette paletteForDungeon(NodeId node) {
  if (node == cryptNode) return DungeonPalette.crypt;
  if (node == seaCave) return DungeonPalette.seaCave;
  if (node == ruinedKeep) return DungeonPalette.ruinedKeep;
  throw ArgumentError.value(node, 'node', 'has no dungeon palette');
}

DungeonPalette paletteForRoad(Route route) {
  if (route.joins(northgate, seaCave)) return DungeonPalette.seaCave;
  if (route.joins(northgate, ruinedKeep)) return DungeonPalette.ruinedKeep;
  if (route.joins(stonebridge, cryptNode) ||
      route.joins(stonebridge, northgate) ||
      route.joins(northgate, cryptNode)) {
    return DungeonPalette.lowlandRoad;
  }
  throw ArgumentError.value(route, 'route', 'has no regional palette');
}

/// Warm stone terrain ink (PLAN.md G3), identical in every region including
/// road fights — the regional difference now lives only in [DungeonPalette]'s
/// fog. `Lit` is the cell's base `ink` (bright, near the hero); `Shade` is
/// its `shade` (dim, at the edge of sight or once only remembered).
const Color stoneWallLit = Color(0xFFDCC08A);
const Color stoneWallShade = Color(0xFF8A7552);
const Color stoneFloorLit = Color(0xFFB39B6C);
const Color stoneFloorShade = Color(0xFF6B5B40);
const Color stoneStairsLit = Color(0xFFFFE3A0);
const Color stoneStairsShade = Color(0xFFB39A6A);

/// The old teal sat next to enemy red — a red-vs-green-adjacent pair. Cold
/// blue carries litter instead.
const Color litterInk = crawlCold;
const Color nodeInk = Color(0xFFA87BC0);
