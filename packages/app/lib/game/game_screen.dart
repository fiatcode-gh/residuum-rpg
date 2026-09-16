import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../town/town_bloc.dart';
import '../world/world_bloc.dart';
import 'battle_view.dart';
import 'crawl_status.dart';
import 'dungeon_palette.dart';
import 'dungeon_scene.dart';
import 'game_bloc.dart';
import 'log_drawer.dart';
import 'log_line.dart';
import 'grid_geometry.dart';
import 'pack_screen.dart';
import 'spell_row.dart';
import '../town/town_style.dart' show ink, dim;

const recenterKey = Key('recenter');
const shelfKey = Key('battle-shelf');
const overflowKey = Key('shelf-overflow');
const shelfWaitKey = Key('shelf-wait');
const controlsKey = Key('crawl-controls');

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
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<GameBloc, GameViewState>(
            builder: (context, state) {
              final bloc = context.read<GameBloc>();
              return Stack(
                children: [
                  Column(
                    children: [
                      if (state.isBattleOpen)
                        BattleDock(
                          state: state,
                          onActorSelected: (actor) {
                            final presentation = state.presentationOf(actor.id);
                            if (presentation == null) return;
                            bloc.add(TimelineActorSelected(actor.id));
                            showEnemyInfo(context, actor, presentation);
                          },
                        ),
                      Expanded(
                        key: dungeonSceneSlotKey,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: LayoutBuilder(
                            builder: (mapContext, constraints) {
                              final size = constraints.biggest;
                              return Stack(
                                children: [
                                  DungeonSceneHost(
                                    key: dungeonSceneHostKey,
                                    state: state,
                                    palette: palette,
                                    onTap: (position) => _onMapTap(
                                      context,
                                      bloc,
                                      state,
                                      position,
                                    ),
                                    onPan: (delta) =>
                                        bloc.add(MapPanned(delta)),
                                    onLongPress: (position) => _onMapLongPress(
                                      context,
                                      state,
                                      position,
                                    ),
                                  ),
                                  if (_heroOffScreen(state, size))
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: FloatingActionButton.small(
                                        key: recenterKey,
                                        onPressed: () =>
                                            bloc.add(const RecenterPressed()),
                                        child: const Icon(
                                          Icons.center_focus_strong,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      if (state.isBattleOpen)
                        BattleShelf(state: state, bloc: bloc),
                      CrawlStatus(state: state, dungeon: bloc.dungeon),
                      LogPeek(key: logPeekKey, state: state, bloc: bloc),
                      _Controls(key: controlsKey, state: state),
                    ],
                  ),
                  if (state.logDrawerExtent != LogDrawerExtent.peek)
                    LogDrawer(key: logDrawerKey, state: state, bloc: bloc),
                  if (state.game.isGameOver) _DeathOverlay(state: state),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Routes a map tap: all meaning stays in the bloc; only inspection is routed
/// here, because it is presentation-only.
///
/// Armed, the tap is the bloc's to decide — cast at a marked monster or
/// disarm. Bare, a tap on a monster beyond one orthogonal step is the enemy's
/// numbers, and a tap on an adjacent monster is the bump the bloc answers.
void _onMapTap(
  BuildContext context,
  GameBloc bloc,
  GameViewState state,
  Position position,
) {
  if (state.armedSpellId != null) {
    bloc.add(TileTapped(position));
    return;
  }
  final monster = state.inspectTargetAt(position);
  final adjacent = state.game.hero.position.isOrthogonallyAdjacentTo(position);
  if (monster != null && !adjacent) {
    final presentation = state.presentationOf(monster.id);
    if (presentation != null) {
      showEnemyInfo(context, monster, presentation);
    }
    return;
  }
  bloc.add(TileTapped(position));
}

/// Opens the enemy's numbers under the long-press, at no turn cost.
void _onMapLongPress(
  BuildContext context,
  GameViewState state,
  Position position,
) {
  if (state.inspectTargetAt(position) case final Actor monster) {
    final presentation = state.presentationOf(monster.id);
    if (presentation != null) {
      showEnemyInfo(context, monster, presentation);
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

/// The one row of controls the crawl needs, each appearing only when it can do
/// something.
///
/// A control that is visible but inert teaches the player nothing; a control
/// that appears exactly when it applies is how the rules explain themselves. The
/// pack is the exception and is always reachable, because looking at what you
/// are carrying is not an action and should never be gated.
///
/// Labels are short because the row divides by how many controls apply, and on
/// the stairs with something underfoot that is four ways. 'Drink potion (2)'
/// ellipsized to 'Drink poti…' there, which threw away the count — the one part
/// of that label the player cannot get anywhere else.

class _Controls extends StatelessWidget {
  const _Controls({required this.state, super.key});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final underfoot = state.itemsUnderfoot;
    final node = state.nodeUnderfoot;
    final potion = state.firstPotion;
    final ending = state.canLeave && state.isAtTheBottom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          if (ending)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                doneAtTheBottom,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF8A919E),
                ),
              ),
            ),
          if (node != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Underfoot: ${node.marking} ${node.word}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF8A919E),
                ),
              ),
            ),
          if (underfoot.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                underfoot.length == 1
                    ? 'Here: ${underfoot.last.displayName}'
                    : 'Here: ${underfoot.last.displayName} '
                          'and ${underfoot.length - 1} more',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF8A919E),
                ),
              ),
            ),
          Row(
            children: [
              if (state.canPickUp)
                Expanded(
                  child: _Control(
                    label: 'Pick up',
                    onPressed: () => bloc.add(const PickUpPressed()),
                  ),
                ),
              if (state.canGather)
                Expanded(
                  child: _Control(
                    label: node!.verb,
                    onPressed: () => bloc.add(const GatherPressed()),
                  ),
                ),
              if (potion != null)
                Expanded(
                  child: _Control(
                    label: 'Drink (${state.potionCount})',
                    onPressed: state.game.isGameOver
                        ? null
                        : () => bloc.add(const QuickDrinkPressed()),
                  ),
                ),
              Expanded(
                child: _Control(
                  label: 'Pack (${state.game.inventory.length})',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: bloc,
                        child: const CrawlPackScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.isEncounter &&
                  !state.isRoadClear &&
                  !state.isBattleOpen)
                Expanded(
                  child: _Control(
                    label: 'Wait',
                    onPressed: () =>
                        context.read<GameBloc>().add(const WaitPressed()),
                  ),
                ),
              if (state.canFlee)
                Expanded(
                  child: _Control(
                    label: 'Flee',
                    onPressed: () =>
                        context.read<GameBloc>().add(const FleePressed()),
                  ),
                ),
              if (state.isRoadClear)
                Expanded(
                  child: _Control(
                    label: 'Move on',
                    onPressed: () =>
                        leaveEncounter(context, state, EncounterEnding.cleared),
                  ),
                ),
              if (state.canAscend)
                Expanded(
                  child: _Control(
                    label: 'Ascend <',
                    onPressed: () => bloc.add(const AscendPressed()),
                  ),
                ),
              if (state.canDescend)
                Expanded(
                  child: _Control(
                    label: 'Descend >',
                    onPressed: () => bloc.add(const DescendPressed()),
                  ),
                ),
              if (state.canLeave)
                Expanded(
                  child: _Control(
                    label: ending ? doneControl : 'Leave',
                    onPressed: () => ending
                        ? _confirmCompletion(context, state)
                        : suspendDungeon(context, state),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
  final done = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text(
        'The delve is done. Leave with your spoils?',
        style: TextStyle(fontFamily: 'monospace'),
      ),
      content: const Text(
        'There is nothing below this floor, so walking out ends the delve '
        'rather than leaving it standing. Everything you carry comes with '
        'you.',
        style: TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: const Text(
            'Stay down here',
            style: TextStyle(fontFamily: 'monospace'),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: const Text(
            'Leave with them',
            style: TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    ),
  );
  if (!(done ?? false) || !context.mounted) return;
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

class _Control extends StatelessWidget {
  const _Control({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    ),
  );
}

class _DeathOverlay extends StatelessWidget {
  const _DeathOverlay({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xCC0E1014),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'You died.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              color: Color(0xFFE6EAF0),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'What you carried is gone. What you wore is not.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF8A919E),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => state.isEncounter
                ? leaveEncounter(context, state, EncounterEnding.died)
                : leaveDungeon(context, state, died: true),
            child: Text(state.isEncounter ? 'Wake at home' : 'Return to town'),
          ),
        ],
      ),
    ),
  );
}

/// The one combat shelf: readied abilities, the overflow into the full
/// grimoire, a quick drink, and Wait.
///
/// Consolidation, not restriction: the readied slots are the first few known
/// spells in the pack's own order — school, then name — and the overflow lists
/// every known spell, so nothing a hero knows is unreachable from the shelf.
/// A target spell arms and the map carries the aim; Mend and Ward land on the
/// hero and cast from the row itself.
///
/// The armed state reads by border and word — never a hue — the same grammar
/// the old bar used.
class BattleShelf extends StatelessWidget {
  const BattleShelf({super.key, required this.state, required this.bloc});

  final GameViewState state;
  final GameBloc bloc;

  /// How many known spells sit readied on the shelf before the overflow.
  static const int readiedSpellCount = 3;

  void _onSpell(Spell spell) {
    if (spell.kind == SpellKind.mend || spell.kind == SpellKind.ward) {
      bloc.add(CastPressed(spell.id));
    } else {
      bloc.add(SkillArmed(state.armedSpellId == spell.id ? null : spell.id));
    }
  }

  Widget _shelfButton(Spell spell) {
    final armed = state.armedSpellId == spell.id;
    return TextButton(
      key: Key('shelf-spell-${spell.id}'),
      onPressed: () => _onSpell(spell),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: armed ? const BorderSide(color: ink) : null,
      ),
      child: Text(
        armed
            ? '${spell.school.schoolMarking} ${spell.name} '
                  '${spell.manaCost} — armed'
            : '${spell.school.schoolMarking} ${spell.name} ${spell.manaCost}',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: ink,
        ),
      ),
    );
  }

  Future<void> _openOverflow(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Spells',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: ink,
                    ),
                  ),
                ),
                for (final spell in state.knownSpells)
                  _OverflowRow(
                    spell: spell,
                    armed: state.armedSpellId == spell.id,
                    onCast: () {
                      Navigator.of(sheetContext).pop();
                      _onSpell(spell);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readied = state.knownSpells.take(readiedSpellCount);
    final overflowCount = state.knownSpells.length - readiedSpellCount;
    final potion = state.firstPotion;
    return Padding(
      key: shelfKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (potion != null)
            _ShelfButton(
              label: 'Drink (${state.potionCount})',
              onPressed: state.game.isGameOver
                  ? null
                  : () => bloc.add(const QuickDrinkPressed()),
            ),
          for (final spell in readied) _shelfButton(spell),
          if (overflowCount > 0)
            _ShelfButton(
              key: overflowKey,
              label: '+$overflowCount',
              onPressed: () => _openOverflow(context),
            ),
          _ShelfButton(
            key: shelfWaitKey,
            label: 'Wait',
            onPressed: () => bloc.add(const WaitPressed()),
          ),
        ],
      ),
    );
  }
}

/// One wide shelf button: a word, tappable, in the dock's ink.
class _ShelfButton extends StatelessWidget {
  const _ShelfButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
    child: Text(
      label,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: ink),
    ),
  );
}

/// One row of the overflow grimoire: what the shelf button casts, in full.
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
  Widget build(BuildContext context) => SpellRow(
    spell: spell,
    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: ink),
    dimStyle: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 11,
      color: dim,
    ),
    detail: effectOf(spell),
    trailing: TextButton(
      key: Key('overflow-${spell.id}'),
      onPressed: onCast,
      style: TextButton.styleFrom(
        side: armed ? const BorderSide(color: ink) : null,
      ),
      child: Text(
        armed ? '— armed' : spell.school.schoolMarking,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: ink,
        ),
      ),
    ),
  );
}
