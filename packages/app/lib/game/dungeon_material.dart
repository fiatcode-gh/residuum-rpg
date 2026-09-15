import 'package:residuum_core/core.dart';

import 'dungeon_palette.dart';

/// The dungeon's material layer, as data.
///
/// Unit 2 separates **what the place is made of** from **what the player
/// sees**: the glyph plan already carries terrain as terminal characters for
/// characterization, and this plan carries the same knowledge boundary as
/// explicit presentation facts instead — tile kind and visible-vs-remembered
/// knowledge.
///
/// Everything here is pure and deterministic. Decorative variation is hashed
/// from coordinate, kind, knowledge, and theme — it never consumes gameplay
/// RNG, never sees the frame clock, and reproduces itself identically across
/// rebuilds, syncs, and revisits.
enum MaterialTileKind { wall, floor, stairsDown, stairsUp }

/// How the hero knows a tile: seeing it now, or remembering it.
enum MaterialKnowledge { visible, remembered }

/// One known terrain tile of the material layer.
class MaterialCell {
  const MaterialCell({
    required this.position,
    required this.kind,
    required this.knowledge,
  });

  final Position position;
  final MaterialTileKind kind;

  /// Seeing it now vs. remembering it. The renderer uses this authoritative
  /// knowledge boundary to decide material detail and clip local light.
  final MaterialKnowledge knowledge;

  @override
  bool operator ==(Object other) =>
      other is MaterialCell &&
      other.position == position &&
      other.kind == kind &&
      other.knowledge == knowledge;

  @override
  int get hashCode => Object.hash(position, kind, knowledge);
}

/// The material layer's deterministic decorative decisions for one tile.
///
/// Marks are pure data, hashed from position/kind/knowledge/theme, so the
/// renderer can draw grit, cracks, and edge treatment without owning any
/// randomness of its own. Two equal inputs produce equal marks — the hash is
/// canonical, not incidental.
class MaterialMark {
  const MaterialMark({
    required this.grit,
    required this.speck,
    required this.crack,
    required this.edge,
    required this.pattern,
  });

  /// 0..1 strength of fine surface grit.
  final double grit;

  /// Whether a single small speck (chip/pebble) sits on this tile.
  final bool speck;

  /// 0..1 hairline-crack strength; 0 means no crack.
  final double crack;

  /// 0..1 structural edge response for walls; 0 means no edge treatment.
  final double edge;

  final double pattern;

  @override
  bool operator ==(Object other) =>
      other is MaterialMark &&
      other.grit == grit &&
      other.speck == speck &&
      other.crack == crack &&
      other.edge == edge &&
      other.pattern == pattern;

  @override
  int get hashCode => Object.hash(grit, speck, crack, edge, pattern);
}

/// The whole material layer of one crawl, in draw order.
///
/// The plan is renderer-neutral: the Flame scene consumes [cells] and [marks]
/// without ever learning a tile kind from a glyph character, without running
/// a second FOV, and without ever drawing outside the authoritative known
/// set.
class MaterialPlan {
  MaterialPlan({
    required List<MaterialCell> cells,
    required Map<Position, MaterialMark> marks,
    required Set<Position> masonry,
    required this.heroPosition,
    required this.palette,
  }) : cells = List.unmodifiable(cells),
       marks = Map.unmodifiable(marks),
       masonry = Set.unmodifiable(masonry);

  final List<MaterialCell> cells;

  /// Deterministic decorative decisions keyed by tile position.
  final Map<Position, MaterialMark> marks;

  /// Which known walls are part of a masonry mass.
  ///
  /// A wall joins the mass when **known** neighbours flank it, so adjacent
  /// walls read as one continuous structure. Unknown neighbours count as
  /// closed — they join nothing and change nothing — which keeps the
  /// knowledge boundary out of the masonry.
  final Set<Position> masonry;

  final Position heroPosition;

  final DungeonPalette palette;

  MaterialCell? cellAt(Position position) {
    for (final cell in cells) {
      if (cell.position == position) return cell;
    }
    return null;
  }

  MaterialMark? markAt(Position position) => marks[position];

  /// Whether a wall reads as part of a masonry mass.
  bool masonryAt(Position position) => masonry.contains(position);
}

/// The tile kind a tile actually is — the fact, not a glyph string.
MaterialTileKind _kindOf(Tile tile) => switch (tile) {
  Tile.wall => MaterialTileKind.wall,
  Tile.floor => MaterialTileKind.floor,
  Tile.stairsDown => MaterialTileKind.stairsDown,
  Tile.stairsUp => MaterialTileKind.stairsUp,
};

/// Pure presentation hashing: splitmix-style mixing, coordinate + theme salt.
///
/// Same inputs → same output. Never reads gameplay RNG, never the frame
/// clock.
int _hash(Position position, int salt, int extra) {
  var h = 0x9E3779B97F4A7C15 ^ salt ^ (extra * 0x2545F4914F6CDD1D);
  h ^= position.x * 0x9E3779B1;
  h ^= position.y * 0xC2B2AE35;
  h &= 0x7FFFFFFFFFFFFFFF;
  h ^= h >> 30;
  h *= 0xBF58476D1CE4E5B9;
  h &= 0x7FFFFFFFFFFFFFFF;
  h ^= h >> 27;
  h *= 0x94D049BB133111EB;
  h &= 0x7FFFFFFFFFFFFFFF;
  return h;
}

double _unit01(int h) => (h & 0xFFFFFFFF) / 0xFFFFFFFF;

/// Builds the material plan for one crawl.
///
/// Only tiles in `visible ∪ explored` appear; the visible set stays
/// authoritative for material presence. Unknown neighbors influence nothing:
/// a wall's edge treatment is computed only from **known** adjacency, so the
/// material can never disclose unseen geometry.
MaterialPlan materialPlan(GameState game, DungeonPalette palette) {
  final cells = <MaterialCell>[];
  final known = {...game.visible, ...game.explored};
  final hero = game.hero.position;

  for (final position in known) {
    final kind = _kindOf(game.map.tileAt(position));
    final knowledge = game.visible.contains(position)
        ? MaterialKnowledge.visible
        : MaterialKnowledge.remembered;
    cells.add(
      MaterialCell(position: position, kind: kind, knowledge: knowledge),
    );
  }

  cells.sort((a, b) {
    final byY = a.position.y.compareTo(b.position.y);
    return byY != 0 ? byY : a.position.x.compareTo(b.position.x);
  });
  final masonry = _masonryMass(cells);
  final marks = {
    for (final cell in cells)
      cell.position: _markFor(
        cell.position,
        cell.kind,
        cell.knowledge,
        palette,
        masonry: masonry.contains(cell.position),
      ),
  };

  return MaterialPlan(
    cells: cells,
    marks: marks,
    masonry: masonry,
    heroPosition: hero,
    palette: palette,
  );
}

/// Which walls read as one masonry mass.
///
/// A wall joins when two or more of its orthogonal neighbours are known
/// walls; a lone corner or an exposed wall face stands on its own. Unknown
/// neighbours are simply absent from the count — they neither join a mass
/// nor break one — so the treatment of a known wall never depends on what
/// the hero has not seen.
Set<Position> _masonryMass(List<MaterialCell> cells) {
  final walls = {
    for (final cell in cells)
      if (cell.kind == MaterialTileKind.wall) cell.position,
  };
  return {
    for (final position in walls)
      if (Direction.values
              .map((direction) => position.step(direction))
              .where(walls.contains)
              .length >=
          2)
        position,
  };
}

MaterialMark _markFor(
  Position position,
  MaterialTileKind kind,
  MaterialKnowledge knowledge,
  DungeonPalette palette, {
  required bool masonry,
}) {
  final themeSalt = palette.themeSalt;
  final remembered = knowledge == MaterialKnowledge.remembered;
  final visibleFloor =
      knowledge == MaterialKnowledge.visible && kind == MaterialTileKind.floor;
  final visibleExposedWall =
      knowledge == MaterialKnowledge.visible &&
      kind == MaterialTileKind.wall &&
      !masonry;
  final grit =
      _unit01(_hash(position, themeSalt ^ 0x1111, kind.index)) *
      (kind == MaterialTileKind.wall ? 0.7 : 0.4) *
      (remembered ? 0.35 : 1.0);
  final speck =
      visibleFloor &&
      _unit01(_hash(position, themeSalt ^ 0x2222, kind.index)) > 0.86;
  final crackHash = visibleExposedWall
      ? _hash(position, themeSalt ^ 0x3333, kind.index)
      : 0;
  final crack = _unit01(crackHash) > 0.82
      ? _unit01(crackHash >> 16) * 0.6
      : 0.0;
  final edge = visibleExposedWall
      ? _unit01(_hash(position, themeSalt ^ 0x4444, kind.index)) * 0.85
      : 0.0;

  final pattern = remembered
      ? 0.0
      : _unit01(_hash(position, palette.themeSalt ^ 0x5555, kind.index));

  return MaterialMark(
    grit: grit,
    speck: speck,
    crack: crack,
    edge: edge,
    pattern: pattern,
  );
}
