import 'dart:ui' show Color;

import 'package:flutter/material.dart' show HSVColor;

import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/style/tokens.dart' show crawlEnemy;
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

double _hue(Color colour) => HSVColor.fromColor(colour).hue;

/// The shorter way around the hue circle between two hues in degrees.
double _hueDistance(double a, double b) {
  final delta = (a - b).abs() % 360;
  return delta > 180 ? 360 - delta : delta;
}

void main() {
  group('the region palettes', () {
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

    test('carries four distinct fog values, one per region', () {
      // assert
      expect(DungeonPalette.crypt.fog, const Color(0xFF1A2430));
      expect(DungeonPalette.seaCave.fog, const Color(0xFF152A3A));
      expect(DungeonPalette.ruinedKeep.fog, const Color(0xFF221F2A));
      expect(DungeonPalette.lowlandRoad.fog, const Color(0xFF1D2327));
      expect({
        DungeonPalette.crypt.fog,
        DungeonPalette.seaCave.fog,
        DungeonPalette.ruinedKeep.fog,
        DungeonPalette.lowlandRoad.fog,
      }, hasLength(4));
    });
  });

  group('the warm stone terrain ink (PLAN.md G3)', () {
    test('keeps a floor < wall < stairs value ladder, lit and shade', () {
      double value(Color colour) => HSVColor.fromColor(colour).value;

      expect(value(stoneFloorLit), lessThan(value(stoneWallLit)));
      expect(value(stoneWallLit), lessThan(value(stoneStairsLit)));
      expect(value(stoneFloorShade), lessThan(value(stoneWallShade)));
      expect(value(stoneWallShade), lessThan(value(stoneStairsShade)));
    });

    test(
      'keeps litterInk, nodeInk and crawlEnemy pairwise distinct in hue',
      () {
        final hues = {
          'litter': _hue(litterInk),
          'node': _hue(nodeInk),
          'enemy': _hue(crawlEnemy),
        };
        final entries = hues.entries.toList();
        for (var i = 0; i < entries.length; i++) {
          for (var j = i + 1; j < entries.length; j++) {
            expect(
              _hueDistance(entries[i].value, entries[j].value),
              greaterThan(30),
              reason: '${entries[i].key} vs ${entries[j].key}',
            );
          }
        }
      },
    );
  });
}
