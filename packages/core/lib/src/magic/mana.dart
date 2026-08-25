import '../loot/loadout.dart';
import '../skills/skill.dart';
import 'spell.dart';

/// The pool a hero with no schooling at all still carries.
///
/// Above zero, because a hero who has just read their first book has trained
/// nothing yet and a first spell they cannot cast is a page that does nothing.
/// The floor is what makes the opening book worth picking up.
const int baseMana = 4;

/// How many school levels buy one more point of mana.
const int levelsPerManaPoint = 2;

/// The most mana [loadout] can hold on a floor.
///
/// Derived from the three schools rather than stored, for the reason every other
/// hero stat is derived: a stored total is a running sum some path will
/// eventually fail to keep, and there is no such thing as a stale derivation.
///
/// The three schools sum **before** the halving rather than each halving on its
/// own, which is what makes a hero who dabbles in all three no worse off than
/// one who specialises. Splitting a spread across schools is already paid for by
/// the gates; charging for it twice would make the only sensible hero a
/// single-school one.
int heroMaxMana(Loadout loadout) {
  final schooled = SkillId.values
      .where((skill) => skill.isSchool)
      .fold(0, (total, skill) => total + loadout.levelOf(skill));
  return baseMana + schooled ~/ levelsPerManaPoint;
}
