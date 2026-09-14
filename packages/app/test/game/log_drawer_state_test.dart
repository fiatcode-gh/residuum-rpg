import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/event_messages.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/log_line.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

GameState _game({
  required Position heroAt,
  List<Actor> monsters = const [],
  int heroHp = 20,
}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: heroId,
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
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

Actor _ghoul(Position at, {String id = 'ghoul-1', int attack = 3}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: attack,
  attackMax: attack,
  speed: 10,
  energy: actThreshold,
);

const _heroAt = Position(2, 2);
const _adjacentToHero = Position(3, 2);

void main() {
  group('a fresh drawer', () {
    test('starts at peek, following, with nothing unread', () {
      // arrange
      final bloc = GameBloc(game: _game(heroAt: _heroAt));
      addTearDown(bloc.close);

      // assert
      expect(bloc.state.logDrawerExtent, LogDrawerExtent.peek);
      expect(bloc.state.logFollowing, isTrue);
      expect(bloc.state.logUnread, 0);
    });
  });

  group('the handle and the close affordance', () {
    blocTest<GameBloc, GameViewState>(
      'the handle cycles peek, half, full, then back to peek',
      build: () => GameBloc(game: _game(heroAt: _heroAt)),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled()),
      expect: () => [
        isA<GameViewState>().having(
          (s) => s.logDrawerExtent,
          'extent',
          LogDrawerExtent.half,
        ),
        isA<GameViewState>().having(
          (s) => s.logDrawerExtent,
          'extent',
          LogDrawerExtent.full,
        ),
        isA<GameViewState>().having(
          (s) => s.logDrawerExtent,
          'extent',
          LogDrawerExtent.peek,
        ),
        isA<GameViewState>().having(
          (s) => s.logDrawerExtent,
          'extent',
          LogDrawerExtent.half,
        ),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'closing collapses from anywhere, and a second close at peek is silent',
      build: () => GameBloc(game: _game(heroAt: _heroAt)),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerClosed())
        ..add(const LogDrawerClosed()),
      expect: () => [
        isA<GameViewState>().having(
          (s) => s.logDrawerExtent,
          'extent',
          LogDrawerExtent.half,
        ),
        isA<GameViewState>().having(
          (s) => s.logDrawerExtent,
          'extent',
          LogDrawerExtent.full,
        ),
        isA<GameViewState>().having(
          (s) => s.logDrawerExtent,
          'extent',
          LogDrawerExtent.peek,
        ),
      ],
    );
  });

  group('criterion 7: a drawer interaction spends no turn and mutates '
      'nothing', () {
    final seededGame = _game(heroAt: _heroAt);
    const seededLog = [
      LogLine('Something is on the road.', LogCategory.noticed),
    ];
    const seededPan = Offset(12, 4);
    const seededAutoPath = [Position(3, 2), Position(4, 2)];
    const seededWalkId = 3;
    const seededArmed = 'firebolt';
    const seededSelected = 'ghoul-1';

    blocTest<GameBloc, GameViewState>(
      'the drawer handle, follow-broken and close events all carry pan, '
      'the walk, the arm, the selection and the game and log references '
      'through unchanged',
      build: () => GameBloc(game: seededGame),
      seed: () => GameViewState(
        game: seededGame,
        log: seededLog,
        autoPath: seededAutoPath,
        walkId: seededWalkId,
        pan: seededPan,
        armedSpellId: seededArmed,
        selectedActorId: seededSelected,
      ),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogFollowBroken())
        ..add(const LogDrawerClosed()),
      expect: () => [
        for (var i = 0; i < 3; i++)
          isA<GameViewState>()
              .having((s) => s.game, 'game', same(seededGame))
              .having((s) => s.log, 'log', same(seededLog))
              .having((s) => s.pan, 'pan', seededPan)
              .having((s) => s.autoPath, 'autoPath', same(seededAutoPath))
              .having((s) => s.walkId, 'walkId', seededWalkId)
              .having((s) => s.armedSpellId, 'armedSpellId', seededArmed)
              .having(
                (s) => s.selectedActorId,
                'selectedActorId',
                seededSelected,
              ),
      ],
    );
  });

  group('criteria 5 and 6: follow and the unread count', () {
    blocTest<GameBloc, GameViewState>(
      'follow holds: an arriving line stays visible and nothing '
      'accumulates',
      build: () => GameBloc(game: _game(heroAt: _heroAt)),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const WaitPressed()),
      verify: (bloc) {
        expect(bloc.state.logDrawerExtent, LogDrawerExtent.half);
        expect(bloc.state.logFollowing, isTrue);
        expect(bloc.state.logUnread, 0);
        expect(bloc.state.log.length, 1);
      },
    );

    blocTest<GameBloc, GameViewState>(
      'follow off: the count is the exact number appended, never the log '
      'length',
      build: () => GameBloc(
        game: _game(heroAt: _heroAt),
        log: const [LogLine('Something is on the road.', LogCategory.noticed)],
      ),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogFollowBroken())
        ..add(const WaitPressed())
        ..add(const WaitPressed()),
      verify: (bloc) {
        expect(bloc.state.logFollowing, isFalse);
        expect(bloc.state.logUnread, 2);
        expect(bloc.state.log.length, greaterThan(bloc.state.logUnread));
      },
    );

    blocTest<GameBloc, GameViewState>(
      'resuming clears the count; a second resume is silent',
      build: () => GameBloc(game: _game(heroAt: _heroAt)),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogFollowBroken())
        ..add(const WaitPressed())
        ..add(const LogFollowResumed())
        ..add(const LogFollowResumed()),
      expect: () => List.filled(4, isA<GameViewState>()),
      verify: (bloc) {
        expect(bloc.state.logFollowing, isTrue);
        expect(bloc.state.logUnread, 0);
      },
    );

    blocTest<GameBloc, GameViewState>(
      'closing while follow is off resumes follow and clears the count',
      build: () => GameBloc(game: _game(heroAt: _heroAt)),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled())
        ..add(const LogFollowBroken())
        ..add(const WaitPressed())
        ..add(const LogDrawerClosed()),
      verify: (bloc) {
        expect(bloc.state.logDrawerExtent, LogDrawerExtent.peek);
        expect(bloc.state.logFollowing, isTrue);
        expect(bloc.state.logUnread, 0);
      },
    );

    blocTest<GameBloc, GameViewState>(
      'cycling the handle back to peek also resumes follow and clears the '
      'count',
      build: () => GameBloc(game: _game(heroAt: _heroAt)),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled())
        ..add(const LogFollowBroken())
        ..add(const WaitPressed())
        ..add(const LogDrawerHandlePulled()),
      verify: (bloc) {
        expect(bloc.state.logDrawerExtent, LogDrawerExtent.peek);
        expect(bloc.state.logFollowing, isTrue);
        expect(bloc.state.logUnread, 0);
      },
    );

    blocTest<GameBloc, GameViewState>(
      'a turn does not close the drawer or resume follow',
      build: () => GameBloc(game: _game(heroAt: _heroAt)),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled())
        ..add(const LogFollowBroken())
        ..add(const WaitPressed()),
      verify: (bloc) {
        expect(bloc.state.logDrawerExtent, LogDrawerExtent.full);
        expect(bloc.state.logFollowing, isFalse);
      },
    );
  });

  group('criterion 8: death collapses and inerts the drawer', () {
    blocTest<GameBloc, GameViewState>(
      'a lethal turn collapses the drawer, resumes follow, clears the '
      'count, and the handle stops responding',
      build: () => GameBloc(
        game: _game(
          heroAt: _heroAt,
          heroHp: 2,
          monsters: [_ghoul(_adjacentToHero)],
        ),
      ),
      act: (bloc) => bloc
        ..add(const LogDrawerHandlePulled())
        ..add(const LogDrawerHandlePulled())
        ..add(const LogFollowBroken())
        ..add(const TileTapped(_adjacentToHero))
        ..add(const LogDrawerHandlePulled()),
      expect: () => [
        isA<GameViewState>(),
        isA<GameViewState>(),
        isA<GameViewState>(),
        isA<GameViewState>()
            .having((s) => s.game.isGameOver, 'isGameOver', isTrue)
            .having((s) => s.logDrawerExtent, 'extent', LogDrawerExtent.peek)
            .having((s) => s.logFollowing, 'following', isTrue)
            .having((s) => s.logUnread, 'unread', 0),
      ],
    );
  });

  group('the invariant is unconditional', () {
    test('holds for a state built directly, not only through a handler', () {
      // arrange
      final over = _game(heroAt: _heroAt).copyWith(isGameOver: true);

      // act
      final state = GameViewState(
        game: over,
        log: const [],
        logDrawerExtent: LogDrawerExtent.full,
        logFollowing: false,
        logUnread: 5,
      );

      // assert
      expect(state.logDrawerExtent, LogDrawerExtent.peek);
      expect(state.logFollowing, isTrue);
      expect(state.logUnread, 0);
    });
  });
}
