import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
#######
#.....#
#.....#
#######''';

Floor _noFloorBelow(int depth) =>
    throw StateError('this crawl was not meant to descend');

const _hero = Actor(
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

GameState _game({Map<String, Spell> spells = const {}}) => GameState(
  map: FloorMap.parse(_room),
  hero: _hero,
  monsters: const [],
  rng: Rng(1),
  lootRng: Rng(2),
  visible: const {},
  explored: const {},
  buildFloor: _noFloorBelow,
  spells: spells,
);

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
        lootRng: Rng(2),
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
        lootRng: Rng(2),
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

    test('carries the delve\'s own depth across a copy, like the seed', () {
      // arrange
      final state = GameState(
        map: FloorMap.parse('###\n#.#\n###'),
        hero: _hero,
        monsters: const [],
        rng: Rng(1),
        lootRng: Rng(2),
        buildFloor: _noFloorBelow,
        visible: const {},
        explored: const {},
        worldSeed: 909,
        deepest: 7,
      );

      // act
      final moved = state.copyWith(depth: 4);

      // assert
      expect(moved.deepest, 7);
      expect(moved.worldSeed, 909);
    });

    test('bottoms out at the crypt\'s five when nobody names a depth', () {
      // arrange
      final state = GameState(
        map: FloorMap.parse('###\n#.#\n###'),
        hero: _hero,
        monsters: const [],
        rng: Rng(1),
        lootRng: Rng(2),
        buildFloor: _noFloorBelow,
        visible: const {},
        explored: const {},
      );

      // assert
      expect(state.deepest, deepestDepth);
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
          lootRng: Rng(2),
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

  group('GameState floors', () {
    test('carries no snapshots, no gold and no stairs up by default', () {
      // arrange
      final state = crawl(ascii: _room, heroAt: const Position(1, 1));

      // act
      final carried = (state.gold, state.stairsUp);

      // assert
      expect(carried, (0, null));
      expect(state.floors, isEmpty);
    });

    test('copyWith clears the stairs up without clearing the stairs down', () {
      // arrange
      final state = crawl(
        ascii: _room,
        heroAt: const Position(1, 1),
        stairsDown: const Position(2, 1),
        stairsUp: const Position(1, 1),
      );

      // act
      final next = state.copyWith(clearStairsUp: true);

      // assert
      expect((next.stairsUp, next.stairsDown), (null, const Position(2, 1)));
    });

    test('copyWith carries the gold across untouched', () {
      // arrange
      final state = crawl(ascii: _room, heroAt: const Position(1, 1), gold: 44);

      // act
      final next = state.copyWith(depth: 2);

      // assert
      expect(next.gold, 44);
    });

    test('defensively copies the floors it is handed', () {
      // arrange
      final snapshots = <int, FloorMemory>{};
      final state = crawl(
        ascii: _room,
        heroAt: const Position(1, 1),
        floors: snapshots,
      );

      // act
      snapshots[7] = FloorMemory(
        map: FloorMap.parse(_room),
        monsters: const [],
        groundItems: const {},
        explored: const {},
        stairsDown: null,
        stairsUp: null,
      );

      // assert
      expect(state.floors, isEmpty);
    });

    test('a snapshot defensively copies the monsters it is handed', () {
      // arrange
      final monsters = [ghoul('ghoul-1', const Position(2, 2))];
      final memory = FloorMemory(
        map: FloorMap.parse(_room),
        monsters: monsters,
        groundItems: const {},
        explored: const {},
        stairsDown: null,
        stairsUp: null,
      );

      // act
      monsters.add(ghoul('ghoul-2', const Position(3, 3)));

      // assert
      expect(memory.monsters.map((monster) => monster.id), ['ghoul-1']);
    });
  });

  group('resistances', () {
    test('a creature resists nothing and burns at nothing by default', () {
      // arrange
      const plain = Actor(
        id: 'rat-1',
        name: 'the rat',
        glyph: 'r',
        position: Position(1, 1),
        hp: 3,
        maxHp: 3,
        attackMin: 1,
        attackMax: 2,
        speed: 10,
        energy: 100,
      );

      // act
      final resists = plain.resists;
      final vulnerable = plain.vulnerableTo;

      // assert
      expect(resists, isEmpty);
      expect(vulnerable, isEmpty);
    });

    test('a copy carries the resistances over, because they never move', () {
      // arrange
      const drowned = Actor(
        id: 'drowned-1',
        name: 'the drowned sailor',
        glyph: 'd',
        position: Position(1, 1),
        hp: 9,
        maxHp: 9,
        attackMin: 2,
        attackMax: 4,
        speed: 10,
        energy: 100,
        resists: {DamageType.frost},
        vulnerableTo: {DamageType.fire},
      );

      // act
      final wounded = drowned.copyWith(hp: 4);

      // assert - a creature's make-up is not something a fight changes, which
      // is why copyWith never offers to change it
      expect(wounded.resists, {DamageType.frost});
      expect(wounded.vulnerableTo, {DamageType.fire});
    });

    test('says what it resists when it is asked to describe itself', () {
      // arrange
      const wight = Actor(
        id: 'wight-1',
        name: 'the wight',
        glyph: 'w',
        position: Position(2, 3),
        hp: 14,
        maxHp: 14,
        attackMin: 3,
        attackMax: 6,
        speed: 10,
        energy: 100,
        vulnerableTo: {DamageType.fire},
      );

      // act
      final described = wight.toString();

      // assert
      expect(described, contains('fire'));
    });
  });

  group('the crawl a magic hero plays', () {
    test('starts with no mana, no ward, no bind and no spells known', () {
      // arrange
      // act
      final game = _game();

      // assert - a state built without naming any of it is the state every
      // pre-magic rule test has always built
      expect(game.mana, 0);
      expect(game.warded, 0);
      expect(game.bound, isEmpty);
      expect(game.knownSpells, isEmpty);
    });

    test('carries mana, ward, bind and known spells through copyWith', () {
      // arrange
      final game = _game();

      // act
      final cast = game.copyWith(
        mana: 3,
        warded: 6,
        bound: const {'ghoul-1': 2},
        knownSpells: const {'firebolt'},
      );

      // assert
      expect(cast.mana, 3);
      expect(cast.warded, 6);
      expect(cast.bound, const {'ghoul-1': 2});
      expect(cast.knownSpells, const {'firebolt'});
    });

    test('carries the spell registry by identity, never through copyWith', () {
      // arrange
      const firebolt = Spell(
        id: 'firebolt',
        name: 'Firebolt',
        school: SkillId.wrath,
        manaCost: 2,
        requiredLevel: 0,
        kind: SpellKind.bolt,
        type: DamageType.fire,
        min: 2,
        max: 4,
      );
      final game = _game(spells: const {'firebolt': firebolt});

      // act
      final moved = game.copyWith(mana: 1);

      // assert - content data injected at the door, exactly as dropTables are
      expect(moved.spells, {'firebolt': firebolt});
    });

    test('holds its bind counters and its known spells unmodifiable', () {
      // arrange
      final game = _game().copyWith(
        bound: const {'ghoul-1': 3},
        knownSpells: const {'mend'},
      );

      // act
      write() => game.bound['wight-1'] = 1;
      learn() => game.knownSpells.add('ward');

      // assert
      expect(write, throwsUnsupportedError);
      expect(learn, throwsUnsupportedError);
    });
  });

  group('the materials a crawl carries', () {
    test('a crawl the hero has gathered nothing in carries no counters', () {
      // arrange
      // act
      final game = crawl(ascii: _room, heroAt: const Position(1, 1));

      // assert
      expect(game.materials, isEmpty);
    });

    test('the counters cannot be written through', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: const Position(1, 1),
        materials: const {MaterialId.ore: 1},
      );

      // act
      void write() => game.materials[MaterialId.herb] = 1;

      // assert
      expect(write, throwsUnsupportedError);
    });

    test('copyWith moves them, which gold has no need of', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: const Position(1, 1));

      // act
      final after = game.copyWith(materials: const {MaterialId.ore: 2});

      // assert - gathering is what moves these mid-crawl, and nothing in the
      // rules moves gold, which is why only one of the two is in copyWith
      expect(after.materials, const {MaterialId.ore: 2});
      expect(game.materials, isEmpty);
    });
  });
}
