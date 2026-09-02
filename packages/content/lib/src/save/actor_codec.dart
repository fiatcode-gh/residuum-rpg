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
///
/// [reach] is the one exception, and it is deliberate: the field defaults to
/// one, and one is what every document written before the field existed means,
/// so it is written **only when it is not one** and read as one where absent.
/// An unconditional encode would rewrite every golden document in the game for
/// a number nobody's creature carries.
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
  'resists': encodeDamageTypes(actor.resists),
  'vulnerableTo': encodeDamageTypes(actor.vulnerableTo),
  if (actor.reach != 1) 'reach': actor.reach,
};

/// Every damage type in [types], as sorted names.
///
/// Sorted for [encodePositions]'s reason: one state has to encode to one
/// document or a golden fixture cannot be pinned, and nothing reads a
/// resistance set in order — it is asked whether it holds a type, never what
/// its first type is. Written by name rather than by index so that appending a
/// type to the enum never rewrites what an old document meant.
List<Object?> encodeDamageTypes(Set<DamageType> types) =>
    [for (final type in types) type.name]..sort();

/// Every damage type in the list at [key].
Set<DamageType> decodeDamageTypes(Map<String, Object?> from, String key) => {
  for (final written in listAt(from, key)) _damageTypeNamed(written, key),
};

DamageType _damageTypeNamed(Object? written, String key) {
  for (final type in DamageType.values) {
    if (type.name == written) return type;
  }
  throw SaveMalformed('"$key" names a kind of damage this build does not deal');
}

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
    reach: from.containsKey('reach') ? intAt(from, 'reach') : 1,
    resists: decodeDamageTypes(from, 'resists'),
    vulnerableTo: decodeDamageTypes(from, 'vulnerableTo'),
  );
}

/// Every actor in the list at [key], in the order written.
List<Actor> decodeActors(Map<String, Object?> from, String key) => [
  for (final written in listAt(from, key)) decodeActor(written),
];

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
