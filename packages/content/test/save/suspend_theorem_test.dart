import 'dart:convert';

import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/run_codec.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/deep_run.dart';

/// A fixed script that walks every direction, swings at whatever is in the way,
/// and reaches into the pack — so the clock turns and both streams are drawn
/// from whatever the floor happens to look like.
const List<GameAction> _script = [
  MoveAction(Direction.north),
  MoveAction(Direction.east),
  MoveAction(Direction.east),
  MoveAction(Direction.south),
  MoveAction(Direction.south),
  MoveAction(Direction.west),
  MoveAction(Direction.west),
  MoveAction(Direction.north),
  MoveAction(Direction.north),
  MoveAction(Direction.east),
  PickUpAction(),
  MoveAction(Direction.south),
  MoveAction(Direction.east),
  MoveAction(Direction.north),
  MoveAction(Direction.west),
  MoveAction(Direction.south),
  MoveAction(Direction.east),
  MoveAction(Direction.south),
  MoveAction(Direction.west),
  MoveAction(Direction.north),
  MoveAction(Direction.north),
  MoveAction(Direction.east),
  MoveAction(Direction.south),
  MoveAction(Direction.west),
];

(GameState, List<GameEvent>) _play(GameState from) {
  var state = from;
  final transcript = <GameEvent>[];
  for (final action in _script) {
    final (after, events) = step(state, action);
    state = after;
    transcript.addAll(events);
  }
  return (state, transcript);
}

GameState _suspendAndResume(GameState run) {
  final read = decodeSave(
    encodeSave(
      SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: newProfile(worldSeed: run.worldSeed),
        run: run,
        dungeon: cryptNode,
        campDay: 0,
      ),
    ),
  );
  return (read as SaveDocument).run!;
}

GameState _standing(GameState from, Position? at) =>
    from.copyWith(hero: from.hero.copyWith(position: at));

/// The crawl as bytes. [GameState] has no `operator==`, so the codec is the
/// equality instrument — and it is the right one, because the bytes are exactly
/// what a resume has to reproduce for a relaunch to be the same game.
///
/// A test that plays a crawl and its resumed self has to build the crawl twice.
/// `resumeRun` carries the generators by reference, exactly as `copyWith` does
/// and for the documented reason, so playing the original first would advance
/// the very stream the resumed state is about to draw from — and the divergence
/// would look like a broken resume rather than a shared object.
String _asBytes(GameState run) => jsonEncode(encodeRun(run));

void main() {
  group('the suspend theorem', () {
    test('a resumed crawl plays out exactly as the one it resumed', () {
      // arrange
      final live = deepRun(worldSeed: 4242, depth: 3);
      final resumed = _suspendAndResume(live);

      // act
      final (livePlayed, liveEvents) = _play(live);
      final (resumedPlayed, resumedEvents) = _play(resumed);

      // assert
      expect(resumedEvents, liveEvents);
      expect(resumedPlayed.hero.position, livePlayed.hero.position);
      expect(resumedPlayed.hero.hp, livePlayed.hero.hp);
      expect(resumedPlayed.hero.energy, livePlayed.hero.energy);
      expect(
        resumedPlayed.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
        livePlayed.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
      );
      expect(resumedPlayed.rng.state, livePlayed.rng.state);
      expect(resumedPlayed.lootRng.state, livePlayed.lootRng.state);
      expect(resumedPlayed.inventory, livePlayed.inventory);
      expect(resumedPlayed.groundItems, livePlayed.groundItems);
      expect(resumedPlayed.equipment, livePlayed.equipment);
      expect(resumedPlayed.skills, livePlayed.skills);
      expect(resumedPlayed.nextDropNumber, livePlayed.nextDropNumber);
      expect(resumedPlayed.explored, livePlayed.explored);
      expect(resumedPlayed.visible, livePlayed.visible);
      expect(resumedPlayed.isGameOver, livePlayed.isGameOver);
    });

    test(
      'the script draws from both streams, so the theorem has work to do',
      () {
        // arrange
        final live = deepRun(worldSeed: 4242, depth: 3);

        // act
        final (_, events) = _play(live);

        // assert
        expect(events, isNotEmpty);
        expect(events.whereType<AttackHit>(), isNotEmpty);
        expect(events.whereType<ActorMoved>(), isNotEmpty);
      },
    );

    test('a stream restored by seed instead of state would diverge', () {
      // arrange
      final live = deepRun(worldSeed: 4242, depth: 3);
      final reseeded = _suspendAndResume(live).copyWith();

      // act
      final (_, fromState) = _play(_suspendAndResume(live));
      final (_, fromSeed) = _play(
        GameState(
          map: reseeded.map,
          hero: reseeded.hero,
          monsters: reseeded.monsters,
          rng: Rng(reseeded.worldSeed),
          lootRng: Rng(reseeded.worldSeed ^ lootStreamSalt),
          visible: reseeded.visible,
          explored: reseeded.explored,
          buildFloor: reseeded.buildFloor,
          depth: reseeded.depth,
          worldSeed: reseeded.worldSeed,
          visit: reseeded.visit,
          stairsDown: reseeded.stairsDown,
          stairsUp: reseeded.stairsUp,
          gold: reseeded.gold,
          floors: reseeded.floors,
          groundItems: reseeded.groundItems,
          inventory: reseeded.inventory,
          equipment: reseeded.equipment,
          skills: reseeded.skills,
          dropTables: reseeded.dropTables,
          nextDropNumber: reseeded.nextDropNumber,
        ),
      );

      // assert
      expect(fromSeed, isNot(fromState));
    });

    test('a resumed crawl walks back onto the floor it left, unchanged', () {
      // arrange
      final live = deepRun(worldSeed: 99, depth: 2);
      final resumed = _suspendAndResume(live);

      // act
      final (liveClimb, _) = step(
        _standing(live, live.stairsUp),
        const AscendAction(),
      );
      final (resumedClimb, _) = step(
        _standing(resumed, resumed.stairsUp),
        const AscendAction(),
      );

      // assert
      expect(liveClimb.depth, 1);
      expect(resumedClimb.depth, liveClimb.depth);
      expect(resumedClimb.map.toAscii(), liveClimb.map.toAscii());
      expect(
        resumedClimb.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
        liveClimb.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
      );
      expect(resumedClimb.explored, liveClimb.explored);
      expect(resumedClimb.groundItems, liveClimb.groundItems);
    });

    test('a resumed crawl descends onto the same next floor', () {
      // arrange
      final live = deepRun(worldSeed: 31337, depth: 1);
      final resumed = _suspendAndResume(live);

      // act
      final (liveDown, _) = step(
        _standing(live, live.stairsDown),
        const DescendAction(),
      );
      final (resumedDown, _) = step(
        _standing(resumed, resumed.stairsDown),
        const DescendAction(),
      );

      // assert
      expect(resumedDown.depth, 2);
      expect(resumedDown.map.toAscii(), liveDown.map.toAscii());
      expect(
        resumedDown.monsters.map((m) => (m.id, m.position)),
        liveDown.monsters.map((m) => (m.id, m.position)),
      );
      expect(resumedDown.floors.keys, liveDown.floors.keys);
    });

    test('a resumed crawl on a revisited floor plays out the same', () {
      // arrange
      final live = deepRun(worldSeed: 555, depth: 2);
      final (climbed, _) = step(
        _standing(live, live.stairsUp),
        const AscendAction(),
      );
      final resumedClimbed = _suspendAndResume(climbed);

      // act
      final (livePlayed, liveEvents) = _play(climbed);
      final (resumedPlayed, resumedEvents) = _play(resumedClimbed);

      // assert
      expect(resumedEvents, liveEvents);
      expect(resumedPlayed.rng.state, livePlayed.rng.state);
      expect(
        resumedPlayed.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
        livePlayed.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
      );
      expect(resumedPlayed.floors.keys.toList()..sort(), [2]);
    });
  });

  group('the identity theorem', () {
    test('suspending and resuming with no town business between them leaves '
        'the crawl untouched', () {
      // arrange
      final live = deepRun(worldSeed: 4242, depth: 3);
      final entered = newProfile(worldSeed: 4242);

      // act
      final resumed = resumeRun(suspendRun(entered, live), live);

      // assert
      expect(_asBytes(resumed), _asBytes(live));
    });

    test('the crawl it hands back plays out exactly as the one it left', () {
      // arrange
      final live = deepRun(worldSeed: 99, depth: 2);
      final twin = deepRun(worldSeed: 99, depth: 2);
      final resumed = resumeRun(
        suspendRun(newProfile(worldSeed: 99), twin),
        twin,
      );

      // act
      final (livePlayed, liveEvents) = _play(live);
      final (resumedPlayed, resumedEvents) = _play(resumed);

      // assert
      expect(resumedEvents, liveEvents);
      expect(_asBytes(resumedPlayed), _asBytes(livePlayed));
    });

    test('a camp written to disk and then walked back into is still the same '
        'crawl', () {
      // arrange
      final live = deepRun(worldSeed: 777, depth: 2);
      final camped = suspendRun(newProfile(worldSeed: 777), live);

      // act
      final resumed = resumeRun(camped, _suspendAndResume(live));

      // assert
      expect(_asBytes(resumed), _asBytes(live));
    });

    test('town business is the one thing the theorem does not cover', () {
      // arrange
      final live = deepRun(worldSeed: 4242, depth: 3);
      final shopped = suspendRun(
        newProfile(worldSeed: 4242),
        live,
      ).copyWith(gold: 9999);

      // act
      final resumed = resumeRun(shopped, live);

      // assert
      expect(_asBytes(resumed), isNot(_asBytes(live)));
      expect(resumed.gold, 9999);
    });
  });
}
