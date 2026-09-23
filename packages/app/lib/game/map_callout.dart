import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';
import 'grid_geometry.dart';
import 'target_facts.dart';

const mapCalloutKey = Key('map-callout');

/// PLAN.md Task 12 decision 3: an anchored card beside an inspected
/// monster's cell, with a leader line back to it — replacing the bottom
/// sheet a map tap or long-press used to open. Shown only while
/// [GameViewState.inspectedActor] names a monster whose cell rect still
/// intersects the map slot; panning, stepping, dying or otherwise leaving
/// sight removes the card exactly as `inspectedActor`'s own
/// alive/visible/known test says it should — the same guard
/// [GameViewState.selectedActor] already carries.
///
/// [size] is the map slot's own size, the same box `GameScreen`'s recenter
/// check frames its [GridGeometry] against, so the card and the glyphs it
/// points at agree on where the cell actually is.
class MapCallout extends StatelessWidget {
  const MapCallout({required this.state, required this.size, super.key});

  final GameViewState state;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final actor = state.inspectedActor;
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

    final resists = actor.resists;
    final vulnerable = actor.vulnerableTo;
    final lineCount = 2 + resists.length + vulnerable.length;
    final scale = crawlScale(context);
    final height =
        crawlCalloutPadding * 2 +
        crawlCalloutNameRow * scale +
        crawlCalloutGap +
        crawlCalloutHpRow * scale +
        crawlCalloutGap +
        crawlCalloutLineHeight * scale * lineCount;

    var flipped = false;
    var left = cellRect.right + crawlCalloutMargin;
    if (left + crawlCalloutWidth > size.width - crawlCalloutEdgeClamp) {
      flipped = true;
      left = cellRect.left - crawlCalloutMargin - crawlCalloutWidth;
    }
    var below = false;
    var top = cellRect.top - crawlCalloutLeaderGap - height;
    if (top < crawlCalloutEdgeClamp) {
      below = true;
      top = cellRect.bottom + crawlCalloutLeaderGap;
    }
    left = left.clamp(
      crawlCalloutEdgeClamp,
      math.max(
        crawlCalloutEdgeClamp,
        size.width - crawlCalloutEdgeClamp - crawlCalloutWidth,
      ),
    );
    top = top.clamp(
      crawlCalloutEdgeClamp,
      math.max(
        crawlCalloutEdgeClamp,
        size.height - crawlCalloutEdgeClamp - height,
      ),
    );

    final cardRect = Offset(left, top) & Size(crawlCalloutWidth, height);
    final cellCorner = Offset(
      flipped ? cellRect.left : cellRect.right,
      below ? cellRect.bottom : cellRect.top,
    );
    final cardCorner = Offset(
      flipped ? cardRect.right : cardRect.left,
      below ? cardRect.top : cardRect.bottom,
    );

    final hp = actor.hp.clamp(0, actor.maxHp);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LeaderPainter(from: cellCorner, to: cardCorner),
            ),
          ),
        ),
        Positioned(
          key: mapCalloutKey,
          left: cardRect.left,
          top: cardRect.top,
          width: cardRect.width,
          height: cardRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: crawlCalloutFill,
                border: Border.all(color: crawlFrame),
                borderRadius: BorderRadius.circular(6),
              ),
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
                    SizedBox(
                      height: crawlCalloutHpRow * scale,
                      child: Text('HP $hp/${actor.maxHp}', style: monoData),
                    ),
                    const SizedBox(height: crawlCalloutGap),
                    for (final line in targetFactLines(actor)) _MetaLine(line),
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

/// One `monoMeta` fact line (PLAN.md G11 "callout"): the fixed-height row
/// the card's height formula counts one [crawlCalloutLineHeight] for.
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

/// The 1 dp gold leader (PLAN.md Task 12 decision 3): the cell's own corner
/// on the card's side, to the card's nearest corner, with a 2.5 dp dot at
/// the cell end.
class _LeaderPainter extends CustomPainter {
  const _LeaderPainter({required this.from, required this.to});

  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = crawlGold.withValues(alpha: 0.7)
      ..strokeWidth = crawlCalloutLeaderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, line);
    final dot = Paint()
      ..color = crawlGold.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(from, crawlCalloutDotRadius, dot);
  }

  @override
  bool shouldRepaint(covariant _LeaderPainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}
