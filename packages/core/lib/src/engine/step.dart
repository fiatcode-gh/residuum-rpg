import '../dungeon/floor_map.dart';
import '../dungeon/fov.dart';
import 'action.dart';
import 'actor.dart';
import 'event.dart';
import 'game_state.dart';
import 'position.dart';

/// Advances the crawl by one hero [action].
///
/// A blocked move still consumes the turn. Bumping a wall costs exactly as
/// much time as bumping a ghoul, which is the classic roguelike rule and a
/// deliberate balance decision: if wall-bumps were free the player could probe
/// the dark edges of a room, learn its shape and re-plan without the dungeon
/// ever acting, which turns fog of war from a risk into a free scouting tool.
(GameState, List<GameEvent>) step(GameState state, GameAction action) {
  if (state.isGameOver) return (state, const []);

  final events = <GameEvent>[];
  final monsters = [...state.monsters];
  var hero = state.hero;

  switch (action) {
    case MoveAction(:final direction):
      final target = hero.position.step(direction);
      final defending = monsters.indexWhere(
        (monster) => monster.position == target,
      );
      if (defending >= 0) {
        final damage = state.rng.rollRange(hero.attackMin, hero.attackMax);
        final defender = monsters[defending];
        events.add(
          AttackHit(attackerId: hero.id, targetId: defender.id, damage: damage),
        );
        final wounded = defender.copyWith(hp: defender.hp - damage);
        if (wounded.isAlive) {
          monsters[defending] = wounded;
        } else {
          monsters.removeAt(defending);
          events.add(ActorDied(actorId: defender.id));
        }
      } else if (state.map.isWalkable(target)) {
        events.add(
          ActorMoved(actorId: hero.id, from: hero.position, to: target),
        );
        hero = hero.copyWith(position: target);
      } else {
        events.add(MoveBlocked(actorId: hero.id, at: target));
      }
  }

  for (var index = 0; index < monsters.length; index++) {
    final monster = monsters[index];
    if (monster.position.isOrthogonallyAdjacentTo(hero.position)) {
      final damage = state.rng.rollRange(monster.attackMin, monster.attackMax);
      events.add(
        AttackHit(attackerId: monster.id, targetId: hero.id, damage: damage),
      );
      hero = hero.copyWith(hp: hero.hp - damage);
      continue;
    }
    final target = _chaseStep(state.map, monster, hero, monsters);
    if (target == null) continue;
    events.add(
      ActorMoved(actorId: monster.id, from: monster.position, to: target),
    );
    monsters[index] = monster.copyWith(position: target);
  }

  if (!hero.isAlive) {
    events.add(ActorDied(actorId: hero.id));
    events.add(const GameOver());
  }

  final visible = computeFov(state.map, hero.position, fovRadius);
  return (
    state.copyWith(
      hero: hero,
      monsters: monsters,
      visible: visible,
      explored: {...state.explored, ...visible},
      isGameOver: !hero.isAlive,
    ),
    events,
  );
}

Position? _chaseStep(
  FloorMap map,
  Actor monster,
  Actor hero,
  List<Actor> monsters,
) {
  final deltaX = hero.position.x - monster.position.x;
  final deltaY = hero.position.y - monster.position.y;
  final horizontal = deltaX == 0
      ? null
      : (deltaX > 0 ? Direction.east : Direction.west);
  final vertical = deltaY == 0
      ? null
      : (deltaY > 0 ? Direction.south : Direction.north);
  final candidates = deltaX.abs() >= deltaY.abs()
      ? [horizontal, vertical]
      : [vertical, horizontal];
  final occupied = <Position>{
    hero.position,
    for (final other in monsters)
      if (other.id != monster.id) other.position,
  };
  for (final direction in candidates) {
    if (direction == null) continue;
    final target = monster.position.step(direction);
    if (!map.isWalkable(target) || occupied.contains(target)) continue;
    return target;
  }
  return null;
}
