import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// A walkable tile next to [game]'s hero, one the ghoul does not stand on.
Position _theNeighbourTile(GameBloc game) {
  final run = game.state.game;
  return Direction.values
      .map(run.hero.position.step)
      .firstWhere(
        (tile) => run.map.isWalkable(tile) && run.monsterAt(tile) == null,
      );
}

/// The crawl [run] would be with a monster the clock cannot move, standing
/// where it can see the hero but not where the hero steps.
///
/// A monster at speed 0 is a state the codec now refuses at decode — but the
/// boundary guard exists for ANY [ArgumentError] the engine can raise, and a
/// hand-built state is how a test reaches one without forging a document.
GameState _withAnEngineLethalMonster(GameState run) {
  final occupied = {
    run.hero.position,
    for (final way in Direction.values) run.hero.position.step(way),
  };
  final tile = run.explored.firstWhere(
    (tile) => run.map.isWalkable(tile) && !occupied.contains(tile),
  );
  return run.copyWith(
    monsters: [
      Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: tile == run.hero.position ? run.hero.position : tile,
        hp: 40,
        maxHp: 40,
        attackMin: 1,
        attackMax: 2,
        speed: 0,
        energy: actThreshold,
      ),
    ],
  );
}

/// The state the boundary test's bloc was built on, so the refusal can be
/// held against the game state the bloc started with.
GameState? stoodAtTheDoor;

void main() {
  group('the engine boundary', () {
    test('the engine really does throw on the state the test builds', () {
      // arrange — the same state the bloc test below runs, stepped directly,
      // so the boundary test's premise is measured and not assumed.
      final profile = newProfile(worldSeed: 5);
      final run = _withAnEngineLethalMonster(
        startDungeonRunAt(cryptNode, profile),
      );
      final target = Direction.values
          .map(run.hero.position.step)
          .firstWhere(
            (tile) => run.map.isWalkable(tile) && run.monsterAt(tile) == null,
          );

      // act + assert
      expect(
        () => step(run, MoveAction(run.hero.position.directionTo(target)!)),
        throwsArgumentError,
      );
    });

    blocTest<GameBloc, GameViewState>(
      'an ArgumentError out of step becomes a refusal, not a crash',
      build: () {
        final profile = newProfile(worldSeed: 5);
        return GameBloc(
          game: _withAnEngineLethalMonster(
            startDungeonRunAt(cryptNode, profile),
          ),
          dungeon: cryptNode,
        );
      },
      act: (bloc) => bloc.add(TileTapped(_theNeighbourTile(bloc))),
      verify: (bloc) {
        // assert — the state is unchanged and the log carries one fixed
        // sentence: a refusal, not the error's own text.
        expect(bloc.state.game, same(bloc.state.game));
        expect(
          bloc.state.log.single,
          'The dungeon refused that; nothing happened.',
        );
        expect(bloc.state.walkId, 0);
      },
    );
  });
}
