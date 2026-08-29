import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('GatherKind', () {
    test('every kind draws as its own single character', () {
      // act
      final glyphs = [for (final kind in GatherKind.values) kind.glyph];

      // assert
      expect(glyphs, everyElement(hasLength(1)));
      expect(glyphs.toSet(), hasLength(glyphs.length));
    });

    test('no glyph collides with the terrain or with the hero', () {
      // arrange
      const taken = {'#', '.', '<', '>', '@'};

      // act
      final glyphs = {for (final kind in GatherKind.values) kind.glyph};

      // assert
      expect(glyphs.intersection(taken), isEmpty);
    });

    test('no glyph is a letter, which is what every creature draws as', () {
      // act
      final glyphs = [for (final kind in GatherKind.values) kind.glyph];

      // assert
      expect(
        glyphs.where((glyph) => RegExp(r'^[A-Za-z]$').hasMatch(glyph)),
        isEmpty,
      );
    });

    test('every kind has its own marking, so hue carries nothing', () {
      // act
      final markings = {for (final kind in GatherKind.values) kind.marking};

      // assert
      expect(markings, hasLength(GatherKind.values.length));
    });

    test('every kind yields a material, and no two yield the same one', () {
      // act
      final yielded = [for (final kind in GatherKind.values) kind.yields];

      // assert
      expect(yielded.toSet(), hasLength(yielded.length));
    });

    test('every kind has a word and a verb of its own', () {
      // act
      final words = [for (final kind in GatherKind.values) kind.word];
      final verbs = [for (final kind in GatherKind.values) kind.verb];

      // assert - the verb is what the control says, and mining a seam does not
      // read like picking a plant
      expect(words, everyElement(isNotEmpty));
      expect(verbs, everyElement(isNotEmpty));
      expect(verbs.toSet(), hasLength(verbs.length));
    });
  });
}
