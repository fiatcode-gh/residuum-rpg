import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_core/core.dart';

void main() {
  group('heroOffScreen', () {
    test('a hero the camera centres inside a small viewport is on screen', () {
      // arrange - the camera clamps the map's origin, so the focus cell's
      // position is read off the clamped origin, not a naive centre
      const viewport = Size(72, 72);
      const hero = Position(1, 1);
      final geometry = GridGeometry.camera(viewport, 7, 5, hero);

      // act + assert
      expect(heroOffScreen(viewport, geometry, hero), isFalse);
    });

    test('a hero pushed off the right edge by pan is off screen', () {
      // arrange - a floor wider than the viewport; the player's pan has been
      // clamped against the map's near edge, leaving the hero far right
      const viewport = Size(72, 72);
      const hero = Position(20, 1);
      final geometry = GridGeometry.camera(
        viewport,
        22,
        5,
        hero,
        const Offset(2000, 0),
      );

      // act + assert
      expect(heroOffScreen(viewport, geometry, hero), isTrue);
    });

    test('a hero pushed below the viewport by pan is off screen', () {
      // arrange - a tall floor; the pan has been clamped against the map's
      // top edge while the hero stands far down it
      const viewport = Size(360, 72);
      const hero = Position(2, 20);
      final geometry = GridGeometry.camera(
        viewport,
        7,
        22,
        hero,
        const Offset(0, 2000),
      );

      // act + assert
      expect(heroOffScreen(viewport, geometry, hero), isTrue);
    });

    test('a partially visible hero cell is not off screen', () {
      // arrange - the cell's top-left corner is inside the viewport even
      // though the cell extends past the edge: the player can still see part
      // of the hero
      const viewport = Size(360, 80);
      const hero = Position(2, 1);
      final geometry = GridGeometry.camera(viewport, 7, 22, hero);

      // act + assert
      expect(heroOffScreen(viewport, geometry, hero), isFalse);
    });
  });
}
