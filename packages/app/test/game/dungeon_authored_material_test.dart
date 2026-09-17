import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/art/art_assets.dart';
import 'package:residuum_app/art/dungeon_art.dart';
import 'package:residuum_app/game/dungeon_material.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_render_style.dart';
import 'package:residuum_app/game/dungeon_scene_material.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
############
#..........#
#..........#
#..........#
############''';

Actor _heroAt(Position position) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: position,
  hp: 20,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

GameState _game({
  required Set<Position> visible,
  required Set<Position> explored,
  required FloorMap map,
  Position heroPosition = const Position(1, 1),
}) => GameState(
  map: map,
  hero: _heroAt(heroPosition),
  monsters: const [],
  rng: Rng(1),
  lootRng: Rng(2),
  visible: visible,
  explored: explored,
  buildFloor: (depth) => throw StateError('no descent in a paint test'),
);

MaterialPlan _singleCellPlan({
  required DungeonPalette palette,
  required MaterialTileKind kind,
  MaterialMark mark = const MaterialMark(
    grit: 0,
    speck: false,
    crack: 0,
    edge: 0,
    pattern: 0,
  ),
}) {
  const position = Position(1, 1);
  return MaterialPlan(
    cells: [
      MaterialCell(
        position: position,
        kind: kind,
        knowledge: MaterialKnowledge.visible,
      ),
    ],
    marks: {position: mark},
    masonry: const {},
    heroPosition: position,
    palette: palette,
  );
}

/// A visible cell paired with one remembered cell, so the render's mask
/// bounds stay non-empty while the remembered cell stays outside it.
MaterialPlan _twoCellPlan({
  required DungeonPalette palette,
  required Position visiblePosition,
  required MaterialTileKind visibleKind,
  required Position rememberedPosition,
}) {
  const mark = MaterialMark(
    grit: 0,
    speck: false,
    crack: 0,
    edge: 0,
    pattern: 0,
  );
  return MaterialPlan(
    cells: [
      MaterialCell(
        position: visiblePosition,
        kind: visibleKind,
        knowledge: MaterialKnowledge.visible,
      ),
      MaterialCell(
        position: rememberedPosition,
        kind: MaterialTileKind.floor,
        knowledge: MaterialKnowledge.remembered,
      ),
    ],
    marks: {visiblePosition: mark, rememberedPosition: mark},
    masonry: const {},
    heroPosition: visiblePosition,
    palette: palette,
  );
}

Future<ui.Image> _renderMaterial(MaterialComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(dungeonVoid, BlendMode.src);
  component.render(canvas);
  return recorder.endRecording().toImage(12 * 36, 5 * 36);
}

Future<ByteData> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

Future<ByteData> _renderBytes(
  MaterialPlan plan, {
  DungeonArt art = const DungeonArt.none(),
}) async {
  final image = await _renderMaterial(MaterialComponent(plan, art: art));
  try {
    return await _rgba(image);
  } finally {
    image.dispose();
  }
}

Color _pixel(ByteData rgba, int x, int y) {
  final offset = (y * 12 * 36 + x) * 4;
  return Color.fromARGB(
    rgba.getUint8(offset + 3),
    rgba.getUint8(offset),
    rgba.getUint8(offset + 1),
    rgba.getUint8(offset + 2),
  );
}

Uint8List _bytes(ByteData data) =>
    Uint8List.view(data.buffer, data.offsetInBytes, data.lengthInBytes);

int _at(double cell) => (cell * cameraCellSize).round();

/// Two-tone, never uniform: a uniform mid-grey sheet is `softLight`'s
/// identity element and would render byte-identically to no art at all.
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

/// An overlay sheet: opaque white in its top half, fully transparent below.
Future<ui.Image> _overlayImage(int size) {
  final pixels = Uint8List(size * size * 4);
  for (var i = 0; i < size * size; i++) {
    final visible = (i ~/ size) < size ~/ 2;
    pixels[i * 4] = pixels[i * 4 + 1] = pixels[i * 4 + 2] = 0xFF;
    pixels[i * 4 + 3] = visible ? 0xFF : 0x00;
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

/// An asymmetric L-shaped overlay with a transparent remainder. Each
/// quarter-turn/mirror combination therefore produces an observable signature.
Future<ui.Image> _asymmetricOverlayImage(int size) {
  final pixels = Uint8List(size * size * 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final inL =
          (x < size ~/ 5 && y < size * 3 ~/ 4) ||
          (x < size * 3 ~/ 5 && y < size ~/ 5);
      if (inL) {
        final index = (y * size + x) * 4;
        pixels[index] = pixels[index + 1] = pixels[index + 2] = 0xFF;
        pixels[index + 3] = 0xFF;
      }
    }
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

DungeonPalette _cryptWithSalt(int themeSalt) => DungeonPalette(
  wall: DungeonPalette.crypt.wall,
  floor: DungeonPalette.crypt.floor,
  stairs: DungeonPalette.crypt.stairs,
  themeSalt: themeSalt,
  material: DungeonPalette.crypt.material,
  rememberedStone: DungeonPalette.crypt.rememberedStone,
  visibleStone: DungeonPalette.crypt.visibleStone,
  edgeInk: DungeonPalette.crypt.edgeInk,
  detailInk: DungeonPalette.crypt.detailInk,
  lightInk: DungeonPalette.crypt.lightInk,
  maxLightLift: DungeonPalette.crypt.maxLightLift,
  maxTintMix: DungeonPalette.crypt.maxTintMix,
);

String _overlaySignature(
  ByteData base,
  ByteData rendered,
  ui.Rect destination,
) {
  const samples = 12;
  final signature = StringBuffer();
  for (var y = 0; y < samples; y++) {
    for (var x = 0; x < samples; x++) {
      final sampleX =
          (destination.left + (x + 0.5) / samples * destination.width).round();
      final sampleY =
          (destination.top + (y + 0.5) / samples * destination.height).round();
      final delta =
          _pixel(rendered, sampleX, sampleY).computeLuminance() -
          _pixel(base, sampleX, sampleY).computeLuminance();
      signature.write(delta > 0.01 ? '#' : '.');
    }
  }
  return signature.toString();
}

MaterialPlan _crackedWallPlan(DungeonPalette palette) {
  const wall = Position(1, 1);
  const open = Position(1, 2);
  return MaterialPlan(
    cells: const [
      MaterialCell(
        position: wall,
        kind: MaterialTileKind.wall,
        knowledge: MaterialKnowledge.visible,
      ),
      MaterialCell(
        position: open,
        kind: MaterialTileKind.floor,
        knowledge: MaterialKnowledge.visible,
      ),
    ],
    marks: {
      wall: const MaterialMark(
        grit: 0,
        speck: false,
        crack: 0.5,
        edge: 0,
        pattern: 0,
      ),
      open: const MaterialMark(
        grit: 0,
        speck: false,
        crack: 0,
        edge: 0,
        pattern: 0,
      ),
    },
    masonry: const {},
    heroPosition: wall,
    palette: palette,
  );
}

/// A loaded overlay that paints nothing: fully transparent everywhere.
/// Loading it still counts as "an overlay is loaded" — the fact the
/// procedural crack ternary gates on — while never itself being visible, so
/// its render isolates whether the procedural mark was actually replaced.
Future<ui.Image> _transparentOverlayImage(int size) {
  final pixels = Uint8List(size * size * 4);
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

void main() {
  group('authored dungeon materials', () {
    test('authored material changes visible stone', () async {
      // arrange
      final plan = _singleCellPlan(
        palette: DungeonPalette.crypt,
        kind: MaterialTileKind.floor,
      );
      final floorImage = await _twoTone(4);
      final art = DungeonArt(
        surfaces: {MaterialArt.cryptFloor: floorImage},
        overlays: const {},
      );

      // act
      final withArt = await _renderBytes(plan, art: art);
      final withoutArt = await _renderBytes(plan);

      // assert
      expect(
        _pixel(withArt, _at(1.5), _at(1.5)),
        isNot(_pixel(withoutArt, _at(1.5), _at(1.5))),
      );
    });

    test('remembered stays exactly flat under authored art', () async {
      // arrange
      const remembered = Position(3, 1);
      final plan = _twoCellPlan(
        palette: DungeonPalette.crypt,
        visiblePosition: const Position(1, 1),
        visibleKind: MaterialTileKind.floor,
        rememberedPosition: remembered,
      );
      final art = DungeonArt(
        surfaces: {
          MaterialArt.cryptFloor: await _twoTone(4),
          MaterialArt.cryptWall: await _twoTone(4),
        },
        overlays: const {},
      );

      // act
      final rgba = await _renderBytes(plan, art: art);

      // assert
      expect(
        _pixel(rgba, _at(3.5), _at(1.5)),
        DungeonPalette.crypt.rememberedStone,
      );
    });

    test(
      'remembered wall with a known-open neighbor stays strictly base-only',
      () async {
        // arrange
        const remembered = Position(3, 1);
        const knownOpen = Position(3, 2);
        const detail = MaterialMark(
          grit: 1,
          speck: true,
          crack: 1,
          edge: 1,
          pattern: 1,
        );
        const quiet = MaterialMark(
          grit: 0,
          speck: false,
          crack: 0,
          edge: 0,
          pattern: 0,
        );
        final plan = MaterialPlan(
          cells: const [
            MaterialCell(
              position: remembered,
              kind: MaterialTileKind.wall,
              knowledge: MaterialKnowledge.remembered,
            ),
            MaterialCell(
              position: knownOpen,
              kind: MaterialTileKind.floor,
              knowledge: MaterialKnowledge.visible,
            ),
          ],
          marks: {remembered: detail, knownOpen: quiet},
          masonry: const {},
          heroPosition: knownOpen,
          palette: DungeonPalette.crypt,
        );
        final art = DungeonArt(
          surfaces: {
            MaterialArt.cryptFloor: await _twoTone(4),
            MaterialArt.cryptWall: await _twoTone(4),
          },
          overlays: const {},
        );

        // act
        final rgba = await _renderBytes(plan, art: art);

        // assert — the open neighbor deliberately exposes a wall face, while
        // every remembered-wall pixel must remain the flat remembered value.
        for (var x = _at(3); x < _at(4); x++) {
          for (var y = _at(1); y < _at(2); y++) {
            expect(
              _pixel(rgba, x, y),
              DungeonPalette.crypt.rememberedStone,
              reason: 'remembered wall detail leaked at ($x, $y)',
            );
          }
        }
      },
    );

    test('unknown stays void under authored art', () async {
      // arrange
      final plan = _singleCellPlan(
        palette: DungeonPalette.crypt,
        kind: MaterialTileKind.floor,
      );
      final art = DungeonArt(
        surfaces: {
          MaterialArt.cryptFloor: await _twoTone(4),
          MaterialArt.cryptWall: await _twoTone(4),
        },
        overlays: const {},
      );

      // act
      final rgba = await _renderBytes(plan, art: art);

      // assert
      expect(_pixel(rgba, _at(8.5), _at(3.5)), dungeonVoid);
    });

    test('the light still owns brightness', () async {
      // arrange
      const hero = Position(1, 1);
      const near = Position(2, 1);
      const far = Position(9, 1);
      const mark = MaterialMark(
        grit: 0,
        speck: false,
        crack: 0,
        edge: 0,
        pattern: 0,
      );
      final plan = MaterialPlan(
        cells: const [
          MaterialCell(
            position: hero,
            kind: MaterialTileKind.floor,
            knowledge: MaterialKnowledge.visible,
          ),
          MaterialCell(
            position: near,
            kind: MaterialTileKind.floor,
            knowledge: MaterialKnowledge.visible,
          ),
          MaterialCell(
            position: far,
            kind: MaterialTileKind.floor,
            knowledge: MaterialKnowledge.visible,
          ),
        ],
        marks: {hero: mark, near: mark, far: mark},
        masonry: const {},
        heroPosition: hero,
        palette: DungeonPalette.crypt,
      );
      final art = DungeonArt(
        surfaces: {MaterialArt.cryptFloor: await _twoTone(4)},
        overlays: const {},
      );

      // act
      final rgba = await _renderBytes(plan, art: art);
      final nearLuminance = _pixel(rgba, _at(2.5), _at(1.5)).computeLuminance();
      final farLuminance = _pixel(rgba, _at(9.5), _at(1.5)).computeLuminance();

      // assert
      expect(nearLuminance, greaterThan(farLuminance));
    });

    test('identical state renders identically', () async {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final game = _game(map: map, visible: visible, explored: visible);
      final plan = materialPlan(game, DungeonPalette.crypt);
      final art = DungeonArt(
        surfaces: {MaterialArt.cryptFloor: await _twoTone(4)},
        overlays: const {},
      );

      // act
      final first = await _renderBytes(plan, art: art);
      final second = await _renderBytes(plan, art: art);
      final rebuilt = materialPlan(game, DungeonPalette.crypt);
      final third = await _renderBytes(rebuilt, art: art);

      // assert
      expect(_bytes(first), orderedEquals(_bytes(second)));
      expect(_bytes(first), orderedEquals(_bytes(third)));
    });

    test('the road is untouched by authored art', () async {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final game = _game(map: map, visible: visible, explored: visible);
      final plan = materialPlan(game, DungeonPalette.lowlandRoad);
      final floorImage = await _twoTone(4);
      final overlayImg = await _overlayImage(8);
      final fullArt = DungeonArt(
        surfaces: {for (final art in MaterialArt.values) art: floorImage},
        overlays: {for (final art in TerrainOverlayArt.values) art: overlayImg},
      );

      // act
      final withArt = await _renderBytes(plan, art: fullArt);
      final withoutArt = await _renderBytes(plan);

      // assert
      expect(_bytes(withArt), orderedEquals(_bytes(withoutArt)));
    });

    test(
      'an authored overlay replaces its procedural mark, not adds to it',
      () async {
        // arrange
        const position = Position(1, 1);
        const crackedMark = MaterialMark(
          grit: 0,
          speck: false,
          crack: 0.5,
          edge: 0,
          pattern: 0,
        );
        const flatMark = MaterialMark(
          grit: 0,
          speck: false,
          crack: 0,
          edge: 0,
          pattern: 0,
        );
        MaterialPlan planFor(MaterialMark mark) => MaterialPlan(
          cells: const [
            MaterialCell(
              position: position,
              kind: MaterialTileKind.wall,
              knowledge: MaterialKnowledge.visible,
            ),
            MaterialCell(
              position: Position(1, 2),
              kind: MaterialTileKind.floor,
              knowledge: MaterialKnowledge.visible,
            ),
          ],
          marks: {position: mark, const Position(1, 2): flatMark},
          masonry: const {},
          heroPosition: position,
          palette: DungeonPalette.crypt,
        );
        final opaqueArt = DungeonArt(
          surfaces: const {},
          overlays: {TerrainOverlayArt.cryptCrackB: await _overlayImage(8)},
        );
        final transparentArt = DungeonArt(
          surfaces: const {},
          overlays: {
            TerrainOverlayArt.cryptCrackB: await _transparentOverlayImage(8),
          },
        );

        // act - the crack-stroke sample with no art at all, with a loaded but
        // fully transparent overlay, with a visible overlay, and the true
        // flat fill from a mark with no crack gated at all.
        final noArt = await _renderBytes(planFor(crackedMark));
        final transparentOverlay = await _renderBytes(
          planFor(crackedMark),
          art: transparentArt,
        );
        final opaqueOverlay = await _renderBytes(
          planFor(crackedMark),
          art: opaqueArt,
        );
        final flatFill = await _renderBytes(planFor(flatMark));

        // assert - additive drawing would still paint the procedural crack
        // once an overlay is loaded, so a transparent overlay would then
        // match the no-art render instead of the flat fill.
        expect(_pixel(noArt, 54, 51), isNot(_pixel(flatFill, 54, 51)));
        expect(_pixel(transparentOverlay, 54, 51), _pixel(flatFill, 54, 51));
        expect(_pixel(opaqueOverlay, 54, 51), isNot(_pixel(flatFill, 54, 51)));
      },
    );

    test(
      'renders all eight authored overlay rotation and mirror variants',
      () async {
        // arrange — vary only the presentation salt to find every allowed
        // transform for the same known-open wall anchor.
        const wall = Position(1, 1);
        const wallMark = MaterialMark(
          grit: 0,
          speck: false,
          crack: 0.5,
          edge: 0,
          pattern: 0,
        );
        const neighbours = KnownMaterialNeighbours(
          north: null,
          east: null,
          south: MaterialTileKind.floor,
          west: null,
        );
        const faces = DungeonWallFaces(
          north: false,
          east: false,
          south: true,
          west: false,
        );
        final salts = <(int, bool), int>{};
        for (var salt = 0; salt < 100000 && salts.length < 8; salt++) {
          final palette = _cryptWithSalt(salt);
          final placement = decorationPlacement(
            cell: const MaterialCell(
              position: wall,
              kind: MaterialTileKind.wall,
              knowledge: MaterialKnowledge.visible,
            ),
            mark: wallMark,
            candidate: OverlayKind.crackB,
            palette: palette,
            neighbours: neighbours,
            faces: faces,
          );
          if (placement.draw) {
            salts.putIfAbsent((
              placement.quarterTurns,
              placement.mirrorX,
            ), () => salt);
          }
        }
        expect(salts, hasLength(8));

        final overlay = await _asymmetricOverlayImage(16);
        final transparent = await _transparentOverlayImage(16);
        addTearDown(overlay.dispose);
        addTearDown(transparent.dispose);
        final signatures = <String>[];

        // act and assert
        for (final salt in salts.values) {
          final palette = _cryptWithSalt(salt);
          final plan = _crackedWallPlan(palette);
          final base = await _renderBytes(
            plan,
            art: DungeonArt(
              surfaces: const {},
              overlays: {TerrainOverlayArt.cryptCrackB: transparent},
            ),
          );
          final rendered = await _renderBytes(
            plan,
            art: DungeonArt(
              surfaces: const {},
              overlays: {TerrainOverlayArt.cryptCrackB: overlay},
            ),
          );
          final placement = decorationPlacement(
            cell: const MaterialCell(
              position: wall,
              kind: MaterialTileKind.wall,
              knowledge: MaterialKnowledge.visible,
            ),
            mark: wallMark,
            candidate: OverlayKind.crackB,
            palette: palette,
            neighbours: neighbours,
            faces: faces,
          );
          final destination = ui.Rect.fromLTWH(
            _at(1) + placement.destination.left * cameraCellSize,
            _at(1) + placement.destination.top * cameraCellSize,
            placement.destination.width * cameraCellSize,
            placement.destination.height * cameraCellSize,
          );
          final signature = _overlaySignature(base, rendered, destination);
          expect(
            signature.contains('#'),
            isTrue,
            reason: 'transform $placement rendered no authored pixels',
          );
          signatures.add(signature);
          final outsideCellDifferences = <List<int>>[];
          for (var x = 0; x < 12 * 36; x++) {
            for (var y = 0; y < 5 * 36; y++) {
              final insideCell =
                  x >= _at(1) && x < _at(2) && y >= _at(1) && y < _at(2);
              if (!insideCell && _pixel(base, x, y) != _pixel(rendered, x, y)) {
                outsideCellDifferences.add([x, y]);
              }
            }
          }
          expect(
            outsideCellDifferences,
            isEmpty,
            reason: 'transform $placement escaped its owning cell',
          );
        }
        expect(
          signatures.toSet(),
          hasLength(8),
          reason: 'authored transform signatures were not orientation-distinct',
        );
      },
    );

    test('an ungated cell draws no overlay', () async {
      // arrange
      const position = Position(1, 1);
      const mark = MaterialMark(
        grit: 0,
        speck: false,
        crack: 0,
        edge: 0,
        pattern: 0,
      );
      final plan = MaterialPlan(
        cells: const [
          MaterialCell(
            position: position,
            kind: MaterialTileKind.wall,
            knowledge: MaterialKnowledge.visible,
          ),
        ],
        marks: {position: mark},
        masonry: const {},
        heroPosition: position,
        palette: DungeonPalette.crypt,
      );
      final overlayImg = await _overlayImage(8);
      final art = DungeonArt(
        surfaces: const {},
        overlays: {
          TerrainOverlayArt.cryptCrackA: overlayImg,
          TerrainOverlayArt.cryptCrackB: overlayImg,
        },
      );

      // act
      final withArt = await _renderBytes(plan, art: art);
      final withoutArt = await _renderBytes(plan);

      // assert
      expect(_bytes(withArt), orderedEquals(_bytes(withoutArt)));
    });

    test('an overlay never leaves its cell', () async {
      // arrange
      const position = Position(1, 1);
      const mark = MaterialMark(
        grit: 0,
        speck: false,
        crack: 0.5,
        edge: 0,
        pattern: 0,
      );
      final plan = MaterialPlan(
        cells: const [
          MaterialCell(
            position: position,
            kind: MaterialTileKind.wall,
            knowledge: MaterialKnowledge.visible,
          ),
          MaterialCell(
            position: Position(1, 2),
            kind: MaterialTileKind.floor,
            knowledge: MaterialKnowledge.visible,
          ),
        ],
        marks: {
          position: mark,
          const Position(1, 2): const MaterialMark(
            grit: 0,
            speck: false,
            crack: 0,
            edge: 0,
            pattern: 0,
          ),
        },

        masonry: const {},
        heroPosition: position,
        palette: DungeonPalette.crypt,
      );
      final art = DungeonArt(
        surfaces: const {},
        overlays: {TerrainOverlayArt.cryptCrackB: await _overlayImage(8)},
      );

      // act
      final withArt = await _renderBytes(plan, art: art);
      final withoutArt = await _renderBytes(plan);
      final interiorDifferences = [
        for (var x = _at(1) + 1; x < _at(2); x++)
          for (var y = _at(1) + 1; y < _at(2); y++)
            if (_pixel(withArt, x, y) != _pixel(withoutArt, x, y)) [x, y],
      ];
      expect(interiorDifferences, isNotEmpty);

      // assert
      for (final sample in [
        [_at(1) - 1, _at(1.5)],
        [_at(2), _at(1.5)],
        [_at(1.5), _at(1) - 1],
        [_at(1.5), _at(2)],
      ]) {
        expect(
          _pixel(withArt, sample[0], sample[1]),
          _pixel(withoutArt, sample[0], sample[1]),
          reason: 'overlay leaked at $sample',
        );
      }
    });
  });
}
