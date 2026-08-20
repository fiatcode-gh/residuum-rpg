/// How much an item was blessed on the way out of the dungeon.
///
/// A tier *is* its affix count: that is the whole definition, and every other
/// difference between a Common and an Epic follows from how many affixes got
/// rolled onto the same base item.
///
/// [marking] exists because the author is deuteranomalous and hue alone must
/// never carry a category. A list of items reads correctly in greyscale, on a
/// monochrome display, and aloud, because the tier is a glyph and [word] is
/// part of the item's own name.
enum Rarity {
  common(affixCount: 0, marking: '·', word: 'Common'),
  fine(affixCount: 1, marking: '+', word: 'Fine'),
  rare(affixCount: 2, marking: '++', word: 'Rare'),
  epic(affixCount: 3, marking: '※', word: 'Epic'),
  legendary(affixCount: 4, marking: '★', word: 'Legendary');

  const Rarity({
    required this.affixCount,
    required this.marking,
    required this.word,
  });

  /// How many affixes an item of this tier rolls.
  final int affixCount;

  /// The non-hue mark a list draws beside an item of this tier.
  final String marking;

  /// The tier word that opens the item's display name.
  final String word;
}
