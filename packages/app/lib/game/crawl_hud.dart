import 'package:flutter/material.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../style/tokens.dart';
import 'crawl_meter.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';

const crawlHudKey = Key('crawl-hud');
const depthPairKey = Key('crawl-depth');
const crawlChipBattleKey = Key('crawl-chip-battle');
const crawlChipConditionKey = Key('crawl-chip-condition');
const crawlChipWardKey = Key('crawl-chip-ward');
const hpMeterKey = Key('hp-meter');
const manaMeterKey = Key('mana-meter');
const crawlGoldKey = Key('crawl-gold');

class CrawlHud extends StatelessWidget {
  const CrawlHud({
    required this.state,
    required this.dungeon,
    required this.day,
    super.key,
  });

  final GameViewState state;
  final NodeId? dungeon;
  final int? day;

  @override
  Widget build(BuildContext context) {
    final hero = state.game.hero;
    final hasSpell = state.knownSpells.isNotEmpty;
    return SizedBox(
      key: crawlHudKey,
      width: double.infinity,
      height: crawlHudHeight * crawlScale(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 38,
                  child: CrawlMeter(
                    key: hpMeterKey,
                    label: 'HP',
                    value: hero.hp.clamp(0, state.maxHp),
                    ceiling: state.maxHp,
                    fill: crawlEnemy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 38,
                  child: hasSpell
                      ? CrawlMeter(
                          key: manaMeterKey,
                          label: 'Mana',
                          value: state.mana,
                          ceiling: state.maxMana,
                          fill: crawlCold,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  key: crawlGoldKey,
                  width: 72,
                  child: Semantics(
                    label: 'Gold ${state.game.gold}',
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.paid, size: 14, color: crawlGold),
                          const SizedBox(width: 4),
                          Text('${state.game.gold}', style: monoData),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MetaLine(state: state, dungeon: dungeon, day: day),
            const SizedBox(height: 4),
            _ChipsRow(state: state),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.state, required this.dungeon, this.day});

  final GameViewState state;
  final NodeId? dungeon;
  final int? day;

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[
      if (!state.isEncounter)
        Text(
          'Depth ${state.depth}/${state.deepest}',
          key: depthPairKey,
          style: monoMeta,
        ),
      Text(_placeName(state, dungeon), style: monoMeta),
      if (day != null) Text('Day $day', style: monoMeta),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const Text('  |  ', style: monoMeta),
          segments[i],
        ],
      ],
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final hero = state.game.hero;
    final ceiling = state.maxHp;
    final fraction = ceiling == 0 ? 0.0 : hero.hp / ceiling;
    final chips = <Widget>[
      ?_battleChip(state),
      _conditionChip(fraction),
      if (state.warded > 0)
        _StatusChip(
          key: crawlChipWardKey,
          mark: ChipMark.square,
          color: crawlCold,
          word: 'Ward ${state.warded}',
        ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          chips[i],
        ],
      ],
    );
  }
}

Widget? _battleChip(GameViewState state) {
  if (state.isBattleOpen) {
    return _StatusChip(
      key: crawlChipBattleKey,
      mark: ChipMark.diamond,
      color: crawlEnemy,
      word: 'Engaged ${state.enemiesInSight}',
    );
  }
  if (state.enemiesInSight > 0) {
    return _StatusChip(
      key: crawlChipBattleKey,
      mark: ChipMark.ring,
      color: crawlTorch,
      word: 'Watched ${state.enemiesInSight}',
    );
  }
  return null;
}

Widget _conditionChip(double fraction) {
  if (fraction <= 0) {
    return const _StatusChip(
      key: crawlChipConditionKey,
      mark: ChipMark.cross,
      color: crawlEnemy,
      word: 'Dead',
    );
  }
  if (fraction < 0.25) {
    return const _StatusChip(
      key: crawlChipConditionKey,
      mark: ChipMark.triangle,
      color: crawlEnemy,
      word: 'Critical',
    );
  }
  if (fraction < 0.6) {
    return const _StatusChip(
      key: crawlChipConditionKey,
      mark: ChipMark.halfCircle,
      color: crawlTorch,
      word: 'Wounded',
    );
  }
  return const _StatusChip(
    key: crawlChipConditionKey,
    mark: ChipMark.filledCircle,
    color: crawlGold,
    word: 'Steady',
  );
}

String _placeName(GameViewState state, NodeId? dungeon) {
  if (state.isEncounter) return 'The Road';
  if (dungeon == null) return '';
  return residuumWorld.nodeAt(dungeon).name;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.mark,
    required this.color,
    required this.word,
    super.key,
  });

  final ChipMark mark;
  final Color color;
  final String word;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: crawlBackground.withValues(alpha: 0.5),
      border: Border.all(color: crawlChipBorder),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CustomPaint(painter: ChipMarkPainter(mark, color)),
            ),
            const SizedBox(width: 5),
            Text(word, style: monoChip),
          ],
        ),
      ),
    ),
  );
}

enum ChipMark {
  diamond,
  ring,
  filledCircle,
  halfCircle,
  triangle,
  cross,
  square,
}

class ChipMarkPainter extends CustomPainter {
  const ChipMarkPainter(this.mark, this.color);

  final ChipMark mark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    switch (mark) {
      case ChipMark.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(centre.dx, 0)
            ..lineTo(size.width, centre.dy)
            ..lineTo(centre.dx, size.height)
            ..lineTo(0, centre.dy)
            ..close(),
          fill,
        );
      case ChipMark.ring:
        canvas.drawCircle(centre, size.width / 2 - 0.75, stroke);
      case ChipMark.filledCircle:
        canvas.drawCircle(centre, size.width / 2, fill);
      case ChipMark.halfCircle:
        canvas.drawCircle(centre, size.width / 2, stroke);
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
        canvas.drawCircle(centre, size.width / 2, fill);
        canvas.restore();
      case ChipMark.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(centre.dx, 0)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close(),
          fill,
        );
      case ChipMark.cross:
        canvas
          ..drawLine(Offset.zero, Offset(size.width, size.height), stroke)
          ..drawLine(Offset(size.width, 0), Offset(0, size.height), stroke);
      case ChipMark.square:
        canvas.drawRect(Offset.zero & size, fill);
    }
  }

  @override
  bool shouldRepaint(covariant ChipMarkPainter oldDelegate) =>
      oldDelegate.mark != mark || oldDelegate.color != color;
}
