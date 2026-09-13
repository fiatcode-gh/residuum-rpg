import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:residuum_app/game/dungeon_material.dart';
import 'package:residuum_app/game/dungeon_scene_material.dart';
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
}) => GameState(
  map: map,
  hero: _heroAt(const Position(1, 1)),
  monsters: const [],
  rng: Rng(1),
  lootRng: Rng(2),
  visible: visible,
  explored: explored,
  buildFloor: (depth) => throw StateError('no descent in a paint test'),
);

MaterialPlan _plan(GameState game) => materialPlan(game, DungeonPalette.crypt);

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
      final paint = materialCellPaint(
        plan.cellAt(remembered)!,
        masonry: plan.masonryAt(remembered),
      );

      expect(paint.fill, rememberedStoneColor);
      expect(
        paint.fill,
        isNot(
          materialCellPaint(
            plan.cellAt(const Position(2, 1))!,
            masonry: plan.masonryAt(const Position(2, 1)),
          ).fill,
        ),
      );
    });

    test('paint visible geometry by its presentation light', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final plan = _plan(_game(visible: visible, explored: visible, map: map));

      final atHero = materialCellPaint(
        plan.cellAt(const Position(1, 1))!,
        masonry: plan.masonryAt(const Position(1, 1)),
      );
      final far = materialCellPaint(
        plan.cellAt(const Position(1, 3))!,
        masonry: plan.masonryAt(const Position(1, 3)),
      );

      // assert — light lifts value first: brighter near the hero, never
      expect(
        atHero.fill,
        stoneLitColor(plan.cellAt(const Position(1, 1))!.light),
      );
      expect(far.fill, stoneLitColor(plan.cellAt(const Position(1, 3))!.light));
    });

    test('lift stone value before hue as light grows', () {
      // arrange
      final dim = stoneLitColor(0.2);
      final bright = stoneLitColor(0.8);

      // act
      final dimHsl = HSLColor.fromColor(dim);
      final brightHsl = HSLColor.fromColor(bright);
      final valueGain = bright.computeLuminance() - dim.computeLuminance();
      final saturationGain = brightHsl.saturation - dimHsl.saturation;

      // assert — value-first: the luminance step dominates any warmth step
      expect(valueGain, greaterThan(saturationGain));
    });

    test(
      'crack exposed visible walls occasionally, never masonry or floors',
      () {
        // arrange
        final map = FloorMap.parse(_arena);
        final visible = computeFov(map, const Position(1, 1), fovRadius);
        final plan = _plan(
          _game(visible: visible, explored: visible, map: map),
        );

        // act
        final exposedPaint = materialCellPaint(
          plan.cellAt(const Position(8, 0))!,
          masonry: false,
        );
        final massPaint = materialCellPaint(
          plan.cellAt(const Position(2, 0))!,
          masonry: true,
        );

        // assert — the art bible's occasional hairline crack lives on exposed
        // wall faces, gated by the plan's own hashed crack decision; masonry
        // mass and floors stay uncracked
        expect(exposedPaint.crackStrength, greaterThan(0.0));
        expect(massPaint.crackStrength, 0.0);
        for (final cell in plan.cells) {
          if (cell.kind == MaterialTileKind.floor) {
            expect(
              materialCellPaint(cell, masonry: false).crackStrength,
              0.0,
              reason: 'floor ${cell.position} must not crack',
            );
          }
        }
      },
    );

    test(
      'paint a masonry wall as part of the mass, a lone wall on its own',
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

        // assert — the treatment differs between the two structural roles;
        expect(
          materialCellPaint(massCell, masonry: true).edge,
          isNot(materialCellPaint(loneCell, masonry: false).edge),
        );
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
      final wall = plan.markAt(const Position(2, 0))!;
      final floor = plan.markAt(const Position(2, 1))!;

      // assert — structure carries more material response than the quiet
      // stone field
      expect(wall.grit, greaterThan(floor.grit));
      expect(wall.crack, greaterThanOrEqualTo(floor.crack));
      expect(floor.edge, 0.0);
      expect(floor.crack, 0.0);
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
      final paint = materialCellPaint(
        rememberedFloor,
        masonry: plan.masonryAt(remembered),
      );
      final visibleFloorPaint = materialCellPaint(
        plan.cellAt(const Position(2, 1))!,
        masonry: plan.masonryAt(const Position(2, 1)),
      );

      // assert — the remembered floor keeps a faint grit trace (the geometry
      // survives) but its detail is a fraction of the visible response, and
      // it carries none of the structural ornament
      expect(paint.gritStrength, greaterThan(0.0));
      expect(paint.gritStrength, lessThan(visibleFloorPaint.gritStrength));
      expect(paint.crackStrength, 0.0);
      expect(paint.speck, isFalse);
      expect(paint.fill, rememberedStoneColor);
    });

    test('keep the same marks across two identical plans', () {
      // arrange
      final map = FloorMap.parse(_arena);
      final visible = computeFov(map, const Position(1, 1), fovRadius);
      final game = _game(visible: visible, explored: visible, map: map);
      final first = _plan(game);
      final second = _plan(game);

      // act
      final firstPaint = [
        for (final cell in first.cells)
          materialCellPaint(cell, masonry: first.masonryAt(cell.position)),
      ];
      final secondPaint = [
        for (final cell in second.cells)
          materialCellPaint(cell, masonry: second.masonryAt(cell.position)),
      ];

      // assert — deterministic presentation: rebuild, pan, revisit produce
      // the same picture
      expect(firstPaint, secondPaint);
      expect(first.masonry, second.masonry);
    });
  });
}
