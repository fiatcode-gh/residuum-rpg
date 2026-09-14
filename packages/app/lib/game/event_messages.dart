import 'package:residuum_core/core.dart';

import 'log_line.dart';

/// One line of the message log, and the kind it is, or null when the event
/// needs no words.
///
/// [names] maps actor ids to what the log calls them, taken from the state
/// *before* the turn ran — a monster that died this turn is gone from the state
/// but still has to be named in the sentence announcing it.
///
/// [strikesFromAfar] carries the ids of monsters whose swing this turn was
/// delivered from outside arm's length: the ranged verb is the sentence's way
/// of saying the blow crossed the room. Adjacency is the caller's knowledge —
/// it reads the start state — which is why the set rides in rather than the
/// reach, and why an adjacent monster claws even when its reach is longer than
/// one: a blow from arm's length is a claw, however long the arms.
LogLine? describeEvent(
  GameEvent event,
  Map<String, String> names, {
  Set<String> strikesFromAfar = const {},
}) => switch (event) {
  ActorMoved(:final actorId, :final from, :final to) when actorId == heroId =>
    LogLine('You step ${_bearing(from, to)}.', LogCategory.moved),
  ActorMoved() => null,
  MoveBlocked(:final actorId) when actorId == heroId => LogLine(
    'The way is blocked.',
    LogCategory.refused,
  ),
  MoveBlocked() => null,
  AttackHit(:final attackerId, :final targetId, :final damage)
      when attackerId == heroId =>
    LogLine('You hit ${_named(names, targetId)} for $damage.', LogCategory.hit),
  AttackHit(:final attackerId, :final damage) => LogLine(
    strikesFromAfar.contains(attackerId)
        ? '${_capitalised(_named(names, attackerId))} strikes you from afar '
              'for $damage.'
        : '${_capitalised(_named(names, attackerId))} claws you for $damage.',
    LogCategory.struck,
  ),
  ActorDied(:final actorId) when actorId == heroId => LogLine(
    'You die.',
    LogCategory.died,
  ),
  ActorDied(:final actorId) => LogLine(
    '${_capitalised(_named(names, actorId))} dies.',
    LogCategory.died,
  ),
  ActorNoticed(:final actorId) => LogLine(
    '${_capitalised(_named(names, actorId))} comes into view.',
    LogCategory.noticed,
  ),
  Descended(:final newDepth) => LogLine(
    'You descend to depth $newDepth.',
    LogCategory.moved,
  ),
  Ascended(:final newDepth) => LogLine(
    'You climb to depth $newDepth.',
    LogCategory.moved,
  ),
  AttackDodged(:final attackerId) => LogLine(
    '${_capitalised(_named(names, attackerId))} swings and misses.',
    LogCategory.struck,
  ),
  ItemDropped(:final item) => LogLine(
    '${item.displayName} falls to the floor.',
    LogCategory.item,
  ),
  ItemPickedUp(:final item) => LogLine(
    'You pick up ${item.displayName}.',
    LogCategory.item,
  ),
  InventoryFull() => const LogLine(
    'You cannot carry any more.',
    LogCategory.refused,
  ),
  ItemEquipped(:final item, :final slot) => LogLine(
    'You put on ${item.displayName} (${_slotName(slot)}).',
    LogCategory.item,
  ),
  ItemUnequipped(:final item, :final slot) => LogLine(
    'You take off ${item.displayName} (${_slotName(slot)}).',
    LogCategory.item,
  ),
  ActionRefused(:final reason) => LogLine(
    '${_capitalised(reason)}.',
    LogCategory.refused,
  ),
  PotionDrunk(:final item, :final healed) when healed == 0 => LogLine(
    'You drink ${item.displayName}. Nothing was wrong with you.',
    LogCategory.item,
  ),
  PotionDrunk(:final item, :final healed) => LogLine(
    'You drink ${item.displayName} and recover $healed.',
    LogCategory.item,
  ),
  SpellLearned(:final book, :final spell) => LogLine(
    'You read ${book.displayName} and learn ${spell.name}.',
    LogCategory.raised,
  ),
  SpellHit(:final spell, :final targetId, :final damage, :final bite) =>
    LogLine(
      '${_capitalised(spell.name)} ${_boltVerb(spell.type!)} '
      '${_named(names, targetId)} for $damage${_biteAside(bite)}',
      LogCategory.hit,
    ),
  MendCast(:final healed) when healed == 0 => const LogLine(
    'You mend. Nothing was wrong with you.',
    LogCategory.raised,
  ),
  MendCast(:final healed) => LogLine(
    'You mend and recover $healed.',
    LogCategory.raised,
  ),
  WardRaised(:final absorbs) => LogLine(
    'A ward closes over you, holding $absorbs.',
    LogCategory.raised,
  ),
  WardStruck(:final absorbed, :final remaining) when remaining == 0 => LogLine(
    'Your ward takes $absorbed and breaks.',
    LogCategory.struck,
  ),
  WardStruck(:final absorbed, :final remaining) => LogLine(
    'Your ward takes $absorbed, $remaining left.',
    LogCategory.struck,
  ),
  MonsterBound(:final targetId, :final turns) => LogLine(
    '${_capitalised(_named(names, targetId))} is bound for $turns turns.',
    LogCategory.hit,
  ),
  MonsterBanished(:final targetId) => LogLine(
    '${_capitalised(_named(names, targetId))} vanishes and reappears '
    'elsewhere.',
    LogCategory.hit,
  ),
  NodeGathered(:final kind, :final material) => LogLine(
    'You ${kind.verb.toLowerCase()} the ${kind.word} and take one '
    '${material.word}.',
    LogCategory.gathered,
  ),
  SkillLevelledUp(:final skill, :final level) => LogLine(
    '${_skillName(skill)} rises to $level.',
    LogCategory.raised,
  ),
  Fled() => const LogLine('You break off and get away.', LogCategory.moved),
  HeroWaited() => const LogLine('You hold your ground.', LogCategory.moved),
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

String _named(Map<String, String> names, String id) =>
    names[id] ?? 'something in the dark';

String _capitalised(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

String _bearing(Position from, Position to) =>
    from.directionTo(to)?.name ?? 'aside';
