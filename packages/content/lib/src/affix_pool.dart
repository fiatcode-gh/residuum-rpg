import 'package:residuum_core/core.dart';

const Affix keen = Affix(
  id: 'keen',
  affixName: 'Keen',
  isPrefix: true,
  attackMax: 2,
);

const Affix vicious = Affix(
  id: 'vicious',
  affixName: 'Vicious',
  isPrefix: true,
  attackMin: 2,
  attackMax: 3,
);

const Affix ofEmbers = Affix(
  id: 'of-embers',
  affixName: 'of Embers',
  isPrefix: false,
  attackMin: 1,
  attackMax: 2,
);

const Affix ofFury = Affix(
  id: 'of-fury',
  affixName: 'of Fury',
  isPrefix: false,
  attackMax: 1,
  speed: 1,
);

const Affix sturdy = Affix(
  id: 'sturdy',
  affixName: 'Sturdy',
  isPrefix: true,
  armor: 2,
);

const Affix reinforced = Affix(
  id: 'reinforced',
  affixName: 'Reinforced',
  isPrefix: true,
  armor: 3,
);

const Affix ofVigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 6,
);

const Affix ofSwiftness = Affix(
  id: 'of-swiftness',
  affixName: 'of Swiftness',
  isPrefix: false,
  speed: 2,
);

/// What a weapon can roll.
///
/// Four entries, which is the floor rather than a coincidence: affixes are
/// drawn without replacement and a Legendary rolls four, so a pool of three
/// would make `affixes.length == rarity.affixCount` a promise the roll could
/// not keep.
const List<Affix> weaponAffixes = [keen, vicious, ofEmbers, ofFury];

/// What a piece of armour or a shield can roll. Four, for the same reason as
/// [weaponAffixes].
const List<Affix> armourAffixes = [sturdy, reinforced, ofVigour, ofSwiftness];

/// Every affix in the game.
const List<Affix> affixPool = [...weaponAffixes, ...armourAffixes];

/// The affix with this [id], or null when nothing answers to it.
///
/// The nullable door exists for the save codec, for the same reason
/// [baseItemOrNull] does: an unknown id out of a save file is a sentence the
/// player reads, not an exception.
Affix? affixOrNull(String id) {
  for (final affix in affixPool) {
    if (affix.id == id) return affix;
  }
  return null;
}

/// The affix with this [id].
///
/// Throws [ArgumentError] when nothing answers to it.
Affix affixById(String id) =>
    affixOrNull(id) ?? (throw ArgumentError.value(id, 'id', 'no such affix'));
