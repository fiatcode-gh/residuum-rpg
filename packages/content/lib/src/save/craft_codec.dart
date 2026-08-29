import 'package:residuum_core/core.dart';

import 'save_json.dart';

/// What the hero is carrying of each material, by name.
///
/// **Written in enum order and never in map order**, which is [encodeSkills]'
/// rule and exists for the same reason: one hero has to encode to one document,
/// or a golden fixture is a coincidence rather than a pin. A counter at zero has
/// no entry at all, because [withMaterial] drops it — so the block's length is
/// what the hero actually has.
///
/// By name rather than by index, so appending a material to the enum never
/// changes what an already-written document meant.
Map<String, Object?> encodeMaterials(Map<MaterialId, int> materials) => {
  for (final id in MaterialId.values)
    if (materials[id] case final int count) id.name: count,
};

/// What the hero is carrying of each material, from the object at [key].
///
/// A name this build does not have is a refusal with a sentence in it rather
/// than a counter quietly dropped: a hero who came home a material short would
/// have no way to find out which.
Map<MaterialId, int> decodeMaterials(Map<String, Object?> from, String key) {
  final written = objectAt(from, key);
  return {
    for (final entry in written.entries)
      _materialNamed(entry.key, key): _countOf(entry.key, entry.value),
  };
}

/// What is still there to be worked on one floor, in a stable order.
///
/// Sorted by [byRowThenColumn], which is what every other tile-keyed block in
/// this codec is sorted by — the litter, the visible set, the explored set.
List<Object?> encodeNodes(Map<Position, GatherKind> nodes) {
  final tiles = nodes.keys.toList()..sort(byRowThenColumn);
  return [
    for (final tile in tiles)
      {'x': tile.x, 'y': tile.y, 'kind': nodes[tile]!.name},
  ];
}

/// What is still there to be worked, from the list at [key].
Map<Position, GatherKind> decodeNodes(Map<String, Object?> from, String key) {
  final nodes = <Position, GatherKind>{};
  for (final written in listAt(from, key)) {
    if (written is! Map<String, Object?>) {
      throw SaveMalformed('a node in the save file is not an object');
    }
    nodes[Position(intAt(written, 'x'), intAt(written, 'y'))] = _kindNamed(
      stringAt(written, 'kind'),
    );
  }
  return nodes;
}

MaterialId _materialNamed(String name, String key) {
  for (final id in MaterialId.values) {
    if (id.name == name) return id;
  }
  throw SaveMalformed(
    '"$key" names a material this build does not have: "$name"',
  );
}

GatherKind _kindNamed(String name) {
  for (final kind in GatherKind.values) {
    if (kind.name == name) return kind;
  }
  throw SaveMalformed(
    'the save file names a kind of node this build does not have: "$name"',
  );
}

int _countOf(String name, Object? written) {
  if (written is! int) {
    throw SaveMalformed('the material "$name" is not counted in whole numbers');
  }
  if (written <= 0) {
    throw SaveMalformed(
      'the save file carries $written of "$name", and a counter the hero has '
      'none of is written by leaving it out',
    );
  }
  return written;
}
