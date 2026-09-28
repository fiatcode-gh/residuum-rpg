import 'dart:math' as math;

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

const actionBarKey = Key('action-bar');
const actionBarIdle = 'Nothing to do here.';

double actionBarHeight(double scale) =>
    2 * crawlActionBarPadding +
    crawlActionBarTitleRow * scale +
    crawlActionBarTitleGap +
    crawlActionBarFactLines * crawlCalloutLineHeight * scale +
    crawlActionBarGap +
    crawlTouchTarget;

class ActionBar extends StatelessWidget {
  const ActionBar({required this.bloc, required this.state, super.key});

  final GameBloc bloc;
  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final scale = crawlScale(context);
    final verbs = cardVerbsFor(state);
    final rawFacts = placeFacts(state);
    final facts = rawFacts.length <= 3
        ? rawFacts
        : [rawFacts[0], rawFacts[1], rawFacts.sublist(2).join(' · ')];
    final lines = facts.isEmpty && verbs.isEmpty
        ? const [actionBarIdle]
        : facts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
      child: SizedBox(
        height: actionBarHeight(scale),
        child: DecoratedBox(
          decoration: crawlFrameDecoration,
          child: Padding(
            padding: const EdgeInsets.all(crawlActionBarPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final n = math.max(4, verbs.length);
                final buttonWidth =
                    (constraints.maxWidth - (n - 1) * crawlActionBarGap) / n;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: crawlActionBarTitleRow * scale,
                      child: const Text(
                        'ACTIONS',
                        style: displaySection,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: crawlActionBarTitleGap),
                    SizedBox(
                      height:
                          crawlActionBarFactLines *
                          crawlCalloutLineHeight *
                          scale,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in lines)
                            SizedBox(
                              height: crawlCalloutLineHeight * scale,
                              child: Text(
                                line,
                                style: monoMeta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: crawlActionBarGap),
                    SizedBox(
                      height: crawlTouchTarget,
                      child: Row(
                        children: [
                          for (var i = 0; i < verbs.length; i++) ...[
                            if (i > 0) const SizedBox(width: crawlActionBarGap),
                            _button(context, verbs[i], buttonWidth),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
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
