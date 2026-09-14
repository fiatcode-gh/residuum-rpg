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

    test('leave terrain glyphs untouched by the actor treatment', () {
      // arrange
      const terrain = GlyphCell(
        Position(1, 1),
        '.',
        Color(0xFF5B6270),
        1.0,
        layer: GlyphLayer.terrain,
      );

      // act
      final treatment = glyphMarkTreatment(terrain);

      // assert — terrain gets no actor-grade mark; the material layer owns
      // the visible terrain
      expect(treatment.scale, 1.0);
      expect(treatment.halo, isFalse);
    });

    test('do not infer terrain semantics from a glyph character', () {
      // arrange — glyph-plan characters are a characterization boundary, not
      // terrain facts the Flame layer may parse back into game semantics.
      const terrainCharacter = GlyphCell(
        Position(1, 1),
        '>',
        Color(0xFFE8ECF2),
        1.0,
        layer: GlyphLayer.terrain,
      );

      // act
      final treatment = glyphMarkTreatment(terrainCharacter);

      // assert — without the material-plan feature, this terrain cell stays
      expect(treatment.scale, 1.0);
    });

    test('mark stairs as semantic glyphs above the material', () {
      // arrange — stairs carry a terrain-layer cell, but unlike wall/floor
      // text they must survive as a drawn mark: the exit is a semantic
      // feature, not stone texture
      const stairsDown = GlyphCell(
        Position(1, 1),
        '>',
        Color(0xFFE8ECF2),
        1.0,
        layer: GlyphLayer.terrain,
      );
      const stairsUp = GlyphCell(
        Position(2, 1),
        '<',
        Color(0xFFE8ECF2),
        1.0,
        layer: GlyphLayer.terrain,
      );
      const floor = GlyphCell(
        Position(3, 1),
        '.',
        Color(0xFF5B6270),
        1.0,
        layer: GlyphLayer.terrain,
      );

      // act
      final downTreatment = glyphMarkTreatment(
        stairsDown,
        semanticTerrain: true,
      );
      final upTreatment = glyphMarkTreatment(stairsUp, semanticTerrain: true);

      // assert — stairs render as deliberate marks with a slight presence
      // lift, while floor text does not.
      expect(downTreatment.scale, greaterThan(1.0));
      expect(upTreatment.scale, greaterThan(1.0));
      expect(glyphMarkTreatment(floor).scale, 1.0);
    });
  });
}
