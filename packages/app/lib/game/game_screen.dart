import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../town/town_bloc.dart';
import '../world/world_bloc.dart';
import 'game_bloc.dart';
import 'battle_view.dart';
import 'glyph_grid.dart';
import 'inventory_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

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
                      if (state.isBattleOpen) BattleDock(state: state),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: GlyphGrid(
                            state: state,
                            palette: paletteFor(bloc.dungeon),
                            onTap: (position) => bloc.add(TileTapped(position)),
                            onPan: (delta) => bloc.add(MapPanned(delta)),
                          ),
                        ),
                      ),
                      if (state.isBattleOpen && state.knownSpells.isNotEmpty)
                        BattleSkillBar(state: state, bloc: bloc),
                      _HitPoints(state: state),
                      _Controls(state: state),
                      _MessageLog(log: state.log),
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
  );
}

class _HitPoints extends StatelessWidget {
  const _HitPoints({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final hero = state.game.hero;
    final ceiling = state.maxHp;
    final fraction = ceiling == 0 ? 0.0 : hero.hp / ceiling;
    final shown = hero.hp.clamp(0, ceiling);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1),
                minHeight: 14,
                backgroundColor: const Color(0xFF23262E),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFDDE1E7)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _line(shown, ceiling, fraction, context, state),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Color(0xFFDDE1E7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The whole status line as one string, so it can be scaled as one thing.
  ///
  /// **Four texts in a row became one, and the reason is a device pass.** The
  /// row used to be a stretched bar and three fixed labels, which fitted while
  /// the middle one read `Depth 3/5`. Naming the dungeon made it fifteen
  /// characters longer, and a floor with something in sight overflowed a phone
  /// by sixty-four pixels — the widget tests never saw it, because their surface
  /// is wider than a phone is.
  ///
  /// One string inside a scale-down box shrinks instead of clipping, which keeps
  /// every word on screen. Nothing is ellipsised: the M2 device pass already
  /// found that a truncated label throws away exactly the part the player cannot
  /// get anywhere else.
  static String _line(
    int shown,
    int ceiling,
    double fraction,
    BuildContext context,
    GameViewState state,
  ) {
    final engaged = state.enemiesInSight > 0
        ? '  Engaged ${state.enemiesInSight}'
        : '';
    return '$shown / $ceiling  ${_condition(fraction)}  '
        '${_whereabouts(context, state)}$engaged${_magic(state)}';
  }

  /// The pool and the ward, as words and numbers, and only when they say
  /// something.
  ///
  /// **Not a sixth control**, because the control row is full and a device pass
  /// has twice found the sixth thing on a phone row ellipsised down to nonsense.
  /// It joins the status line instead, which shrinks to fit rather than
  /// truncating.
  ///
  /// **Silent for a hero who knows no spells**, which is every hero until they
  /// read their first book. A pool nobody can spend is a number in the way, and
  /// leaving it out means the line a non-casting hero reads is exactly the line
  /// that shipped before magic did. The ward joins it only while one stands, for
  /// the same reason and because a ward is the one piece of state a player has
  /// to be able to see mid-fight.
  static String _magic(GameViewState state) {
    if (state.game.knownSpells.isEmpty) return '';
    final ward = state.warded > 0 ? '  Ward ${state.warded}' : '';
    return '  Mana ${state.mana}/${state.maxMana}$ward';
  }

  /// Where the hero is standing, in words and a depth.
  ///
  /// **The dungeon is named, because there are three of them now.** A hero
  /// three floors down needs to know three floors down *what* — the crypt and
  /// the keep are opposite ends of the world and a bare "Depth 3/5" reads the
  /// same in both. A road fight keeps "The road", which is the whole of where
  /// it is.
  ///
  /// **The total is the delve's own, not a constant.** A themed delve rolls how
  /// deep it goes, so "depth 3/6" and "depth 3/5" are two different places to be
  /// standing and the second number is the only thing that says which. It also
  /// tells the player how much is left, which is the whole reason to print a
  /// total at all.
  static String _whereabouts(BuildContext context, GameViewState state) {
    if (state.isEncounter) return 'The road';
    final depth = 'depth ${state.depth}/${state.deepest}';
    final node = context.read<GameBloc>().dungeon;
    if (node == null) return 'Depth ${state.depth}/${state.deepest}';
    return '${residuumWorld.nodeAt(node).name} — $depth';
  }

  static String _condition(double fraction) {
    if (fraction <= 0) return 'Dead';
    if (fraction < 0.25) return 'Critical';
    if (fraction < 0.6) return 'Wounded';
    return 'Steady';
  }
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
  const _Controls({required this.state});

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
                        child: const InventoryScreen(),
                      ),
                    ),
                  ),
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
              if (state.isEncounter && !state.isRoadClear)
                Expanded(
                  child: _Control(
                    label: 'Wait',
                    onPressed: () =>
                        context.read<GameBloc>().add(const WaitPressed()),
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
    RunSuspended(state.game, day: context.read<WorldBloc>().state.world.day),
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

class _MessageLog extends StatelessWidget {
  const _MessageLog({required this.log});

  final List<String> log;

  @override
  Widget build(BuildContext context) => Container(
    height: 104,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    color: const Color(0xFF15181F),
    child: ListView.builder(
      reverse: true,
      itemCount: log.length,
      itemBuilder: (context, index) => Text(
        log[log.length - 1 - index],
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Color(index == 0 ? 0xFFE6EAF0 : 0xFF8A919E),
        ),
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
