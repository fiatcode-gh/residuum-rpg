import 'package:residuum_core/core.dart';

import 'bestiary.dart';

/// How much danger one depth of a themed dungeon carries, and of what kind.
///
/// **[SpawnTable]'s twin, and it holds its creatures rather than naming them.**
/// The shipped table draws entries by id and resolves them through
/// [creatureById], which searches the one global [bestiary] — so a table for a
/// dungeon whose creatures are not in that list could never roll one. Holding
/// the [CreatureSpec] outright removes the lookup and with it the whole class of
/// fault the content validation tests exist to catch: a themed table cannot name
/// a creature that does not exist, because it does not name creatures at all.
///
/// The draws are [SpawnTable]'s exactly — one [Rng.rollRange] for the count,
/// then one for the creature, walked against the weights in list order — so a
/// themed floor consumes the same stream in the same shape a crypt floor does,
/// and the two stay comparable seed for seed.
class DungeonSpawnTable {
  const DungeonSpawnTable({
    required this.minCount,
    required this.maxCount,
    required this.entries,
  });

  final int minCount;
  final int maxCount;

  /// What can stand on this floor, and each one's share of the danger.
  final List<Weighted<CreatureSpec>> entries;

  /// How many monsters this floor gets.
  int rollCount(Rng rng) => rng.rollRange(minCount, maxCount);

  /// One creature, drawn against the entry weights.
  CreatureSpec rollCreature(Rng rng) {
    final total = entries.fold(0, (sum, entry) => sum + entry.weight);
    var roll = rng.rollRange(1, total);
    for (final entry in entries) {
      roll -= entry.weight;
      if (roll <= 0) return entry.value;
    }
    return entries.last.value;
  }

  /// Everything this table can put on a floor.
  Iterable<CreatureSpec> get creatures => entries.map((entry) => entry.value);
}

/// The table for [depth] of [tables].
///
/// Throws [ArgumentError] outside the depths the dungeon has, so a floor can
/// never be built from a table that does not exist — [spawnTableFor]'s contract,
/// held to by every dungeon rather than by the crypt alone.
DungeonSpawnTable dungeonSpawnTableFor(
  Map<int, DungeonSpawnTable> tables,
  int depth,
) {
  final table = tables[depth];
  if (table == null) {
    throw ArgumentError.value(depth, 'depth', 'no spawn table for this depth');
  }
  return table;
}
