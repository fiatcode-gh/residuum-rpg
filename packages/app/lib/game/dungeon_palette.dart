import 'package:flutter/material.dart';
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

  final Color wall;
  final Color floor;
  final Color stairs;
}

DungeonPalette paletteFor(NodeId? node) {
  if (node == seaCave) return DungeonPalette.seaCave;
  if (node == ruinedKeep) return DungeonPalette.ruinedKeep;
  return DungeonPalette.crypt;
}

const Color litterInk = Color(0xFF7FC8B8);
const Color nodeInk = Color(0xFFA87BC0);
