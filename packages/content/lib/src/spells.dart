import 'package:residuum_core/core.dart';

/// How many scheduled turns a bind holds a monster still.
///
/// Content's number rather than a rule's constant, carried in the spell's own
/// [Spell.min], so the one place a reader looks for what Bind does is the row
/// that says what every other spell does.
const int _boundTurns = 3;

/// The first spell of Wrath, and the first spell most heroes ever cast.
///
/// Ungated and cheap, because the opening spell has to be castable by a hero who
/// has trained nothing: a first book that could not be read would be a goal
/// rather than a beginning, and Wrath trains on nothing but casting.
const Spell firebolt = Spell(
  id: 'firebolt',
  name: 'Firebolt',
  school: SkillId.wrath,
  manaCost: 2,
  requiredLevel: 0,
  kind: SpellKind.bolt,
  type: DamageType.fire,
  min: 2,
  max: 4,
);

/// Wrath's second word: colder, dearer, and the answer to what shrugs off fire.
///
/// The gate is what makes it a goal — a hero reaches it by casting, which is the
/// only thing that trains Wrath — and the type is what makes it a decision. The
/// sea-cave teaches this and its own creatures resist it; the crypt's fire is
/// what the cave is actually afraid of.
const Spell frostLance = Spell(
  id: 'frost-lance',
  name: 'Frost Lance',
  school: SkillId.wrath,
  manaCost: 4,
  requiredLevel: 4,
  kind: SpellKind.bolt,
  type: DamageType.frost,
  min: 4,
  max: 7,
);

/// Mending's first word: hit points back, and the first healing in the game that
/// is not a bottle.
///
/// Capped at what is missing rather than overflowing, and cast at full health it
/// is simply wasted — the potion's doctrine, and the reason casting it is never
/// refused.
const Spell mend = Spell(
  id: 'mend',
  name: 'Mend',
  school: SkillId.mending,
  manaCost: 3,
  requiredLevel: 0,
  kind: SpellKind.mend,
  min: 8,
  max: 8,
);

/// A pool that takes blows in the hero's place until it is spent.
///
/// A stated number rather than a rolled one, because a ward is a plan: a player
/// deciding whether to spend three mana before opening a door needs to know what
/// the three buys. Casting it again replaces what is left rather than adding to
/// it, so it can never be stacked into invulnerability on a quiet corridor.
const Spell ward = Spell(
  id: 'ward',
  name: 'Ward',
  school: SkillId.mending,
  manaCost: 3,
  requiredLevel: 3,
  kind: SpellKind.ward,
  min: 6,
  max: 6,
);

/// Binding's first word: one monster stops for three of its turns.
///
/// It deals nothing and it draws nothing. What it buys is the choice of which
/// fight to have — walk away from the wight and kill the ghoul, or three free
/// swings at the thing that was about to kill you.
const Spell bind = Spell(
  id: 'bind',
  name: 'Bind',
  school: SkillId.binding,
  manaCost: 3,
  requiredLevel: 0,
  kind: SpellKind.bind,
  min: _boundTurns,
  max: _boundTurns,
);

/// Binding's second word: the monster is somewhere else now.
///
/// The escape hatch a cornered hero pays for. It does no damage and it does not
/// end the fight — the thing is still on the floor, and it is still coming.
const Spell banish = Spell(
  id: 'banish',
  name: 'Banish',
  school: SkillId.binding,
  manaCost: 4,
  requiredLevel: 4,
  kind: SpellKind.banish,
  min: 0,
  max: 0,
);

/// Every spell in the game.
///
/// Two per school, and the pairing is the design: each school opens with an
/// ungated word a fresh hero can cast, and closes with one that has to be earned
/// by casting the first. A school whose only spell were gated could never train
/// itself past its own gate.
const List<Spell> spellbook = [firebolt, frostLance, mend, ward, bind, banish];

/// Every spell in the game, by id, as the rules carry it.
final Map<String, Spell> spellsById = {
  for (final spell in spellbook) spell.id: spell,
};

/// The spell with this [id], or null when nothing answers to it.
///
/// The nullable door exists for the save codec, exactly as [baseItemOrNull]'s
/// does: a spell id read out of a file written by an older build is a load
/// failure with a sentence in it, not a crash.
Spell? spellOrNull(String id) => spellsById[id];
