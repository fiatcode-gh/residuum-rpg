import 'package:residuum_core/core.dart';

/// The starting sword: barely better than a fist, and the point of the game is
/// to replace it.
const BaseItem rustySword = BaseItem(
  id: 'rusty-sword',
  name: 'Rusty Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 2,
  attackMax: 3,
);

const BaseItem ironSword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

/// Hits harder than a sword and swings wider: the one-handed damage ceiling.
const BaseItem warAxe = BaseItem(
  id: 'war-axe',
  name: 'War Axe',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 4,
  attackMax: 7,
);

const BaseItem greatsword = BaseItem(
  id: 'greatsword',
  name: 'Greatsword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.two,
  attackMin: 6,
  attackMax: 9,
);

/// The heaviest thing in the game, and it costs you the shield to hold it.
const BaseItem maul = BaseItem(
  id: 'maul',
  name: 'Maul',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.two,
  attackMin: 7,
  attackMax: 11,
);

const BaseItem kiteShield = BaseItem(
  id: 'kite-shield',
  name: 'Kite Shield',
  glyph: '[',
  slot: EquipSlot.offHand,
  armor: 3,
  heavy: true,
);

const BaseItem ironHelm = BaseItem(
  id: 'iron-helm',
  name: 'Iron Helm',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 2,
  heavy: true,
);

const BaseItem leatherCap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

const BaseItem mailHauberk = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 4,
  heavy: true,
);

const BaseItem leatherJerkin = BaseItem(
  id: 'leather-jerkin',
  name: 'Leather Jerkin',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 2,
);

const BaseItem ironGauntlets = BaseItem(
  id: 'iron-gauntlets',
  name: 'Iron Gauntlets',
  glyph: '[',
  slot: EquipSlot.hands,
  armor: 2,
  heavy: true,
);

const BaseItem ironGreaves = BaseItem(
  id: 'iron-greaves',
  name: 'Iron Greaves',
  glyph: '[',
  slot: EquipSlot.feet,
  armor: 2,
  heavy: true,
);

const BaseItem leatherBoots = BaseItem(
  id: 'leather-boots',
  name: 'Leather Boots',
  glyph: '[',
  slot: EquipSlot.feet,
  armor: 1,
);

/// The only healing in the game this milestone. There is no regeneration, no
/// resting and no safe point, so how many of these the hero is carrying *is*
/// the decision about how much further down it can go.
const BaseItem healingPotion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 10,
);

/// Every base item in the game.
///
/// Heavy and light armour are deliberate alternatives rather than a ladder: a
/// leather cap and an iron helm both give one armour, and the difference is
/// which skill wearing it trains. Heavy trades the growing dodge of Fleetfoot
/// for the flat reduction of Bulwark, and the hero has to pick.
const List<BaseItem> armory = [
  rustySword,
  ironSword,
  warAxe,
  greatsword,
  maul,
  kiteShield,
  ironHelm,
  leatherCap,
  mailHauberk,
  leatherJerkin,
  ironGauntlets,
  ironGreaves,
  leatherBoots,
  healingPotion,
];

/// The base item with this [id], or null when nothing answers to it.
///
/// The nullable door exists for the save codec: an id read out of a file written
/// by an older build is a load failure with a sentence in it, not a crash, so the
/// codec has to be able to ask without being thrown at.
BaseItem? baseItemOrNull(String id) {
  for (final item in armory) {
    if (item.id == id) return item;
  }
  return null;
}

/// The base item with this [id].
///
/// Throws [ArgumentError] when nothing answers to it, so a typo in a drop table
/// fails the content validation tests rather than the game.
BaseItem baseItemById(String id) =>
    baseItemOrNull(id) ??
    (throw ArgumentError.value(id, 'id', 'no such base item'));
