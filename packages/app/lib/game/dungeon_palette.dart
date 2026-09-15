import 'package:flutter/material.dart' show Color;
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

enum RegionMaterial { cryptStone, seaCaveStone, ruinedKeepMasonry, lowlandRoad }

class DungeonPalette {
  const DungeonPalette({
    required this.wall,
    required this.floor,
    required this.stairs,
    required this.themeSalt,
    required this.material,
    required this.rememberedStone,
    required this.visibleStone,
    required this.edgeInk,
    required this.detailInk,
    required this.lightInk,
    required this.maxLightLift,
    required this.maxTintMix,
  });

  static const DungeonPalette crypt = DungeonPalette(
    wall: Color(0xFFB9BEC6),
    floor: Color(0xFF5B6270),
    stairs: Color(0xFFE8ECF2),
    themeSalt: 0x0C7,
    material: RegionMaterial.cryptStone,
    rememberedStone: Color(0xFF1A1E20),
    visibleStone: Color(0xFF292A27),
    edgeInk: Color(0xFF48463F),
    detailInk: Color(0xFFD4B77B),
    lightInk: Color(0xFFE8C58A),
    maxLightLift: 0.30,
    maxTintMix: 0.12,
  );

  static const DungeonPalette seaCave = DungeonPalette(
    wall: Color(0xFF9FC2C6),
    floor: Color(0xFF44575E),
    stairs: Color(0xFFE4F1F2),
    themeSalt: 0x5EA,
    material: RegionMaterial.seaCaveStone,
    rememberedStone: Color(0xFF161E21),
    visibleStone: Color(0xFF263236),
    edgeInk: Color(0xFF56676A),
    detailInk: Color(0xFF91B2B5),
    lightInk: Color(0xFFB9D7D8),
    maxLightLift: 0.26,
    maxTintMix: 0.10,
  );

  static const DungeonPalette ruinedKeep = DungeonPalette(
    wall: Color(0xFFC8B79C),
    floor: Color(0xFF64594A),
    stairs: Color(0xFFF2EDE2),
    themeSalt: 0x10E,
    material: RegionMaterial.ruinedKeepMasonry,
    rememberedStone: Color(0xFF201B18),
    visibleStone: Color(0xFF332B26),
    edgeInk: Color(0xFF6C5A49),
    detailInk: Color(0xFFB78C65),
    lightInk: Color(0xFFE0B77D),
    maxLightLift: 0.28,
    maxTintMix: 0.11,
  );

  static const DungeonPalette lowlandRoad = DungeonPalette(
    wall: Color(0xFFB9B6A9),
    floor: Color(0xFF57564F),
    stairs: Color(0xFFE7E3D5),
    themeSalt: 0x10A,
    material: RegionMaterial.lowlandRoad,
    rememberedStone: Color(0xFF1B1C19),
    visibleStone: Color(0xFF2D2C26),
    edgeInk: Color(0xFF5B584C),
    detailInk: Color(0xFFA6A08B),
    lightInk: Color(0xFFD8CCA2),
    maxLightLift: 0.22,
    maxTintMix: 0.06,
  );

  final Color wall;
  final Color floor;
  final Color stairs;
  final int themeSalt;
  final RegionMaterial material;
  final Color rememberedStone;
  final Color visibleStone;
  final Color edgeInk;
  final Color detailInk;
  final Color lightInk;
  final double maxLightLift;
  final double maxTintMix;
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
  throw ArgumentError.value(route, 'route', 'has no regional material');
}

const Color litterInk = Color(0xFF7FC8B8);
const Color nodeInk = Color(0xFFA87BC0);
