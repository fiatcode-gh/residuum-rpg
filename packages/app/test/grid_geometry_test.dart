import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

void main() {
  group('GridGeometry.camera', () {
    test('camera cells are 16 by 20 dp on every viewport', () {
      // arrange
      const size = Size(200, 400);

      // act
      final geometry = GridGeometry.camera(
        size,
        40,
        40,
        const Position(20, 20),
      );

      // assert
      expect(mapCellWidth, 16);
      expect(mapCellHeight, 20);
      expect(geometry.cellWidth, mapCellWidth);
      expect(geometry.cellHeight, mapCellHeight);
    });

    test('an axis that fits centres with its own extent', () {
      // arrange
      const size = Size(200, 400);

      // act
      final geometry = GridGeometry.camera(size, 10, 10, const Position(0, 0));

      // assert
      expect(geometry.origin, const Offset(20, 100));
    });

    test('ignores pan on an axis whose whole extent fits', () {
      // arrange
      const size = Size(200, 400);

      // act
      final panned = GridGeometry.camera(
        size,
        10,
        10,
        const Position(0, 0),
        const Offset(90, 90),
      );

      // assert
      expect(panned.origin, const Offset(20, 100));
    });

    test('treats an extent exactly filling the viewport as fitting', () {
      // arrange
      const size = Size(mapCellWidth * 5, mapCellHeight * 5);

      // act
      final geometry = GridGeometry.camera(
        size,
        5,
        5,
        const Position(4, 4),
        const Offset(50, 50),
      );

      // assert
      expect(geometry.origin, Offset.zero);
    });

    test('centres the focus cell on an overflowing axis', () {
      // arrange
      const size = Size(360, 360);

      // act
      final geometry = GridGeometry.camera(
        size,
        40,
        40,
        const Position(20, 20),
      );

      // assert
      expect(geometry.topLeftOf(20, 20), const Offset(172, 170));
    });

    test('clamps at the near edges rather than showing void', () {
      // arrange
      const size = Size(360, 360);

      // act
      final geometry = GridGeometry.camera(size, 40, 40, const Position(0, 0));

      // assert
      expect(geometry.origin, Offset.zero);
    });

    test('clamps at the far edges rather than showing void', () {
      // arrange
      const size = Size(360, 360);
      const extentX = mapCellWidth * 40;
      const extentY = mapCellHeight * 40;

      // act
      final geometry = GridGeometry.camera(
        size,
        40,
        40,
        const Position(39, 39),
      );

      // assert
      expect(geometry.origin, const Offset(360 - extentX, 360 - extentY));
    });

    test('shifts by the pan before clamping', () {
      // arrange
      const size = Size(360, 360);
      final unpanned = GridGeometry.camera(
        size,
        40,
        40,
        const Position(20, 20),
      );

      // act
      final panned = GridGeometry.camera(
        size,
        40,
        40,
        const Position(20, 20),
        const Offset(30, -30),
      );

      // assert
      expect(panned.origin, unpanned.origin + const Offset(30, -30));
    });

    test('a pan past the edge clamps instead of running off', () {
      // arrange
      const size = Size(360, 360);

      // act
      final geometry = GridGeometry.camera(
        size,
        40,
        40,
        const Position(20, 20),
        const Offset(9999, 9999),
      );

      // assert
      expect(geometry.origin, Offset.zero);
    });

    test('each axis fits or overflows independently', () {
      // arrange - width (5 cells * 16 = 80) fits the 400 dp viewport and
      // centres; height (40 cells * 20 = 800) overflows the 200 dp viewport
      // and follows the focus instead
      const size = Size(400, 200);

      // act
      final geometry = GridGeometry.camera(size, 5, 40, const Position(2, 20));

      // assert
      expect(geometry.cellWidth, mapCellWidth);
      expect(geometry.cellHeight, mapCellHeight);
      expect(geometry.origin.dx, (400 - 5 * mapCellWidth) / 2);
      expect(geometry.origin.dy, lessThan(0));
    });

    test('positionAt inverts centreOf and topLeftOf for a panned, clamped '
        'camera on a 40 x 30 map, including the last row and column', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(357, 411),
        40,
        30,
        const Position(17, 23),
        const Offset(13, -29),
      );

      // act + assert
      for (final tile in [
        const Position(0, 0),
        const Position(19, 21),
        const Position(39, 29),
      ]) {
        final corner = geometry.topLeftOf(tile.x, tile.y);
        expect(geometry.positionAt(corner + const Offset(1, 1)), tile);
        expect(geometry.positionAt(geometry.centreOf(tile)), tile);
      }
    });

    test('a point one dp past the right or bottom edge is null', () {
      // arrange - the last cell of a panned, clamped camera
      final geometry = GridGeometry.camera(
        const Size(357, 411),
        40,
        30,
        const Position(17, 23),
        const Offset(13, -29),
      );
      final corner = geometry.topLeftOf(39, 29);

      // act
      final pastRight = geometry.positionAt(
        Offset(corner.dx + mapCellWidth + 1, corner.dy),
      );
      final pastBottom = geometry.positionAt(
        Offset(corner.dx, corner.dy + mapCellHeight + 1),
      );

      // assert
      expect(pastRight, isNull);
      expect(pastBottom, isNull);
    });
  });

  group('GridGeometry.topLeftOf', () {
    test('walks cells by the dense cell size from the origin', () {
      // arrange - a camera whose grid exactly fills the viewport, so the
      // origin is the known (0, 0)
      final geometry = GridGeometry.camera(
        const Size(mapCellWidth * 20, mapCellHeight * 12),
        20,
        12,
        const Position(0, 0),
      );

      // act
      final corner = geometry.topLeftOf(3, 2);

      // assert
      expect(corner, const Offset(48, 40));
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

      // act + assert
      expect(
        geometry.centreOf(const Position(3, 2)),
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

      // act + assert
      expect(
        geometry.rectOf(const Position(3, 2)),
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
      // arrange - a viewport far taller than a 5-row grid, so it centres
      // with a wide letterbox above it
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

      // act
      final beyondX = geometry.positionAt(const Offset(190, 200));
      final beyondY = geometry.positionAt(const Offset(100, 260));

      // assert
      expect(beyondX, isNull);
      expect(beyondY, isNull);
    });

    test('rejects a tap on a collapsed layout', () {
      // arrange - a hand-built degenerate geometry; GridGeometry.camera's
      // dense cell never collapses on its own
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
