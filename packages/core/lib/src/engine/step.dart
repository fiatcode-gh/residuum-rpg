import '../dungeon/flow_field.dart';
import '../dungeon/fov.dart';
import 'action.dart';
import 'actor.dart';
import 'energy.dart';
import 'event.dart';
import 'game_state.dart';
import 'position.dart';

/// Advances the crawl by one hero [action].
///
/// The hero acts first and spends [actCost] doing so; the clock then runs
/// forward, letting monsters act as they come due, and stops the moment the
/// hero is next again. A speed-10 hero among speed-10 monsters gets exactly one
/// monster turn per hero turn, which is the strict alternation Milestone 1 was
/// built on.
///
/// A blocked move still consumes the turn. Bumping a wall costs exactly as
/// much time as bumping a ghoul, which is the classic roguelike rule and a
/// deliberate balance decision: if wall-bumps were free the player could probe
/// the dark edges of a room, learn its shape and re-plan without the dungeon
/// ever acting, which turns fog of war from a risk into a free scouting tool.
/// [DescendAction] away from the stairs follows the same rule and reports
/// [MoveBlocked], so the log says why nothing happened rather than swallowing
/// the tap.
///
/// Descending is the one action that does not end in a monster phase: the hero
/// arrives on a still floor with the clock restarted. Carrying spent energy
/// down the stairs would hand every monster on the new floor a free move before
/// the player had seen a single tile of it.
(GameState, List<GameEvent>) step(GameState state, GameAction action) {
  if (state.isGameOver) return (state, const []);

  final events = <GameEvent>[];
  final seenBefore = _visibleMonsterIds(state);
  final monsters = [...state.monsters];
  var hero = state.hero.copyWith(energy: state.hero.energy - actCost);

  switch (action) {
    case MoveAction(:final direction):
      hero = _moveHero(state, hero, monsters, direction, events);
    case DescendAction():
      if (state.stairsDown == hero.position) {
        return _arriveBelow(state, hero, events);
      }
      events.add(MoveBlocked(actorId: hero.id, at: hero.position));
  }

  hero = _monsterPhase(state, hero, monsters, events);

  if (!hero.isAlive) {
    events.add(ActorDied(actorId: hero.id));
    events.add(const GameOver());
  }

  final visible = computeFov(state.map, hero.position, fovRadius);
  events.addAll(_noticings(monsters, visible, seenBefore));
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

Actor _moveHero(
  GameState state,
  Actor hero,
  List<Actor> monsters,
  Direction direction,
  List<GameEvent> events,
) {
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
    return hero;
  }
  if (state.map.isWalkable(target)) {
    events.add(ActorMoved(actorId: hero.id, from: hero.position, to: target));
    return hero.copyWith(position: target);
  }
  events.add(MoveBlocked(actorId: hero.id, at: target));
  return hero;
}

Actor _monsterPhase(
  GameState state,
  Actor hero,
  List<Actor> monsters,
  List<GameEvent> events,
) {
  final owed = scheduleMonsterTurns(
    heroSpeed: hero.speed,
    heroEnergy: hero.energy,
    monsterSpeeds: [for (final monster in monsters) monster.speed],
    monsterEnergies: [for (final monster in monsters) monster.energy],
  );
  final field = computeFlowField(state.map, hero.position);
  var wounded = hero;
  for (final index in owed.monsterTurns) {
    if (!wounded.isAlive) break;
    final monster = monsters[index];
    if (monster.position.isOrthogonallyAdjacentTo(wounded.position)) {
      final damage = state.rng.rollRange(monster.attackMin, monster.attackMax);
      events.add(
        AttackHit(attackerId: monster.id, targetId: wounded.id, damage: damage),
      );
      wounded = wounded.copyWith(hp: wounded.hp - damage);
      continue;
    }
    final target = flowFieldStep(
      state.map,
      field,
      monster.position,
      _occupiedTiles(wounded, monsters, monster.id),
    );
    if (target == null) continue;
    events.add(
      ActorMoved(actorId: monster.id, from: monster.position, to: target),
    );
    monsters[index] = monster.copyWith(position: target);
  }
  for (var index = 0; index < monsters.length; index++) {
    monsters[index] = monsters[index].copyWith(
      energy: owed.monsterEnergies[index],
    );
  }
  return wounded.copyWith(energy: owed.heroEnergy);
}

Set<Position> _occupiedTiles(Actor hero, List<Actor> monsters, String moving) =>
    {
      hero.position,
      for (final other in monsters)
        if (other.id != moving) other.position,
    };

(GameState, List<GameEvent>) _arriveBelow(
  GameState state,
  Actor hero,
  List<GameEvent> events,
) {
  final depth = state.depth + 1;
  final floor = state.buildFloor(depth);
  final arrived = hero.copyWith(
    position: floor.heroSpawn,
    energy: actThreshold,
  );
  final visible = computeFov(floor.map, floor.heroSpawn, fovRadius);
  events.add(Descended(newDepth: depth));
  return (
    state.copyWith(
      map: floor.map,
      hero: arrived,
      monsters: [
        for (final monster in floor.monsters)
          monster.copyWith(energy: actThreshold),
      ],
      visible: visible,
      explored: {...visible},
      depth: depth,
      stairsDown: floor.stairsDown,
      clearStairsDown: floor.stairsDown == null,
    ),
    events,
  );
}

Set<String> _visibleMonsterIds(GameState state) => {
  for (final monster in state.monsters)
    if (state.visible.contains(monster.position)) monster.id,
};

Iterable<GameEvent> _noticings(
  List<Actor> monsters,
  Set<Position> visible,
  Set<String> seenBefore,
) => [
  for (final monster in monsters)
    if (visible.contains(monster.position) && !seenBefore.contains(monster.id))
      ActorNoticed(actorId: monster.id, at: monster.position),
];
