import 'position.dart';

/// One living thing on a dungeon floor: the hero, or a monster.
class Actor {
  const Actor({
    required this.id,
    required this.name,
    required this.glyph,
    required this.position,
    required this.hp,
    required this.maxHp,
    required this.attackMin,
    required this.attackMax,
    required this.speed,
    required this.energy,
    this.dropChance = 0,
  });

  /// Unique within a crawl: `hero`, or `ghoul-1`.
  final String id;

  /// What the message log calls this actor: `you`, or `the dire wolf`.
  ///
  /// Written the way it reads mid-sentence, article included, so a message is
  /// a join and never a lookup table of grammar.
  final String name;

  /// The single character this actor draws as.
  final String glyph;

  final Position position;
  final int hp;

  /// The hit point ceiling before any gear. For the hero, gear adds to this
  /// rather than replacing it — see `heroMaxHp`.
  final int maxHp;

  /// The lowest damage a hit from this actor deals, before any gear.
  ///
  /// For the hero this is its bare fists: a weapon adds on top, so an unarmed
  /// hero still punches. See `heroAttack`.
  final int attackMin;

  /// The highest damage a hit from this actor deals, before any gear.
  final int attackMax;

  /// Energy gained per tick of the speed clock. The baseline is 10. For the
  /// hero, gear adds to this — see `heroSpeed`.
  final int speed;

  /// Energy accumulated so far: an actor acts at `actThreshold` and spends
  /// `actCost` doing so.
  final int energy;

  /// The chance in a hundred that killing this actor yields an item.
  ///
  /// Zero for the hero, which is why it defaults to nothing: the hero's own
  /// death spills nothing, and the death penalty that will take its gear is a
  /// later milestone's rule.
  final int dropChance;

  /// Whether this actor still has hit points.
  bool get isAlive => hp > 0;

  /// A copy with a new [position], [hp] or [energy]; the rest is carried over.
  Actor copyWith({Position? position, int? hp, int? energy}) => Actor(
    id: id,
    name: name,
    glyph: glyph,
    position: position ?? this.position,
    hp: hp ?? this.hp,
    maxHp: maxHp,
    attackMin: attackMin,
    attackMax: attackMax,
    speed: speed,
    energy: energy ?? this.energy,
    dropChance: dropChance,
  );

  @override
  String toString() => 'Actor($id at $position, $hp/$maxHp hp)';
}
