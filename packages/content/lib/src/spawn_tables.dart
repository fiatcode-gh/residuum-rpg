import 'package:residuum_core/core.dart';

import 'bestiary.dart';

/// One creature's share of a floor's danger.
class SpawnEntry {
  const SpawnEntry(this.creatureId, this.weight);

  final String creatureId;

  /// Relative chance against the other entries of the same table.
  final int weight;
}

/// How much danger one depth carries, and of what kind.
class SpawnTable {
  const SpawnTable({
    required this.minCount,
    required this.maxCount,
    required this.entries,
  });

  final int minCount;
  final int maxCount;
  final List<SpawnEntry> entries;

  /// How many monsters this floor gets.
  int rollCount(Rng rng) => rng.rollRange(minCount, maxCount);

  /// One creature, drawn against the entry weights.
  CreatureSpec rollCreature(Rng rng) {
    final total = entries.fold(0, (sum, entry) => sum + entry.weight);
    var roll = rng.rollRange(1, total);
    for (final entry in entries) {
      roll -= entry.weight;
      if (roll <= 0) return creatureById(entry.creatureId);
    }
    return creatureById(entries.last.creatureId);
  }
}

/// What waits on each depth, one through five.
///
/// Counts and weights slide together: the dungeon gets bigger, more crowded and
/// slower-and-harder as it goes down, and each creature fades in and out over
/// the depth band the bestiary gives it, so no floor is a single monster on
/// repeat.
const Map<int, SpawnTable> spawnTables = {
  1: SpawnTable(
    minCount: 3,
    maxCount: 5,
    entries: [SpawnEntry('rat', 4), SpawnEntry('wolf', 1)],
  ),
  2: SpawnTable(
    minCount: 4,
    maxCount: 6,
    entries: [
      SpawnEntry('rat', 3),
      SpawnEntry('wolf', 2),
      SpawnEntry('ghoul', 2),
    ],
  ),
  3: SpawnTable(
    minCount: 5,
    maxCount: 7,
    entries: [
      SpawnEntry('wolf', 2),
      SpawnEntry('ghoul', 3),
      SpawnEntry('skeleton', 1),
    ],
  ),
  4: SpawnTable(
    minCount: 6,
    maxCount: 8,
    entries: [
      SpawnEntry('ghoul', 3),
      SpawnEntry('skeleton', 2),
      SpawnEntry('wight', 1),
    ],
  ),
  5: SpawnTable(
    minCount: 7,
    maxCount: 9,
    entries: [SpawnEntry('skeleton', 3), SpawnEntry('wight', 2)],
  ),
};

/// The table for [depth].
///
/// Throws [ArgumentError] outside one to five, so a floor can never be built
/// from a table that does not exist.
SpawnTable spawnTableFor(int depth) {
  final table = spawnTables[depth];
  if (table == null) {
    throw ArgumentError.value(depth, 'depth', 'no spawn table for this depth');
  }
  return table;
}
