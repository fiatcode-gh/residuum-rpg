import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/actor_presentation.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/map_callout.dart';
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

/// A room close to the map slot's own width, so a monster comfortably
/// clear of the hero renders its callout comfortably clear of the hero's
/// own adjacent tiles too — unlike [_roomArena], whose centring margins put
/// a flipped card back over the room it was tapped from.
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

GameState _gameState({
  required String ascii,
  required Position heroAt,
  List<Actor> monsters = const [],
  Set<Position>? visible,
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
  );
}

/// A map wide or tall enough that the camera clamps to an edge instead of
/// centring — [heroAt] pinned at that edge, [monsterAt] a few cells inside
/// it so the monster's own cell lands near the same edge on screen.
/// [visible] is explicit rather than FOV-derived, so the scene never has to
/// out-chase a monster to stay known.
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

/// Pumps a standalone [MapCallout] over a fixed [size] box anchored at the
/// surface's own origin, so [WidgetTester.getRect] reads in the same local
/// space [GridGeometry] does. [textScaler] feeds the ambient `MediaQuery`
/// a physical device's system text size would turn — `MapCallout` itself
/// is pumped outside `GameScreen`'s own clamp here, so the test supplies
/// an already-clamped value directly.
Future<Rect> _pumpCallout(
  WidgetTester tester,
  GameViewState state,
  Size size, {
  TextScaler? textScaler,
}) async {
  final callout = MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: MapCallout(state: state, size: size),
      ),
    ),
  );
  await tester.pumpWidget(
    textScaler == null
        ? callout
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: callout,
          ),
  );
  return tester.getRect(find.byKey(mapCalloutKey));
}

void main() {
  testWidgets(
    'a tap 18 dp off a far known monster opens the callout with its facts, '
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
      final callout = find.byKey(mapCalloutKey);
      expect(callout, findsOneWidget);
      expect(
        find.descendant(of: callout, matching: find.text('The ghoul')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: callout, matching: find.text('HP 6/8')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: callout, matching: find.text('ATK 2–4  SPD 7')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: callout, matching: find.text('Adjacent')),
        findsOneWidget,
      );

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

    await tester.tapAt(tester.getCenter(find.byKey(mapCalloutKey)));
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, monster.id);
    expect(bloc.state.game, same(gameBefore));
    expect(find.byKey(mapCalloutKey), findsOneWidget);
  });

  testWidgets('tapping empty blank space dismisses the callout', (
    tester,
  ) async {
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
    expect(find.byKey(mapCalloutKey), findsNothing);
  });

  testWidgets(
    'tapping a floor cell dismisses the callout and still steps the hero',
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
      expect(find.byKey(mapCalloutKey), findsOneWidget);

      final adjacent = _wideHero.step(Direction.south);
      await _tapLocal(tester, geometry.centreOf(adjacent));
      await tester.pumpAndSettle();

      expect(bloc.state.inspectedActorId, isNull);
      expect(find.byKey(mapCalloutKey), findsNothing);
      expect(bloc.state.game.hero.position, adjacent);
    },
  );

  testWidgets('a long-press on the monster opens the callout', (tester) async {
    final monster = _ghoul(_farMonster);
    final bloc = await _openCrawl(
      tester,
      _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
    );
    final geometry = _mapGeometry(tester, bloc.state);

    await _longPressLocal(tester, geometry.centreOf(_farMonster));
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, monster.id);
    expect(find.byKey(mapCalloutKey), findsOneWidget);
  });

  testWidgets(
    'tapping a distant known wall dismisses the callout, without moving the '
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
      expect(find.byKey(mapCalloutKey), findsNothing);
      expect(bloc.state.game.hero.position, heroBefore);
      expect(bloc.state.log, logBefore);
    },
  );

  testWidgets("tapping the hero's own cell dismisses an open callout", (
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

    await _tapLocal(tester, geometry.centreOf(_wideHero));
    await tester.pumpAndSettle();

    expect(bloc.state.inspectedActorId, isNull);
    expect(find.byKey(mapCalloutKey), findsNothing);
    expect(bloc.state.game.hero.position, heroBefore);
  });

  testWidgets('a long-press on empty ground dismisses an open callout', (
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
    expect(find.byKey(mapCalloutKey), findsNothing);
    expect(bloc.state.game.hero.position, heroBefore);
  });

  testWidgets('a timeline actor tap still opens the sheet in battle', (
    tester,
  ) async {
    const adjacent = Position(1, 2);
    final monster = _ghoul(adjacent);
    final bloc = await _openCrawl(
      tester,
      _gameState(ascii: _roomArena, heroAt: _hero, monsters: [monster]),
    );
    expect(bloc.state.isBattleOpen, isTrue);

    await tester.tap(find.byKey(const Key('timeline-actor-ghoul-1-1')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(bloc.state.inspectedActorId, isNull);
    expect(find.byKey(mapCalloutKey), findsNothing);
  });

  testWidgets('the map rect is unchanged with and without the callout', (
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

    expect(find.byKey(mapCalloutKey), findsOneWidget);
    expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);
  });

  testWidgets(
    'a monster near the right edge flips the card left, still inside the '
    'slot',
    (tester) async {
      const size = Size(392.7, 441.8);
      const heroAt = Position(29, 5);
      const monsterAt = Position(26, 5);
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

      final cardRect = await _pumpCallout(tester, state, size);

      final geometry = GridGeometry.camera(
        size,
        30,
        12,
        state.cameraFocus,
        state.pan,
      );
      final cellRect = geometry.rectOf(monsterAt);

      expect(cardRect.right, lessThanOrEqualTo(cellRect.left));
      expect(cardRect.left, greaterThanOrEqualTo(8));
      expect(cardRect.top, greaterThanOrEqualTo(8));
      expect(cardRect.right, lessThanOrEqualTo(size.width - 8));
      expect(cardRect.bottom, lessThanOrEqualTo(size.height - 8));
    },
  );

  testWidgets(
    'a monster near the top edge places the card below, still inside the '
    'slot',
    (tester) async {
      const size = Size(392.7, 441.8);
      const heroAt = Position(6, 0);
      const monsterAt = Position(6, 2);
      final game = _clampedGameState(
        columns: 12,
        rows: 30,
        heroAt: heroAt,
        monsterAt: monsterAt,
      );
      final state = GameViewState(
        game: game,
        log: const [],
        inspectedActorId: 'ghoul-1',
      );

      final cardRect = await _pumpCallout(tester, state, size);

      final geometry = GridGeometry.camera(
        size,
        12,
        30,
        state.cameraFocus,
        state.pan,
      );
      final cellRect = geometry.rectOf(monsterAt);

      expect(cardRect.top, greaterThanOrEqualTo(cellRect.bottom));
      expect(cardRect.left, greaterThanOrEqualTo(8));
      expect(cardRect.top, greaterThanOrEqualTo(8));
      expect(cardRect.right, lessThanOrEqualTo(size.width - 8));
      expect(cardRect.bottom, lessThanOrEqualTo(size.height - 8));
    },
  );

  testWidgets('a known actor that has left sight renders no callout', (
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
            child: MapCallout(state: state, size: size),
          ),
        ),
      ),
    );

    expect(find.byKey(mapCalloutKey), findsNothing);
  });

  testWidgets(
    "the callout's name, HP and fact rows stay unclipped at 1.3x text scale",
    (tester) async {
      const size = Size(392.7, 441.8);
      const heroAt = Position(6, 5);
      const monsterAt = Position(20, 5);
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
      await _pumpCallout(tester, state, size, textScaler: scaler);

      double naturalHeight(Finder finder) {
        final text = tester.widget<Text>(finder);
        final painter = TextPainter(
          text: TextSpan(text: text.data, style: text.style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        return painter.height;
      }

      final callout = find.byKey(mapCalloutKey);
      for (final label in [
        'The ghoul',
        'HP 10/10',
        'ATK 3–3  SPD 10',
        'Adjacent',
      ]) {
        final finder = find.descendant(of: callout, matching: find.text(label));
        expect(
          tester.getSize(finder).height,
          greaterThanOrEqualTo(naturalHeight(finder) - 0.5),
          reason: '"$label" clips at 1.3x text scale',
        );
      }
    },
  );
}
