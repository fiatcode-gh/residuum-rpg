import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/glyph_plan.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/log_line.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:residuum_app/game/glyph_marks.dart';
import 'package:residuum_app/game/dungeon_depth.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _stairsArena = '''
#######
#.....#
#..>..#
#.....#
#######''';

// 40 interior columns (520dp of floor at mapCellWidth=13) still overflow the
// 360dp test viewport used below, which is what the camera-clamping tests
// in this file need real overflow to clamp against.
const _overflowingArena = '''
##########################################
#........................................#
#........................................#
#........................................#
##########################################''';

Actor _heroAt(Position position) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: position,
  hp: 20,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

Actor _ghoulAt(Position position, {String id = 'ghoul-1'}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: position,
  hp: 10,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: 10,
  energy: actThreshold,
);

GameViewState _viewState({
  Offset pan = Offset.zero,
  String? armedSpellId,
  String? selectedActorId,
  List<Actor>? monsters,
}) {
  const heroPosition = Position(1, 1);
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, heroPosition, fovRadius);
  return GameViewState(
    game: GameState(
      map: map,
      hero: _heroAt(heroPosition),
      monsters: monsters ?? [_ghoulAt(const Position(1, 2))],
      rng: Rng(1),
      lootRng: Rng(2),
      visible: visible,
      explored: {...visible, const Position(5, 3)},
      nodes: {const Position(4, 2): GatherKind.oreVein},
      buildFloor: (depth) => throw StateError('no floor below'),
      spells: spellsById,
    ),
    log: const [],
    pan: pan,
    armedSpellId: armedSpellId,
    selectedActorId: selectedActorId,
  );
}

GameViewState _stairsViewState() {
  const heroPosition = Position(1, 1);
  final map = FloorMap.parse(_stairsArena);
  final visible = computeFov(map, heroPosition, fovRadius);
  return GameViewState(
    game: GameState(
      map: map,
      hero: _heroAt(heroPosition),
      monsters: const [],
      rng: Rng(1),
      lootRng: Rng(2),
      visible: visible,
      explored: visible,
      buildFloor: (depth) => throw StateError('no floor below'),
    ),
    log: const [],
  );
}

GameViewState _overflowingViewState(Position hero, {Offset pan = Offset.zero}) {
  final map = FloorMap.parse(_overflowingArena);
  final visible = computeFov(map, hero, fovRadius);
  return GameViewState(
    game: GameState(
      map: map,
      hero: _heroAt(hero),
      monsters: const [],
      rng: Rng(1),
      lootRng: Rng(2),
      visible: visible,
      explored: visible,
      buildFloor: (depth) => throw StateError('no floor below'),
    ),
    log: const [],
    pan: pan,
  );
}

({Position position, String glyph, double opacity, bool marked}) _cell(
  GlyphCell cell,
) => (
  position: cell.position,
  glyph: cell.glyph,
  opacity: cell.opacity,
  marked: cell.marked,
);

Future<Uint8List> _renderDepth(Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const DungeonDepthPainter().paint(canvas, size);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(size.width.ceil(), size.height.ceil());
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

Color _depthPixel(Uint8List pixels, Size size, int x, int y) {
  final offset = (y * size.width.toInt() + x) * 4;
  return Color.fromARGB(
    pixels[offset + 3],
    pixels[offset],
    pixels[offset + 1],
    pixels[offset + 2],
  );
}

Future<Uint8List> _renderPixels(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
) async {
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
    } finally {
      image.dispose();
    }
  });
  return pixels!;
}

Future<Uint8List> _renderScene(WidgetTester tester, GameViewState state) async {
  const key = Key('scene-depth-surface');
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: 360,
          height: 360,
          child: DungeonSceneHost(
            state: state,
            palette: DungeonPalette.crypt,
            onTap: (_) {},
            onPan: (_) {},
            onLongPress: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return _renderPixels(tester, boundary);
}

Future<Uint8List> _renderBackgroundOnly(
  WidgetTester tester,
  GameViewState state,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 360,
        height: 360,
        child: DungeonSceneHost(
          state: state,
          palette: DungeonPalette.crypt,
          onTap: (_) {},
          onPan: (_) {},
          onLongPress: (_) {},
        ),
      ),
    ),
  );
  final builder = tester
      .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
      .backgroundBuilder!;
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: const Key('background-only-surface'),
        child: SizedBox(
          width: 360,
          height: 360,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('background-only-surface')),
  );
  return _renderPixels(tester, boundary);
}

void main() {
  testWidgets(
    'the viewport depth has broad variation and exact repeatability',
    (tester) async {
      const size = Size(360, 360);
      final first = await tester.runAsync(() => _renderDepth(size));
      final second = await tester.runAsync(() => _renderDepth(size));

      expect(second!, orderedEquals(first!));
      expect(
        _depthPixel(first, size, 90, 90),
        isNot(_depthPixel(first, size, 270, 270)),
      );
      expect(
        DungeonDepthPainter().shouldRepaint(const DungeonDepthPainter()),
        isFalse,
      );
    },
  );

  testWidgets(
    'background-only pixels ignore hidden topology and view-state changes',
    (tester) async {
      final original = _overflowingViewState(const Position(1, 1));
      final hiddenWallMap = FloorMap.parse(
        '######################\n'
        '#....................#\n'
        '#....................#\n'
        '#...................##\n'
        '######################',
      );
      final alternateTopology = GameViewState(
        game: original.game.copyWith(map: hiddenWallMap),
        log: original.log,
        pan: original.pan,
      );
      expect(
        glyphPlan(original.game).map(_cell),
        orderedEquals(glyphPlan(alternateTopology.game).map(_cell)),
      );
      final movedHero = _overflowingViewState(const Position(2, 1));
      final panned = GameViewState(
        game: original.game,
        log: original.log,
        pan: const Offset(72, -36),
      );
      final selectedActor = _viewState(selectedActorId: 'ghoul-1');

      final baseline = await _renderBackgroundOnly(tester, original);
      expect(
        await _renderBackgroundOnly(tester, alternateTopology),
        orderedEquals(baseline),
      );
      expect(
        await _renderBackgroundOnly(tester, movedHero),
        orderedEquals(baseline),
      );
      expect(
        await _renderBackgroundOnly(tester, panned),
        orderedEquals(baseline),
      );
      expect(
        await _renderBackgroundOnly(tester, selectedActor),
        orderedEquals(baseline),
      );

      const size = Size(360, 360);
      expect(
        _depthPixel(baseline, size, 90, 90),
        isNot(_depthPixel(baseline, size, 270, 270)),
      );
    },
  );

  testWidgets('Flame keeps the atmosphere visible beneath unknown map cells', (
    tester,
  ) async {
    final state = _overflowingViewState(const Position(1, 1));
    final unknown = GameViewState(
      game: state.game.copyWith(visible: const {}, explored: const {}),
      log: state.log,
      pan: state.pan,
    );
    final background = await _renderBackgroundOnly(tester, unknown);
    final scene = await _renderScene(tester, unknown);

    const size = Size(360, 360);
    for (final point in [(10, 10), (350, 10), (10, 350), (350, 350)]) {
      expect(
        _depthPixel(scene, size, point.$1, point.$2),
        _depthPixel(background, size, point.$1, point.$2),
      );
    }
    expect(
      _depthPixel(scene, size, 10, 10),
      isNot(_depthPixel(scene, size, 350, 350)),
    );
  });
  testWidgets('the scene installs a non-semantic viewport backdrop', (
    tester,
  ) async {
    final taps = <Position>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 360,
          child: DungeonSceneHost(
            state: _viewState(),
            palette: DungeonPalette.crypt,
            onTap: taps.add,
            onPan: (_) {},
            onLongPress: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final gameWidgetFinder = find.byKey(dungeonSceneKey);
    final gameWidget = tester.widget<GameWidget<FlameGame>>(gameWidgetFinder);
    expect(gameWidget.backgroundBuilder, isNotNull);
    final backgroundPointer = find.descendant(
      of: gameWidgetFinder,
      matching: find.byType(IgnorePointer),
    );
    final backgroundSemantics = find.descendant(
      of: gameWidgetFinder,
      matching: find.byType(ExcludeSemantics),
    );
    expect(backgroundPointer, findsOneWidget);
    expect(tester.widget<IgnorePointer>(backgroundPointer).ignoring, isTrue);
    expect(backgroundSemantics, findsOneWidget);
    expect(
      tester.widget<ExcludeSemantics>(backgroundSemantics).excluding,
      isTrue,
    );
    final paint = find.descendant(
      of: gameWidgetFinder,
      matching: find.byType(CustomPaint),
    );
    expect(paint, findsOneWidget);
    expect(tester.getRect(paint), tester.getRect(gameWidgetFinder));

    await tester.tapAt(tester.getCenter(gameWidgetFinder));
    await tester.pump(const Duration(milliseconds: 50));
    expect(taps, isNotEmpty);
  });
  test('the scene snapshot preserves glyph projection and camera facts', () {
    final state = _viewState(
      pan: const Offset(12, -8),
      armedSpellId: 'firebolt',
    );

    final snapshot = DungeonSceneSnapshot.fromViewState(state);

    expect(snapshot.columns, 7);
    expect(snapshot.rows, 5);
    expect(snapshot.focus, state.cameraFocus);
    expect(snapshot.heroPosition, state.game.hero.position);
    expect(snapshot.pan, const Offset(12, -8));
    expect(
      snapshot.cells.map(_cell),
      glyphPlan(state.game, markedIds: state.armedTargets).map(_cell),
    );
    expect(
      () => snapshot.cells.add(
        const GlyphCell(Position(0, 0), '?', Colors.white, fullOpacity),
      ),
      throwsUnsupportedError,
    );
  });

  test('the snapshot reuses a projection across a view-only pan', () {
    final state = _viewState();
    final snapshot = DungeonSceneSnapshot.fromViewState(state);
    final panned = snapshot.withViewport(
      columns: state.game.map.width,
      rows: state.game.map.height,
      focus: state.game.hero.position,
      pan: const Offset(12, -8),
    );

    expect(identical(panned.cells, snapshot.cells), isTrue);
  });

  test(
    'hero light origin is independent of camera focus and survives pan reuse',
    () {
      final selected = _ghoulAt(const Position(2, 2));
      final state = _viewState(
        selectedActorId: selected.id,
        monsters: [selected],
      );
      final snapshot = DungeonSceneSnapshot.fromViewState(state);
      final panned = snapshot.withViewport(
        columns: snapshot.columns,
        rows: snapshot.rows,
        focus: state.cameraFocus,
        pan: const Offset(12, -8),
      );

      expect(snapshot.focus, selected.position);
      final terrainAtHero = snapshot.cells.singleWhere(
        (cell) =>
            cell.layer == GlyphLayer.terrain &&
            cell.position == state.game.hero.position,
      );
      expect(
        glyphInk(terrainAtHero, snapshot.heroPosition),
        isNot(glyphInk(terrainAtHero, snapshot.focus)),
      );
      expect(snapshot.heroPosition, state.game.hero.position);
      expect(panned.heroPosition, state.game.hero.position);
      expect(identical(panned.cells, snapshot.cells), isTrue);
    },
  );

  testWidgets('renders known terrain glyphs as live scene text', (
    tester,
  ) async {
    final source = _stairsViewState();
    final visible = {
      const Position(0, 0),
      const Position(1, 1),
      const Position(3, 2),
    };
    final remembered = const Position(5, 3);
    final state = GameViewState(
      game: source.game.copyWith(
        visible: visible,
        explored: {...visible, remembered},
      ),
      log: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 360,
          child: DungeonSceneHost(
            state: state,
            palette: DungeonPalette.crypt,
            onTap: (_) {},
            onPan: (_) {},
            onLongPress: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final world = tester
        .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
        .game!
        .world;
    PositionComponent terrainAt(Position position) =>
        world.children.whereType<PositionComponent>().singleWhere(
          (component) =>
              component.priority == GlyphLayer.terrain.index &&
              component.position ==
                  Vector2(
                    position.x * mapCellWidth,
                    position.y * mapCellHeight,
                  ),
        );
    TextComponent textAt(Position position) =>
        terrainAt(position).children.whereType<TextComponent>().single;

    expect(textAt(const Position(0, 0)).text, '#');
    expect(textAt(const Position(1, 1)).text, '·');
    expect(textAt(const Position(3, 2)).text, '>');
    expect(
      (textAt(const Position(1, 1)).textRenderer as TextPaint).style.color,
      glyphInk(
        glyphPlan(state.game).singleWhere(
          (cell) =>
              cell.layer == GlyphLayer.terrain &&
              cell.position == const Position(1, 1),
        ),
        state.game.hero.position,
      ),
    );
    expect(textAt(remembered).text, '·');
    expect(
      (textAt(remembered).textRenderer as TextPaint).style.color!.a,
      closeTo(rememberedOpacity, 0.001),
    );
    expect(
      world.children.whereType<PositionComponent>().where(
        (component) =>
            component.position == Vector2(5 * mapCellWidth, mapCellHeight),
      ),
      isEmpty,
    );

    final hero = world.children.whereType<PositionComponent>().singleWhere(
      (component) =>
          component.priority == GlyphLayer.hero.index &&
          component.position == Vector2(mapCellWidth, mapCellHeight),
    );
    expect(
      world.children.toList().indexOf(terrainAt(const Position(1, 1))),
      lessThan(world.children.toList().indexOf(hero)),
    );
    expect(hero.children.whereType<TextComponent>().single.text, '@');
  });
  testWidgets('retained terrain recolours for hero movement, not pan', (
    tester,
  ) async {
    Future<void> pumpScene(GameViewState state) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 360,
            child: DungeonSceneHost(
              state: state,
              palette: DungeonPalette.crypt,
              onTap: (_) {},
              onPan: (_) {},
              onLongPress: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    PositionComponent terrainAt(World world, Position position) =>
        world.children.whereType<PositionComponent>().singleWhere(
          (component) =>
              component.priority == GlyphLayer.terrain.index &&
              component.position ==
                  Vector2(
                    position.x * mapCellWidth,
                    position.y * mapCellHeight,
                  ),
        );
    Color inkOf(PositionComponent component) =>
        (component.children.whereType<TextComponent>().single.textRenderer
                as TextPaint)
            .style
            .color!;

    final firstState = _overflowingViewState(const Position(1, 1));
    await pumpScene(firstState);
    final world = tester
        .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
        .game!
        .world;
    final terrain = terrainAt(world, const Position(3, 1));
    final originalInk = inkOf(terrain);

    final movedState = _overflowingViewState(const Position(2, 1));
    await pumpScene(movedState);
    final movedInk = inkOf(terrain);
    expect(terrainAt(world, const Position(3, 1)), same(terrain));
    expect(movedInk, isNot(originalInk));

    final pannedState = GameViewState(
      game: movedState.game,
      log: movedState.log,
      pan: const Offset(12, -8),
    );
    await pumpScene(pannedState);
    expect(terrainAt(world, const Position(3, 1)), same(terrain));
    expect(inkOf(terrain), movedInk);
  });

  testWidgets(
    'does not rebuild the Flame scene when only the log drawer extent '
    'changes',
    (tester) async {
      const hostKey = Key('drawer-extent-scene');

      Future<void> pumpScene(GameViewState state) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 360,
              height: 360,
              child: DungeonSceneHost(
                key: hostKey,
                state: state,
                palette: DungeonPalette.crypt,
                onTap: (_) {},
                onPan: (_) {},
                onLongPress: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
      }

      final state = _viewState();
      await pumpScene(state);
      final gameBefore = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game;
      final heroBefore = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .whereType<PositionComponent>()
          .singleWhere(
            (component) => component.priority == GlyphLayer.hero.index,
          );

      final withDrawerOpen = GameViewState(
        game: state.game,
        log: state.log,
        pan: state.pan,
        armedSpellId: state.armedSpellId,
        actorIdentity: state.actorIdentity,
        selectedActorId: state.selectedActorId,
        logDrawerExtent: LogDrawerExtent.full,
      );
      await pumpScene(withDrawerOpen);
      final gameAfter = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game;
      expect(gameAfter, same(gameBefore));
      expect(
        tester
            .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
            .game!
            .world
            .children,
        contains(same(heroBefore)),
      );
    },
  );

  testWidgets(
    'the Flame scene projects taps and pans as presentation intents',
    (tester) async {
      final taps = <Position>[];
      final pans = <Offset>[];
      final state = _viewState();

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 360,
              child: DungeonSceneHost(
                state: state,
                palette: DungeonPalette.crypt,
                onTap: taps.add,
                onPan: pans.add,
                onLongPress: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final scene = find.byKey(dungeonSceneKey);
      final size = tester.getSize(scene);
      final geometry = GridGeometry.camera(
        size,
        state.game.map.width,
        state.game.map.height,
        state.game.hero.position,
      );
      final local = geometry.centreOf(const Position(2, 1));

      await tester.tapAt(tester.getTopLeft(scene) + local);
      await tester.dragFrom(
        tester.getCenter(scene),
        const Offset(48, 24),
        touchSlopX: 0,
        touchSlopY: 0,
      );

      await tester.pump(const Duration(milliseconds: 50));

      expect(taps, [const Position(2, 1)]);
      expect(
        pans.fold(Offset.zero, (sum, delta) => sum + delta),
        const Offset(48, 24),
      );
    },
  );

  testWidgets(
    'the host keeps Flame projection and hits current across pan and focus',
    (tester) async {
      final taps = <Position>[];
      const hostKey = Key('overflowing-dungeon-scene');

      Future<void> pumpScene(GameViewState state) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: DungeonSceneHost(
                  key: hostKey,
                  state: state,
                  palette: DungeonPalette.crypt,
                  onTap: taps.add,
                  onPan: (_) {},
                  onLongPress: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      Future<GridGeometry> tapProjectedTile(
        GameViewState state,
        Position tile,
      ) async {
        final scene = find.byKey(dungeonSceneKey);
        final size = tester.getSize(scene);
        final geometry = GridGeometry.camera(
          size,
          state.game.map.width,
          state.game.map.height,
          state.game.hero.position,
          state.pan,
        );
        final local = geometry.centreOf(tile);
        final game = tester.widget<GameWidget<FlameGame>>(scene).game!;
        final worldPoint = game.camera.globalToLocal(
          Vector2(local.dx, local.dy),
        );

        expect(
          worldPoint.x,
          closeTo((tile.x + 0.5) * geometry.cellWidth, 0.001),
        );
        expect(
          worldPoint.y,
          closeTo((tile.y + 0.5) * geometry.cellHeight, 0.001),
        );

        await tester.tapAt(tester.getTopLeft(scene) + local);
        await tester.pump(const Duration(milliseconds: 50));
        expect(taps.last, tile);
        return geometry;
      }

      // The overflow arena's 40 interior columns give the 360dp viewport
      // (extent 42 * 13 = 546dp) 186dp of scrollable range: column 20 sits
      // comfortably mid-scroll, unclamped; column 38 sits two columns from
      // the far wall, past the scrollable range, so the camera clamps at
      // its far bound (360 - 546 = -186) instead of centring on it exactly.
      var state = _overflowingViewState(const Position(20, 1));
      await pumpScene(state);
      expect(
        (await tapProjectedTile(state, const Position(21, 1))).origin.dx,
        closeTo(-86.5, 0.001),
      );

      final glyphsBeforeFocus = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .toList(growable: false);
      final heroBeforeFocus = glyphsBeforeFocus.last as PositionComponent;

      state = _overflowingViewState(const Position(38, 1));
      await pumpScene(state);
      final glyphsAfterFocus = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children;
      expect(glyphsAfterFocus, contains(same(heroBeforeFocus)));
      expect(
        heroBeforeFocus.position,
        Vector2(38 * mapCellWidth, mapCellHeight),
      );
      expect(
        (await tapProjectedTile(state, const Position(38, 1))).origin.dx,
        closeTo(-186, 0.001),
      );

      final glyphsBeforePan = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .toList(growable: false);

      state = _overflowingViewState(
        const Position(38, 1),
        pan: const Offset(1000, 0),
      );
      await pumpScene(state);
      expect(
        tester
            .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
            .game!
            .world
            .children,
        orderedEquals(glyphsBeforePan),
      );
      expect(
        (await tapProjectedTile(state, const Position(5, 1))).origin.dx,
        0,
      );

      state = _overflowingViewState(const Position(20, 1));
      await pumpScene(state);
      expect(
        (await tapProjectedTile(state, const Position(21, 1))).origin.dx,
        closeTo(-86.5, 0.001),
      );

      expect(taps, const [
        Position(21, 1),
        Position(38, 1),
        Position(5, 1),
        Position(21, 1),
      ]);
    },
  );

  testWidgets(
    'a long-press projects to a tile and leaves taps and drags intact',
    (tester) async {
      final taps = <Position>[];
      final longPresses = <Position>[];
      final state = _viewState();

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 360,
              child: DungeonSceneHost(
                state: state,
                palette: DungeonPalette.crypt,
                onTap: taps.add,
                onPan: (_) {},
                onLongPress: longPresses.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final scene = find.byKey(dungeonSceneKey);
      final size = tester.getSize(scene);
      final geometry = GridGeometry.camera(
        size,
        state.game.map.width,
        state.game.map.height,
        state.game.hero.position,
      );
      final local = geometry.centreOf(const Position(2, 1));

      await tester.longPressAt(tester.getTopLeft(scene) + local);
      await tester.pump(const Duration(milliseconds: 50));
      expect(longPresses, [const Position(2, 1)]);

      await tester.tapAt(tester.getTopLeft(scene) + local);
      await tester.dragFrom(
        tester.getCenter(scene),
        const Offset(48, 24),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(taps, [const Position(2, 1)]);
      expect(longPresses, const [Position(2, 1)]);
    },
  );
  test('snapshot carries selected actor presentation facts and focus', () {
    final first = _ghoulAt(const Position(1, 2));
    final second = _ghoulAt(const Position(2, 2), id: 'ghoul-2');
    final state = _viewState(
      monsters: [first, second],
      armedSpellId: 'firebolt',
      selectedActorId: second.id,
    );

    final snapshot = DungeonSceneSnapshot.fromViewState(state);

    expect(snapshot.focus, second.position);
    final cells = snapshot.cells.where(
      (cell) => cell.layer == GlyphLayer.monster,
    );
    expect(cells.map((cell) => cell.glyph), ['g', 'g']);
    expect(cells.map((cell) => cell.badge), ['¹', '²']);
    expect(cells.map((cell) => cell.marked), [true, true]);
    expect(cells.map((cell) => cell.selected), [false, true]);
  });

  test('pan-only viewport reuse preserves selected projection and focus', () {
    final state = _viewState(selectedActorId: 'ghoul-1');
    final snapshot = DungeonSceneSnapshot.fromViewState(state);

    final panned = snapshot.withViewport(
      columns: snapshot.columns,
      rows: snapshot.rows,
      focus: state.cameraFocus,
      pan: const Offset(12, -8),
    );

    expect(identical(panned.cells, snapshot.cells), isTrue);
    expect(panned.focus, state.cameraFocus);
    expect(panned.pan, const Offset(12, -8));
  });

  testWidgets('keeps glyph text, halo, badge and reticle inside their cells', (
    tester,
  ) async {
    Rect childBounds(PositionComponent child) {
      final width = child.size.x * child.scale.x;
      final height = child.size.y * child.scale.y;
      return Rect.fromLTWH(
        child.position.x - width * child.anchor.x,
        child.position.y - height * child.anchor.y,
        width,
        height,
      );
    }

    Future<void> pumpScene(GameViewState state) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 360,
            child: DungeonSceneHost(
              state: state,
              palette: DungeonPalette.crypt,
              onTap: (_) {},
              onPan: (_) {},
              onLongPress: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    PositionComponent glyphAt(
      World world,
      GlyphLayer layer,
      Position position,
    ) => world.children.whereType<PositionComponent>().singleWhere(
      (component) =>
          component.priority == layer.index &&
          component.position ==
              Vector2(position.x * mapCellWidth, position.y * mapCellHeight),
    );

    Future<void> expectContained(PositionComponent glyph) async {
      expect(glyph.size, Vector2(mapCellWidth, mapCellHeight));
      for (final child in glyph.children.whereType<PositionComponent>()) {
        final bounds = childBounds(child);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(mapCellWidth));
        if (child is TextComponent && child.anchor == Anchor.center) {
          expect(bounds.top, greaterThanOrEqualTo(-1.2));
          expect(bounds.bottom, lessThanOrEqualTo(mapCellHeight + 1.2));
        } else {
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.bottom, lessThanOrEqualTo(mapCellHeight));
        }
      }
    }

    await pumpScene(
      _viewState(
        armedSpellId: 'firebolt',
        selectedActorId: 'ghoul-1',
        monsters: [
          _ghoulAt(const Position(1, 2)),
          _ghoulAt(const Position(2, 2), id: 'ghoul-2'),
        ],
      ),
    );
    final world = tester
        .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
        .game!
        .world;
    final hero = glyphAt(world, GlyphLayer.hero, const Position(1, 1));
    final monster = glyphAt(world, GlyphLayer.monster, const Position(1, 2));
    await expectContained(hero);
    await expectContained(monster);
    expect(hero.children.whereType<CircleComponent>(), hasLength(1));
    expect(
      hero.children.whereType<CircleComponent>().single.radius,
      closeTo(mapCellWidth * 0.5, 0.0001),
    );
    expect(monster.children.whereType<TextComponent>(), hasLength(2));
    // A monster both marked (armed target) and selected carries exactly one
    // reticle — selection supersedes marking rather than stacking both, the
    // regression the old square-plus-circle outline pair used to allow.
    final monsterReticles = monster.children
        .whereType<PositionComponent>()
        .where((child) => child is! TextComponent);
    expect(monsterReticles, hasLength(1));

    await pumpScene(_stairsViewState());
    final stairsWorld = tester
        .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
        .game!
        .world;
    final stairs = glyphAt(
      stairsWorld,
      GlyphLayer.terrain,
      const Position(3, 2),
    );
    await expectContained(stairs);
  });

  testWidgets(
    'retained actor component synchronizes badge and reticle, superseding '
    'marking with selection instead of stacking both',
    (tester) async {
      Future<void> pumpScene(GameViewState state) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 360,
              height: 360,
              child: DungeonSceneHost(
                state: state,
                palette: DungeonPalette.crypt,
                onTap: (_) {},
                onPan: (_) {},
                onLongPress: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
      }

      final first = _ghoulAt(const Position(1, 2));
      final second = _ghoulAt(const Position(2, 2), id: 'ghoul-2');
      final initial = _viewState(monsters: [first, second]);
      await pumpScene(initial);

      final world = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world;
      PositionComponent actorComponent() =>
          world.children.whereType<PositionComponent>().singleWhere(
            (component) =>
                component.priority == GlyphLayer.monster.index &&
                component.position ==
                    Vector2(
                      first.position.x * mapCellWidth,
                      first.position.y * mapCellHeight,
                    ),
          );

      final retained = actorComponent();
      Rect badgeBounds() {
        final badge = retained.children.whereType<TextComponent>().last;
        final width = badge.size.x * badge.scale.x;
        final height = badge.size.y * badge.scale.y;
        return Rect.fromLTWH(
          badge.position.x - width * badge.anchor.x,
          badge.position.y - height * badge.anchor.y,
          width,
          height,
        );
      }

      void expectBadgeContained() {
        final bounds = badgeBounds();
        expect(bounds.left, greaterThan(0));
        expect(bounds.top, greaterThan(0));
        expect(bounds.right, lessThan(mapCellWidth));
        expect(bounds.bottom, lessThan(mapCellHeight));
      }

      Iterable<PositionComponent> reticlesOf(PositionComponent actor) => actor
          .children
          .whereType<PositionComponent>()
          .where((child) => child is! TextComponent);

      expectBadgeContained();
      expect(
        retained.children.whereType<TextComponent>().map((child) => child.text),
        ['g', '¹'],
      );
      expect(reticlesOf(retained), isEmpty);

      final selected = GameViewState(
        game: initial.game,
        log: initial.log,
        actorIdentity: initial.actorIdentity,
        selectedActorId: first.id,
      );
      await pumpScene(selected);
      expect(actorComponent(), same(retained));
      expect(reticlesOf(retained), hasLength(1));
      final reticle = reticlesOf(retained).single;
      expectBadgeContained();

      final targeted = GameViewState(
        game: initial.game,
        log: initial.log,
        actorIdentity: initial.actorIdentity,
        selectedActorId: first.id,
        armedSpellId: 'firebolt',
      );
      await pumpScene(targeted);
      expect(actorComponent(), same(retained));
      // Selected and marked at once still carries exactly one reticle, the
      // same retained instance — selection supersedes marking rather than
      // stacking a second shape.
      expect(reticlesOf(retained), hasLength(1));
      expect(reticlesOf(retained).single, same(reticle));
      expectBadgeContained();

      final cleared = GameViewState(
        game: initial.game,
        log: initial.log,
        actorIdentity: initial.actorIdentity,
      );
      await pumpScene(cleared);
      expect(actorComponent(), same(retained));
      expect(reticlesOf(retained), isEmpty);
      expectBadgeContained();
      expect(
        retained.children.whereType<TextComponent>().map((child) => child.text),
        ['g', '¹'],
      );
    },
  );
}
