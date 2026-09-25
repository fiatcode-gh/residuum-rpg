import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'crawl_meter.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'grid_geometry.dart';
import 'map_overlay_layout.dart';
import 'target_facts.dart';

const targetCardKey = Key('target-card');

class TargetCard extends StatelessWidget {
  const TargetCard({
    required this.state,
    required this.size,
    this.area,
    this.avoid = const [],
    super.key,
  });

  final GameViewState state;
  final Size size;
  final Rect? area;
  final List<Rect> avoid;

  @override
  Widget build(BuildContext context) {
    final actor =
        state.inspectedActor ?? (state.isBattleOpen ? state.targetActor : null);
    if (actor == null) return const SizedBox.shrink();
    final name = state.presentationOf(actor.id)?.displayName;
    if (name == null) return const SizedBox.shrink();

    final geometry = GridGeometry.camera(
      size,
      state.game.map.width,
      state.game.map.height,
      state.cameraFocus,
      state.pan,
    );
    final cellRect = geometry.rectOf(actor.position);
    if (!(Offset.zero & size).overlaps(cellRect)) {
      return const SizedBox.shrink();
    }

    final lines = targetFactLines(actor);
    final scale = crawlScale(context);
    final height =
        crawlCalloutPadding * 2 +
        crawlCalloutNameRow * scale +
        crawlCalloutGap +
        crawlCalloutHpRow * scale +
        crawlCalloutBarRow +
        crawlCalloutLineHeight * scale * lines.length;
    const width = crawlCalloutWidth;

    final hero = geometry.rectOf(state.game.hero.position);
    final block = heroBlock(hero);
    final cardRect = placeMapOverlay(
      area: area ?? (Offset.zero & size),
      size: Size(width, height),
      hero: hero,
      preferred: [
        Offset(
          cellRect.right + crawlCalloutMargin,
          cellRect.top - crawlCalloutLeaderGap - height,
        ),
        Offset(
          cellRect.left - crawlCalloutMargin - width,
          cellRect.top - crawlCalloutLeaderGap - height,
        ),
        Offset(
          cellRect.right + crawlCalloutMargin,
          cellRect.bottom + crawlCalloutLeaderGap,
        ),
        Offset(
          cellRect.left - crawlCalloutMargin - width,
          cellRect.bottom + crawlCalloutLeaderGap,
        ),
        Offset(
          hero.center.dx - width / 2,
          block.bottom + crawlCalloutLeaderGap,
        ),
        Offset(
          hero.center.dx - width / 2,
          block.top - crawlCalloutLeaderGap - height,
        ),
      ],
      avoid: [cellRect, ...avoid],
    );

    final cellCorner = Offset(
      cardRect.center.dx >= cellRect.center.dx ? cellRect.right : cellRect.left,
      cardRect.center.dy >= cellRect.center.dy ? cellRect.bottom : cellRect.top,
    );
    final cardCorner = Offset(
      cellRect.center.dx >= cardRect.center.dx ? cardRect.right : cardRect.left,
      cellRect.center.dy >= cardRect.center.dy ? cardRect.bottom : cardRect.top,
    );

    final hp = actor.hp.clamp(0, actor.maxHp);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: LeaderPainter(from: cellCorner, to: cardCorner),
            ),
          ),
        ),
        Positioned(
          key: targetCardKey,
          left: cardRect.left,
          top: cardRect.top,
          width: cardRect.width,
          height: cardRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: DecoratedBox(
              decoration: crawlCalloutDecoration,
              child: Padding(
                padding: const EdgeInsets.all(crawlCalloutPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: crawlCalloutNameRow * scale,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          capitaliseFirst(name),
                          style: displayName,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: crawlCalloutGap),
                    CrawlMeter(
                      label: 'HP',
                      value: hp,
                      ceiling: actor.maxHp,
                      barHeight: 5,
                      fill: crawlEnemy,
                    ),
                    const SizedBox(height: crawlCalloutGap),
                    for (final line in lines) _MetaLine(line),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: crawlCalloutLineHeight * crawlScale(context),
    child: Text(
      text,
      style: monoMeta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
