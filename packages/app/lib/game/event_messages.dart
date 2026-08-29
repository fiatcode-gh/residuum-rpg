import 'package:residuum_core/core.dart';

/// One line of the message log, or null when the event needs no words.
///
/// [names] maps actor ids to what the log calls them, taken from the state
/// *before* the turn ran — a monster that died this turn is gone from the state
/// but still has to be named in the sentence announcing it.
String? describeEvent(
  GameEvent event,
  Map<String, String> names,
) => switch (event) {
  ActorMoved(:final actorId, :final from, :final to) when actorId == heroId =>
    'You step ${_bearing(from, to)}.',
  ActorMoved() => null,
  MoveBlocked(:final actorId) when actorId == heroId => 'The way is blocked.',
  MoveBlocked() => null,
  AttackHit(:final attackerId, :final targetId, :final damage)
      when attackerId == heroId =>
    'You hit ${_named(names, targetId)} for $damage.',
  AttackHit(:final attackerId, :final damage) =>
    '${_capitalised(_named(names, attackerId))} claws you for $damage.',
  ActorDied(:final actorId) when actorId == heroId => 'You die.',
  ActorDied(:final actorId) => '${_capitalised(_named(names, actorId))} dies.',
  ActorNoticed(:final actorId) =>
    '${_capitalised(_named(names, actorId))} comes into view.',
  Descended(:final newDepth) => 'You descend to depth $newDepth.',
  Ascended(:final newDepth) => 'You climb to depth $newDepth.',
  AttackDodged(:final attackerId) =>
    '${_capitalised(_named(names, attackerId))} swings and misses.',
  ItemDropped(:final item) => '${item.displayName} falls to the floor.',
  ItemPickedUp(:final item) => 'You pick up ${item.displayName}.',
  InventoryFull() => 'You cannot carry any more.',
  ItemEquipped(:final item, :final slot) =>
    'You put on ${item.displayName} (${_slotName(slot)}).',
  ItemUnequipped(:final item, :final slot) =>
    'You take off ${item.displayName} (${_slotName(slot)}).',
  ActionRefused(:final reason) => '${_capitalised(reason)}.',
  PotionDrunk(:final item, :final healed) when healed == 0 =>
    'You drink ${item.displayName}. Nothing was wrong with you.',
  PotionDrunk(:final item, :final healed) =>
    'You drink ${item.displayName} and recover $healed.',
  SpellLearned(:final book, :final spell) =>
    'You read ${book.displayName} and learn ${spell.name}.',
  SpellHit(:final spell, :final targetId, :final damage, :final bite) =>
    '${_capitalised(spell.name)} ${_boltVerb(spell.type!)} '
        '${_named(names, targetId)} for $damage${_biteAside(bite)}',
  MendCast(:final healed) when healed == 0 =>
    'You mend. Nothing was wrong with you.',
  MendCast(:final healed) => 'You mend and recover $healed.',
  WardRaised(:final absorbs) => 'A ward closes over you, holding $absorbs.',
  WardStruck(:final absorbed, :final remaining) when remaining == 0 =>
    'Your ward takes $absorbed and breaks.',
  WardStruck(:final absorbed, :final remaining) =>
    'Your ward takes $absorbed, $remaining left.',
  MonsterBound(:final targetId, :final turns) =>
    '${_capitalised(_named(names, targetId))} is bound for $turns turns.',
  MonsterBanished(:final targetId) =>
    '${_capitalised(_named(names, targetId))} vanishes and reappears '
        'elsewhere.',
  NodeGathered(:final kind, :final material) =>
    'You ${kind.verb.toLowerCase()} the ${kind.word} and take one '
        '${material.word}.',
  SkillLevelledUp(:final skill, :final level) =>
    '${_skillName(skill)} rises to $level.',
  Fled() => 'You break off and get away.',
  GameOver() => null,
};

/// What a bolt of this type does to the thing it lands on.
///
/// The verb carries the damage type in a word, so the log says which element
/// landed without the player having to remember what colour anything was.
String _boltVerb(DamageType type) => switch (type) {
  DamageType.fire => 'burns',
  DamageType.frost => 'freezes',
};

/// The clause that says why a bolt's number differs from its usual range.
///
/// Spelled out rather than shown as a mark, because whether a creature resists
/// what you are throwing at it is the single most useful thing a caster can
/// learn from a fight — and a player who never reads it will go on throwing
/// fire at the thing that shrugs it off.
String _biteAside(SpellBite bite) => switch (bite) {
  SpellBite.plain => '.',
  SpellBite.resisted => ' — it resists.',
  SpellBite.vulnerable => ' — it burns.',
};

/// What the log calls a slot, in words rather than a field name.
String _slotName(EquipSlot slot) => switch (slot) {
  EquipSlot.mainHand => 'main hand',
  EquipSlot.offHand => 'off hand',
  EquipSlot.head => 'head',
  EquipSlot.chest => 'chest',
  EquipSlot.hands => 'hands',
  EquipSlot.feet => 'feet',
};

/// What the log and the skill readout call a skill.
String skillName(SkillId skill) => _skillName(skill);

String _skillName(SkillId skill) => switch (skill) {
  SkillId.arms => 'Arms',
  SkillId.might => 'Might',
  SkillId.bulwark => 'Bulwark',
  SkillId.fleetfoot => 'Fleetfoot',
  SkillId.wrath || SkillId.mending || SkillId.binding => skill.schoolWord,
  SkillId.herbcraft => 'Herbcraft',
  SkillId.blacksmith => 'Blacksmith',
};

/// The id the hero always answers to.
const String heroId = 'hero';

/// What the log calls every actor in [game], the hero included.
Map<String, String> namesIn(GameState game) => {
  game.hero.id: game.hero.name,
  for (final monster in game.monsters) monster.id: monster.name,
};

String _named(Map<String, String> names, String id) =>
    names[id] ?? 'something in the dark';

String _capitalised(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

String _bearing(Position from, Position to) =>
    from.directionTo(to)?.name ?? 'aside';
