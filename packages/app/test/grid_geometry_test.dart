import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

void main() {
  group('GridGeometry.fit', () {
    test('sizes cells by the tighter dimension', () {
      // arrange
      const size = Size(200, 400);

      // act
      final geometry = GridGeometry.fit(size, 20, 12);

      // assert
      expect(geometry.cellSize, 10);
    });

    test('centres the grid inside the available space', () {
      // arrange
      const size = Size(200, 400);

      // act
      final geometry = GridGeometry.fit(size, 20, 12);

      // assert
      expect(geometry.origin, const Offset(0, 140));
    });
  });

  group('GridGeometry.camera', () {
    test('uses the fixed cell size however small the viewport', () {
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
      expect(geometry.cellSize, cameraCellSize);
    });

    test('centres an axis whose whole extent fits', () {
      // arrange
      const size = Size(400, 400);

      // act
      final geometry = GridGeometry.camera(size, 5, 5, const Position(0, 0));

      // assert
      expect(geometry.origin, const Offset(110, 110));
    });

    test('ignores pan on an axis whose whole extent fits', () {
      // arrange
      const size = Size(400, 400);

      // act
      final panned = GridGeometry.camera(
        size,
        5,
        5,
        const Position(0, 0),
        const Offset(90, 90),
      );

      // assert
      expect(panned.origin, const Offset(110, 110));
    });

    test('treats an extent exactly filling the viewport as fitting', () {
      // arrange
      const size = Size(cameraCellSize * 5, cameraCellSize * 5);

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
      expect(geometry.topLeftOf(20, 20), const Offset(162, 162));
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
      const extent = cameraCellSize * 40;

      // act
      final geometry = GridGeometry.camera(
        size,
        40,
        40,
        const Position(39, 39),
      );

      // assert
      expect(geometry.origin, const Offset(360 - extent, 360 - extent));
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

    test('holds the fixed cell size when one axis fits and one does not', () {
      // arrange
      const size = Size(400, 200);

      // act
      final geometry = GridGeometry.camera(size, 5, 40, const Position(2, 20));

      // assert
      expect(geometry.cellSize, cameraCellSize);
      expect(geometry.origin.dx, 110);
      expect(geometry.origin.dy, lessThan(0));
    });

    test('positionAt inverts topLeftOf under an arbitrary camera', () {
      // arrange
      final geometry = GridGeometry.camera(
        const Size(357, 411),
        40,
        40,
        const Position(17, 23),
        const Offset(13, -29),
      );

      // act
      final corner = geometry.topLeftOf(19, 21);
      final position = geometry.positionAt(corner + const Offset(1, 1));

      // assert
      expect(position, const Position(19, 21));
    });
  });

  group('GridGeometry.topLeftOf', () {
    test('walks cells by one cell size from the origin', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final corner = geometry.topLeftOf(3, 2);

      // assert
      expect(corner, const Offset(30, 160));
    });
  });

  group('GridGeometry.positionAt', () {
    test('maps a tap inside a cell to that cell', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final position = geometry.positionAt(const Offset(35, 165));

      // assert
      expect(position, const Position(3, 2));
    });

    test('maps the exact top-left corner of a cell to that cell', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final position = geometry.positionAt(const Offset(30, 160));

      // assert
      expect(position, const Position(3, 2));
    });

    test('rejects a tap in the letterbox above the grid', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final position = geometry.positionAt(const Offset(100, 10));

      // assert
      expect(position, isNull);
    });

    test('rejects a tap past the last column and row', () {
      // arrange
      final geometry = GridGeometry.fit(const Size(200, 400), 20, 12);

      // act
      final beyondX = geometry.positionAt(const Offset(205, 200));
      final beyondY = geometry.positionAt(const Offset(100, 395));

      // assert
      expect(beyondX, isNull);
      expect(beyondY, isNull);
    });

    test('rejects a tap on a collapsed layout', () {
      // arrange
      final geometry = GridGeometry.fit(Size.zero, 20, 12);

      // act
      final position = geometry.positionAt(Offset.zero);

      // assert
      expect(position, isNull);
    });
  });
}
