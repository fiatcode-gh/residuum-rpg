import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Loadout _trained(Map<SkillId, SkillState> schools) =>
    Loadout(equipment: const {}, skills: {...untrainedSkills, ...schools});

void main() {
  group('heroMaxMana', () {
    test('an untrained hero carries the base pool', () {
      // arrange
      final loadout = _trained(const {});

      // act
      final pool = heroMaxMana(loadout);

      // assert
      expect(pool, baseMana);
    });

    test('the three schools sum before they are halved', () {
      // arrange
      final loadout = _trained(const {
        SkillId.wrath: SkillState(level: 3),
        SkillId.mending: SkillState(level: 2),
        SkillId.binding: SkillState(level: 1),
      });

      // act
      final pool = heroMaxMana(loadout);

      // assert - six levels between them buy three points, not one each
      expect(pool, baseMana + 3);
    });

    test('a level that does not complete a pair buys nothing yet', () {
      // arrange
      final loadout = _trained(const {SkillId.wrath: SkillState(level: 1)});

      // act
      final pool = heroMaxMana(loadout);

      // assert
      expect(pool, baseMana);
    });

    test('no skill outside the three schools buys any mana at all', () {
      // arrange
      final loadout = _trained(const {
        SkillId.arms: SkillState(level: 40),
        SkillId.might: SkillState(level: 40),
        SkillId.bulwark: SkillState(level: 40),
        SkillId.fleetfoot: SkillState(level: 40),
      });

      // act
      final pool = heroMaxMana(loadout);

      // assert - swinging a sword has never taught anybody a spell
      expect(pool, baseMana);
    });

    test('neither craft buys any mana, however far it is trained', () {
      // arrange
      final loadout = _trained(const {
        SkillId.herbcraft: SkillState(level: maxSkillLevel),
        SkillId.blacksmith: SkillState(level: maxSkillLevel),
      });

      // act
      final pool = heroMaxMana(loadout);

      // assert - the pool comes off the three schools by an explicit check, so
      // a skill that is not one contributes nothing by construction rather than
      // by happening not to be counted. A hero who ground the forge to a
      // hundred is not a caster
      expect(pool, baseMana);
    });

    test('reads an absent school as untrained rather than throwing', () {
      // arrange
      const loadout = Loadout(equipment: {}, skills: {});

      // act
      final pool = heroMaxMana(loadout);

      // assert
      expect(pool, baseMana);
    });
  });
}
