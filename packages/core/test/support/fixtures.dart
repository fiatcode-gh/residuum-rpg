import 'package:residuum_core/core.dart';

Actor hero(Position at, {int hp = 20, int attack = 4, int? attackMax}) => Actor(
  id: 'hero',
  glyph: '@',
  position: at,
  hp: hp,
  maxHp: 20,
  attackMin: attack,
  attackMax: attackMax ?? attack,
);

Actor ghoul(String id, Position at, {int hp = 10, int attack = 3}) => Actor(
  id: id,
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
);

GameState crawl({
  required String ascii,
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
  int heroAttack = 4,
  int? heroAttackMax,
  int seed = 1,
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
    ),
    monsters: monsters,
    rng: Rng(seed),
    visible: visible,
    explored: {...visible},
  );
}
