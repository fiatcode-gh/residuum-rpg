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
  stairsUp: depth <= 1 ? null : const Position(1, 1),
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
  Position? stairsUp,
  FloorBuilder buildFloor = _noFloorBelow,
  Set<Position>? explored,
  Map<Position, List<Item>> groundItems = const {},
  List<Item> inventory = const [],
  Equipment equipment = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
  Map<int, DropTable> dropTables = const {},
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
    lootRng: Rng(2),
    buildFloor: buildFloor,
    visible: visible,
    explored: explored ?? {...visible},
    depth: depth,
    stairsDown: stairsDown,
    stairsUp: stairsUp,
    groundItems: groundItems,
    inventory: inventory,
    equipment: equipment,
    skills: skills,
    dropTables: dropTables,
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
  _lootTests();
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

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _shield = BaseItem(
  id: 'kite-shield',
  name: 'Kite Shield',
  glyph: '[',
  slot: EquipSlot.offHand,
  armor: 3,
  heavy: true,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 10,
);

Item _item(String id, BaseItem base, {Rarity rarity = Rarity.common}) =>
    Item(id: id, base: base, rarity: rarity);

void _lootTests() {
  group('GameBloc picking things up', () {
    blocTest<GameBloc, GameViewState>(
      'takes what is underfoot and says so',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          groundItems: {
            const Position(3, 2): [_item('floor-1-1', _sword)],
          },
        ),
      ),
      act: (bloc) => bloc.add(const PickUpPressed()),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.inventory.map((item) => item.id), 'carried', [
              'floor-1-1',
            ])
            .having((s) => s.log, 'log', ['You pick up Common Iron Sword.']),
      ],
    );

    test('offers the control only when there is something to take', () {
      // arrange
      final bare = GameBloc(game: arenaGame(heroAt: const Position(3, 2)));
      final littered = GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          groundItems: {
            const Position(3, 2): [_item('floor-1-1', _sword)],
          },
        ),
      );

      // act
      final offered = (bare.state.canPickUp, littered.state.canPickUp);

      // assert
      expect(offered, (false, true));
      addTearDown(bare.close);
      addTearDown(littered.close);
    });

    blocTest<GameBloc, GameViewState>(
      'a full pack refuses the pick-up and the log says why',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          inventory: [
            for (var index = 0; index < inventoryCap; index++)
              _item('kit-$index', _potion),
          ],
          groundItems: {
            const Position(3, 2): [_item('floor-1-1', _sword)],
          },
        ),
      ),
      act: (bloc) => bloc.add(const PickUpPressed()),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.inventory, 'carried', hasLength(inventoryCap))
            .having((s) => s.log, 'log', ['You cannot carry any more.']),
      ],
    );
  });

  group('GameBloc equipping', () {
    blocTest<GameBloc, GameViewState>(
      'wearing a weapon raises the derived attack',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          inventory: [_item('kit-1', _sword)],
        ),
      ),
      act: (bloc) => bloc.add(const EquipPressed('kit-1')),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.attack, 'attack', (7, 9))
            .having((s) => s.game.inventory, 'carried', isEmpty)
            .having((s) => s.log, 'log', [
              'You put on Common Iron Sword (main hand).',
            ]),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'wearing a shield raises the derived armour',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          inventory: [_item('kit-1', _shield)],
        ),
      ),
      act: (bloc) => bloc.add(const EquipPressed('kit-1')),
      expect: () => [isA<GameViewState>().having((s) => s.armor, 'armour', 3)],
    );

    blocTest<GameBloc, GameViewState>(
      'taking a piece off puts it back in the pack',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          equipment: {EquipSlot.mainHand: _item('kit-1', _sword)},
        ),
      ),
      act: (bloc) => bloc.add(const UnequipPressed(EquipSlot.mainHand)),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.equipment, 'worn', isEmpty)
            .having((s) => s.game.inventory.map((item) => item.id), 'carried', [
              'kit-1',
            ])
            .having((s) => s.attack, 'attack', (4, 4)),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a refused equip surfaces in the log and changes nothing',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          inventory: [_item('kit-1', _potion)],
        ),
      ),
      act: (bloc) => bloc.add(const EquipPressed('kit-1')),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.equipment, 'worn', isEmpty)
            .having((s) => s.log, 'log', hasLength(1)),
      ],
    );
  });

  group('GameBloc drinking', () {
    blocTest<GameBloc, GameViewState>(
      'the quick drink heals and logs the amount',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          heroHp: 5,
          inventory: [_item('kit-1', _potion)],
        ),
      ),
      act: (bloc) => bloc.add(const QuickDrinkPressed()),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.hero.hp, 'hp', 15)
            .having((s) => s.game.inventory, 'carried', isEmpty)
            .having((s) => s.log, 'log', [
              'You drink Common Healing Potion and recover 10.',
            ]),
      ],
    );

    test('the quick drink does nothing at all with no potion carried', () {
      // arrange
      final bloc = GameBloc(
        game: arenaGame(heroAt: const Position(3, 2), heroHp: 5),
      );

      // act
      bloc.add(const QuickDrinkPressed());

      // assert
      expect(bloc.state.firstPotion, isNull);
      expect(bloc.state.game.hero.hp, 5);
      addTearDown(bloc.close);
    });

    blocTest<GameBloc, GameViewState>(
      'a potion drunk at full health is wasted, and the log admits it',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          inventory: [_item('kit-1', _potion)],
        ),
      ),
      act: (bloc) => bloc.add(const QuickDrinkPressed()),
      expect: () => [
        isA<GameViewState>().having((s) => s.log, 'log', [
          'You drink Common Healing Potion. Nothing was wrong with you.',
        ]),
      ],
    );
  });

  group('GameBloc dropping', () {
    blocTest<GameBloc, GameViewState>(
      'puts the item down where the hero stands',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          inventory: [_item('kit-1', _sword)],
        ),
      ),
      act: (bloc) => bloc.add(const DropPressed('kit-1')),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.inventory, 'carried', isEmpty)
            .having(
              (s) => s.itemsUnderfoot.map((item) => item.id),
              'underfoot',
              ['kit-1'],
            )
            .having((s) => s.log, 'log', [
              'Common Iron Sword falls to the floor.',
            ]),
      ],
    );
  });

  group('GameBloc training', () {
    blocTest<GameBloc, GameViewState>(
      'a skill level-up reaches the log',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          monsters: [ghoul(const Position(4, 2), hp: 500)],
          skills: const {SkillId.arms: SkillState(level: 0, xp: 3)},
        ),
      ),
      act: (bloc) => bloc.add(const TileTapped(Position(4, 2))),
      expect: () => [
        isA<GameViewState>()
            .having((s) => s.game.skills[SkillId.arms]?.level, 'Arms', 1)
            .having((s) => s.log, 'log', contains('Arms rises to 1.')),
      ],
    );

    blocTest<GameBloc, GameViewState>(
      'a dodge reaches the log',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(1, 1),
          heroHp: 100000,
          monsters: [ghoul(const Position(2, 1), hp: 100000)],
          skills: const {SkillId.fleetfoot: SkillState(level: maxSkillLevel)},
        ),
      ),
      act: (bloc) async {
        for (var turn = 0; turn < 40; turn++) {
          bloc.add(const TileTapped(Position(1, 0)));
          await Future<void>.delayed(Duration.zero);
        }
      },
      verify: (bloc) {
        expect(bloc.state.log, contains('The ghoul swings and misses.'));
      },
    );
  });

  group('GameBloc loot on the grid', () {
    test('a ground item is visible to the view state under the hero', () {
      // arrange
      final bloc = GameBloc(
        game: arenaGame(
          heroAt: const Position(3, 2),
          groundItems: {
            const Position(3, 2): [
              _item('floor-1-1', _sword),
              _item('floor-1-2', _potion),
            ],
          },
        ),
      );

      // act
      final underfoot = bloc.state.itemsUnderfoot;

      // assert
      expect(underfoot.map((item) => item.id), ['floor-1-1', 'floor-1-2']);
      addTearDown(bloc.close);
    });

    test('a fresh crawl arms the hero and stocks the pack', () {
      // arrange
      final bloc = GameBloc();

      // act
      final state = bloc.state;

      // assert
      expect(state.attack, (3, 5));
      expect(state.firstPotion, isNotNull);
      expect(state.game.equipment[EquipSlot.mainHand], isNotNull);
      addTearDown(bloc.close);
    });
  });

  group('GameBloc climbing', () {
    test('the ascend control appears only on the stairs up', () {
      // arrange
      final onTile = GameBloc(
        game: arenaGame(
          heroAt: const Position(1, 1),
          depth: 2,
          stairsUp: const Position(1, 1),
        ),
      );
      final elsewhere = GameBloc(
        game: arenaGame(
          heroAt: const Position(2, 1),
          depth: 2,
          stairsUp: const Position(1, 1),
        ),
      );

      // act
      final offered = (onTile.state.canAscend, elsewhere.state.canAscend);

      // assert
      expect(offered, (true, false));
    });

    test('depth one never offers a way up', () {
      // arrange
      final bloc = GameBloc(game: arenaGame(heroAt: const Position(1, 1)));

      // act
      final offered = bloc.state.canAscend;

      // assert
      expect(offered, isFalse);
    });

    test('a dead hero is offered nothing', () {
      // arrange
      final bloc = GameBloc(
        game: arenaGame(
          heroAt: const Position(1, 1),
          depth: 2,
          stairsUp: const Position(1, 1),
        ).copyWith(isGameOver: true),
      );

      // act
      final offered = (bloc.state.canAscend, bloc.state.canLeave);

      // assert
      expect(offered, (false, false));
    });

    test('leaving is offered on either flight of stairs and nowhere else', () {
      // arrange
      final down = GameBloc(
        game: arenaGame(
          heroAt: const Position(5, 3),
          stairsDown: const Position(5, 3),
        ),
      );
      final up = GameBloc(
        game: arenaGame(
          heroAt: const Position(1, 1),
          depth: 2,
          stairsUp: const Position(1, 1),
        ),
      );
      final neither = GameBloc(game: arenaGame(heroAt: const Position(2, 2)));

      // act
      final offered = (
        down.state.canLeave,
        up.state.canLeave,
        neither.state.canLeave,
      );

      // assert
      expect(offered, (true, true, false));
    });

    blocTest<GameBloc, GameViewState>(
      'the ascend control takes the hero up a floor',
      build: () => GameBloc(
        game: arenaGame(
          heroAt: const Position(5, 3),
          stairsDown: const Position(5, 3),
          buildFloor: deeperFloor,
        ),
        stepDelay: Duration.zero,
      ),
      act: (bloc) async {
        bloc.add(const DescendPressed());
        await bloc.stream.first;
        bloc.add(const AscendPressed());
      },
      verify: (bloc) {
        expect(bloc.state.depth, 1);
        expect(bloc.state.log.last, 'You climb to depth 1.');
      },
    );

    blocTest<GameBloc, GameViewState>(
      'asking to climb where there are no stairs says so and costs nothing',
      build: () => GameBloc(
        game: arenaGame(heroAt: const Position(2, 2), depth: 1),
        stepDelay: Duration.zero,
      ),
      act: (bloc) => bloc.add(const AscendPressed()),
      verify: (bloc) {
        expect(bloc.state.depth, 1);
        expect(bloc.state.log.last, 'There are no stairs up from here.');
      },
    );
  });
}
