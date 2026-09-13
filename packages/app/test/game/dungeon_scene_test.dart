import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
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

Actor _ghoulAt(Position position) => Actor(
  id: 'ghoul-1',
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

GameViewState _viewState({Offset pan = Offset.zero, ArmedAction? armedAction}) {
  const heroPosition = Position(1, 1);
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, heroPosition, fovRadius);
  return GameViewState(
    game: GameState(
      map: map,
      hero: _heroAt(heroPosition),
      monsters: [_ghoulAt(const Position(1, 2))],
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
    armedAction: armedAction,
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

void main() {
  test('the scene snapshot preserves glyph projection and camera facts', () {
    final state = _viewState(
      pan: const Offset(12, -8),
      armedAction: const ArmedAttack(),
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
      final terrainBeforeFocus = glyphsBeforeFocus.firstWhere(
        (component) =>
            component is PositionComponent &&
            component.position == Vector2(12 * cameraCellSize, cameraCellSize),
      );

      state = _overflowingViewState(const Position(18, 1));
      await pumpScene(state);
      final glyphsAfterFocus = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!
          .world
          .children;
      expect(glyphsAfterFocus, contains(same(heroBeforeFocus)));
      expect(glyphsAfterFocus, contains(same(terrainBeforeFocus)));
      expect(
        heroBeforeFocus.position,
        Vector2(18 * cameraCellSize, cameraCellSize),
      );
      expect(
        (await tapProjectedTile(state, const Position(18, 1))).origin.dx,
        closeTo(-432, 0.001),
      );

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
}
