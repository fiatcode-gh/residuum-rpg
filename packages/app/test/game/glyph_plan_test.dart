import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/glyph_grid.dart';
import 'package:residuum_app/game/glyph_plan.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _remembered = Position(4, 2);
const _seen = Position(2, 1);
const _unseen = Position(5, 3);

GameState _game({
  required Set<Position> visible,
  required Set<Position> explored,
  Map<Position, GatherKind> nodes = const {},
}) => GameState(
  map: FloorMap.parse(_arena),
  hero: Actor(
    id: 'hero',
    name: 'you',
    glyph: '@',
    position: const Position(1, 1),
    hp: 20,
    maxHp: 20,
    attackMin: 4,
    attackMax: 4,
    speed: 10,
    energy: actThreshold,
  ),
  monsters: const [],
  rng: Rng(1),
  lootRng: Rng(2),
  visible: visible,
  explored: explored,
  nodes: nodes,
  buildFloor: (depth) => throw StateError('no descent in a paint test'),
);

GlyphCell? _terrainCellAt(List<GlyphCell> plan, Position position) => plan
    .where((cell) => cell.position == position && cell.glyph == '.')
    .firstOrNull;

GlyphCell? _nodeCellAt(List<GlyphCell> plan, Position position) => plan
    .where((cell) => cell.position == position && cell.ink == nodeInk)
    .firstOrNull;

void main() {
  group('the vein a hero walked away from', () {
    test('draws at full strength while it is in sight', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(
        visible: seen,
        explored: seen,
        nodes: {_seen: GatherKind.oreVein},
      );

      // act
      final plan = glyphPlan(game, DungeonPalette.crypt);

      // assert
      final cell = _nodeCellAt(plan, _seen);
      expect(cell, isNotNull);
      expect(cell!.glyph, GatherKind.oreVein.glyph);
      expect(cell.ink, nodeInk);
      expect(cell.opacity, fullOpacity);
    });

    test('stays on the remembered map at the remembered opacity', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(
        visible: seen,
        explored: {...seen, _remembered},
        nodes: {_remembered: GatherKind.oreVein},
      );

      // act
      final plan = glyphPlan(game, DungeonPalette.crypt);

      // assert
      final cell = _nodeCellAt(plan, _remembered);
      expect(cell, isNotNull);
      expect(cell!.glyph, GatherKind.oreVein.glyph);
      expect(cell.ink, nodeInk);
      expect(cell.opacity, rememberedOpacity);
    });

    test('does not exist where the hero has never looked', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(
        visible: seen,
        explored: seen,
        nodes: {_unseen: GatherKind.oreVein},
      );

      // act
      final plan = glyphPlan(game, DungeonPalette.crypt);

      // assert
      expect(_nodeCellAt(plan, _unseen), isNull);
    });

    test('paints between the terrain and the hero, as it always did', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(
        visible: seen,
        explored: seen,
        nodes: {_seen: GatherKind.oreVein},
      );

      // act
      final plan = glyphPlan(game, DungeonPalette.crypt);

      // assert — an item dropped on a vein has to be the glyph the player
      // sees, and the hero the glyph above both, so the node paints after
      // every terrain cell and before the hero
      final nodeAt = plan.indexWhere(
        (cell) => cell.position == _seen && cell.ink == nodeInk,
      );
      final heroAt = plan.indexWhere((cell) => cell.glyph == '@');
      expect(nodeAt, greaterThan(0));
      expect(heroAt, greaterThan(nodeAt));
    });
  });

  group('the remembered terrain in the paint plan', () {
    test('draws at the remembered opacity', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(visible: seen, explored: {...seen, _remembered});

      // act
      final plan = glyphPlan(game, DungeonPalette.crypt);

      // assert
      final cell = _terrainCellAt(plan, _remembered);
      expect(cell, isNotNull);
      expect(cell!.glyph, '.');
      expect(cell.ink, DungeonPalette.crypt.floor);
      expect(cell.opacity, rememberedOpacity);
      expect(cell.opacity, 0.4);
    });

    test('draws what the hero is looking at at full strength', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(visible: seen, explored: seen);

      // act
      final plan = glyphPlan(game, DungeonPalette.crypt);

      // assert
      final cell = _terrainCellAt(plan, _seen);
      expect(cell, isNotNull);
      expect(cell!.opacity, fullOpacity);
    });

    test('draws nothing where the hero has never looked', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(visible: seen, explored: seen);

      // act
      final plan = glyphPlan(game, DungeonPalette.crypt);

      // assert
      expect(_terrainCellAt(plan, _unseen), isNull);
      expect(plan.where((cell) => cell.position == _unseen), isEmpty);
    });
  });
}
