import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../game/dungeon_palette.dart';
import 'art_assets.dart';

class DungeonArt {
  const DungeonArt({required this.surfaces, required this.overlays});
  const DungeonArt.none() : surfaces = const {}, overlays = const {};

  final Map<MaterialArt, ui.Image> surfaces;
  final Map<TerrainOverlayArt, ui.Image> overlays;

  ui.Image? surfaceFor(RegionMaterial region, MaterialSurface surface) {
    final art = MaterialArt.of(region, surface);
    return art == null ? null : surfaces[art];
  }

  ui.Image? overlayFor(RegionMaterial region, OverlayKind kind) {
    final art = TerrainOverlayArt.of(region, kind);
    return art == null ? null : overlays[art];
  }
}

DungeonArt _loaded = const DungeonArt.none();
bool _warmedUp = false;

/// The decoded dungeon art this process loaded at launch, or none.
DungeonArt get dungeonArt => _loaded;

Future<ui.Image?> _decode(String path) async {
  try {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  } catch (_) {
    return null;
  }
}

Future<void> _precache(String path) async {
  try {
    final completer = Completer<void>();
    final stream = AssetImage(path).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );
    stream.addListener(listener);
    await completer.future;
  } catch (_) {}
}

/// Decodes every shipped dungeon image and precaches the three illustrations,
/// once per process.
Future<void> warmUpArt() async {
  if (_warmedUp) return;
  _warmedUp = true;

  final decodedSurfaces = await Future.wait(
    MaterialArt.values.map((art) => _decode(art.path)),
  );
  final surfaces = <MaterialArt, ui.Image>{};
  for (var i = 0; i < MaterialArt.values.length; i++) {
    final image = decodedSurfaces[i];
    if (image != null) surfaces[MaterialArt.values[i]] = image;
  }

  final decodedOverlays = await Future.wait(
    TerrainOverlayArt.values.map((art) => _decode(art.path)),
  );
  final overlays = <TerrainOverlayArt, ui.Image>{};
  for (var i = 0; i < TerrainOverlayArt.values.length; i++) {
    final image = decodedOverlays[i];
    if (image != null) overlays[TerrainOverlayArt.values[i]] = image;
  }

  await Future.wait(EnvironmentArt.values.map((art) => _precache(art.path)));

  _loaded = DungeonArt(surfaces: surfaces, overlays: overlays);
}
