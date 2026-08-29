import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/glyph_grid.dart';
import 'package:residuum_content/content.dart';

/// How bright a colour reads with the hue thrown away.
///
/// The sRGB luma weights, which is what a greyscale screenshot of the game
/// would show. The author is deuteranomalous: a palette that separates only by
/// hue separates by nothing, so this is the number the tests below hold apart.
double _value(Color colour) =>
    0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b;

/// Every palette the game draws terrain in.
const Map<String, DungeonPalette> _palettes = {
  'crypt': DungeonPalette.crypt,
  'sea-cave': DungeonPalette.seaCave,
  'ruined keep': DungeonPalette.ruinedKeep,
};

void main() {
  group('the terrain palettes', () {
    test('the crypt keeps the exact colours it always had', () {
      // assert
      expect(DungeonPalette.crypt.wall, const Color(0xFFB9BEC6));
      expect(DungeonPalette.crypt.floor, const Color(0xFF5B6270));
      expect(DungeonPalette.crypt.stairs, const Color(0xFFE8ECF2));
    });

    test(
      'each dungeon is drawn in its own palette, and roads in the crypt\'s',
      () {
        // assert
        expect(paletteFor(cryptNode), DungeonPalette.crypt);
        expect(paletteFor(seaCave), DungeonPalette.seaCave);
        expect(paletteFor(ruinedKeep), DungeonPalette.ruinedKeep);
        expect(paletteFor(null), DungeonPalette.crypt);
      },
    );

    test('wall, floor and stairs separate by value, not only by hue', () {
      // assert — a tenth of the range apart in greyscale, which is the gap that
      // survives a phone screen in daylight
      for (final entry in _palettes.entries) {
        final wall = _value(entry.value.wall);
        final floor = _value(entry.value.floor);
        final stairs = _value(entry.value.stairs);
        expect(wall - floor, greaterThan(0.1), reason: entry.key);
        expect(stairs - wall, greaterThan(0.05), reason: entry.key);
      }
    });

    test('the floors are darker than the walls in every dungeon', () {
      // assert — one rule everywhere, so a player reading one dungeon in
      // greyscale can read the next without relearning it
      for (final entry in _palettes.entries) {
        expect(
          _value(entry.value.floor),
          lessThan(_value(entry.value.wall)),
          reason: entry.key,
        );
      }
    });

    test('no two dungeons are the same palette', () {
      // act
      final walls = {for (final p in _palettes.values) p.wall};
      final floors = {for (final p in _palettes.values) p.floor};

      // assert
      expect(walls, hasLength(3));
      expect(floors, hasLength(3));
    });
  });

  group('the ink a node is drawn in', () {
    test('is a step apart from the litter it can lie under', () {
      // act
      final gap = _value(litterInk) - _value(nodeInk);

      // assert — a vein and a dropped sword are two things a player walks
      // toward, so they have to be told apart with the colour thrown away
      expect(gap, greaterThan(0.1));
    });

    test('is a step apart from every floor it sits on', () {
      // assert
      for (final entry in _palettes.entries) {
        expect(
          _value(nodeInk) - _value(entry.value.floor),
          greaterThan(0.1),
          reason: entry.key,
        );
      }
    });

    test('is lighter than every floor and darker than the litter', () {
      // assert — one rule everywhere, so the reading learned in the crypt holds
      // in the cave and in the keep
      for (final entry in _palettes.entries) {
        expect(_value(nodeInk), greaterThan(_value(entry.value.floor)));
      }
      expect(_value(nodeInk), lessThan(_value(litterInk)));
    });

    test('is not themed, so it is one colour in every dungeon', () {
      // assert — DungeonPalette is terrain-only by its own dartdoc, and a node
      // is something the player walks toward rather than part of the place
      expect(nodeInk, const Color(0xFFA87BC0));
    });
  });
}
