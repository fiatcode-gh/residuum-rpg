import 'dart:async';

import 'package:flutter/painting.dart';

import 'art_assets.dart';

bool _warmedUp = false;

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

/// Precaches the environment illustrations once per process.
Future<void> warmUpArt() async {
  if (_warmedUp) return;
  _warmedUp = true;

  await Future.wait(EnvironmentArt.values.map((art) => _precache(art.path)));
}
