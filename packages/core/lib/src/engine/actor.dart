import 'position.dart';

/// One living thing on a dungeon floor: the hero, or a monster.
class Actor {
  const Actor({
    required this.id,
    required this.glyph,
    required this.position,
    required this.hp,
    required this.maxHp,
    required this.attackMin,
    required this.attackMax,
  });

  /// Unique within a crawl: `hero`, or `ghoul-1`.
  final String id;

  /// The single character this actor draws as.
  final String glyph;

  final Position position;
  final int hp;
  final int maxHp;

  /// The lowest damage a hit from this actor deals.
  final int attackMin;

  /// The highest damage a hit from this actor deals.
  final int attackMax;

  /// Whether this actor still has hit points.
  bool get isAlive => hp > 0;

  /// A copy with a new [position] or [hp]; everything else is carried over.
  Actor copyWith({Position? position, int? hp}) => Actor(
    id: id,
    glyph: glyph,
    position: position ?? this.position,
    hp: hp ?? this.hp,
    maxHp: maxHp,
    attackMin: attackMin,
    attackMax: attackMax,
  );

  @override
  String toString() => 'Actor($id at $position, $hp/$maxHp hp)';
}
