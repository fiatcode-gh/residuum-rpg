import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

void main() {
  group('GridGeometry.camera', () {
    const viewport = Size(392.7, 568.8);

    test('cells are 24 by 30 dp', () {
      final geometry = GridGeometry.camera(
        viewport,
        40,
        40,
        const Position(20, 20),
      );

      expect(mapCellWidth, 24);
      expect(mapCellHeight, 30);
      expect(geometry.cellWidth, mapCellWidth);
      expect(geometry.cellHeight, mapCellHeight);
    });

    test('centres the hero on the viewport at zero pan, near every edge of a '
        '24 x 16 floor', () {
      const columns = 24;
      const rows = 16;
      for (final hero in const [
        Position(3, 2),
        Position(23, 15),
        Position(12, 8),
      ]) {
        final geometry = GridGeometry.camera(viewport, columns, rows, hero);
        final centre = geometry.centreOf(hero);
        expect(centre.dx, closeTo(viewport.width / 2, 0.01));
        expect(centre.dy, closeTo(viewport.height / 2, 0.01));
      }
    });

    test('a pan on an axis that used to fit moves the origin instead of being '
        'ignored', () {
      const columns = 24;
      const rows = 16;
      const hero = Position(12, 8);
      final unpanned = GridGeometry.camera(viewport, columns, rows, hero);
      final panned = GridGeometry.camera(
        viewport,
        columns,
        rows,
        hero,
        const Offset(100, 50),
      );

      expect(panned.origin, unpanned.origin + const Offset(100, 50));
    });

    test('an extreme pan clamps so the viewport centre lands on the floor '
        'edge instead of past it', () {
      const columns = 24;
      const rows = 16;
      const hero = Position(12, 8);
      final extentY = mapCellHeight * rows;
      final geometry = GridGeometry.camera(
        viewport,
        columns,
        rows,
        hero,
        const Offset(10000, -10000),
      );

      expect(geometry.origin.dx, viewport.width / 2);
      expect(geometry.origin.dy, viewport.height / 2 - extentY);
    });

    test('clampPan reports exactly the pan the camera already applied for '
        'that same drag', () {
      const columns = 24;
      const rows = 16;
      const hero = Position(12, 8);
      const rawPan = Offset(10000, -10000);

      final geometry = GridGeometry.camera(
        viewport,
        columns,
        rows,
        hero,
        rawPan,
      );
      final effective = GridGeometry.clampPan(
        viewport,
        columns,
        rows,
        hero,
        rawPan,
      );

      expect(
        GridGeometry.camera(viewport, columns, rows, hero, effective).origin,
        geometry.origin,
      );
      expect(effective, isNot(rawPan));
    });

    test('the lit area around a centred hero on a depth-5 floor stays fully '
        'on screen', () {
      const columns = 32;
      const rows = 20;
      const hero = Position(16, 10);
      final geometry = GridGeometry.camera(viewport, columns, rows, hero);

      for (var dx = -7; dx <= 7; dx++) {
        for (var dy = -8; dy <= 8; dy++) {
          final rect = geometry.rectOf(Position(hero.x + dx, hero.y + dy));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(viewport.width));
          expect(rect.bottom, lessThanOrEqualTo(viewport.height));
        }
      }
    });

    test(
      'positionAt round-trips centreOf for every cell of a panned camera',
      () {
        const columns = 24;
        const rows = 16;
        final geometry = GridGeometry.camera(
          viewport,
          columns,
          rows,
          const Position(12, 8),
          const Offset(13, -29),
        );

        for (var x = 0; x < columns; x++) {
          for (var y = 0; y < rows; y++) {
            final cell = Position(x, y);
            expect(geometry.positionAt(geometry.centreOf(cell)), cell);
          }
        }
      },
    );

    test('a point one dp past the right or bottom edge is null', () {
      final geometry = GridGeometry.camera(
        viewport,
        24,
        16,
        const Position(12, 8),
        const Offset(13, -29),
      );
      final corner = geometry.topLeftOf(23, 15);

      final pastRight = geometry.positionAt(
        Offset(corner.dx + mapCellWidth + 1, corner.dy),
      );
      final pastBottom = geometry.positionAt(
        Offset(corner.dx, corner.dy + mapCellHeight + 1),
      );

      expect(pastRight, isNull);
      expect(pastBottom, isNull);
    });
  });

  group('GridGeometry.topLeftOf', () {
    test('walks cells by the dense cell size from the origin', () {
      // arrange
      const geometry = GridGeometry(
        cellWidth: mapCellWidth,
        cellHeight: mapCellHeight,
        origin: Offset.zero,
        columns: 20,
        rows: 12,
      );

      // act
      final corner = geometry.topLeftOf(3, 2);

      // assert
      expect(corner, const Offset(3 * mapCellWidth, 2 * mapCellHeight));
    });
  });

  group('GridGeometry.centreOf', () {
    test('sits half a cell past the top-left corner', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(mapCellWidth * 20, mapCellHeight * 12),
        20,
        12,
        const Position(0, 0),
      );

      // act
      final centre = geometry.centreOf(const Position(3, 2));

      // assert
      expect(
        centre,
        geometry.topLeftOf(3, 2) +
            const Offset(mapCellWidth / 2, mapCellHeight / 2),
      );
    });
  });

  group('GridGeometry.rectOf', () {
    test('is topLeftOf sized by the dense cell', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(mapCellWidth * 20, mapCellHeight * 12),
        20,
        12,
        const Position(0, 0),
      );

      // act
      final rect = geometry.rectOf(const Position(3, 2));

      // assert
      expect(
        rect,
        geometry.topLeftOf(3, 2) & const Size(mapCellWidth, mapCellHeight),
      );
    });
  });

  group('GridGeometry.positionAt', () {
    test('maps a tap inside a cell to that cell', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(mapCellWidth * 20, mapCellHeight * 12),
        20,
        12,
        const Position(0, 0),
      );

      // act
      final position = geometry.positionAt(
        geometry.topLeftOf(3, 2) + const Offset(1, 1),
      );

      // assert
      expect(position, const Position(3, 2));
    });

    test('maps the exact top-left corner of a cell to that cell', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(mapCellWidth * 20, mapCellHeight * 12),
        20,
        12,
        const Position(0, 0),
      );

      // act
      final position = geometry.positionAt(geometry.topLeftOf(3, 2));

      // assert
      expect(position, const Position(3, 2));
    });

    test('rejects a tap in the letterbox above the grid', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(200, 400),
        10,
        5,
        const Position(0, 0),
      );

      // act
      final position = geometry.positionAt(const Offset(100, 10));

      // assert
      expect(position, isNull);
    });

    test('rejects a tap past the last column and row', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(200, 400),
        10,
        5,
        const Position(0, 0),
      );
      final corner = geometry.topLeftOf(9, 4);

      // act
      final beyondX = geometry.positionAt(
        Offset(corner.dx + mapCellWidth, corner.dy),
      );
      final beyondY = geometry.positionAt(
        Offset(corner.dx, corner.dy + mapCellHeight),
      );

      // assert
      expect(beyondX, isNull);
      expect(beyondY, isNull);
    });

    test('rejects a tap on a hand-built collapsed geometry, since '
        "GridGeometry.camera never collapses the dense cell on its own", () {
      // arrange
      const geometry = GridGeometry(
        cellWidth: 0,
        cellHeight: 0,
        origin: Offset.zero,
        columns: 20,
        rows: 12,
      );

      // act
      final position = geometry.positionAt(Offset.zero);

      // assert
      expect(position, isNull);
    });
  });
}
