import 'package:flutter/material.dart' show Color;
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

class DungeonPalette {
  const DungeonPalette({
    required this.wall,
    required this.floor,
    required this.stairs,
  });

  static const DungeonPalette crypt = DungeonPalette(
    wall: Color(0xFFB9BEC6),
    floor: Color(0xFF5B6270),
    stairs: Color(0xFFE8ECF2),
  );

  static const DungeonPalette seaCave = DungeonPalette(
    wall: Color(0xFF9FC2C6),
    floor: Color(0xFF44575E),
    stairs: Color(0xFFE4F1F2),
  );

  static const DungeonPalette ruinedKeep = DungeonPalette(
    wall: Color(0xFFC8B79C),
    floor: Color(0xFF64594A),
    stairs: Color(0xFFF2EDE2),
  );

  static const DungeonPalette lowlandRoad = DungeonPalette(
    wall: Color(0xFFB9B6A9),
    floor: Color(0xFF57564F),
    stairs: Color(0xFFE7E3D5),
  );

  final Color wall;
  final Color floor;
  final Color stairs;
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

const Color litterInk = Color(0xFF7FC8B8);
const Color nodeInk = Color(0xFFA87BC0);
