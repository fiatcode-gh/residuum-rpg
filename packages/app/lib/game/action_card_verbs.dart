import 'package:residuum_core/core.dart';

import 'crawl_exits.dart';
import 'event_messages.dart';
import 'game_bloc.dart';

enum CardVerb {
  pickUp,
  gather,
  moveOn,
  ascend,
  descend,
  leave,
  flee,
  wait;

  String get id => switch (this) {
    CardVerb.pickUp => 'pick-up',
    CardVerb.gather => 'gather',
    CardVerb.moveOn => 'move-on',
    CardVerb.ascend => 'ascend',
    CardVerb.descend => 'descend',
    CardVerb.leave => 'leave-dungeon',
    CardVerb.flee => 'flee',
    CardVerb.wait => 'wait',
  };
}

List<CardVerb> cardVerbsFor(GameViewState state) => [
  if (state.canPickUp) CardVerb.pickUp,
  if (state.canGather) CardVerb.gather,
  if (state.isRoadClear) CardVerb.moveOn,
  if (state.canAscend) CardVerb.ascend,
  if (state.canDescend) CardVerb.descend,
  if (state.canLeave) CardVerb.leave,
  if (state.canFlee) CardVerb.flee,
  if (state.offersWait) CardVerb.wait,
];

List<String> placeFacts(GameViewState state) {
  final node = state.nodeUnderfoot;
  final underfoot = state.itemsUnderfoot;
  return [
    if (state.canLeave && state.isAtTheBottom) doneAtTheBottom,
    if (node != null) 'Underfoot: ${node.marking} ${node.word}',
    if (underfoot.isNotEmpty)
      underfoot.length == 1
          ? 'Here: ${underfoot.last.displayName}'
          : 'Here: ${underfoot.last.displayName} '
                'and ${underfoot.length - 1} more',
    if (underfoot.isNotEmpty && state.game.inventory.length >= inventoryCap)
      inventoryFullSentence,
  ];
}
