import 'package:residuum_core/core.dart';

import '../affix_pool.dart';
import '../armory.dart';
import 'save_json.dart';

/// One item, as the registry entries it is made of.
///
/// **A reference, never a copy of the stats.** An item lives in a save for as
/// long as the hero keeps it, which may be longer than the build that dropped
/// it — so a saved Iron Sword has to become whatever an Iron Sword is in the
/// build that reads it, or every balance pass would leave a museum of old
/// numbers in players' vaults. The item's own [Item.id] is kept, because
/// uniqueness within a crawl is a contract the drop counter depends on.
///
/// **The temper is the one number here that is not a reference**, and it has to
/// be written rather than looked up for exactly the reason everything else is
/// looked up: it is not a fact about what an Iron Sword is, it is a fact about
/// what this hero paid for. A balance pass may change what an Iron Sword does; it
/// cannot change how many ingots went into this one. Always written, even at
/// zero, so a document has one shape and a missing key is never read as
/// "probably unworked".
Map<String, Object?> encodeItem(Item item) => {
  'id': item.id,
  'base': item.base.id,
  'rarity': item.rarity.name,
  'affixes': [for (final affix in item.affixes) affix.id],
  'temper': item.temper,
};

/// Every item in [items], in the order carried.
List<Object?> encodeItems(List<Item> items) => [
  for (final item in items) encodeItem(item),
];

/// One item, from the object [from].
Item decodeItem(Object? from) {
  if (from is! Map<String, Object?>) {
    throw SaveMalformed('an item in the save file is not an object');
  }
  final baseId = stringAt(from, 'base');
  final base = baseItemOrNull(baseId);
  if (base == null) {
    throw SaveMalformed(
      'the save file names an item this build does not have: "$baseId"',
    );
  }
  return Item(
    id: stringAt(from, 'id'),
    base: base,
    rarity: _rarityNamed(stringAt(from, 'rarity')),
    affixes: [
      for (final written in listAt(from, 'affixes')) _affixNamed(written),
    ],
    temper: _temperAt(from),
  );
}

/// Every item in the list at [key], in the order written.
List<Item> decodeItems(Map<String, Object?> from, String key) => [
  for (final written in listAt(from, key)) decodeItem(written),
];

/// Worn gear, by the name of the slot it is worn in.
Map<String, Object?> encodeEquipment(Equipment equipment) => {
  for (final slot in EquipSlot.values)
    if (equipment[slot] case final Item item) slot.name: encodeItem(item),
};

/// Worn gear, from the object at [key].
Equipment decodeEquipment(Map<String, Object?> from, String key) {
  final written = objectAt(from, key);
  return {
    for (final entry in written.entries)
      _slotNamed(entry.key): decodeItem(entry.value),
  };
}

/// How far every skill has come, by name.
Map<String, Object?> encodeSkills(Map<SkillId, SkillState> skills) => {
  for (final id in SkillId.values)
    if (skills[id] case final SkillState skill)
      id.name: {'level': skill.level, 'xp': skill.xp},
};

/// How far every skill has come, from the object at [key].
Map<SkillId, SkillState> decodeSkills(Map<String, Object?> from, String key) {
  final written = objectAt(from, key);
  return {
    for (final entry in written.entries)
      _skillNamed(entry.key): _skillFrom(entry.key, entry.value),
  };
}

/// What is lying on each tile, in a stable order.
List<Object?> encodeGroundItems(Map<Position, List<Item>> groundItems) {
  final tiles = groundItems.keys.toList()..sort(byRowThenColumn);
  return [
    for (final tile in tiles)
      {'x': tile.x, 'y': tile.y, 'items': encodeItems(groundItems[tile]!)},
  ];
}

/// What is lying on each tile, from the list at [key].
Map<Position, List<Item>> decodeGroundItems(
  Map<String, Object?> from,
  String key,
) {
  final litter = <Position, List<Item>>{};
  for (final tile in listAt(from, key)) {
    if (tile is! Map<String, Object?>) {
      throw SaveMalformed('a littered tile in the save file is not an object');
    }
    litter[Position(intAt(tile, 'x'), intAt(tile, 'y'))] = decodeItems(
      tile,
      'items',
    );
  }
  return litter;
}

/// How many times a forge worked this item, from the required key.
///
/// Required and range-checked rather than clamped, because this codec never
/// repairs: a document naming a fourth tier describes an item this build has no
/// arithmetic for, and quietly reading it as three would hand the player back a
/// weaker sword than the file says they own.
int _temperAt(Map<String, Object?> from) {
  final temper = intAt(from, 'temper');
  if (temper < 0 || temper > maxTemper) {
    throw SaveMalformed(
      'the save file has an item worked to temper $temper, and a forge goes to '
      '$maxTemper',
    );
  }
  return temper;
}

Rarity _rarityNamed(String name) {
  for (final rarity in Rarity.values) {
    if (rarity.name == name) return rarity;
  }
  throw SaveMalformed(
    'the save file names a rarity this build does not have: "$name"',
  );
}

Affix _affixNamed(Object? written) {
  if (written is! String) {
    throw SaveMalformed('an affix in the save file is not named by text');
  }
  final affix = affixOrNull(written);
  if (affix == null) {
    throw SaveMalformed(
      'the save file names an affix this build does not have: "$written"',
    );
  }
  return affix;
}

EquipSlot _slotNamed(String name) {
  for (final slot in EquipSlot.values) {
    if (slot.name == name) return slot;
  }
  throw SaveMalformed(
    'the save file names a gear slot this build does not have: "$name"',
  );
}

SkillId _skillNamed(String name) {
  for (final id in SkillId.values) {
    if (id.name == name) return id;
  }
  throw SaveMalformed(
    'the save file names a skill this build does not have: "$name"',
  );
}

SkillState _skillFrom(String name, Object? written) {
  if (written is! Map<String, Object?>) {
    throw SaveMalformed('the skill "$name" in the save file is not an object');
  }
  return SkillState(level: intAt(written, 'level'), xp: intAt(written, 'xp'));
}
