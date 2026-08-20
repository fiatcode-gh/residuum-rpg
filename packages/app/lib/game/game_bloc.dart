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
