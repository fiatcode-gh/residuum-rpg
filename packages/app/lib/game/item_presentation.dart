import 'package:residuum_core/core.dart';

/// The mark a tempered item wears beside its stats.
///
/// **Deliberately not a plus sign.** The rarity column already spends `+` on
/// Fine and `++` on Rare, so a temper drawn with plusses would put two
/// categories in one shape on a screen the author has to read in greyscale. The
/// word and the number ride beside it, so the line reads aloud as well: "plus
/// five to seven attack, temper plus two".
const String temperMarking = '‡';

/// What [item] adds, as a compact line of only the parts that are not zero.
///
/// Nothing here is told apart by colour: every part is a label and a signed
/// number, so the line reads in greyscale and it reads aloud.
///
/// The temper comes last and says only itself. What it *did* has already been
/// counted in the attack or the armour above it, because every stat an item has
/// is read through the item's own getters — so this part is the explanation of a
/// number the player can already see, not a second copy of it.
String statLine(Item item) => [
  ..._attackParts(item.attackMin, item.attackMax, 'atk'),
  if (item.armor != 0) '${_signed(item.armor)} arm',
  if (item.maxHp != 0) '${_signed(item.maxHp)} hp',
  if (item.speed != 0) '${_signed(item.speed)} spd',
  if (item.base.heal != 0) '${_signed(item.base.heal)} heal',
  if (item.temper != 0) '$temperMarking${_signed(item.temper)} temper',
].join(' · ');

/// What makes two items the same row in a list: the base, the tier, the affixes
/// and the temper — never the id.
///
/// Ids are unique by design, so keying on one would mean nothing ever stacked.
/// Stacking is a display decision about items the player cannot tell apart, and
/// the pack still holds each one separately: an action on a stack reaches for one
/// item of it.
///
/// **The temper is in the key for that last sentence's sake.** A `+2` sword and
/// a `+0` sword are not items the player cannot tell apart — one of them is the
/// one they paid six ingots for. Merged into one row, Wear would reach whichever
/// of the two the pack happened to hold first.
String stackKey(Item item) => [
  item.base.id,
  item.rarity.name,
  for (final affix in item.affixes) affix.id,
  'temper${item.temper}',
].join('|');

/// One row of a list: an item, and how many the hero is carrying like it.
class ItemStack {
  const ItemStack(this.item, this.count);

  /// The one item this row acts through.
  final Item item;

  final int count;

  /// What the row calls itself, counting only when there is more than one.
  String get label =>
      count > 1 ? '${item.displayName} ×$count' : item.displayName;
}

/// The four lists the pack is read in, in the order it reads them.
enum PackSection {
  weapons('Weapons'),
  armour('Armour'),
  potions('Potions'),
  books('Books');

  const PackSection(this.title);

  final String title;
}

/// The pack split into its four sections, each sorted and stacked.
///
/// Every section is present even when it is empty, so the screen's headings stay
/// in a fixed order — the position of a list is information the player can rely
/// on, which is what lets the sections be told apart without colour.
///
/// Within a section the order is slot, then tier best-first, then name. Slot
/// first because that is the decision the player is making — what goes on my
/// head — and tier next because inside one slot the better item is almost always
/// the one being looked for.
Map<PackSection, List<ItemStack>> packSections(List<Item> items) {
  final sorted = [...items]..sort(_byShelfOrder);
  return {
    for (final section in PackSection.values)
      section: _stacked([
        for (final item in sorted)
          if (_sectionOf(item) == section) item,
      ]),
  };
}

/// One stat's change from wearing a piece instead of what is worn now.
class StatDelta {
  const StatDelta(this.label, this.amount);

  final String label;

  /// Signed: positive is an improvement, negative is a loss.
  final int amount;

  /// The arrow that carries the direction without relying on hue.
  String get marker => amount > 0 ? '▲' : '▼';

  String get text => '$marker${_signed(amount)} $label';
}

/// What changes by wearing [item] in place of [worn], one entry per stat.
///
/// An empty slot compares against zeros, because that is exactly what wearing
/// nothing contributes. An identical piece yields an empty list, which
/// [deltaLine] turns into words rather than a blank.
///
/// A damage change that moves both ends of the range by the same amount reads as
/// one entry, because two lines saying `+1` about the same weapon is noise. The
/// split entries appear only when the ends genuinely move apart.
List<StatDelta> wornDeltas(Item item, Item? worn) {
  final minChange = item.attackMin - (worn?.attackMin ?? 0);
  final maxChange = item.attackMax - (worn?.attackMax ?? 0);
  final armorChange = item.armor - (worn?.armor ?? 0);
  final maxHpChange = item.maxHp - (worn?.maxHp ?? 0);
  final speedChange = item.speed - (worn?.speed ?? 0);
  return [
    if (minChange == maxChange && minChange != 0)
      StatDelta('atk', minChange)
    else ...[
      if (minChange != 0) StatDelta('atk min', minChange),
      if (maxChange != 0) StatDelta('atk max', maxChange),
    ],
    if (armorChange != 0) StatDelta('arm', armorChange),
    if (maxHpChange != 0) StatDelta('hp', maxHpChange),
    if (speedChange != 0) StatDelta('spd', speedChange),
  ];
}

/// [deltas] as one line, or the plain sentence for a piece that changes nothing.
String deltaLine(List<StatDelta> deltas) => deltas.isEmpty
    ? 'same as worn'
    : deltas.map((delta) => delta.text).join(' · ');

List<String> _attackParts(int min, int max, String label) {
  if (min == 0 && max == 0) return const [];
  if (min == max) return ['${_signed(min)} $label'];
  return ['${_signed(min)}-$max $label'];
}

String _signed(int amount) => amount > 0 ? '+$amount' : '$amount';

/// Which list an item is read in.
///
/// A weapon is what needs hands; anything else worn is armour; a book is what
/// teaches something; everything left is drunk.
///
/// **Books are named before the fall-through rather than after it**, and that
/// ordering is the whole fix: the last line used to catch everything that was
/// not worn or swung, so the first spell book ever added to the game would have
/// been filed under Potions and offered a Drink button. A kind the reader has
/// to know about is a kind this function has to name.
PackSection _sectionOf(Item item) {
  if (item.base.isWeapon) return PackSection.weapons;
  if (item.base.isEquippable) return PackSection.armour;
  if (item.base.isSpellBook) return PackSection.books;
  return PackSection.potions;
}

int _byShelfOrder(Item one, Item other) {
  final bySlot = _slotRank(one).compareTo(_slotRank(other));
  if (bySlot != 0) return bySlot;
  final byTier = other.rarity.index.compareTo(one.rarity.index);
  if (byTier != 0) return byTier;
  return one.displayName.compareTo(other.displayName);
}

int _slotRank(Item item) => item.base.slot?.index ?? EquipSlot.values.length;

List<ItemStack> _stacked(List<Item> items) {
  final counts = <String, int>{};
  final firsts = <String, Item>{};
  for (final item in items) {
    final key = stackKey(item);
    counts[key] = (counts[key] ?? 0) + 1;
    firsts[key] ??= item;
  }
  return [for (final key in firsts.keys) ItemStack(firsts[key]!, counts[key]!)];
}
