import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/target_card.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// Acceptance 4 (`CONTRACT.md`): every verb the crawl offers is still
/// reachable, each through the one surface `CONTRACT.md` names for it —
/// never the retired action bar. Unlike the bar this reshuffle retired,
/// nothing here pins a frozen control set: the bottom menu's four slots are
/// the only thing whose order is ever asserted (`crawl_menu_test.dart`
/// covers that). This file only proves each verb still fires.
const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _heroAt = Position(2, 2);

Actor _hero(Position at, {int hp = 20}) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: hp,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

Actor _ghoul(Position at, {String id = 'ghoul-1'}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: 10,
  energy: actThreshold,
);

GameState _mapScene() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(_heroAt),
    monsters: [
      _ghoul(const Position(3, 2)), // adjacent: attack
      _ghoul(const Position(5, 2), id: 'ghoul-2'), // distant: watched/inspect
    ],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    spells: spellsById,
    knownSpells: const {'firebolt'},
    mana: 10,
  );
}

/// The same room, quiet: nothing adjacent to hold the hero in a fight, so a
/// distant tap auto-walks instead of being refused mid-battle.
GameState _autoWalkScene() => _mapScene().copyWith(monsters: const []);

/// A mid-depth landing: loot underfoot and a potion carried, so pick up and
/// drink both apply without leaving the dungeon.
GameState _landingScene() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(_heroAt, hp: 10),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: 2,
    stairsUp: _heroAt,
    groundItems: {
      _heroAt: [
        const Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
      ],
    },
    inventory: const [
      Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
    ],
  );
}

/// A floor whose stairs down leads to a floor whose own stairs up returns
/// here — so both `Descend` and, once there, `Ascend` are reachable in one
/// continuous session (core's own way-back bookkeeping needs a real
/// descent, not a hand-set `depth`).
Floor _floorBelow(int depth) => Floor(
  map: FloorMap.parse(_arena),
  heroSpawn: _heroAt,
  monsters: const [],
  stairsDown: null,
  stairsUp: _heroAt,
);

GameState _descendScene() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(_heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: _floorBelow,
    stairsDown: _heroAt,
  );
}

GameState _bottomLandingScene() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(_heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: deepestDepth,
    stairsUp: _heroAt,
  );
}

/// The outermost ring of a road fight, live but not adjacent, so waiting
/// and fleeing both apply.
GameState _roadScene() {
  const roadArena = '''
.......
.......
.......''';
  const heroAt = Position(0, 1);
  final map = FloorMap.parse(roadArena);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoul(const Position(5, 1))],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isEncounter: true,
  );
}

/// The same road, cleared, so `Move on` is the only place verb standing.
GameState _clearedRoadScene() => _roadScene().copyWith(monsters: const []);

/// A room with an oreVein underfoot, so gathering applies.
GameState _gatherScene() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(_heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    nodes: {_heroAt: GatherKind.oreVein},
  );
}

/// Pushes the crawl over a real [TownBloc] and [WorldBloc], the way the
/// session pushes it — every verb that leaves the dungeon needs both.
Future<GameBloc> _pushCrawl(WidgetTester tester, GameState game) async {
  await onTheTargetPhone(tester);
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final world = WorldBloc(world: newWhereabouts(), worldSeed: 5);
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: town),
                  BlocProvider.value(value: world),
                  BlocProvider.value(value: bloc),
                ],
                child: const GameScreen(palette: DungeonPalette.crypt),
              ),
            ),
          ),
          child: const Text('down'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('down'));
  await tester.pumpAndSettle();
  return bloc;
}

Future<void> _tapTile(
  WidgetTester tester,
  Position tile, {
  Position focus = _heroAt,
}) async {
  final scene = find.byKey(dungeonSceneKey);
  final size = tester.getSize(scene);
  final geometry = GridGeometry.camera(size, 7, 5, focus);
  final local = geometry.centreOf(tile);
  await tester.tapAt(tester.getTopLeft(scene) + local);
}

void main() {
  testWidgets('attack: a map tap on an adjacent monster is a bump', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _mapScene());
    final hpBefore = bloc.state.game.monsterAt(const Position(3, 2))!.hp;

    await _tapTile(tester, const Position(3, 2));
    await tester.pumpAndSettle();

    expect(
      bloc.state.game.monsterAt(const Position(3, 2))!.hp,
      lessThan(hpBefore),
    );
  });

  testWidgets('move: a map tap on the floor beside the hero steps there', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _mapScene());

    await _tapTile(tester, const Position(2, 3));
    await tester.pumpAndSettle();

    expect(bloc.state.game.hero.position, const Position(2, 3));
  });

  testWidgets('auto-walk: a map tap on a distant explored tile walks there', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _autoWalkScene());

    await _tapTile(tester, const Position(5, 1));
    await tester.pumpAndSettle();

    expect(bloc.state.game.hero.position, const Position(5, 1));
  });

  testWidgets('inspect: a map tap on a watched monster opens its card', (
    tester,
  ) async {
    await _pushCrawl(tester, _mapScene());

    await _tapTile(tester, const Position(5, 2));
    await tester.pumpAndSettle();

    expect(find.byKey(targetCardKey), findsOneWidget);
  });

  testWidgets('cast: the Spells pop-up arms Firebolt and a map tap casts it', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _mapScene());

    await tester.tap(find.byKey(const ValueKey('menu-spells')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('spell:firebolt')));
    await tester.pumpAndSettle();
    expect(bloc.state.armedSpellId, 'firebolt');

    final hpBefore = bloc.state.game.monsterAt(const Position(3, 2))!.hp;
    await _tapTile(tester, const Position(3, 2));
    await tester.pumpAndSettle();

    expect(
      bloc.state.game.monsterAt(const Position(3, 2))!.hp,
      lessThan(hpBefore),
    );
  });

  testWidgets('drink: the Quick pop-up heals from the pack', (tester) async {
    final bloc = await _pushCrawl(tester, _landingScene());
    final hpBefore = bloc.state.game.hero.hp;

    await tester.tap(find.byKey(const ValueKey('menu-quick')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('drink:potion-1')));
    await tester.pumpAndSettle();

    expect(bloc.state.game.hero.hp, greaterThan(hpBefore));
  });

  testWidgets('wait: the log row control holds ground for a turn', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _roadScene());

    await tester.tap(find.byKey(const ValueKey('wait')));
    await tester.pumpAndSettle();

    expect(
      bloc.state.log.map((line) => line.sentence),
      contains('You hold your ground.'),
    );
  });

  testWidgets('flee: the log row control walks the hero off the ring', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _roadScene());

    await tester.tap(find.byKey(const ValueKey('flee')));
    await tester.pumpAndSettle();

    expect(bloc.state.hasFled, isTrue);
  });

  testWidgets('pick up: the place pop-up takes what is underfoot', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _landingScene());

    await tester.tap(find.byKey(const ValueKey('pick-up')));
    await tester.pumpAndSettle();

    expect(bloc.state.itemsUnderfoot, isEmpty);
    expect(bloc.state.game.inventory, hasLength(2));
  });

  testWidgets('mine/gather: the place pop-up works the node underfoot', (
    tester,
  ) async {
    final bloc = await _pushCrawl(tester, _gatherScene());

    await tester.tap(find.byKey(const ValueKey('gather')));
    await tester.pumpAndSettle();

    expect(bloc.state.nodeUnderfoot, isNull);
  });

  testWidgets(
    'descend, then ascend: the place pop-up moves a floor at a time',
    (tester) async {
      final bloc = await _pushCrawl(tester, _descendScene());

      await tester.tap(find.byKey(const ValueKey('descend')));
      await tester.pumpAndSettle();
      expect(bloc.state.game.depth, 2);

      await tester.tap(find.byKey(const ValueKey('ascend')));
      await tester.pumpAndSettle();
      expect(bloc.state.game.depth, 1);
    },
  );

  testWidgets('move on: the place pop-up clears a won road fight', (
    tester,
  ) async {
    await _pushCrawl(tester, _clearedRoadScene());

    await tester.tap(find.byKey(const ValueKey('move-on')));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('leave/finish: the place pop-up ends a bottom-floor delve', (
    tester,
  ) async {
    await _pushCrawl(tester, _bottomLandingScene());

    await tester.tap(find.byKey(const ValueKey('leave-dungeon')));
    await tester.pumpAndSettle();
    expect(
      find.text('The delve is done. Leave with your spoils?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Leave with them'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('pack: the Hero slot opens the crawl pack screen', (
    tester,
  ) async {
    await _pushCrawl(tester, _landingScene());

    await tester.tap(find.byKey(const ValueKey('menu-hero')));
    await tester.pumpAndSettle();

    expect(find.text('Pack'), findsOneWidget);
  });
}
