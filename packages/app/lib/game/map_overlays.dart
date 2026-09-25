import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'grid_geometry.dart';
import 'map_overlay_layout.dart';
import 'place_actions.dart';
import 'place_popup.dart';

const recenterKey = Key('recenter');

bool _heroOffScreen(GameViewState state, Size size) {
  final geometry = GridGeometry.camera(
    size,
    state.game.map.width,
    state.game.map.height,
    state.cameraFocus,
    state.pan,
  );
  return heroOffScreen(size, geometry, state.game.hero.position);
}

class MapOverlays extends StatelessWidget {
  const MapOverlays({
    required this.bloc,
    required this.state,
    required this.size,
    super.key,
  });

  final GameBloc bloc;
  final GameViewState state;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final geometry = GridGeometry.camera(
      size,
      state.game.map.width,
      state.game.map.height,
      state.cameraFocus,
      state.pan,
    );
    final hero = geometry.rectOf(state.game.hero.position);
    final showRecenter = _heroOffScreen(state, size);
    final avoid = [if (showRecenter) recenterRect(size)];

    final facts = placeFacts(state);
    final verbs = placeVerbsFor(state);
    Rect? popupRect;
    if (facts.isNotEmpty || verbs.isNotEmpty) {
      final scale = crawlScale(context);
      final width = math.min(size.width - 16, crawlPlacePopupWidth);
      final height = placePopupHeight(state, scale);
      final hc = hero.center;
      popupRect = placeMapOverlay(
        map: size,
        size: Size(width, height),
        hero: hero,
        preferred: [
          Offset(hc.dx - width / 2, hero.bottom + 6),
          Offset(hc.dx - width / 2, hero.top - 6 - height),
        ],
        avoid: avoid,
      );
    }

    return Stack(
      children: [
        if (popupRect != null)
          Positioned(
            left: popupRect.left,
            top: popupRect.top,
            width: popupRect.width,
            height: popupRect.height,
            child: PlacePopup(bloc: bloc, state: state, width: popupRect.width),
          ),
        if (showRecenter)
          Positioned(
            right: 8,
            bottom: 8,
            child: CrawlPill(
              key: recenterKey,
              label: 'Recenter on the hero',
              icon: Icons.center_focus_strong,
              extent: crawlTouchTarget,
              onPressed: () => bloc.add(const RecenterPressed()),
            ),
          ),
      ],
    );
  }
}
