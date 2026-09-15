import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:residuum_app/game/dungeon_material.dart';
import 'package:residuum_app/game/dungeon_scene_material.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
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

MaterialPlan _plan(GameState game) => materialPlan(game, DungeonPalette.crypt);
MaterialCellPaint _paint(MaterialPlan plan, MaterialCell cell) =>
    materialCellPaint(
      cell,
      palette: plan.palette,
      masonry: plan.masonryAt(cell.position),
    );

Future<ByteData> _renderBytes(MaterialPlan plan) async {
  final image = await _renderMaterial(MaterialComponent(plan));
  try {
    return await _rgba(image);
  } finally {
    image.dispose();
  }
}

Future<ui.Image> _renderMaterial(MaterialComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(dungeonVoid, BlendMode.src);
  component.render(canvas);
  return recorder.endRecording().toImage(12 * 36, 5 * 36);
}

Future<ByteData> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

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

MaterialPlan _singleCellPlan({
  required DungeonPalette palette,
  required MaterialTileKind kind,
  double pattern = 0,
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
    marks: {
      position: MaterialMark(
        grit: 0,
        speck: false,
        crack: 0,
        edge: 0,
        pattern: pattern,
      ),
    },
    masonry: const {},
    heroPosition: position,
    palette: palette,
  );
}

int _channel(ByteData rgba, int x, int y, int channel) =>
    rgba.getUint8((y * 12 * 36 + x) * 4 + channel);

int _at(double cell) => (cell * cameraCellSize).round();
double _value(Color colour) =>
    0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b;

void main() {
  group('the material paint decisions', () {
    test('paint remembered geometry flat, dark, and unlit', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      const remembered = Position(9, 2);
      final plan = _plan(
        _game(visible: visible, explored: {...visible, remembered}, map: map),
      );

      // act
      final paint = _paint(plan, plan.cellAt(remembered)!);

      expect(paint.fill, DungeonPalette.crypt.rememberedStone);
      expect(
        paint.fill,
        isNot(_paint(plan, plan.cellAt(const Position(2, 1))!).fill),
      );
    });

    test('keep a neutral visible stone foundation beneath local light', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final plan = _plan(_game(visible: visible, explored: visible, map: map));

      // act — these same floor cells receive different local-light amounts.
      final atHero = _paint(plan, plan.cellAt(const Position(1, 1))!);
      final far = _paint(plan, plan.cellAt(const Position(1, 3))!);

      // assert — a tile must not encode the local-light gradient in its solid
      // fill, or every logical cell becomes a visible lighting step. The
      // renderer applies one mask-clipped continuous gradient over this base.
      expect(atHero.fill, far.fill);
    });

    test('clip presentation light to authoritative visible material', () {
      // arrange — remembered terrain remains known but must never enter the
      // local-light mask, and unexplored space has no material at all.
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      const remembered = Position(9, 2);
      final plan = _plan(
        _game(visible: visible, explored: {...visible, remembered}, map: map),
      );

      // act
      final mask = visibleMaterialMask(plan);

      Offset centerOf(Position position) => Offset(
        (position.x + 0.5) * cameraCellSize,
        (position.y + 0.5) * cameraCellSize,
      );

      // assert — the mask follows visibility, not the broader known set, so
      // neither remembered nor unknown geometry can receive or reveal light.
      expect(mask.contains(centerOf(const Position(2, 1))), isTrue);
      expect(mask.contains(centerOf(remembered)), isFalse);
      expect(mask.contains(centerOf(const Position(11, 1))), isFalse);
    });

    test(
      'render visible light continuously inside its material mask',
      () async {
        // arrange — two visible neighbouring floors, a remembered floor, and an
        // unknown floor all sit in one row of the same real render pass.
        final map = FloorMap.parse(_arena);
        const first = Position(1, 1);
        const second = Position(2, 1);
        const remembered = Position(4, 1);
        final plan = _plan(
          _game(
            map: map,
            visible: {first, second},
            explored: {first, second, remembered},
          ),
        );
        final image = await _renderMaterial(MaterialComponent(plan));
        addTearDown(image.dispose);
        final rgba = await _rgba(image);

        // act
        final boundaryY = _at(1.94);
        final beforeBoundaryX = _at(2) - 1;
        final afterBoundaryX = _at(2);
        final lit = _pixel(rgba, _at(1.5), boundaryY);
        final rememberedPixel = _pixel(rgba, _at(4.5), boundaryY);
        final unknown = _pixel(rgba, _at(5.5), boundaryY);

        // assert — local lift crosses the logical boundary without a tile
        // step; remembered material is outside the mask and unknown remains
        // void.
        for (final channel in [0, 1, 2]) {
          expect(
            (_channel(rgba, beforeBoundaryX, boundaryY, channel) -
                    _channel(rgba, afterBoundaryX, boundaryY, channel))
                .abs(),
            lessThanOrEqualTo(1),
          );
        }
        expect(
          lit.computeLuminance(),
          greaterThan(rememberedPixel.computeLuminance()),
        );
        expect(unknown, dungeonVoid);
      },
    );

    test(
      'render remembered material exactly unlit at every light distance',
      () async {
        const visible = Position(1, 1);
        const remembered = Position(3, 1);
        MaterialPlan planFor(Position heroPosition) => MaterialPlan(
          cells: [
            MaterialCell(
              position: visible,
              kind: MaterialTileKind.floor,
              knowledge: MaterialKnowledge.visible,
            ),
            MaterialCell(
              position: remembered,
              kind: MaterialTileKind.floor,
              knowledge: MaterialKnowledge.remembered,
            ),
          ],
          marks: {
            visible: MaterialMark(
              grit: 0,
              speck: false,
              crack: 0,
              edge: 0,
              pattern: 0,
            ),
            remembered: MaterialMark(
              grit: 0,
              speck: false,
              crack: 0,
              edge: 0,
              pattern: 0,
            ),
          },
          masonry: {},
          heroPosition: heroPosition,
          palette: DungeonPalette.crypt,
        );

        final nearImage = await _renderMaterial(
          MaterialComponent(planFor(visible)),
        );
        final farImage = await _renderMaterial(
          MaterialComponent(planFor(const Position(5, 1))),
        );
        addTearDown(nearImage.dispose);
        addTearDown(farImage.dispose);

        final near = _pixel(await _rgba(nearImage), _at(3.5), _at(1.5));
        final far = _pixel(await _rgba(farImage), _at(3.5), _at(1.5));

        expect(near, DungeonPalette.crypt.rememberedStone);
        expect(far, DungeonPalette.crypt.rememberedStone);
      },
    );

    test('refresh cached material light only for a new projection', () async {
      // arrange — both plans share the authoritative visible material, while
      // the focus moves from one floor to another.
      final map = FloorMap.parse(_arena);
      const firstHero = Position(1, 1);
      const secondHero = Position(3, 1);
      final known = {firstHero, const Position(2, 1), secondHero};
      final first = _plan(_game(map: map, visible: known, explored: known));
      final second = _plan(
        _game(
          map: map,
          visible: known,
          explored: known,
          heroPosition: secondHero,
        ),
      );
      final component = MaterialComponent(first);

      // act — pan-only synchronization hands back the identical projection;
      // a real focus update adopts a distinct material plan.
      final firstImage = await _renderMaterial(component);
      addTearDown(firstImage.dispose);
      final firstRgba = await _rgba(firstImage);
      final firstAtOldFocus = _pixel(firstRgba, _at(1.5), _at(1.94));
      component.adopt(first);
      final pannedImage = await _renderMaterial(component);
      addTearDown(pannedImage.dispose);
      final pannedRgba = await _rgba(pannedImage);
      component.adopt(second);
      final movedImage = await _renderMaterial(component);
      addTearDown(movedImage.dispose);
      final movedRgba = await _rgba(movedImage);

      // assert — cached world-space output stays identical across a pan-only
      // reuse, then the one cached light pass moves with real focus.
      expect(_pixel(pannedRgba, _at(1.5), _at(1.94)), firstAtOldFocus);
      expect(identical(component.plan, second), isTrue);
      expect(
        _pixel(movedRgba, _at(3.5), _at(1.94)).computeLuminance(),
        greaterThan(_pixel(movedRgba, _at(1.5), _at(1.94)).computeLuminance()),
      );
      final sea = materialPlan(
        _game(
          map: map,
          visible: known,
          explored: known,
          heroPosition: secondHero,
        ),
        DungeonPalette.seaCave,
      );
      component.adopt(sea);
      final seaRgba = await _renderBytes(sea);
      expect(identical(component.plan, sea), isTrue);
      expect(_bytes(seaRgba), isNot(orderedEquals(_bytes(movedRgba))));
    });

    test('lift stone value before hue as light grows', () {
      // arrange

      final dim = stoneLitColor(DungeonPalette.crypt, 0.2);
      final bright = stoneLitColor(DungeonPalette.crypt, 0.8);

      // act
      final dimHsl = HSLColor.fromColor(dim);
      final brightHsl = HSLColor.fromColor(bright);
      final valueGain = bright.computeLuminance() - dim.computeLuminance();
      final saturationGain = brightHsl.saturation - dimHsl.saturation;

      // assert — value-first: the luminance step dominates any warmth step
      expect(valueGain, greaterThan(saturationGain));
    });
    test('draw wall structure only on exposed known faces', () async {
      // arrange — two known walls share one internal face. The exterior faces
      // must remain structural, while their shared tile boundary must not
      // become a UI-cell line.
      const left = Position(1, 1);
      const right = Position(2, 1);
      const coveredWest = Position(0, 1);
      final plan = MaterialPlan(
        cells: [
          MaterialCell(
            position: left,
            kind: MaterialTileKind.wall,
            knowledge: MaterialKnowledge.visible,
          ),
          MaterialCell(
            position: right,
            kind: MaterialTileKind.wall,
            knowledge: MaterialKnowledge.visible,
          ),
        ],
        marks: {
          left: MaterialMark(
            grit: 0,
            speck: false,
            crack: 0,
            edge: 1,
            pattern: 0,
          ),
          right: MaterialMark(
            grit: 0,
            speck: false,
            crack: 0,
            edge: 1,
            pattern: 0,
          ),
        },
        masonry: {},
        heroPosition: left,
        palette: DungeonPalette.crypt,
      );
      final coveredWestPlan = MaterialPlan(
        cells: [
          MaterialCell(
            position: coveredWest,
            kind: MaterialTileKind.wall,
            knowledge: MaterialKnowledge.visible,
          ),
          ...plan.cells,
        ],
        marks: {
          coveredWest: MaterialMark(
            grit: 0,
            speck: false,
            crack: 0,
            edge: 1,
            pattern: 0,
          ),
          ...plan.marks,
        },
        masonry: plan.masonry,
        heroPosition: plan.heroPosition,
        palette: DungeonPalette.crypt,
      );
      final image = await _renderMaterial(MaterialComponent(plan));
      addTearDown(image.dispose);
      final rgba = await _rgba(image);
      final coveredWestImage = await _renderMaterial(
        MaterialComponent(coveredWestPlan),
      );
      addTearDown(coveredWestImage.dispose);
      final coveredWestRgba = await _rgba(coveredWestImage);
      final faceY = _at(1.5);
      // act
      final outerFace = _pixel(rgba, _at(1), faceY);
      final wallInterior = _pixel(rgba, _at(1) + 4, faceY);

      // assert — the internal boundary must continue the local gradient,
      // rather than becoming a dark or bright doubled stroke. The exposed
      // west face remains structurally distinct from its wall interior.
      for (final channel in [0, 1, 2]) {
        expect(
          (_channel(rgba, _at(2) - 2, faceY, channel) -
                  _channel(rgba, _at(2) - 1, faceY, channel))
              .abs(),
          lessThanOrEqualTo(1),
        );
        expect(
          (_channel(rgba, _at(2), faceY, channel) -
                  _channel(rgba, _at(2) + 1, faceY, channel))
              .abs(),
          lessThanOrEqualTo(1),
        );
      }
      expect(outerFace, isNot(wallInterior));
      expect(
        outerFace,
        isNot(_pixel(coveredWestRgba, _at(1), faceY)),
        reason: 'the exposed west face needs a structural stroke beyond the same radial light',
      );
    });

    test('keep exposed wall strokes out of adjacent unknown pixels', () async {
      const wall = Position(1, 1);
      final plan = MaterialPlan(
        cells: const [
          MaterialCell(
            position: wall,
            kind: MaterialTileKind.wall,
            knowledge: MaterialKnowledge.visible,
          ),
        ],
        marks: {
          wall: MaterialMark(
            grit: 0,
            speck: false,
            crack: 0,
            edge: 1,
            pattern: 0,
          ),
        },
        masonry: const {},
        heroPosition: wall,
        palette: DungeonPalette.crypt,
      );
      final image = await _renderMaterial(MaterialComponent(plan));
      addTearDown(image.dispose);
      final rgba = await _rgba(image);
      final faceCenter = _at(1.5);

      for (final sample in [
        [_at(1) - 1, faceCenter],
        [_at(2), faceCenter],
        [faceCenter, _at(1) - 1],
        [faceCenter, _at(2)],
      ]) {
        expect(
          _pixel(rgba, sample[0], sample[1]),
          dungeonVoid,
          reason: 'wall stroke leaked into unknown pixel $sample',
        );
      }
    });

    test(
      'crack exposed visible walls occasionally, never masonry or floors',
      () {
        // arrange — a pillared hall: pillars stand alone, so every pillar
        // face is an exposed wall with its own hashed crack decision
        const hall = '''
###############
#.............#
#.#..#..#..#..#
#.............#
#......#..#...#
#.............#
###############''';
        final map = FloorMap.parse(hall);
        final visible = computeFov(map, const Position(1, 1), fovRadius);
        final plan = _plan(
          _game(visible: visible, explored: visible, map: map),
        );

        // act
        final rendered = [
          for (final cell in plan.cells)
            if (_paint(plan, cell).crackStrength > 0 &&
                plan.markAt(cell.position)!.crack > 0)
              cell.position,
        ];
        final floorsCracked = [
          for (final cell in plan.cells)
            if (cell.kind == MaterialTileKind.floor &&
                _paint(plan, cell).crackStrength > 0)
              cell.position,
        ];

        // assert — at least one exposed wall in the hall actually renders a
        // crack (paint gate AND hashed mark agree), and no floor ever does
        expect(rendered, isNotEmpty);
        for (final position in rendered) {
          expect(plan.masonryAt(position), isFalse);
        }
        expect(floorsCracked, isEmpty);
      },
    );

    test(
      'give every wall a structural response before topology selects faces',
      () {
        // arrange
        final map = FloorMap.parse(_arena);
        final visible = computeFov(map, const Position(1, 1), fovRadius);
        final plan = _plan(
          _game(visible: visible, explored: visible, map: map),
        );

        // act
        final massCell = plan.cellAt(const Position(2, 0))!;
        final loneCell = plan.cellAt(const Position(8, 0))!;

        // assert — masonry membership gates cracks, not a whole-tile outline;
        // the cached topology pass alone decides which outer faces render.
        expect(_paint(plan, massCell).edge, greaterThan(0));
        expect(_paint(plan, loneCell).edge, greaterThan(0));
      },
    );

    test('draw nothing for unknown space, not even a silhouette', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final plan = _plan(_game(visible: visible, explored: visible, map: map));

      // act
      final painted = plan.cells.map((cell) => cell.position).toSet();
      final unknown = const [
        Position(9, 0),
        Position(10, 0),
        Position(10, 2),
        Position(11, 1),
      ].where((position) => !painted.contains(position)).toList();

      // assert — the plan simply has no cells there; the renderer paints
      // only from the plan, so unknown space is untouched void
      expect(unknown.length, 4);
      expect(
        plan.cells.any((cell) => unknown.contains(cell.position)),
        isFalse,
      );
    });

    test('give visible floors quieter decoration than visible walls', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final plan = _plan(_game(visible: visible, explored: visible, map: map));

      // act
      final wallPaint = _paint(plan, plan.cellAt(const Position(2, 0))!);
      final floorPaint = _paint(plan, plan.cellAt(const Position(2, 1))!);

      // assert — structure carries more material response than the quiet
      // stone field, while floors carry no structural ornament.
      expect(wallPaint.gritStrength, greaterThan(floorPaint.gritStrength));
      expect(floorPaint.edge, 0.0);
      expect(floorPaint.crackStrength, 0.0);
      expect(floorPaint.speck, isTrue);
    });

    test('keep stairs in the continuous stone field', () {
      // arrange — two cells at the same position and knowledge, differing
      // only by terrain kind.
      const stairs = MaterialCell(
        position: Position(4, 2),
        kind: MaterialTileKind.stairsDown,
        knowledge: MaterialKnowledge.visible,
      );
      const twinFloor = MaterialCell(
        position: Position(4, 2),
        kind: MaterialTileKind.floor,
        knowledge: MaterialKnowledge.visible,
      );

      // act
      final stairsPaint = materialCellPaint(
        stairs,
        palette: DungeonPalette.crypt,
        masonry: false,
      );
      final floorPaint = materialCellPaint(
        twinFloor,
        palette: DungeonPalette.crypt,
        masonry: false,
      );

      // assert — the material stays continuous; the final glyph layer, not a
      // highlighted tile square, keeps the semantic exit findable.
      expect(stairsPaint.fill, floorPaint.fill);
      expect(stairsPaint.edge, floorPaint.edge);
      expect(stairsPaint.crackStrength, 0.0);
      expect(stairsPaint.speck, isFalse);
    });

    test('reduce remembered detail without erasing the geometry', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      const remembered = Position(9, 2);
      final plan = _plan(
        _game(visible: visible, explored: {...visible, remembered}, map: map),
      );
      final rememberedFloor = plan.cellAt(remembered)!;

      // act
      final paint = _paint(plan, rememberedFloor);
      final visibleFloorPaint = _paint(
        plan,
        plan.cellAt(const Position(2, 1))!,
      );

      // assert — the remembered floor keeps a faint grit trace (the geometry
      // survives) but its detail is a fraction of the visible response, and
      // it carries none of the structural ornament
      expect(paint.gritStrength, greaterThan(0.0));
      expect(paint.gritStrength, lessThan(visibleFloorPaint.gritStrength));
      expect(paint.crackStrength, 0.0);
      expect(paint.speck, isFalse);
      expect(paint.fill, DungeonPalette.crypt.rememberedStone);
    });

    test('keep the same marks across two identical plans', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final game = _game(visible: visible, explored: visible, map: map);
      final first = _plan(game);
      final second = _plan(game);

      // act
      final firstPaint = [for (final cell in first.cells) _paint(first, cell)];
      final secondPaint = [
        for (final cell in second.cells) _paint(second, cell),
      ];

      // assert — deterministic presentation: rebuild, pan, revisit produce
      // the same picture
      expect(firstPaint, secondPaint);
      expect(first.masonry, second.masonry);
    });
    test('selects the locked surface treatment for every identity', () {
      // arrange
      const wall = MaterialCell(
        position: Position(1, 1),
        kind: MaterialTileKind.wall,
        knowledge: MaterialKnowledge.visible,
      );
      const floor = MaterialCell(
        position: Position(1, 1),
        kind: MaterialTileKind.floor,
        knowledge: MaterialKnowledge.visible,
      );
      const stairs = MaterialCell(
        position: Position(1, 1),
        kind: MaterialTileKind.stairsDown,
        knowledge: MaterialKnowledge.visible,
      );
      const remembered = MaterialCell(
        position: Position(1, 1),
        kind: MaterialTileKind.floor,
        knowledge: MaterialKnowledge.remembered,
      );
      const cases = [
        (
          palette: DungeonPalette.crypt,
          wallEdge: 0.55,
          wallGrit: 0.14,
          wallPattern: SurfacePattern.none,
          wallPatternStrength: 0.0,
          wallCrack: 0.5,
          floorGrit: 0.08,
          floorPattern: SurfacePattern.none,
          floorPatternStrength: 0.0,
          floorSpeck: true,
        ),
        (
          palette: DungeonPalette.seaCave,
          wallEdge: 0.42,
          wallGrit: 0.10,
          wallPattern: SurfacePattern.tideStrata,
          wallPatternStrength: 0.36,
          wallCrack: 0.0,
          floorGrit: 0.055,
          floorPattern: SurfacePattern.tideStrata,
          floorPatternStrength: 0.20,
          floorSpeck: true,
        ),
        (
          palette: DungeonPalette.ruinedKeep,
          wallEdge: 0.68,
          wallGrit: 0.15,
          wallPattern: SurfacePattern.ashlarFracture,
          wallPatternStrength: 0.45,
          wallCrack: 0.70,
          floorGrit: 0.07,
          floorPattern: SurfacePattern.ashlarFracture,
          floorPatternStrength: 0.28,
          floorSpeck: true,
        ),
        (
          palette: DungeonPalette.lowlandRoad,
          wallEdge: 0.32,
          wallGrit: 0.07,
          wallPattern: SurfacePattern.none,
          wallPatternStrength: 0.0,
          wallCrack: 0.0,
          floorGrit: 0.045,
          floorPattern: SurfacePattern.roadWear,
          floorPatternStrength: 0.24,
          floorSpeck: false,
        ),
      ];

      // act and assert
      for (final row in cases) {
        final wallPaint = materialCellPaint(
          wall,
          palette: row.palette,
          masonry: false,
        );
        final floorPaint = materialCellPaint(
          floor,
          palette: row.palette,
          masonry: false,
        );
        final stairsPaint = materialCellPaint(
          stairs,
          palette: row.palette,
          masonry: false,
        );
        final rememberedPaint = materialCellPaint(
          remembered,
          palette: row.palette,
          masonry: false,
        );

        expect(wallPaint.edge, row.wallEdge);
        expect(wallPaint.gritStrength, row.wallGrit);
        expect(wallPaint.pattern, row.wallPattern);
        expect(wallPaint.patternStrength, row.wallPatternStrength);
        expect(wallPaint.crackStrength, row.wallCrack);
        expect(floorPaint.gritStrength, row.floorGrit);
        expect(floorPaint.pattern, row.floorPattern);
        expect(floorPaint.patternStrength, row.floorPatternStrength);
        expect(floorPaint.speck, row.floorSpeck);
        expect(stairsPaint.fill, floorPaint.fill);
        expect(stairsPaint.edge, floorPaint.edge);
        expect(stairsPaint.speck, isFalse);
        expect(stairsPaint.pattern, SurfacePattern.none);
        expect(stairsPaint.patternStrength, 0.0);
        expect(rememberedPaint.fill, row.palette.rememberedStone);
        expect(rememberedPaint.pattern, SurfacePattern.none);
        expect(rememberedPaint.patternStrength, 0.0);
        expect(rememberedPaint.gritStrength, lessThan(floorPaint.gritStrength));
        expect(rememberedPaint.edge, lessThan(wallPaint.edge));
      }
    });

    test(
      'renders equal plans equally and each regional identity differently',
      () async {
        // arrange
        final map = FloorMap.parse(_arena);
        final visible = computeFov(map, const Position(1, 1), fovRadius);
        final game = _game(map: map, visible: visible, explored: visible);
        const palettes = [
          DungeonPalette.crypt,
          DungeonPalette.seaCave,
          DungeonPalette.ruinedKeep,
          DungeonPalette.lowlandRoad,
        ];

        // act
        final rendered = <Uint8List>[];
        for (final palette in palettes) {
          final first = await _renderBytes(materialPlan(game, palette));
          final second = await _renderBytes(materialPlan(game, palette));
          rendered.add(_bytes(first));
          expect(_bytes(first), orderedEquals(_bytes(second)));
        }

        // assert
        for (var index = 1; index < rendered.length; index++) {
          expect(rendered[index], isNot(orderedEquals(rendered.first)));
        }
      },
    );

    test(
      'regional patterns alter only their interior and leave controls base',
      () async {
        // arrange
        const cases = [
          (
            palette: DungeonPalette.seaCave,
            kind: MaterialTileKind.floor,
            patterned: Offset(44, 47),
            control: Offset(54, 58),
          ),
          (
            palette: DungeonPalette.ruinedKeep,
            kind: MaterialTileKind.wall,
            patterned: Offset(50, 49),
            control: Offset(60, 60),
          ),
          (
            palette: DungeonPalette.lowlandRoad,
            kind: MaterialTileKind.floor,
            patterned: Offset(48, 56),
            control: Offset(62, 54),
          ),
        ];

        // act and assert
        for (final row in cases) {
          final patterned = await _renderBytes(
            _singleCellPlan(palette: row.palette, kind: row.kind),
          );
          final base = await _renderBytes(
            _singleCellPlan(
              palette: row.palette,
              kind: MaterialTileKind.stairsDown,
            ),
          );
          final differences = [
            for (var x = _at(1) + 6; x <= _at(1) + 30; x++)
              for (var y = _at(1) + 6; y <= _at(1) + 30; y++)
                if (_pixel(patterned, x, y) != _pixel(base, x, y))
                  Offset(x.toDouble(), y.toDouble()),
          ];
          expect(differences, isNotEmpty, reason: '${row.palette.material}');
          expect(
            _pixel(patterned, row.control.dx.toInt(), row.control.dy.toInt()),
            _pixel(base, row.control.dx.toInt(), row.control.dy.toInt()),
          );
        }
      },
    );

    test('visibility, memory, void, and exposed strokes stay bounded for every palette', () async {
      // arrange
      final map = FloorMap.parse(_arena);
      const visible = Position(1, 1);
      const remembered = Position(3, 1);
      const wall = Position(1, 1);
      const mark = MaterialMark(
        grit: 0,
        speck: false,
        crack: 1,
        edge: 1,
        pattern: 0,
      );
      MaterialPlan rememberedPlan(DungeonPalette palette) => MaterialPlan(
        cells: const [
          MaterialCell(
            position: visible,
            kind: MaterialTileKind.floor,
            knowledge: MaterialKnowledge.visible,
          ),
          MaterialCell(
            position: remembered,
            kind: MaterialTileKind.floor,
            knowledge: MaterialKnowledge.remembered,
          ),
        ],
        marks: {visible: mark, remembered: mark},
        masonry: const {},
        heroPosition: visible,
        palette: palette,
      );
      MaterialPlan wallPlan(DungeonPalette palette) => MaterialPlan(
        cells: const [
          MaterialCell(
            position: wall,
            kind: MaterialTileKind.wall,
            knowledge: MaterialKnowledge.visible,
          ),
        ],
        marks: {wall: mark},
        masonry: const {},
        heroPosition: wall,
        palette: palette,
      );

      // act and assert
      for (final palette in const [
        DungeonPalette.crypt,
        DungeonPalette.seaCave,
        DungeonPalette.ruinedKeep,
        DungeonPalette.lowlandRoad,
      ]) {
        final known = materialPlan(
          _game(map: map, visible: {visible}, explored: {visible, remembered}),
          palette,
        );
        final mask = visibleMaterialMask(known);
        Offset centerOf(Position position) => Offset(
          (position.x + 0.5) * cameraCellSize,
          (position.y + 0.5) * cameraCellSize,
        );
        expect(mask.contains(centerOf(visible)), isTrue);
        expect(mask.contains(centerOf(remembered)), isFalse);
        expect(mask.contains(centerOf(const Position(11, 1))), isFalse);

        final memoryRgba = await _renderBytes(rememberedPlan(palette));
        expect(_pixel(memoryRgba, _at(3.5), _at(1.5)), palette.rememberedStone);
        final knownRgba = await _renderBytes(known);
        expect(_pixel(knownRgba, _at(5.5), _at(1.5)), dungeonVoid);

        final wallRgba = await _renderBytes(wallPlan(palette));
        for (final sample in [
          [_at(1) - 1, _at(1.5)],
          [_at(2), _at(1.5)],
          [_at(1.5), _at(1) - 1],
          [_at(1.5), _at(2)],
        ]) {
          expect(
            _pixel(wallRgba, sample[0], sample[1]),
            dungeonVoid,
            reason: '${palette.material} stroke leaked at $sample',
          );
        }
      }
    });
    test('light growth is value-first for every palette', () {
      // arrange and act
      for (final palette in const [
        DungeonPalette.crypt,
        DungeonPalette.seaCave,
        DungeonPalette.ruinedKeep,
        DungeonPalette.lowlandRoad,
      ]) {
        final dim = stoneLitColor(palette, 0.2);
        final bright = stoneLitColor(palette, 0.8);
        final dimHsl = HSLColor.fromColor(dim);
        final brightHsl = HSLColor.fromColor(bright);

        // assert
        expect(
          bright.computeLuminance() - dim.computeLuminance(),
          greaterThan(brightHsl.saturation - dimHsl.saturation),
          reason: '${palette.material}',
        );
        expect(
          _value(palette.rememberedStone),
          lessThan(_value(palette.visibleStone)),
        );
        expect(
          _value(palette.visibleStone),
          lessThan(_value(stoneLitColor(palette, 1))),
        );
      }
    });
  });
}
