/// One kind of stuff the hero gathers, carries home and spends in a town room.
///
/// **A counter, never an item, and the difference is a design decision rather
/// than a convenience.** The pack cap is a decision about *gear*: twenty slots,
/// and filling one is choosing to carry a sword instead of a helm. A currency
/// that took slots would tax that choice with something the player never chose
/// — fifteen ore and ten herbs do not fit at all — and would then have to
/// answer six more questions it has no business answering: which pack section
/// ore is read in (the fall-through would offer it a Drink button), which glyph
/// it draws as in a closed glyph set, what the merchant pays for a thing whose
/// worth is read off attack and armour, whether the bot picks it up, and — the
/// one that matters most — what a new entry does to the drop tables' weight
/// total, which is the number every band line in this repository is measured
/// against.
///
/// So materials mirror [Profile.gold] instead: a number on the profile and a
/// number on the crawl, carried in at the door, carried out alive, and taken by
/// death. They ride exactly the risk gold rides, because they are earned the
/// same way — underfoot, in the dark, several floors from home.
///
/// [marking] exists because the author is deuteranomalous and hue alone must
/// never carry a category, and [word] is what makes a row read aloud. Between
/// them a materials panel is legible in greyscale, which is the standing rule.
enum MaterialId {
  /// What a vein gives up. The bulk material, and the only one that is smelted.
  ore(word: 'Ore', marking: '◆'),

  /// What a forge makes of ore, and what a temper is paid in.
  ingot(word: 'Ingot', marking: '▮'),

  /// What a patch gives up, and what an alchemist brews with.
  herb(word: 'Herb', marking: '✿');

  const MaterialId({required this.word, required this.marking});

  /// What a row calls this material, in words rather than an enum name.
  final String word;

  /// The non-hue mark a row draws beside it.
  final String marking;
}

/// [materials] with [change] more of [material], which may be negative.
///
/// **A counter that reaches zero loses its entry**, which is
/// [GameState.groundItems]' rule about bare tiles applied to the purse: the
/// map's size is what the hero actually carries, so a save file never grows a
/// key for a material the hero spent, and a panel never draws a row of nothing.
///
/// Never returns a negative count; the callers refuse before they spend, and a
/// count below zero would be a debt the game has no way to collect.
Map<MaterialId, int> withMaterial(
  Map<MaterialId, int> materials,
  MaterialId material,
  int change,
) {
  final after = countOf(materials, material) + change;
  final without = {...materials}..remove(material);
  return after <= 0 ? without : {...without, material: after};
}

/// How much of [material] [materials] holds, zero when it holds none.
int countOf(Map<MaterialId, int> materials, MaterialId material) =>
    materials[material] ?? 0;
