import 'package:flutter/material.dart';

import '../art/art_assets.dart';
import 'action_icon.dart';
import 'crawl_slot.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';
import 'log_drawer.dart';

/// The log row's only test handle (PLAN.md G8).
const logRowKey = Key('log-row');

/// The framed recent-events peek beside the crawl's combat-time controls
/// (PLAN.md G8): Wait while the hero is Watched or fighting, and Flee
/// alongside it while fleeing is legal. The row's own height never changes
/// whether the side column shows nothing, one control or both — only the
/// log narrows to make room for it.
class LogRow extends StatelessWidget {
  const LogRow({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) {
    final height = crawlLogRowHeight * crawlScale(context);
    final side = state.offersWait || state.canFlee;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LogPeek(key: logPeekKey, state: state, bloc: bloc),
            ),
            if (side) ...[
              const SizedBox(width: crawlSideControlGap),
              _SideControls(state: state, bloc: bloc, height: height),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wait on top, Flee on the bottom, each slot rendered or held open as an
/// empty gap so Wait never moves down to meet a missing Flee.
class _SideControls extends StatelessWidget {
  const _SideControls({
    required this.state,
    required this.bloc,
    required this.height,
  });

  final GameViewState state;
  final GameBloc bloc;
  final double height;

  @override
  Widget build(BuildContext context) {
    final slotHeight = (height - crawlSideControlGap) / 2;
    return SizedBox(
      width: crawlSideControlWidth,
      height: height,
      child: Column(
        children: [
          if (state.offersWait)
            CrawlSlot(
              key: const ValueKey('wait'),
              label: 'Wait',
              mark: const ShippedMark(ActionIcon.wait),
              onPressed: () => bloc.add(const WaitPressed()),
              width: crawlSideControlWidth,
              height: slotHeight,
            )
          else
            SizedBox(width: crawlSideControlWidth, height: slotHeight),
          const SizedBox(height: crawlSideControlGap),
          if (state.canFlee)
            CrawlSlot(
              key: const ValueKey('flee'),
              label: 'Flee',
              mark: const FontMark(Icons.directions_run),
              onPressed: () => bloc.add(const FleePressed()),
              width: crawlSideControlWidth,
              height: slotHeight,
            )
          else
            SizedBox(width: crawlSideControlWidth, height: slotHeight),
        ],
      ),
    );
  }
}
