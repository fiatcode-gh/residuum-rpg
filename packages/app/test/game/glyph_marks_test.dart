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

    test('keep glyph identity exact through the treatment', () {
      // arrange
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
      );

      // act
      final treatment = glyphMarkTreatment(cell);

      // assert — the mark is drawn from the cell's own glyph and ink; the
      // treatment decorates, it never replaces the semantics
      expect(treatment.glyph, 'g');
      expect(treatment.ink, cell.ink);
    });

    test('fade remembered nodes with the glyph plan opacity', () {
      // arrange
      const seen = GlyphCell(
        Position(1, 1),
        '*',
        Color(0xFFA87BC0),
        1.0,
        layer: GlyphLayer.node,
      );
      const remembered = GlyphCell(
        Position(1, 2),
        '*',
        Color(0xFFA87BC0),
        0.4,
        layer: GlyphLayer.node,
      );

      // act
      final seenTreatment = glyphMarkTreatment(seen);
      final rememberedTreatment = glyphMarkTreatment(remembered);

      // assert
      expect(seenTreatment.opacity, greaterThan(rememberedTreatment.opacity));
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
      expect(treatment.shadow, isFalse);
    });
  });
}
