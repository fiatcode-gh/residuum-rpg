/// One cell of dungeon terrain.
enum Tile {
  wall(walkable: false, transparent: false),
  floor(walkable: true, transparent: true),
  stairsDown(walkable: true, transparent: true);

  const Tile({required this.walkable, required this.transparent});

  /// Whether an actor may occupy this tile.
  final bool walkable;

  /// Whether sight passes through this tile.
  final bool transparent;
}
