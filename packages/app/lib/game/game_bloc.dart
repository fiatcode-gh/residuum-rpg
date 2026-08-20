import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'event_messages.dart';

sealed class GameBlocEvent {
  const GameBlocEvent();
}

final class GameStarted extends GameBlocEvent {
  const GameStarted({this.worldSeed = 1});

  final int worldSeed;
}

final class TileTapped extends GameBlocEvent {
  const TileTapped(this.position);

  final Position position;
}

final class DescendPressed extends GameBlocEvent {
  const DescendPressed();
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
  });

  final GameState game;
  final List<String> log;

  /// The tiles still to walk. Empty when the hero is not walking.
  final List<Position> autoPath;

  /// Bumped whenever a walk starts or stops.
  final int walkId;

  int get depth => game.depth;

  bool get isWalking => autoPath.isNotEmpty;

  bool get canDescend =>
      !game.isGameOver &&
      game.stairsDown != null &&
      game.hero.position == game.stairsDown;

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
    this.stepDelay = const Duration(milliseconds: 90),
  }) : super(
         GameViewState(
           game: game ?? newGame(worldSeed: worldSeed),
           log: const [],
         ),
       ) {
    on<GameStarted>(_onGameStarted);
    on<TileTapped>(_onTileTapped);
    on<DescendPressed>(_onDescendPressed);
    on<AutoWalkAdvanced>(_onAutoWalkAdvanced);
    on<PickUpPressed>(_onPickUpPressed);
    on<EquipPressed>(_onEquipPressed);
    on<UnequipPressed>(_onUnequipPressed);
    on<DrinkPressed>(_onDrinkPressed);
    on<DropPressed>(_onDropPressed);
    on<QuickDrinkPressed>(_onQuickDrinkPressed);
  }

  /// How long the hero pauses between tiles of a walk. Zero in tests.
  final Duration stepDelay;

  void _onGameStarted(GameStarted event, Emitter<GameViewState> emit) {
    emit(
      GameViewState(
        game: newGame(worldSeed: event.worldSeed),
        log: const [],
        walkId: state.walkId + 1,
      ),
    );
  }

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
    if (_somethingIsWatching(game)) return;
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

  /// Whether anything is already in sight. A walk never starts under a
  /// monster's eye; once it has started, [ActorNoticed] is the single thing
  /// that stops it for a monster, so that rule has exactly one home.
  static bool _somethingIsWatching(GameState game) =>
      game.monsters.any((monster) => game.visible.contains(monster.position));
}
