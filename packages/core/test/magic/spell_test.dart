import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const Spell _firebolt = Spell(
  id: 'firebolt',
  name: 'Firebolt',
  school: SkillId.wrath,
  manaCost: 2,
  requiredLevel: 0,
  kind: SpellKind.bolt,
  type: DamageType.fire,
  min: 2,
  max: 4,
);

void main() {
  group('DamageType', () {
    test('ships with exactly fire and frost', () {
      // arrange
      // act
      final types = DamageType.values;

      // assert - the other five arrive with weapon typing, and a type nothing
      // can deal is a promise the rules cannot keep
      expect(types, [DamageType.fire, DamageType.frost]);
    });

    test('reads without hue: its own marking and its own word', () {
      // arrange
      final types = DamageType.values;

      // act
      final markings = {for (final type in types) type.marking};
      final words = {for (final type in types) type.word};

      // assert
      expect(markings, hasLength(types.length));
      expect(words, hasLength(types.length));
      expect(DamageType.fire.word, 'fire');
      expect(DamageType.frost.word, 'frost');
    });
  });

  group('the schools', () {
    test('are the three that train by casting, and no others', () {
      // arrange
      final skills = SkillId.values;

      // act
      final schools = [
        for (final skill in skills)
          if (skill.isSchool) skill,
      ];

      // assert
      expect(schools, [SkillId.wrath, SkillId.mending, SkillId.binding]);
    });

    test('each carries its own word and its own marking', () {
      // arrange
      const schools = [SkillId.wrath, SkillId.mending, SkillId.binding];

      // act
      final words = [for (final school in schools) school.schoolWord];
      final markings = {for (final school in schools) school.schoolMarking};

      // assert - the Rarity pattern, so a spell row reads in greyscale
      expect(words, ['Wrath', 'Mending', 'Binding']);
      expect(markings, hasLength(schools.length));
    });
  });

  group('Spell', () {
    test('a bolt carries the damage type it deals', () {
      // arrange
      const bolt = _firebolt;

      // act
      final type = bolt.type;

      // assert
      expect(type, DamageType.fire);
    });

    test('is equal to another spell written the same way', () {
      // arrange
      const one = _firebolt;

      // act
      const other = Spell(
        id: 'firebolt',
        name: 'Firebolt',
        school: SkillId.wrath,
        manaCost: 2,
        requiredLevel: 0,
        kind: SpellKind.bolt,
        type: DamageType.fire,
        min: 2,
        max: 4,
      );

      // assert
      expect(one, other);
    });

    test('refuses a school that is not one of the three', () {
      // arrange
      // act
      build() => Spell(
        id: 'bad',
        name: 'Bad',
        school: SkillId.arms,
        manaCost: 1,
        requiredLevel: 0,
        kind: SpellKind.mend,
        min: 1,
        max: 1,
      );

      // assert
      expect(build, throwsA(isA<AssertionError>()));
    });

    test('refuses a bolt with no damage type', () {
      // arrange
      // act
      build() => Spell(
        id: 'bad',
        name: 'Bad',
        school: SkillId.wrath,
        manaCost: 1,
        requiredLevel: 0,
        kind: SpellKind.bolt,
        min: 1,
        max: 2,
      );

      // assert
      expect(build, throwsA(isA<AssertionError>()));
    });

    test('refuses a damage type on anything that is not a bolt', () {
      // arrange
      // act
      build() => Spell(
        id: 'bad',
        name: 'Bad',
        school: SkillId.mending,
        manaCost: 1,
        requiredLevel: 0,
        kind: SpellKind.mend,
        type: DamageType.fire,
        min: 1,
        max: 1,
      );

      // assert
      expect(build, throwsA(isA<AssertionError>()));
    });

    test('refuses a range whose bottom is above its top', () {
      // arrange
      // act
      build() => Spell(
        id: 'bad',
        name: 'Bad',
        school: SkillId.mending,
        manaCost: 1,
        requiredLevel: 0,
        kind: SpellKind.mend,
        min: 8,
        max: 3,
      );

      // assert
      expect(build, throwsA(isA<AssertionError>()));
    });

    test('refuses a ward whose absorb pool is a range', () {
      // arrange
      // act
      build() => Spell(
        id: 'bad',
        name: 'Bad',
        school: SkillId.mending,
        manaCost: 1,
        requiredLevel: 0,
        kind: SpellKind.ward,
        min: 4,
        max: 6,
      );

      // assert - a ward absorbs a stated pool, and a rolled one would be a
      // number the player could not plan against
      expect(build, throwsA(isA<AssertionError>()));
    });

    test('refuses a spell that costs no mana', () {
      // arrange
      // act
      build() => Spell(
        id: 'bad',
        name: 'Bad',
        school: SkillId.wrath,
        manaCost: 0,
        requiredLevel: 0,
        kind: SpellKind.bolt,
        type: DamageType.fire,
        min: 1,
        max: 2,
      );

      // assert
      expect(build, throwsA(isA<AssertionError>()));
    });

    test('refuses a gate below zero', () {
      // arrange
      // act
      build() => Spell(
        id: 'bad',
        name: 'Bad',
        school: SkillId.wrath,
        manaCost: 1,
        requiredLevel: -1,
        kind: SpellKind.bolt,
        type: DamageType.fire,
        min: 1,
        max: 2,
      );

      // assert
      expect(build, throwsA(isA<AssertionError>()));
    });
  });
}
