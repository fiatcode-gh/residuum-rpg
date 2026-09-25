import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import '../world/world_bloc.dart';
import 'action_icon.dart';
import 'battle_view.dart';
import 'crawl_action_row.dart';
import 'crawl_exits.dart';
import 'crawl_hud.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'dungeon_palette.dart';
import 'dungeon_scene.dart';
import 'game_bloc.dart';
import 'grid_geometry.dart';
import 'log_drawer.dart';
import 'log_line.dart';
import 'log_row.dart';
import 'map_callout.dart';
import 'map_overlays.dart';
import 'map_touch.dart';
import 'pack_screen.dart';
import 'spell_row.dart';

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
                              onActorSelected: (actor) {
                                final presentation = state.presentationOf(
                                  actor.id,
                                );
                                if (presentation == null) return;
                                bloc.add(TimelineActorSelected(actor.id));
                                showEnemyInfo(context, actor, presentation);
                              },
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
                                                  MapCallout(
                                                    state: state,
                                                    size: size,
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
                          CrawlActionBar(
                            key: actionRowKey,
                            actions: _actionsFor(context, bloc, state),
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

/// Routes a map tap by intent (`map_touch.dart::resolveMapTap`): a cell means
/// the bloc decides — move, bump or cast — and an inspect names the map
/// callout's target, at no turn cost. A tap that resolves to a cell or to
/// nothing dismisses an open callout first: the bloc's own no-op returns
/// (an unexplored cell, a non-adjacent wall, no path) never emit, so the
/// dismissal has to come from here, not from whatever `TileTapped` decides.
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

/// Names the map callout's target under the long-press, at no turn cost.
/// A long-press that resolves to nothing dismisses an open callout too,
/// the same rule [_onMapTap] applies.
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

/// The crawl's one action row: every verb that applies, each appearing only
/// when it can do something.
///
/// A chip that is visible but inert teaches the player nothing; a chip that
/// appears exactly when it applies is how the rules explain themselves. The
/// pack is the exception and is always reachable, because looking at what you
/// are carrying is not an action and should never be gated.
///
/// Exploration and the combat shelf shared no row before this unit — a hero
/// mid-fight saw the combat shelf under the map and the exploration row
/// beneath it, and Drink was live on both. The Drink entry below carries the
/// merge's own mechanism: it gains the guard its other half already had, so
/// it renders from exactly one guard, never two. Wait and Flee left this row
/// for the log row beside them (PLAN.md G8, Task 05).
List<CrawlAction> _actionsFor(
  BuildContext context,
  GameBloc bloc,
  GameViewState state,
) {
  final isBattleOpen = state.isBattleOpen;
  final firstPotion = state.firstPotion;
  final readied = state.knownSpells.take(readiedSpellCount);
  return [
    if (isBattleOpen && firstPotion != null)
      CrawlAction(
        id: 'drink',
        label: 'Drink',
        metadata: '×${state.potionCount}',
        mark: const ShippedMark(ActionIcon.potion),
        onPressed: state.game.isGameOver
            ? null
            : () => bloc.add(const QuickDrinkPressed()),
      ),
    if (isBattleOpen)
      for (final spell in readied)
        CrawlAction(
          id: 'spell:${spell.id}',
          label: '${spell.school.schoolMarking} ${spell.name}',
          metadata: '${spell.manaCost} mana',
          mark: spellMark(spell),
          armable: true,
          armed: state.armedSpellId == spell.id,
          onPressed: () => _onSpell(bloc, state, spell),
        ),
    if (isBattleOpen && state.knownSpells.length > readiedSpellCount)
      CrawlAction(
        id: 'spells-overflow',
        label: '+${state.knownSpells.length - readiedSpellCount}',
        mark: const ShippedMark(ActionIcon.more),
        onPressed: () => _openSpellsOverflow(context, bloc, state),
      ),
    if (!isBattleOpen && firstPotion != null)
      CrawlAction(
        id: 'drink',
        label: 'Drink',
        metadata: '×${state.potionCount}',
        mark: const ShippedMark(ActionIcon.potion),
        onPressed: state.game.isGameOver
            ? null
            : () => bloc.add(const QuickDrinkPressed()),
      ),
    CrawlAction(
      id: 'pack',
      label: 'Pack',
      metadata: '×${state.game.inventory.length}',
      mark: const ShippedMark(ActionIcon.pack),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BlocProvider.value(value: bloc, child: const CrawlPackScreen()),
        ),
      ),
    ),
  ];
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

/// What tapping a spell chip or overflow row does: Mend and Ward cast
/// straight from the row since they never need a target; everything else
/// arms — a second tap on the same chip disarms.
void _onSpell(GameBloc bloc, GameViewState state, Spell spell) {
  if (spell.kind == SpellKind.mend || spell.kind == SpellKind.ward) {
    bloc.add(CastPressed(spell.id));
  } else {
    bloc.add(SkillArmed(state.armedSpellId == spell.id ? null : spell.id));
  }
}

/// Opens the full grimoire behind the row's overflow chip: every known
/// spell, so nothing a hero knows is unreachable from the row.
Future<void> _openSpellsOverflow(
  BuildContext context,
  GameBloc bloc,
  GameViewState state,
) => showCrawlSheet<void>(
  context,
  children: (sheetContext) => [
    const Padding(
      padding: EdgeInsets.only(bottom: crawlPanelPadding),
      child: Text('Spells', style: displayPanel),
    ),
    for (final spell in state.knownSpells)
      _OverflowRow(
        spell: spell,
        armed: state.armedSpellId == spell.id,
        onCast: () {
          Navigator.of(sheetContext).pop();
          _onSpell(bloc, state, spell);
        },
      ),
  ],
);

/// One row of the overflow grimoire: what the row's chip would cast, in
/// full — the school and name a chip's marking can only abbreviate.
class _OverflowRow extends StatelessWidget {
  const _OverflowRow({
    required this.spell,
    required this.armed,
    required this.onCast,
  });

  final Spell spell;
  final bool armed;
  final VoidCallback onCast;

  @override
  Widget build(BuildContext context) {
    return SpellRow(
      spell: spell,
      style: textLine,
      dimStyle: textDetailDim,
      detail: effectOf(spell),
      trailing: TextButton(
        key: Key('overflow-${spell.id}'),
        onPressed: onCast,
        style: TextButton.styleFrom(
          side: armed
              ? const BorderSide(color: crawlCold, width: hairline * 1.5)
              : null,
        ),
        child: Text(
          armed ? '— armed' : spell.school.schoolMarking,
          style: textLine,
        ),
      ),
    );
  }
}
