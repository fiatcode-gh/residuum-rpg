import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/art/art_assets.dart';
import 'package:residuum_app/game/dungeon_material.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_render_style.dart';
import 'package:residuum_core/core.dart';

MaterialCell _cell(Position position, MaterialTileKind kind) => MaterialCell(
  position: position,
  kind: kind,
  knowledge: MaterialKnowledge.visible,
);

void main() {
  const dungeonPalettes = [
    DungeonPalette.crypt,
    DungeonPalette.seaCave,
    DungeonPalette.ruinedKeep,
  ];

  group('dungeon surface treatment', () {
    test('walls are darker and receive less local light than floors', () {
      for (final palette in dungeonPalettes) {
        final floor = dungeonSurfaceTreatment(palette, MaterialSurface.floor);
        final wall = dungeonSurfaceTreatment(palette, MaterialSurface.wall);

        expect(wall.foundationDarken, greaterThan(floor.foundationDarken));
        expect(wall.lightLiftScale, lessThan(floor.lightLiftScale));
        expect(wall.tintScale, lessThan(floor.tintScale));
        expect(wall.authoredScale, 0.32);
        expect(wall.authoredStrength, 0.55);
        expect(floor.authoredScale, 0.32);
        expect(floor.authoredStrength, 0.55);

        expect(wall.boundaryShadow, greaterThan(0));
      }
    });

    test(
      'road keeps the Unit 10 compatibility treatment and no authored art',
      () {
        final palette = DungeonPalette.lowlandRoad;
        for (final surface in MaterialSurface.values) {
          final treatment = dungeonSurfaceTreatment(palette, surface);
          expect(treatment.foundationDarken, 0.0);
          expect(treatment.lightLiftScale, 1.0);
          expect(treatment.tintScale, 1.0);
          expect(treatment.authoredScale, 0.5);
          expect(treatment.authoredStrength, 1.0);
          expect(treatment.boundaryShadow, 0.0);
          expect(MaterialArt.of(palette.material, surface), isNull);
        }
      },
    );

    test('surface treatments compare by value', () {
      final floor = dungeonSurfaceTreatment(
        DungeonPalette.crypt,
        MaterialSurface.floor,
      );
      final same = dungeonSurfaceTreatment(
        DungeonPalette.crypt,
        MaterialSurface.floor,
      );
      expect(floor, same);
      expect(floor.hashCode, same.hashCode);
    });
  });

  group('decoration placement', () {
    const position = Position(4, 4);
    const visibleFloor = MaterialCell(
      position: position,
      kind: MaterialTileKind.floor,
      knowledge: MaterialKnowledge.visible,
    );
    const rubble = OverlayKind.rubbleSmall;
    const mark = MaterialMark(
      grit: 0.8,
      speck: true,
      crack: 0,
      edge: 0,
      pattern: 0,
    );
    const openNeighbours = KnownMaterialNeighbours(
      north: null,
      east: null,
      south: null,
      west: null,
    );
    const openFaces = DungeonWallFaces.none();

    test('equal inputs compare by value and salts stay presentation-only', () {
      final first = decorationPlacement(
        cell: visibleFloor,
        mark: mark,
        candidate: rubble,
        palette: DungeonPalette.crypt,
        neighbours: openNeighbours,
        faces: openFaces,
      );
      final second = decorationPlacement(
        cell: visibleFloor,
        mark: mark,
        candidate: rubble,
        palette: DungeonPalette.crypt,
        neighbours: openNeighbours,
        faces: openFaces,
      );
      final shiftedPalette = DungeonPalette(
        wall: DungeonPalette.crypt.wall,
        floor: DungeonPalette.crypt.floor,
        stairs: DungeonPalette.crypt.stairs,
        themeSalt: DungeonPalette.crypt.themeSalt ^ 0x2A2A,
        material: DungeonPalette.crypt.material,
        rememberedStone: DungeonPalette.crypt.rememberedStone,
        visibleStone: DungeonPalette.crypt.visibleStone,
        edgeInk: DungeonPalette.crypt.edgeInk,
        detailInk: DungeonPalette.crypt.detailInk,
        lightInk: DungeonPalette.crypt.lightInk,
        maxLightLift: DungeonPalette.crypt.maxLightLift,
        maxTintMix: DungeonPalette.crypt.maxTintMix,
      );
      final saltChanged = decorationPlacement(
        cell: visibleFloor,
        mark: mark,
        candidate: rubble,
        palette: shiftedPalette,
        neighbours: openNeighbours,
        faces: openFaces,
      );
      const shiftedCell = MaterialCell(
        position: Position(5, 4),
        kind: MaterialTileKind.floor,
        knowledge: MaterialKnowledge.visible,
      );
      final positionChanged = decorationPlacement(
        cell: shiftedCell,
        mark: mark,
        candidate: rubble,
        palette: DungeonPalette.crypt,
        neighbours: openNeighbours,
        faces: openFaces,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(saltChanged.destination.left, inInclusiveRange(0.0, 1.0));
      expect(saltChanged.destination.top, inInclusiveRange(0.0, 1.0));
      expect(positionChanged.destination.left, inInclusiveRange(0.0, 1.0));
      expect(shiftedCell.kind, visibleFloor.kind);
      expect(shiftedCell.knowledge, visibleFloor.knowledge);
    });

    test('remembered, road, and ineligible inputs suppress drawing', () {
      final remembered = decorationPlacement(
        cell: const MaterialCell(
          position: position,
          kind: MaterialTileKind.floor,
          knowledge: MaterialKnowledge.remembered,
        ),
        mark: mark,
        candidate: rubble,
        palette: DungeonPalette.crypt,
        neighbours: openNeighbours,
        faces: openFaces,
      );
      final road = decorationPlacement(
        cell: visibleFloor,
        mark: mark,
        candidate: rubble,
        palette: DungeonPalette.lowlandRoad,
        neighbours: openNeighbours,
        faces: openFaces,
      );
      final noCandidate = decorationPlacement(
        cell: visibleFloor,
        mark: mark,
        candidate: null,
        palette: DungeonPalette.crypt,
        neighbours: openNeighbours,
        faces: openFaces,
      );
      final floorCrack = decorationPlacement(
        cell: visibleFloor,
        mark: mark,
        candidate: OverlayKind.crackA,
        palette: DungeonPalette.crypt,
        neighbours: openNeighbours,
        faces: openFaces,
      );

      for (final placement in [remembered, road, noCandidate, floorCrack]) {
        expect(placement.draw, isFalse);
        expect(placement.destination, ui.Rect.zero);
        expect(placement.quarterTurns, 0);
        expect(placement.mirrorX, isFalse);
        expect(placement.opacity, 0);
        expect(placement.groundShadowOpacity, 0);
      }
    });

    test('canonical fixture is sparse and prefers anchored floors', () {
      final anchored = <DungeonDecorationPlacement>[];
      final open = <DungeonDecorationPlacement>[];
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final cell = MaterialCell(
            position: Position(x, y),
            kind: MaterialTileKind.floor,
            knowledge: MaterialKnowledge.visible,
          );
          final placement = decorationPlacement(
            cell: cell,
            mark: mark,
            candidate: rubble,
            palette: DungeonPalette.crypt,
            neighbours: const KnownMaterialNeighbours(
              north: MaterialTileKind.wall,
              east: null,
              south: null,
              west: null,
            ),
            faces: openFaces,
          );
          anchored.add(placement);
          final openPlacement = decorationPlacement(
            cell: cell,
            mark: mark,
            candidate: rubble,
            palette: DungeonPalette.crypt,
            neighbours: openNeighbours,
            faces: openFaces,
          );
          open.add(openPlacement);
        }
      }
      final anchoredDraws = anchored
          .where((placement) => placement.draw)
          .length;
      final openDraws = open.where((placement) => placement.draw).length;

      expect(anchoredDraws, greaterThan(0));
      expect(anchoredDraws + openDraws, lessThanOrEqualTo(32 * 32 ~/ 4));
      expect(
        anchoredDraws / anchored.length,
        greaterThan(openDraws / open.length),
      );
    });
  });

  group('known material neighbours', () {
    test('retains known kinds and leaves absent neighbours null', () {
      const center = Position(3, 3);
      final known = {
        center: _cell(center, MaterialTileKind.wall),
        const Position(3, 2): _cell(
          const Position(3, 2),
          MaterialTileKind.wall,
        ),
        const Position(4, 3): _cell(
          const Position(4, 3),
          MaterialTileKind.stairsDown,
        ),
      };

      final neighbours = knownMaterialNeighbours(center, known);

      expect(neighbours.north, MaterialTileKind.wall);
      expect(neighbours.east, MaterialTileKind.stairsDown);
      expect(neighbours.south, isNull);
      expect(neighbours.west, isNull);
    });

    test('only known floor or stair neighbours expose a wall face', () {
      const wall = Position(3, 3);
      const floor = Position(3, 2);
      const knownWall = Position(4, 3);
      const unknown = Position(3, 4);
      final current = _cell(wall, MaterialTileKind.wall);

      final faces = dungeonWallFaces(
        current,
        KnownMaterialNeighbours(
          north: MaterialTileKind.floor,
          east: MaterialTileKind.wall,
          south: null,
          west: MaterialTileKind.stairsUp,
        ),
      );
      expect(faces.north, isTrue, reason: '$floor is exposed');
      expect(faces.east, isFalse, reason: '$knownWall is covered');
      expect(faces.south, isFalse, reason: '$unknown is absent');
      expect(faces.west, isTrue);

      final nonWallFaces = dungeonWallFaces(
        _cell(wall, MaterialTileKind.floor),
        const KnownMaterialNeighbours(
          north: MaterialTileKind.floor,
          east: MaterialTileKind.wall,
          south: MaterialTileKind.stairsDown,
          west: MaterialTileKind.stairsUp,
        ),
      );
      expect(nonWallFaces, const DungeonWallFaces.none());
    });
  });
}
