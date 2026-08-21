import 'package:residuum_core/core.dart';

import 'save_json.dart';

/// A tile, as the two numbers that name it.
List<int> encodePosition(Position position) => [position.x, position.y];

/// A tile, or nothing where a floor has no such stairway.
Object? encodeNullablePosition(Position? position) =>
    position == null ? null : encodePosition(position);

/// Every tile in [positions], in a stable order.
///
/// Sorted rather than written in iteration order, so that one state always
/// encodes to one document — which is what makes a golden fixture pinnable.
/// Sorting is safe because no rule reads these sets in order: they are asked
/// whether they hold a tile, never what their first tile is.
List<Object?> encodePositions(Set<Position> positions) {
  final ordered = positions.toList()..sort(byRowThenColumn);
  return [for (final position in ordered) encodePosition(position)];
}

/// The tile at [key], or null when the document says there is none.
Position? decodeNullablePosition(Map<String, Object?> from, String key) {
  if (!from.containsKey(key)) {
    throw SaveMalformed('the save file is missing "$key"');
  }
  final value = from[key];
  if (value == null) return null;
  return _asPosition(value, key);
}

/// Every tile in the list at [key].
Set<Position> decodePositions(Map<String, Object?> from, String key) => {
  for (final written in listAt(from, key)) _asPosition(written, key),
};

/// One actor, whole: every field it has, including the turn it is holding.
///
/// A run snapshot serializes its actors completely rather than rebuilding them
/// from content, and the reason is [FloorMemory]'s: a suspended crawl is frozen
/// mid-fight, so a monster that came back on full hit points at its spawn tile
/// would be a different monster from the one the player walked away from.
Map<String, Object?> encodeActor(Actor actor) => {
  'id': actor.id,
  'name': actor.name,
  'glyph': actor.glyph,
  'x': actor.position.x,
  'y': actor.position.y,
  'hp': actor.hp,
  'maxHp': actor.maxHp,
  'attackMin': actor.attackMin,
  'attackMax': actor.attackMax,
  'speed': actor.speed,
  'energy': actor.energy,
  'dropChance': actor.dropChance,
  'pierce': actor.pierce,
};

/// Every actor in [actors], in the order they act in.
///
/// The order is data. The monster phase walks this list and every monster that
/// acts draws from the crawl's stream, so two documents differing only in the
/// order of this list describe two different next turns.
List<Object?> encodeActors(List<Actor> actors) => [
  for (final actor in actors) encodeActor(actor),
];

/// One actor, from the object [from].
Actor decodeActor(Object? from) {
  if (from is! Map<String, Object?>) {
    throw SaveMalformed('an actor in the save file is not an object');
  }
  return Actor(
    id: stringAt(from, 'id'),
    name: stringAt(from, 'name'),
    glyph: stringAt(from, 'glyph'),
    position: Position(intAt(from, 'x'), intAt(from, 'y')),
    hp: intAt(from, 'hp'),
    maxHp: intAt(from, 'maxHp'),
    attackMin: intAt(from, 'attackMin'),
    attackMax: intAt(from, 'attackMax'),
    speed: intAt(from, 'speed'),
    energy: intAt(from, 'energy'),
    dropChance: intAt(from, 'dropChance'),
    pierce: intAt(from, 'pierce'),
  );
}

/// Every actor in the list at [key], in the order written.
List<Actor> decodeActors(Map<String, Object?> from, String key) => [
  for (final written in listAt(from, key)) decodeActor(written),
];

/// Rows first, then columns, so a sorted document reads the way a floor does.
int byRowThenColumn(Position first, Position second) => first.y == second.y
    ? first.x.compareTo(second.x)
    : first.y.compareTo(second.y);

Position _asPosition(Object? written, String key) {
  if (written is! List || written.length != 2) {
    throw SaveMalformed('"$key" must hold tiles written as two numbers');
  }
  final x = written[0];
  final y = written[1];
  if (x is! int || y is! int) {
    throw SaveMalformed('"$key" must hold tiles written as two numbers');
  }
  return Position(x, y);
}
