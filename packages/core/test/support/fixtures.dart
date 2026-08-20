import 'package:residuum_core/core.dart';

Actor hero(
  Position at, {
  int hp = 20,
  int attack = 4,
  int? attackMax,
  int speed = 10,
}) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: hp,
  maxHp: 20,
  attackMin: attack,
  attackMax: attackMax ?? attack,
  speed: speed,
  energy: actThreshold,
);

Actor ghoul(
  String id,
  Position at, {
  int hp = 10,
  int attack = 3,
  int speed = 10,
}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
  speed: speed,
  energy: actThreshold,
);

Floor noFloorBelow(int depth) =>
    throw StateError('this crawl was not meant to descend');

GameState crawl({
  required String ascii,
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
  int heroAttack = 4,
  int? heroAttackMax,
  int heroSpeed = 10,
  int seed = 1,
  int depth = 1,
  Position? stairsDown,
  FloorBuilder buildFloor = noFloorBelow,
}) {
  final map = FloorMap.parse(ascii);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: hero(
      heroAt,
      hp: heroHp,
      attack: heroAttack,
      attackMax: heroAttackMax,
      speed: heroSpeed,
    ),
    monsters: monsters,
    rng: Rng(seed),
    visible: visible,
    explored: {...visible},
    buildFloor: buildFloor,
    depth: depth,
    stairsDown: stairsDown,
  );
}
