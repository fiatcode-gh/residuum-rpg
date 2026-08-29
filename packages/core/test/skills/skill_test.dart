import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('SkillId', () {
    test('every addition appends, in the order the milestones added it', () {
      // arrange
      const shipped = [
        SkillId.arms,
        SkillId.might,
        SkillId.bulwark,
        SkillId.fleetfoot,
      ];
      const schools = [SkillId.wrath, SkillId.mending, SkillId.binding];
      const crafts = [SkillId.herbcraft, SkillId.blacksmith];

      // act
      final values = SkillId.values;

      // assert - appended and never reordered, because the save's skills block
      // is written in enum order and a reorder would rewrite every document
      expect(values.take(4), shipped);
      expect(values.skip(4).take(3), schools);
      expect(values.skip(7), crafts);
    });

    test('every skill in the enum starts untrained', () {
      // arrange
      const untouched = SkillState();

      // act
      final untrained = untrainedSkills;

      // assert
      expect(untrained.keys, SkillId.values);
      expect(untrained.values, everyElement(untouched));
    });
  });

  group('xpToNext', () {
    test('rises with every level, so later levels cost more', () {
      // arrange
      const levels = [0, 1, 2, 3, 4];

      // act
      final costs = [for (final level in levels) xpToNext(level)];

      // assert
      expect(costs, [4, 6, 8, 10, 12]);
    });

    test('costs forty triggers to reach level five, as the curve claims', () {
      // arrange
      const levels = [0, 1, 2, 3, 4];

      // act
      final toFive = [
        for (final level in levels) xpToNext(level),
      ].fold(0, (total, cost) => total + cost);

      // assert
      expect(toFive, 40);
    });

    test('is monotonically increasing all the way to the cap', () {
      // arrange
      final costs = [
        for (var level = 0; level < maxSkillLevel; level++) xpToNext(level),
      ];

      // act
      final rising = [
        for (var index = 1; index < costs.length; index++)
          costs[index] > costs[index - 1],
      ];

      // assert
      expect(rising, everyElement(isTrue));
    });
  });

  group('SkillState.trained', () {
    test('banks one experience point short of the next level', () {
      // arrange
      const skill = SkillState();

      // act
      final after = skill.trained();

      // assert
      expect((after.level, after.xp), (0, 1));
    });

    test('levels up when the cost is met and spends the experience', () {
      // arrange
      const skill = SkillState(level: 0, xp: 3);

      // act
      final after = skill.trained();

      // assert
      expect((after.level, after.xp), (1, 0));
    });

    test('carries surplus experience into the new level', () {
      // arrange
      const skill = SkillState(level: 1, xp: 5);

      // act
      final after = skill.trained();

      // assert
      expect((after.level, after.xp), (2, 0));
    });

    test('stops at the cap and stops banking experience there', () {
      // arrange
      const skill = SkillState(level: maxSkillLevel, xp: 0);

      // act
      final after = skill.trained();

      // assert
      expect(after, skill);
    });

    test('reports whether that training levelled the skill', () {
      // arrange
      const ready = SkillState(level: 0, xp: 3);
      const notReady = SkillState(level: 0, xp: 0);

      // act
      final levelled = (
        ready.trained().level > ready.level,
        notReady.trained().level > notReady.level,
      );

      // assert
      expect(levelled, (true, false));
    });
  });

  group('untrainedSkills', () {
    test('holds all nine skills at level zero', () {
      // arrange
      const skills = untrainedSkills;

      // act
      final ids = skills.keys.toSet();

      // assert
      expect(ids, SkillId.values.toSet());
      expect(skills.values, everyElement(const SkillState()));
    });
  });
}
