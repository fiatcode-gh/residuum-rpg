import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'game/game_bloc.dart';
import 'game/game_screen.dart';
import 'save/autosaver.dart';
import 'save/boot.dart';
import 'save/save_files_io.dart';
import 'save/save_store.dart';
import 'town/roster_screen.dart';
import 'town/town_bloc.dart';
import 'town/town_screen.dart';
import 'world/world_bloc.dart';
import 'world/world_screen.dart';

Future<void> main() async {
  final store = SaveStore(IoSaveFiles());
  final boot = await bootFrom(store, rollWorldSeed: rollWorldSeedFromClock);
  runApp(ResiduumApp(store: store, boot: boot));
}

/// The app, and the one thing it can do that no screen can: play somebody else.
///
/// Stateful because switching, creating or deleting a hero replaces every bloc in
/// the tree at once.
class ResiduumApp extends StatefulWidget {
  const ResiduumApp({required this.store, required this.boot, super.key});

  final SaveStore store;
  final Boot boot;

  @override
  State<ResiduumApp> createState() => _ResiduumAppState();
}

class _ResiduumAppState extends State<ResiduumApp> {
  late Boot _boot = widget.boot;
  int _generation = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Residuum',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E1014),
      useMaterial3: true,
    ),
    home: _Session(
      key: ValueKey(_generation),
      store: widget.store,
      boot: _boot,
      onRoster: _rosterChose,
    ),
  );

  /// Carries out what the roster answered with, and rebuilds the session onto it.
  ///
  /// **The generation counter goes into the session's key so that every bloc and
  /// the autosaver are torn down rather than re-pointed.** A session handed a
  /// different hero would still be holding the old hero's town bloc, the old
  /// autosaver watching it, and the old crawl's log — and the first thing that
  /// autosaver did would be to write the new hero's document with the old hero's
  /// profile inside it. Bumping the key makes switching hero the same operation
  /// as launching the app on that hero, which is the only version of it that has
  /// one code path.
  ///
  /// The [document] comes up from the session rather than being read from
  /// [_boot], because the boot's copy is as old as the launch: the hero being
  /// played has spent gold and taken wounds since, and editing the stale copy
  /// would hand those back on the way out.
  ///
  /// **The roster must be pushed only over the navigator's bottom route, and
  /// this is why.** Bumping the generation swaps the session under `home:`, and
  /// a generation bump does not clear routes pushed on top of it — so a roster
  /// reached through a pushed screen would leave the new hero's world sitting
  /// underneath the old hero's route, holding blocs that [_SessionState.dispose]
  /// has just closed. The Heroes door therefore lives on the world screen, which
  /// *is* the bottom route, and nowhere else.
  Future<void> _rosterChose(RosterChoice chosen, SaveDocument document) async {
    final fresh = switch (chosen) {
      PlayHero(:final id) => await switchHero(widget.store, document, id),
      DropHero(:final id) => await deleteHero(widget.store, document, id),
      MakeHero(:final label, :final replacing) =>
        replacing == null
            ? await createHero(
                widget.store,
                document,
                label: label,
                rollWorldSeed: rollWorldSeedFromClock,
              )
            : await replaceOnlyHero(
                widget.store,
                document,
                label: label,
                rollWorldSeed: rollWorldSeedFromClock,
              ),
    };
    if (fresh == null || !mounted) return;
    setState(() {
      _boot = fresh;
      _generation++;
    });
  }
}

/// One hero's session: the town, the autosaver, and every door into a crawl.
///
/// Entering the dungeon, walking back into a camp, giving one up, and booting
/// into a crawl the app was killed inside all live here rather than on the town
/// screen, because every one of them builds a [GameBloc] and the autosaver has to
/// be watching it. Two places that made one would eventually disagree about
/// whether the crawl was being written down.
class _Session extends StatefulWidget {
  const _Session({
    required this.store,
    required this.boot,
    required this.onRoster,
    super.key,
  });

  final SaveStore store;
  final Boot boot;

  /// Carries out what the roster answered with, on the document as it stands.
  final Future<void> Function(RosterChoice, SaveDocument) onRoster;

  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> {
  /// The town, holding the camp when the hero booted out of their crawl.
  ///
  /// The crawl goes to one owner or the other and never both: a hero standing in
  /// it hands it to the [GameBloc] that opens below, and a hero camped away from
  /// it hands it to the town, whose door is the only way back.
  late final TownBloc _town = TownBloc(
    profile: widget.boot.profile,
    town: _townFor(widget.boot.world),
    merchant: widget.boot.merchant,
    notice: widget.boot.notice,
    suspended: widget.boot.inside ? null : widget.boot.run,
  );

  /// Where the hero is in the world, and every day they spend walking it.
  ///
  /// Beside the town rather than under it. The town owns the hero and this owns
  /// the map; the two are told apart everywhere, and the places one press moves
  /// both — a rumor, a fight ending — hand each half to its owner.
  late final WorldBloc _world = WorldBloc(
    world: widget.boot.world,
    worldSeed: widget.boot.profile.worldSeed,
  );
  late final Autosaver _saver = Autosaver(widget.store, from: widget.boot);

  /// The town whose shelf the hero should be looking at.
  ///
  /// A hero standing on a road or at the crypt is at no town, and the shop they
  /// last stood in is the honest answer — it is the one whose remembered
  /// purchases are still theirs. `home` is exactly that: the last town stood in.
  static NodeId _townFor(Whereabouts world) =>
      residuumWorld.nodeAt(world.at).kind == NodeKind.town
      ? world.at
      : world.home;

  /// Attaches the autosaver to the town before anything can be pressed.
  ///
  /// It has to happen here and not in the field's own initializer: a
  /// `late final` field is built the first time it is read, and nothing on the
  /// town screen reads this one — so the autosaver would sit unbuilt, watching
  /// nothing, until the first crawl opened, and every transaction before that
  /// would go unwritten.
  @override
  void initState() {
    super.initState();
    _saver.watchTown(_town);
    _saver.watchWorld(_world);
    if (widget.boot.inside) {
      final run = widget.boot.run!;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openCrawl(run, resumed: true),
      );
    }
  }

  @override
  void dispose() {
    _saver.close();
    _town.close();
    _world.close();
    super.dispose();
  }

  /// The world screen, with a fight opened over it whenever the road produces
  /// one, and the town told whenever the hero walks into one.
  ///
  /// Both listeners live here rather than on the screen because both are about
  /// what happens *between* blocs, which is the session's whole job. The screen
  /// draws; this wires.
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _town),
      BlocProvider.value(value: _world),
    ],
    child: MultiBlocListener(
      listeners: [
        BlocListener<WorldBloc, WorldViewState>(
          listenWhen: (before, after) =>
              before.fight == null && after.fight != null,
          listener: (context, state) => _openRoadFight(state.world.day),
        ),
        BlocListener<WorldBloc, WorldViewState>(
          listenWhen: (before, after) => before.world.at != after.world.at,
          listener: (context, state) {
            if (residuumWorld.nodeAt(state.world.at).kind == NodeKind.town) {
              _town.add(ArrivedInTown(state.world.at));
            }
          },
        ),
      ],
      child: WorldScreen(
        onEnterTown: _enterTown,
        onEnterDungeon: _enterDungeon,
        onResumeCrawl: _resumeCrawl,
        onDelveAnew: _delveAnew,
        onOpenRoster: _openRoster,
      ),
    ),
  );

  /// Pushes the town over the world.
  ///
  /// The world is never torn down, so leaving town is one pop — the same shape
  /// the crawl has used since it was first pushed over something.
  Future<void> _enterTown() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _town),
          BlocProvider.value(value: _world),
        ],
        child: const TownScreen(),
      ),
    ),
  );

  /// Opens the fight the road produced on [day], over the world screen.
  ///
  /// **The autosaver is deliberately not watching it.** A road fight is never
  /// written down: it is re-derived from the world seed and the day counter, both
  /// of which the world block already holds, so an app killed mid-fight comes
  /// back to the same day and a fresh fight rather than to a half-resolved one.
  /// That is the one crawl in the app that `_openCrawl` must not be used for, and
  /// this is why there are two functions rather than a flag on one.
  ///
  /// The fight's own bloc is closed when the route comes back, exactly as a
  /// crawl's is.
  Future<void> _openRoadFight(int day) async {
    final fight = GameBloc(
      game: startRoadEncounter(_town.state.profile, day: day),
      log: const [roadOpeningLog],
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _town),
            BlocProvider.value(value: _world),
            BlocProvider.value(value: fight),
          ],
          child: const GameScreen(),
        ),
      ),
    );
    await fight.close();
  }

  /// Opens the roster on the document as it stands, and acts on the answer.
  ///
  /// The document comes from the autosaver rather than from the boot, because the
  /// boot's copy is as old as the launch: the hero being played has spent gold and
  /// taken wounds since, and the roster would print the numbers they walked in
  /// with. The autosaver is the one object holding both the roster and the live
  /// hero, so it is the one that can answer the question.
  ///
  /// The saver is closed before anything is written, exactly as giving a hero up
  /// used to be: the rebuild tears the autosaver down, and a write still queued
  /// when the document changed underneath it would put the hero who was just left
  /// back over the hero who was just chosen.
  Future<void> _openRoster() async {
    final chosen = await Navigator.of(context).push<RosterChoice>(
      MaterialPageRoute<RosterChoice>(
        builder: (_) => RosterScreen(document: _saver.document),
      ),
    );
    if (chosen == null || !mounted) return;
    await _saver.close();
    await widget.onRoster(chosen, _saver.document);
  }

  Future<void> _enterDungeon() async =>
      _openAnswer(const EnterDungeonPressed(), resumed: false);

  Future<void> _resumeCrawl() async =>
      _openAnswer(const ResumeCrawlPressed(), resumed: true);

  Future<void> _delveAnew() async =>
      _openAnswer(const DelveAnewPressed(), resumed: false);

  /// Presses one of the town's doors and opens whatever crawl it answers with.
  ///
  /// Three doors, one shape, because the difference between them is entirely the
  /// town's business: which crawl comes back is a rule, and all the session has
  /// to know is that a crawl came back. Waiting on the emission rather than
  /// reading the state straight after is what makes it the town's answer and not
  /// a guess about when a bloc has caught up.
  ///
  /// [resumed] is not derived from the event, because it says something the event
  /// does not: whether the log opens with a line explaining itself. Delving anew
  /// is a fresh crawl the player asked for and has nothing to explain, even
  /// though it starts from a camp.
  Future<void> _openAnswer(TownBlocEvent door, {required bool resumed}) async {
    _town.add(door);
    await _town.stream.firstWhere((state) => state.run != null);
    if (!mounted) return;
    await _openCrawl(_town.state.run!, resumed: resumed);
  }

  /// Puts the crawl on top of the town.
  ///
  /// The town is never torn down — the crawl is pushed over it — so leaving is
  /// one pop, which is the architecture `suspendDungeon` documents.
  ///
  /// **Every crawl in the app is opened here, and there are now four ways in:**
  /// booting into one the app was killed inside, walking into a fresh one,
  /// walking back into a camp, and giving a camp up for a fresh one. They share
  /// this function because they share the one thing that must not be forgotten —
  /// the autosaver has to be watching the bloc before the player can take a turn
  /// in it — and a second place that built a [GameBloc] would eventually be the
  /// place that forgot.
  ///
  /// The message log does not survive a suspend, because it is view state the
  /// app owns rather than anything the rules produced. A [resumed] crawl
  /// therefore opens with one line saying so, rather than with a history it
  /// would have to invent; a crawl being entered for the first time opens on an
  /// empty log, because nothing has happened in it yet.
  Future<void> _openCrawl(GameState run, {required bool resumed}) async {
    final game = GameBloc(game: run, log: resumed ? _openingLog() : const []);
    _saver.watchGame(game);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _town),
            BlocProvider.value(value: _world),
            BlocProvider.value(value: game),
          ],
          child: const GameScreen(),
        ),
      ),
    );
    await game.close();
  }

  /// What a resumed crawl opens its log with.
  ///
  /// The fallback report has to appear here as well as on the town screen. A
  /// save that fell back to the older slot may well hold a crawl, and then the
  /// player never sees the town: they are put straight into the dungeon, and by
  /// the time they walk out of it, ending the run has built a fresh town state
  /// with no notice on it. The log is the only place left to say it, so it says
  /// it.
  ///
  /// It says it once. The notice is a fact about the launch, not about this
  /// crawl, and a hero who walks out and back in twice would otherwise be told
  /// three times that a save was recovered an hour ago.
  List<String> _openingLog() {
    final report = _reported ? null : widget.boot.notice;
    _reported = true;
    return [
      if (report case final String recovered) _asSentence(recovered),
      _resumed,
    ];
  }

  /// The town's phrasing, turned into a line of the message log.
  ///
  /// One wording, two renderings. A notice is written to sit inside the town's
  /// `— ….` frame, so it is lowercase and unpunctuated; the log has no frame and
  /// its lines are sentences. Wording it twice would let the two drift.
  static String _asSentence(String notice) =>
      '${notice[0].toUpperCase()}${notice.substring(1)}.';

  static const String _resumed = 'The crawl resumes.';

  bool _reported = false;
}
