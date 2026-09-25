import 'crawl_exits.dart';
import 'game_bloc.dart';

enum PlaceVerb {
  pickUp,
  gather,
  moveOn,
  ascend,
  descend,
  leave;

  String get id => switch (this) {
    PlaceVerb.pickUp => 'pick-up',
    PlaceVerb.gather => 'gather',
    PlaceVerb.moveOn => 'move-on',
    PlaceVerb.ascend => 'ascend',
    PlaceVerb.descend => 'descend',
    PlaceVerb.leave => 'leave-dungeon',
  };
}

List<PlaceVerb> placeVerbsFor(GameViewState state) => [
  if (state.canPickUp) PlaceVerb.pickUp,
  if (state.canGather) PlaceVerb.gather,
  if (state.isRoadClear) PlaceVerb.moveOn,
  if (state.canAscend) PlaceVerb.ascend,
  if (state.canDescend) PlaceVerb.descend,
  if (state.canLeave) PlaceVerb.leave,
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
  ];
}
