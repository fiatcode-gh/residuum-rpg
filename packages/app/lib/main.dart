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
  late final TownBloc _town = TownBloc(
    profile: widget.boot.profile,
    merchant: widget.boot.merchant,
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
    child: TownScreen(onEnterDungeon: _enterDungeon, onOpenRoster: _openRoster),
  );

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

  static const String _resumed = 'The crawl resumes.';
}
