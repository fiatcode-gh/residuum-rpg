import 'dart:math' as math;

import 'package:residuum_core/core.dart';

import 'dungeon_palette.dart';

/// The dungeon's material layer, as data.
///
/// Unit 2 separates **what the place is made of** from **what the player
/// sees**: the glyph plan already carries terrain as terminal characters for
/// characterization, and this plan carries the same knowledge boundary as
/// explicit presentation facts instead — tile kind, visible-vs-remembered
/// knowledge, and a presentation-only light value per known tile.
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
    required this.light,
  });

  final Position position;
  final MaterialTileKind kind;

  /// Seeing it now vs. remembering it — [MaterialKnowledge.visible] tiles get
  /// the full material response and the warm local light; remembered tiles
  /// are dark, flat, and unlit.
  final MaterialKnowledge knowledge;

  /// Presentation light 0..1. Positive only inside the authoritative visible
  /// set; remembered tiles are always 0.0.
  final double light;

  /// Whether this cell is lit by the presentation light.
  bool get lit => knowledge == MaterialKnowledge.visible && light > 0;

  @override
  bool operator ==(Object other) =>
      other is MaterialCell &&
      other.position == position &&
      other.kind == kind &&
      other.knowledge == knowledge &&
      other.light == light;

  @override
  int get hashCode => Object.hash(position, kind, knowledge, light);
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
  });

  /// 0..1 strength of fine surface grit.
  final double grit;

  /// Whether a single small speck (chip/pebble) sits on this tile.
  final bool speck;

  /// 0..1 hairline-crack strength; 0 means no crack.
  final double crack;

  /// 0..1 structural edge response for walls; 0 means no edge treatment.
  final double edge;

  @override
  bool operator ==(Object other) =>
      other is MaterialMark &&
      other.grit == grit &&
      other.speck == speck &&
      other.crack == crack &&
      other.edge == edge;

  @override
  int get hashCode => Object.hash(grit, speck, crack, edge);
}

/// The whole material layer of one crawl, in draw order.
///
/// The plan is renderer-neutral: the Flame scene consumes [cells] and [marks]
/// without ever learning a tile kind from a glyph character, without running
/// a second FOV, and without ever drawing outside the authoritative known
/// set.
class MaterialPlan {
  const MaterialPlan({
    required this.cells,
    required this.marks,
    required this.masonry,
    required this.heroPosition,
  });

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
/// authoritative for both presence and lighting. Unknown neighbors influence
/// nothing: a wall's edge treatment is computed only from **known** adjacency,
/// so the material can never disclose unseen geometry.
MaterialPlan materialPlan(GameState game, DungeonPalette palette) {
  final cells = <MaterialCell>[];
  final marks = <Position, MaterialMark>{};
  final known = {...game.visible, ...game.explored};
  final hero = game.hero.position;

  for (final position in known) {
    final kind = _kindOf(game.map.tileAt(position));
    final knowledge = game.visible.contains(position)
        ? MaterialKnowledge.visible
        : MaterialKnowledge.remembered;
    final dx = position.x - hero.x;
    final dy = position.y - hero.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final falloff = _presentationLight(distance);
    final light = knowledge == MaterialKnowledge.visible ? falloff : 0.0;

    cells.add(
      MaterialCell(
        position: position,
        kind: kind,
        knowledge: knowledge,
        light: light,
      ),
    );
    marks[position] = _markFor(position, kind, knowledge, palette);
  }

  cells.sort((a, b) {
    final byY = a.position.y.compareTo(b.position.y);
    return byY != 0 ? byY : a.position.x.compareTo(b.position.x);
  });

  return MaterialPlan(
    cells: cells,
    marks: marks,
    masonry: _masonryMass(cells),
    heroPosition: hero,
  );
}

/// The presentation light at a distance from the hero, 0..1.
///
/// A smoothstep over the FOV radius: near-full light holds a plateau around
/// the hero, then eases off to the edge of sight — a warm pool on the stone,
/// not a straight-line wedge. The visible set stays authoritative; this only
/// shapes the light inside it.
double _presentationLight(double distance) {
  final t = (1.0 - distance / (fovRadius + 1)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
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
  DungeonPalette palette,
) {
  final themeSalt = palette.themeSalt;
  final gritH = _hash(position, themeSalt ^ 0x1111, kind.index);
  final speckH = _hash(position, themeSalt ^ 0x2222, kind.index);
  final crackH = _hash(position, themeSalt ^ 0x3333, kind.index);
  final edgeH = _hash(position, themeSalt ^ 0x4444, kind.index);

  final remembered = knowledge == MaterialKnowledge.remembered;
  final detailScale = remembered ? 0.35 : 1.0;

  final grit =
      _unit01(gritH) *
      (kind == MaterialTileKind.wall ? 0.7 : 0.4) *
      detailScale;
  final speck = _unit01(speckH) > (remembered ? 0.93 : 0.86);
  final crack = kind == MaterialTileKind.wall && !remembered
      ? (_unit01(crackH) > 0.82 ? _unit01(crackH >> 16) * 0.6 : 0.0)
      : 0.0;
  final edge = kind == MaterialTileKind.wall
      ? _unit01(edgeH) * (remembered ? 0.25 : 0.85)
      : 0.0;

  return MaterialMark(grit: grit, speck: speck, crack: crack, edge: edge);
}
