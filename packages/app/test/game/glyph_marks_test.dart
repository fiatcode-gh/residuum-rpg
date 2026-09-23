import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/glyph_plan.dart';
import 'package:residuum_app/game/glyph_marks.dart';

void main() {
  group('the graphical glyph marks', () {
    test('render every actor layer as a graphical mark', () {
      // arrange
      const layers = [
        GlyphLayer.node,
        GlyphLayer.litter,
        GlyphLayer.monster,
        GlyphLayer.hero,
      ];

      // act
      final treatments = [
        for (final layer in layers)
          glyphMarkTreatment(
            GlyphCell(
              Position(1, 1),
              'g',
              Color(0xFFD9A227),
              1.0,
              layer: layer,
            ),
          ),
      ];

      // assert — each actor mark carries a graphical treatment, not a bare
      // terminal cell
      for (final treatment in treatments) {
        expect(treatment.scale, greaterThan(0.0));
      }
    });

    test('give the hero the strongest presence in the hierarchy', () {
      // arrange
      const hero = GlyphCell(
        Position(1, 1),
        '@',
        Color(0xFFFFFFFF),
        1.0,
        layer: GlyphLayer.hero,
      );
      const monster = GlyphCell(
        Position(1, 2),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
      );
      const litter = GlyphCell(
        Position(1, 3),
        '!',
        Color(0xFF7FC8B8),
        1.0,
        layer: GlyphLayer.litter,
      );

      // act
      final heroTreatment = glyphMarkTreatment(hero);
      final monsterTreatment = glyphMarkTreatment(monster);
      final litterTreatment = glyphMarkTreatment(litter);

      // assert — subtle scale hierarchy: hero above monster above litter
      expect(heroTreatment.scale, greaterThan(monsterTreatment.scale));
      expect(monsterTreatment.scale, greaterThan(litterTreatment.scale));
      expect(heroTreatment.halo, isTrue);
    });

    test('uses a square outline for a marked target', () {
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
        marked: true,
      );

      final treatment = glyphMarkTreatment(cell);

      expect(treatment.targetOutline, GlyphOutlineShape.square);
      expect(treatment.selectedOutline, isNull);
    });

    test('uses a circle outline for a selected actor', () {
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
        selected: true,
      );

      final treatment = glyphMarkTreatment(cell);

      expect(treatment.targetOutline, isNull);
      expect(treatment.selectedOutline, GlyphOutlineShape.circle);
    });

    test('keeps target and selection outlines together', () {
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
        marked: true,
        selected: true,
      );

      final treatment = glyphMarkTreatment(cell);

      expect(treatment.targetOutline, GlyphOutlineShape.square);
      expect(treatment.selectedOutline, GlyphOutlineShape.circle);
    });

    test('lights only visible terrain by deterministic hero distance', () {
      const terrain = GlyphCell(
        Position(3, 1),
        '.',
        Color(0xFF38424A),
        fullOpacity,
        layer: GlyphLayer.terrain,
      );
      const remembered = GlyphCell(
        Position(2, 1),
        '.',
        Color(0xFF38424A),
        0.45,
        layer: GlyphLayer.terrain,
      );
      const node = GlyphCell(
        Position(2, 1),
        '⌂',
        Color(0xFF789ABC),
        fullOpacity,
        layer: GlyphLayer.node,
      );
      const rememberedNode = GlyphCell(
        Position(2, 1),
        '⌂',
        Color(0xFF789ABC),
        0.45,
        layer: GlyphLayer.node,
      );
      const monster = GlyphCell(
        Position(2, 1),
        'g',
        Color(0xFF789ABC),
        fullOpacity,
        layer: GlyphLayer.monster,
      );
      const hero = Position(1, 1);
      const terrainAtHero = GlyphCell(
        Position(1, 1),
        '.',
        Color(0xFF38424A),
        fullOpacity,
        layer: GlyphLayer.terrain,
      );

      final nearInk = terrainPresentationInk(terrain, hero);
      final repeatedInk = terrainPresentationInk(terrain, hero);
      final outsideRadius = terrainPresentationInk(
        const GlyphCell(
          Position(7, 1),
          '.',
          Color(0xFF38424A),
          fullOpacity,
          layer: GlyphLayer.terrain,
        ),
        hero,
      );

      expect(
        nearInk,
        Color.lerp(terrain.ink, const Color(0xFFE8C58A), 0.38 * (1 - 4 / 25)),
      );
      expect(nearInk, repeatedInk);
      expect(
        terrainPresentationInk(terrainAtHero, hero),
        Color.lerp(terrainAtHero.ink, const Color(0xFFE8C58A), 0.38),
      );
      expect(outsideRadius, terrain.ink);
      expect(nearInk, isNot(outsideRadius));
      expect(terrainPresentationInk(remembered, hero), remembered.ink);
      expect(remembered.opacity, 0.45);
      expect(terrainPresentationInk(node, hero), node.ink);
      expect(terrainPresentationInk(rememberedNode, hero), rememberedNode.ink);
      expect(terrainPresentationInk(monster, hero), monster.ink);
    });

    test('uses no outline for an ordinary actor', () {
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
      );

      final treatment = glyphMarkTreatment(cell);

      expect(treatment.targetOutline, isNull);
      expect(treatment.selectedOutline, isNull);
    });
  });
}
