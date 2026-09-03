import '../craft/material.dart';
import '../dungeon/floor.dart';
import '../dungeon/floor_memory.dart';
import '../dungeon/flow_field.dart';
import '../dungeon/fov.dart';
import '../loot/wear.dart';
import '../loot/drop.dart';
import '../loot/item.dart';
import '../loot/loadout.dart';
import '../magic/mana.dart';
import '../magic/read.dart';
import '../magic/spell.dart';
import '../magic/target.dart';
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
  final reachedAtStart = _reachedAtStart(state);
  final monsters = [...state.monsters];
  var hero = state.hero.copyWith(energy: state.hero.energy - actCost);
  var loadout = state.loadout;
  var groundItems = state.groundItems;
  var nodes = state.nodes;
  var materials = state.materials;
  var inventory = state.inventory;
  var nextDropNumber = state.nextDropNumber;
  var itemNumber = state.itemNumber;
  var knownSpells = state.knownSpells;
  var mana = state.mana;
  var warded = state.warded;
  var bound = state.bound;

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
      // The mint at the pack's door: the ground id is transient state — a
      // litter id is minted on every visit and a drop id on every delve, so a
      // pack that persisted across delves could hold two items answering to
      // one id, and every removal would take both. The pack item's id is
      // durable identity, so it is re-minted here off the hero-scoped
      // counter, once per item, while the ground keeps its frozen litter ids.
      final carried = taken.withId('item-$itemNumber');
      itemNumber++;
      inventory = [...inventory, carried];
      events.add(ItemPickedUp(item: carried));
    case EquipAction(:final itemId):
      final worn = wear(loadout.equipment, inventory, itemId);
      _announce(worn, events);
      loadout = loadout.withEquipment(worn.equipment);
      inventory = worn.inventory;
      hero = clampedToMaxHp(hero, loadout);
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
    case ReadAction(:final itemId):
      final book = inventory.firstWhere((item) => item.id == itemId);
      final learned = state.spells[book.base.teaches]!;
      knownSpells = {...knownSpells, learned.id};
      inventory = [
        for (final item in inventory)
          if (item.id != itemId) item,
      ];
      events.add(SpellLearned(book: book, spell: learned));
    case CastSpellAction(:final spellId, :final targetId):
      final spell = state.spells[spellId]!;
      final cast = _castSpell(state, spell, hero, monsters, events, targetId);
      hero = cast.hero;
      loadout = loadout.withSkills(
        _train(spell.school, loadout.skills, events),
      );
      mana -= spell.manaCost;
      warded = cast.warded ?? warded;
      bound = cast.bound ?? bound;
      if (cast.spoils != null) {
        groundItems = _withItem(groundItems, cast.spoils!.$1, cast.spoils!.$2);
        nextDropNumber++;
      }
    case GatherAction():
      final kind = nodes[hero.position]!;
      nodes = {...nodes}..remove(hero.position);
      materials = withMaterial(materials, kind.yields, 1);
      events.add(
        NodeGathered(kind: kind, at: hero.position, material: kind.yields),
      );
      loadout = loadout.withSkills(_train(kind.trains, loadout.skills, events));
    case DropAction(:final itemId):
      final put = inventory.firstWhere((item) => item.id == itemId);
      inventory = [
        for (final item in inventory)
          if (item.id != itemId) item,
      ];
      groundItems = _withItem(groundItems, hero.position, put);
      events.add(ItemDropped(item: put, at: hero.position));
  }

  final phase = _monsterPhase(
    state,
    hero,
    loadout,
    monsters,
    warded,
    bound,
    reachedAtStart,
    events,
  );
  hero = phase.hero;
  loadout = loadout.withSkills(phase.skills);
  warded = phase.warded;
  bound = phase.bound;

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
      nodes: nodes,
      materials: materials,
      inventory: inventory,
      equipment: loadout.equipment,
      skills: loadout.skills,
      knownSpells: knownSpells,
      mana: mana,
      warded: warded,
      bound: _stillStanding(bound, monsters),
      nextDropNumber: nextDropNumber,
      itemNumber: itemNumber,
    ),
    events,
  );
}

/// Why the rules will not cast [spellId], or null when they will.
///
/// **The order is the contract.** An empty pool is answered before an empty
/// room, because a hero who could not have cast the spell at anything should be
/// told that rather than sent looking for a target they could not have used.
String? _castRefusal(GameState state, String spellId, String? targetId) {
  final spell = state.spells[spellId];
  if (spell == null || !state.knownSpells.contains(spellId)) {
    return 'you do not know that spell';
  }
  if (state.mana < spell.manaCost) return 'not enough mana';
  if (_needsATarget(spell.kind)) {
    if (targetId != null) {
      if (_namedVisibleEnemy(state, targetId) == null) {
        return 'you cannot see that target';
      }
    } else if (nearestVisibleEnemy(
          state.monsters,
          state.visible,
          state.hero.position,
        ) ==
        null) {
      return 'no enemy in sight';
    }
  }
  return null;
}

/// The monster [targetId] names, when it stands in the hero's sight.
Actor? _namedVisibleEnemy(GameState state, String targetId) {
  for (final monster in state.monsters) {
    if (monster.id == targetId && state.visible.contains(monster.position)) {
      return monster;
    }
  }
  return null;
}

/// Whether this kind of spell has to land on something.
///
/// Mend and Ward are cast on the hero, so an empty room is exactly when a
/// player most wants them.
bool _needsATarget(SpellKind kind) =>
    kind == SpellKind.bolt ||
    kind == SpellKind.bind ||
    kind == SpellKind.banish;

/// What one cast changed, beyond the monsters it wrote through.
///
/// [warded] and [bound] are null where the cast did not touch them, so the
/// caller can tell "set to zero" from "left alone" without a second flag.
class _Cast {
  const _Cast(this.hero, {this.warded, this.bound, this.spoils});

  final Actor hero;
  final int? warded;
  final Map<String, int>? bound;
  final (Position, Item)? spoils;
}

/// Resolves one cast of [spell], writing wounded or moved monsters into
/// [monsters].
///
/// **Every draw this can make is named here and nowhere else**, because the
/// count and the order of draws is the seed contract: a bolt draws exactly one
/// number for its damage, a banish draws exactly one to pick a tile, and mend,
/// ward and bind draw nothing whatsoever. A conditional draw anywhere on this
/// path would make two crawls on one seed diverge the moment one of them cast.
_Cast _castSpell(
  GameState state,
  Spell spell,
  Actor hero,
  List<Actor> monsters,
  List<GameEvent> events,
  String? targetId,
) {
  switch (spell.kind) {
    case SpellKind.mend:
      final missing = heroMaxHp(hero, state.loadout) - hero.hp;
      final healed = spell.min < missing ? spell.min : missing;
      final given = healed > 0 ? healed : 0;
      events.add(MendCast(healed: given));
      return _Cast(hero.copyWith(hp: hero.hp + given));
    case SpellKind.ward:
      events.add(WardRaised(absorbs: spell.min));
      return _Cast(hero, warded: spell.min);
    case SpellKind.bolt:
      return _boltAt(state, spell, hero, monsters, events, targetId);
    case SpellKind.bind:
      final target = _targetOf(state, monsters, targetId);
      events.add(MonsterBound(targetId: target.id, turns: spell.min));
      return _Cast(hero, bound: {...state.bound, target.id: spell.min});
    case SpellKind.banish:
      _banish(state, monsters, events, targetId);
      return _Cast(hero);
  }
}

_Cast _boltAt(
  GameState state,
  Spell spell,
  Actor hero,
  List<Actor> monsters,
  List<GameEvent> events,
  String? targetId,
) {
  final target = _targetOf(state, monsters, targetId);
  final index = monsters.indexOf(target);
  final roll = state.rng.rollRange(spell.min, spell.max);
  final bite = _biteOf(target, spell.type!);
  final damage = switch (bite) {
    SpellBite.plain => roll,
    SpellBite.resisted => roll ~/ 2 < 1 ? 1 : roll ~/ 2,
    SpellBite.vulnerable => roll * 2,
  };
  events.add(
    SpellHit(spell: spell, targetId: target.id, damage: damage, bite: bite),
  );
  final wounded = target.copyWith(hp: target.hp - damage);
  if (wounded.isAlive) {
    monsters[index] = wounded;
    return _Cast(hero);
  }
  monsters.removeAt(index);
  events.add(ActorDied(actorId: target.id));
  return _Cast(hero, spoils: _spoilsOf(state, target, events));
}

/// How [target]'s make-up answers a bolt of [type].
///
/// Resistance halves rounding down with a floor of one, for the reason armour
/// has a floor of one: a creature nothing can hurt stops being a reason to leave
/// the room. Vulnerability doubles, and the two can never both apply — content
/// validation keeps the sets disjoint.
SpellBite _biteOf(Actor target, DamageType type) {
  if (target.resists.contains(type)) return SpellBite.resisted;
  if (target.vulnerableTo.contains(type)) return SpellBite.vulnerable;
  return SpellBite.plain;
}

/// Moves the targeted monster to a tile drawn from the crawl's stream.
///
/// **One draw, into a list built row by row and then column by column.** That
/// order is [byRowThenColumn]'s, walked rather than sorted, and it is what makes
/// the draw mean the same thing twice: an index only names a tile if the list it
/// indexes into is in a stated order.
void _banish(
  GameState state,
  List<Actor> monsters,
  List<GameEvent> events,
  String? targetId,
) {
  final target = _targetOf(state, monsters, targetId);
  final index = monsters.indexOf(target);
  final taken = _occupiedTiles(state.hero, monsters, target.id);
  final candidates = <Position>[
    for (var y = 0; y < state.map.height; y++)
      for (var x = 0; x < state.map.width; x++)
        if (state.map.isWalkable(Position(x, y)) &&
            !taken.contains(Position(x, y)) &&
            Position(x, y) != target.position)
          Position(x, y),
  ];
  if (candidates.isEmpty) return;
  final landing = candidates[state.rng.rollRange(0, candidates.length - 1)];
  monsters[index] = target.copyWith(position: landing);
  events.add(
    MonsterBanished(targetId: target.id, from: target.position, to: landing),
  );
}

/// What this cast lands on: the monster it named, or the nearest enemy in
/// sight.
///
/// A named target was validated visible by `_castRefusal` before this ran, so
/// the fallback can never fire for one; the `!` reads the rule, not a guess.
Actor _targetOf(GameState state, List<Actor> monsters, String? targetId) {
  if (targetId != null) {
    return _namedVisibleEnemy(state, targetId)!;
  }
  return nearestVisibleEnemy(monsters, state.visible, state.hero.position)!;
}

/// [bound] with every counter whose monster is no longer on the floor dropped.
///
/// A bound monster that dies takes its counter with it, and so does one that was
/// never there. Left alone the map would grow a entry per kill and a save file
/// would carry counters for the dead.
Map<String, int> _stillStanding(Map<String, int> bound, List<Actor> monsters) {
  if (bound.isEmpty) return bound;
  final alive = {for (final monster in monsters) monster.id};
  return {
    for (final held in bound.entries)
      if (alive.contains(held.key)) held.key: held.value,
  };
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
    case GatherAction():
      if (state.nodeAt(state.hero.position) == null) {
        return const ActionRefused(reason: 'there is nothing here to gather');
      }
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
    case ReadAction(:final itemId):
      return _refusedBy(
        readRefusal(
          state.loadout,
          state.inventory,
          state.knownSpells,
          state.spells,
          itemId,
        ),
      );
    case CastSpellAction(:final spellId, :final targetId):
      return _refusedBy(_castRefusal(state, spellId, targetId));
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

/// The hero after the monsters have had their turns, the skills they trained,
/// what is left of the ward they struck, and how much longer each held monster
/// stays held.
class _MonsterPhase {
  const _MonsterPhase(this.hero, this.skills, this.warded, this.bound);

  final Actor hero;
  final Map<SkillId, SkillState> skills;
  final int warded;
  final Map<String, int> bound;
}

_MonsterPhase _monsterPhase(
  GameState state,
  Actor hero,
  Loadout loadout,
  List<Actor> monsters,
  int warded,
  Map<String, int> bound,
  Set<String> reachedAtStart,
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
  var standing = warded;
  var held = bound;

  // **The ambush opening: reach is a debt the monster collects.** A monster
  // the hero's own move just handed reach to — walked up to, or closed with —
  // swings in this phase even when the clock owes it nothing, and an owed
  // opener's opening IS its owed turn, spent here rather than again below.
  // The opening is a turn, never a bonus: an unowed opener's energy is
  // charged at the end of the phase, an owed one's was spent by the schedule,
  // and either way the monster swings once and once only. Bound monsters get
  // nothing: the clock is holding them still, and a hold that granted a free
  // swing would be a hold worth less than standing still.
  final pending = [...owed.monsterTurns];
  final charged = <int>{};
  for (var index = 0; index < monsters.length; index++) {
    final monster = monsters[index];
    if (!monster.isAlive) continue;
    if (bound.containsKey(monster.id)) continue;
    if (reachedAtStart.contains(monster.id)) continue;
    if (!_holdsReach(state, monster, wounded.position)) continue;
    final strike = _monsterStrikes(
      state,
      monster,
      trained,
      wounded,
      standing,
      events,
    );
    wounded = strike.hero;
    trained = trained.withSkills(strike.skills);
    standing = strike.standing;
    final owedIndex = pending.indexOf(index);
    if (owedIndex >= 0) {
      pending.removeAt(owedIndex);
    } else {
      charged.add(index);
    }
  }

  for (final index in pending) {
    if (!wounded.isAlive) break;
    final monster = monsters[index];
    if (held[monster.id] case final turns?) {
      held = _oneTurnLess(held, monster.id, turns);
      continue;
    }
    if (monster.position.isOrthogonallyAdjacentTo(wounded.position)) {
      final strike = _monsterStrikes(
        state,
        monster,
        trained,
        wounded,
        standing,
        events,
      );
      wounded = strike.hero;
      trained = trained.withSkills(strike.skills);
      standing = strike.standing;
      continue;
    }
    if (_holdsReach(state, monster, wounded.position)) {
      // **A spitter stands its ground while it can shoot.** The blow is an
      // ordinary melee blow — _defend verbatim, no to-hit roll, no damage
      // type — only delivered from where the monster stands.
      final strike = _monsterStrikes(
        state,
        monster,
        trained,
        wounded,
        standing,
        events,
      );
      wounded = strike.hero;
      trained = trained.withSkills(strike.skills);
      standing = strike.standing;
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
    final moved = monster.copyWith(position: target);
    monsters[index] = moved;
    // **The lunge is the chase catching the hero.** A monster whose step
    // lands it in reach swings in the same phase, with _defend's own draws —
    // and the swing is an ambush, not a free rider on the move: the monster's
    // owed turn bought the step, so the swing is charged [actCost] and spent
    // against the turn the clock would have owed it next. Front-loaded, not
    // doubled. The gate is the snapshot: the ambush fires on reach *newly
    // created* this turn, so a monster that held reach at the turn's start
    // and merely re-caught the fleeing hero waits for the swing it is owed —
    // measured: without the gate, the charged lunge on every chaser dropped
    // the crypt to 17/40, under the suite's own still-unfair floor.
    if (!reachedAtStart.contains(monster.id) &&
        _holdsReach(state, moved, wounded.position)) {
      final strike = _monsterStrikes(
        state,
        moved,
        trained,
        wounded,
        standing,
        events,
      );
      wounded = strike.hero;
      trained = trained.withSkills(strike.skills);
      standing = strike.standing;
      charged.add(index);
    }
  }
  for (var index = 0; index < monsters.length; index++) {
    monsters[index] = monsters[index].copyWith(
      energy:
          owed.monsterEnergies[index] - (charged.contains(index) ? actCost : 0),
    );
  }
  return _MonsterPhase(
    wounded.copyWith(energy: owed.heroEnergy),
    trained.skills,
    standing,
    held,
  );
}

/// Whether [monster] can strike a hero standing at [heroPosition] right now.
///
/// Adjacency for every actor; a reach greater than one reaches across the
/// room — but only along a line of sight the hero holds, and the distance is
/// Chebyshev's. It draws nothing: every input is already on the state.
bool _holdsReach(GameState state, Actor monster, Position heroPosition) {
  if (monster.position.isOrthogonallyAdjacentTo(heroPosition)) return true;
  return monster.reach > 1 &&
      state.visible.contains(monster.position) &&
      monster.position.chebyshevTo(heroPosition) <= monster.reach;
}

/// Every monster holding reach on the hero, as the turn begins.
///
/// The snapshot is what makes the ambush an opening and not a tax: a monster
/// that could already strike gains nothing it did not have, and one that the
/// hero's own move just armed does.
Set<String> _reachedAtStart(GameState state) => {
  for (final monster in state.monsters)
    if (_holdsReach(state, monster, state.hero.position)) monster.id,
};

/// The hero, defence and skills after one monster's swing.
///
/// Every branch that resolves a monster attack — the owed turn, the lunge,
/// the ambush opening — spends [ _defend] through this one shape, so the
/// dodge gate, the armour and the ward behave identically no matter which of
/// the three reasons the swing happened for.
class _Strike {
  const _Strike(this.hero, this.skills, this.standing);

  final Actor hero;
  final Map<SkillId, SkillState> skills;
  final int standing;
}

_Strike _monsterStrikes(
  GameState state,
  Actor monster,
  Loadout loadout,
  Actor hero,
  int standing,
  List<GameEvent> events,
) {
  var wounded = hero;
  var left = standing;
  final skills = _defend(state, monster, loadout, events, hero.id, standing, (
    damage,
    warded,
  ) {
    wounded = wounded.copyWith(hp: wounded.hp - damage);
    left = warded;
  });
  return _Strike(wounded, skills, left);
}

/// [bound] with [id]'s count spent by one, and the entry gone when it runs out.
///
/// Counted in the held monster's own turns rather than the hero's, so a fast
/// monster works its way free sooner than a slow one — the same clock every
/// other rule in this phase runs on.
Map<String, int> _oneTurnLess(Map<String, int> bound, String id, int turns) {
  if (turns <= 1) return {...bound}..remove(id);
  return {...bound, id: turns - 1};
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
///
/// **A ward soaks what is left, after the floor of one and never before it.**
/// Armour reduces a blow and a ward takes what still lands, which is the only
/// order that keeps both rules meaning what they say: absorbing first would let
/// a ward eat a blow armour was going to floor anyway, and the floor exists so
/// that no defence can make a creature harmless. [AttackHit] is emitted only
/// when hit points actually drop, because that event is what the log turns into
/// a wound — a blow the ward ate whole is a [WardStruck] and nothing else.
///
/// **The ward adds no roll**, which is the dodge gate's determinism rule again:
/// it is arithmetic over a number already on the state, so a warded hero and a
/// bare one draw from the combat stream identically.
Map<SkillId, SkillState> _defend(
  GameState state,
  Actor attacker,
  Loadout loadout,
  List<GameEvent> events,
  String heroId,
  int warded,
  void Function(int damage, int warded) wound,
) {
  final defence = loadout.wearsHeavy ? SkillId.bulwark : SkillId.fleetfoot;
  final dodge = heroDodgePercent(loadout);
  if (dodge > 0 && state.rng.rollRange(1, 100) <= dodge) {
    events.add(AttackDodged(attackerId: attacker.id));
    wound(0, warded);
    return _train(defence, loadout.skills, events);
  }
  final roll = state.rng.rollRange(attacker.attackMin, attacker.attackMax);
  final armor = heroArmor(loadout) - attacker.pierce;
  final reduced = roll - (armor < 0 ? 0 : armor);
  final damage = reduced < 1 ? 1 : reduced;
  final absorbed = warded < damage ? warded : damage;
  final left = warded - absorbed;
  if (absorbed > 0) {
    events.add(WardStruck(absorbed: absorbed, remaining: left));
  }
  final taken = damage - absorbed;
  if (taken > 0) {
    events.add(
      AttackHit(attackerId: attacker.id, targetId: heroId, damage: taken),
    );
  }
  wound(taken, left);
  return _train(defence, loadout.skills, events);
}

/// [skills] after one use of [skill], announcing a level-up if it crossed one.
///
/// The grant itself is [trainedIn]'s, so the crawl and the town train by exactly
/// the same rule; the only thing this adds is the sentence.
Map<SkillId, SkillState> _train(
  SkillId skill,
  Map<SkillId, SkillState> skills,
  List<GameEvent> events,
) {
  final before = skills[skill] ?? const SkillState();
  final trained = trainedIn(skills, skill);
  final after = trained[skill]!;
  if (after.level > before.level) {
    events.add(SkillLevelledUp(skill: skill, level: after.level));
  }
  return trained;
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
///
/// The nodes ride beside the litter, and for the same reason: a vein the hero
/// walked past is still there when they walk back, and one they worked is still
/// gone.
FloorMemory _snapshot(GameState state) => FloorMemory(
  map: state.map,
  monsters: state.monsters,
  groundItems: state.groundItems,
  nodes: state.nodes,
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
  nodes: floor.nodes,
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
/// back without ever being hit. It buys time, and time buys nothing.
///
/// **Which is exactly why mana refills on a floor never built and not on every
/// arrival.** Mend gives hit points back, so a pool that topped up every time
/// the hero crossed a stairwell would be the healing loop this arrival was
/// always one rule away from: step down, step up, mend, repeat, for free and
/// forever. Refilling on the first arrival at a depth keeps the budget the
/// per-floor thing it is meant to be — one floor, one pool — and leaves a
/// bounce buying nothing at all, which is what it has always bought.
///
/// **Binds are cleared here, on every arrival in both directions.** A monster
/// id is unique to a floor and not to a run, so the crypt's first ghoul is
/// `ghoul-1` on depth one and a different `ghoul-1` waits on depth two: a
/// counter carried down the stairs would hold a monster the hero never bound,
/// and one carried back up would hold one that had long since worked free.
(GameState, List<GameEvent>) _arriveOn(
  GameState state,
  Actor hero,
  int depth,
  FloorMemory floor,
  Position at,
  List<GameEvent> events, {
  bool refillMana = false,
}) {
  final arrived = hero.copyWith(position: at, energy: actThreshold);
  final visible = computeFov(floor.map, at, fovRadius);
  return (
    state.copyWith(
      bound: const {},
      mana: refillMana ? heroMaxMana(state.loadout) : state.mana,
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
      nodes: floor.nodes,
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
  final remembered = state.floors[depth];
  final floor = remembered ?? _built(state.buildFloor(depth));
  events.add(Descended(newDepth: depth));
  return _arriveOn(
    state,
    hero,
    depth,
    floor,
    floor.stairsUp!,
    events,
    refillMana: remembered == null,
  );
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
