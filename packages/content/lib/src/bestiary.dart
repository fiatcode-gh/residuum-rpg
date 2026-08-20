import 'package:residuum_core/core.dart';

/// What one kind of creature is, before it stands anywhere.
///
/// A spec is the template; an [Actor] is one of them on a floor. Speeds differ
/// on purpose — a dire wolf that outruns the hero and a skeleton that plods are
/// how the speed clock becomes visible from the other side of the screen.
class CreatureSpec {
  const CreatureSpec({
    required this.id,
    required this.name,
    required this.glyph,
    required this.hp,
    required this.attackMin,
    required this.attackMax,
    required this.speed,
  });

  final String id;

  /// How the message log names it, article included: `the dire wolf`.
  final String name;

  final String glyph;
  final int hp;
  final int attackMin;
  final int attackMax;
  final int speed;

  /// One of these creatures, alive and ready to act, standing at [at].
  Actor spawn({required String id, required Position at}) => Actor(
    id: id,
    name: name,
    glyph: glyph,
    position: at,
    hp: hp,
    maxHp: hp,
    attackMin: attackMin,
    attackMax: attackMax,
    speed: speed,
    energy: actThreshold,
  );
}

/// Quick and weak; the first thing that bites you.
const CreatureSpec giantRat = CreatureSpec(
  id: 'rat',
  name: 'the giant rat',
  glyph: 'r',
  hp: 4,
  attackMin: 1,
  attackMax: 2,
  speed: 10,
);

/// Twice the hero's speed: it closes corridors before you can back out of them.
const CreatureSpec direWolf = CreatureSpec(
  id: 'wolf',
  name: 'the dire wolf',
  glyph: 'w',
  hp: 8,
  attackMin: 2,
  attackMax: 3,
  speed: 20,
);

const CreatureSpec ghoul = CreatureSpec(
  id: 'ghoul',
  name: 'the ghoul',
  glyph: 'g',
  hp: 10,
  attackMin: 2,
  attackMax: 4,
  speed: 10,
);

/// Half the hero's speed, but it hits hard and takes a long time to fell.
const CreatureSpec skeleton = CreatureSpec(
  id: 'skeleton',
  name: 'the skeleton',
  glyph: 's',
  hp: 16,
  attackMin: 3,
  attackMax: 5,
  speed: 5,
);

const CreatureSpec wight = CreatureSpec(
  id: 'wight',
  name: 'the wight',
  glyph: 'W',
  hp: 20,
  attackMin: 4,
  attackMax: 6,
  speed: 10,
);

/// Every creature in the game, in the order they are first met.
const List<CreatureSpec> bestiary = [
  giantRat,
  direWolf,
  ghoul,
  skeleton,
  wight,
];

/// The creature with this [id].
///
/// Throws [ArgumentError] when nothing answers to it, so a typo in a spawn
/// table fails the content validation tests rather than the game.
CreatureSpec creatureById(String id) {
  for (final creature in bestiary) {
    if (creature.id == id) return creature;
  }
  throw ArgumentError.value(id, 'id', 'no such creature');
}
