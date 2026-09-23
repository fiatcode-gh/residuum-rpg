import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';

const heroPanelKey = Key('hero-panel');
const hpMeterKey = Key('hp-meter');
const manaMeterKey = Key('mana-meter');

/// The crawl's character panel (PLAN.md G8 "Hero panel internals", G9, G11):
/// the hero's name, hit points and mana, combat stats, and what they are
/// carrying in the two equipped slots and the two quick ones.
///
/// A pure projection over [state], exactly like [CrawlStatus]: nothing here
/// dispatches, so every fact comes in through the constructor. [heroLabel] is
/// a separate parameter rather than read off [state] because it is app state,
/// not crawl state (PLAN.md E4) — [GameBloc] carries it as a run constant
/// beside `dungeon`.
class HeroPanel extends StatelessWidget {
  const HeroPanel({required this.state, required this.heroLabel, super.key});

  final GameViewState state;
  final String? heroLabel;

  @override
  Widget build(BuildContext context) {
    final hasSpell = state.knownSpells.isNotEmpty;
    final weapon = state.game.loadout.weapon;
    final chest = state.game.equipment[EquipSlot.chest];
    final (attackMin, attackMax) = state.attack;
    return SizedBox(
      key: heroPanelKey,
      width: double.infinity,
      height: crawlHeroPanelHeight * crawlScale(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
        child: DecoratedBox(
          decoration: crawlFrameDecoration,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 11,
              right: 11,
              top: 10,
              bottom: 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 40,
                  child: _HeroColumn(
                    heroLabel: heroLabel,
                    hp: state.game.hero.hp.clamp(0, state.maxHp),
                    maxHp: state.maxHp,
                    mana: state.mana,
                    maxMana: state.maxMana,
                    hasSpell: hasSpell,
                    attackMin: attackMin,
                    attackMax: attackMax,
                    armor: state.armor,
                    gold: state.game.gold,
                  ),
                ),
                const VerticalDivider(
                  width: 23,
                  thickness: hairline,
                  indent: 8,
                  endIndent: 8,
                  color: crawlDivider,
                ),
                Expanded(
                  flex: 33,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _LabelledMark(
                        label: 'WEAPON',
                        mark: FontMark(
                          weapon != null ? Icons.gavel : Icons.front_hand,
                        ),
                        text: weapon?.displayName ?? 'Bare fists',
                      ),
                      _LabelledMark(
                        label: 'ARMOUR',
                        mark: FontMark(
                          chest != null ? Icons.shield : Icons.shield_outlined,
                        ),
                        text: chest?.displayName ?? 'None',
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(
                  width: 23,
                  thickness: hairline,
                  indent: 8,
                  endIndent: 8,
                  color: crawlDivider,
                ),
                Expanded(
                  flex: 27,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _LabelledMark(
                        label: 'QUICK',
                        mark: const ShippedMark(ActionIcon.potion),
                        text: 'Potion ×${state.potionCount}',
                      ),
                      _LabelledMark(
                        label: 'PACK',
                        mark: const ShippedMark(ActionIcon.pack),
                        text: '${state.game.inventory.length}/$inventoryCap',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The left column: the hero's name, the two resource meters (PLAN.md G11:
/// mana only with a known spell, an equal-height blank otherwise so the
/// panel never resizes), and the combat stat line.
class _HeroColumn extends StatelessWidget {
  const _HeroColumn({
    required this.heroLabel,
    required this.hp,
    required this.maxHp,
    required this.mana,
    required this.maxMana,
    required this.hasSpell,
    required this.attackMin,
    required this.attackMax,
    required this.armor,
    required this.gold,
  });

  final String? heroLabel;
  final int hp;
  final int maxHp;
  final int mana;
  final int maxMana;
  final bool hasSpell;
  final int attackMin;
  final int attackMax;
  final int armor;
  final int gold;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (heroLabel ?? '').toUpperCase(),
            style: displaySection,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const SizedBox(
            height: hairline,
            child: ColoredBox(color: crawlGoldRule),
          ),
          const SizedBox(height: 4),
          _CrawlMeter(
            key: hpMeterKey,
            label: 'HP',
            value: hp,
            ceiling: maxHp,
            fill: crawlEnemy,
          ),
          const SizedBox(height: 4),
          hasSpell
              ? _CrawlMeter(
                  key: manaMeterKey,
                  label: 'Mana',
                  value: mana,
                  ceiling: maxMana,
                  fill: crawlCold,
                )
              : const SizedBox(height: 20),
        ],
      ),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'ATK ', style: monoDataDim),
            TextSpan(text: '$attackMin–$attackMax', style: monoData),
            const TextSpan(text: '  ARM ', style: monoDataDim),
            TextSpan(text: '$armor', style: monoData),
            const TextSpan(text: '  GOLD ', style: monoDataDim),
            TextSpan(text: '$gold', style: monoData),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

/// One resource meter: the "`label a/b`" line over its 6 dp bar (PLAN.md
/// G8). The key sits on this group, not on either child, so the finder that
/// used to reach the bar through [ResourceMeter] on the old status row now
/// reaches it here instead.
class _CrawlMeter extends StatelessWidget {
  const _CrawlMeter({
    required this.label,
    required this.value,
    required this.ceiling,
    required this.fill,
    super.key,
  });

  final String label;
  final int value;
  final int ceiling;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final fraction = ceiling == 0
        ? 0.0
        : (value / ceiling).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label $value/$ceiling', style: monoData),
        const SizedBox(height: 1),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: crawlMeterTrack,
            valueColor: AlwaysStoppedAnimation(fill),
          ),
        ),
      ],
    );
  }
}

/// One middle/right-column entry: a section caption, then a mark beside a
/// name or count that may wrap to at most two lines (PLAN.md G8).
class _LabelledMark extends StatelessWidget {
  const _LabelledMark({
    required this.label,
    required this.mark,
    required this.text,
  });

  final String label;
  final ActionMark mark;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: displayLabel),
      const SizedBox(height: 3),
      SizedBox(
        height: 26,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActionMarkView(mark, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: monoItem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
