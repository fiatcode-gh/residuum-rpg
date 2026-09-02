import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

/// One known spell: what it is, what it costs, and — where a cast is offered —
/// whether it can be cast now.
///
/// **The school is a marking and a word, never a colour.** The author is
/// deuteranomalous and the standing rule is that no category may be carried by
/// hue alone, so a Wrath row says so twice — the glyph and the word — and reads
/// correctly in greyscale and aloud.
///
/// One grammar for every screen that lists known spells, carried here because
/// a fourth private copy was the threshold the craft rules forbid. The screens
/// differ only in what they hang on the row, and each hangs its own: the Pack
/// offers the cast and speaks the refusal, the character room reads alone, and
/// the battle skill bar keeps the facts and drops the layout. Text styles are
/// parameters rather than decisions, so a screen keeps the type it shipped
/// with and the lift moves no pixel.
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

  /// The row's action, if the screen offers one — the Pack's Cast button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(spell.school.schoolMarking, style: style),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spell.name, style: style),
              Text(
                '${spell.school.schoolWord} · ${spell.manaCost} mana$detail',
                style: dimStyle,
              ),
              if (reason != null) Text(reason!, style: dimStyle),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
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
