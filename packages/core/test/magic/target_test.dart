import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Actor _monster(String id, Position at) => Actor(
  id: id,
  name: 'the $id',
  glyph: 'm',
  position: at,
  hp: 5,
  maxHp: 5,
  attackMin: 1,
  attackMax: 2,
  speed: 10,
  energy: actThreshold,
);

void main() {
  group('byRowThenColumn', () {
    test('orders rows before columns, so a sort reads like a floor', () {
      // arrange
      final tiles = [
        const Position(9, 0),
        const Position(1, 2),
        const Position(0, 0),
        const Position(0, 2),
      ];

      // act
      final sorted = [...tiles]..sort(byRowThenColumn);

      // assert
      expect(sorted, [
        const Position(0, 0),
        const Position(9, 0),
        const Position(0, 2),
        const Position(1, 2),
      ]);
    });
  });

  group('chebyshev distance', () {
    test('counts a diagonal step as one, the way a king moves', () {
      // arrange
      const from = Position(4, 4);

      // act
      final diagonal = from.chebyshevTo(const Position(5, 5));
      final straight = from.chebyshevTo(const Position(6, 4));

      // assert
      expect(diagonal, 1);
      expect(straight, 2);
    });

    test('is zero to the tile it is measured from', () {
      // arrange
      const here = Position(3, 7);

      // act
      final distance = here.chebyshevTo(here);

      // assert
      expect(distance, 0);
    });
  });

  group('nearestVisibleEnemy', () {
    test('picks the closest of the monsters in sight', () {
      // arrange
      final monsters = [
        _monster('far', const Position(8, 1)),
        _monster('near', const Position(3, 1)),
      ];
      final visible = {const Position(8, 1), const Position(3, 1)};

      // act
      final target = nearestVisibleEnemy(
        monsters,
        visible,
        const Position(1, 1),
      );

      // assert
      expect(target?.id, 'near');
    });

    test('measures by Chebyshev, so a diagonal beats two tiles along', () {
      // arrange
      final monsters = [
        _monster('along', const Position(3, 1)),
        _monster('diagonal', const Position(2, 2)),
      ];
      final visible = {const Position(3, 1), const Position(2, 2)};

      // act
      final target = nearestVisibleEnemy(
        monsters,
        visible,
        const Position(1, 1),
      );

      // assert - a bolt does not walk, so it does not measure in walked steps
      expect(target?.id, 'diagonal');
    });

    test('never picks a monster out of sight, however close it stands', () {
      // arrange
      final monsters = [
        _monster('hidden', const Position(2, 1)),
        _monster('seen', const Position(6, 1)),
      ];
      final visible = {const Position(6, 1)};

      // act
      final target = nearestVisibleEnemy(
        monsters,
        visible,
        const Position(1, 1),
      );

      // assert
      expect(target?.id, 'seen');
    });

    test('breaks a tie by row and then by column, every time it is asked', () {
      // arrange - both stand two tiles from the hero, one above and one below
      final monsters = [
        _monster('south', const Position(1, 7)),
        _monster('north', const Position(1, 3)),
      ];
      final visible = {const Position(1, 7), const Position(1, 3)};

      // act
      final first = nearestVisibleEnemy(
        monsters,
        visible,
        const Position(1, 5),
      );
      final again = nearestVisibleEnemy(
        monsters.reversed.toList(),
        visible,
        const Position(1, 5),
      );

      // assert - the answer cannot depend on the order the monsters happen to
      // be listed in, or two identical crawls would cast at two targets
      expect(first?.id, 'north');
      expect(again?.id, 'north');
    });

    test('breaks a same-row tie by column', () {
      // arrange
      final monsters = [
        _monster('east', const Position(7, 4)),
        _monster('west', const Position(1, 4)),
      ];
      final visible = {const Position(7, 4), const Position(1, 4)};

      // act
      final target = nearestVisibleEnemy(
        monsters,
        visible,
        const Position(4, 4),
      );

      // assert
      expect(target?.id, 'west');
    });

    test('yields nothing at all when nothing is in sight', () {
      // arrange
      final monsters = [_monster('hidden', const Position(2, 1))];

      // act
      final target = nearestVisibleEnemy(
        monsters,
        const {},
        const Position(1, 1),
      );

      // assert
      expect(target, isNull);
    });
  });
}
