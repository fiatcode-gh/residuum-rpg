import 'dart:async';

import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../game/game_bloc.dart';
import '../town/town_bloc.dart';
import '../world/world_bloc.dart';
import 'boot.dart';
import 'save_store.dart';

/// Writes the game down whenever it changes.
///
/// It holds the profile and the crawl itself rather than reading them off either
/// bloc, because at boot there is a crawl to resume and no town emission to
/// learn it from: a resumed run exists before the town has said anything at all.
/// Seeding both from the boot document and updating each from its own bloc is
/// what makes the first save after a relaunch describe the crawl the player is
/// standing in rather than an empty town.
///
/// Whether the hero is *in* that crawl is held here for the same reason and read
/// off the same two sources. It has to be written down rather than worked out,
/// because a crawl on disk means two opposite things — a hero killed mid-fight,
/// or a hero who walked out at the stairs and left it standing — and the next
/// launch opens a different screen for each.
class Autosaver {
  Autosaver(this._store, {required Boot from})
    : _roster = from.document,
      _profile = from.profile,
      _run = from.run,
      _dungeon = from.dungeon,
      _inside = from.inside,
      _merchant = from.merchant,
      _world = from.world;

  final SaveStore _store;
  final List<StreamSubscription<Object?>> _watching = [];

  /// Every hero, so the ones nobody is playing are written back out as they were.
  final SaveDocument _roster;

  Profile _profile;
  GameState? _run;

  /// Which dungeon [_run] is a crawl of, held for [_run]'s reason: at boot
  /// there is a crawl to resume and no town emission to learn its place from.
  NodeId? _dungeon;
  bool _inside;
  MerchantVisit _merchant;
  Whereabouts _world;
  Future<void> _queue = Future<void>.value();

  /// Saves after every town emission.
  ///
  /// Always, rather than only on the ones that changed something. Transactions
  /// are rare and each one moves gold or gear the player chose to move, so there
  /// is nothing to gain by working out which emissions were nothing — and the
  /// one that got the test wrong would be a purchase the player paid for and
  /// then lost.
  ///
  /// What the merchant remembers of the visit is written with the rest of the
  /// hero, because a purchase that lived only in this bloc would put the whole
  /// shelf back on the next launch.
  ///
  /// The town's two crawl fields answer both questions at once: whichever of
  /// them holds a crawl is the crawl to write down, and *which* of them holds it
  /// is whether the hero is standing in it. A crawl to open now is the hero
  /// walking in; a camp and nothing else is the hero out in town with a dungeon
  /// waiting. One expression each, and no third piece of state to fall out of
  /// step with the screen.
  void watchTown(TownBloc town) {
    _profile = town.state.profile;
    _watching.add(
      town.stream.listen((state) {
        _profile = state.profile;
        _run = state.run ?? state.suspended;
        _dungeon = state.dungeon;
        _inside = state.run != null;
        _merchant = state.merchant;
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
  /// A crawl on screen is a hero standing in it, which is the one thing this can
  /// say that the town cannot. The town's own answer arrives one emission
  /// earlier — pressing a door is not yet being through it — so this is what
  /// makes the document true for every turn after the first.
  void watchGame(GameBloc game) {
    _run = game.state.game;
    _inside = true;
    _watching.add(
      game.stream.listen((state) {
        if (state.game == _run) return;
        _run = state.game;
        _inside = true;
        saveNow();
      }),
    );
  }

  /// Saves after every world emission.
  ///
  /// The world block is a day counter, a place and a set of names — small, and
  /// changed by exactly the things a player would be furious to lose: a day
  /// walked, a place reached, a rumor paid for. So every emission is written, for
  /// the reason every town emission is.
  ///
  /// **What is deliberately not written is the fight.** A road fight is
  /// re-derived from the world seed and the day, so there is nothing about one
  /// worth keeping and nothing here reads `fight`. An app killed mid-fight comes
  /// back to the same day and the same creatures, freshly stood up. Nothing here
  /// watches the fight's own bloc either — see `_openRoadFight`.
  void watchWorld(WorldBloc world) {
    _world = world.state.world;
    _watching.add(
      world.stream.listen((state) {
        if (state.world == _world) return;
        _world = state.world;
        saveNow();
      }),
    );
  }

  /// The whole roster with the active hero brought up to date: the document as
  /// it stands right now.
  ///
  /// The active hero's entry is replaced inside the document the session booted
  /// with, rather than a document built from the active hero alone. A save that
  /// wrote only the hero being played would delete every other hero on the
  /// install, once per turn, and nothing on screen would say so.
  ///
  /// One expression, two readers. This is the only object holding both the roster
  /// it booted with and the active hero's live profile, crawl and visit, so this
  /// is where "the document as it stands" is built — and the roster screen reads
  /// it here rather than assembling a second version that could disagree with
  /// the one being written to disk.
  SaveDocument get document => _roster.replacingActive(
    _profile,
    _run,
    _merchant,
    _world,
    inside: _inside,
    dungeon: _dungeon,
  );

  /// Writes the document down.
  ///
  /// Queued rather than overlapped. Two writes in flight at once could finish
  /// out of order and leave the older document in the current slot, which is the
  /// one failure a save layer must not have.
  void saveNow() {
    final written = document;
    _queue = _queue.then((_) async {
      await _store.save(written);
    });
  }

  /// Completes when every queued write has finished.
  Future<void> settled() => _queue;

  /// Stops watching. Any write already queued still finishes.
  ///
  /// The cancellations are asked for and not waited on, while the queue is waited
  /// on. That is the whole of what closing has to promise: cancelling a
  /// subscription stops delivery at once, so no further write can be queued after
  /// this line, and awaiting the queue is what makes the last write land before
  /// the caller moves on. Waiting for each cancellation to finish at its source
  /// adds nothing to either promise — and it costs something real, because a
  /// bloc's stream completes its cancellation on the event loop rather than in a
  /// microtask, which no widget test's clock ever reaches. A session rebuild that
  /// awaited it would deadlock every widget test that switched hero.
  Future<void> close() async {
    for (final subscription in _watching) {
      unawaited(subscription.cancel());
    }
    _watching.clear();
    await _queue;
  }
}
