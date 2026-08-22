import '../dungeon/floor.dart';
import '../dungeon/floor_memory.dart';
import '../dungeon/flow_field.dart';
import '../dungeon/fov.dart';
import '../loot/wear.dart';
import '../loot/drop.dart';
import '../loot/item.dart';
import '../loot/loadout.dart';
import '../skills/skill.dart';
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
/// A **refused** action is the opposite case and costs nothing: it returns the
/// state untouched with a single event saying why. The difference is whether
/// the hero did something — a wall-bump is a swing at the world that missed,
/// while equipping an item the hero is not carrying never happened at all, and
/// charging a monster turn for a control the interface should not have offered
/// is how a player loses a run to a mis-tap.
///
/// Taking the stairs, either way, is the one action that does not end in a
/// monster phase: the hero arrives on a still floor with the clock restarted.
/// Carrying spent energy through the stairwell would hand every monster on the
/// far side a free move before the player had seen a single tile of it.
///
/// A floor the hero has already walked is **restored, never rebuilt**. Only a
/// depth nobody has been to runs the generator, so a monster left on three hit
/// points is still on three hit points and an item left on the ground is still
/// on the ground. See [FloorMemory] for why the monsters freeze while the hero
/// is elsewhere.
(GameState, List<GameEvent>) step(GameState state, GameAction action) {
  if (state.isGameOver) return (state, const []);

  final refusal = _refuse(state, action);
  if (refusal != null) return (state, [refusal]);

  if (_flees(state, action)) return (state, const [Fled()]);

  final events = <GameEvent>[];
  final seenBefore = _visibleMonsterIds(state);
  final monsters = [...state.monsters];
  var hero = state.hero.copyWith(energy: state.hero.energy - actCost);
  var loadout = state.loadout;
  var groundItems = state.groundItems;
  var inventory = state.inventory;
  var nextDropNumber = state.nextDropNumber;

  switch (action) {
    case MoveAction(:final direction):
      final swung = _moveHero(
        state,
        hero,
        loadout,
        monsters,
        direction,
        events,
      );
      hero = swung.hero;
      loadout = loadout.withSkills(swung.skills);
      if (swung.spoils != null) {
        groundItems = _withItem(
          groundItems,
          swung.spoils!.$1,
          swung.spoils!.$2,
        );
        nextDropNumber++;
      }
    case DescendAction():
      if (state.stairsDown == hero.position) {
        return _arriveBelow(state, hero, events);
      }
      events.add(MoveBlocked(actorId: hero.id, at: hero.position));
    case AscendAction():
      return _arriveAbove(state, hero, events);
    case PickUpAction():
      final here = groundItems[hero.position]!;
      final taken = here.last;
      groundItems = _withoutLastItem(groundItems, hero.position);
      inventory = [...inventory, taken];
      events.add(ItemPickedUp(item: taken));
    case EquipAction(:final itemId):
      final worn = wear(loadout.equipment, inventory, itemId);
      _announce(worn, events);
      loadout = loadout.withEquipment(worn.equipment);
      inventory = worn.inventory;
    case UnequipAction(:final slot):
      final worn = takeOff(loadout.equipment, inventory, slot);
      _announce(worn, events);
      loadout = loadout.withEquipment(worn.equipment);
      inventory = worn.inventory;
      hero = clampedToMaxHp(hero, loadout);
    case DrinkAction(:final itemId):
      final potion = inventory.firstWhere((item) => item.id == itemId);
      final missing = heroMaxHp(hero, loadout) - hero.hp;
      final healed = potion.base.heal < missing ? potion.base.heal : missing;
      hero = hero.copyWith(hp: hero.hp + (healed > 0 ? healed : 0));
      inventory = [
        for (final item in inventory)
          if (item.id != itemId) item,
      ];
      events.add(PotionDrunk(item: potion, healed: healed > 0 ? healed : 0));
    case DropAction(:final itemId):
      final put = inventory.firstWhere((item) => item.id == itemId);
      inventory = [
        for (final item in inventory)
          if (item.id != itemId) item,
      ];
      groundItems = _withItem(groundItems, hero.position, put);
      events.add(ItemDropped(item: put, at: hero.position));
  }

  final phase = _monsterPhase(state, hero, loadout, monsters, events);
  hero = phase.hero;
  loadout = loadout.withSkills(phase.skills);

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
      groundItems: groundItems,
      inventory: inventory,
      equipment: loadout.equipment,
      skills: loadout.skills,
      nextDropNumber: nextDropNumber,
    ),
    events,
  );
}

/// Whether [action] walks the hero off the edge of a road fight.
///
/// **Turn-less, like a refusal and unlike a wall.** Bumping a wall costs a turn
/// because it is a swing at the world that missed; walking off the edge of an
/// encounter is the hero leaving, and there is no world left to answer them —
/// charging a monster phase for it would let the thing the hero ran from get a
/// free swing at their back after they had gone.
///
/// False in a crawl whatever the direction, and unreachable there twice over:
/// the field is off, and the crypt's border is solid wall so no crawling hero
/// can stand where this would be asked. See [GameState.isEncounter].
bool _flees(GameState state, GameAction action) =>
    state.isEncounter &&
    action is MoveAction &&
    !state.map.inBounds(state.hero.position.step(action.direction));

/// Why the rules will not even try [action], or null when they will.
///
/// Every check here is a question about the state alone, which is what lets the
/// answer be "nothing happened" rather than "a turn passed and nothing
/// happened".
GameEvent? _refuse(GameState state, GameAction action) {
  switch (action) {
    case MoveAction():
    case DescendAction():
      return null;
    case AscendAction():
      if (state.depth <= 1) {
        return const ActionRefused(reason: 'there are no stairs up from here');
      }
      if (state.stairsUp != state.hero.position) {
        return const ActionRefused(reason: 'the stairs up are not here');
      }
      return null;
    case PickUpAction():
      if (state.itemsAt(state.hero.position).isEmpty) {
        return const ActionRefused(reason: 'there is nothing here to take');
      }
      if (state.inventory.length >= inventoryCap) return const InventoryFull();
      return null;
    case EquipAction(:final itemId):
      return _refusedBy(wearRefusal(state.loadout, state.inventory, itemId));
    case UnequipAction(:final slot):
      return _refusedBy(takeOffRefusal(state.equipment, state.inventory, slot));
    case DrinkAction(:final itemId):
      final item = _carried(state, itemId);
      if (item == null)
        return const ActionRefused(reason: 'you are not carrying that');
      if (!item.base.isPotion) {
        return ActionRefused(reason: '${item.base.name} is not a drink');
      }
      return null;
    case DropAction(:final itemId):
      if (_carried(state, itemId) == null) {
        return const ActionRefused(reason: 'you are not carrying that');
      }
      return null;
  }
}

Item? _carried(GameState state, String itemId) {
  for (final item in state.inventory) {
    if (item.id == itemId) return item;
  }
  return null;
}

GameEvent? _refusedBy(String? reason) =>
    reason == null ? null : ActionRefused(reason: reason);

/// Announces the pieces a [Worn] moved, in the order the log has to read them.
void _announce(Worn worn, List<GameEvent> events) {
  for (final (item, slot) in worn.taken) {
    events.add(ItemUnequipped(item: item, slot: slot));
  }
  final put = worn.put;
  if (put != null) {
    events.add(ItemEquipped(item: put.$1, slot: put.$2));
  }
}

/// The hero after a swing, and the skills that swing trained.
///
/// [spoils] carries what the kill left behind, if anything, and where.
class _HeroSwing {
  const _HeroSwing(this.hero, this.skills, this.spoils);

  final Actor hero;
  final Map<SkillId, SkillState> skills;
  final (Position, Item)? spoils;
}

_HeroSwing _moveHero(
  GameState state,
  Actor hero,
  Loadout loadout,
  List<Actor> monsters,
  Direction direction,
  List<GameEvent> events,
) {
  final target = hero.position.step(direction);
  final defending = monsters.indexWhere(
    (monster) => monster.position == target,
  );
  if (defending >= 0) {
    final (min, max) = heroAttack(hero, loadout);
    final damage = state.rng.rollRange(min, max);
    final defender = monsters[defending];
    events.add(
      AttackHit(attackerId: hero.id, targetId: defender.id, damage: damage),
    );
    final mastery = loadout.wieldsTwoHanded ? SkillId.might : SkillId.arms;
    final skills = _train(mastery, loadout.skills, events);
    final wounded = defender.copyWith(hp: defender.hp - damage);
    if (wounded.isAlive) {
      monsters[defending] = wounded;
      return _HeroSwing(hero, skills, null);
    }
    monsters.removeAt(defending);
    events.add(ActorDied(actorId: defender.id));
    return _HeroSwing(hero, skills, _spoilsOf(state, defender, events));
  }
  if (state.map.isWalkable(target)) {
    events.add(ActorMoved(actorId: hero.id, from: hero.position, to: target));
    return _HeroSwing(hero.copyWith(position: target), loadout.skills, null);
  }
  events.add(MoveBlocked(actorId: hero.id, at: target));
  return _HeroSwing(hero, loadout.skills, null);
}

/// What [defender]'s death left on its tile, or null when it left nothing.
///
/// Both rolls — whether anything dropped, and what — come from the loot stream,
/// never the combat stream. See [GameState.lootRng] for why that split is the
/// whole point.
(Position, Item)? _spoilsOf(
  GameState state,
  Actor defender,
  List<GameEvent> events,
) {
  final table = state.dropTables[state.depth];
  if (table == null || defender.dropChance <= 0) return null;
  if (state.lootRng.rollRange(1, 100) > defender.dropChance) return null;
  final item = rollDrop(table, state.lootRng, 'drop-${state.nextDropNumber}');
  events.add(ItemDropped(item: item, at: defender.position));
  return (defender.position, item);
}

/// The hero after the monsters have had their turns, and the skills they trained.
class _MonsterPhase {
  const _MonsterPhase(this.hero, this.skills);

  final Actor hero;
  final Map<SkillId, SkillState> skills;
}

_MonsterPhase _monsterPhase(
  GameState state,
  Actor hero,
  Loadout loadout,
  List<Actor> monsters,
  List<GameEvent> events,
) {
  final owed = scheduleMonsterTurns(
    heroSpeed: heroSpeed(hero, loadout),
    heroEnergy: hero.energy,
    monsterSpeeds: [for (final monster in monsters) monster.speed],
    monsterEnergies: [for (final monster in monsters) monster.energy],
  );
  final field = computeFlowField(state.map, hero.position);
  var wounded = hero;
  var trained = loadout;
  for (final index in owed.monsterTurns) {
    if (!wounded.isAlive) break;
    final monster = monsters[index];
    if (monster.position.isOrthogonallyAdjacentTo(wounded.position)) {
      trained = trained.withSkills(
        _defend(state, monster, trained, events, wounded.id, (damage) {
          wounded = wounded.copyWith(hp: wounded.hp - damage);
        }),
      );
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
  return _MonsterPhase(
    wounded.copyWith(energy: owed.heroEnergy),
    trained.skills,
  );
}

/// Resolves one monster swing at the hero and returns the skills it trained.
///
/// The pipeline is dodge first, then armour: a dodged swing does no damage at
/// all, and a landed one is reduced by [heroArmor] to a floor of one. The floor
/// exists so that armour can never make a monster harmless — a creature that
/// cannot hurt the hero at all stops being a reason to leave the room.
///
/// **A hero with no dodge chance does not roll at all**, and that is a
/// determinism rule rather than an optimisation. The dodge roll draws from the
/// combat stream, so rolling it unconditionally would advance that stream once
/// per monster attack for every hero in the game — including every hero with
/// no chance whatsoever of dodging. Every seeded fight ever recorded would
/// resolve differently, and a zero-probability roll would have bought exactly
/// nothing in exchange.
///
/// Which defensive skill trains follows what the hero is wearing, and the two
/// are exclusive: Bulwark while any piece is heavy, Fleetfoot while none is.
/// That is what keeps armour and dodge from compounding — a hero cannot train
/// both at once, so it has to pick a defence and live with it.
///
/// **Pierce subtracts from the hero's armour, never adds to the roll.** The two
/// arithmetics look alike until the armour runs out: adding to the roll would
/// go on scaling against a hero wearing nothing, while eating armour stops at
/// zero and leaves the floor of one to do the rest. It also keeps the sentence
/// the player reads honest — the wight did not swing harder, the mail did
/// less.
Map<SkillId, SkillState> _defend(
  GameState state,
  Actor attacker,
  Loadout loadout,
  List<GameEvent> events,
  String heroId,
  void Function(int damage) wound,
) {
  final defence = loadout.wearsHeavy ? SkillId.bulwark : SkillId.fleetfoot;
  final dodge = heroDodgePercent(loadout);
  if (dodge > 0 && state.rng.rollRange(1, 100) <= dodge) {
    events.add(AttackDodged(attackerId: attacker.id));
    return _train(defence, loadout.skills, events);
  }
  final roll = state.rng.rollRange(attacker.attackMin, attacker.attackMax);
  final armor = heroArmor(loadout) - attacker.pierce;
  final reduced = roll - (armor < 0 ? 0 : armor);
  final damage = reduced < 1 ? 1 : reduced;
  events.add(
    AttackHit(attackerId: attacker.id, targetId: heroId, damage: damage),
  );
  wound(damage);
  return _train(defence, loadout.skills, events);
}

/// [skills] after one use of [skill], announcing a level-up if it crossed one.
Map<SkillId, SkillState> _train(
  SkillId skill,
  Map<SkillId, SkillState> skills,
  List<GameEvent> events,
) {
  final before = skills[skill] ?? const SkillState();
  final after = before.trained();
  if (after.level > before.level) {
    events.add(SkillLevelledUp(skill: skill, level: after.level));
  }
  return {...skills, skill: after};
}

Map<Position, List<Item>> _withItem(
  Map<Position, List<Item>> groundItems,
  Position at,
  Item item,
) => {
  ...groundItems,
  at: [...groundItems[at] ?? const [], item],
};

Map<Position, List<Item>> _withoutLastItem(
  Map<Position, List<Item>> groundItems,
  Position at,
) {
  final left = [...groundItems[at]!]..removeLast();
  final without = {...groundItems}..remove(at);
  return left.isEmpty ? without : {...without, at: left};
}

Set<Position> _occupiedTiles(Actor hero, List<Actor> monsters, String moving) =>
    {
      hero.position,
      for (final other in monsters)
        if (other.id != moving) other.position,
    };

/// The floor the hero is standing on, frozen for its return.
FloorMemory _snapshot(GameState state) => FloorMemory(
  map: state.map,
  monsters: state.monsters,
  groundItems: state.groundItems,
  explored: state.explored,
  stairsDown: state.stairsDown,
  stairsUp: state.stairsUp,
);

/// A floor built for the first time, ready to be arrived on.
///
/// Freshly built monsters are set ready to act, which is what everything on a
/// generated floor has always been. Restored monsters skip this: theirs is the
/// energy they were left holding.
///
/// A floor built here is always a floor entered from the one above, so it
/// always has a way back up. Where the builder did not name one, the arrival
/// tile is it — which is where the generator puts it anyway.
FloorMemory _built(Floor floor) => FloorMemory(
  map: floor.map,
  monsters: [
    for (final monster in floor.monsters)
      monster.copyWith(energy: actThreshold),
  ],
  groundItems: floor.groundItems,
  explored: const {},
  stairsDown: floor.stairsDown,
  stairsUp: floor.stairsUp ?? floor.heroSpawn,
);

/// The state after stepping onto [depth], arriving at [at].
///
/// The departing floor goes into [GameState.floors] and the arriving one comes
/// out of it, so exactly one floor is ever live and there is never a second
/// copy of it to go stale.
///
/// The clock restarts for the hero and the arrival runs no monster phase, which
/// is the rule descending has always followed: a hero who has not yet seen a
/// tile of the floor should not already have been swung at on it.
///
/// **That makes a stairs bounce two free actions**, because neither direction
/// runs a monster phase: a hero cornered on the stairs can step through and
/// back without ever being hit. It is harmless only while nothing in the game
/// gives hit points back on its own — the bounce buys time, and time buys
/// nothing. The day regeneration arrives, or any rule that pays out per turn,
/// this becomes a healing loop and the arrival will have to start charging for
/// itself.
(GameState, List<GameEvent>) _arriveOn(
  GameState state,
  Actor hero,
  int depth,
  FloorMemory floor,
  Position at,
  List<GameEvent> events,
) {
  final arrived = hero.copyWith(position: at, energy: actThreshold);
  final visible = computeFov(floor.map, at, fovRadius);
  return (
    state.copyWith(
      map: floor.map,
      hero: arrived,
      monsters: floor.monsters,
      visible: visible,
      explored: {...floor.explored, ...visible},
      depth: depth,
      stairsDown: floor.stairsDown,
      clearStairsDown: floor.stairsDown == null,
      stairsUp: floor.stairsUp,
      clearStairsUp: floor.stairsUp == null,
      groundItems: floor.groundItems,
      floors: {...state.floors, state.depth: _snapshot(state)}..remove(depth),
    ),
    events,
  );
}

(GameState, List<GameEvent>) _arriveBelow(
  GameState state,
  Actor hero,
  List<GameEvent> events,
) {
  final depth = state.depth + 1;
  final floor = state.floors[depth] ?? _built(state.buildFloor(depth));
  events.add(Descended(newDepth: depth));
  return _arriveOn(state, hero, depth, floor, floor.stairsUp!, events);
}

/// Climbs to the floor above, which the hero must have walked to get here.
///
/// A missing snapshot is a programming error rather than a game state: the only
/// way onto depth two or deeper is through the floor above it, and that descent
/// is what wrote the snapshot. Rebuilding one here would be worse than throwing
/// — it would silently reshuffle a floor the player thought they knew.
(GameState, List<GameEvent>) _arriveAbove(
  GameState state,
  Actor hero,
  List<GameEvent> events,
) {
  final depth = state.depth - 1;
  final floor = state.floors[depth];
  if (floor == null) {
    throw StateError('depth $depth was never walked, so there is no way back');
  }
  events.add(Ascended(newDepth: depth));
  return _arriveOn(state, hero, depth, floor, floor.stairsDown!, events);
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
