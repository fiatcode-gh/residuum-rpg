import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_material.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/dungeon_scene_material.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/glyph_plan.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

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

const _overflowingArena = '''
######################
#....................#
#....................#
#....................#
######################''';

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

Future<Color> _materialPixel(
  MaterialComponent component,
  GameViewState state,
  Offset point,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..drawColor(dungeonVoid, ui.BlendMode.src);
  component.render(canvas);
  final image = await recorder.endRecording().toImage(
    (state.game.map.width * cameraCellSize).round(),
    (state.game.map.height * cameraCellSize).round(),
  );
  try {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final offset = (point.dy.round() * image.width + point.dx.round()) * 4;
    return Color.fromARGB(
      rgba!.getUint8(offset + 3),
      rgba.getUint8(offset),
      rgba.getUint8(offset + 1),
      rgba.getUint8(offset + 2),
    );
  } finally {
    image.dispose();
  }
}

void main() {
  test('the scene snapshot preserves glyph projection and camera facts', () {
    final state = _viewState(
      pan: const Offset(12, -8),
      armedSpellId: 'firebolt',
    );

    final snapshot = DungeonSceneSnapshot.fromViewState(
      state,
      DungeonPalette.crypt,
    );

    expect(snapshot.columns, 7);
    expect(snapshot.rows, 5);
    expect(snapshot.focus, const Position(1, 1));
    expect(snapshot.pan, const Offset(12, -8));
    expect(
      snapshot.cells.map(_cell),
      glyphPlan(
        state.game,
        DungeonPalette.crypt,
        markedIds: state.armedTargets,
      ).map(_cell),
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
    final snapshot = DungeonSceneSnapshot.fromViewState(
      state,
      DungeonPalette.crypt,
    );
    final panned = snapshot.withViewport(
      columns: state.game.map.width,
      rows: state.game.map.height,
      focus: state.game.hero.position,
      pan: const Offset(12, -8),
    );

    expect(identical(panned.cells, snapshot.cells), isTrue);
  });

  testWidgets(
    'synchronizes retained material for a new projection but not a pan',
    (tester) async {
      const hostKey = Key('material-synchronization-scene');

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

      final sampledFloor = Offset(11.5 * cameraCellSize, 1.94 * cameraCellSize);
      var state = _overflowingViewState(const Position(10, 1));
      await pumpScene(state);
      final materialBefore = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .whereType<MaterialComponent>()
          .single;
      final planBefore = materialBefore.plan;
      final outputBefore = (await tester.runAsync(
        () => _materialPixel(materialBefore, state, sampledFloor),
      ))!;

      state = _overflowingViewState(const Position(18, 1));
      await pumpScene(state);
      final materialAfterProjection = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .whereType<MaterialComponent>()
          .single;
      final planAfterProjection = materialAfterProjection.plan;
      final outputAfterProjection = (await tester.runAsync(
        () => _materialPixel(materialAfterProjection, state, sampledFloor),
      ))!;

      expect(materialAfterProjection, same(materialBefore));
      expect(planAfterProjection, isNot(same(planBefore)));
      expect(planAfterProjection.heroPosition, const Position(18, 1));
      expect(outputAfterProjection, isNot(outputBefore));

      state = GameViewState(
        game: state.game,
        log: state.log,
        pan: const Offset(1000, 0),
        armedSpellId: state.armedSpellId,
        actorIdentity: state.actorIdentity,
        selectedActorId: state.selectedActorId,
      );
      await pumpScene(state);
      final materialAfterPan = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .whereType<MaterialComponent>()
          .single;
      final outputAfterPan = (await tester.runAsync(
        () => _materialPixel(materialAfterPan, state, sampledFloor),
      ))!;

      expect(materialAfterPan, same(materialBefore));
      expect(materialAfterPan.plan, same(planAfterProjection));
      expect(outputAfterPan, outputAfterProjection);
    },
  );

  test('selects stair glyphs from material facts, not terrain characters', () {
    // arrange — material and glyph characters deliberately disagree. Both
    // stair kinds must be retained, while terminal-looking terrain in floor
    // and wall facts remains suppressed.
    const down = Position(1, 1);
    const up = Position(2, 1);
    const floor = Position(3, 1);
    const wall = Position(4, 1);
    const hero = Position(5, 1);
    final material = MaterialPlan(
      cells: [
        MaterialCell(
          position: down,
          kind: MaterialTileKind.stairsDown,
          knowledge: MaterialKnowledge.visible,
        ),
        MaterialCell(
          position: up,
          kind: MaterialTileKind.stairsUp,
          knowledge: MaterialKnowledge.visible,
        ),
        MaterialCell(
          position: floor,
          kind: MaterialTileKind.floor,
          knowledge: MaterialKnowledge.visible,
        ),
        MaterialCell(
          position: wall,
          kind: MaterialTileKind.wall,
          knowledge: MaterialKnowledge.visible,
        ),
      ],
      marks: {},
      masonry: {},
      heroPosition: hero,
    );
    const glyphs = [
      GlyphCell(down, '#', Colors.white, fullOpacity),
      GlyphCell(up, '.', Colors.white, fullOpacity),
      GlyphCell(floor, '>', Colors.white, fullOpacity),
      GlyphCell(wall, '<', Colors.white, fullOpacity),
      GlyphCell(hero, '@', Colors.white, fullOpacity, layer: GlyphLayer.hero),
    ];

    // act
    final selected = glyphCellsAboveMaterial(glyphs, material);

    // assert — stair identity comes from the down/up material facts; floor
    // and wall glyph characters never bypass the material layer.
    expect(selected.map((cell) => cell.position), [down, up, hero]);
    expect(selected.map((cell) => cell.glyph), ['#', '.', '@']);
  });

  testWidgets('draws semantic stairs above continuous material', (
    tester,
  ) async {
    // arrange
    final state = _stairsViewState();
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

    // act — terrain components are only present where an explicit material
    // fact says the terrain is a semantic stair, never merely from its glyph.
    final world = tester
        .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
        .game!
        .world;
    Iterable<PositionComponent> terrainAt(Position position) =>
        world.children.whereType<PositionComponent>().where(
          (component) =>
              component.priority == GlyphLayer.terrain.index &&
              component.position ==
                  Vector2(
                    position.x * cameraCellSize,
                    position.y * cameraCellSize,
                  ),
        );

    // assert — the exit stays a final glyph above the material while plain
    // floor text remains absent.
    expect(terrainAt(const Position(3, 2)), hasLength(1));
    expect(terrainAt(const Position(2, 2)), isEmpty);
  });

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
      final local =
          geometry.topLeftOf(2, 1) +
          Offset(geometry.cellSize / 2, geometry.cellSize / 2);

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
        final local =
            geometry.topLeftOf(tile.x, tile.y) +
            Offset(geometry.cellSize / 2, geometry.cellSize / 2);
        final game = tester.widget<GameWidget<FlameGame>>(scene).game!;
        final worldPoint = game.camera.globalToLocal(
          Vector2(local.dx, local.dy),
        );

        expect(
          worldPoint.x,
          closeTo((tile.x + 0.5) * geometry.cellSize, 0.001),
        );
        expect(
          worldPoint.y,
          closeTo((tile.y + 0.5) * geometry.cellSize, 0.001),
        );

        await tester.tapAt(tester.getTopLeft(scene) + local);
        await tester.pump(const Duration(milliseconds: 50));
        expect(taps.last, tile);
        return geometry;
      }

      var state = _overflowingViewState(const Position(10, 1));
      await pumpScene(state);
      expect(
        (await tapProjectedTile(state, const Position(11, 1))).origin.dx,
        closeTo(-198, 0.001),
      );

      final glyphsBeforeFocus = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .toList(growable: false);
      final heroBeforeFocus = glyphsBeforeFocus.last as PositionComponent;
      final materialBeforeFocus = glyphsBeforeFocus
          .whereType<MaterialComponent>()
          .single;

      state = _overflowingViewState(const Position(18, 1));
      await pumpScene(state);
      final glyphsAfterFocus = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children;
      expect(glyphsAfterFocus, contains(same(heroBeforeFocus)));
      expect(glyphsAfterFocus, contains(same(materialBeforeFocus)));
      expect(
        heroBeforeFocus.position,
        Vector2(18 * cameraCellSize, cameraCellSize),
      );
      expect(
        (await tapProjectedTile(state, const Position(18, 1))).origin.dx,
        closeTo(-432, 0.001),
      );

      final materialBeforePan = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .whereType<MaterialComponent>()
          .single;
      final glyphsBeforePan = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .toList(growable: false);

      state = _overflowingViewState(
        const Position(18, 1),
        pan: const Offset(1000, 0),
      );
      await pumpScene(state);
      final materialAfterPan = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children
          .whereType<MaterialComponent>()
          .single;
      expect(materialAfterPan, same(materialBeforePan));
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

      state = _overflowingViewState(const Position(10, 1));
      await pumpScene(state);
      expect(
        (await tapProjectedTile(state, const Position(11, 1))).origin.dx,
        closeTo(-198, 0.001),
      );

      expect(taps, const [
        Position(11, 1),
        Position(18, 1),
        Position(5, 1),
        Position(11, 1),
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
      final local =
          geometry.topLeftOf(2, 1) +
          Offset(geometry.cellSize / 2, geometry.cellSize / 2);

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

    final snapshot = DungeonSceneSnapshot.fromViewState(
      state,
      DungeonPalette.crypt,
    );

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
    final snapshot = DungeonSceneSnapshot.fromViewState(
      state,
      DungeonPalette.crypt,
    );

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

  testWidgets(
    'retained actor component synchronizes badge and both outline shapes',
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
                      first.position.x * cameraCellSize,
                      first.position.y * cameraCellSize,
                    ),
          );

      final retained = actorComponent();
      expect(
        retained.children.whereType<TextComponent>().map((child) => child.text),
        ['g', '¹'],
      );

      final selected = GameViewState(
        game: initial.game,
        log: initial.log,
        actorIdentity: initial.actorIdentity,
        selectedActorId: first.id,
      );
      await pumpScene(selected);
      expect(actorComponent(), same(retained));
      expect(retained.children.whereType<CircleComponent>(), hasLength(1));

      final targeted = GameViewState(
        game: initial.game,
        log: initial.log,
        actorIdentity: initial.actorIdentity,
        selectedActorId: first.id,
        armedSpellId: 'firebolt',
      );
      await pumpScene(targeted);
      expect(actorComponent(), same(retained));
      expect(retained.children.whereType<CircleComponent>(), hasLength(1));
      expect(retained.children.whereType<RectangleComponent>(), hasLength(1));

      final cleared = GameViewState(
        game: initial.game,
        log: initial.log,
        actorIdentity: initial.actorIdentity,
      );
      await pumpScene(cleared);
      expect(actorComponent(), same(retained));
      expect(retained.children.whereType<CircleComponent>(), isEmpty);
      expect(retained.children.whereType<RectangleComponent>(), isEmpty);
      expect(
        retained.children.whereType<TextComponent>().map((child) => child.text),
        ['g', '¹'],
      );
    },
  );
}
