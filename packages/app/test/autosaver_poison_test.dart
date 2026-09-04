import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
      'today a failing save poisons the queue and later saves never run',
      () async {
        // arrange — a disk whose rename of the current slot fails, which is
        // what a locked slot looks like from up here: the write landed, the
        // read-back passed, and the rotate did not.
        final errors = <Object>[];
        final files = MemorySaveFiles()..failRenamesFrom.add(currentSlot);
        final town = TownBloc(
          profile: newProfile(worldSeed: 5).copyWith(gold: 500),
        );
        await runZonedGuarded(() async {
          Autosaver(SaveStore(files), from: _boot(town.state.profile))
            .watchTown(town);

          // act — two saves; the first fails at its rename and poisons the
          // chain, so the second never runs.
          town.add(const DepositGoldPressed(120));
          await town.stream.first;
          town.add(const RestPressed());
          await town.stream.first;
          await Future<void>.delayed(Duration.zero);
        }, (error, stack) => errors.add(error));
        await town.close();

        // assert — the poison, as it behaves today: the first save's rename
        // threw out of the queue chain, so nothing rotated and the second
        // queued save never ran at all.
        expect(errors, isNotEmpty);
        expect(errors.first, isA<StateError>());
        expect(files.contents[previousSlot], isNull);
        expect(files.contents[currentSlot], isNull);
        expect(files.contents[pendingSlot], isNotNull);
      },
    );
  });
}
