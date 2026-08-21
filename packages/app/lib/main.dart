import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import 'game/game_bloc.dart';
import 'game/game_screen.dart';
import 'save/autosaver.dart';
import 'save/boot.dart';
import 'save/save_files_io.dart';
import 'save/save_store.dart';
import 'town/town_bloc.dart';
import 'town/town_screen.dart';

Future<void> main() async {
  final store = SaveStore(IoSaveFiles());
  final boot = await bootFrom(store, rollWorldSeed: rollWorldSeedFromClock);
  runApp(ResiduumApp(store: store, boot: boot));
}

/// The app, and the one thing it can do that no screen can: start over.
///
/// Stateful because abandoning a hero replaces every bloc in the tree at once.
/// The generation counter goes into the session's key so the old town and its
/// autosaver are torn down rather than reused with a new profile pushed through
/// them.
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
      onAbandoned: _startOver,
    ),
  );

  Future<void> _startOver() async {
    final fresh = await abandonActiveHero(
      widget.store,
      _boot.document,
      rollWorldSeed: rollWorldSeedFromClock,
    );
    if (!mounted) return;
    setState(() {
      _boot = fresh;
      _generation++;
    });
  }
}

/// One hero's session: the town, the autosaver, and both doors into a crawl.
///
/// Entering the dungeon and resuming a suspended crawl both live here rather
/// than on the town screen, because both build a [GameBloc] and the autosaver
/// has to be watching it. Two places that made one would eventually disagree
/// about whether the crawl was being written down.
class _Session extends StatefulWidget {
  const _Session({
    required this.store,
    required this.boot,
    required this.onAbandoned,
    super.key,
  });

  final SaveStore store;
  final Boot boot;
  final Future<void> Function() onAbandoned;

  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> {
  late final TownBloc _town = TownBloc(
    profile: widget.boot.profile,
    notice: widget.boot.notice,
  );
  late final Autosaver _saver = Autosaver(widget.store, from: widget.boot);

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
    if (widget.boot.run case final GameState run) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openCrawl(run, resumed: true),
      );
    }
  }

  @override
  void dispose() {
    _saver.close();
    _town.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _town,
    child: BlocListener<TownBloc, TownViewState>(
      listenWhen: (before, after) => after.abandoned && !before.abandoned,
      listener: (_, _) => _abandon(),
      child: TownScreen(
        onEnterDungeon: _enterDungeon,
        onAbandonHero: () => _town.add(const AbandonHeroConfirmed()),
      ),
    ),
  );

  Future<void> _enterDungeon() async {
    _town.add(const EnterDungeonPressed());
    await _town.stream.firstWhere((state) => state.run != null);
    if (!mounted) return;
    await _openCrawl(_town.state.run!, resumed: false);
  }

  /// Puts the crawl on top of the town.
  ///
  /// The town is never torn down — the crawl is pushed over it — so leaving is
  /// one pop, which is the architecture `leaveDungeon` documents.
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
  List<String> _openingLog() => [
    if (widget.boot.notice case final String report) _asSentence(report),
    _resumed,
  ];

  /// The town's phrasing, turned into a line of the message log.
  ///
  /// One wording, two renderings. A notice is written to sit inside the town's
  /// `— ….` frame, so it is lowercase and unpunctuated; the log has no frame and
  /// its lines are sentences. Wording it twice would let the two drift.
  static String _asSentence(String notice) =>
      '${notice[0].toUpperCase()}${notice.substring(1)}.';

  Future<void> _abandon() async {
    await _saver.close();
    await widget.onAbandoned();
  }

  static const String _resumed = 'The crawl resumes.';
}
