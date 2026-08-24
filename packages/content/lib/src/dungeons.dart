import 'package:residuum_core/core.dart';

import 'bestiary.dart';
import 'drop_tables.dart';
import 'dungeon_spawn.dart';
import 'new_game.dart';
import 'ruined_keep.dart';
import 'sea_cave.dart';
import 'world.dart';

/// One themed dungeon's whole content: what lives in it, what it drops, what
/// holds the bottom of it and what that thing is standing over.
///
/// A bundle rather than five lookups keyed by node, because every one of these
/// is answered for the same place at the same moment — building a floor needs
/// the tables, the boss and the trophy together — and five parallel maps are
/// five chances for a dungeon to be added to four of them.
///
/// The crypt is deliberately not one of these. Its floors come from
/// [residuumDungeon] and its tables from the global maps, unsalted and
/// untouched; see [dungeonFor].
class ThemedDungeon {
  ThemedDungeon({
    required this.node,
    required this.bestiary,
    required this.spawnTables,
    required this.dropTables,
    required this.boss,
    required this.trophyTable,
  });

  /// The place on the world map this is under.
  final NodeId node;

  /// Everything that can be met here, boss included.
  final List<CreatureSpec> bestiary;

  final Map<int, DungeonSpawnTable> spawnTables;
  final Map<int, DropTable> dropTables;

  /// What stands on the bottom floor. In no spawn table, ever.
  final CreatureSpec boss;

  /// What the boss is guarding: one item, rare or better, every time.
  final DropTable trophyTable;

  /// What the message log and the screens call this place.
  String get name => residuumWorld.nodeAt(node).name;
}

/// The sea-cave, a day west of Northgate.
final ThemedDungeon theSeaCave = ThemedDungeon(
  node: seaCave,
  bestiary: seaCaveBestiary,
  spawnTables: seaCaveSpawnTables,
  dropTables: seaCaveDropTables,
  boss: drownedCaptain,
  trophyTable: seaCaveTrophyTable,
);

/// The ruined keep, two days east of Northgate and the longest walk in the
/// world.
final ThemedDungeon theRuinedKeep = ThemedDungeon(
  node: ruinedKeep,
  bestiary: ruinedKeepBestiary,
  spawnTables: ruinedKeepSpawnTables,
  dropTables: ruinedKeepDropTables,
  boss: fallenCastellan,
  trophyTable: ruinedKeepTrophyTable,
);

/// Every dungeon with a theme of its own, which is every one but the crypt.
final List<ThemedDungeon> themedDungeons = [theSeaCave, theRuinedKeep];

/// The themed dungeon under [node], or null when there is none — which is true
/// of every town and of the crypt.
ThemedDungeon? themedDungeonAt(NodeId node) {
  for (final dungeon in themedDungeons) {
    if (dungeon.node == node) return dungeon;
  }
  return null;
}

/// Whether [node] has a crawl under it this build knows how to lay out.
bool isDungeonNode(NodeId node) =>
    node == cryptNode || themedDungeonAt(node) != null;

/// A number standing for the dungeon at [node] in a seed mix, the same on every
/// build.
///
/// **A twin of the market's `_townSalt`, not a share of it.** Both are the same
/// Fowler–Noll–Vo walk over an id's own text, and copying it here keeps
/// `economy.dart` untouched while the second caller exists; a third caller is
/// what earns the extraction. Derived from the text rather than read out of a
/// table for the market's reason: a dungeon added to the world needs no second
/// edit somewhere else to get floors of its own, and the edit that got forgotten
/// would be a dungeon quietly sharing another's.
///
/// The mix is [floorSeed]'s, masked so the arithmetic is exact on a web double
/// as well as a native integer — a shared world seed has to describe the same
/// floors however the game was compiled.
int dungeonSalt(NodeId node) {
  var hash = 0x811c9dc5;
  for (final unit in node.value.codeUnits) {
    hash = ((hash ^ (unit & 0x0fffffff)) & 0x0fffffff) * 0x01000193;
    hash &= 0x3fffffff;
  }
  return hash;
}

/// How the dungeon at [node] lays its floors out on the world [worldSeed]
/// describes.
///
/// **The one door to a floor stream, and the crypt goes through it unsalted.**
/// At [cryptNode] this is [residuumDungeon] and nothing else — not
/// `worldSeed ^ 0`, not a salt that happens to be zero, but the same expression
/// the game has always used. Identity by construction rather than by
/// arithmetic: the crypt's characterization goldens and its asserted twenty-four
/// wins in forty are the proof, and they can only stay the proof if the code
/// under them is byte-identical rather than provably-equivalent.
///
/// Every other dungeon folds [dungeonSalt] into the world seed before
/// [floorSeed] sees it, which is the convention the market, the road and the
/// ambush all follow: identity goes in by exclusive-or, not as a fourth
/// parameter.
///
/// Throws [ArgumentError] at a node with nothing under it, so a town id that
/// reached here is a fault with a sentence rather than an empty dungeon.
Dungeon dungeonFor(NodeId node, int worldSeed) {
  if (node == cryptNode) return residuumDungeon(worldSeed);
  final themed = themedDungeonAt(node);
  if (themed == null) {
    throw ArgumentError.value(node, 'node', 'has no dungeon under it');
  }
  return (visit) =>
      (depth) => themedFloor(themed, depth, worldSeed: worldSeed, visit: visit);
}

/// What a crawl in the dungeon at [node] draws its kill drops from.
///
/// The crypt's are the global maps; everything else brings its own. A resumed
/// crawl needs this as much as a fresh one does — the tables are carried by
/// reference and are not written into the save — so [loadRun] asks the same
/// question the door does.
Map<int, DropTable> dropTablesFor(NodeId node) {
  if (node == cryptNode) return dropTables;
  final themed = themedDungeonAt(node);
  if (themed == null) {
    throw ArgumentError.value(node, 'node', 'has no dungeon under it');
  }
  return themed.dropTables;
}

/// What the loot stream of the dungeon at [node] is offset by.
///
/// The crypt passes exactly [lootStreamSalt] and nothing more, for
/// [dungeonFor]'s reason. Every other dungeon folds its own salt in on top, so
/// two dungeons of one world never hand out the same drops in the same order.
int lootSaltFor(NodeId node) =>
    node == cryptNode ? lootStreamSalt : lootStreamSalt ^ dungeonSalt(node);

/// The floor at [depth] of [dungeon], on the world [worldSeed] and [visit]
/// describe.
///
/// **[buildFloor]'s shape with the dungeon's own tables**, down to the order the
/// stream is drawn in: count, then how much litter, then the layout, then the
/// creatures one per spawn, then the items one per litter tile. Two dungeons on
/// one world seed walk different floors because the seed differs, not because
/// the drawing does — which is what keeps a themed floor comparable with a crypt
/// floor and makes one determinism test cover both.
///
/// The deepest floor carries the two promises the shallow ones do not, and both
/// are additions at the end of the draw rather than changes to it:
///
/// * the last creature rolled is replaced by the dungeon's [ThemedDungeon.boss].
///   **Placed, never rolled.** A boss with a weight in the spawn table is either
///   a lie — weight one thousand, and the floor is nothing but bosses — or a
///   lottery, and the bottom of a dungeon stops being a promise the moment it
///   can be walked without meeting the thing that lives there. The swap costs no
///   draw, so a bottom floor's monsters are otherwise exactly the ones the
///   tables rolled.
/// * one extra item spawn is asked of [generateFloor] and the trophy lies on it.
///   **Raising the item count cannot reshuffle anything**, which is
///   [generateFloor]'s own promise and the reason the trophy rides a spawn
///   rather than displacing a piece of litter: the generator draws its layout
///   and its monsters before it draws where the items lie, so the map, the hero,
///   the stairs and every creature's tile are the same as they would have been —
///   and the litter the floor would have had is still exactly where it was, with
///   the trophy on the tile after it.
///
/// [Floor.stairsUp] is left off here exactly as [buildFloor] leaves it off, and
/// `step` supplies the arrival tile in its place. Preserved rather than fixed:
/// the two builders have to behave the same way, and correcting one of them
/// while the crypt's goldens pin the other is how they start to differ.
Floor themedFloor(
  ThemedDungeon dungeon,
  int depth, {
  required int worldSeed,
  required int visit,
}) {
  final seed = floorSeed(worldSeed ^ dungeonSalt(dungeon.node), depth, visit);
  final table = dungeonSpawnTableFor(dungeon.spawnTables, depth);
  final drops = dungeonDropTableFor(dungeon.dropTables, depth);
  final bottom = depth >= deepestDepth;
  final rng = Rng(seed);
  final count = table.rollCount(rng);
  final itemCount = rollFloorItemCount(drops, rng);
  final generated = generateFloor(
    seed,
    depth,
    monsterCount: count,
    itemCount: bottom ? itemCount + 1 : itemCount,
  );
  final monsters = <Actor>[];
  for (final spawn in generated.monsterSpawns) {
    final creature = table.rollCreature(rng);
    monsters.add(
      creature.spawn(id: '${creature.id}-${monsters.length + 1}', at: spawn),
    );
  }
  if (bottom) {
    monsters[monsters.length - 1] = dungeon.boss.spawn(
      id: 'boss-${dungeon.node.value}',
      at: monsters.last.position,
    );
  }
  final groundItems = <Position, List<Item>>{};
  for (final spawn in generated.itemSpawns.take(itemCount)) {
    final item = rollDrop(drops, rng, 'floor-$depth-${groundItems.length + 1}');
    groundItems[spawn] = [item];
  }
  if (bottom) {
    groundItems[generated.itemSpawns.last] = [
      rollDrop(dungeon.trophyTable, rng, 'trophy-${dungeon.node.value}'),
    ];
  }
  assert(
    monsters.map((monster) => monster.id).toSet().length == monsters.length,
    'two monsters on depth $depth of ${dungeon.node.value} share an id',
  );
  return Floor(
    map: generated.map,
    heroSpawn: generated.heroSpawn,
    stairsDown: generated.stairsDown,
    monsters: monsters,
    groundItems: groundItems,
  );
}

/// The drop table for [depth] of [tables].
///
/// Throws [ArgumentError] outside the depths the dungeon has, holding
/// [dropTableFor]'s contract for every dungeon rather than for the crypt alone.
DropTable dungeonDropTableFor(Map<int, DropTable> tables, int depth) {
  final table = tables[depth];
  if (table == null) {
    throw ArgumentError.value(depth, 'depth', 'no drop table for this depth');
  }
  return table;
}

/// The crawl [profile] begins by walking into the dungeon at [node].
///
/// **The one door the town uses, for every dungeon there is.** It replaces
/// `startDungeonRun`, which knew only the crypt; at [cryptNode] it is that
/// function's exact successor — the same [Dungeon], the same global drop tables,
/// the same [lootStreamSalt] — and a characterization test pins the first floor
/// and both opening streams to prove it rather than to claim it.
///
/// [newGame] is the other door and it stays: asking for one specific crypt by
/// seed and visit is still an honest thing to want, and the balance bot and the
/// seeded rule tests want exactly that.
GameState startDungeonRunAt(NodeId node, Profile profile) => startRun(
  profile,
  dungeon: dungeonFor(node, profile.worldSeed),
  dropTables: dropTablesFor(node),
  lootSeedSalt: lootSaltFor(node),
);
