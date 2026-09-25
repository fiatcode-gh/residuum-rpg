import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../style/surfaces.dart';

class SpellRow extends StatelessWidget {
  const SpellRow({
    super.key,
    required this.spell,
    required this.style,
    required this.dimStyle,
    this.detail = '',
    this.reason,
    this.trailing,
  });

  final Spell spell;

  /// The text style for the marking, the name and nothing dimmer.
  final TextStyle style;

  /// The text style for the cost line and the refusal sentence.
  final TextStyle dimStyle;

  /// What the spell does, appended to the cost line — the numbers the player
  /// is choosing between, or the empty string where the cost says enough.
  final String detail;

  /// Why casting is refused right now, or null when it is not.
  ///
  /// A spell that cannot be cast keeps its button and gains a sentence saying
  /// why, rather than going quietly grey. "Not enough mana" is a thing the
  /// player can act on; a dimmed control is a thing they have to guess at.
  final String? reason;

  /// The row's optional trailing action, if the screen offers one.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => FramedRow(
    title: spell.name,
    titleStyle: style,
    detailStyle: dimStyle,
    details: [
      '${spell.school.schoolWord} · ${spell.manaCost} mana$detail',
      ?reason,
    ],
    medallion: Text(
      spell.school.schoolMarking,
      style: style,
      textAlign: TextAlign.center,
    ),
    trailing: trailing,
  );
}

List<Spell> knownSpellsInOrder(Set<String> ids, Map<String, Spell> spells) {
  final known = [
    for (final id in ids)
      if (spells[id] case final Spell spell) spell,
  ];
  known.sort((one, other) {
    final bySchool = one.school.index.compareTo(other.school.index);
    return bySchool != 0 ? bySchool : one.name.compareTo(other.name);
  });
  return known;
}

/// What a spell does, in the numbers the player is choosing between.
String effectOf(Spell spell) => switch (spell.kind) {
  SpellKind.bolt =>
    ' · ${spell.min}-${spell.max} ${spell.type!.word} ${spell.type!.marking}',
  SpellKind.mend => ' · heals ${spell.min}',
  SpellKind.ward => ' · absorbs ${spell.min}',
  SpellKind.bind => ' · holds ${spell.min} turns',
  SpellKind.banish => ' · moves it away',
};
