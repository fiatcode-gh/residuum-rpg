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

void main() {
  group('the engine boundary', () {
    test(
      'an ArgumentError out of step becomes a refusal, not a crash',
      () async {
        // arrange — the hero stands next to a monster the clock cannot move, so
        // the first turn's schedule throws out of core.
        final profile = newProfile(worldSeed: 5);
        final game = GameBloc(
          game: _withAnEngineLethalMonster(
            startDungeonRunAt(cryptNode, profile),
          ),
          dungeon: cryptNode,
        );
        final before = game.state;

        // act — the first move the hero can make.
        game.add(TileTapped(_theNeighbourTile(game)));
        await game.stream.first;

        // assert — the state is unchanged and the log carries one fixed
        // sentence: a refusal, not the error's own text.
        expect(game.state.game, same(before.game));
        expect(game.state.walkId, before.walkId);
        expect(
          game.state.log.last,
          'The dungeon refused that; nothing happened.',
        );
        await game.close();
      },
    );
  });
}
