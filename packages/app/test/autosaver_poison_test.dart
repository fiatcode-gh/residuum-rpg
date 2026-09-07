import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/save/autosaver.dart';
import 'package:residuum_app/save/boot.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'support/memory_save_files.dart';
import 'support/standing.dart';

/// A one-hero boot, the shape every autosaver test opens on.
Boot _boot(Profile profile) => Boot(
  document: SaveDocument.one(
    id: 'hero-1',
    label: 'Hero 1',
    profile: profile,
    world: atTheCrypt(),
  ),
);

void main() {
  group('the autosaver queue when a save fails', () {
    test(
      'a failing save is survived: later saves run and one notice appears',
      () async {
        // arrange — a disk whose rename of the current slot fails, which is
        // what a locked slot looks like from up here: the write landed, the
        // read-back passed, and the rotate did not. The failure is the poison
        // the queue once died of; now it is a word and a working queue.
        final files = MemorySaveFiles()..failRenamesFrom.add(currentSlot);
        final town = TownBloc(
          profile: newProfile(worldSeed: 5).copyWith(gold: 500),
        );
        final notices = <SaveNotice>[];
        final saver = Autosaver(
          SaveStore(files),
          from: _boot(town.state.profile),
          onSaveFailed: notices.add,
        )..watchTown(town);

        // act — two saves; the first fails at its rename and would once have
        // poisoned the chain.
        town.add(const DepositGoldPressed(120));
        await town.stream.first;
        town.add(const RestPressed());
        await town.stream.first;
        await saver.settled();

        // assert — the queue is alive: settled() and close() answer without
        // rejecting, and the failure was told exactly once despite two failing
        // saves in the same streak.
        await town.close();
        await saver.close();
        expect(notices, hasLength(1));
        expect(
          notices.single.sentence,
          'the game could not be saved; your last save still stands',
        );
      },
    );

    test(
      'a save that lands ends the streak, and the next failure speaks again',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final town = TownBloc(
          profile: newProfile(worldSeed: 5).copyWith(gold: 500),
        );
        final notices = <SaveNotice>[];
        final saver = Autosaver(
          SaveStore(files),
          from: _boot(town.state.profile),
          onSaveFailed: notices.add,
        )..watchTown(town);

        // act — fail once, land once, fail again.
        files.failRenamesFrom.add(currentSlot);
        town.add(const DepositGoldPressed(120));
        await town.stream.first;
        await saver.settled();
        files.failRenamesFrom.remove(currentSlot);
        town.add(const RestPressed());
        await town.stream.first;
        await saver.settled();
        files.failRenamesFrom.add(currentSlot);
        town.add(const DepositGoldPressed(10));
        await town.stream.first;
        await saver.settled();

        // assert
        expect(notices, hasLength(2));
        await town.close();
        await saver.close();
      },
    );

    test('a queue with no sink stays quiet and alive', () async {
      // arrange — the sink is optional; a test that only cares about the
      // queue constructs without one.
      final files = MemorySaveFiles()..failRenamesFrom.add(currentSlot);
      final town = TownBloc(
        profile: newProfile(worldSeed: 5).copyWith(gold: 500),
      );
      final saver = Autosaver(SaveStore(files), from: _boot(town.state.profile))
        ..watchTown(town);

      // act
      town.add(const DepositGoldPressed(120));
      await town.stream.first;
      await saver.settled();

      // assert — nothing threw and the queue answered.
      await town.close();
      await saver.close();
    });
  });
}
