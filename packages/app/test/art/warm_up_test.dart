import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/art/art_assets.dart';
import 'package:residuum_app/art/warm_up.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('warmUpArt', () {
    testWidgets('loads environment art without requesting dungeon images', (
      tester,
    ) async {
      final requestedPaths = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      final assetManifest = await rootBundle.load('AssetManifest.bin');

      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final path = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        requestedPaths.add(path);
        if (path == 'AssetManifest.bin') return assetManifest;
        final bytes = await File(path).readAsBytes();
        return ByteData.sublistView(bytes);
      });
      addTearDown(() {
        messenger.setMockMessageHandler('flutter/assets', null);
        PaintingBinding.instance.imageCache
          ..clear()
          ..clearLiveImages();
      });

      await tester.runAsync(warmUpArt);

      expect(
        requestedPaths,
        containsAll(EnvironmentArt.values.map((art) => art.path)),
      );
      for (final art in EnvironmentArt.values) {
        final key = await AssetImage(art.path)
            .obtainKey(ImageConfiguration.empty);
        expect(
          PaintingBinding.instance.imageCache.containsKey(key),
          isTrue,
          reason: art.name,
        );
      }
      final dungeonPaths = {
        ...MaterialArt.values.map((art) => art.path),
        ...TerrainOverlayArt.values.map((art) => art.path),
      };
      expect(requestedPaths.where(dungeonPaths.contains), isEmpty);
    });
  });
}
