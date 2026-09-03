import 'package:equatable/equatable.dart';

import '../craft/material.dart';
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
    Map<MaterialId, int> materials = const {},
    this.gold = 0,
    this.bankedGold = 0,
    this.visit = 0,
    this.brewNumber = 1,
    this.itemNumber = 1,
  }) : equipment = Map.unmodifiable(equipment),
       skills = Map.unmodifiable(skills),
       inventory = List.unmodifiable(inventory),
       bank = List.unmodifiable(bank),
       knownSpells = Set.unmodifiable(knownSpells),
       materials = Map.unmodifiable(materials);

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

  /// What the hero has gathered, by kind, and loses by dying in it.
  ///
  /// **[gold]'s twin, deliberately, and not the bank's.** Materials are earned
  /// underfoot several floors from home, so they ride the risk the purse rides;
  /// the vault stays gear and coin only this unit, which means a hero who wants
  /// to keep what they mined has to spend it before going back down. A material
  /// a counter holds at zero has no entry at all — see [withMaterial].
  final Map<MaterialId, int> materials;

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

  /// The number the next brewed potion's id is built from.
  ///
  /// **A counter and not a derivation, because uniqueness has to survive
  /// spending.** An item id is unique within a crawl, which is a contract the
  /// pack, the shelf and every action that names an item depend on. Brew, drink
  /// the potion, brew again — anything read off what the hero is holding, or off
  /// the visit, would hand out the id it just freed. This is the same shape
  /// `nextDropNumber` has on the run state, and it lives here rather than there
  /// because the alchemist is in town and a town has no run.
  ///
  /// Starts at one, so the first potion a hero ever brews is `brew-1`.
  final int brewNumber;

  /// The number the next pack item's id is built from.
  ///
  /// **A counter and not a derivation, for [brewNumber]'s reason exactly:** an
  /// id has to be unique among everything the hero holds, and anything read off
  /// the pack, the visit or the dungeon would hand out a number some earlier
  /// delve already spent. The pack persists across delves while ground ids do
  /// not — `drop-1` is minted on every descent, `floor-<depth>-<n>` on every
  /// visit — so a pack that kept litter ids could hold two items answering to
  /// the same name, and every removal would take both. This counter is the
  /// fix's mint: every item that enters the pack is re-id-ed `item-<n>` at the
  /// pack's door, and the number never resets, so a hero-scoped id is unique
  /// for the hero's whole life.
  ///
  /// Starts at one, so the first item a hero ever picks up is `item-1`.
  final int itemNumber;

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
    Map<MaterialId, int>? materials,
    int? brewNumber,
    int? itemNumber,
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
    materials: materials ?? this.materials,
    brewNumber: brewNumber ?? this.brewNumber,
    itemNumber: itemNumber ?? this.itemNumber,
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
    materials,
    brewNumber,
    itemNumber,
  ];

  @override
  String toString() =>
      'Profile(${hero.hp} hp, $gold gold, $bankedGold banked, visit $visit)';
}
