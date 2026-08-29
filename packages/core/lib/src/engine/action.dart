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

/// Take the stairs up. Only does anything where the stairs up are.
///
/// **Refused** rather than blocked away from the tile, which is the opposite of
/// [DescendAction]'s wall-bump. The two differ because their controls do: the
/// interface only ever offers Ascend on the tile it works from, so charging a
/// turn for it could only ever punish a mis-tap, never a probe of the dark.
final class AscendAction extends GameAction {
  const AscendAction();
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

/// Read the carried spell book with this id, learning what it teaches.
///
/// Refused when nothing carried answers to the id, when the item is not a book,
/// when the hero already knows the spell, and when the hero's school is below
/// the book's gate. Reading a book that could have waited is *not* refused: it
/// consumes the turn and the book for a spell the hero may not need yet,
/// because a page spent early is a player's mistake and not the rules' to undo.
/// See [DrinkAction], which this is the sibling of.
final class ReadAction extends GameAction {
  const ReadAction(this.itemId);

  final String itemId;
}

/// Cast the known spell with this id.
///
/// Refused when the hero does not know it, when the pool is short of its cost,
/// and — for the kinds that need something to land on — when no enemy is in
/// sight. Casting Mend at full health is *not* refused: it spends the turn and
/// the mana and heals nothing, for [DrinkAction]'s reason.
///
/// **Nothing here says what to cast it at.** A targeted spell finds the nearest
/// enemy the hero can see, breaking ties by row and then column; see
/// `nearestVisibleEnemy` for why the rule is a rule and not a tap.
final class CastSpellAction extends GameAction {
  const CastSpellAction(this.spellId);

  final String spellId;
}

/// Work whatever ore vein or herb patch the hero is standing on.
///
/// **One action for both kinds, because the tile decides.** The node underfoot
/// is what says whether this is mining or gathering, so two actions would be two
/// names for one question the state already answers — and a caller that chose
/// the wrong one would be asking the rules to do something the floor does not
/// offer. The control says 'Mine' or 'Gather' by the kind it is standing on;
/// that is a label, not a second rule.
///
/// Refused when there is nothing underfoot to work, following [PickUpAction]
/// rather than [DescendAction]: the interface only offers this on a node, so a
/// stray tap must cost nothing.
///
/// **Draws no random number whatsoever.** The yield is a flat one and the node
/// is simply gone, so the crawl's two streams are where they were — see
/// `gatherSalt` for why that is the one thing this path is not allowed to do.
final class GatherAction extends GameAction {
  const GatherAction();
}

/// Put the carried item with this id down on the hero's tile.
///
/// Refused when nothing carried answers to the id.
final class DropAction extends GameAction {
  const DropAction(this.itemId);

  final String itemId;
}
