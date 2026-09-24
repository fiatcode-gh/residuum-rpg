import 'package:flutter/material.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../style/tokens.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';

const crawlHeaderKey = Key('crawl-header');
const depthPairKey = Key('crawl-depth');
const crawlChipBattleKey = Key('crawl-chip-battle');
const crawlChipConditionKey = Key('crawl-chip-condition');
const crawlChipWardKey = Key('crawl-chip-ward');

/// The crawl's wordmark header (PLAN.md G8 "Header internals", G9 chip
/// shapes, G11 displayed facts): the brand, the meta line naming where and
/// when the hero stands, and the chips reading battle, condition and ward.
///
/// A pure projection, deliberately: it reads no bloc and dispatches
/// nothing, so every fact on it comes in through [state], [dungeon] and
/// [day]. [day] is a separate parameter rather than read off [state]
/// because it is app state, not crawl state (PLAN.md E4) — [GameBloc]
/// carries it as a run constant beside `dungeon`.
class CrawlHeader extends StatelessWidget {
  const CrawlHeader({
    required this.state,
    required this.dungeon,
    required this.day,
    super.key,
  });

  final GameViewState state;
  final NodeId? dungeon;
  final int? day;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: crawlHeaderKey,
    width: double.infinity,
    height: crawlHeaderHeight * crawlScale(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        const ExcludeSemantics(
          child: Text(
            'RESIDUUM',
            textAlign: TextAlign.center,
            style: displayWordmark,
          ),
        ),
        const SizedBox(height: 7),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: crawlGutter),
          child: SizedBox(
            height: hairline,
            child: ColoredBox(color: crawlGoldRule),
          ),
        ),
        const SizedBox(height: 7),
        _MetaLine(state: state, dungeon: dungeon, day: day),
        const SizedBox(height: 6),
        _ChipsRow(state: state),
        const SizedBox(height: 4),
      ],
    ),
  );
}

/// The header's second line (PLAN.md G11): depth (omitted on an
/// encounter), the place, and the day (omitted when null), separated by
/// `  |  ` in `monoMeta`.
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

/// The header's chip row (PLAN.md G9, G11): battle, condition, ward, each
/// its own fixed shape and word, in that order.
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

/// One status chip (PLAN.md G8 "Header internals"): an 8 dp
/// [ChipMarkPainter] shape, then its word, framed and filled.
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

/// The status chips' whole shape vocabulary (PLAN.md G9): shape and weight
/// carry the fact, never hue alone, so greyscale reading keeps every chip
/// apart.
enum ChipMark {
  diamond,
  ring,
  filledCircle,
  halfCircle,
  triangle,
  cross,
  square,
}

/// Draws one [ChipMark] inside its 8 dp box (PLAN.md G9 status-chip
/// shapes).
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
