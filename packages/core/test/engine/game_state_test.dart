import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Floor _noFloorBelow(int depth) =>
    throw StateError('this crawl was not meant to descend');

void main() {
  group('Actor', () {
    test('is alive while it has hit points', () {
      // arrange
      const actor = Actor(
        id: 'hero',
        name: 'you',
        glyph: '@',
        position: Position(1, 1),
        hp: 1,
        maxHp: 20,
        attackMin: 3,
        attackMax: 5,
        speed: 10,
        energy: actThreshold,
      );

      // act
      final alive = actor.isAlive;
      final dead = actor.copyWith(hp: 0).isAlive;

      // assert
      expect(alive, isTrue);
      expect(dead, isFalse);
    });

    test('copyWith keeps every untouched field', () {
      // arrange
      const actor = Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: Position(4, 4),
        hp: 10,
        maxHp: 10,
        attackMin: 2,
        attackMax: 4,
        speed: 10,
        energy: actThreshold,
      );

      // act
      final moved = actor.copyWith(position: const Position(5, 4));

      // assert
      expect(moved.id, 'ghoul-1');
      expect(moved.glyph, 'g');
      expect(moved.hp, 10);
      expect(moved.maxHp, 10);
      expect(moved.attackMin, 2);
      expect(moved.attackMax, 4);
      expect(moved.position, const Position(5, 4));
    });

    test('carries a display name, a speed and an energy pool', () {
      // arrange
      const actor = Actor(
        id: 'wolf-1',
        name: 'the dire wolf',
        glyph: 'w',
        position: Position(4, 4),
        hp: 8,
        maxHp: 8,
        attackMin: 2,
        attackMax: 3,
        speed: 20,
        energy: actThreshold,
      );

      // act
      final spent = actor.copyWith(energy: actor.energy - actCost);

      // assert
      expect(
        (actor.name, actor.speed, actor.energy),
        ('the dire wolf', 20, 100),
      );
      expect((spent.name, spent.speed, spent.energy), ('the dire wolf', 20, 0));
    });
  });

  group('GameEvent', () {
    test('events are value objects', () {
      // arrange
      const moved = ActorMoved(
        actorId: 'hero',
        from: Position(1, 1),
        to: Position(1, 2),
      );

      // act
      final events = <GameEvent>[
        const ActorMoved(
          actorId: 'hero',
          from: Position(1, 1),
          to: Position(1, 2),
        ),
        const AttackHit(attackerId: 'hero', targetId: 'ghoul-1', damage: 4),
        const MoveBlocked(actorId: 'hero', at: Position(0, 1)),
        const ActorDied(actorId: 'ghoul-1'),
        const GameOver(),
      ];

      // assert
      expect(events, contains(moved));
      expect(
        events,
        contains(
          const AttackHit(attackerId: 'hero', targetId: 'ghoul-1', damage: 4),
        ),
      );
      expect(
        events,
        contains(const MoveBlocked(actorId: 'hero', at: Position(0, 1))),
      );
      expect(events, contains(const ActorDied(actorId: 'ghoul-1')));
      expect(events, contains(const GameOver()));
      expect(moved.hashCode, events.first.hashCode);
    });

    test('events with different fields are not equal', () {
      // arrange
      const one = AttackHit(attackerId: 'hero', targetId: 'ghoul-1', damage: 4);

      // act
      const another = AttackHit(
        attackerId: 'hero',
        targetId: 'ghoul-1',
        damage: 5,
      );

      // assert
      expect(one, isNot(another));
    });
  });

  group('GameState', () {
    test('finds the monster standing on a tile', () {
      // arrange
      final state = GameState(
        map: FloorMap.parse('###\n#.#\n###'),
        hero: const Actor(
          id: 'hero',
          name: 'you',
          glyph: '@',
          position: Position(1, 1),
          hp: 20,
          maxHp: 20,
          attackMin: 3,
          attackMax: 5,
          speed: 10,
          energy: actThreshold,
        ),
        monsters: const [
          Actor(
            id: 'ghoul-1',
            name: 'the ghoul',
            glyph: 'g',
            position: Position(2, 1),
            hp: 10,
            maxHp: 10,
            attackMin: 2,
            attackMax: 4,
            speed: 10,
            energy: actThreshold,
          ),
        ],
        rng: Rng(1),
        buildFloor: _noFloorBelow,
        visible: {const Position(1, 1)},
        explored: {const Position(1, 1)},
      );

      // act
      final found = state.monsterAt(const Position(2, 1));
      final empty = state.monsterAt(const Position(1, 1));

      // assert
      expect(found?.id, 'ghoul-1');
      expect(empty, isNull);
    });

    test('copyWith changes only the given fields', () {
      // arrange
      final map = FloorMap.parse('###\n#.#\n###');
      const hero = Actor(
        id: 'hero',
        name: 'you',
        glyph: '@',
        position: Position(1, 1),
        hp: 20,
        maxHp: 20,
        attackMin: 3,
        attackMax: 5,
        speed: 10,
        energy: actThreshold,
      );
      const monsters = <Actor>[
        Actor(
          id: 'ghoul-1',
          name: 'the ghoul',
          glyph: 'g',
          position: Position(2, 1),
          hp: 10,
          maxHp: 10,
          attackMin: 2,
          attackMax: 4,
          speed: 10,
          energy: actThreshold,
        ),
      ];
      final rng = Rng(1);
      final visible = {const Position(1, 1)};
      final explored = {const Position(1, 1)};
      final state = GameState(
        map: map,
        hero: hero,
        monsters: monsters,
        rng: rng,
        buildFloor: _noFloorBelow,
        visible: visible,
        explored: explored,
      );
      const movedHero = Actor(
        id: 'hero',
        name: 'you',
        glyph: '@',
        position: Position(2, 2),
        hp: 20,
        maxHp: 20,
        attackMin: 3,
        attackMax: 5,
        speed: 10,
        energy: actThreshold,
      );

      // act
      final next = state.copyWith(hero: movedHero);

      // assert
      expect(next.hero, movedHero);
      expect(next.map, map);
      expect(next.monsters, monsters);
      expect(next.rng, rng);
      expect(next.visible, visible);
      expect(next.explored, explored);
      expect(next.isGameOver, isFalse);
    });

    test(
      'defensively copies the monsters, visible and explored collections',
      () {
        // arrange
        final mutableMonsters = <Actor>[
          const Actor(
            id: 'ghoul-1',
            name: 'the ghoul',
            glyph: 'g',
            position: Position(2, 1),
            hp: 10,
            maxHp: 10,
            attackMin: 2,
            attackMax: 4,
            speed: 10,
            energy: actThreshold,
          ),
        ];
        final state = GameState(
          map: FloorMap.parse('###\n#.#\n###'),
          hero: const Actor(
            id: 'hero',
            name: 'you',
            glyph: '@',
            position: Position(1, 1),
            hp: 20,
            maxHp: 20,
            attackMin: 3,
            attackMax: 5,
            speed: 10,
            energy: actThreshold,
          ),
          monsters: mutableMonsters,
          rng: Rng(1),
          buildFloor: _noFloorBelow,
          visible: {const Position(1, 1)},
          explored: {const Position(1, 1)},
        );

        // act
        mutableMonsters.add(
          const Actor(
            id: 'ghoul-2',
            name: 'the ghoul',
            glyph: 'g',
            position: Position(1, 2),
            hp: 5,
            maxHp: 5,
            attackMin: 1,
            attackMax: 2,
            speed: 10,
            energy: actThreshold,
          ),
        );

        // assert
        expect(state.monsters, hasLength(1));
      },
    );
  });
}
