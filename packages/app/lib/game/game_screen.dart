import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import '../town/town_bloc.dart';
import '../world/world_bloc.dart';
import 'action_icon.dart';
import 'battle_view.dart';
import 'combat_panel.dart';
import 'crawl_action_row.dart';
import 'crawl_header.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'dungeon_palette.dart';
import 'dungeon_scene.dart';
import 'game_bloc.dart';
import 'hero_panel.dart';
import 'log_drawer.dart';
import 'log_line.dart';
import 'grid_geometry.dart';
import 'map_callout.dart';
import 'map_touch.dart';
import 'pack_screen.dart';
import 'spell_row.dart';

const recenterKey = Key('recenter');

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
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: BlocBuilder<GameBloc, GameViewState>(
                builder: (context, state) {
                  final bloc = context.read<GameBloc>();
                  return Stack(
                    children: [
                      Column(
                        children: [
                          CrawlHeader(
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
                                                  _NotesOverlay(
                                                    notes: _notesFor(state),
                                                  ),
                                                  if (_heroOffScreen(
                                                    state,
                                                    size,
                                                  ))
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: CrawlPill(
                                                        key: recenterKey,
                                                        label: 'Recenter on the hero',
                                                        icon: Icons
                                                            .center_focus_strong,
                                                        onPressed: () => bloc.add(
                                                          const RecenterPressed(),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: crawlPanelGap),
                                        state.isBattleOpen
                                            ? CombatPanel(state: state)
                                            : HeroPanel(
                                                state: state,
                                                heroLabel: bloc.heroLabel,
                                              ),
                                        const SizedBox(height: crawlGap),
                                        LogPeek(
                                          key: logPeekKey,
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

/// Whether the hero has been panned off the glass, which is what puts the
/// recenter affordance over the map.
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

/// The crawl's conditional sentences (PLAN.md G8 notes), overlaid at the
/// map slot's top-left: each note reads over the map without ever resizing
/// it, so a note appearing or leaving never nudges the tile the hero stands
/// on.
class _NotesOverlay extends StatelessWidget {
  const _NotesOverlay({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 6,
      left: 8,
      right: 60,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: crawlBackground.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(note, style: textLineDim),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
/// beneath it, and Drink was live on both. The Drink and Wait entries below
/// carry the merge's whole mechanism: each gains the guard its other half
/// already had, so both render from exactly one guard, never two.
List<CrawlAction> _actionsFor(
  BuildContext context,
  GameBloc bloc,
  GameViewState state,
) {
  final isBattleOpen = state.isBattleOpen;
  final firstPotion = state.firstPotion;
  final node = state.nodeUnderfoot;
  final readied = state.knownSpells.take(readiedSpellCount);
  final ending = state.canLeave && state.isAtTheBottom;
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
    if (isBattleOpen)
      CrawlAction(
        id: 'wait',
        label: 'Wait',
        mark: const ShippedMark(ActionIcon.wait),
        onPressed: () => bloc.add(const WaitPressed()),
      ),
    if (state.canPickUp)
      CrawlAction(
        id: 'pick-up',
        label: 'Pick up',
        mark: const FontMark(Icons.back_hand),
        onPressed: () => bloc.add(const PickUpPressed()),
      ),
    if (state.canGather)
      CrawlAction(
        id: 'gather',
        label: node!.verb,
        mark: FontMark(node == GatherKind.oreVein ? Icons.hardware : Icons.spa),
        onPressed: () => bloc.add(const GatherPressed()),
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
    if (state.isEncounter && !state.isRoadClear && !isBattleOpen)
      CrawlAction(
        id: 'wait',
        label: 'Wait',
        mark: const ShippedMark(ActionIcon.wait),
        onPressed: () => bloc.add(const WaitPressed()),
      ),
    if (state.canFlee)
      CrawlAction(
        id: 'flee',
        label: 'Flee',
        mark: const FontMark(Icons.directions_run),
        onPressed: () => bloc.add(const FleePressed()),
      ),
    if (state.isRoadClear)
      CrawlAction(
        id: 'move-on',
        label: 'Move on',
        mark: const FontMark(Icons.hiking),
        onPressed: () =>
            leaveEncounter(context, state, EncounterEnding.cleared),
      ),
    if (state.canAscend)
      CrawlAction(
        id: 'ascend',
        label: 'Ascend <',
        mark: const ShippedMark(ActionIcon.ascend),
        onPressed: () => bloc.add(const AscendPressed()),
      ),
    if (state.canDescend)
      CrawlAction(
        id: 'descend',
        label: 'Descend >',
        mark: const ShippedMark(ActionIcon.descend),
        onPressed: () => bloc.add(const DescendPressed()),
      ),
    if (state.canLeave)
      CrawlAction(
        id: 'leave-dungeon',
        label: ending ? doneControl : 'Leave',
        mark: FontMark(ending ? Icons.flag : Icons.logout),
        onPressed: () => ending
            ? _confirmCompletion(context, state)
            : suspendDungeon(context, state),
      ),
  ];
}

/// The crawl's conditional notice sentences, in the same order and under the
/// same conditions as before the merge.
List<String> _notesFor(GameViewState state) {
  final node = state.nodeUnderfoot;
  final underfoot = state.itemsUnderfoot;
  return [
    if (state.canLeave && state.isAtTheBottom) doneAtTheBottom,
    if (node != null) 'Underfoot: ${node.marking} ${node.word}',
    if (underfoot.isNotEmpty)
      underfoot.length == 1
          ? 'Here: ${underfoot.last.displayName}'
          : 'Here: ${underfoot.last.displayName} '
                'and ${underfoot.length - 1} more',
  ];
}

/// Hands the finished run back to the town and uncovers the town screen.
///
/// The town was never torn down — entering the dungeon pushed the crawl on top
/// of it — so coming home is one pop and one event, and there is exactly one
/// place in the app that does it.
///
/// Two things reach it: the death overlay, and walking out from the bottom
/// floor once the confirm has been answered. [suspendDungeon] is the third way
/// out and the difference is what the delve has left in it — a floor below means
/// the crawl stands and waits, and nothing below means the delve is finished.
void leaveDungeon(
  BuildContext context,
  GameViewState state, {
  required bool died,
}) {
  context.read<TownBloc>().add(RunEnded(state.game, died: died));
  Navigator.of(context).pop();
}

/// Walks the hero out at the stairs and uncovers the town, leaving the crawl
/// standing.
///
/// Structurally [leaveDungeon]: one pop and one event, from one place in the app,
/// because the town was never torn down. What differs is what the town is told —
/// and only the town decides what it means. Here the hero comes home and the
/// dungeon keeps its floors, its monsters, its fog and both its random streams,
/// waiting on the town's door to be pressed again.
///
/// Offered only where `canLeave` is, which is a stairs landing with a living
/// hero. That gate is also `suspendRun`'s precondition, so the one place that
/// calls it is the one place that cannot break it.
void suspendDungeon(BuildContext context, GameViewState state) {
  context.read<TownBloc>().add(
    RunSuspended(
      state.game,
      day: context.read<WorldBloc>().state.world.day,
      dungeon: context.read<GameBloc>().dungeon!,
    ),
  );
  Navigator.of(context).pop();
}

/// What the control that ends a delve says.
///
/// **Six characters, and a device pass is why.** The row divides by how many
/// controls apply and the bottom floor can hold five of them — pick up, drink,
/// pack, ascend and this — which leaves each about eight characters on a phone.
/// The spec's "Leave — the delve is done" rendered as "Leave — t…"; the first
/// try at fixing it, "Leave — done", still rendered as "Leave — do…", which is
/// the same defect one word shorter. The whole sentence lives on the line above
/// and in the dialog, both of which have room for it, so the control only has
/// to be short and unmistakably not "Leave".
const String doneControl = 'Finish';

/// What the bottom stairs say while the hero is standing on them.
///
/// **A status, not a moment.** It shows whenever the hero stands where there is
/// nothing below, including after walking back into a camp on that floor —
/// where the beat, which is a moment, has already been and gone. The pairing is
/// deliberate: a player who resumed into the bottom floor missed the line that
/// marked getting there and must still be told what the door does.
///
/// It lives on its own row rather than on the control, because the control is
/// one of up to five sharing a line and a sentence there ellipsises down to
/// nonsense — which is what two device passes have already found on this exact
/// row.
const String doneAtTheBottom = 'The delve is done. Leaving here ends it.';

/// Ends the delve, alive, after asking once.
///
/// **The first irreversible confirm in the crawl, and that is why it asks.**
/// Every other way out of a dungeon either costs nothing to undo — walking out
/// at the stairs leaves the crawl standing — or is not a decision at all. This
/// one spends the floors, and a mis-tap on a shared control row must not.
Future<void> _confirmCompletion(
  BuildContext context,
  GameViewState state,
) async {
  final done = await showCrawlConfirm(
    context,
    title: 'The delve is done. Leave with your spoils?',
    body:
        'There is nothing below this floor, so walking out ends the delve '
        'rather than leaving it standing. Everything you carry comes with '
        'you.',
    dismiss: 'Stay down here',
    confirm: 'Leave with them',
  );
  if (!done || !context.mounted) return;
  leaveDungeon(context, state, died: false);
}

/// Ends a road fight and uncovers the world screen under it.
///
/// Structurally [leaveDungeon]: one pop from one place in the app, because the
/// world was never torn down. What differs is that a fight has two owners to
/// tell rather than one. The hero is the town's — [endRun] brings them home with
/// whatever they picked up, or without what dying costs — and the journey is the
/// world's, which picks it back up from the same leg or ends it at the hero's own
/// front door.
///
/// All three endings come through here, which is the point of it. Walking off
/// the edge, killing the last creature and dying are three different sentences
/// and one shape, and a second place that ended a fight would eventually be the
/// place that told only one of the two blocs.
void leaveEncounter(
  BuildContext context,
  GameViewState state,
  EncounterEnding ending,
) {
  context.read<TownBloc>().add(
    EncounterEnded(state.game, died: ending == EncounterEnding.died),
  );
  context.read<WorldBloc>().add(RoadFightOver(ending));
  Navigator.of(context).pop();
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
