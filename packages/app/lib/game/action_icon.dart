import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';

/// One mark the action bar (and, later, a panel) can draw for a verb or a
/// spell (PLAN.md G9): either one of the game's own shipped icons, or a
/// Material glyph tinted [crawlGold] — Plex Mono has no geometric marks, so
/// this sealed pair is the whole non-map iconography.
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

/// The mark a known spell shows on the action bar (PLAN.md G9). The two
/// spells with a shipped asset keep it; every other spell draws by what it
/// does, since a spell's [Spell.kind] is what its mark should say —
/// `frost-lance`, the only other bolt the game ships, gets its own glyph so
/// it never collides with the shipped Firebolt mark.
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
