import 'package:equatable/equatable.dart';

/// The name one place on the world map answers to.
///
/// A value object rather than a bare string, and it validates rather than
/// asserts. Ids arrive from save documents as well as from content, and a
/// document is the one source that can be wrong in the field — an assertion
/// would be compiled out of the build a player runs, so an empty id read off
/// disk would flow on into a map lookup and fail somewhere with nothing to say.
/// Throwing here means the codec's own refusal is the thing the player sees.
///
/// The cost is that a [NodeId] cannot be `const`, and so neither can anything
/// holding one. That is the right way round: the world map is assembled once at
/// startup, while a wrong id is forever.
class NodeId extends Equatable {
  /// Throws [ArgumentError] when [value] is empty or is only spaces.
  NodeId(this.value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'a place needs an id');
    }
  }

  /// The text this place is filed under, and what a save document writes.
  ///
  /// Text rather than a position in a list: a world that grew a fourth place
  /// would renumber the three already written down, and every document on the
  /// install would quietly name somewhere else.
  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'NodeId($value)';
}

/// What kind of place a node is, and so what standing on it offers.
///
/// Two kinds and no more, because the interface forks on exactly this: a town
/// has doors and a dungeon has a way down. A third kind would be a third branch
/// on every screen that draws the map, and there is no third thing to stand on.
enum NodeKind {
  /// A place with a merchant, an inn, a bank, a gear rack and a tavern.
  town,

  /// A place with a crawl under it.
  dungeon,
}

/// One place on the world map: what it is called, what kind it is, and what the
/// screen calls it.
class WorldNode extends Equatable {
  WorldNode({required this.id, required this.kind, required this.name});

  final NodeId id;
  final NodeKind kind;

  /// What the screen calls this place, in words rather than an id.
  final String name;

  @override
  List<Object?> get props => [id, kind, name];

  @override
  String toString() => 'WorldNode($name, ${kind.name})';
}
