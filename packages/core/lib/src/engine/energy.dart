import 'package:equatable/equatable.dart';

/// The energy an actor must hold before it may act.
const int actThreshold = 100;

/// The energy one action costs.
const int actCost = 100;

/// The most energy a decoded actor may hold.
///
/// **The arithmetic is the schedule's, and the bound is ten fights deep.** A
/// monster holding energy E drains [actCost] every time it acts, so E /
/// [actCost] is the worst-case number of scheduled turns a resumed crawl owes
/// before the hero moves again: at 1000, a forged document buys ten monster
/// turns, and no real fight comes close — standing energy between actions
/// stays under [actThreshold] + speed, and the fastest creature in the tables
/// runs at speed 20. The bound is defense-in-depth against unbounded schedule
/// work, never the hang fix itself: the value that loops the clock forever is
/// a speed below 1, and that is refused where it is decoded, not bounded here.
const int maxSaveEnergy = 1000;

/// The monster turns owed before the hero may act again, and the energy every
/// actor holds once those turns are spent.
class TurnSchedule extends Equatable {
  const TurnSchedule({
    required this.monsterTurns,
    required this.heroEnergy,
    required this.monsterEnergies,
  });

  /// Indices into the monster list, in the order those monsters act. A monster
  /// fast enough to act twice appears twice.
  final List<int> monsterTurns;

  final int heroEnergy;
  final List<int> monsterEnergies;

  @override
  List<Object?> get props => [monsterTurns, heroEnergy, monsterEnergies];

  @override
  String toString() =>
      'TurnSchedule($monsterTurns, hero $heroEnergy, monsters $monsterEnergies)';
}

/// The monster turns owed after the hero has acted, and the energy left over.
///
/// Every actor gains its speed in energy per tick; an actor holding at least
/// [actThreshold] may act, spending exactly [actCost]. Call this once the hero
/// has spent its own energy: the clock then runs forward, letting monsters act
/// as they come due, and stops the moment the hero is the next actor again.
///
/// **The hero acts first on a shared threshold.** When a tick brings the hero
/// and a monster to [actThreshold] together, this returns immediately and the
/// monster acts after the hero's next action. Player agency is not a coin
/// flip: a monster that "won" a shared tick is indistinguishable, from the
/// other side of the screen, from input the game ignored.
///
/// **Speed 10 against speed 10 reproduces strict alternation exactly.** That is
/// the regression guarantee this whole file exists to keep — the Milestone 1
/// suite is the characterisation layer for the clock, and every one of its
/// turn-order tests must stay green without being rewritten. Everyone spends
/// together, everyone refills together, and the hero is next by the tie-break
/// above.
///
/// Speeds must be at least 1: a hero who never reaches the threshold would
/// leave the clock running forever. Throws [ArgumentError] otherwise, and when
/// [monsterSpeeds] and [monsterEnergies] are different lengths.
TurnSchedule scheduleMonsterTurns({
  required int heroSpeed,
  required int heroEnergy,
  required List<int> monsterSpeeds,
  required List<int> monsterEnergies,
}) {
  _requireActionable(heroSpeed, 'heroSpeed');
  for (final speed in monsterSpeeds) {
    _requireActionable(speed, 'monsterSpeeds');
  }
  if (monsterSpeeds.length != monsterEnergies.length) {
    throw ArgumentError.value(
      monsterEnergies,
      'monsterEnergies',
      'must hold one entry per monster speed (${monsterSpeeds.length})',
    );
  }

  final turns = <int>[];
  final energies = [...monsterEnergies];
  var hero = heroEnergy;
  while (hero < actThreshold) {
    final ready = _firstReady(energies);
    if (ready != null) {
      turns.add(ready);
      energies[ready] -= actCost;
      continue;
    }
    hero += heroSpeed;
    for (var index = 0; index < energies.length; index++) {
      energies[index] += monsterSpeeds[index];
    }
  }
  return TurnSchedule(
    monsterTurns: turns,
    heroEnergy: hero,
    monsterEnergies: energies,
  );
}

int? _firstReady(List<int> energies) {
  for (var index = 0; index < energies.length; index++) {
    if (energies[index] >= actThreshold) return index;
  }
  return null;
}

void _requireActionable(int speed, String name) {
  if (speed < 1) {
    throw ArgumentError.value(speed, name, 'must be at least 1');
  }
}
