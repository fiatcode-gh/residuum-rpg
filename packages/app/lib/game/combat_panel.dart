import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_action_row.dart' show readiedSpellCount;
import 'crawl_status.dart' show hpMeterKey, manaMeterKey;
import 'crawl_style.dart';
import 'game_bloc.dart';

const combatPanelKey = Key('combat-panel');

/// The crawl's battle panel (PLAN.md G8 "Combat panel internals", G11
/// "target", "damage", "spell"): what the hero is fighting, what a swing
/// still costs and what the next cast would do — replacing [HeroPanel] for
/// exactly as long as [GameViewState.isBattleOpen] holds.
///
/// PLAN.md E5: the hero's own HP and mana stay visible in the middle
/// column, in the same keyed spot [HeroPanel] uses, so the fact the old
/// status row's meters tested stays true in battle too.
///
/// A pure projection over [state], exactly like [HeroPanel]: nothing here
/// dispatches, so every fact comes in through the constructor.
class CombatPanel extends StatelessWidget {
  const CombatPanel({required this.state, super.key});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final armedId = state.armedSpellId;
    final armedSpell = armedId == null ? null : state.game.spells[armedId];
    final spell =
        armedSpell ?? state.knownSpells.take(readiedSpellCount).firstOrNull;
    final (meleeMin, meleeMax) = state.attack;
    final boltSpell = armedSpell != null && armedSpell.kind == SpellKind.bolt
        ? armedSpell
        : null;
    final target = state.targetActor;
    return SizedBox(
      key: combatPanelKey,
      width: double.infinity,
      height: crawlCombatPanelHeight * crawlScale(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
        child: DecoratedBox(
          decoration: crawlFrameDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 36,
                  child: _TargetColumn(
                    target: target,
                    name: target == null
                        ? null
                        : state.presentationOf(target.id)?.displayName,
                  ),
                ),
                const _ColumnDivider(),
                Expanded(
                  flex: 24,
                  child: _YouColumn(
                    hp: state.game.hero.hp.clamp(0, state.maxHp),
                    maxHp: state.maxHp,
                    mana: state.mana,
                    maxMana: state.maxMana,
                    hasSpell: state.knownSpells.isNotEmpty,
                    damageMin: boltSpell?.min ?? meleeMin,
                    damageMax: boltSpell?.max ?? meleeMax,
                    damageStyle: boltSpell != null
                        ? monoFigureCold
                        : monoFigure,
                    caption: boltSpell != null ? 'spell' : 'melee',
                  ),
                ),
                const _ColumnDivider(),
                Expanded(
                  flex: 40,
                  child: _SpellColumn(spell: spell, armed: armedSpell != null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnDivider extends StatelessWidget {
  const _ColumnDivider();

  @override
  Widget build(BuildContext context) => const VerticalDivider(
    width: 23,
    thickness: hairline,
    indent: 8,
    endIndent: 8,
    color: crawlDivider,
  );
}

/// TARGET: the panel's own take on `showEnemyInfo`'s facts, compressed to
/// what fits beside DAMAGE and SPELL (PLAN.md G8, G11 "target").
class _TargetColumn extends StatelessWidget {
  const _TargetColumn({required this.target, required this.name});

  final Actor? target;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final target = this.target;
    final name = this.name;
    if (target == null || name == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('TARGET', style: displayLabel),
          SizedBox(height: 3),
          Text('No target in sight', style: textLineDim),
        ],
      );
    }
    final hp = target.hp.clamp(0, target.maxHp);
    final fraction = target.maxHp == 0
        ? 0.0
        : (hp / target.maxHp).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('TARGET', style: displayLabel),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(_capitalise(name), style: displayName, maxLines: 1),
        ),
        const SizedBox(height: 4),
        Text('HP $hp/${target.maxHp}', style: monoData),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.5),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: crawlMeterTrack,
            valueColor: const AlwaysStoppedAnimation(crawlEnemy),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ATK ${target.attackMin}–${target.attackMax}  SPD ${target.speed}',
          style: monoMeta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _factLineB(target),
          style: monoMeta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Fact line B (PLAN.md G11): the target's stated reach or its adjacency,
/// then every resistance and every vulnerability it carries — the same
/// facts `showEnemyInfo`'s sheet lists, joined onto one line rather than
/// stacked, because the panel has one line rather than a sheet's page.
String _factLineB(Actor target) {
  final parts = [
    target.reach > 1 ? 'Reach ${target.reach}' : 'Adjacent',
    for (final type in target.resists) 'Resists ${type.word}',
    for (final type in target.vulnerableTo) 'Burns at ${type.word}',
  ];
  return parts.join(' · ');
}

/// Middle: the hero's own vitals (PLAN.md E5, keyed exactly as [HeroPanel]
/// keys them) over the damage a swing right now would deal.
class _YouColumn extends StatelessWidget {
  const _YouColumn({
    required this.hp,
    required this.maxHp,
    required this.mana,
    required this.maxMana,
    required this.hasSpell,
    required this.damageMin,
    required this.damageMax,
    required this.damageStyle,
    required this.caption,
  });

  final int hp;
  final int maxHp;
  final int mana;
  final int maxMana;
  final bool hasSpell;
  final int damageMin;
  final int damageMax;
  final TextStyle damageStyle;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('YOU', style: displayLabel),
      const SizedBox(height: 2),
      Text('HP $hp/$maxHp', key: hpMeterKey, style: monoData),
      hasSpell
          ? Text('Mana $mana/$maxMana', key: manaMeterKey, style: monoDataDim)
          : const SizedBox(height: 13),
      const SizedBox(height: 6),
      const Divider(height: hairline, thickness: hairline, color: crawlDivider),
      const SizedBox(height: 6),
      const Text('DAMAGE', style: displayLabel),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$damageMin–$damageMax', style: damageStyle),
            const SizedBox(width: 4),
            Text(caption, style: monoSlotMeta),
          ],
        ),
      ),
    ],
  );
}

/// SPELL: the next cast the action row would fire (PLAN.md G11 "spell"), or
/// the sentence a hero with nothing readied sees instead.
class _SpellColumn extends StatelessWidget {
  const _SpellColumn({required this.spell, required this.armed});

  final Spell? spell;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    final label = armed ? 'ARMED SPELL' : 'READIED SPELL';
    final spell = this.spell;
    if (spell == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: displayLabel),
          const SizedBox(height: 3),
          const Text('No spell known', style: textLineDim),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: displayLabel),
        const SizedBox(height: 3),
        SizedBox(
          height: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActionMarkView(spellMark(spell), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spell.name,
                  style: displayNameCold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Mana Cost ', style: monoDataDim),
              TextSpan(text: '${spell.manaCost}', style: monoData),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          _effectOf(spell),
          style: monoMeta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          _tagsOf(spell).join(' | '),
          style: monoMetaCold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// What the spell does, in the panel's own words (PLAN.md G11 "spell"): a
/// distinct grammar from `spell_row.dart`'s `effectOf`, which reads as a
/// cost-line suffix rather than a caption line of its own.
String _effectOf(Spell spell) => switch (spell.kind) {
  SpellKind.bolt => '${spell.type!.word} bolt ${spell.min}–${spell.max}',
  SpellKind.mend => 'Heals ${spell.min}',
  SpellKind.ward => 'Ward holds ${spell.min}',
  SpellKind.bind => 'Binds ${spell.min} turns',
  SpellKind.banish => 'Banishes the target',
};

/// The spell's tags (PLAN.md G11 "spell"): its damage type where it has
/// one, its school, and whether it is cast at a target or at the hero.
List<String> _tagsOf(Spell spell) {
  final type = spell.type;
  return [
    ?type == null ? null : _capitalise(type.word),
    spell.school.schoolWord,
    switch (spell.kind) {
      SpellKind.bolt || SpellKind.bind || SpellKind.banish => 'Targeted',
      SpellKind.mend || SpellKind.ward => 'Self',
    },
  ];
}

/// Upper-cases the first letter only, leaving the rest of the word alone —
/// PLAN.md G11's rule for a target's name and a bolt's damage type, neither
/// of which is otherwise shouted.
String _capitalise(String word) =>
    word.replaceRange(0, 1, word[0].toUpperCase());
