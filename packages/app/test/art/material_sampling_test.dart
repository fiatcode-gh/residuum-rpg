import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/art/art_assets.dart';
import 'package:residuum_app/art/dungeon_art.dart';
import 'package:residuum_app/game/dungeon_material.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene_material.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

const _flatMark = MaterialMark(
  grit: 0,
  speck: false,
  crack: 0,
  edge: 0,
  pattern: 0,
);

MaterialPlan _plan(List<MaterialCell> cells) => MaterialPlan(
  cells: cells,
  marks: {for (final cell in cells) cell.position: _flatMark},
  masonry: const {},
  heroPosition: cells.first.position,
  palette: DungeonPalette.crypt,
);

Offset _centerOf(Position position) => Offset(
  (position.x + 0.5) * cameraCellSize,
  (position.y + 0.5) * cameraCellSize,
);

/// Two-tone, never uniform: a uniform mid-grey sheet is `softLight`'s
/// identity element and would render byte-identically regardless of phase.
Future<ui.Image> _twoTone(int size) {
  final pixels = Uint8List(size * size * 4);
  for (var i = 0; i < size * size; i++) {
    final value = (i ~/ size) < size ~/ 2 ? 0x40 : 0xC0;
    pixels[i * 4] = pixels[i * 4 + 1] = pixels[i * 4 + 2] = value;
    pixels[i * 4 + 3] = 0xFF;
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    size,
    size,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  return done.future;
}

/// Renders one visible floor cell's authored surface pass under [palette],
/// sampled from [sheet].
Future<ByteData> _renderAuthoredFloor(
  DungeonPalette palette,
  ui.Image sheet, {
  List<MaterialCell> extraCells = const [],
}) async {
  const position = Position(1, 1);
  final cells = [
    const MaterialCell(
      position: position,
      kind: MaterialTileKind.floor,
      knowledge: MaterialKnowledge.visible,
    ),
    ...extraCells,
  ];
  final plan = MaterialPlan(
    cells: cells,
    marks: {for (final cell in cells) cell.position: _flatMark},
    masonry: const {},
    heroPosition: position,
    palette: palette,
  );
  final art = DungeonArt(
    surfaces: {MaterialArt.of(palette.material, MaterialSurface.floor)!: sheet},
    overlays: const {},
  );
  final component = MaterialComponent(plan, art: art);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(dungeonVoid, BlendMode.src);
  component.render(canvas);
  final image = await recorder.endRecording().toImage(
    (3 * cameraCellSize).round(),
    (3 * cameraCellSize).round(),
  );
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  } finally {
    image.dispose();
  }
}

Color _authoredPixel(ByteData rgba, Position position) {
  final width = (3 * cameraCellSize).round();
  final x = ((position.x + 0.5) * cameraCellSize).round();
  final y = ((position.y + 0.5) * cameraCellSize).round();
  final offset = (y * width + x) * 4;
  return Color.fromARGB(
    rgba.getUint8(offset + 3),
    rgba.getUint8(offset),
    rgba.getUint8(offset + 1),
    rgba.getUint8(offset + 2),
  );
}

void main() {
  group('visibleSurfaceMask', () {
    test('follows visibility and kind', () {
      // arrange
      const visibleFloor = Position(1, 1);
      const visibleWall = Position(2, 1);
      const visibleStairs = Position(3, 1);
      const rememberedFloor = Position(4, 1);
      const unexplored = Position(5, 1);
      final plan = _plan([
        const MaterialCell(
          position: visibleFloor,
          kind: MaterialTileKind.floor,
          knowledge: MaterialKnowledge.visible,
        ),
        const MaterialCell(
          position: visibleWall,
          kind: MaterialTileKind.wall,
          knowledge: MaterialKnowledge.visible,
        ),
        const MaterialCell(
          position: visibleStairs,
          kind: MaterialTileKind.stairsDown,
          knowledge: MaterialKnowledge.visible,
        ),
        const MaterialCell(
          position: rememberedFloor,
          kind: MaterialTileKind.floor,
          knowledge: MaterialKnowledge.remembered,
        ),
      ]);

      // act
      final floorMask = visibleSurfaceMask(plan, MaterialSurface.floor);
      final wallMask = visibleSurfaceMask(plan, MaterialSurface.wall);

      // assert
      expect(floorMask.contains(_centerOf(visibleFloor)), isTrue);
      expect(floorMask.contains(_centerOf(visibleStairs)), isTrue);
      expect(floorMask.contains(_centerOf(visibleWall)), isFalse);
      expect(floorMask.contains(_centerOf(rememberedFloor)), isFalse);
      expect(floorMask.contains(_centerOf(unexplored)), isFalse);

      expect(wallMask.contains(_centerOf(visibleWall)), isTrue);
      expect(wallMask.contains(_centerOf(visibleFloor)), isFalse);
      expect(wallMask.contains(_centerOf(visibleStairs)), isFalse);
      expect(wallMask.contains(_centerOf(rememberedFloor)), isFalse);
      expect(wallMask.contains(_centerOf(unexplored)), isFalse);
    });
  });

  group('materialPhase', () {
    test('the same inputs give the same phase', () {
      // arrange
      const position = Position(4, 7);

      // act
      final repeated = materialPhase(position, 0x123, 2);
      final saltChanged = materialPhase(position, 0x456, 2);
      final extraChanged = materialPhase(position, 0x123, 3);

      // assert
      expect(materialPhase(position, 0x123, 2), repeated);
      expect(saltChanged, isNot(repeated));
      expect(extraChanged, isNot(repeated));
      expect(repeated, inInclusiveRange(0.0, 1.0));
    });

    test('a distinct theme salt samples a distinct phase', () async {
      // arrange - every field but themeSalt is copied from crypt, so a
      // difference in the render can only come from the phase salt reaching
      // _texturePhase, not from a difference in colour or material.
      final shiftedSalt = DungeonPalette(
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
      final sheet = await _twoTone(4);
      const position = Position(1, 1);

      // act
      final baseline = await _renderAuthoredFloor(DungeonPalette.crypt, sheet);
      final shifted = await _renderAuthoredFloor(shiftedSalt, sheet);

      // assert
      expect(
        _authoredPixel(shifted, position),
        isNot(_authoredPixel(baseline, position)),
      );
    });
    test(
      'world-space samples do not depend on adjacent cell membership',
      () async {
        final sheet = await _twoTone(4);
        const adjacent = MaterialCell(
          position: Position(2, 1),
          kind: MaterialTileKind.floor,
          knowledge: MaterialKnowledge.visible,
        );

        final alone = await _renderAuthoredFloor(DungeonPalette.crypt, sheet);
        final withAdjacent = await _renderAuthoredFloor(
          DungeonPalette.crypt,
          sheet,
          extraCells: [adjacent],
        );

        expect(
          _authoredPixel(withAdjacent, const Position(1, 1)),
          _authoredPixel(alone, const Position(1, 1)),
        );
      },
    );
  });
}
