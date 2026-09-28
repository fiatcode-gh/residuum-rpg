import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'spell_row.dart';

/// How many known spells the Spells pop-up readies before the overflow
/// (PLAN.md G9, moved from the retired action bar).
const int readiedSpellCount = 3;

/// What tapping a spell row does (PLAN.md G9, moved from the action bar's
/// own `_onSpell`): a cast the rules would refuse dispatches anyway, so the
/// refusal reaches the log the way every other refusal does and no turn is
/// spent; Mend and Ward always cast, since they never need a target; every
/// other legal spell arms — a second choice of the same spell disarms it.
void chooseSpell(GameBloc bloc, Spell spell) {
  final state = bloc.state;
  final refused = state.castRefusal(spell) != null;
  if (refused || spell.kind == SpellKind.mend || spell.kind == SpellKind.ward) {
    bloc.add(CastPressed(spell.id));
  } else {
    bloc.add(SkillArmed(state.armedSpellId == spell.id ? null : spell.id));
  }
}

/// Opens the Spells pop-up anchored on the menu's own Spells slot (PLAN.md
/// G9): the readied spells, each with its cost and effect, or why nothing
/// is on offer. Available in and out of combat — the rules decide whether a
/// cast lands, never this pop-up.
Future<void> openSpellsPopup(BuildContext anchor, GameBloc bloc) =>
    showCrawlPopup<void>(
      anchor,
      builder: (context) => _SpellsPopupBody(anchor: anchor, bloc: bloc),
    );

class _SpellsPopupBody extends StatelessWidget {
  const _SpellsPopupBody({required this.anchor, required this.bloc});

  final BuildContext anchor;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) {
    final state = bloc.state;
    final known = state.knownSpells;
    final readied = known.take(readiedSpellCount);
    final overflow = known.length - readiedSpellCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: crawlPanelPadding),
          child: Text('SPELLS', style: displaySection),
        ),
        if (known.isEmpty)
          const Text('You know no spells yet.', style: textLineDim)
        else ...[
          for (final spell in readied)
            _SpellRow(
              spell: spell,
              armed: state.armedSpellId == spell.id,
              refusal: state.castRefusal(spell),
              onChoose: () {
                Navigator.of(context).pop();
                chooseSpell(bloc, spell);
              },
            ),
          if (overflow > 0)
            _SpellsOverflowRow(
              count: overflow,
              onOpen: () {
                Navigator.of(context).pop();
                openGrimoire(anchor, bloc, state);
              },
            ),
        ],
      ],
    );
  }
}

/// One readied spell: its mark, name and cost, keyed `spell:<id>` (PLAN.md
/// G9). A row a cast would refuse still reads and still taps — the refusal
/// is the pop-up's own way of saying why, never a greyed-out dead end.
class _SpellRow extends StatelessWidget {
  const _SpellRow({
    required this.spell,
    required this.armed,
    required this.refusal,
    required this.onChoose,
  });

  final Spell spell;
  final bool armed;
  final String? refusal;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final nameStyle = armed
        ? textSlotArmed
        : refusal != null
        ? textSlotDisabled
        : textSlot;
    final meta = armed
        ? '— armed'
        : refusal != null
        ? _capitalised(refusal!)
        : '${spell.manaCost} mana${effectOf(spell)}';
    return InkWell(
      key: ValueKey('spell:${spell.id}'),
      onTap: onChoose,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: crawlPopupRowMinHeight),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: ActionMarkView(spellMark(spell), size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${spell.school.schoolMarking} ${spell.name}',
                    style: nameStyle,
                  ),
                  Text(meta, style: monoSlotMeta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The row that opens the full grimoire behind the readied three (PLAN.md
/// G9).
class _SpellsOverflowRow extends StatelessWidget {
  const _SpellsOverflowRow({required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('spells-overflow'),
    onTap: onOpen,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: crawlPopupRowMinHeight),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: ActionMarkView(ShippedMark(ActionIcon.more), size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('+$count more spells', style: textSlot)),
        ],
      ),
    ),
  );
}

/// The first letter capitalised, the rest untouched — how a refusal reads as
/// a pop-up row's metadata rather than the log's own trailing-period sentence.
String _capitalised(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

/// Opens the full grimoire behind the pop-up's own readied three (moved
/// verbatim from the retired action bar's `_openSpellsOverflow`): every
/// known spell, so nothing a hero knows is ever unreachable.
Future<void> openGrimoire(
  BuildContext context,
  GameBloc bloc,
  GameViewState state,
) => showCrawlSheet<void>(
  context,
  children: (sheetContext) => [
    const Padding(
      padding: EdgeInsets.only(bottom: crawlPanelPadding),
      child: Text('Spells', style: displayPanel),
    ),
    for (final spell in state.knownSpells)
      _OverflowRow(
        spell: spell,
        armed: state.armedSpellId == spell.id,
        onCast: () {
          Navigator.of(sheetContext).pop();
          chooseSpell(bloc, spell);
        },
      ),
  ],
);

/// One row of the overflow grimoire: what the pop-up's row would cast, in
/// full — the school and name a row's marking can only abbreviate.
class _OverflowRow extends StatelessWidget {
  const _OverflowRow({
    required this.spell,
    required this.armed,
    required this.onCast,
  });

  final Spell spell;
  final bool armed;
  final VoidCallback onCast;

  @override
  Widget build(BuildContext context) => SpellRow(
    spell: spell,
    style: textLine,
    dimStyle: textDetailDim,
    detail: effectOf(spell),
    trailing: TextButton(
      key: Key('overflow-${spell.id}'),
      onPressed: onCast,
      style: TextButton.styleFrom(
        side: armed
            ? const BorderSide(color: crawlCold, width: hairline * 1.5)
            : null,
      ),
      child: Text(
        armed ? '— armed' : spell.school.schoolMarking,
        style: textLine,
      ),
    ),
  );
}
