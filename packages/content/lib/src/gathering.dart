import 'package:residuum_core/core.dart';

import 'world.dart';

/// What the node stream's seed is offset by, so it never runs in step with the
/// stream that laid the floor out.
///
/// **The value is measured, not chosen.** [floorSeed] masks its output to thirty
/// bits, so an exclusive-or at the end lands back inside the same set of numbers
/// the floor stream draws from — and two plausible constants for this actually
/// put seeds in both sets. Swept over eight world seeds, three dungeons, seven
/// depths and two thousand visits, `0x5B1F` shares forty seeds with the floor
/// streams and `0x3C0F` shares ten; this value shares none. The sweep is a test
/// rather than a comment, in `gathering_test.dart`.
///
/// A literal rather than a derived value, for [lootStreamSalt]'s reason: a world
/// seed has to describe the same veins to every player who types it in.
///
/// **Nothing on the gather path draws from the crawl's own generators.** That is
/// the D56 lesson written into the one place it could be broken: the moment
/// placing a node, or working one, took a number off `rng` or `lootRng`, every
/// recorded fight and every recorded drop on every seed would resolve
/// differently — and the four survivability bands are the instrument that would
/// have to be re-pinned instead of trusted. The count and the tiles come off
/// this stream; the yield is flat and draws nothing at all.
const int gatherSalt = 0x6A1E;

/// How richly one dungeon grows and what it grows.
///
/// A band rather than a single number, and the band's two ends rather than a
/// lowest and a width, following [ThemedDungeon.shallowestDelve]: every question
/// anyone asks of it is asked about an end.
class GatherBand {
  const GatherBand({
    required this.fewest,
    required this.most,
    required this.orePercent,
  });

  /// The fewest nodes a floor here lays out. **Never zero.** A floor that can
  /// hold nothing teaches the player not to look, and looking is the whole of
  /// what gathering asks of them.
  final int fewest;

  /// The most a floor here lays out.
  final int most;

  /// The chance in a hundred that a node here is a vein rather than a patch.
  ///
  /// A lean and never a rule: both kinds turn up in every dungeon, because a
  /// dungeon with only one of them would make one of the two skills untrainable
  /// in it, and a hero who happened to walk that way would find a control they
  /// could never press.
  final int orePercent;
}

/// The crypt's: the middle of the world, favouring neither kind.
///
/// **One to three, not zero to two.** The floor of one is argued above. The
/// ceiling of three is what makes the pacing work: a five-floor delve averages
/// ten nodes, so about five ore, so about two ingots — and the first temper
/// costs one ingot and ten gold, which puts a `+1` sword inside a single trip
/// while a `+3` one stays several trips away. At zero to two the same delve
/// averages five nodes, and the Blacksmith 5 gate on `+2` arrives about nine
/// delves in, which is a grind before the player has seen `+1` pay for itself.
const GatherBand cryptGathering = GatherBand(
  fewest: 1,
  most: 3,
  orePercent: 50,
);

/// The sea-cave's: things grow in the wet.
const GatherBand seaCaveGathering = GatherBand(
  fewest: 1,
  most: 3,
  orePercent: 35,
);

/// The ruined keep's: masonry and old iron.
const GatherBand ruinedKeepGathering = GatherBand(
  fewest: 1,
  most: 3,
  orePercent: 65,
);

/// How richly the dungeon at [node] grows.
///
/// Falls back to the crypt's band rather than throwing, because the crypt *is*
/// the fallback everywhere else a dungeon is asked about itself — see
/// `paletteFor` — and a road fight has no node at all.
GatherBand gatherBandFor(NodeId node) {
  if (node == seaCave) return seaCaveGathering;
  if (node == ruinedKeep) return ruinedKeepGathering;
  return cryptGathering;
}

/// The nodes one finished floor grows, drawn from [seed].
///
/// **Called last, after every other draw a floor makes, on a generator of its
/// own.** Both halves of that matter. Last, because a pass that ran earlier
/// would have to be threaded through the generator's own draws and could not
/// then be proved not to have moved them. Its own generator, because the count
/// and the tiles are draws, and a draw on the shared stream would shift every
/// creature and every piece of litter after it — which is the mechanism that
/// re-rolled four survivability bands the last time it was let loose.
///
/// [seed] is the floor's own seed folded with [gatherSalt] by the caller, so
/// this function has no opinion about the salt and a test can hand it a
/// different one.
///
/// Candidate tiles are exactly the plain floor of the map, minus the tile the
/// hero arrives on. Plain floor rather than walkable floor is what keeps nodes
/// off both flights of stairs without naming either: the stairs are their own
/// [Tile] cases. The walk is row by row and then column by column, which is
/// [byRowThenColumn]'s order — an index only names a tile if the list it indexes
/// into is in a stated order.
///
/// The draw order is the contract: the count first, then per node its tile and
/// then its kind. Two nodes never share a tile, because a placed tile leaves the
/// pool.
Map<Position, GatherKind> gatherNodesOn(
  FloorMap map,
  Position heroSpawn,
  int seed,
  GatherBand band,
) {
  final rng = Rng(seed);
  final count = rng.rollRange(band.fewest, band.most);
  final open = <Position>[
    for (var y = 0; y < map.height; y++)
      for (var x = 0; x < map.width; x++)
        if (map.tileAt(Position(x, y)) == Tile.floor &&
            Position(x, y) != heroSpawn)
          Position(x, y),
  ];
  final nodes = <Position, GatherKind>{};
  for (var placed = 0; placed < count && open.isNotEmpty; placed++) {
    final at = open.removeAt(rng.rollRange(0, open.length - 1));
    nodes[at] = rng.rollRange(1, 100) <= band.orePercent
        ? GatherKind.oreVein
        : GatherKind.herbPatch;
  }
  return nodes;
}
