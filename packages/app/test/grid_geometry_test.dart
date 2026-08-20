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
