import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/actor_presentation.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/map_overlay_layout.dart';
import 'package:residuum_app/game/target_card.dart';
import 'package:residuum_app/game/turn_order_strip.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// A small open room, so every axis fits the target phone's map slot and
/// the camera centres it — no edge clamp to reason about for the facts,
/// dismissal and long-press proofs.
const _roomArena = '''
##########
#........#
#........#
#........#
#........#
##########''';
const _hero = Position(1, 1);
const _farMonster = Position(7, 3);
const _nearGhoul = Position(1, 2);
const _farSpitter = Position(4, 1);

/// A room close to the map slot's own width, so a monster comfortably
/// clear of the hero renders its card comfortably clear of the hero's own
/// adjacent tiles too — unlike [_roomArena], whose centring margins put a
/// flipped card back over the room it was tapped from.
String _wideRoomArena(int rows) {
  final wall = '#' * 24;
  final floor = List.generate(rows, (_) => '#${'.' * 22}#').join('\n');
  return '$wall\n$floor\n$wall';
}

const _wideHero = Position(2, 7);
const _wideFarMonster = Position(9, 7);

String _openField(int columns, int rows) =>
    List.generate(rows, (_) => '.' * columns).join('\n');

Actor _ghoul(
  Position at, {
  String id = 'ghoul-1',
  int hp = 10,
  int maxHp = 10,
  int attackMin = 3,
  int attackMax = 3,
  int speed = 10,
  int reach = 1,
}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: maxHp,
  attackMin: attackMin,
  attackMax: attackMax,
  speed: speed,
  energy: actThreshold,
  reach: reach,
);

Actor _spitter(
  Position at, {
  String id = 'spitter-1',
  int hp = 4,
  int maxHp = 4,
  int attackMin = 2,
  int attackMax = 3,
  int speed = 5,
  int reach = 3,
  Set<DamageType> resists = const {},
  Set<DamageType> vulnerableTo = const {},
}) => Actor(
  id: id,
  name: 'the spitter',
  glyph: 'p',
  position: at,
  hp: hp,
  maxHp: maxHp,
  attackMin: attackMin,
  attackMax: attackMax,
  speed: speed,
  energy: actThreshold,
  reach: reach,
  resists: resists,
  vulnerableTo: vulnerableTo,
);

List<Item> _oneSword() => const [
  Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
];

GameState _gameState({
  required String ascii,
  required Position heroAt,
  List<Actor> monsters = const [],
  Set<Position>? visible,
  Map<Position, List<Item>> groundItems = const {},
}) {
  final map = FloorMap.parse(ascii);
  final seen = visible ?? computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: 20,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: seen,
    explored: {...seen},
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    groundItems: groundItems,
  );
}

/// A map with a hero and a monster at explicit positions, [columns]/[rows]
/// apart wide enough to hold them: the camera always centres [heroAt]
/// exactly at zero pan, so [monsterAt]'s own screen offset from the hero —
/// not any floor edge — is what places its cell near a viewport edge.
/// Visibility is explicit rather than FOV-derived, so the scene never has
/// to out-chase a monster to stay known.
GameState _clampedGameState({
  required int columns,
  required int rows,
  required Position heroAt,
  required Position monsterAt,
}) => GameState(
  map: FloorMap.parse(_openField(columns, rows)),
  hero: Actor(
    id: 'hero',
    name: 'you',
    glyph: '@',
    position: heroAt,
    hp: 20,
    maxHp: 20,
    attackMin: 4,
    attackMax: 4,
    speed: 10,
    energy: actThreshold,
  ),
  monsters: [_ghoul(monsterAt)],
  rng: Rng(1),
  lootRng: Rng(2),
  visible: {heroAt, monsterAt},
  explored: {heroAt, monsterAt},
  buildFloor: (depth) => throw StateError('this arena has no floor below'),
);

Future<GameBloc> _openCrawl(WidgetTester tester, GameState game) async {
  await onTheTargetPhone(tester);
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const GameScreen(palette: DungeonPalette.crypt),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

/// The projection the rendered scene actually uses: [_roomArena] fits any
/// test surface this file pumps, so the camera centres it and ignores pan.
GridGeometry _mapGeometry(WidgetTester tester, GameViewState state) =>
    GridGeometry.camera(
      tester.getSize(find.byKey(dungeonSceneKey)),
      state.game.map.width,
      state.game.map.height,
      state.cameraFocus,
      state.pan,
    );

Future<void> _tapLocal(WidgetTester tester, Offset local) async {
  final topLeft = tester.getTopLeft(find.byKey(dungeonSceneKey));
  await tester.tapAt(topLeft + local);
}

Future<void> _longPressLocal(WidgetTester tester, Offset local) async {
  final topLeft = tester.getTopLeft(find.byKey(dungeonSceneKey));
  await tester.longPressAt(topLeft + local);
}

/// Pumps a standalone [TargetCard] over a fixed [size] box anchored at the
/// surface's own origin, so [WidgetTester.getRect] reads in the same local
/// space [GridGeometry] does. [textScaler] feeds the ambient `MediaQuery`
/// a physical device's system text size would turn — [TargetCard] itself
/// is pumped outside `GameScreen`'s own clamp here, so the test supplies
/// an already-clamped value directly.
Future<Rect> _pumpCard(
  WidgetTester tester,
  GameViewState state,
  Size size, {
  TextScaler? textScaler,
}) async {
  final card = MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: TargetCard(state: state, size: size),
      ),
    ),
  );
  await tester.pumpWidget(
    textScaler == null
        ? card
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: card,
          ),
  );
  return tester.getRect(find.byKey(targetCardKey));
}

void main() {
  testWidgets(
    'a tap 18 dp off a far known monster opens the card with its facts, '
    'no sheet, and marks the cell with the heavy reticle',
    (tester) async {
      final monster = _ghoul(
        _farMonster,
        hp: 6,
        maxHp: 8,
        attackMin: 2,
        attackMax: 4,
        speed: 7,
      );
      final bloc = await _openCrawl(
        tester,
        _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
      );
      final geometry = _mapGeometry(tester, bloc.state);
      final local = geometry.centreOf(_farMonster) + const Offset(18, 0);

      await _tapLocal(tester, local);
      await tester.pumpAndSettle();

      expect(bloc.state.inspectedActorId, monster.id);
      expect(find.byType(BottomSheet), findsNothing);
      final card = find.byKey(targetCardKey);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('The ghoul')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('HP 6/8')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('ATK 2–4  SPD 7')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Melee only')),
        findsOneWidget,
      );
      expect(find.text('Adjacent'), findsNothing);

      final cell = DungeonSceneSnapshot.fromViewState(bloc.state).cells
          .singleWhere((c) => c.entity == monster.id);
      expect(cell.selected, isTrue);
    },
  );

  testWidgets('tapping inside the card changes nothing', (tester) async {
    final monster = _ghoul(_farMonster);
    final bloc = await _openCrawl(
      tester,
      _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
    );
    final geometry = _mapGeometry(tester, bloc.state);
    await _tapLocal(
      tester,
      geometry.centreOf(_farMonster) + const Offset(18, 0),
    );
    await tester.pumpAndSettle();
    expect(bloc.state.inspectedActorId, monster.id);
    final gameBefore = bloc.state.game;

    await tester.tapAt(tester.getCenter(find.byKey(targetCardKey)));
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, monster.id);
    expect(bloc.state.game, same(gameBefore));
    expect(find.byKey(targetCardKey), findsOneWidget);
  });

  testWidgets('tapping empty blank space dismisses the card', (tester) async {
    final monster = _ghoul(_farMonster);
    final bloc = await _openCrawl(
      tester,
      _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
    );
    final geometry = _mapGeometry(tester, bloc.state);
    await _tapLocal(
      tester,
      geometry.centreOf(_farMonster) + const Offset(18, 0),
    );
    await tester.pumpAndSettle();
    expect(bloc.state.inspectedActorId, monster.id);

    const blank = Offset(1, 1);
    expect(geometry.positionAt(blank), isNull);
    expect((blank - geometry.centreOf(_hero)).distance, greaterThan(24));

    await _tapLocal(tester, blank);
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, isNull);
    expect(find.byKey(targetCardKey), findsNothing);
  });

  testWidgets(
    'tapping a floor cell dismisses the card and still steps the hero',
    (tester) async {
      final monster = _ghoul(_wideFarMonster);
      final bloc = await _openCrawl(
        tester,
        _gameState(
          ascii: _wideRoomArena(14),
          heroAt: _wideHero,
          monsters: [monster],
        ),
      );
      final geometry = _mapGeometry(tester, bloc.state);
      await _tapLocal(
        tester,
        geometry.centreOf(_wideFarMonster) + const Offset(18, 0),
      );
      await tester.pumpAndSettle();
      expect(bloc.state.inspectedActorId, monster.id);
      expect(find.byKey(targetCardKey), findsOneWidget);

      final adjacent = _wideHero.step(Direction.south);
      await _tapLocal(tester, geometry.centreOf(adjacent));
      await tester.pumpAndSettle();

      expect(bloc.state.inspectedActorId, isNull);
      expect(find.byKey(targetCardKey), findsNothing);
      expect(bloc.state.game.hero.position, adjacent);
    },
  );

  testWidgets('a long-press on the monster opens the card', (tester) async {
    final monster = _ghoul(_farMonster);
    final bloc = await _openCrawl(
      tester,
      _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
    );
    final geometry = _mapGeometry(tester, bloc.state);

    await _longPressLocal(tester, geometry.centreOf(_farMonster));
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, monster.id);
    expect(find.byKey(targetCardKey), findsOneWidget);
  });

  testWidgets(
    'tapping a distant known wall dismisses the card, without moving the '
    'hero or touching the log',
    (tester) async {
      final monster = _ghoul(_wideFarMonster);
      final bloc = await _openCrawl(
        tester,
        _gameState(
          ascii: _wideRoomArena(14),
          heroAt: _wideHero,
          monsters: [monster],
        ),
      );
      final geometry = _mapGeometry(tester, bloc.state);
      await _tapLocal(
        tester,
        geometry.centreOf(_wideFarMonster) + const Offset(18, 0),
      );
      await tester.pumpAndSettle();
      expect(bloc.state.inspectedActorId, monster.id);
      final heroBefore = bloc.state.game.hero.position;
      final logBefore = bloc.state.log;

      const wall = Position(2, 0);
      await _tapLocal(tester, geometry.centreOf(wall));
      await tester.pumpAndSettle();

      expect(bloc.state.inspectedActorId, isNull);
      expect(find.byKey(targetCardKey), findsNothing);
      expect(bloc.state.game.hero.position, heroBefore);
      expect(bloc.state.log, logBefore);
    },
  );

  testWidgets("tapping the hero's own cell dismisses an open card", (
    tester,
  ) async {
    final monster = _ghoul(_wideFarMonster);
    final bloc = await _openCrawl(
      tester,
      _gameState(
        ascii: _wideRoomArena(14),
        heroAt: _wideHero,
        monsters: [monster],
      ),
    );
    final geometry = _mapGeometry(tester, bloc.state);
    await _tapLocal(
      tester,
      geometry.centreOf(_wideFarMonster) + const Offset(18, 0),
    );
    await tester.pumpAndSettle();
    expect(bloc.state.inspectedActorId, monster.id);

    await _tapLocal(tester, geometry.centreOf(_wideHero) + const Offset(5, 0));
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, isNull);
    expect(find.byKey(targetCardKey), findsNothing);
  });

  testWidgets('a long-press on empty ground dismisses an open card', (
    tester,
  ) async {
    final monster = _ghoul(_wideFarMonster);
    final bloc = await _openCrawl(
      tester,
      _gameState(
        ascii: _wideRoomArena(14),
        heroAt: _wideHero,
        monsters: [monster],
      ),
    );
    final geometry = _mapGeometry(tester, bloc.state);
    await _tapLocal(
      tester,
      geometry.centreOf(_wideFarMonster) + const Offset(18, 0),
    );
    await tester.pumpAndSettle();
    expect(bloc.state.inspectedActorId, monster.id);
    final heroBefore = bloc.state.game.hero.position;

    const emptyGround = Position(2, 12);
    await _longPressLocal(tester, geometry.centreOf(emptyGround));
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, isNull);
    expect(find.byKey(targetCardKey), findsNothing);
    expect(bloc.state.game.hero.position, heroBefore);
  });

  testWidgets(
    'a timeline actor tap selects it and shows its card, opening no sheet',
    (tester) async {
      final monster = _ghoul(_nearGhoul);
      final bloc = await _openCrawl(
        tester,
        _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
      );
      expect(bloc.state.isBattleOpen, isTrue);

      await tester.tap(find.byKey(const Key('timeline-actor-ghoul-1-1')));
      await tester.pumpAndSettle();

      expect(bloc.state.selectedActorId, 'ghoul-1');
      expect(find.byType(BottomSheet), findsNothing);
      final card = find.byKey(targetCardKey);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('The ghoul')),
        findsOneWidget,
      );
    },
  );

  testWidgets('the map rect is unchanged with and without the card', (
    tester,
  ) async {
    await _openCrawl(tester, _gameState(ascii: _roomArena, heroAt: _hero));
    final mapRectBefore = tester.getRect(find.byKey(dungeonSceneSlotKey));

    final monster = _ghoul(_farMonster);
    final bloc = await _openCrawl(
      tester,
      _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
    );
    final geometry = _mapGeometry(tester, bloc.state);
    await _tapLocal(
      tester,
      geometry.centreOf(_farMonster) + const Offset(18, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(targetCardKey), findsOneWidget);
    expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);
  });

  testWidgets(
    'with nothing inspected or selected in battle, the card names the '
    'nearest known monster',
    (tester) async {
      final ghoul = _ghoul(_nearGhoul);
      final spitter = _spitter(_farSpitter);
      final bloc = await _openCrawl(
        tester,
        _gameState(
          ascii: _roomArena,
          heroAt: _hero,
          monsters: [ghoul, spitter],
        ),
      );
      expect(bloc.state.isBattleOpen, isTrue);
      expect(bloc.state.inspectedActorId, isNull);
      expect(bloc.state.selectedActorId, isNull);

      final card = find.byKey(targetCardKey);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('The ghoul')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'selecting a farther actor shows that actor on the card instead',
    (tester) async {
      final ghoul = _ghoul(_nearGhoul);
      final spitter = _spitter(_farSpitter);
      final bloc = await _openCrawl(
        tester,
        _gameState(
          ascii: _roomArena,
          heroAt: _hero,
          monsters: [ghoul, spitter],
        ),
      );

      bloc.add(const TimelineActorSelected('spitter-1'));
      await tester.pumpAndSettle();

      expect(bloc.state.selectedActorId, 'spitter-1');
      expect(find.byType(BottomSheet), findsNothing);
      final card = find.byKey(targetCardKey);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('The spitter')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('The ghoul')),
        findsNothing,
      );
    },
  );

  testWidgets('the card words a longer reach as ranged, never as a distance', (
    tester,
  ) async {
    final spitter = _spitter(
      _farSpitter,
      resists: const {DamageType.fire},
      vulnerableTo: const {DamageType.frost},
    );
    await _openCrawl(
      tester,
      _gameState(ascii: _roomArena, heroAt: _hero, monsters: [spitter]),
    );

    final card = find.byKey(targetCardKey);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Ranged, reach 3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Resists fire')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Burns at frost')),
      findsOneWidget,
    );
    expect(find.text('Adjacent'), findsNothing);
  });

  testWidgets('the target card shows during a battle, with loot underfoot', (
    tester,
  ) async {
    final monster = _ghoul(_nearGhoul);
    final bloc = await _openCrawl(
      tester,
      _gameState(
        ascii: _roomArena,
        heroAt: _hero,
        monsters: [monster],
        groundItems: {_hero: _oneSword()},
      ),
    );
    expect(bloc.state.isBattleOpen, isTrue);

    expect(find.byKey(targetCardKey), findsOneWidget);
  });

  testWidgets(
    'a monster two rows below the hero, inspected, misses the hero block, '
    'with loot underfoot',
    (tester) async {
      const monsterAt = Position(3, 3);
      final monster = _ghoul(monsterAt);
      final bloc = await _openCrawl(
        tester,
        _gameState(
          ascii: _roomArena,
          heroAt: _hero,
          monsters: [monster],
          groundItems: {_hero: _oneSword()},
        ),
      );
      final geometry = _mapGeometry(tester, bloc.state);

      await _tapLocal(tester, geometry.centreOf(monsterAt));
      await tester.pumpAndSettle();
      expect(bloc.state.inspectedActorId, monster.id);

      final targetCard = find.byKey(targetCardKey);
      expect(targetCard, findsOneWidget);

      final topLeft = tester.getTopLeft(find.byKey(dungeonSceneKey));
      final heroRect = geometry.rectOf(_hero).shift(topLeft);
      expect(tester.getRect(targetCard).overlaps(heroBlock(heroRect)), isFalse);
    },
  );

  testWidgets(
    'a monster near the right floor edge keeps the card inside the slot, '
    "clear of the hero's block and the target cell",
    (tester) async {
      const size = Size(392.7, 441.8);
      const heroAt = Position(5, 5);
      const monsterAt = Position(12, 5);
      final game = _clampedGameState(
        columns: 20,
        rows: 12,
        heroAt: heroAt,
        monsterAt: monsterAt,
      );
      final state = GameViewState(
        game: game,
        log: const [],
        inspectedActorId: 'ghoul-1',
      );

      final cardRect = await _pumpCard(tester, state, size);

      final geometry = GridGeometry.camera(
        size,
        20,
        12,
        state.cameraFocus,
        state.pan,
      );
      final cellRect = geometry.rectOf(monsterAt);
      final heroRect = geometry.rectOf(heroAt);

      expect(cardRect.overlaps(heroBlock(heroRect)), isFalse);
      expect(cardRect.overlaps(cellRect), isFalse);
      expect(cardRect.left, greaterThanOrEqualTo(8));
      expect(cardRect.top, greaterThanOrEqualTo(8));
      expect(cardRect.right, lessThanOrEqualTo(size.width - 8));
      expect(cardRect.bottom, lessThanOrEqualTo(size.height - 8));
    },
  );

  testWidgets(
    'a monster near the top floor edge keeps the card inside the slot, '
    "clear of the hero's block and the target cell",
    (tester) async {
      const size = Size(392.7, 441.8);
      const heroAt = Position(6, 10);
      const monsterAt = Position(6, 3);
      final game = _clampedGameState(
        columns: 12,
        rows: 20,
        heroAt: heroAt,
        monsterAt: monsterAt,
      );
      final state = GameViewState(
        game: game,
        log: const [],
        inspectedActorId: 'ghoul-1',
      );

      final cardRect = await _pumpCard(tester, state, size);

      final geometry = GridGeometry.camera(
        size,
        12,
        20,
        state.cameraFocus,
        state.pan,
      );
      final cellRect = geometry.rectOf(monsterAt);
      final heroRect = geometry.rectOf(heroAt);

      expect(cardRect.overlaps(heroBlock(heroRect)), isFalse);
      expect(cardRect.overlaps(cellRect), isFalse);
      expect(cardRect.left, greaterThanOrEqualTo(8));
      expect(cardRect.top, greaterThanOrEqualTo(8));
      expect(cardRect.right, lessThanOrEqualTo(size.width - 8));
      expect(cardRect.bottom, lessThanOrEqualTo(size.height - 8));
    },
  );

  const directions = <String, (int, int)>{
    'north': (0, -1),
    'south': (0, 1),
    'east': (1, 0),
    'west': (-1, 0),
    'northeast': (1, -1),
    'northwest': (-1, -1),
    'southeast': (1, 1),
    'southwest': (-1, 1),
  };
  for (final entry in directions.entries) {
    testWidgets(
      'a target adjacent ${entry.key} of a centred hero never overlaps the '
      "hero's own block or its cell",
      (tester) async {
        const size = Size(392.7, 441.8);
        const heroAt = Position(20, 20);
        final (dx, dy) = entry.value;
        final monsterAt = Position(heroAt.x + dx, heroAt.y + dy);
        final game = _clampedGameState(
          columns: 40,
          rows: 40,
          heroAt: heroAt,
          monsterAt: monsterAt,
        );
        final state = GameViewState(
          game: game,
          log: const [],
          inspectedActorId: 'ghoul-1',
        );

        final cardRect = await _pumpCard(tester, state, size);

        final geometry = GridGeometry.camera(
          size,
          40,
          40,
          state.cameraFocus,
          state.pan,
        );
        final cellRect = geometry.rectOf(monsterAt);
        final heroRect = geometry.rectOf(heroAt);

        expect(cardRect.overlaps(heroBlock(heroRect)), isFalse);
        expect(cardRect.overlaps(cellRect), isFalse);
      },
    );
  }

  testWidgets('a known actor that has left sight renders no card', (
    tester,
  ) async {
    const size = Size(392.7, 441.8);
    final visibleGame = _gameState(
      ascii: _roomArena,
      heroAt: _hero,
      monsters: [_ghoul(_farMonster)],
    );
    final identity = ActorIdentityContext.fromGame(visibleGame);
    final hiddenGame = visibleGame.copyWith(visible: {_hero});
    final state = GameViewState(
      game: hiddenGame,
      log: const [],
      actorIdentity: identity,
      inspectedActorId: 'ghoul-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: TargetCard(state: state, size: size),
          ),
        ),
      ),
    );

    expect(find.byKey(targetCardKey), findsNothing);
  });

  testWidgets(
    "the card's name and fact rows stay unclipped at 1.3x text scale",
    (tester) async {
      const size = Size(392.7, 441.8);
      const heroAt = Position(6, 5);
      const monsterAt = Position(13, 5);
      final game = _clampedGameState(
        columns: 30,
        rows: 12,
        heroAt: heroAt,
        monsterAt: monsterAt,
      );
      final state = GameViewState(
        game: game,
        log: const [],
        inspectedActorId: 'ghoul-1',
      );

      const scaler = TextScaler.linear(1.3);
      await _pumpCard(tester, state, size, textScaler: scaler);

      double naturalHeight(Finder finder) {
        final text = tester.widget<Text>(finder);
        final painter = TextPainter(
          text: TextSpan(text: text.data, style: text.style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        return painter.height;
      }

      final card = find.byKey(targetCardKey);
      for (final label in ['The ghoul', 'ATK 3–3  SPD 10', 'Melee only']) {
        final finder = find.descendant(of: card, matching: find.text(label));
        expect(
          tester.getSize(finder).height,
          greaterThanOrEqualTo(naturalHeight(finder) - 0.5),
          reason: '"$label" clips at 1.3x text scale',
        );
      }
    },
  );

  testWidgets(
    'the target card never lands on the turn-order strip when the hero '
    'is panned low in battle (D1 wiring, F3)',
    (tester) async {
      await onTheTargetPhone(tester);
      const heroAt = Position(2, 30);
      const wolfAt = Position(3, 30);
      final map = FloorMap.parse(
        List.generate(
          61,
          (row) => row == 0 || row == 60 ? '#######' : '#.....#',
        ).join('\n'),
      );
      final direWolf = Actor(
        id: 'dire-wolf',
        name: 'the dire wolf',
        glyph: 'w',
        position: wolfAt,
        hp: 14,
        maxHp: 14,
        attackMin: 4,
        attackMax: 6,
        speed: 10,
        energy: actThreshold,
        resists: const {DamageType.fire},
        vulnerableTo: const {DamageType.frost},
      );
      final game = GameState(
        map: map,
        hero: Actor(
          id: 'hero',
          name: 'you',
          glyph: '@',
          position: heroAt,
          hp: 20,
          maxHp: 20,
          attackMin: 4,
          attackMax: 4,
          speed: 10,
          energy: actThreshold,
        ),
        monsters: [direWolf],
        rng: Rng(1),
        lootRng: Rng(2),
        visible: {heroAt, wolfAt},
        explored: {heroAt, wolfAt},
        buildFloor: (depth) => throw StateError('no floor below'),
        stairsDown: heroAt,
        nodes: {heroAt: GatherKind.oreVein},
        groundItems: {
          heroAt: const [
            Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
          ],
        },
      );
      final bloc = GameBloc(game: game, stepDelay: Duration.zero);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const GameScreen(palette: DungeonPalette.crypt),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(bloc.state.isBattleOpen, isTrue);

      final card = find.byKey(targetCardKey);
      final strip = find.byType(TurnOrderStrip);
      expect(card, findsOneWidget);
      expect(strip, findsOneWidget);

      bloc.add(const MapPanned(Offset(0, -30)));
      await tester.pumpAndSettle();

      expect(tester.getRect(card).overlaps(tester.getRect(strip)), isFalse);
    },
  );
}
