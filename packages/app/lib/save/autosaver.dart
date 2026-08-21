import 'dart:async';

import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../game/game_bloc.dart';
import '../town/town_bloc.dart';
import 'boot.dart';
import 'save_store.dart';

/// Writes the game down whenever it changes.
///
/// It holds the profile and the suspended crawl itself rather than reading them
/// off either bloc, because at boot there is a crawl to resume and no town
/// emission to learn it from: a resumed run exists before the town has said
/// anything at all. Seeding both from the boot document and updating each from
/// its own bloc is what makes the first save after a relaunch describe the
/// crawl the player is standing in rather than an empty town.
class Autosaver {
  Autosaver(this._store, {required Boot from})
    : _roster = from.document,
      _profile = from.profile,
      _run = from.run;

  final SaveStore _store;
  final List<StreamSubscription<Object?>> _watching = [];

  /// Every hero, so the ones nobody is playing are written back out as they were.
  final SaveDocument _roster;

  Profile _profile;
  GameState? _run;
  Future<void> _queue = Future<void>.value();

  /// Saves after every town emission.
  ///
  /// Always, rather than only on the ones that changed something. Transactions
  /// are rare and each one moves gold or gear the player chose to move, so there
  /// is nothing to gain by working out which emissions were nothing — and the
  /// one that got the test wrong would be a purchase the player paid for and
  /// then lost.
  ///
  /// A hero who has just been given up is the exception: that state exists to
  /// tell the session to wipe both slots, so writing it would put the abandoned
  /// hero straight back on disk.
  void watchTown(TownBloc town) {
    _profile = town.state.profile;
    _watching.add(
      town.stream.listen((state) {
        if (state.abandoned) return;
        _profile = state.profile;
        _run = state.run;
        saveNow();
      }),
    );
  }

  /// Saves after every settled change to the crawl.
  ///
  /// Every step, not every few. A suspend save that lags one step puts the
  /// player back into a fight they already watched resolve — the monster they
  /// killed is alive again, or the blow that landed has not — and both streams
  /// would be a roll out of line with the board they are drawn against.
  ///
  /// Emissions that leave the game state untouched are skipped, because a
  /// dragged camera is not a turn and the document would be identical.
  void watchGame(GameBloc game) {
    _run = game.state.game;
    _watching.add(
      game.stream.listen((state) {
        if (state.game == _run) return;
        _run = state.game;
        saveNow();
      }),
    );
  }

  /// Writes the whole roster with the active hero brought up to date.
  ///
  /// The active hero's entry is replaced inside the document the session booted
  /// with, rather than a document built from the active hero alone. A save that
  /// wrote only the hero being played would delete every other hero on the
  /// install, once per turn, and nothing on screen would say so.
  ///
  /// Queued rather than overlapped. Two writes in flight at once could finish
  /// out of order and leave the older document in the current slot, which is the
  /// one failure a save layer must not have.
  void saveNow() {
    final document = _roster.replacingActive(_profile, _run);
    _queue = _queue.then((_) async {
      await _store.save(document);
    });
  }

  /// Completes when every queued write has finished.
  Future<void> settled() => _queue;

  /// Stops watching. Any write already queued still finishes.
  Future<void> close() async {
    for (final subscription in _watching) {
      await subscription.cancel();
    }
    _watching.clear();
    await _queue;
  }
}
