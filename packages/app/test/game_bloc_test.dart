import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_core/core.dart';

const arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const twoRooms = '''
##############
#.....#......#
#.....#......#
#..........>.#
#.....#......#
##############''';

Floor _noFloorBelow(int depth) =>
    throw StateError('this crawl was not meant to descend');

Floor deeperFloor(int depth) => Floor(
  map: FloorMap.parse(arena),
  heroSpawn: const Position(1, 1),
  monsters: const [],
  stairsDown: depth >= deepestDepth ? null : const Position(5, 3),
);

Set<Position> everywhereIn(String ascii) {
  final map = FloorMap.parse(ascii);
  return {
    for (var y = 0; y < map.height; y++)
      for (var x = 0; x < map.width; x++) Position(x, y),
  };
}

GameState arenaGame({
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
  String ascii = arena,
  int depth = 1,
  Position? stairsDown,
  FloorBuilder buildFloor = _noFloorBelow,
  Set<Position>? explored,
}) {
  final map = FloorMap.parse(ascii);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: heroHp,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: monsters,
    rng: Rng(1),
    buildFloor: buildFloor,
    visible: visible,
    explored: explored ?? {...visible},
    depth: depth,
    stairsDown: stairsDown,
  );
}

Actor ghoul(Position at, {int hp = 10, int attack = 3, int speed = 10}) =>
    Actor(
      id: 'ghoul-1',
      name: 'the ghoul',
      glyph: 'g',
      position: at,
      hp: hp,
      maxHp: 10,
      attackMin: attack,
      attackMax: attack,
      speed: speed,
      energy: actThreshold,
    );

GameBloc walker(GameState game) =>
    GameBloc(game: game, stepDelay: Duration.zero);

void main() {
  group('GameBloc', () {
    test('starts a fresh crawl on depth one with an empty log', () {
      // arrange
      final bloc = GameBloc();

      // act
      final state = bloc.state;

      // assert
      expect(state.depth, 1);
      expect(state.game.map.isWalkable(state.game.hero.position), isTrue);
      expect(state.log, isEmpty);
      expect(state.isWalking, isFalse);
      addTearDown(bloc.close);
    });

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
      'a tap on an unexplored tile does nothing',
      build: () => walker(
        arenaGame(
          heroAt: const Position(1, 1),
          explored: {const Position(1, 1)},
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(5, 3))),
      expect: () => <GameViewState>[],
    );

    blocTest<GameBloc, GameViewState>(
      'a tap on a wall does nothing',
      build: () => walker(arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(0, 0))),
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
      'restarting clears the log and starts a fresh crawl on depth one',
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
            .having((s) => s.depth, 'depth', 1)
            .having((s) => s.game.hero.hp, 'hp', 20)
            .having((s) => s.log, 'log', isEmpty),
      ],
    );
  });

  group('GameBloc auto-walk', () {
    blocTest<GameBloc, GameViewState>(
      'a tap on a distant explored tile walks the hero all the way there',
      build: () => walker(arenaGame(heroAt: const Position(1, 1))),
      act: (bloc) => bloc.add(const TileTapped(Position(5, 3))),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.game.hero.position, const Position(5, 3));
        expect(bloc.state.isWalking, isFalse);
      },
    );

    blocTest<GameBloc, GameViewState>(
      'a tap on a diagonal neighbour walks the two steps',
      build: () => walker(arenaGame(heroAt: const Position(3, 2))),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 3))),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) =>
          expect(bloc.state.game.hero.position, const Position(4, 3)),
    );

    blocTest<GameBloc, GameViewState>(
      'a monster coming into view stops the walk where it stands',
      build: () => walker(
        arenaGame(
          ascii: twoRooms,
          heroAt: const Position(1, 1),
          monsters: [ghoul(const Position(12, 1))],
          explored: everywhereIn(twoRooms),
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(12, 4))),
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.isWalking, isFalse);
        expect(bloc.state.game.hero.position, isNot(const Position(12, 4)));
        expect(bloc.state.log.last, 'The ghoul comes into view.');
      },
    );

    blocTest<GameBloc, GameViewState>(
      'a walk does not start while a monster is already in view',
      build: () => walker(
        arenaGame(
          heroAt: const Position(1, 1),
          monsters: [ghoul(const Position(5, 3))],
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(5, 1))),
      expect: () => <GameViewState>[],
    );

    blocTest<GameBloc, GameViewState>(
      'a tap during a walk cancels it and does nothing else',
      build: () => walker(arenaGame(heroAt: const Position(1, 1))),
      act: (bloc) {
        bloc.add(const TileTapped(Position(5, 3)));
        bloc.add(const TileTapped(Position(1, 3)));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.isWalking, isFalse);
        expect(bloc.state.game.hero.position, isNot(const Position(5, 3)));
      },
    );

    blocTest<GameBloc, GameViewState>(
      'a walk stops short of its destination when something intercepts it',
      build: () => walker(
        arenaGame(
          ascii: twoRooms,
          heroAt: const Position(1, 3),
          monsters: [ghoul(const Position(12, 3), speed: 20)],
          explored: everywhereIn(twoRooms),
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(12, 4))),
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.isWalking, isFalse);
        expect(bloc.state.game.hero.position, isNot(const Position(12, 4)));
      },
    );
  });

  group('GameBloc descending', () {
    blocTest<GameBloc, GameViewState>(
      'the descend button only offers itself on the stairs',
      build: () => walker(
        arenaGame(
          ascii: twoRooms,
          heroAt: const Position(1, 1),
          stairsDown: const Position(11, 3),
          buildFloor: deeperFloor,
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(2, 1))),
      verify: (bloc) => expect(bloc.state.canDescend, isFalse),
    );

    blocTest<GameBloc, GameViewState>(
      'descending on the stairs deepens the crawl and says so',
      build: () => walker(
        arenaGame(
          ascii: twoRooms,
          heroAt: const Position(11, 3),
          stairsDown: const Position(11, 3),
          buildFloor: deeperFloor,
        ),
      ),
      act: (bloc) => bloc.add(const DescendPressed()),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.depth, 'depth', 2)
            .having((s) => s.game.hero.position, 'hero', const Position(1, 1))
            .having((s) => s.log, 'log', ['You descend to depth 2.']),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'descending off the stairs is blocked, not silently swallowed',
      build: () => walker(
        arenaGame(
          ascii: twoRooms,
          heroAt: const Position(1, 1),
          stairsDown: const Position(11, 3),
          buildFloor: deeperFloor,
        ),
      ),
      act: (bloc) => bloc.add(const DescendPressed()),
      expect: () => [
        isA<GameViewState>().having((s) => s.depth, 'depth', 1).having(
          (s) => s.log,
          'log',
          ['The way is blocked.'],
        ),
      ],
    );

    test('the deepest floor offers no descent', () {
      // arrange
      final bloc = walker(
        arenaGame(heroAt: const Position(1, 1), depth: deepestDepth),
      );

      // act
      final canDescend = bloc.state.canDescend;

      // assert
      expect(canDescend, isFalse);
      addTearDown(bloc.close);
    });
  });
}
