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
  });

  final String id;
  final String name;

  /// The single character this item draws as on the floor: `)`, `[` or `!`.
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

  /// Whether this is swung. Weapons are the only items that need hands.
  bool get isWeapon => hands != null;

  /// Whether this is worn for protection rather than swung.
  bool get isArmour => slot != null && hands == null;

  /// Whether this is drunk.
  bool get isPotion => heal > 0;

  /// Whether this belongs in a slot at all.
  bool get isEquippable => slot != null;

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
  });

  final String id;
  final BaseItem base;
  final Rarity rarity;

  /// Always exactly [Rarity.affixCount] long.
  final List<Affix> affixes;

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

  int get attackMin => _sum(base.attackMin, (affix) => affix.attackMin);

  int get attackMax => _sum(base.attackMax, (affix) => affix.attackMax);

  int get armor => _sum(base.armor, (affix) => affix.armor);

  int get maxHp => _sum(0, (affix) => affix.maxHp);

  int get speed => _sum(0, (affix) => affix.speed);

  int _sum(int from, int Function(Affix) of) =>
      affixes.fold(from, (total, affix) => total + of(affix));

  @override
  List<Object?> get props => [id, base, rarity, affixes];

  @override
  String toString() => 'Item($id, $displayName)';
}
