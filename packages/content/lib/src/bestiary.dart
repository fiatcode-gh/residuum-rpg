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
    required this.dropChance,
    this.pierce = 0,
    this.reach = 1,
    this.resists = const {},
    this.vulnerableTo = const {},
  });

  final String id;

  /// How the message log names it, article included: `the dire wolf`.
  final String name;

  final String glyph;
  final int hp;
  final int attackMin;
  final int attackMax;
  final int speed;

  /// The chance in a hundred that killing one of these yields an item.
  ///
  /// It rises with how hard the creature is to kill, so the reward tracks the
  /// risk: a rat is a nuisance and a wight is an event.
  final int dropChance;

  /// How much of the hero's armour this creature's blows ignore.
  ///
  /// Zero on everything shallow: the first two floors are where armour is
  /// supposed to feel like an answer. It climbs deeper down so that the answer
  /// stops being the only one — a wight that four points of mail turns into a
  /// nuisance is a wight nobody has to think about, and a dungeon whose whole
  /// difficulty curve can be bought off in the armoury is not a dungeon.
  final int pierce;

  /// How many tiles away this creature strikes: one is orthogonal adjacency
  /// and nothing else, more than one reaches across the room along a line of
  /// sight. Defaults to one, which is the behavior every creature shipped
  /// with — a validation test pins that by id, and the save codec omits the
  /// field whenever it holds the default so older documents read unchanged.
  final int reach;

  /// The damage types this creature shrugs off: a bolt of one is halved.
  ///
  /// **A content field and nothing more.** It changes no melee number, so a
  /// hero who never casts fights exactly the dungeon that shipped before magic
  /// did — which is what makes the bands able to say so.
  ///
  /// Disjoint from [vulnerableTo], which a validation test holds: a creature
  /// that both resisted and burned at one type would be a row nobody could
  /// read.
  final Set<DamageType> resists;

  /// The damage types this creature takes double from.
  final Set<DamageType> vulnerableTo;

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
    dropChance: dropChance,
    pierce: pierce,
    reach: reach,
    resists: resists,
    vulnerableTo: vulnerableTo,
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
  dropChance: 35,
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
  dropChance: 40,
);

const CreatureSpec ghoul = CreatureSpec(
  id: 'ghoul',
  name: 'the ghoul',
  glyph: 'g',
  hp: 10,
  attackMin: 2,
  attackMax: 4,
  speed: 10,
  dropChance: 50,
  pierce: 1,
  vulnerableTo: {DamageType.fire},
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
  dropChance: 60,
  pierce: 6,
  resists: {DamageType.fire},
  vulnerableTo: {DamageType.frost},
);

const CreatureSpec wight = CreatureSpec(
  id: 'wight',
  name: 'the wight',
  glyph: 'W',
  hp: 20,
  attackMin: 4,
  attackMax: 6,
  speed: 10,
  dropChance: 70,
  pierce: 6,
  vulnerableTo: {DamageType.fire},
);

/// The first creature that does not have to walk up to you.
///
/// It stands where it can see you and spits from up to three tiles away —
/// Chebyshev, along a line of sight — and walks only when nothing is in
/// reach or in view. A glass cannon: four hit points — one clean exchange
/// for a kit sword — a slow crawl, and a blow that mail mostly turns aside.
/// Its teeth are the ambush: the turn it steps into a shooting line is the
/// turn it shoots, and the chase is no longer a matter of outrunning claws.
/// (The ruling's history is in the ledger: D72/D74 wrote it modest at seven
/// hit points; D78 took the seven to four after the trail showed the shots,
/// not the shooter, carry the danger.)

const CreatureSpec spitter = CreatureSpec(
  id: 'spitter',
  name: 'the spitter',
  glyph: 'p',
  hp: 4,
  attackMin: 2,
  attackMax: 3,
  speed: 5,
  dropChance: 40,
  reach: 3,
);

/// Every creature in the game, in the order they are first met.
const List<CreatureSpec> bestiary = [
  giantRat,
  direWolf,
  spitter,
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
