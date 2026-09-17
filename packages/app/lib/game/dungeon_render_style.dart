import 'dart:ui' show Rect;

import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';

import 'dungeon_material.dart';
import 'dungeon_palette.dart';

/// Presentation-only response multipliers for one dungeon material surface.
class DungeonSurfaceTreatment {
  const DungeonSurfaceTreatment({
    required this.foundationDarken,
    required this.lightLiftScale,
    required this.tintScale,
    required this.authoredScale,
    required this.authoredStrength,
    required this.boundaryShadow,
  });

  final double foundationDarken;
  final double lightLiftScale;
  final double tintScale;
  final double authoredScale;
  final double authoredStrength;
  final double boundaryShadow;

  @override
  bool operator ==(Object other) =>
      other is DungeonSurfaceTreatment &&
      other.foundationDarken == foundationDarken &&
      other.lightLiftScale == lightLiftScale &&
      other.tintScale == tintScale &&
      other.authoredScale == authoredScale &&
      other.authoredStrength == authoredStrength &&
      other.boundaryShadow == boundaryShadow;

  @override
  int get hashCode => Object.hash(
    foundationDarken,
    lightLiftScale,
    tintScale,
    authoredScale,
    authoredStrength,
    boundaryShadow,
  );
}

/// A prepared, presentation-only placement for one authored crack or rubble
/// overlay. Coordinates are normalized to the owning cell.
class DungeonDecorationPlacement {
  const DungeonDecorationPlacement({
    required this.draw,
    required this.destination,
    required this.quarterTurns,
    required this.mirrorX,
    required this.opacity,
    required this.groundShadowOpacity,
  });

  final bool draw;
  final Rect destination;
  final int quarterTurns;
  final bool mirrorX;
  final double opacity;
  final double groundShadowOpacity;

  @override
  bool operator ==(Object other) =>
      other is DungeonDecorationPlacement &&
      other.draw == draw &&
      other.destination == destination &&
      other.quarterTurns == quarterTurns &&
      other.mirrorX == mirrorX &&
      other.opacity == opacity &&
      other.groundShadowOpacity == groundShadowOpacity;

  @override
  int get hashCode => Object.hash(
    draw,
    destination,
    quarterTurns,
    mirrorX,
    opacity,
    groundShadowOpacity,
  );
}

const _suppressedDecorationPlacement = DungeonDecorationPlacement(
  draw: false,
  destination: Rect.zero,
  quarterTurns: 0,
  mirrorX: false,
  opacity: 0,
  groundShadowOpacity: 0,
);

/// Chooses one deterministic, cell-contained authored decoration placement.
///
/// This consumes only the known material projection and presentation facts.
/// It deliberately does not select an overlay or inspect any gameplay state.
DungeonDecorationPlacement decorationPlacement({
  required MaterialCell cell,
  required MaterialMark mark,
  required OverlayKind? candidate,
  required DungeonPalette palette,
  required KnownMaterialNeighbours neighbours,
  required DungeonWallFaces faces,
}) {
  if (candidate == null ||
      cell.knowledge != MaterialKnowledge.visible ||
      palette.material == RegionMaterial.lowlandRoad) {
    return _suppressedDecorationPlacement;
  }

  final wall = cell.kind == MaterialTileKind.wall;
  final rubble =
      candidate == OverlayKind.rubbleSmall ||
      candidate == OverlayKind.rubbleMedium;
  final crack =
      candidate == OverlayKind.crackA || candidate == OverlayKind.crackB;
  if (wall ? !crack : cell.kind != MaterialTileKind.floor || !rubble) {
    return _suppressedDecorationPlacement;
  }

  bool knownOpen(MaterialTileKind? kind) =>
      kind == MaterialTileKind.floor ||
      kind == MaterialTileKind.stairsDown ||
      kind == MaterialTileKind.stairsUp;
  final wallAnchor =
      (faces.north && knownOpen(neighbours.north)) ||
      (faces.east && knownOpen(neighbours.east)) ||
      (faces.south && knownOpen(neighbours.south)) ||
      (faces.west && knownOpen(neighbours.west));
  if (wall && !wallAnchor) return _suppressedDecorationPlacement;
  final anchored = wall
      ? wallAnchor
      : [
          neighbours.north,
          neighbours.east,
          neighbours.south,
          neighbours.west,
        ].contains(MaterialTileKind.wall);
  final markSalt =
      (mark.grit * 1000).round() ^
      ((mark.crack * 1000).round() << 10) ^
      ((mark.edge * 1000).round() << 20) ^
      ((mark.pattern * 1000).round() << 30);
  final density = materialPhase(
    cell.position,
    palette.themeSalt ^ 0x6A6A,
    candidate.index * 17 + cell.kind.index + markSalt,
  );
  final threshold = wall
      ? 0.18
      : anchored
      ? 0.20
      : 0.03;
  if (density >= threshold) return _suppressedDecorationPlacement;

  final xJitter = materialPhase(
    cell.position,
    palette.themeSalt ^ 0x6B6B,
    candidate.index + markSalt,
  );
  final yJitter = materialPhase(
    cell.position,
    palette.themeSalt ^ 0x6C6C,
    candidate.index + markSalt,
  );
  const width = 0.54;
  const height = 0.54;
  final destination = Rect.fromLTWH(
    (0.23 + (xJitter - 0.5) * 0.08).clamp(0.0, 1.0 - width),
    (0.23 + (yJitter - 0.5) * 0.08).clamp(0.0, 1.0 - height),
    width,
    height,
  );
  final opacity =
      0.35 +
      materialPhase(
            cell.position,
            palette.themeSalt ^ 0x6D6D,
            candidate.index + markSalt,
          ) *
          0.25;
  final quarterTurns =
      ((materialPhase(
                    cell.position,
                    palette.themeSalt ^ 0x6E6E,
                    candidate.index + markSalt,
                  ) *
                  4)
              .floor())
          .clamp(0, 3)
          .toInt();
  final mirrorX =
      materialPhase(
        cell.position,
        palette.themeSalt ^ 0x6F6F,
        candidate.index + markSalt,
      ) >=
      0.5;
  return DungeonDecorationPlacement(
    draw: true,
    destination: destination,
    quarterTurns: quarterTurns,
    mirrorX: mirrorX,
    opacity: opacity,
    groundShadowOpacity: anchored && !wall ? 0.08 : 0,
  );
}

DungeonSurfaceTreatment dungeonSurfaceTreatment(
  DungeonPalette palette,
  MaterialSurface surface,
) {
  if (palette.material == RegionMaterial.lowlandRoad) {
    return const DungeonSurfaceTreatment(
      foundationDarken: 0,
      lightLiftScale: 1,
      tintScale: 1,
      authoredScale: 0.5,
      authoredStrength: 1,
      boundaryShadow: 0,
    );
  }
  return switch (surface) {
    MaterialSurface.floor => const DungeonSurfaceTreatment(
      foundationDarken: 0,
      lightLiftScale: 1,
      tintScale: 1,
      authoredScale: 0.32,
      authoredStrength: 0.55,
      boundaryShadow: 0,
    ),
    MaterialSurface.wall => const DungeonSurfaceTreatment(
      foundationDarken: 0.24,
      lightLiftScale: 0.42,
      tintScale: 0.55,
      authoredScale: 0.32,
      authoredStrength: 0.55,
      boundaryShadow: 0.22,
    ),
  };
}

/// The four known orthogonal material kinds around a prepared cell.
class KnownMaterialNeighbours {
  const KnownMaterialNeighbours({
    required this.north,
    required this.east,
    required this.south,
    required this.west,
  });

  final MaterialTileKind? north;
  final MaterialTileKind? east;
  final MaterialTileKind? south;
  final MaterialTileKind? west;

  @override
  bool operator ==(Object other) =>
      other is KnownMaterialNeighbours &&
      other.north == north &&
      other.east == east &&
      other.south == south &&
      other.west == west;

  @override
  int get hashCode => Object.hash(north, east, south, west);
}

KnownMaterialNeighbours knownMaterialNeighbours(
  Position position,
  Map<Position, MaterialCell> knownCells,
) => KnownMaterialNeighbours(
  north: knownCells[position.step(Direction.north)]?.kind,
  east: knownCells[position.step(Direction.east)]?.kind,
  south: knownCells[position.step(Direction.south)]?.kind,
  west: knownCells[position.step(Direction.west)]?.kind,
);

/// Which known floor/stair boundaries are exposed on a wall cell.
class DungeonWallFaces {
  const DungeonWallFaces({
    required this.north,
    required this.east,
    required this.south,
    required this.west,
  });

  const DungeonWallFaces.none()
    : north = false,
      east = false,
      south = false,
      west = false;

  final bool north;
  final bool east;
  final bool south;
  final bool west;

  bool get hasAny => north || east || south || west;

  @override
  bool operator ==(Object other) =>
      other is DungeonWallFaces &&
      other.north == north &&
      other.east == east &&
      other.south == south &&
      other.west == west;

  @override
  int get hashCode => Object.hash(north, east, south, west);
}

DungeonWallFaces dungeonWallFaces(
  MaterialCell cell,
  KnownMaterialNeighbours neighbours,
) {
  if (cell.kind != MaterialTileKind.wall) return const DungeonWallFaces.none();
  bool exposed(MaterialTileKind? kind) =>
      kind == MaterialTileKind.floor ||
      kind == MaterialTileKind.stairsDown ||
      kind == MaterialTileKind.stairsUp;
  return DungeonWallFaces(
    north: exposed(neighbours.north),
    east: exposed(neighbours.east),
    south: exposed(neighbours.south),
    west: exposed(neighbours.west),
  );
}
