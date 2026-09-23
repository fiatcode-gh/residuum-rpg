import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/glyph_plan.dart';
import 'package:residuum_core/core.dart';
import 'package:residuum_content/content.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

Actor ghoulAt(
  Position at, {
  String id = 'ghoul-1',
  int speed = 10,
  int energy = actThreshold,
}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: speed,
  energy: energy,
);

GameState battleGame({
  Position heroAt = const Position(1, 1),
  List<Actor> monsters = const [],
}) {
  final map = FloorMap.parse(_arena);
  final seen = computeFov(map, heroAt, fovRadius);
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
    buildFloor: (depth) => throw StateError('no descent in a marking test'),
    spells: spellsById,
  );
}

void main() {
  group('the armed slot and its legal targets', () {
    test('nothing armed marks nothing', () {
      // arrange
      final state = GameViewState(game: battleGame(), log: const []);

      // act + assert
      expect(state.armedTargets, isEmpty);
    });

    test('an armed target-needing spell marks every visible enemy', () {
      // arrange - the far ghoul is visible and marked; the sight rule is
      // unchanged
      final state = GameViewState(
        game: battleGame(
          monsters: [
            ghoulAt(const Position(1, 2)),
            ghoulAt(const Position(5, 1), id: 'ghoul-2'),
          ],
        ),
        log: const [],
        armedSpellId: 'firebolt',
      );

      // act + assert
      expect(state.armedTargets, {'ghoul-1', 'ghoul-2'});
    });

    test('the armed spell marks no monster the hero cannot see', () {
      // arrange - the near ghoul is in the default FOV, the far one is edited
      // out of the sight set afterwards
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          ghoulAt(const Position(5, 1), id: 'ghoul-2'),
        ],
      ).copyWith(visible: {const Position(1, 1), const Position(1, 2)});
      final state = GameViewState(
        game: game,
        log: const [],
        armedSpellId: 'firebolt',
      );

      // act + assert - the sight rule is armedTargets', not adjacency: the
      // unseen monster is not a legal target even though it stands nearer
      expect(state.armedTargets, {'ghoul-1'});
    });
  });

  group('the target mark on the map', () {
    test('a marked monster carries the mark on its glyph cell', () {
      // arrange
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

      // act
      final plan = glyphPlan(game, markedIds: {'ghoul-1'});

      // assert
      final cell = plan
          .where((cell) => cell.position == const Position(1, 2))
          .where((cell) => cell.glyph == 'g')
          .single;
      expect(cell.marked, isTrue);
    });

    test('an unmarked monster carries no mark', () {
      // arrange
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          ghoulAt(const Position(5, 1), id: 'ghoul-2'),
        ],
      );

      // act
      final plan = glyphPlan(game, markedIds: {'ghoul-1'});

      // assert
      expect(
        plan
            .where((cell) => cell.position == const Position(5, 1))
            .where((cell) => cell.glyph == 'g')
            .single
            .marked,
        isFalse,
      );
    });

    test('nothing is marked when the marked set is empty', () {
      // arrange
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

      // act
      final plan = glyphPlan(game);

      // assert
      expect(plan.where((cell) => cell.marked), isEmpty);
    });
    test(
      'selected armed duplicate keeps badge, selection, and target facts',
      () {
        final state = GameViewState(
          game: battleGame(
            monsters: [
              ghoulAt(const Position(1, 2)),
              ghoulAt(const Position(2, 2), id: 'ghoul-2'),
            ],
          ),
          log: const [],
          armedSpellId: 'firebolt',
          selectedActorId: 'ghoul-1',
        );

        final cell =
            glyphPlan(
              state.game,
              markedIds: state.armedTargets,
              actorPresentations: state.actorIdentity.knownActors,
              selectedActorId: state.selectedActor?.id,
            ).singleWhere(
              (cell) =>
                  cell.layer == GlyphLayer.monster && cell.entity == 'ghoul-1',
            );

        expect(cell.glyph, 'g');
        expect(cell.badge, '¹');
        expect(cell.selected, isTrue);
        expect(cell.marked, isTrue);
      },
    );
  });
}
