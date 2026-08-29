import '../skills/skill.dart';
import 'material.dart';

/// One thing on a dungeon floor the hero can work with their hands.
///
/// **Not a [Tile] and not an [Item], and each of those two is load-bearing on
/// its own.**
///
/// A fifth `Tile` case would change `toAscii`, which every map-byte golden in
/// this repository is written in — and a case that was not walkable would
/// re-shape the flow fields the monsters path on and move where the generator
/// is willing to put stairs, so the crypt's frozen layouts would stop being the
/// crypt's layouts. A node has to be something the hero *stands on*, so the
/// tile under it stays [Tile.floor] and the terrain is untouched.
///
/// An item would ride `groundItems`, which the litter pins count and the balance
/// bot picks up. Materials are not loot and must not compete with it, so a vein
/// is neither a thing lying there nor part of the floor: it is state over the
/// tile, `Map<Position, GatherKind>`, modelled field for field on `groundItems`
/// and living exactly as long — per floor, per run, gone when it is worked.
///
/// **Named `GatherKind` and not `NodeKind` because that name is taken**, by the
/// world map's town-or-dungeon question. Two enums of one name in one exported
/// barrel is not a style choice.
///
/// [glyph] is one character from outside every set already in use: the terrain's
/// `#`, `.`, `<`, `>`, the hero's `@`, the four item glyphs, and the letters
/// every creature draws as. [marking] and [word] are what let a row about a node
/// read in greyscale and read aloud.
enum GatherKind {
  /// A seam of metal in the rock. Mined, and it trains Blacksmith.
  oreVein(glyph: '*', marking: '◆', word: 'ore vein', yields: MaterialId.ore),

  /// Something growing where it should not. Gathered, and it trains Herbcraft.
  herbPatch(
    glyph: '"',
    marking: '✿',
    word: 'herb patch',
    yields: MaterialId.herb,
  );

  const GatherKind({
    required this.glyph,
    required this.marking,
    required this.word,
    required this.yields,
  });

  /// The single character this draws as on the floor.
  final String glyph;

  /// The non-hue mark a row draws beside it.
  final String marking;

  /// What the log and the controls call this, in words.
  final String word;

  /// What working it gives the hero one of.
  final MaterialId yields;

  /// Which craft working it teaches.
  ///
  /// One point per success, which is exactly what a landed swing and a
  /// successful cast are worth. A pick is a pick whether the vein is on depth
  /// one or depth seven, so the grant does not scale with depth: what deeper
  /// floors give is more veins, not richer ones.
  SkillId get trains => switch (this) {
    GatherKind.oreVein => SkillId.blacksmith,
    GatherKind.herbPatch => SkillId.herbcraft,
  };

  /// What the control on the crawl screen says: the verb, not the noun.
  ///
  /// Two words rather than one shared 'Gather', because the two things read
  /// differently to a player — you mine a seam and you pick a plant — and the
  /// label is the only place the difference is ever said out loud.
  String get verb => switch (this) {
    GatherKind.oreVein => 'Mine',
    GatherKind.herbPatch => 'Gather',
  };
}
