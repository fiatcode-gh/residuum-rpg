import 'dart:ui' show Color;

import 'package:flutter/material.dart' show HSLColor;

import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

double _value(Color colour) =>
    0.2126 * colour.r + 0.7152 * colour.g + 0.0722 * colour.b;

const Map<String, DungeonPalette> _palettes = {
  'crypt': DungeonPalette.crypt,
  'sea-cave': DungeonPalette.seaCave,
  'ruined-keep': DungeonPalette.ruinedKeep,
  'lowland-road': DungeonPalette.lowlandRoad,
};

void main() {
  group('the terrain palettes', () {
    test('the crypt keeps the exact Unit 2 anchors', () {
      // assert
      expect(DungeonPalette.crypt.wall, const Color(0xFFB9BEC6));
      expect(DungeonPalette.crypt.floor, const Color(0xFF5B6270));
      expect(DungeonPalette.crypt.stairs, const Color(0xFFE8ECF2));
      expect(DungeonPalette.crypt.rememberedStone, const Color(0xFF1A1E20));
      expect(DungeonPalette.crypt.visibleStone, const Color(0xFF292A27));
      expect(DungeonPalette.crypt.edgeInk, const Color(0xFF48463F));
      expect(DungeonPalette.crypt.detailInk, const Color(0xFFD4B77B));
      expect(DungeonPalette.crypt.lightInk, const Color(0xFFE8C58A));
      expect(DungeonPalette.crypt.maxLightLift, 0.30);
      expect(DungeonPalette.crypt.maxTintMix, 0.12);
      expect(DungeonPalette.crypt.themeSalt, 0x0C7);
      expect(DungeonPalette.crypt.material, RegionMaterial.cryptStone);
    });

    test('maps exactly the three dungeon ids and rejects towns', () {
      // assert
      expect(paletteForDungeon(cryptNode), DungeonPalette.crypt);
      expect(paletteForDungeon(seaCave), DungeonPalette.seaCave);
      expect(paletteForDungeon(ruinedKeep), DungeonPalette.ruinedKeep);
      expect(() => paletteForDungeon(stonebridge), throwsArgumentError);
      expect(() => paletteForDungeon(northgate), throwsArgumentError);
    });

    test('maps every shipped road regardless of endpoint ordering', () {
      // act
      final reversedSeaCave = Route(from: seaCave, to: northgate, days: 1);

      // assert
      expect(
        paletteForRoad(Route(from: northgate, to: seaCave, days: 1)),
        DungeonPalette.seaCave,
      );
      expect(paletteForRoad(reversedSeaCave), DungeonPalette.seaCave);
      expect(
        paletteForRoad(Route(from: northgate, to: ruinedKeep, days: 2)),
        DungeonPalette.ruinedKeep,
      );
      expect(
        paletteForRoad(Route(from: stonebridge, to: cryptNode, days: 1)),
        DungeonPalette.lowlandRoad,
      );
      expect(
        paletteForRoad(Route(from: stonebridge, to: northgate, days: 2)),
        DungeonPalette.lowlandRoad,
      );
      expect(
        paletteForRoad(Route(from: cryptNode, to: northgate, days: 2)),
        DungeonPalette.lowlandRoad,
      );
      expect(
        () => paletteForRoad(Route(from: stonebridge, to: ruinedKeep, days: 1)),
        throwsArgumentError,
      );
    });

    test('keeps the glyph and material value ladders readable', () {
      // assert
      for (final entry in _palettes.entries) {
        final palette = entry.value;
        expect(
          _value(palette.floor),
          lessThan(_value(palette.wall)),
          reason: entry.key,
        );
        expect(
          _value(palette.wall),
          lessThan(_value(palette.stairs)),
          reason: entry.key,
        );
        expect(
          _value(palette.rememberedStone),
          lessThan(_value(palette.visibleStone)),
          reason: entry.key,
        );
        expect(
          _value(nodeInk) - _value(palette.floor),
          greaterThan(0.1),
          reason: entry.key,
        );
        expect(
          _value(litterInk) - _value(nodeInk),
          greaterThan(0.1),
          reason: entry.key,
        );
      }
      final lowlandSaturation = HSLColor.fromColor(
        DungeonPalette.lowlandRoad.floor,
      ).saturation;
      expect(
        lowlandSaturation,
        lessThan(HSLColor.fromColor(DungeonPalette.seaCave.floor).saturation),
      );
      expect(
        lowlandSaturation,
        lessThan(
          HSLColor.fromColor(DungeonPalette.ruinedKeep.floor).saturation,
        ),
      );
    });

    test('gives each context its material, anchors, and salt', () {
      // act
      final materials = _palettes.values.map((palette) => palette.material);
      final salts = _palettes.values.map((palette) => palette.themeSalt);
      final visible = _palettes.values.map((palette) => palette.visibleStone);
      final remembered = _palettes.values.map(
        (palette) => palette.rememberedStone,
      );
      final edges = _palettes.values.map((palette) => palette.edgeInk);

      // assert
      expect(materials.toSet(), hasLength(4));
      expect(salts.toSet(), hasLength(4));
      expect(visible.toSet(), hasLength(4));
      expect(remembered.toSet(), hasLength(4));
      expect(edges.toSet(), hasLength(4));
      expect(litterInk, const Color(0xFF7FC8B8));
      expect(nodeInk, const Color(0xFFA87BC0));
    });
  });
}
