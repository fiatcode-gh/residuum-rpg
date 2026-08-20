import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const room = '''
#######
#.....#
#.....#
#.....#
#######''';

const bentCorridor = '''
#######
#..#..#
#..#..#
#.....#
#######''';

const sealed = '''
#####
#.#.#
#.###
#...#
#####''';

void main() {
  group('computeFlowField', () {
    test('the goal reads zero', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final field = computeFlowField(map, const Position(3, 2));

      // assert
      expect(field[const Position(3, 2)], 0);
    });

    test('distance grows by one per orthogonal step', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final field = computeFlowField(map, const Position(1, 1));

      // assert
      expect(field[const Position(2, 1)], 1);
      expect(field[const Position(3, 1)], 2);
      expect(field[const Position(2, 2)], 2);
      expect(field[const Position(3, 3)], 4);
    });

    test('walls carry no entry', () {
      // arrange
      final map = FloorMap.parse(room);

      // act
      final field = computeFlowField(map, const Position(1, 1));

      // assert
      expect(field.containsKey(const Position(0, 0)), isFalse);
      expect(field.containsKey(const Position(3, 0)), isFalse);
    });

    test('unreachable tiles carry no entry', () {
      // arrange
      final map = FloorMap.parse(sealed);

      // act
      final field = computeFlowField(map, const Position(1, 1));

      // assert
      expect(field.containsKey(const Position(3, 1)), isFalse);
      expect(field.containsKey(const Position(3, 3)), isTrue);
    });

    test('the field measures around a wall, not through it', () {
      // arrange
      final map = FloorMap.parse(bentCorridor);

      // act
      final field = computeFlowField(map, const Position(2, 1));

      // assert
      expect(field[const Position(4, 1)], 6);
    });

    test('the same map and goal always give the same field', () {
      // arrange
      final map = FloorMap.parse(bentCorridor);

      // act
      final first = computeFlowField(map, const Position(2, 1));
      final second = computeFlowField(map, const Position(2, 1));

      // assert
      expect(first, second);
    });
  });

  group('flowFieldStep', () {
    test('a monster rounds a corner to reach the hero', () {
      // arrange
      final map = FloorMap.parse(bentCorridor);
      const hero = Position(2, 1);
      const monster = Position(4, 1);
      final field = computeFlowField(map, hero);

      // act
      final target = flowFieldStep(map, field, monster, {hero});

      // assert
      expect(target, const Position(4, 2));
    });

    test('a monster walks the whole corner and arrives beside the hero', () {
      // arrange
      final map = FloorMap.parse(bentCorridor);
      const hero = Position(2, 1);
      final field = computeFlowField(map, hero);
      var monster = const Position(4, 1);
      final walked = <Position>[];

      // act
      while (!monster.isOrthogonallyAdjacentTo(hero) && walked.length < 25) {
        final target = flowFieldStep(map, field, monster, {hero});
        if (target == null) break;
        walked.add(target);
        monster = target;
      }

      // assert
      expect(monster.isOrthogonallyAdjacentTo(hero), isTrue);
      expect(walked, hasLength(5));
      expect(walked.toSet(), hasLength(walked.length));
    });

    test('a tie is broken north before east, south and west', () {
      // arrange
      final map = FloorMap.parse(room);
      const hero = Position(2, 2);
      const monster = Position(4, 3);
      final field = computeFlowField(map, hero);

      // act
      final target = flowFieldStep(map, field, monster, {hero});

      // assert
      expect(field[const Position(4, 2)], field[const Position(3, 3)]);
      expect(target, const Position(4, 2));
    });

    test('an occupied improving neighbour is skipped for the next best', () {
      // arrange
      final map = FloorMap.parse(room);
      const hero = Position(2, 2);
      const monster = Position(4, 3);
      final field = computeFlowField(map, hero);

      // act
      final target = flowFieldStep(map, field, monster, {
        hero,
        const Position(4, 2),
      });

      // assert
      expect(target, const Position(3, 3));
    });

    test('no strictly smaller free neighbour means standing still', () {
      // arrange
      final map = FloorMap.parse(room);
      const hero = Position(2, 2);
      const monster = Position(3, 2);
      final field = computeFlowField(map, hero);

      // act
      final target = flowFieldStep(map, field, monster, {hero});

      // assert
      expect(target, isNull);
    });

    test('a monster off the field stands still', () {
      // arrange
      final map = FloorMap.parse(sealed);
      const hero = Position(1, 1);
      const monster = Position(3, 1);
      final field = computeFlowField(map, hero);

      // act
      final target = flowFieldStep(map, field, monster, {hero});

      // assert
      expect(target, isNull);
    });

    test(
      'a step never lands on an equal or larger value, so it cannot loop',
      () {
        // arrange
        final map = FloorMap.parse(room);
        const hero = Position(1, 1);
        final field = computeFlowField(map, hero);
        var monster = const Position(5, 3);
        final distances = <int>[field[monster]!];

        // act
        for (var turn = 0; turn < 10; turn++) {
          final target = flowFieldStep(map, field, monster, {hero});
          if (target == null) break;
          monster = target;
          distances.add(field[monster]!);
        }

        // assert
        for (var index = 1; index < distances.length; index++) {
          expect(distances[index], lessThan(distances[index - 1]));
        }
        expect(distances.last, 1);
      },
    );
  });
}
