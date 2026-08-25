import 'package:residuum_core/core.dart';

import '../new_game.dart';
import '../spells.dart';
import 'item_codec.dart';
import 'save_json.dart';

/// The hero between runs, as the fields a dungeon earned them.
///
/// **The profile's hero saves what it earned; a run's actors save everything.**
/// Both halves are deliberate and they point opposite ways on purpose. A profile
/// is long-lived: it outlives balance passes, so its hero is written as the one
/// field a run can change on its own — hit points — and rebuilt on whatever
/// [newProfile] says a hero's body is in the build that reads it. That way a
/// rebalance reaches old saves, and hero base stats, which are a forbidden
/// lever, cannot fossilize inside a save file. A run block is the opposite: it
/// is a single fight frozen in place, so its actors are written whole, down to
/// the turn each one is holding — the same argument [FloorMemory] makes for
/// keeping terrain it could have regenerated. Rebalance reach for the thing that
/// lasts; frozen honesty for the thing that is paused.
///
/// The hero's tile and held energy are not earned and are not written: a hero in
/// town stands nowhere, and `startRun` sets both at the door.
Map<String, Object?> encodeProfile(Profile profile) => {
  'hp': profile.hero.hp,
  'gold': profile.gold,
  'bankedGold': profile.bankedGold,
  'worldSeed': encodeWide(profile.worldSeed),
  'visit': profile.visit,
  'equipment': encodeEquipment(profile.equipment),
  'inventory': encodeItems(profile.inventory),
  'bank': encodeItems(profile.bank),
  'skills': encodeSkills(profile.skills),
  'knownSpells': encodeSpellIds(profile.knownSpells),
};

/// Every spell in [known], as sorted ids.
///
/// Sorted for [encodeSkills]'s reason: one profile has to encode to one
/// document, and nothing reads this set in order. Ids rather than names, because
/// a name is a thing a screen shows and an id is the thing the rules join on.
List<Object?> encodeSpellIds(Set<String> known) => known.toList()..sort();

/// Every spell in the list at [key].
///
/// An id this build has never heard of is a load failure with a sentence in it,
/// not a spell quietly dropped: a hero who came back one spell short would have
/// no way to find out which.
Set<String> decodeSpellIds(Map<String, Object?> from, String key) => {
  for (final written in listAt(from, key)) _spellIdNamed(written, key),
};

String _spellIdNamed(Object? written, String key) {
  if (written is String && spellOrNull(written) != null) return written;
  throw SaveMalformed('"$key" names a spell this build does not know');
}

/// The hero between runs, from the object at [key].
Profile decodeProfile(Map<String, Object?> from, String key) {
  final written = objectAt(from, key);
  final worldSeed = wideAt(written, 'worldSeed');
  return Profile(
    hero: newProfile(
      worldSeed: worldSeed,
    ).hero.copyWith(hp: intAt(written, 'hp')),
    worldSeed: worldSeed,
    equipment: decodeEquipment(written, 'equipment'),
    skills: decodeSkills(written, 'skills'),
    inventory: decodeItems(written, 'inventory'),
    bank: decodeItems(written, 'bank'),
    gold: intAt(written, 'gold'),
    bankedGold: intAt(written, 'bankedGold'),
    visit: intAt(written, 'visit'),
    knownSpells: decodeSpellIds(written, 'knownSpells'),
  );
}
