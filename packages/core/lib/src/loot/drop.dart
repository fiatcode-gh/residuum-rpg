import 'package:equatable/equatable.dart';

import '../engine/rng.dart';
import 'item.dart';
import 'rarity.dart';

/// One entry of a weighted table: a [value] and its share of the draw.
///
/// A weight of zero is never drawn. That is how [Rarity.legendary] exists as a
/// tier this milestone without ever appearing in a drop: sets arrive with M4,
/// and until then a Legendary would be an Epic wearing a better word.
class Weighted<T> extends Equatable {
  const Weighted(this.value, this.weight);

  final T value;

  /// Relative chance against the other entries of the same list.
  final int weight;

  @override
  List<Object?> get props => [value, weight];

  @override
  String toString() => 'Weighted($value, $weight)';
}

/// What one depth of the dungeon can give up.
///
/// A table is data, not behaviour, which is why the game state carries these
/// directly instead of a closure the way it carries its floor builder: nothing
/// about choosing an item needs to know where the numbers came from.
class DropTable extends Equatable {
  const DropTable({
    required this.items,
    required this.rarities,
    required this.weaponAffixes,
    required this.armourAffixes,
    required this.minFloorItems,
    required this.maxFloorItems,
  });

  final List<Weighted<BaseItem>> items;
  final List<Weighted<Rarity>> rarities;

  /// Drawn onto weapons. Kept apart from [armourAffixes] so a helmet never
  /// rolls a bonus that reads as a weapon's.
  final List<Affix> weaponAffixes;

  final List<Affix> armourAffixes;

  /// The fewest items this depth scatters before the hero arrives.
  final int minFloorItems;

  /// The most items this depth scatters before the hero arrives.
  final int maxFloorItems;

  @override
  List<Object?> get props => [
    items,
    rarities,
    weaponAffixes,
    armourAffixes,
    minFloorItems,
    maxFloorItems,
  ];

  @override
  String toString() => 'DropTable(${items.length} items)';
}

/// One item rolled off [table] with id [id], drawing every decision from [rng].
///
/// The order of draws is fixed — base item, then tier, then affixes — because
/// that order is part of the seed contract: two crawls on one world seed that
/// kill the same monsters in the same order must find the same loot, and a
/// reordered draw would break that as surely as a different seed would.
///
/// Affixes are drawn without replacement, so no item carries the same affix
/// twice. Each table's pools therefore need at least [Rarity.legendary]'s affix
/// count of entries; the content validation tests pin that.
///
/// A potion is forced to [Rarity.common]. Affixes on a consumable would be
/// bonuses on a thing that is never worn, and a 'Rare Healing Potion of Vigour'
/// promises the player something the rules cannot deliver.
Item rollDrop(DropTable table, Rng rng, String id) {
  final base = _draw(table.items, rng);
  if (base.isPotion) {
    return Item(id: id, base: base, rarity: Rarity.common);
  }
  final rarity = _draw(table.rarities, rng);
  final pool = [...base.isWeapon ? table.weaponAffixes : table.armourAffixes];
  final affixes = <Affix>[];
  while (affixes.length < rarity.affixCount && pool.isNotEmpty) {
    affixes.add(pool.removeAt(rng.rollRange(0, pool.length - 1)));
  }
  return Item(id: id, base: base, rarity: rarity, affixes: affixes);
}

/// How many items this depth scatters on the floor before the hero arrives.
int rollFloorItemCount(DropTable table, Rng rng) =>
    rng.rollRange(table.minFloorItems, table.maxFloorItems);

T _draw<T>(List<Weighted<T>> entries, Rng rng) {
  final total = entries.fold(0, (sum, entry) => sum + entry.weight);
  var roll = rng.rollRange(1, total);
  for (final entry in entries) {
    if (entry.weight == 0) continue;
    roll -= entry.weight;
    if (roll <= 0) return entry.value;
  }
  return entries.lastWhere((entry) => entry.weight > 0).value;
}
