import 'package:equatable/equatable.dart';

import '../engine/actor.dart';
import '../loot/item.dart';
import '../loot/loadout.dart';
import '../skills/skill.dart';

/// The hero between runs: everything a dungeon cannot take away by itself.
///
/// A profile is what the town screens read and write, and it is deliberately
/// not a game state with the map taken out. A run has a floor, a clock and two
/// random streams; a hero standing in town has none of those. Modelling the
/// town as a degenerate crawl would mean every town screen had to be careful
/// not to touch machinery that was not running, and the first one that forgot
/// would advance a clock nobody was watching.
///
/// **A fresh profile stands at full health, but full health is not an
/// invariant.** A hero who walks out of the dungeon on four hit points is on
/// four hit points in town, and stays there until it pays for a bed. That is
/// the whole reason the inn exists, so nothing here quietly tops the hero up.
class Profile extends Equatable {
  Profile({
    required this.hero,
    required this.worldSeed,
    Equipment equipment = const {},
    Map<SkillId, SkillState> skills = untrainedSkills,
    List<Item> inventory = const [],
    List<Item> bank = const [],
    Set<String> knownSpells = const {},
    this.gold = 0,
    this.bankedGold = 0,
    this.visit = 0,
  }) : equipment = Map.unmodifiable(equipment),
       skills = Map.unmodifiable(skills),
       inventory = List.unmodifiable(inventory),
       bank = List.unmodifiable(bank),
       knownSpells = Set.unmodifiable(knownSpells);

  /// The base body: base stats, and the hit points the hero walked out with.
  final Actor hero;

  final Equipment equipment;
  final Map<SkillId, SkillState> skills;

  /// Every spell this hero has read a book to learn, by id.
  ///
  /// **Mirrors [skills] exactly, and for the same reason.** What a hero has
  /// learned is not something a dungeon can take back: the book is spent at the
  /// moment of reading, so a death that burned the spell would charge twice for
  /// one page. It rides all four run-boundary doors beside the training, and it
  /// is part of [props] because a hero who can cast is not the hero who cannot.
  final Set<String> knownSpells;

  /// What the hero carries into the dungeon, and loses by dying in it.
  final List<Item> inventory;

  /// What the hero carries into the dungeon, and loses by dying in it.
  final int gold;

  /// What the vault holds. Death cannot reach it, and it has no cap.
  ///
  /// No cap because the bank is the answer to the pack's cap, and a vault that
  /// filled up would just move the same decision one screen along.
  final List<Item> bank;

  final int bankedGold;

  /// The seed the whole dungeon derives from.
  final int worldSeed;

  /// How many times this hero has entered the dungeon.
  final int visit;

  /// The gear and the training every derived hero stat reads from.
  Loadout get loadout => Loadout(equipment: equipment, skills: skills);

  /// The hit point ceiling this profile's gear allows.
  int get maxHp => heroMaxHp(hero, loadout);

  Profile copyWith({
    Actor? hero,
    Equipment? equipment,
    Map<SkillId, SkillState>? skills,
    List<Item>? inventory,
    int? gold,
    List<Item>? bank,
    int? bankedGold,
    int? visit,
    Set<String>? knownSpells,
  }) => Profile(
    hero: hero ?? this.hero,
    worldSeed: worldSeed,
    equipment: equipment ?? this.equipment,
    skills: skills ?? this.skills,
    inventory: inventory ?? this.inventory,
    gold: gold ?? this.gold,
    bank: bank ?? this.bank,
    bankedGold: bankedGold ?? this.bankedGold,
    visit: visit ?? this.visit,
    knownSpells: knownSpells ?? this.knownSpells,
  );

  /// [Actor] is not a value object, so a profile's identity names the fields of
  /// its hero that town rules actually turn on rather than the actor itself.
  @override
  List<Object?> get props => [
    hero.id,
    hero.hp,
    hero.maxHp,
    equipment,
    skills,
    inventory,
    gold,
    bank,
    bankedGold,
    worldSeed,
    visit,
    knownSpells,
  ];

  @override
  String toString() =>
      'Profile(${hero.hp} hp, $gold gold, $bankedGold banked, visit $visit)';
}
