import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import '../world/world_bloc.dart';
import 'action_icon.dart';
import 'crawl_exits.dart';
import 'crawl_style.dart';
import 'game_bloc.dart';
import 'place_actions.dart';

const placePopupKey = Key('place-popup');

double placePopupHeight(GameViewState state, double scale) {
  final facts = placeFacts(state).length;
  final verbs = placeVerbsFor(state).length;
  if (facts == 0 && verbs == 0) return 0;
  final rows = verbs == 0 ? 0 : (verbs / 2).ceil();
  return crawlCalloutPadding * 2 +
      facts * crawlCalloutLineHeight * scale +
      (facts > 0 && verbs > 0 ? crawlPlaceButtonGap : 0) +
      rows * crawlPlaceButtonHeight +
      (rows > 1 ? (rows - 1) * crawlPlaceButtonGap : 0);
}

class PlacePopup extends StatelessWidget {
  const PlacePopup({
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
    final verbs = placeVerbsFor(state);
    final buttonWidth = verbs.length <= 1
        ? width - crawlCalloutPadding * 2
        : (width - crawlCalloutPadding * 2 - crawlPlaceButtonGap) / 2;

    final rows = <Widget>[];
    for (var index = 0; index < verbs.length; index += 2) {
      if (index > 0) rows.add(const SizedBox(height: crawlPlaceButtonGap));
      final left = verbs[index];
      final right = index + 1 < verbs.length ? verbs[index + 1] : null;
      rows.add(
        verbs.length == 1
            ? _button(context, left, buttonWidth)
            : Row(
                children: [
                  _button(context, left, buttonWidth),
                  const SizedBox(width: crawlPlaceButtonGap),
                  right == null
                      ? SizedBox(width: buttonWidth)
                      : _button(context, right, buttonWidth),
                ],
              ),
      );
    }

    return GestureDetector(
      key: placePopupKey,
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
                const SizedBox(height: crawlPlaceButtonGap),
              ...rows,
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(BuildContext context, PlaceVerb verb, double width) {
    final node = state.nodeUnderfoot;
    final ending = state.canLeave && state.isAtTheBottom;
    final (label, mark, onPressed) = switch (verb) {
      PlaceVerb.pickUp => (
        'Pick up',
        const FontMark(Icons.back_hand) as ActionMark,
        () => bloc.add(const PickUpPressed()),
      ),
      PlaceVerb.gather => (
        node!.verb,
        FontMark(node == GatherKind.oreVein ? Icons.hardware : Icons.spa)
            as ActionMark,
        () => bloc.add(const GatherPressed()),
      ),
      PlaceVerb.moveOn => (
        'Move on',
        const FontMark(Icons.hiking) as ActionMark,
        () => leaveEncounter(context, state, EncounterEnding.cleared),
      ),
      PlaceVerb.ascend => (
        'Ascend <',
        const ShippedMark(ActionIcon.ascend) as ActionMark,
        () => bloc.add(const AscendPressed()),
      ),
      PlaceVerb.descend => (
        'Descend >',
        const ShippedMark(ActionIcon.descend) as ActionMark,
        () => bloc.add(const DescendPressed()),
      ),
      PlaceVerb.leave => (
        ending ? doneControl : 'Leave',
        FontMark(ending ? Icons.flag : Icons.logout) as ActionMark,
        ending
            ? () => confirmCompletion(context, state)
            : () => suspendDungeon(context, state),
      ),
    };
    return SizedBox(
      key: ValueKey(verb.id),
      width: width,
      height: crawlPlaceButtonHeight,
      child: Semantics(
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: Material(
            color: crawlSlotFill,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: crawlFrame),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionMarkView(mark, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, style: textSlot),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
