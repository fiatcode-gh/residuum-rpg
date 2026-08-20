import 'position.dart';

/// Something the player asks the game to do. One action is one turn.
sealed class GameAction {
  const GameAction();
}

/// Step the hero one tile, or attack whatever stands there.
final class MoveAction extends GameAction {
  const MoveAction(this.direction);

  final Direction direction;
}
