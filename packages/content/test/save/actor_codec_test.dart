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

    test('reach is read as one where the document does not name it', () {
      // arrange — a version-3 document has no reach key; every creature the
      // old build ever wrote strikes from adjacency
      final written = encodeActor(_ghoul);
      expect(written.containsKey('reach'), isFalse);

      // act
      final after = decodeActor(written);

      // assert
      expect(after.reach, 1);
    });

    test('a reach other than one survives the round trip', () {
      // arrange
      const spitter = Actor(
        id: 'spitter-1',
        name: 'the spitter',
        glyph: 'p',
        position: Position(3, 3),
        hp: 7,
        maxHp: 7,
        attackMin: 2,
        attackMax: 3,
        speed: 5,
        energy: 100,
        reach: 3,
      );

      // act
      final written = encodeActor(spitter);
      final after = decodeActor(written);

      // assert — omit-on-default: the key exists only when the value is not
      // the one every older document already means
      expect(written['reach'], 3);
      expect(after.reach, 3);
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

  group('what an actor is made of', () {
    test('resistances and vulnerabilities survive a round trip', () {
      // arrange
      const drowned = Actor(
        id: 'drowned-1',
        name: 'the drowned sailor',
        glyph: 'd',
        position: Position(2, 2),
        hp: 9,
        maxHp: 9,
        attackMin: 2,
        attackMax: 4,
        speed: 10,
        energy: 100,
        resists: {DamageType.frost},
        vulnerableTo: {DamageType.fire},
      );

      // act
      final after = decodeActor(encodeActor(drowned));

      // assert
      expect(after.resists, {DamageType.frost});
      expect(after.vulnerableTo, {DamageType.fire});
    });

    test('are written even when the creature is made of nothing special', () {
      // arrange
      const plain = _ghoul;

      // act
      final written = encodeActor(plain);

      // assert - present and empty rather than absent, so a reader never has to
      // guess whether the build that wrote this knew about resistances
      expect(written['resists'], isEmpty);
      expect(written['vulnerableTo'], isEmpty);
    });

    test('are written as sorted names, so one actor is one document', () {
      // arrange
      const both = Actor(
        id: 'thing-1',
        name: 'the thing',
        glyph: 't',
        position: Position(1, 1),
        hp: 1,
        maxHp: 1,
        attackMin: 1,
        attackMax: 1,
        speed: 10,
        energy: 100,
        resists: {DamageType.frost, DamageType.fire},
      );

      // act
      final written = encodeActor(both);

      // assert
      expect(written['resists'], ['fire', 'frost']);
    });

    test('a damage type this build never heard of is refused by name', () {
      // arrange
      final written = encodeActor(_ghoul);
      written['resists'] = ['aether'];

      // act
      call() => decodeActor(written);

      // assert
      expect(call, throwsA(isA<SaveMalformed>()));
      expect(
        () => decodeActor(written),
        throwsA(
          isA<SaveMalformed>().having(
            (failure) => failure.reason,
            'reason',
            contains('resists'),
          ),
        ),
      );
    });

    test('a missing resistance key is refused rather than defaulted', () {
      // arrange
      final written = encodeActor(_ghoul)..remove('vulnerableTo');

      // act
      call() => decodeActor(written);

      // assert - never repair: a document that did not answer the question is
      // refused whole, so nobody loses a creature's make-up quietly
      expect(call, throwsA(isA<SaveMalformed>()));
    });
  });
}
