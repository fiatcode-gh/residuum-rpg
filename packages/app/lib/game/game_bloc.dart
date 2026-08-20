import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'event_messages.dart';

sealed class GameBlocEvent {
  const GameBlocEvent();
}

final class GameStarted extends GameBlocEvent {
  const GameStarted({this.seed = 1});

  final int seed;
}

final class TileTapped extends GameBlocEvent {
  const TileTapped(this.position);

  final Position position;
}

class GameViewState {
  const GameViewState({required this.game, required this.log});

  final GameState game;
  final List<String> log;
}

class GameBloc extends Bloc<GameBlocEvent, GameViewState> {
  GameBloc({GameState? game, int seed = 1})
    : super(
        GameViewState(
          game: game ?? newGame(seed: seed),
          log: const [],
        ),
      ) {
    on<GameStarted>(_onGameStarted);
    on<TileTapped>(_onTileTapped);
  }

  void _onGameStarted(GameStarted event, Emitter<GameViewState> emit) {
    emit(
      GameViewState(
        game: newGame(seed: event.seed),
        log: const [],
      ),
    );
  }

  void _onTileTapped(TileTapped event, Emitter<GameViewState> emit) {
    final game = state.game;
    if (game.isGameOver) return;
    final direction = game.hero.position.directionTo(event.position);
    if (direction == null) return;
    final (next, events) = step(game, MoveAction(direction));
    emit(
      GameViewState(
        game: next,
        log: [...state.log, ...events.map(describeEvent).whereType<String>()],
      ),
    );
  }
}
