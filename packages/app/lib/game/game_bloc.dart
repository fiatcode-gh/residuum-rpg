import 'dart:ui' show Offset;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'event_messages.dart';

sealed class GameBlocEvent {
  const GameBlocEvent();
}

final class TileTapped extends GameBlocEvent {
  const TileTapped(this.position);

  final Position position;
}

/// The player tapped a stage card in the battle dock.
///
/// Adjacent, the card is the D89 grammar exactly: no armed skill is the
/// bump-attack ([TileTapped] at the monster's tile), an armed spell is
/// [CastPressed] at the named target. Beyond one orthogonal step, **core never
/// sees the tap** — the dock's sentence is the app translating a useless
/// gesture into information, a presentation refusal and not an engine one, so
/// the rules layer gains no verb and no exception to carry.
final class StageCardTapped extends GameBlocEvent {
  const StageCardTapped(this.monster);

  final Actor monster;
}

final class DescendPressed extends GameBlocEvent {
  const DescendPressed();
}

final class AscendPressed extends GameBlocEvent {
  const AscendPressed();
}

/// Take what is lying under the hero.
final class PickUpPressed extends GameBlocEvent {
  const PickUpPressed();
}

/// The player asked to work the node they are standing on.
///
/// One event for both kinds, following [GatherAction]: the tile decides whether
/// this is mining or gathering, and the control's label is the only place the
/// difference is said.
final class GatherPressed extends GameBlocEvent {
  const GatherPressed();
}

final class EquipPressed extends GameBlocEvent {
  const EquipPressed(this.itemId);

  final String itemId;
}

final class UnequipPressed extends GameBlocEvent {
  const UnequipPressed(this.slot);

  final EquipSlot slot;
}

final class DrinkPressed extends GameBlocEvent {
  const DrinkPressed(this.itemId);

  final String itemId;
}

final class DropPressed extends GameBlocEvent {
  const DropPressed(this.itemId);

  final String itemId;
}

/// Read the carried spell book with this id, learning what it teaches.
final class ReadPressed extends GameBlocEvent {
  const ReadPressed(this.itemId);

  final String itemId;
}

/// Cast the known spell with this id at the named target, or at whatever the
/// rules choose when no target is named.
final class CastPressed extends GameBlocEvent {
  const CastPressed(this.spellId, {this.targetId});

  final String spellId;

  /// The monster this cast names, or null for the nearest-enemy fallback —
  /// the Pack's path, which has no aim to name.
  final String? targetId;
}

/// Drink the first potion the hero is carrying, so the common case is one tap.
final class QuickDrinkPressed extends GameBlocEvent {
  const QuickDrinkPressed();
}

/// The player dragged the map by [delta].
final class MapPanned extends GameBlocEvent {
  const MapPanned(this.delta);

  final Offset delta;
}

/// What the player armed in the battle skill bar, one slot at a time.
///
/// A view-scoped fact, not a rule: the armed slot names the action the next
/// legal target tap will apply. Attack arms like a spell does — the bump is
/// still core's blocked move, but the gesture that reaches it is the armed
/// flow now.
sealed class ArmedAction {
  const ArmedAction();
}

/// The armed slot holds the attack.
final class ArmedAttack extends ArmedAction {
  const ArmedAttack();

  @override
  bool operator ==(Object other) => other is ArmedAttack;

  @override
  int get hashCode => 'ArmedAttack'.hashCode;

  @override
  String toString() => 'ArmedAttack()';
}

/// The armed slot holds the spell with this id.
final class ArmedSpell extends ArmedAction {
  const ArmedSpell(this.spellId);

  final String spellId;

  @override
  bool operator ==(Object other) =>
      other is ArmedSpell && other.spellId == spellId;

  @override
  int get hashCode => Object.hash(ArmedSpell, spellId);

  @override
  String toString() => 'ArmedSpell($spellId)';
}

/// The player tapped a skill button in the battle bar, arming [spellId], or
/// disarmed by naming null.
final class SkillArmed extends GameBlocEvent {
  const SkillArmed(this.spellId);

  final String? spellId;
}

/// The player tapped Attack in the battle bar, arming the bump.
///
/// Tapping it again disarms: an armed slot nobody can put down would make the
/// second tap a guess.
final class AttackArmed extends GameBlocEvent {
  const AttackArmed();
}

/// The player pressed the system back button while the crawl was on screen.
///
/// The crawl has an event for this because the crawl refuses it. Android's back
/// button is not a door out of the dungeon — the stairs and death are the only
/// two — so the route declines the pop and dispatches this instead, and the
/// refusal gets a sentence rather than being a press that does nothing.
final class SystemBackPressed extends GameBlocEvent {
  const SystemBackPressed();
}

/// The player pressed the control that walks off the edge of a road fight.
///
/// **A control rather than a tap, because a tap cannot say this.** Movement is
/// tapping the tile you want, and `positionAt` refuses anything off the grid —
/// so there is no tile to tap on the far side of the edge and the flee rule was
/// unreachable by touch. The rule in `step` is unchanged: this dispatches the
/// same outward [MoveAction] a tap would have, if a tap could have.
final class FleePressed extends GameBlocEvent {
  const FleePressed();
}

/// The player asked to hold ground for one turn.
final class WaitPressed extends GameBlocEvent {
  const WaitPressed();
}

/// One step of a walk in progress. Carries the [walkId] it belongs to so a
/// step left over from a cancelled walk cannot resume it.
final class AutoWalkAdvanced extends GameBlocEvent {
  const AutoWalkAdvanced(this.walkId);

  final int walkId;
}

class GameViewState {
  const GameViewState({
    required this.game,
    required this.log,
    this.autoPath = const [],
    this.walkId = 0,
    this.pan = Offset.zero,
    this.hasFled = false,
    this.armedAction,
  });

  final GameState game;
  final List<String> log;

  /// The tiles still to walk. Empty when the hero is not walking.
  final List<Position> autoPath;

  /// Bumped whenever a walk starts or stops.
  final int walkId;

  /// How far the player has dragged the view from where the camera would put it.
  ///
  /// The rule is that **any new game state resets the camera**, and it is
  /// enforced by construction rather than by code: every other handler builds a
  /// fresh [GameViewState] without naming this field, so it falls back to
  /// [Offset.zero]. A future handler that helpfully carried the pan forward
  /// would break the snap-back silently, and no test of that handler would
  /// notice.
  final Offset pan;

  /// Whether the hero has just walked off the edge of a road fight.
  ///
  /// A fact about the last turn rather than about the state, which is why it is
  /// here and not on [GameState]: the rules said "they are gone", and it is the
  /// interface's job to notice and close the screen. It cannot be worked out
  /// from the state, because fleeing changes nothing about the board — that is
  /// the whole of what fleeing is.
  final bool hasFled;

  /// The action the player armed in the battle skill bar, or null for none.
  ///
  /// A view-scoped fact like [pan] and [hasFled]: an aim is a fact about the
  /// interface, not the rules. The same constructor-drop convention as [pan]
  /// enforces its reset rule — any handler that builds a fresh view state
  /// without naming this field disarms silently — and the handlers that name
  /// it are exactly the ones that change nothing about the game: the pan, the
  /// system back refusal, the walk refusal and the walk's own bookkeeping.
  /// Everything that steps the game drops the arm, the completed cast
  /// included, and the battle view closing always rides a stepped state.
  final ArmedAction? armedAction;

  /// The spell the armed slot holds, or null when it holds nothing or holds
  /// the attack — the bar's spell buttons read only their own arming.
  String? get armedSpellId => switch (armedAction) {
    ArmedSpell(spellId: final id) => id,
    _ => null,
  };

  /// The monsters the armed action may land on, by id, in stage order.
  ///
  /// Attack reaches what the bump rule reaches: the orthogonally adjacent.
  /// A target-needing spell keeps the sight rule it has always had: anything
  /// the hero can see. Nothing armed marks nothing.
  Set<String> get armedTargets => switch (armedAction) {
    ArmedAttack() => {
      for (final monster in game.monsters)
        if (monster.position.isOrthogonallyAdjacentTo(game.hero.position))
          monster.id,
    },
    ArmedSpell() => {
      for (final monster in game.monsters)
        if (game.visible.contains(monster.position)) monster.id,
    },
    null => const {},
  };

  int get depth => game.depth;

  /// How many floors the delve the hero is in laid out.
  ///
  /// Read off the state rather than off `deepestDepth`, because a themed delve
  /// rolls its own bottom: the status line has to say three of six in a
  /// six-floor cave and three of five in the crypt, and a constant would tell
  /// the player the same thing in both.
  int get deepest => game.deepest;

  /// Whether this is a fight on the road rather than a crawl.
  bool get isEncounter => game.isEncounter;

  /// The way off the grid from where the hero stands, or null when there is
  /// none.
  ///
  /// Null everywhere in a crawl, because a crawl's border is solid wall and no
  /// hero can stand on it. On a road it is null anywhere but the outermost ring,
  /// which is what makes fleeing cost the walk out to the edge.
  ///
  /// A corner answers with one of its two edges rather than both. Stepping off
  /// either one is the same act, and offering a choice would be asking the
  /// player a question with one answer.
  Direction? get wayOut {
    if (!game.isEncounter || game.isGameOver) return null;
    final at = game.hero.position;
    if (at.x <= 0) return Direction.west;
    if (at.x >= game.map.width - 1) return Direction.east;
    if (at.y <= 0) return Direction.north;
    if (at.y >= game.map.height - 1) return Direction.south;
    return null;
  }

  /// Whether the hero is standing where they could walk away from this fight.
  bool get canFlee => wayOut != null;

  /// Whether a road fight is won and the hero is free to walk on.
  ///
  /// Not an automatic ending. A cleared fight leaves whatever the creatures
  /// dropped lying on the ground, and popping the screen the moment the last one
  /// fell would take the loot with it.
  ///
  /// The control it draws says `Move on` rather than anything longer: three
  /// controls share one row, and a device pass found the fuller wording
  /// ellipsised down to nonsense.
  bool get isRoadClear =>
      game.isEncounter && !game.isGameOver && game.monsters.isEmpty;

  bool get isWalking => autoPath.isNotEmpty;

  bool get canDescend =>
      !game.isGameOver &&
      game.stairsDown != null &&
      game.hero.position == game.stairsDown;

  bool get canAscend =>
      !game.isGameOver &&
      game.stairsUp != null &&
      game.hero.position == game.stairsUp;

  /// Whether the hero is standing where it could walk out of the dungeon.
  ///
  /// Either flight of stairs is a way home, which is what makes a stairwell the
  /// place a player decides at rather than a place they pass through.
  bool get canLeave => !game.isGameOver && (canDescend || canAscend);

  /// Every monster that can strike the hero right now, in floor order.
  ///
  /// The engine's rule mirrored exactly (`_holdsReach`): orthogonal adjacency
  /// for every actor, and a reach greater than one reaching across the room —
  /// but only along a line of sight the hero holds, and the distance is
  /// Chebyshev's. One-way-sight corner pairs where the hero sees without being
  /// seen are accepted and bounded (unit A's probe: 40 asymmetric pairs,
  /// hero-safe direction).
  List<Actor> get monstersHoldingReach => [
    for (final monster in game.monsters)
      if (GameBloc._holdsReachIn(game, monster)) monster,
  ];

  /// Whether [monster] can strike a hero standing where it stands.
  bool _holdsReach(Actor monster) => GameBloc._holdsReachIn(game, monster);

  /// The monsters that act before the hero may act again, in the order they
  /// act — who the turn strip names.
  ///
  /// The exact call the engine's monster phase makes, over the state as the
  /// hero left it: the hero's energy is what the phase schedules on **after
  /// the action's own spend**, which is why the getter spends the threshold
  /// here. Ambush-charged monsters already paid `actCost` from their live
  /// energy, so the schedule reads them correctly from the state. A bound
  /// monster owes no turn the player can watch — the clock holds it still —
  /// so it is filtered out rather than named.
  List<Actor> get upNext {
    final owed = scheduleMonsterTurns(
      heroSpeed: heroSpeed(game.hero, game.loadout),
      heroEnergy: game.hero.energy - actCost,
      monsterSpeeds: [for (final monster in game.monsters) monster.speed],
      monsterEnergies: [for (final monster in game.monsters) monster.energy],
    );
    return [
      for (final index in owed.monsterTurns)
        if (!game.bound.containsKey(game.monsters[index].id))
          game.monsters[index],
    ];
  }

  /// The monsters still walking in, with the hero actions it takes each to
  /// arrive — the turn strip's "n turns out" line.
  ///
  /// Every actor moves one tile per own turn, and a monster's turns arrive
  /// every `heroSpeed / monsterSpeed` hero actions, so the clock-correct count
  /// is the flow-field distance times the speed ratio, rounded up (D86). The
  /// flow field is the same one the engine's chase runs down, so a monster
  /// with no entry — walled off, however visible — has no way in and stands
  /// still in the engine too; it is excluded rather than promised. Monsters
  /// already holding reach are on the stage, not walking in.
  List<(Actor, int)> get arrivals {
    final field = computeFlowField(game.map, game.hero.position);
    final walking = <(Actor, int)>[];
    for (final monster in game.monsters) {
      if (_holdsReach(monster)) continue;
      final distance = field[monster.position];
      if (distance == null) continue;
      walking.add((monster, (distance * speed / monster.speed).ceil()));
    }
    return walking;
  }

  /// Whether the dungeon screen is showing a battle rather than the crawl.
  ///
  /// Open when something holds reach, closed when nothing does — a pure getter
  /// over the state, with no hysteresis and no persisted flag: the fight the
  /// rules see is the fight the player sees, and a flag that outlived the
  /// reach would be the interface lying about the rules.
  bool get isBattleOpen => monstersHoldingReach.isNotEmpty;

  /// Whether there is nothing below this floor.
  ///
  /// **What makes leaving here an ending rather than a pause.** A delve with a
  /// floor left under it is a crawl the hero can walk back into, and the world
  /// screen offers exactly that; a delve with nothing below is a promise kept,
  /// and offering to resume it is a lie the fork used to tell. False on a road,
  /// which has no floors at all.
  bool get isAtTheBottom => !isEncounter && game.depth >= game.deepest;

  /// What is lying under the hero, oldest first.
  List<Item> get itemsUnderfoot => game.itemsAt(game.hero.position);

  bool get canPickUp =>
      !game.isGameOver &&
      itemsUnderfoot.isNotEmpty &&
      game.inventory.length < inventoryCap;

  /// What can be worked where the hero stands, or null when nothing can.
  GatherKind? get nodeUnderfoot => game.nodeAt(game.hero.position);

  /// Whether the crawl screen should offer a Mine or Gather control at all.
  ///
  /// **No pack-cap term, unlike [canPickUp].** Materials are counters and never
  /// items, so there is no cap to run into — which is the whole reason they are
  /// counters.
  bool get canGather => !game.isGameOver && nodeUnderfoot != null;

  /// What the hero has gathered so far, in a fixed order, counters and all.
  ///
  /// Every material is present even at zero, so the panel's rows never move: the
  /// position of a row is information the player relies on, which is the same
  /// rule the pack's sections follow.
  Map<MaterialId, int> get materials => {
    for (final id in MaterialId.values) id: countOf(game.materials, id),
  };

  /// The potion a quick drink would reach for, or null when none is carried.
  Item? get firstPotion {
    for (final item in game.inventory) {
      if (item.base.isPotion) return item;
    }
    return null;
  }

  /// How many potions are in the pack, for the quick-drink control to count.
  int get potionCount =>
      game.inventory.where((item) => item.base.isPotion).length;

  /// How many monsters the hero can see right now.
  ///
  /// **The single home of "something is watching."** The Engaged indicator and
  /// the refusal that stops a walk from starting both read this one getter,
  /// rather than each asking the question in its own words. Two expressions of
  /// the same question drift, and the drift here would be the worst kind: the
  /// interface refusing to walk while showing the player an empty room, or
  /// promising danger that the rules do not act on. A UI that lies about the
  /// rules is worse than either answer on its own.
  int get enemiesInSight => game.monsters
      .where((monster) => game.visible.contains(monster.position))
      .length;

  /// What the hero has left to cast with on this floor.
  int get mana => game.mana;

  /// The most this hero's schooling lets them hold.
  int get maxMana => heroMaxMana(game.loadout);

  /// What is left of the hero's ward, or zero when none stands.
  int get warded => game.warded;

  /// Every spell the hero can cast, in the order the pack screen lists them.
  ///
  /// School first and then name, so a spell keeps its place in the list from one
  /// screen to the next. Position is information a player relies on, which is the
  /// whole reason the pack's own sections are in a fixed order too.
  List<Spell> get knownSpells {
    final known = [
      for (final id in game.knownSpells)
        if (game.spells[id] case final Spell spell) spell,
    ];
    known.sort((one, other) {
      final bySchool = one.school.index.compareTo(other.school.index);
      return bySchool != 0 ? bySchool : one.name.compareTo(other.name);
    });
    return known;
  }

  /// Every spell book in the pack, so the screen can offer Read on each.
  List<Item> get carriedBooks => [
    for (final item in game.inventory)
      if (item.base.isSpellBook) item,
  ];

  /// Why [spell] cannot be cast right now, or null when it can.
  ///
  /// **The screen asks the rules rather than deciding for itself**, which is what
  /// stops the two from drifting: a button that greyed itself out on its own
  /// arithmetic would eventually offer a cast the rules refuse, or refuse one
  /// they would have allowed. The sentence it hands back is the one the log
  /// would have printed.
  ///
  /// The target branch is the mirror of core's `_castRefusal`, order included:
  /// a named target the hero cannot see refuses before the room is called
  /// empty, because a hero aiming at something specific should be told about
  /// that aim and not sent looking for any enemy at all.
  String? castRefusal(Spell spell, {String? targetId}) {
    if (game.isGameOver) return 'you are dead';
    if (game.mana < spell.manaCost) return 'not enough mana';
    if (_needsATarget(spell)) {
      if (targetId != null) {
        if (!_namedVisibleEnemy(targetId)) {
          return 'you cannot see that target';
        }
      } else if (enemiesInSight == 0) {
        return 'no enemy in sight';
      }
    }
    return null;
  }

  /// The monster [targetId] names, when it stands in the hero's sight.
  bool _namedVisibleEnemy(String targetId) => game.monsters.any(
    (monster) =>
        monster.id == targetId && game.visible.contains(monster.position),
  );

  bool _needsATarget(Spell spell) =>
      spell.kind == SpellKind.bolt ||
      spell.kind == SpellKind.bind ||
      spell.kind == SpellKind.banish;

  /// Why the carried book [itemId] cannot be read, or null when it can.
  String? readRefusalFor(String itemId) => readRefusal(
    game.loadout,
    game.inventory,
    game.knownSpells,
    game.spells,
    itemId,
  );

  (int, int) get attack => heroAttack(game.hero, game.loadout);

  int get armor => heroArmor(game.loadout);

  int get dodgePercent => heroDodgePercent(game.loadout);

  int get maxHp => heroMaxHp(game.hero, game.loadout);

  int get speed => heroSpeed(game.hero, game.loadout);
}

class GameBloc extends Bloc<GameBlocEvent, GameViewState> {
  GameBloc({
    GameState? game,
    int worldSeed = 1,
    List<String> log = const [],
    this.dungeon,
    this.stepDelay = const Duration(milliseconds: 90),
  }) : super(
         GameViewState(
           game: game ?? newGame(worldSeed: worldSeed),
           log: log,
         ),
       ) {
    on<TileTapped>(_onTileTapped);
    on<StageCardTapped>(_onStageCardTapped);
    on<WaitPressed>(_onWaitPressed);
    on<DescendPressed>(_onDescendPressed);
    on<AscendPressed>(_onAscendPressed);
    on<AutoWalkAdvanced>(_onAutoWalkAdvanced);
    on<PickUpPressed>(_onPickUpPressed);
    on<GatherPressed>(_onGatherPressed);
    on<EquipPressed>(_onEquipPressed);
    on<UnequipPressed>(_onUnequipPressed);
    on<DrinkPressed>(_onDrinkPressed);
    on<DropPressed>(_onDropPressed);
    on<ReadPressed>(_onReadPressed);
    on<CastPressed>(_onCastPressed);
    on<QuickDrinkPressed>(_onQuickDrinkPressed);
    on<MapPanned>(_onMapPanned);
    on<SkillArmed>(_onSkillArmed);
    on<AttackArmed>(_onAttackArmed);
    on<SystemBackPressed>(_onSystemBackPressed);
    on<FleePressed>(_onFleePressed);
  }

  /// How long the hero pauses between tiles of a walk. Zero in tests.
  final Duration stepDelay;

  /// Which dungeon this crawl is in, or null on a road fight.
  ///
  /// **On the bloc rather than on [GameViewState], and that is deliberate.**
  /// It cannot change for as long as this bloc lives — a crawl does not move
  /// dungeon — while every handler builds a fresh view state by construction, so
  /// a field there would have to be carried through each of them and the first
  /// one that forgot would quietly rename the place on the screen. A run
  /// constant belongs beside [stepDelay].
  final NodeId? dungeon;

  void _onTileTapped(TileTapped event, Emitter<GameViewState> emit) {
    final game = state.game;
    if (game.isGameOver) return;
    if (state.isWalking) {
      emit(_stopWalking());
      return;
    }
    final direction = game.hero.position.directionTo(event.position);
    if (direction != null && game.monsterAt(event.position) == null) {
      emit(_afterAction(MoveAction(direction)));
      return;
    }
    if (!game.explored.contains(event.position)) return;
    if (!game.map.isWalkable(event.position)) return;
    if (state.enemiesInSight > 0) {
      emit(
        GameViewState(
          game: game,
          log: [...state.log, _watchedRefusal],
          walkId: state.walkId,
          armedAction: state.armedAction,
        ),
      );
      return;
    }
    final path = findPath(game.map, game.hero.position, event.position);
    if (path.isEmpty) return;
    final walkId = state.walkId + 1;
    emit(
      GameViewState(
        game: game,
        log: state.log,
        autoPath: path,
        walkId: walkId,
        armedAction: state.armedAction,
      ),
    );
    add(AutoWalkAdvanced(walkId));
  }

  /// Applies the armed action at a stage card.
  ///
  /// The view only sends this event with an armed slot; a bare tap is the
  /// enemy's numbers, which costs no turn and reaches no rule. Adjacent, the
  /// armed spell is the named cast and the armed attack is the bump dispatch
  /// core always answered — the same [MoveAction] a blocked move is, swung
  /// from the dock now that the map refuses to swing. Beyond the action's
  /// targets, the walk sentence — log-only, the arm carried so the next tap
  /// keeps it.
  void _onStageCardTapped(StageCardTapped event, Emitter<GameViewState> emit) {
    if (state.game.isGameOver) return;
    final armed = state.armedAction;
    if (armed == null) return;
    final monster = event.monster;
    if (state.game.hero.position.isOrthogonallyAdjacentTo(monster.position)) {
      if (armed case ArmedSpell(spellId: final spellId)) {
        add(CastPressed(spellId, targetId: monster.id));
      } else {
        final direction = state.game.hero.position.directionTo(
          monster.position,
        );
        if (direction != null) emit(_afterAction(MoveAction(direction)));
      }
      return;
    }
    emit(
      GameViewState(
        game: state.game,
        log: [...state.log, _outOfReach(monster.name)],
        walkId: state.walkId,
        armedAction: state.armedAction,
      ),
    );
  }

  void _onDescendPressed(DescendPressed event, Emitter<GameViewState> emit) {
    if (state.game.isGameOver) return;
    emit(_afterAction(const DescendAction()));
  }

  void _onAscendPressed(AscendPressed event, Emitter<GameViewState> emit) {
    if (state.game.isGameOver) return;
    emit(_afterAction(const AscendAction()));
  }

  void _onPickUpPressed(PickUpPressed event, Emitter<GameViewState> emit) =>
      _act(const PickUpAction(), emit);

  void _onGatherPressed(GatherPressed event, Emitter<GameViewState> emit) =>
      _act(const GatherAction(), emit);

  void _onEquipPressed(EquipPressed event, Emitter<GameViewState> emit) =>
      _act(EquipAction(event.itemId), emit);

  void _onUnequipPressed(UnequipPressed event, Emitter<GameViewState> emit) =>
      _act(UnequipAction(event.slot), emit);

  void _onDrinkPressed(DrinkPressed event, Emitter<GameViewState> emit) =>
      _act(DrinkAction(event.itemId), emit);

  void _onDropPressed(DropPressed event, Emitter<GameViewState> emit) =>
      _act(DropAction(event.itemId), emit);

  void _onReadPressed(ReadPressed event, Emitter<GameViewState> emit) =>
      _act(ReadAction(event.itemId), emit);

  void _onCastPressed(CastPressed event, Emitter<GameViewState> emit) =>
      _act(CastSpellAction(event.spellId, targetId: event.targetId), emit);

  void _onQuickDrinkPressed(
    QuickDrinkPressed event,
    Emitter<GameViewState> emit,
  ) {
    final potion = state.firstPotion;
    if (potion == null) return;
    _act(DrinkAction(potion.id), emit);
  }

  /// Arms or disarms a skill without spending a turn.
  ///
  /// An aim is not a hero action: nothing steps, the walk in progress carries
  /// through, and the same state comes back with the aim named. [pan] is not
  /// carried — every handler but the pan's own resets the camera, and arming
  /// is no exception.
  void _onSkillArmed(SkillArmed event, Emitter<GameViewState> emit) => emit(
    GameViewState(
      game: state.game,
      log: state.log,
      autoPath: state.autoPath,
      walkId: state.walkId,
      armedAction: event.spellId == null ? null : ArmedSpell(event.spellId!),
    ),
  );

  /// Arms the attack, or puts it down when it is already the armed slot.
  ///
  /// One armed slot at a time: arming the attack disarms whatever spell held
  /// the slot, and nothing steps — an aim is not a hero action.
  void _onAttackArmed(AttackArmed event, Emitter<GameViewState> emit) => emit(
    GameViewState(
      game: state.game,
      log: state.log,
      autoPath: state.autoPath,
      walkId: state.walkId,
      armedAction: state.armedAction == const ArmedAttack()
          ? null
          : const ArmedAttack(),
    ),
  );

  /// Drags the view without spending a turn.
  ///
  /// A pan is not a hero action, so it carries the walk in progress through
  /// rather than cancelling it. The walk's next step then builds a fresh view
  /// state, which is what snaps the camera back.
  void _onMapPanned(MapPanned event, Emitter<GameViewState> emit) => emit(
    GameViewState(
      game: state.game,
      log: state.log,
      autoPath: state.autoPath,
      walkId: state.walkId,
      pan: state.pan + event.delta,
      armedAction: state.armedAction,
    ),
  );

  /// Walks off the edge of the road, which ends the fight.
  ///
  /// The direction comes from where the hero is standing, so this is the same
  /// outward step the rules already answer to — nothing new is decided here.
  /// Silent when the hero is not on the edge, because then the control is not on
  /// screen and the event is a press nobody made.
  void _onFleePressed(FleePressed event, Emitter<GameViewState> emit) {
    if (state.wayOut case final Direction out) _act(MoveAction(out), emit);
  }

  /// Holds ground for one turn, stopping any walk in progress first.
  ///
  /// Every control tap interrupts a walk; spending the turn is what [_act]
  /// already does to the arm and the path by building a fresh view state.
  void _onWaitPressed(WaitPressed event, Emitter<GameViewState> emit) {
    if (state.game.isGameOver) return;
    _act(const WaitAction(), emit);
  }

  /// Says where the way out is, and stops any walk in progress.
  ///
  /// **Leaving is the stairs or it is dying, and this is what keeps that true.**
  /// A pushed route pops on the system back button by default, which would have
  /// taken the player to town without ending the run: the town would show the
  /// profile that walked in while the save still held the crawl, and the next
  /// descent would bump the visit and write over it. That is progress lost
  /// through a door the design never opened, so the route declines the pop and
  /// the log explains why.
  ///
  /// A dead hero is told nothing, because the death overlay is already covering
  /// the screen with the one control that does work. A line about the stairs
  /// would be advice the player cannot take.
  void _onSystemBackPressed(
    SystemBackPressed event,
    Emitter<GameViewState> emit,
  ) {
    if (state.game.isGameOver) return;
    emit(
      GameViewState(
        game: state.game,
        log: [
          ...state.log,
          state.game.isEncounter ? _roadBackRefusal : _backRefusal,
        ],
        walkId: state.walkId + 1,
        armedAction: state.armedAction,
      ),
    );
  }

  /// Runs one loot action, cancelling any walk in progress first.
  ///
  /// Every loot control goes through here rather than calling [step] itself, so
  /// the rule that reaching into the pack interrupts a walk lives in exactly one
  /// place — and so does the rule that a dead hero does nothing.
  void _act(GameAction action, Emitter<GameViewState> emit) {
    if (state.game.isGameOver) return;
    final before = state.game;
    final (after, events) = step(before, action);
    emit(
      GameViewState(
        game: after,
        log: [...state.log, ..._describe(before, events)],
        walkId: state.walkId + 1,
        hasFled: events.contains(const Fled()),
      ),
    );
  }

  Future<void> _onAutoWalkAdvanced(
    AutoWalkAdvanced event,
    Emitter<GameViewState> emit,
  ) async {
    if (event.walkId != state.walkId || !state.isWalking) return;
    final game = state.game;
    final next = state.autoPath.first;
    if (game.isGameOver ||
        !game.map.isWalkable(next) ||
        game.monsterAt(next) != null) {
      emit(_stopWalking());
      return;
    }
    final direction = game.hero.position.directionTo(next);
    if (direction == null) {
      emit(_stopWalking());
      return;
    }

    final (after, events) = step(game, MoveAction(direction));
    final interrupted = _interrupts(events, after, game.hero.id);
    final remaining = state.autoPath.sublist(1);
    emit(
      GameViewState(
        game: after,
        log: [...state.log, ..._describe(game, events)],
        autoPath: interrupted ? const [] : remaining,
        walkId: interrupted ? state.walkId + 1 : state.walkId,
      ),
    );
    if (interrupted || remaining.isEmpty) return;
    await Future<void>.delayed(stepDelay);
    if (isClosed || state.walkId != event.walkId) return;
    add(AutoWalkAdvanced(event.walkId));
  }

  GameViewState _afterAction(GameAction action) {
    final before = state.game;
    final (after, events) = step(before, action);
    return GameViewState(
      game: after,
      log: [...state.log, ..._describe(before, events)],
      walkId: state.walkId,
      hasFled: events.contains(const Fled()),
    );
  }

  GameViewState _stopWalking() => GameViewState(
    game: state.game,
    log: state.log,
    walkId: state.walkId + 1,
    armedAction: state.armedAction,
  );

  Iterable<String> _describe(GameState before, List<GameEvent> events) {
    final names = namesIn(before);
    final afar = {
      for (final monster in before.monsters)
        if (monster.reach > 1 &&
            !monster.position.isOrthogonallyAdjacentTo(before.hero.position))
          monster.id,
    };
    final beat = _ambushBeat(before, events, names);
    final lines = <String>[];
    var beatPending = beat != null;
    for (final event in events) {
      final sentence = describeEvent(event, names, strikesFromAfar: afar);
      if (sentence == null) continue;
      if (beatPending && _isMonsterAttackOnHero(event)) {
        lines.add(beat!);
        beatPending = false;
      }
      lines.add(sentence);
    }
    return [...lines, ..._beats(before, events)];
  }

  /// The sentence that says the fight opened on the monster's terms, or null.
  ///
  /// **The detection rule is stateless, and its edge cases are its price.** The
  /// beat fires when a step's events carry a monster attack on the hero and
  /// the step's start state held no reach-holders — the fight opened because
  /// the monster struck first. A dodged swing counts (the monster still acted
  /// first), two monsters opening at once take one beat, and the hero's own
  /// bump-attack never fires it: the adjacent defender is a start-state reach
  /// holder by the snapshot rule. Two stateless mis-reads are accepted and
  /// documented: the hero's own closing move takes the opening swing and the
  /// beat — which reads true, the monster did strike first — and a paused
  /// chase that re-catches fires the beat mid-fight, which is the cost of not
  /// carrying a flag the rules never asked for.
  String? _ambushBeat(
    GameState before,
    List<GameEvent> events,
    Map<String, String> names,
  ) {
    if (!events.any(_isMonsterAttackOnHero)) return null;
    if (before.monsters.any((monster) => _holdsReachIn(before, monster))) {
      return null;
    }
    for (final event in events) {
      if (_isMonsterAttackOnHero(event)) {
        final attacker = switch (event) {
          AttackHit(:final attackerId) => attackerId,
          AttackDodged(:final attackerId) => attackerId,
          _ => null,
        };
        if (attacker == null) continue;
        return '${_capitalised(_nameOf(names, attacker))} gets the drop on you.';
      }
    }
    return null;
  }

  /// Whether [event] is a monster swinging at the hero, hit or miss.
  static bool _isMonsterAttackOnHero(GameEvent event) => switch (event) {
    AttackHit(:final attackerId, :final targetId) =>
      attackerId != heroId && targetId == heroId,
    AttackDodged(:final attackerId) => attackerId != heroId,
    _ => false,
  };

  /// Whether [monster] can strike a hero standing at the hero's tile in
  /// [game] — the engine's `_holdsReach`, mirrored on public state.
  static bool _holdsReachIn(GameState game, Actor monster) =>
      monster.position.isOrthogonallyAdjacentTo(game.hero.position) ||
      (monster.reach > 1 &&
          game.visible.contains(monster.position) &&
          monster.position.chebyshevTo(game.hero.position) <= monster.reach);

  static String _nameOf(Map<String, String> names, String id) =>
      names[id] ?? 'it';

  /// The lines a moment is worth, beyond the ones the rules described.
  ///
  /// **Composed here, and core knows nothing about any of it.** A boss is a
  /// content decision — the id prefix `boss-` is the whole of the contract the
  /// themed dungeons ship — and the bottom of a delve is a depth compared with a
  /// depth. Neither is a rule, so neither is an event: they are the
  /// `roadOpeningLog` shape, a sentence the interface says because the moment
  /// deserves one.
  ///
  /// The bottom line rides the descent rather than the floor, because a descent
  /// is the only way to reach a bottom floor for the first time. A hero walking
  /// back into a camp on that floor has already been told.
  Iterable<String> _beats(GameState before, List<GameEvent> events) {
    final names = namesIn(before);
    return [
      for (final event in events)
        if (event is ActorDied && event.actorId.startsWith(bossIdPrefix))
          '${_capitalised(names[event.actorId] ?? 'it')} is slain. '
              'The delve is yours.',
      for (final event in events)
        if (event is Descended && event.newDepth >= before.deepest)
          bottomOfTheDelve,
    ];
  }

  static String _capitalised(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  static bool _interrupts(
    List<GameEvent> events,
    GameState after,
    String heroId,
  ) =>
      after.isGameOver ||
      events.any(
        (event) =>
            event is ActorNoticed ||
            (event is AttackHit && event.targetId == heroId),
      );
}

/// What the log says when a walk will not start under a monster's eye.
///
/// A walk never starts in sight of anything; once it has started,
/// [ActorNoticed] is the single thing that stops it. The rule was always there
/// — until now it refused in silence, which read to the player as a dead tap
/// rather than a decision the game had made.
const String _watchedRefusal = 'Something is watching. You stay put.';

/// What a stage card says when its monster stands beyond one orthogonal step.
///
/// Names the monster and names the walk — the two things the player needs and
/// the two things the tap took away. Core is not told: the hero's position is
/// unchanged, the fight is unchanged, and the only fact added is the sentence
/// itself.
String _outOfReach(String name) => '$name is out of reach. Walk to it.';

/// What the log says when the system back button is pressed in the dungeon.
///
/// Phrased as where the exit *is* rather than as what the button is not, so a
/// player who pressed it by habit learns the rule instead of being told off.
const String _backRefusal = 'You can only leave at the stairs.';

/// What names a boss apart from anything else standing on a floor.
///
/// **Content's id scheme read as a contract, and it is the only one there is.**
/// A themed dungeon stands its boss up as `boss-<node>` and nothing else in the
/// game is named that way, so the prefix is what lets a beat know a captain from
/// a crab without core growing any idea of what a boss is. It is written here
/// rather than imported because the beat is the app's and the ids are content's,
/// and the one thing that must not happen is core learning the word.
const String bossIdPrefix = 'boss-';

/// What the log says on arriving where there is nothing below.
///
/// Said out loud because the map does not show it: a bottom floor looks like
/// every other floor until the player has walked it and found no stairs down.
const String bottomOfTheDelve = 'This is the bottom of the delve.';

/// What a road fight opens its log with.
///
/// Said out loud because it has to be learnt once and cannot be guessed: the
/// way out of a fight is the edge of the ground it is fought on, and nothing on
/// the screen shows an edge until the hero walks near one.
const String roadOpeningLog =
    'Something is on the road. Walk to any edge to get away, or stand and '
    'fight.';

/// What the log says when the system back button is pressed in a road fight.
///
/// A different sentence because a different door: there are no stairs on a road,
/// and the way out is any edge of the ground the hero is standing on.
const String _roadBackRefusal =
    'You can only leave by walking off the edge of the road.';
