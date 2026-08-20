import '../loot/equip_slot.dart';
import 'position.dart';

/// Something the player asks the game to do. One action is one turn.
///
/// An action the rules **refuse** is not a turn: it costs nothing and the
/// monsters do not act. Bumping a wall is different — that is an accepted move
/// that failed, and it costs the turn like any other.
sealed class GameAction {
  const GameAction();
}

/// Step the hero one tile, or attack whatever stands there.
final class MoveAction extends GameAction {
  const MoveAction(this.direction);

  final Direction direction;
}

/// Take the stairs down. Only does anything where the stairs are.
final class DescendAction extends GameAction {
  const DescendAction();
}

/// Take the newest item lying under the hero.
///
/// Refused when there is nothing underfoot, and when the inventory is full.
final class PickUpAction extends GameAction {
  const PickUpAction();
}

/// Wear the carried item with this id, displacing whatever the slot holds.
///
/// Refused when nothing carried answers to the id, when the item is not
/// equippable, and when a shield is offered while a two-hander is held.
final class EquipAction extends GameAction {
  const EquipAction(this.itemId);

  final String itemId;
}

/// Take off whatever is in this slot. Refused when the slot is empty.
final class UnequipAction extends GameAction {
  const UnequipAction(this.slot);

  final EquipSlot slot;
}

/// Drink the carried potion with this id.
///
/// Refused when nothing carried answers to the id, and when it is not a potion.
/// Drinking at full health is *not* refused: it consumes the turn and the
/// potion and heals nothing, because a wasted potion is a player's mistake and
/// not the rules' to undo.
final class DrinkAction extends GameAction {
  const DrinkAction(this.itemId);

  final String itemId;
}

/// Put the carried item with this id down on the hero's tile.
///
/// Refused when nothing carried answers to the id.
final class DropAction extends GameAction {
  const DropAction(this.itemId);

  final String itemId;
}
