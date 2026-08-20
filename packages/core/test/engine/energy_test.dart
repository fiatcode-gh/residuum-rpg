import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

TurnSchedule schedule({
  int heroSpeed = 10,
  int heroEnergy = 0,
  List<int> monsterSpeeds = const [10],
  List<int>? monsterEnergies,
}) => scheduleMonsterTurns(
  heroSpeed: heroSpeed,
  heroEnergy: heroEnergy,
  monsterSpeeds: monsterSpeeds,
  monsterEnergies:
      monsterEnergies ?? List.filled(monsterSpeeds.length, actThreshold),
);

void main() {
  group('scheduleMonsterTurns', () {
    test('equal speeds owe exactly one monster turn per hero turn', () {
      // arrange
      const speeds = [10];

      // act
      final owed = schedule(monsterSpeeds: speeds);

      // assert
      expect(owed.monsterTurns, [0]);
      expect(owed.heroEnergy, actThreshold);
      expect(owed.monsterEnergies, [actThreshold]);
    });

    test('equal speeds stay in lockstep turn after turn', () {
      // arrange
      var heroEnergy = actThreshold;
      var monsterEnergies = [actThreshold];
      final owedPerTurn = <int>[];

      // act
      for (var turn = 0; turn < 10; turn++) {
        final owed = schedule(
          heroEnergy: heroEnergy - actCost,
          monsterEnergies: monsterEnergies,
        );
        owedPerTurn.add(owed.monsterTurns.length);
        heroEnergy = owed.heroEnergy;
        monsterEnergies = owed.monsterEnergies;
      }

      // assert
      expect(owedPerTurn, everyElement(1));
    });

    test('a speed twenty monster acts twice per hero turn', () {
      // arrange
      const speeds = [20];

      // act
      final owed = schedule(monsterSpeeds: speeds);

      // assert
      expect(owed.monsterTurns, [0, 0]);
    });

    test('a speed five monster acts every other hero turn', () {
      // arrange
      const speeds = [5];

      // act
      final first = schedule(monsterSpeeds: speeds);
      final second = schedule(
        monsterSpeeds: speeds,
        heroEnergy: first.heroEnergy - actCost,
        monsterEnergies: first.monsterEnergies,
      );
      final third = schedule(
        monsterSpeeds: speeds,
        heroEnergy: second.heroEnergy - actCost,
        monsterEnergies: second.monsterEnergies,
      );

      // assert
      expect(first.monsterTurns, [0]);
      expect(second.monsterTurns, isEmpty);
      expect(third.monsterTurns, [0]);
    });

    test('on a shared threshold the hero acts before the monsters', () {
      // arrange
      const heroEnergy = actThreshold;

      // act
      final owed = schedule(heroEnergy: heroEnergy);

      // assert
      expect(owed.monsterTurns, isEmpty);
      expect(owed.monsterEnergies, [actThreshold]);
    });

    test('monsters at the threshold act in list order', () {
      // arrange
      const speeds = [10, 10, 10];

      // act
      final owed = schedule(monsterSpeeds: speeds);

      // assert
      expect(owed.monsterTurns, [0, 1, 2]);
    });

    test('a faster monster takes its extra turns after the slower ones', () {
      // arrange
      const speeds = [10, 20];

      // act
      final owed = schedule(monsterSpeeds: speeds);

      // assert
      expect(owed.monsterTurns, [0, 1, 1]);
    });

    test('a monster that comes due mid-tick still takes its turn', () {
      // arrange
      const energies = [50];

      // act
      final owed = schedule(monsterEnergies: energies);

      // assert
      expect(owed.monsterTurns, [0]);
      expect(owed.monsterEnergies, [50]);
    });

    test('a monster too slow to come due is owed no turn', () {
      // arrange
      const energies = [40];

      // act
      final owed = schedule(
        monsterSpeeds: const [5],
        monsterEnergies: energies,
      );

      // assert
      expect(owed.monsterTurns, isEmpty);
      expect(owed.monsterEnergies, [90]);
    });

    test('no monsters still advances the hero to the threshold', () {
      // arrange
      const speeds = <int>[];

      // act
      final owed = schedule(monsterSpeeds: speeds);

      // assert
      expect(owed.monsterTurns, isEmpty);
      expect(owed.heroEnergy, actThreshold);
    });

    test('leaves the caller list untouched', () {
      // arrange
      final energies = [actThreshold];

      // act
      scheduleMonsterTurns(
        heroSpeed: 10,
        heroEnergy: 0,
        monsterSpeeds: const [10],
        monsterEnergies: energies,
      );

      // assert
      expect(energies, [actThreshold]);
    });

    test('a non-positive hero speed is rejected', () {
      // arrange
      const heroSpeed = 0;

      // act
      void act() => schedule(heroSpeed: heroSpeed);

      // assert
      expect(act, throwsArgumentError);
    });

    test('a non-positive monster speed is rejected', () {
      // arrange
      const speeds = [10, -1];

      // act
      void act() => schedule(monsterSpeeds: speeds);

      // assert
      expect(act, throwsArgumentError);
    });

    test('mismatched speed and energy lists are rejected', () {
      // arrange
      const speeds = [10, 10];

      // act
      void act() => schedule(
        monsterSpeeds: speeds,
        monsterEnergies: const [actThreshold],
      );

      // assert
      expect(act, throwsArgumentError);
    });

    test('a schedule is a value object', () {
      // arrange
      const one = TurnSchedule(
        monsterTurns: [0],
        heroEnergy: 100,
        monsterEnergies: [0],
      );

      // act
      const another = TurnSchedule(
        monsterTurns: [0],
        heroEnergy: 100,
        monsterEnergies: [0],
      );

      // assert
      expect(one, another);
    });
  });
}
