import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/art/art_assets.dart';
import 'package:residuum_app/art/dungeon_art.dart';

void main() {
  group('warmUpArt', () {
    testWidgets('loads every surface and overlay dungeonArt serves', (
      tester,
    ) async {
      // act
      await tester.runAsync(warmUpArt);

      // assert - _decode/_precache never throw, so a total activation
      // failure would silently leave dungeonArt on DungeonArt.none() and
      // every one of these calls null instead of failing loudly.
      for (final art in MaterialArt.values) {
        expect(
          dungeonArt.surfaceFor(art.region, art.surface),
          isNotNull,
          reason: art.name,
        );
      }
      for (final art in TerrainOverlayArt.values) {
        expect(
          dungeonArt.overlayFor(art.region, art.kind),
          isNotNull,
          reason: art.name,
        );
      }
    });
  });
}
