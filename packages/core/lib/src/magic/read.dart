import '../loot/item.dart';
import '../loot/loadout.dart';
import 'spell.dart';

/// Why the rules will not read the carried book [itemId], or null when they
/// will.
///
/// A plain sentence rather than an event or a refusal object, for
/// [wearRefusal]'s reason and by its example: the dungeon wraps it in an
/// `ActionRefused` and the town wraps it in a `TownRefusal`, so the rule and the
/// words it refuses in have one home while each context keeps its own answer
/// type. A book that reads one way in a corridor and another in a shop would be
/// worse than a book that was wrong in both.
///
/// **A book the hero could have saved for later is not refused.** Reading the
/// only Book of Mend on depth one, with nothing hurt and a camp two floors up,
/// spends the page for a spell that could have waited — and that is the
/// player's mistake to make, exactly as drinking a potion at full health is.
/// The rules refuse what they cannot do, never what they think unwise.
String? readRefusal(
  Loadout loadout,
  List<Item> inventory,
  Set<String> knownSpells,
  Map<String, Spell> spells,
  String itemId,
) {
  final item = _find(inventory, itemId);
  if (item == null) return 'you are not carrying that';
  final teaches = item.base.teaches;
  if (teaches == null) return '${item.base.name} is not something to read';
  final spell = spells[teaches];
  if (spell == null) {
    return '${item.base.name} is written in a hand you cannot read';
  }
  if (knownSpells.contains(teaches)) return 'you already know ${spell.name}';
  if (loadout.levelOf(spell.school) < spell.requiredLevel) {
    return 'needs ${spell.school.schoolWord} ${spell.requiredLevel}';
  }
  return null;
}

Item? _find(List<Item> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) return item;
  }
  return null;
}
