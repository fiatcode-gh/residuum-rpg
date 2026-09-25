import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import '../world/world_bloc.dart';
import 'action_card_verbs.dart';
import 'action_icon.dart';
import 'crawl_exits.dart';
import 'crawl_slot.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';

const actionCardKey = Key('action-card');
const actionCardLeaderKey = Key('action-card-leader');

double actionCardHeight(GameViewState state, double scale) {
  final facts = placeFacts(state).length;
  final verbs = cardVerbsFor(state).length;
  if (facts == 0 && verbs == 0) return 0;
  final rows = verbs == 0 ? 0 : (verbs / 4).ceil();
  return crawlCalloutPadding * 2 +
      facts * crawlCalloutLineHeight * scale +
      (facts > 0 && verbs > 0 ? crawlActionCardGap : 0) +
      rows * crawlTouchTarget +
      (rows > 1 ? (rows - 1) * crawlActionCardGap : 0);
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.bloc,
    required this.state,
    required this.width,
    super.key,
  });

  final GameBloc bloc;
  final GameViewState state;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scale = crawlScale(context);
    final facts = placeFacts(state);
    final verbs = cardVerbsFor(state);
    final buttonWidth =
        (width - crawlCalloutPadding * 2 - 3 * crawlActionCardGap) / 4;

    final rows = <Widget>[];
    for (var index = 0; index < verbs.length; index += 4) {
      if (index > 0) rows.add(const SizedBox(height: crawlActionCardGap));
      final slice = verbs.skip(index).take(4).toList(growable: false);
      rows.add(
        Row(
          children: [
            for (var i = 0; i < slice.length; i++) ...[
              if (i > 0) const SizedBox(width: crawlActionCardGap),
              _button(context, slice[i], buttonWidth),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      key: actionCardKey,
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: DecoratedBox(
        decoration: crawlCalloutDecoration,
        child: Padding(
          padding: const EdgeInsets.all(crawlCalloutPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final fact in facts)
                SizedBox(
                  height: crawlCalloutLineHeight * scale,
                  child: Text(
                    fact,
                    style: monoMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (facts.isNotEmpty && verbs.isNotEmpty)
                const SizedBox(height: crawlActionCardGap),
              ...rows,
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(BuildContext context, CardVerb verb, double width) {
    final node = state.nodeUnderfoot;
    final ending = state.canLeave && state.isAtTheBottom;
    final (label, mark, onPressed) = switch (verb) {
      CardVerb.pickUp => (
        'Pick up',
        const FontMark(Icons.back_hand) as ActionMark,
        () => bloc.add(const PickUpPressed()),
      ),
      CardVerb.gather => (
        node!.verb,
        FontMark(node == GatherKind.oreVein ? Icons.hardware : Icons.spa)
            as ActionMark,
        () => bloc.add(const GatherPressed()),
      ),
      CardVerb.moveOn => (
        'Move on',
        const FontMark(Icons.hiking) as ActionMark,
        () => leaveEncounter(context, state, EncounterEnding.cleared),
      ),
      CardVerb.ascend => (
        'Ascend <',
        const ShippedMark(ActionIcon.ascend) as ActionMark,
        () => bloc.add(const AscendPressed()),
      ),
      CardVerb.descend => (
        'Descend >',
        const ShippedMark(ActionIcon.descend) as ActionMark,
        () => bloc.add(const DescendPressed()),
      ),
      CardVerb.leave => (
        ending ? doneControl : 'Leave',
        FontMark(ending ? Icons.flag : Icons.logout) as ActionMark,
        ending
            ? () => confirmCompletion(context, state)
            : () => suspendDungeon(context, state),
      ),
      CardVerb.flee => (
        'Flee',
        const FontMark(Icons.directions_run) as ActionMark,
        () => bloc.add(const FleePressed()),
      ),
      CardVerb.wait => (
        'Wait',
        const ShippedMark(ActionIcon.wait) as ActionMark,
        () => bloc.add(const WaitPressed()),
      ),
    };
    return CrawlSlot(
      key: ValueKey(verb.id),
      label: label,
      mark: mark,
      onPressed: onPressed,
      width: width,
      height: crawlTouchTarget,
    );
  }
}
