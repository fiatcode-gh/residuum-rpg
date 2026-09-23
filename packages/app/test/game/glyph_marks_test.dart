import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/glyph_plan.dart';
import 'package:residuum_app/game/glyph_marks.dart';
import 'package:residuum_app/style/tokens.dart';

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
    });

    test('uses ticks for a marked target', () {
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
        marked: true,
      );

      final treatment = glyphMarkTreatment(cell);

      expect(treatment.targetMark, GlyphTargetMark.ticks);
    });

    test('uses brackets for a selected actor', () {
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
        selected: true,
      );

      final treatment = glyphMarkTreatment(cell);

      expect(treatment.targetMark, GlyphTargetMark.brackets);
    });

    test('selection supersedes marking on the same cell', () {
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

      expect(treatment.targetMark, GlyphTargetMark.brackets);
    });

    group('glyphInk (PLAN.md G4)', () {
      const hero = Position(0, 0);

      GlyphCell wallAt(int distance) => GlyphCell(
        Position(distance, 0),
        '#',
        stoneWallLit,
        fullOpacity,
        shade: stoneWallShade,
        layer: GlyphLayer.terrain,
      );

      test('a visible wall at the hero is lit stone at full alpha', () {
        expect(glyphInk(wallAt(0), hero), stoneWallLit.withValues(alpha: 1.0));
      });

      test('a visible wall at the edge of sight is shade stone at 0.55', () {
        expect(
          glyphInk(wallAt(fovRadius), hero),
          stoneWallShade.withValues(alpha: 0.55),
        );
      });

      test('a visible wall halfway to the edge lerps at 0.6625 alpha', () {
        final ink = glyphInk(wallAt(4), hero);
        final expected = Color.lerp(
          stoneWallShade,
          stoneWallLit,
          0.25,
        )!.withValues(alpha: 0.55 + 0.45 * 0.25);

        expect(ink, expected);
        expect(ink.a, closeTo(0.6625, 0.0001));
      });

      test('value strictly decreases with distance along a row', () {
        double luminance(Color colour) =>
            0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b;
        final values = [
          for (var distance = 0; distance <= fovRadius; distance++)
            luminance(glyphInk(wallAt(distance), hero)),
        ];
        for (var i = 1; i < values.length; i++) {
          expect(values[i], lessThan(values[i - 1]));
        }
      });

      test('a remembered wall is shade stone at the remembered opacity, '
          'dimmer than the edge of sight', () {
        const remembered = GlyphCell(
          Position(4, 0),
          '#',
          stoneWallLit,
          rememberedOpacity,
          shade: stoneWallShade,
          layer: GlyphLayer.terrain,
        );

        final ink = glyphInk(remembered, hero);
        final edgeOfSight = glyphInk(wallAt(fovRadius), hero);

        expect(ink, stoneWallShade.withValues(alpha: 0.24));
        expect(ink.a, lessThan(edgeOfSight.a));
      });

      test('node, litter, monster and hero glyphs paint at their own ink '
          'and opacity', () {
        const node = GlyphCell(
          Position(1, 1),
          '⌂',
          nodeInk,
          fullOpacity,
          layer: GlyphLayer.node,
        );
        const rememberedNode = GlyphCell(
          Position(1, 1),
          '⌂',
          nodeInk,
          rememberedOpacity,
          layer: GlyphLayer.node,
        );
        const litter = GlyphCell(
          Position(1, 1),
          '!',
          litterInk,
          fullOpacity,
          layer: GlyphLayer.litter,
        );
        const monster = GlyphCell(
          Position(1, 2),
          'g',
          crawlEnemy,
          fullOpacity,
          layer: GlyphLayer.monster,
        );
        const heroCell = GlyphCell(
          Position(0, 0),
          '@',
          crawlHero,
          fullOpacity,
          layer: GlyphLayer.hero,
        );

        for (final cell in [node, rememberedNode, litter, monster, heroCell]) {
          expect(
            glyphInk(cell, hero),
            cell.ink.withValues(alpha: cell.opacity),
          );
        }
      });
    });

    test('carries no target mark for an ordinary actor', () {
      const cell = GlyphCell(
        Position(1, 1),
        'g',
        Color(0xFFD9A227),
        1.0,
        layer: GlyphLayer.monster,
      );

      final treatment = glyphMarkTreatment(cell);

      expect(treatment.targetMark, isNull);
    });
  });
}
