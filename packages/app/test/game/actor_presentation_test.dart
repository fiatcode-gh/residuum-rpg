import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/actor_presentation.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
##########
#........#
#........#
#........#
##########''';

Floor _noFloorBelow(int depth) =>
    throw StateError('this fixture has no adjacent floor');

Actor _actor(
  String id,
  Position position, {
  String name = 'the ghoul',
  int hp = 10,
}) => Actor(
  id: id,
  name: name,
  glyph: 'g',
  position: position,
  hp: hp,
  maxHp: 10,
  attackMin: 1,
  attackMax: 1,
  speed: 10,
  energy: actThreshold,
);

GameState _game({required List<Actor> monsters, Set<Position>? visible}) {
  final map = FloorMap.parse(_arena);
  final heroPosition = const Position(1, 1);
  final seen =
      visible ??
      {heroPosition, for (final monster in monsters) monster.position};
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroPosition,
      hp: 20,
      maxHp: 20,
      attackMin: 1,
      attackMax: 1,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: seen,
    explored: seen,
    buildFloor: _noFloorBelow,
  );
}

void main() {
  test(
    'allocates duplicate ordinals by initial group order, not actor ids',
    () {
      final game = _game(
        monsters: [
          _actor('ghoul-b', const Position(2, 1)),
          _actor('spitter', const Position(3, 1), name: 'the spitter'),
          _actor('ghoul-a', const Position(4, 1)),
        ],
      );

      final context = ActorIdentityContext.fromGame(game);

      expect(context['ghoul-b']?.displayName, 'the ghoul¹');
      expect(context['ghoul-b']?.glyphLabel, 'g¹');
      expect(context['ghoul-a']?.displayName, 'the ghoul²');
      expect(context['ghoul-a']?.glyphLabel, 'g²');
      expect(context['spitter']?.displayName, 'the spitter');
      expect(context['spitter']?.badge, isNull);
    },
  );

  test('keeps the first duplicate unbadged until the second is noticed', () {
    final game = _game(
      monsters: [
        _actor('ghoul-b', const Position(2, 1)),
        _actor('ghoul-a', const Position(8, 3)),
      ],
      visible: {const Position(1, 1), const Position(2, 1)},
    );
    final context = ActorIdentityContext.fromGame(game);

    expect(context.knownActors.keys, ['ghoul-b']);
    expect(context['ghoul-b']?.displayName, 'the ghoul');
    expect(context['ghoul-a'], isNull);

    final revealed = context.noticeAll(['ghoul-a']);

    expect(revealed['ghoul-b']?.displayName, 'the ghoul¹');
    expect(revealed['ghoul-a']?.displayName, 'the ghoul²');
    expect(revealed['ghoul-b']?.glyphLabel, 'g¹');
    expect(revealed['ghoul-a']?.glyphLabel, 'g²');
  });

  test('keeps a survivor ordinal through an actual state removal', () async {
    final bloc = GameBloc(
      game: _game(
        monsters: [
          _actor('ghoul-1', const Position(1, 2), hp: 1),
          _actor('ghoul-2', const Position(2, 1)),
        ],
      ),
      stepDelay: Duration.zero,
    );
    addTearDown(bloc.close);

    expect(bloc.state.presentationOf('ghoul-2')?.displayName, 'the ghoul²');
    expect(bloc.state.presentationOf('ghoul-2')?.glyphLabel, 'g²');

    final afterRemoval = bloc.stream.first;
    bloc.add(const TileTapped(Position(1, 2)));
    await afterRemoval;

    expect(bloc.state.game.monsters.map((actor) => actor.id), ['ghoul-2']);
    expect(bloc.state.presentationOf('ghoul-2')?.displayName, 'the ghoul²');
    expect(bloc.state.presentationOf('ghoul-2')?.glyphLabel, 'g²');
  });

  test('encodes every digit in ordinals of ten or more', () {
    final monsters = [
      for (var index = 0; index < 10; index++)
        _actor('ghoul-$index', Position(index % 8 + 1, index ~/ 8 + 1)),
    ];

    final context = ActorIdentityContext.fromGame(_game(monsters: monsters));

    expect(context['ghoul-9']?.displayName, 'the ghoul¹⁰');
    expect(context['ghoul-9']?.glyphLabel, 'g¹⁰');
  });

  test('does not expose unallocated noticed ids or raw names', () {
    final context = ActorIdentityContext.fromGame(
      _game(monsters: [_actor('ghoul-1', const Position(2, 1))]),
    );

    final noticed = context.noticeAll(['unknown-actor']);
    final names = noticed.eventNames(_game(monsters: const []).hero);

    expect(noticed['unknown-actor'], isNull);
    expect(noticed.knownActors.keys, ['ghoul-1']);
    expect(names, {'hero': 'you', 'ghoul-1': 'the ghoul'});
    expect(names.containsKey('unknown-actor'), isFalse);
  });

  test('keeps the public known actor map unmodifiable', () {
    final context = ActorIdentityContext.fromGame(
      _game(monsters: [_actor('ghoul-1', const Position(2, 1))]),
    );

    expect(() => context.knownActors.clear(), throwsUnsupportedError);
  });
}
