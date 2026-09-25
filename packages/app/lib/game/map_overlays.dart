import 'package:flutter/material.dart';

import 'action_card.dart';
import 'action_card_verbs.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'grid_geometry.dart';
import 'map_overlay_layout.dart';
import 'target_card.dart';
import 'turn_order_strip.dart';

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

    Rect? stripRect;
    var stripFlipped = false;
    if (state.isBattleOpen) {
      final stripHeight = crawlStripHeight * crawlScale(context);
      final topStrip = Rect.fromLTWH(0, 0, size.width, stripHeight);
      stripFlipped = topStrip.overlaps(hero);
      final stripWidth = stripFlipped ? size.width - 64 : size.width;
      stripRect = Rect.fromLTWH(
        0,
        stripFlipped ? size.height - stripHeight : 0,
        stripWidth,
        stripHeight,
      );
    }

    final showCard =
        cardVerbsFor(state).isNotEmpty || placeFacts(state).isNotEmpty;
    Rect? cardRect;
    if (showCard) {
      cardRect = placeActionCard(
        map: size,
        height: actionCardHeight(state, crawlScale(context)),
        hero: hero,
        strip: stripRect,
      );
    }

    Rect? recenter;
    if (showRecenter) {
      recenter = recenterRect(size, actionCard: cardRect);
    }

    final leader = cardRect == null
        ? null
        : actionCardLeader(map: size, card: cardRect, hero: hero);

    final targetArea = cardRect == null
        ? Offset.zero & size
        : (cardRect.center.dy >= hero.center.dy
              ? Rect.fromLTRB(0, 0, size.width, cardRect.top)
              : Rect.fromLTRB(0, cardRect.bottom, size.width, size.height));

    return Stack(
      children: [
        if (stripRect != null)
          Positioned(
            left: stripRect.left,
            top: stripRect.top,
            width: stripRect.width,
            height: stripRect.height,
            child: TurnOrderStrip(
              state: state,
              onActorSelected: (actor) =>
                  bloc.add(TimelineActorSelected(actor.id)),
              flipped: stripFlipped,
            ),
          ),
        if (leader != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: actionCardLeaderKey,
                painter: LeaderPainter(from: leader.$1, to: leader.$2),
              ),
            ),
          ),
        if (cardRect != null)
          Positioned.fromRect(
            rect: cardRect,
            child: ActionCard(bloc: bloc, state: state, width: cardRect.width),
          ),
        Positioned.fill(
          child: TargetCard(
            state: state,
            size: size,
            area: targetArea,
            avoid: [?recenter, ?stripRect],
          ),
        ),
        if (showRecenter && recenter != null)
          Positioned.fromRect(
            rect: recenter,
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
