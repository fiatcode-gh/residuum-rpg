import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('MaterialId', () {
    test('every material has its own marking, so hue carries nothing', () {
      // act
      final markings = {for (final id in MaterialId.values) id.marking};

      // assert
      expect(markings, hasLength(MaterialId.values.length));
    });

    test('no marking collides with a rarity marking', () {
      // arrange
      final tiers = {for (final rarity in Rarity.values) rarity.marking};

      // act
      final markings = {for (final id in MaterialId.values) id.marking};

      // assert - a materials row and an item row are read on the same screen,
      // so a shared mark would be two categories wearing one shape
      expect(markings.intersection(tiers), isEmpty);
    });

    test('every material has a word, so a row reads aloud', () {
      // act
      final words = [for (final id in MaterialId.values) id.word];

      // assert
      expect(words, everyElement(isNotEmpty));
      expect(words.toSet(), hasLength(words.length));
    });
  });

  group('withMaterial', () {
    test('adds to a counter the hero does not have yet', () {
      // arrange
      const carried = <MaterialId, int>{};

      // act
      final after = withMaterial(carried, MaterialId.ore, 1);

      // assert
      expect(after, {MaterialId.ore: 1});
    });

    test('adds to a counter the hero already has', () {
      // arrange
      const carried = {MaterialId.ore: 3};

      // act
      final after = withMaterial(carried, MaterialId.ore, 2);

      // assert
      expect(after, {MaterialId.ore: 5});
    });

    test('leaves every other counter alone', () {
      // arrange
      const carried = {MaterialId.ore: 3, MaterialId.herb: 1};

      // act
      final after = withMaterial(carried, MaterialId.ore, -1);

      // assert
      expect(after, {MaterialId.ore: 2, MaterialId.herb: 1});
    });

    test('drops the entry when the last of a material is spent', () {
      // arrange
      const carried = {MaterialId.ore: 2, MaterialId.herb: 1};

      // act
      final after = withMaterial(carried, MaterialId.ore, -2);

      // assert - no zero entries, for the reason a bare tile has no groundItems
      // entry: the map's size is what the hero actually carries
      expect(after, {MaterialId.herb: 1});
    });
  });

  group('countOf', () {
    test('is zero for a material the hero has never carried', () {
      // arrange
      const carried = <MaterialId, int>{};

      // act
      final held = countOf(carried, MaterialId.ingot);

      // assert
      expect(held, 0);
    });

    test('is what the counter says', () {
      // arrange
      const carried = {MaterialId.ingot: 4};

      // act
      final held = countOf(carried, MaterialId.ingot);

      // assert
      expect(held, 4);
    });
  });
}
