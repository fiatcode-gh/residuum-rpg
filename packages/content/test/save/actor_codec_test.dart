import 'package:residuum_content/src/save/actor_codec.dart';
import 'package:residuum_content/src/save/save_json.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const Actor _ghoul = Actor(
  id: 'ghoul-1',
  name: 'the ghoul',
  glyph: 'g',
  position: Position(4, 7),
  hp: 9,
  maxHp: 12,
  attackMin: 2,
  attackMax: 4,
  speed: 11,
  energy: 30,
  dropChance: 25,
  pierce: 3,
);

void main() {
  group('actor codec', () {
    test('all twelve fields survive a round trip', () {
      // arrange
      const before = _ghoul;

      // act
      final after = decodeActor(encodeActor(before));

      // assert
      expect(after.id, before.id);
      expect(after.name, before.name);
      expect(after.glyph, before.glyph);
      expect(after.position, before.position);
      expect(after.hp, before.hp);
      expect(after.maxHp, before.maxHp);
      expect(after.attackMin, before.attackMin);
      expect(after.attackMax, before.attackMax);
      expect(after.speed, before.speed);
      expect(after.energy, before.energy);
      expect(after.dropChance, before.dropChance);
      expect(after.pierce, before.pierce);
    });

    test('a held turn is carried over rather than zeroed', () {
      // arrange
      final waiting = _ghoul.copyWith(energy: 137);

      // act
      final after = decodeActor(encodeActor(waiting));

      // assert
      expect(after.energy, 137);
    });

    test('a list of actors keeps its order', () {
      // arrange
      final line = [
        _ghoul,
        _ghoul.copyWith(position: const Position(1, 1)),
        _ghoul.copyWith(position: const Position(2, 2)),
      ];

      // act
      final after = decodeActors({'monsters': encodeActors(line)}, 'monsters');

      // assert
      expect(
        after.map((actor) => actor.position),
        line.map((actor) => actor.position),
      );
    });

    test('an actor that is not an object is refused', () {
      // arrange
      const written = 'ghoul-1';

      // act
      void act() => decodeActor(written);

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });

    test('a set of positions is written in a stable order', () {
      // arrange
      final scattered = {
        const Position(5, 2),
        const Position(1, 9),
        const Position(1, 2),
      };

      // act
      final written = encodePositions(scattered);

      // assert
      expect(written, [
        [1, 2],
        [5, 2],
        [1, 9],
      ]);
    });

    test('a set of positions round-trips whatever the order', () {
      // arrange
      final scattered = {
        const Position(5, 2),
        const Position(1, 9),
        const Position(1, 2),
      };

      // act
      final after = decodePositions({
        'explored': encodePositions(scattered),
      }, 'explored');

      // assert
      expect(after, scattered);
    });

    test('an absent stairway round-trips as absent', () {
      // arrange
      final written = <String, Object?>{
        'stairsUp': encodeNullablePosition(null),
        'stairsDown': encodeNullablePosition(const Position(3, 4)),
      };

      // act
      final up = decodeNullablePosition(written, 'stairsUp');
      final down = decodeNullablePosition(written, 'stairsDown');

      // assert
      expect(up, isNull);
      expect(down, const Position(3, 4));
    });

    test('a position that is not two numbers is refused', () {
      // arrange
      final written = <String, Object?>{
        'at': <Object?>[1],
      };

      // act
      void act() => decodeNullablePosition(written, 'at');

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });

    test('a position written as text is refused', () {
      // arrange
      final written = <String, Object?>{
        'at': <Object?>['1', '2'],
      };

      // act
      void act() => decodeNullablePosition(written, 'at');

      // assert
      expect(act, throwsA(isA<SaveMalformed>()));
    });

    test('a missing position field names itself', () {
      // arrange
      final written = <String, Object?>{};

      // act
      void act() => decodeNullablePosition(written, 'stairsDown');

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('stairsDown'),
          ),
        ),
      );
    });
  });
}
