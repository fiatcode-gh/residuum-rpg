import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/actor_presentation.dart';
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
  List<Actor> monsters = const [],
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
  monsters: monsters,
  rng: Rng(1),
  lootRng: Rng(2),
  visible: visible,
  explored: explored,
  nodes: nodes,
  buildFloor: (depth) => throw StateError('no descent in a paint test'),
);

GlyphCell? _terrainCellAt(List<GlyphCell> plan, Position position) => plan
    .where((cell) => cell.position == position && cell.glyph == '·')
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
      final plan = glyphPlan(game);

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
      final plan = glyphPlan(game);

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
      final plan = glyphPlan(game);

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
      final plan = glyphPlan(game);

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
      final plan = glyphPlan(game);

      // assert
      final cell = _terrainCellAt(plan, _remembered);
      expect(cell, isNotNull);
      expect(cell!.glyph, '·');
      expect(cell.ink, stoneFloorLit);
      expect(cell.shade, stoneFloorShade);
      expect(cell.opacity, rememberedOpacity);
      expect(cell.opacity, 0.24);
    });

    test('draws what the hero is looking at at full strength', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(visible: seen, explored: seen);

      // act
      final plan = glyphPlan(game);

      // assert
      final cell = _terrainCellAt(plan, _seen);
      expect(cell, isNotNull);
      expect(cell!.ink, stoneFloorLit);
      expect(cell.shade, stoneFloorShade);
      expect(cell.opacity, fullOpacity);
    });

    test('draws nothing where the hero has never looked', () {
      // arrange
      final seen = {const Position(1, 1), _seen};
      final game = _game(visible: seen, explored: seen);

      // act
      final plan = glyphPlan(game);

      // assert
      expect(_terrainCellAt(plan, _unseen), isNull);
      expect(plan.where((cell) => cell.position == _unseen), isEmpty);
    });
  });

  group('monster presentation facts', () {
    final first = Actor(
      id: 'ghoul-1',
      name: 'the ghoul',
      glyph: 'g',
      position: const Position(2, 1),
      hp: 10,
      maxHp: 10,
      attackMin: 3,
      attackMax: 3,
      speed: 10,
      energy: actThreshold,
    );
    final second = Actor(
      id: 'ghoul-2',
      name: first.name,
      glyph: first.glyph,
      position: const Position(3, 1),
      hp: first.hp,
      maxHp: first.maxHp,
      attackMin: first.attackMin,
      attackMax: first.attackMax,
      speed: first.speed,
      energy: first.energy,
    );

    test('keeps raw glyphs and projects separate badges by actor id', () {
      final game = _game(
        visible: {const Position(1, 1), first.position, second.position},
        explored: {const Position(1, 1), first.position, second.position},
        monsters: [first, second],
      );

      final plan = glyphPlan(
        game,
        actorPresentations: {
          first.id: const ActorPresentation(
            actorId: 'ghoul-1',
            displayName: 'the ghoul¹',
            glyph: 'g',
            badge: '¹',
          ),
          second.id: const ActorPresentation(
            actorId: 'ghoul-2',
            displayName: 'the ghoul²',
            glyph: 'g',
            badge: '²',
          ),
        },
      );

      final cells = plan.where((cell) => cell.layer == GlyphLayer.monster);
      expect(cells.map((cell) => cell.glyph), ['g', 'g']);
      expect(cells.map((cell) => cell.entity), ['ghoul-1', 'ghoul-2']);
      expect(cells.map((cell) => cell.badge), ['¹', '²']);
    });

    test('omits a known but hidden duplicate from projection', () {
      final hidden = second.copyWith(position: const Position(5, 3));
      final game = _game(
        visible: {const Position(1, 1), first.position},
        explored: {const Position(1, 1), first.position, hidden.position},
        monsters: [first, hidden],
      );

      final plan = glyphPlan(
        game,
        markedIds: {hidden.id},
        selectedActorId: hidden.id,
        actorPresentations: {
          first.id: const ActorPresentation(
            actorId: 'ghoul-1',
            displayName: 'the ghoul¹',
            glyph: 'g',
            badge: '¹',
          ),
          hidden.id: const ActorPresentation(
            actorId: 'ghoul-2',
            displayName: 'the ghoul²',
            glyph: 'g',
            badge: '²',
          ),
        },
      );

      expect(
        plan.where(
          (cell) =>
              cell.layer == GlyphLayer.monster && cell.entity == hidden.id,
        ),
        isEmpty,
      );
    });

    test('marks only the selected visible actor', () {
      final game = _game(
        visible: {const Position(1, 1), first.position, second.position},
        explored: {const Position(1, 1), first.position, second.position},
        monsters: [first, second],
      );

      final plan = glyphPlan(
        game,
        selectedActorId: second.id,
        actorPresentations: {
          first.id: const ActorPresentation(
            actorId: 'ghoul-1',
            displayName: 'the ghoul¹',
            glyph: 'g',
            badge: '¹',
          ),
          second.id: const ActorPresentation(
            actorId: 'ghoul-2',
            displayName: 'the ghoul²',
            glyph: 'g',
            badge: '²',
          ),
        },
      );

      final cells = plan.where((cell) => cell.layer == GlyphLayer.monster);
      expect(
        cells.where((cell) => cell.entity == first.id).single.selected,
        isFalse,
      );
      expect(
        cells.where((cell) => cell.entity == second.id).single.selected,
        isTrue,
      );
    });
  });
}
