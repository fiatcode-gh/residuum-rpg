import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';

sealed class ActionMark {
  const ActionMark();
}

/// A shipped multitone icon, rendered untinted at its own colours.
class ShippedMark extends ActionMark {
  const ShippedMark(this.icon);

  final ActionIcon icon;
}

/// A Material glyph, rendered as a single flat colour.
class FontMark extends ActionMark {
  const FontMark(this.icon);

  final IconData icon;
}

/// Draws an [ActionMark] at [size]: a shipped icon exactly as the crawl has
/// always rendered one — `Image.asset`, never `ImageIcon`, because the
/// shipped icons are multitone masters and an `IconTheme` tint would flatten
/// them to a silhouette — or a Material [Icon] tinted [crawlGold]. Both stay
/// out of the semantics tree; the word beside this widget carries the
/// announcement instead.
class ActionMarkView extends StatelessWidget {
  const ActionMarkView(this.mark, {this.size = 18, super.key});

  final ActionMark mark;
  final double size;

  @override
  Widget build(BuildContext context) => switch (mark) {
    ShippedMark(:final icon) => Image.asset(
      icon.path,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    ),
    FontMark(:final icon) => ExcludeSemantics(
      child: Icon(icon, size: size, color: crawlGold),
    ),
  };
}

ActionMark spellMark(Spell spell) {
  final shipped = ActionIcon.forSpell(spell.id);
  if (shipped != null) return ShippedMark(shipped);
  if (spell.id == 'frost-lance') return const FontMark(Icons.ac_unit);
  return FontMark(switch (spell.kind) {
    SpellKind.ward => Icons.health_and_safety,
    SpellKind.bind => Icons.link,
    SpellKind.banish => Icons.blur_on,
    SpellKind.bolt || SpellKind.mend => Icons.auto_awesome,
  });
}
