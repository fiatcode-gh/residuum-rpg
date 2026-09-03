import 'package:equatable/equatable.dart';

import 'equip_slot.dart';
import 'rarity.dart';

/// How many hands a weapon needs.
enum WeaponHands { one, two }

/// One kind of thing that can be found, before any affix is rolled onto it.
///
/// Content-defined and identified by [id]. A base item is a template: the thing
/// the hero actually carries is an [Item], which is this plus a [Rarity] and
/// the affixes that tier bought.
///
/// The stat fields are additive contributions, not totals. A weapon's
/// [attackMin] and [attackMax] are what it adds to the hero's bare fists, so a
/// hero who drops everything still punches rather than dealing nothing.
class BaseItem extends Equatable {
  const BaseItem({
    required this.id,
    required this.name,
    required this.glyph,
    this.slot,
    this.hands,
    this.attackMin = 0,
    this.attackMax = 0,
    this.armor = 0,
    this.heavy = false,
    this.heal = 0,
    this.teaches,
  });

  final String id;
  final String name;

  /// The single character this item draws as on the floor: `)`, `[`, `!` or
  /// `?`.
  final String glyph;

  /// Where it is worn, or null when it is not worn at all.
  final EquipSlot? slot;

  /// Weapons only; null otherwise.
  final WeaponHands? hands;

  final int attackMin;
  final int attackMax;
  final int armor;

  /// Whether wearing this trains Bulwark rather than Fleetfoot.
  final bool heavy;

  /// Potions only; how much one restores.
  final int heal;

  /// Spell books only; the id of the spell reading this teaches.
  ///
  /// The id rather than the spell, because `core`'s item layer has no business
  /// holding content's spell table: the book names what it teaches and the
  /// registry on the game state answers for it, exactly as a drop table names
  /// base items and the armory answers for those.
  final String? teaches;

  /// Whether this is swung. Weapons are the only items that need hands.
  bool get isWeapon => hands != null;

  /// Whether this is worn for protection rather than swung.
  bool get isArmour => slot != null && hands == null;

  /// Whether this is drunk.
  bool get isPotion => heal > 0;

  /// Whether this is read, and spent by reading.
  bool get isSpellBook => teaches != null;

  /// Whether using this spends it.
  ///
  /// The one question the drop roller asks, and the reason it is a predicate
  /// rather than two: an affix on a thing that is used up once is a bonus on
  /// something that will not be there tomorrow, so a 'Rare Book of Firebolt'
  /// promises the player exactly as much as a 'Rare Healing Potion of Vigour'
  /// does, which is nothing.
  bool get isConsumable => isPotion || isSpellBook;

  /// Whether this belongs in a slot at all.
  bool get isEquippable => slot != null;

  /// Whether a forge can work this: steel only, so a weapon or a piece of
  /// armour and nothing else.
  ///
  /// **One predicate with three readers**, which is the reason it is here rather
  /// than spelled out at each of them: the stat getters ask it to decide where a
  /// tier lands, `sellPriceOf` asks it so a price can never disagree with the
  /// forge about what was worked, and `temperRefusal` asks it to say 'only steel
  /// takes a temper'. Three copies of `isWeapon || isArmour` is three chances
  /// for a fourth kind of item to be added to two of them.
  bool get takesTemper => isWeapon || isArmour;

  @override
  List<Object?> get props => [
    id,
    name,
    glyph,
    slot,
    hands,
    attackMin,
    attackMax,
    armor,
    heavy,
    heal,
    teaches,
  ];

  @override
  String toString() => 'BaseItem($id)';
}

/// A bonus rolled onto a base item.
///
/// One word each, so a display name reads as English: a prefix before the base
/// name, a suffix after it.
class Affix extends Equatable {
  const Affix({
    required this.id,
    required this.affixName,
    required this.isPrefix,
    this.attackMin = 0,
    this.attackMax = 0,
    this.armor = 0,
    this.maxHp = 0,
    this.speed = 0,
  });

  final String id;

  /// The word this affix contributes to an item's name: 'Keen', 'of Embers'.
  final String affixName;

  /// Whether that word goes before the base name rather than after it.
  final bool isPrefix;

  final int attackMin;
  final int attackMax;
  final int armor;
  final int maxHp;
  final int speed;

  @override
  List<Object?> get props => [
    id,
    affixName,
    isPrefix,
    attackMin,
    attackMax,
    armor,
    maxHp,
    speed,
  ];

  @override
  String toString() => 'Affix($id)';
}

/// One rolled item: a base, a tier, and the affixes that tier bought.
///
/// [id] is unique within a crawl and comes from one of three namespaces —
/// `kit-<n>` for what the hero starts with, `floor-<depth>-<n>` for what a
/// floor was built holding, and `drop-<n>` for what a kill produced. They are
/// separate because the floor builder is a content closure and the drop roller
/// lives in the rules, and threading one shared counter between them would put
/// mutable state inside the closure for no gain. Uniqueness is the contract;
/// a single counter was never it.
class Item extends Equatable {
  const Item({
    required this.id,
    required this.base,
    required this.rarity,
    this.affixes = const [],
    this.temper = 0,
  });

  final String id;
  final BaseItem base;
  final Rarity rarity;

  /// Always exactly [Rarity.affixCount] long.
  final List<Affix> affixes;

  /// How many times a forge has worked this piece: zero to three.
  ///
  /// **The one number on an item that a dungeon never rolls.** Rarity and
  /// affixes are what the world gave; this is what the hero paid for, which is
  /// the whole of what crafting is allowed to be here — it serves loot and never
  /// competes with it, so best in slot stays a found item somebody invested in.
  /// `temperItem` is the only thing that changes it.
  ///
  /// A tier adds to what the piece is *for*: both ends of a weapon's damage,
  /// because a smith makes the whole blade better, or a piece of armour's
  /// armour. It never reaches hit points or speed — neither of those is steel.
  ///
  /// It is part of [props], and that is load-bearing rather than tidy: two
  /// swords that differ only here would otherwise compare equal, a list would
  /// merge them into one row, and an action on the row would reach whichever of
  /// the two came first.
  final int temper;

  /// What the log and the inventory call this item.
  ///
  /// The tier word opens the name so rarity is legible without any colour at
  /// all: 'Rare Keen Iron Sword of Embers'.
  String get displayName => [
    rarity.word,
    for (final affix in affixes)
      if (affix.isPrefix) affix.affixName,
    base.name,
    for (final affix in affixes)
      if (!affix.isPrefix) affix.affixName,
  ].join(' ');

  int get attackMin => _sum(base.attackMin + _weaponTemper, (a) => a.attackMin);

  int get attackMax => _sum(base.attackMax + _weaponTemper, (a) => a.attackMax);

  int get armor => _sum(base.armor + _armourTemper, (affix) => affix.armor);

  int get maxHp => _sum(0, (affix) => affix.maxHp);

  int get speed => _sum(0, (affix) => affix.speed);

  int _sum(int from, int Function(Affix) of) =>
      affixes.fold(from, (total, affix) => total + of(affix));

  int get _weaponTemper => base.isWeapon ? temper : 0;

  int get _armourTemper => base.isArmour ? temper : 0;

  /// This item worked to [temper] instead.
  ///
  /// Narrower than a `copyWith` on purpose. Every other field of an item is
  /// settled the moment it is rolled, so a general copy would be a door onto
  /// changing a rarity or an id, and the only reason to open one is this.
  Item tempered(int temper) => Item(
    id: id,
    base: base,
    rarity: rarity,
    affixes: affixes,
    temper: temper,
  );

  /// This item answering to [id] instead.
  ///
  /// Narrower than a `copyWith` on purpose, for [tempered]'s reason: every other
  /// field of an item is settled the moment it is rolled, and the only reason to
  /// change an id is the mint at the pack's door — the moment a ground item
  /// becomes a pack item, its transient litter id gives way to the hero's
  /// durable `item-<n>`. Everything else about the item travels untouched.
  Item withId(String id) => Item(
    id: id,
    base: base,
    rarity: rarity,
    affixes: affixes,
    temper: temper,
  );

  @override
  List<Object?> get props => [id, base, rarity, affixes, temper];

  @override
  String toString() => 'Item($id, $displayName)';
}

/// The list with its FIRST item answering to [id] gone, in order.
///
/// **One tap, one item.** After the mint at the pack's door, ids are unique by
/// construction, so removing the first match and removing every match coincide
/// on every pack the game can mint. On a pack inherited from an older save the
/// two differ — legacy saves can hold duplicate ids — and removing exactly one
/// is the honest semantics: the tap named one thing, and one thing is what it
/// takes. The first match in the list's existing order is the oldest, which
/// makes the removal deterministic through every sell-and-rebuy cycle.
List<Item> withoutFirst(List<Item> items, String id) {
  final at = items.indexWhere((item) => item.id == id);
  if (at < 0) return items;
  return [...items]..removeAt(at);
}
