import 'package:equatable/equatable.dart';

import '../engine/actor.dart';
import '../skills/skill.dart';
import 'equip_slot.dart';
import 'item.dart';

/// What the hero is wearing, by slot.
typedef Equipment = Map<EquipSlot, Item>;

/// The most dodge Fleetfoot can ever buy, in percent.
///
/// A cap exists because dodge multiplies with armour instead of adding to it:
/// an uncapped dodge chance would eventually make every other defensive
/// decision irrelevant, and a hero who is simply never hit has stopped playing
/// the combat system at all.
const int dodgeCapPercent = 30;

/// The gear and the training every effective hero stat derives from.
///
/// These are derivations rather than fields mutated on [Actor], and that is the
/// most important decision in this file. If equipping a helmet added two to an
/// `Actor.armor`, unequipping it would have to subtract exactly two — and once
/// armour also comes from a skill level, from an affix and later from a set
/// bonus, "exactly two" is a running total that some code path will eventually
/// fail to keep. Deriving on read makes the equipment map the single source of
/// truth, so an unequip cannot leave a stale bonus behind: there is no stored
/// total left to go stale.
///
/// It is a value object rather than a view over the game state because skills
/// train *during* a turn. A level-up in the middle of the monster phase has to
/// change armour and dodge for the very next monster's swing, and those trained
/// skills are not in any game state yet.
class Loadout extends Equatable {
  const Loadout({required this.equipment, required this.skills});

  final Equipment equipment;
  final Map<SkillId, SkillState> skills;

  /// How far [skill] has come, reading an absent entry as untrained.
  int levelOf(SkillId skill) => skills[skill]?.level ?? 0;

  /// What is in the hero's main hand, or null for bare fists.
  Item? get weapon => equipment[EquipSlot.mainHand];

  /// Whether any worn piece is heavy, which is what Bulwark trains on.
  bool get wearsHeavy => equipment.values.any((item) => item.base.heavy);

  /// Whether the held weapon claims both hands, which excludes a shield.
  bool get wieldsTwoHanded => weapon?.base.hands == WeaponHands.two;

  /// This loadout wearing [equipment] instead.
  Loadout withEquipment(Equipment equipment) =>
      Loadout(equipment: equipment, skills: skills);

  /// This loadout trained to [skills] instead.
  Loadout withSkills(Map<SkillId, SkillState> skills) =>
      Loadout(equipment: equipment, skills: skills);

  @override
  List<Object?> get props => [equipment, skills];

  @override
  String toString() =>
      'Loadout(${equipment.length} worn, ${skills.length} skills)';
}

/// The damage range one hero swing rolls between.
///
/// The hero's own [Actor.attackMin] and [Actor.attackMax] are its bare fists; a
/// weapon and its affixes add on top, so a hero who drops everything still
/// punches instead of dealing nothing. That additive reading is also what lets
/// the whole pre-loot test suite keep its numbers: a hero with no weapon
/// derives exactly the attack it was built with.
///
/// Only the skill matching the held weapon applies — Arms for one-handed
/// weapons and for fists, Might for two-handed. Adding both would mean training
/// a greatsword sharpened the hero's dagger, which is neither what the training
/// triggers say nor what a player would expect.
(int, int) heroAttack(Actor hero, Loadout loadout) {
  final weapon = loadout.weapon;
  final mastery = loadout.wieldsTwoHanded ? SkillId.might : SkillId.arms;
  final bonus = loadout.levelOf(mastery) ~/ 2;
  return (
    hero.attackMin + (weapon?.attackMin ?? 0) + bonus,
    hero.attackMax + (weapon?.attackMax ?? 0) + bonus,
  );
}

/// How much a hit against the hero is reduced by, before the floor of one.
int heroArmor(Loadout loadout) {
  final worn = loadout.equipment.values.fold(
    0,
    (total, item) => total + item.armor,
  );
  return worn + loadout.levelOf(SkillId.bulwark) ~/ 2;
}

/// The chance in a hundred that a hit against the hero misses entirely.
///
/// Fleetfoot alone feeds this, which is what stops dodge and armour compounding
/// without limit: Fleetfoot only trains while the hero wears nothing heavy and
/// Bulwark only while it does, so the two defences are alternatives rather than
/// a stack. See [dodgeCapPercent] for the ceiling on what is left.
int heroDodgePercent(Loadout loadout) {
  final trained = loadout.levelOf(SkillId.fleetfoot) * 3;
  return trained > dodgeCapPercent ? dodgeCapPercent : trained;
}

/// The hero's hit point ceiling: its own base plus every worn affix.
int heroMaxHp(Actor hero, Loadout loadout) =>
    hero.maxHp +
    loadout.equipment.values.fold(0, (total, item) => total + item.maxHp);

/// How fast the hero acts on the speed clock: its own base plus worn affixes.
int heroSpeed(Actor hero, Loadout loadout) =>
    hero.speed +
    loadout.equipment.values.fold(0, (total, item) => total + item.speed);
