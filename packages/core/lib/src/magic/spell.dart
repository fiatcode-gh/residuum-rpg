import 'package:equatable/equatable.dart';

import '../skills/skill.dart';

/// What a blow is made of, where the rules care.
///
/// **Exactly two, and that is a scope decision rather than an oversight.** Fire
/// and frost are what the first spells deal, so they are what creatures can be
/// written to resist. The design spec's remaining five types belong with weapon
/// typing: a type no spell casts and no weapon carries would be a column in
/// every bestiary entry that nothing could ever put a number in, and content
/// nobody can exercise is content nobody can be wrong about.
///
/// [marking] and [word] exist for [Rarity]'s reason: the author is
/// deuteranomalous, so a type is told apart by a glyph and a word and never by
/// hue. A resist line reads correctly in greyscale and aloud.
enum DamageType {
  fire(marking: '△', word: 'fire'),
  frost(marking: '◇', word: 'frost');

  const DamageType({required this.marking, required this.word});

  /// The non-hue mark a line draws beside damage of this type.
  final String marking;

  /// The word the message log uses for this type, mid-sentence.
  final String word;
}

/// What a spell does when it lands.
///
/// The kind is what decides which effect runs and how many numbers the cast
/// draws, so it is an enum the rules switch on exhaustively rather than a bag of
/// nullable fields: a spell that both healed and bound would have no answer for
/// what its damage range meant.
enum SpellKind {
  /// Damage at range, of a stated [DamageType]. One roll.
  bolt,

  /// Hit points back, capped at what is missing. No roll.
  mend,

  /// A pool that soaks incoming damage until it is spent. No roll.
  ward,

  /// A monster held still for a count of turns. No roll.
  bind,

  /// A monster moved elsewhere on the floor. One roll.
  banish,
}

/// How a target's make-up answered the bolt that hit it.
///
/// One value rather than two flags, because resisting and burning at the same
/// type are mutually exclusive by content validation and a pair of booleans
/// would leave a fourth state nobody could describe. The log reads this to say
/// whether the blow was dulled or doubled, so the message layer never has to
/// look a creature up in a bestiary it cannot see.
enum SpellBite {
  /// The target is made of nothing that cares. Full damage.
  plain,

  /// The target resists the type. Halved, rounding down, never below one.
  resisted,

  /// The target burns at the type. Doubled.
  vulnerable,
}

/// Which of the nine skills are spell schools, and what each is called.
///
/// An extension rather than three more fields on [SkillId], because a school is
/// a fact about how a skill is trained and not a property every skill has: Arms
/// has no marking to draw and no spells to gate, and giving it a null one would
/// invite a screen to render it.
extension School on SkillId {
  /// Whether casting is what trains this skill.
  bool get isSchool =>
      this == SkillId.wrath ||
      this == SkillId.mending ||
      this == SkillId.binding;

  /// What a spell row calls this school. Empty for a skill that is not one.
  String get schoolWord => switch (this) {
    SkillId.wrath => 'Wrath',
    SkillId.mending => 'Mending',
    SkillId.binding => 'Binding',
    _ => '',
  };

  /// The non-hue mark a spell row draws beside this school. Empty for a skill
  /// that is not one.
  String get schoolMarking => switch (this) {
    SkillId.wrath => '✳',
    SkillId.mending => '✚',
    SkillId.binding => '⛒',
    _ => '',
  };
}

/// One spell: what it is called, what it costs, and what it does.
///
/// Content-defined and identified by [id], the way a [BaseItem] is. The rules
/// know the five [SpellKind]s and nothing about which spells exist; the numbers
/// and the names are content's, and the registry rides the game state by
/// identity exactly as the drop tables do.
///
/// **Self-validating at construction**, because every one of these invariants is
/// a thing a content table can get wrong and none of them can be recovered from
/// at the cast site: a bolt with no type has no resistance to check, a school
/// that is not a school has no skill to train, and a ward whose pool is a range
/// is a number the player cannot plan against.
class Spell extends Equatable {
  const Spell({
    required this.id,
    required this.name,
    required this.school,
    required this.manaCost,
    required this.requiredLevel,
    required this.kind,
    required this.min,
    required this.max,
    this.type,
  }) : assert(
         school == SkillId.wrath ||
             school == SkillId.mending ||
             school == SkillId.binding,
         'a spell belongs to one of the three schools',
       ),
       assert(manaCost > 0, 'a spell that costs nothing is not a decision'),
       assert(requiredLevel >= 0, 'a gate below zero gates nothing'),
       assert(
         (kind == SpellKind.bolt) == (type != null),
         'a bolt states its damage type, and nothing else carries one',
       ),
       assert(min <= max, 'a range runs upward'),
       assert(
         kind != SpellKind.ward || min == max,
         'a ward absorbs a stated pool, never a rolled one',
       );

  final String id;

  /// What the pack screen and the message log call this spell.
  final String name;

  /// The skill a successful cast trains. Always one of the three schools.
  final SkillId school;

  /// What one cast takes out of the hero's pool. Always above zero.
  final int manaCost;

  /// The level of [school] a hero needs before a book of this can be read.
  final int requiredLevel;

  final SpellKind kind;

  /// What a bolt is made of, and null for every other kind.
  final DamageType? type;

  /// The bottom of the range: damage for a bolt, healing for a mend, the absorb
  /// pool for a ward. Unused by bind and banish.
  final int min;

  /// The top of that range, equal to [min] for a ward.
  final int max;

  @override
  List<Object?> get props => [
    id,
    name,
    school,
    manaCost,
    requiredLevel,
    kind,
    type,
    min,
    max,
  ];

  @override
  String toString() => 'Spell($id)';
}
