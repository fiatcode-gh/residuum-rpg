import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../style/tokens.dart';
import '../world/world_bloc.dart';
import 'battle_view.dart';
import 'crawl_exits.dart';
import 'crawl_hud.dart';
import 'crawl_menu.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'dungeon_palette.dart';
import 'dungeon_scene.dart';
import 'game_bloc.dart';
import 'grid_geometry.dart';
import 'log_drawer.dart';
import 'log_line.dart';
import 'log_row.dart';
import 'map_overlays.dart';
import 'map_touch.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({required this.palette, super.key});

  final DungeonPalette palette;

  /// The crawl, and the refusal that makes the stairs the only way out.
  ///
  /// [PopScope] with [PopScope.canPop] false is what stops Android's back
  /// button popping this route. **The stairs are the door, and back is not the
  /// stairs.** Walking out is now a decision made at a landing — the hero climbs
  /// out and the dungeon waits — and a pop from the middle of a floor is not
  /// that decision: it would put the hero in town from wherever they happened to
  /// be standing, mid-fight and mid-corridor, and make the one place the crawl
  /// can be left mean nothing. An interruption is what closing the app is for,
  /// and that already suspends everything exactly as it stands.
  ///
  /// The refusal is not silent. `didPop` is false exactly when the system tried
  /// and was declined — a programmatic pop, which is what [suspendDungeon] does
  /// at the stairs and [leaveDungeon] at the death overlay, reports true and
  /// must say nothing. The pack's route is pushed on top of this one and carries
  /// no [PopScope] of its own, so back closes the pack as it always did.
  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      context.read<GameBloc>().add(const SystemBackPressed());
    },
    child: BlocListener<GameBloc, GameViewState>(
      listenWhen: (before, after) => !before.hasFled && after.hasFled,
      listener: (context, state) =>
          leaveEncounter(context, state, EncounterEnding.fled),
      child: Theme(
        data: residuumTheme,
        child: Scaffold(
          body: SafeArea(
            minimum: const EdgeInsets.only(bottom: crawlGestureClear),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: BlocBuilder<GameBloc, GameViewState>(
                builder: (context, state) {
                  final bloc = context.read<GameBloc>();
                  return Stack(
                    children: [
                      Column(
                        children: [
                          CrawlHud(
                            state: state,
                            dungeon: bloc.dungeon,
                            day: bloc.day,
                          ),
                          if (state.isBattleOpen)
                            BattleDock(
                              state: state,
                              onActorSelected: (actor) =>
                                  bloc.add(TimelineActorSelected(actor.id)),
                            ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (overlayContext, overlayConstraints) {
                                final overlayHeight =
                                    overlayConstraints.maxHeight;
                                final fullDrawer =
                                    state.logDrawerExtent ==
                                    LogDrawerExtent.full;
                                return Stack(
                                  children: [
                                    Column(
                                      children: [
                                        Expanded(
                                          key: dungeonSceneSlotKey,
                                          child: LayoutBuilder(
                                            builder: (mapContext, constraints) {
                                              final size = constraints.biggest;
                                              return Stack(
                                                children: [
                                                  DungeonSceneHost(
                                                    key: dungeonSceneHostKey,
                                                    state: state,
                                                    palette: palette,
                                                    onTap: (local, geometry) =>
                                                        _onMapTap(
                                                          bloc,
                                                          state,
                                                          geometry,
                                                          local,
                                                        ),
                                                    onPan: (delta) => bloc.add(
                                                      MapPanned(delta),
                                                    ),
                                                    onLongPress:
                                                        (local, geometry) =>
                                                            _onMapLongPress(
                                                              bloc,
                                                              state,
                                                              geometry,
                                                              local,
                                                            ),
                                                  ),
                                                  MapOverlays(
                                                    bloc: bloc,
                                                    state: state,
                                                    size: size,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: crawlPanelGap),
                                        LogRow(
                                          key: logRowKey,
                                          state: state,
                                          bloc: bloc,
                                        ),
                                        const SizedBox(height: crawlGap),
                                      ],
                                    ),
                                    if (state.logDrawerExtent !=
                                        LogDrawerExtent.peek)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        top: fullDrawer ? 0 : null,
                                        child: fullDrawer
                                            ? LogDrawer(
                                                key: logDrawerKey,
                                                state: state,
                                                bloc: bloc,
                                              )
                                            : SizedBox(
                                                height: math.min(
                                                  crawlLogSheetHeight *
                                                      crawlScale(context),
                                                  overlayHeight,
                                                ),
                                                child: LogDrawer(
                                                  key: logDrawerKey,
                                                  state: state,
                                                  bloc: bloc,
                                                ),
                                              ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          CrawlMenu(
                            key: crawlMenuKey,
                            state: state,
                            bloc: bloc,
                          ),
                          const SizedBox(height: crawlBottomGap),
                        ],
                      ),
                      if (state.game.isGameOver) _DeathOverlay(state: state),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _onMapTap(
  GameBloc bloc,
  GameViewState state,
  GridGeometry geometry,
  Offset local,
) {
  switch (resolveMapTap(state, geometry, local)) {
    case MapTouchCell(:final position):
      if (state.inspectedActorId != null) {
        bloc.add(const InspectDismissed());
      }
      bloc.add(TileTapped(position));
    case MapTouchInspect(:final actor):
      bloc.add(ActorInspected(actor.id));
    case MapTouchNothing():
      if (state.inspectedActorId != null) {
        bloc.add(const InspectDismissed());
      }
  }
}

void _onMapLongPress(
  GameBloc bloc,
  GameViewState state,
  GridGeometry geometry,
  Offset local,
) {
  switch (resolveMapLongPress(state, geometry, local)) {
    case MapTouchInspect(:final actor):
      bloc.add(ActorInspected(actor.id));
    case MapTouchCell():
    case MapTouchNothing():
      if (state.inspectedActorId != null) {
        bloc.add(const InspectDismissed());
      }
  }
}

class _DeathOverlay extends StatelessWidget {
  const _DeathOverlay({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: scrim,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You died.', style: textHeadline),
          const SizedBox(height: rhythm * 2),
          const Text(
            'What you carried is gone. What you wore is not.',
            style: textLineDim,
          ),
          const SizedBox(height: rhythm * 4),
          CrawlPill(
            label: state.isEncounter ? 'Wake at home' : 'Return to town',
            onPressed: () => state.isEncounter
                ? leaveEncounter(context, state, EncounterEnding.died)
                : leaveDungeon(context, state, died: true),
          ),
        ],
      ),
    ),
  );
}
