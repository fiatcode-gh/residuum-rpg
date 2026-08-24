import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/run_codec.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/deep_run.dart';

GameState _reread(GameState run) =>
    loadRun({'run': encodeRun(run)}, 'run', dungeon: cryptNode);

void main() {
  group('run codec', () {
    test('every plain field of a deep run round-trips', () {
      // arrange
      final before = deepRun();

      // act
      final after = _reread(before);

      // assert
      expect(after.depth, before.depth);
      expect(after.worldSeed, before.worldSeed);
      expect(after.visit, before.visit);
      expect(after.gold, before.gold);
      expect(after.isGameOver, before.isGameOver);
      expect(after.nextDropNumber, before.nextDropNumber);
      expect(after.stairsDown, before.stairsDown);
      expect(after.stairsUp, before.stairsUp);
      expect(after.visible, before.visible);
      expect(after.explored, before.explored);
      expect(after.inventory, before.inventory);
      expect(after.equipment, before.equipment);
      expect(after.skills, before.skills);
      expect(after.groundItems, before.groundItems);
    });

    test('the terrain survives being written down and read back', () {
      // arrange
      final before = deepRun();

      // act
      final after = _reread(before);

      // assert
      expect(after.map.toAscii(), before.map.toAscii());
      expect(after.map.width, before.map.width);
      expect(after.map.height, before.map.height);
    });

    test('the hero and every monster come back whole and in order', () {
      // arrange
      final before = deepRun();

      // act
      final after = _reread(before);

      // assert
      expect(after.hero.position, before.hero.position);
      expect(after.hero.hp, before.hero.hp);
      expect(after.hero.energy, before.hero.energy);
      expect(
        after.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
        before.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
      );
      expect(after.monsters, isNotEmpty);
    });

    test("a monster's held turn is not zeroed", () {
      // arrange
      final loaded = deepRun();
      final waiting = loaded.copyWith(
        monsters: [
          for (final monster in loaded.monsters) monster.copyWith(energy: 87),
        ],
      );

      // act
      final after = _reread(waiting);

      // assert
      expect(after.monsters.map((m) => m.energy), everyElement(87));
    });

    test('both streams resume where they stopped', () {
      // arrange
      final before = deepRun();

      // act
      final after = _reread(before);

      // assert
      expect(after.rng.state, before.rng.state);
      expect(after.lootRng.state, before.lootRng.state);
      expect(
        after.rng.rollRange(0, 999),
        Rng.fromState(before.rng.state).rollRange(0, 999),
      );
    });

    test(
      'a full-width stream state is written as text and survives exactly',
      () {
        // arrange
        final before = deepRun();

        // act
        final written = encodeRun(before);

        // assert
        expect(before.rng.state, -8613303245920329199);
        expect(written['rngState'], '-8613303245920329199');
        expect(written['lootRngState'], '2420599403871909411');
        expect(_reread(before).rng.state, -8613303245920329199);
      },
    );

    test('every floor left behind comes back, field for field', () {
      // arrange
      final before = deepRun();

      // act
      final after = _reread(before);

      // assert
      expect(after.floors.keys.toList()..sort(), [1, 2, 3, 4]);
      for (final depth in before.floors.keys) {
        final was = before.floors[depth]!;
        final now = after.floors[depth]!;
        expect(now.map.toAscii(), was.map.toAscii(), reason: 'depth $depth');
        expect(now.explored, was.explored, reason: 'depth $depth');
        expect(now.groundItems, was.groundItems, reason: 'depth $depth');
        expect(now.stairsDown, was.stairsDown, reason: 'depth $depth');
        expect(now.stairsUp, was.stairsUp, reason: 'depth $depth');
        expect(
          now.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
          was.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
          reason: 'depth $depth',
        );
      }
    });

    test('a single-floor run round-trips with no floors behind it', () {
      // arrange
      final before = deepRun(depth: 1);

      // act
      final after = _reread(before);

      // assert
      expect(before.floors, isEmpty);
      expect(after.floors, isEmpty);
      expect(after.depth, 1);
      expect(after.map.toAscii(), before.map.toAscii());
    });

    test('resuming does not bump the visit', () {
      // arrange
      final before = deepRun(visit: 4);

      // act
      final after = _reread(before);

      // assert
      expect(after.visit, 4);
    });

    test('the floor builder comes back, laying out the same next floor', () {
      // arrange
      final before = deepRun(depth: 2);

      // act
      final after = _reread(before);

      // assert
      expect(
        after.buildFloor(3).map.toAscii(),
        before.buildFloor(3).map.toAscii(),
      );
      expect(
        after.buildFloor(3).monsters.map((m) => (m.id, m.position)),
        before.buildFloor(3).monsters.map((m) => (m.id, m.position)),
      );
    });

    test('the floor builder is laid out for the run\'s own visit', () {
      // arrange
      final before = deepRun(depth: 1, visit: 3);

      // act
      final after = _reread(before);

      // assert
      expect(
        after.buildFloor(2).map.toAscii(),
        isNot(deepRun(depth: 1, visit: 4).buildFloor(2).map.toAscii()),
      );
      expect(
        after.buildFloor(2).map.toAscii(),
        before.buildFloor(2).map.toAscii(),
      );
    });

    test('the drop tables come back', () {
      // arrange
      final before = deepRun();

      // act
      final after = _reread(before);

      // assert
      expect(after.dropTables, before.dropTables);
      expect(after.dropTables, isNotEmpty);
    });

    test('a run that ended in death round-trips as over', () {
      // arrange
      final before = deepRun().copyWith(isGameOver: true);

      // act
      final after = _reread(before);

      // assert
      expect(after.isGameOver, isTrue);
    });
  });
}
