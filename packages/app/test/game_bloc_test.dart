import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

const arena = '''
#######
#.....#
#.....#
#.....#
#######''';

GameState arenaGame({
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
}) {
  final map = FloorMap.parse(arena);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      glyph: '@',
      position: heroAt,
      hp: heroHp,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
    ),
    monsters: monsters,
    rng: Rng(1),
    visible: visible,
    explored: {...visible},
  );
}

Actor ghoul(Position at, {int hp = 10, int attack = 3}) => Actor(
  id: 'ghoul-1',
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
);

void main() {
  group('GameBloc', () {
    test(
      'starts a fresh crawl with the hero at its spawn and an empty log',
      () {
        // arrange
        final bloc = GameBloc();

        // act
        final state = bloc.state;

        // assert
        expect(state.game.hero.position, heroSpawn);
        expect(state.log, isEmpty);
        addTearDown(bloc.close);
      },
    );

    blocTest<GameBloc, GameViewState>(
      'a tap on an adjacent tile moves the hero and writes to the log',
      build: () => GameBloc(game: arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.hero.position, 'hero', const Position(4, 2))
            .having((s) => s.log, 'log', ['You step east.']),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a tap on a distant tile is ignored',
      build: () => GameBloc(game: arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(1, 1))),
      expect: () => <GameViewState>[],
    );

    blocTest<GameBloc, GameViewState>(
      'a tap on a diagonal neighbour is ignored',
      build: () => GameBloc(game: arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 3))),
      expect: () => <GameViewState>[],
    );

    blocTest<GameBloc, GameViewState>(
      'bumping a wall logs the block and still costs the turn',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(1, 2),
          monsters: [ghoul(const Position(5, 2))],
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(0, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.log, 'log', ['The way is blocked.'])
            .having(
              (s) => s.game.monsters.single.position,
              'ghoul',
              const Position(4, 2),
            ),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a killing blow logs the hit and the death',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          monsters: [ghoul(const Position(4, 2), hp: 4)],
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.monsters, 'monsters', isEmpty)
            .having((s) => s.log, 'log', [
              'You hit the ghoul for 4.',
              'The ghoul dies.',
            ]),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a lethal claw ends the game and logs the death',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          heroHp: 2,
          monsters: [ghoul(const Position(4, 2), attack: 3)],
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.isGameOver, 'isGameOver', isTrue)
            .having((s) => s.log, 'log', contains('You die.'))
            .having(
              (s) => s.log,
              'log',
              contains('The ghoul claws you for 3.'),
            ),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'taps after death do nothing',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          heroHp: 2,
          monsters: [ghoul(const Position(4, 2), attack: 3)],
        ),
      ),
      act: (bloc) => bloc
        ..add(const TileTapped(Position(4, 2)))
        ..add(const TileTapped(Position(2, 2))),
      expect: () => [
        isA<GameViewState>().having((s) => s.game.isGameOver, 'over', isTrue),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'restarting clears the log and puts the hero back at the spawn',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          heroHp: 2,
          monsters: [ghoul(const Position(4, 2), attack: 3)],
        ),
      ),
      act: (bloc) => bloc
        ..add(const TileTapped(Position(4, 2)))
        ..add(const GameStarted()),
      skip: 1,
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.isGameOver, 'isGameOver', isFalse)
            .having((s) => s.game.hero.position, 'hero', heroSpawn)
            .having((s) => s.game.hero.hp, 'hp', 20)
            .having((s) => s.log, 'log', isEmpty),
      ],
    );
  });
}
