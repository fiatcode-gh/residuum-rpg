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

/// Drink the first potion the hero is carrying, so the common case is one tap.
final class QuickDrinkPressed extends GameBlocEvent {
  const QuickDrinkPressed();
}

/// The player dragged the map by [delta].
final class MapPanned extends GameBlocEvent {
  const MapPanned(this.delta);

  final Offset delta;
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

  int get depth => game.depth;

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

  /// What is lying under the hero, oldest first.
  List<Item> get itemsUnderfoot => game.itemsAt(game.hero.position);

  bool get canPickUp =>
      !game.isGameOver &&
      itemsUnderfoot.isNotEmpty &&
      game.inventory.length < inventoryCap;

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
    this.stepDelay = const Duration(milliseconds: 90),
  }) : super(
         GameViewState(
           game: game ?? newGame(worldSeed: worldSeed),
           log: log,
         ),
       ) {
    on<TileTapped>(_onTileTapped);
    on<DescendPressed>(_onDescendPressed);
    on<AscendPressed>(_onAscendPressed);
    on<AutoWalkAdvanced>(_onAutoWalkAdvanced);
    on<PickUpPressed>(_onPickUpPressed);
    on<EquipPressed>(_onEquipPressed);
    on<UnequipPressed>(_onUnequipPressed);
    on<DrinkPressed>(_onDrinkPressed);
    on<DropPressed>(_onDropPressed);
    on<QuickDrinkPressed>(_onQuickDrinkPressed);
    on<MapPanned>(_onMapPanned);
    on<SystemBackPressed>(_onSystemBackPressed);
    on<FleePressed>(_onFleePressed);
  }

  /// How long the hero pauses between tiles of a walk. Zero in tests.
  final Duration stepDelay;

  void _onTileTapped(TileTapped event, Emitter<GameViewState> emit) {
    final game = state.game;
    if (game.isGameOver) return;
    if (state.isWalking) {
      emit(_stopWalking());
      return;
    }
    final direction = game.hero.position.directionTo(event.position);
    if (direction != null) {
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
        ),
      );
      return;
    }
    final path = findPath(game.map, game.hero.position, event.position);
    if (path.isEmpty) return;
    final walkId = state.walkId + 1;
    emit(
      GameViewState(game: game, log: state.log, autoPath: path, walkId: walkId),
    );
    add(AutoWalkAdvanced(walkId));
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

  void _onEquipPressed(EquipPressed event, Emitter<GameViewState> emit) =>
      _act(EquipAction(event.itemId), emit);

  void _onUnequipPressed(UnequipPressed event, Emitter<GameViewState> emit) =>
      _act(UnequipAction(event.slot), emit);

  void _onDrinkPressed(DrinkPressed event, Emitter<GameViewState> emit) =>
      _act(DrinkAction(event.itemId), emit);

  void _onDropPressed(DropPressed event, Emitter<GameViewState> emit) =>
      _act(DropAction(event.itemId), emit);

  void _onQuickDrinkPressed(
    QuickDrinkPressed event,
    Emitter<GameViewState> emit,
  ) {
    final potion = state.firstPotion;
    if (potion == null) return;
    _act(DrinkAction(potion.id), emit);
  }

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

  GameViewState _stopWalking() =>
      GameViewState(game: state.game, log: state.log, walkId: state.walkId + 1);

  Iterable<String> _describe(GameState before, List<GameEvent> events) {
    final names = namesIn(before);
    return events
        .map((event) => describeEvent(event, names))
        .whereType<String>();
  }

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

/// What the log says when the system back button is pressed in the dungeon.
///
/// Phrased as where the exit *is* rather than as what the button is not, so a
/// player who pressed it by habit learns the rule instead of being told off.
const String _backRefusal = 'You can only leave at the stairs.';

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
