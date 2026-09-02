import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/kit.dart';

/// The shallowest depth at which armour stops being allowed to be the answer.
///
/// **One and two are where armour is supposed to feel like an answer**, which is
/// the intent this pin is scoped to honour. A hero who finds a hauberk on floor
/// one should feel it work on floor two. From three down, a creature whose blows
/// a suit of mail turns into a scratch is a creature nobody has to think about,
/// and a difficulty curve that can be bought off in the armoury is not a curve.
const int _deepEnoughToMatter = 3;

/// How much a blow has to beat the floor of one by before it counts as a blow.
///
/// Two rather than one, because one *is* the floor: a creature that lands
/// exactly the minimum the rules guarantee has not beaten armour, it has been
/// stopped by it and rescued by a clause. Two is the smallest number that says
/// the armour was outrun rather than tied.
const int _mustBeatTheFloorBy = 2;

/// Everything that appears at [_deepEnoughToMatter] or below, once each.
Map<String, CreatureSpec> _deepCreatures() {
  final deep = <String, CreatureSpec>{};
  for (final depth in spawnTables.keys) {
    if (depth < _deepEnoughToMatter) continue;
    for (final entry in spawnTableFor(depth).entries) {
      final creature = creatureById(entry.creatureId);
      deep[creature.id] = creature;
    }
  }
  for (final dungeon in themedDungeons) {
    for (final depth in dungeon.spawnTables.keys) {
      if (depth < _deepEnoughToMatter) continue;
      for (final creature in dungeon.spawnTables[depth]!.creatures) {
        deep[creature.id] = creature;
      }
    }
    deep[dungeon.boss.id] = dungeon.boss;
  }
  return deep;
}

/// Everything in a spawn table anywhere, once each.
Map<String, CreatureSpec> _allCreatures() {
  final all = <String, CreatureSpec>{};
  for (final depth in spawnTables.keys) {
    for (final entry in spawnTableFor(depth).entries) {
      final creature = creatureById(entry.creatureId);
      all[creature.id] = creature;
    }
  }
  for (final dungeon in themedDungeons) {
    for (final depth in dungeon.spawnTables.keys) {
      for (final creature in dungeon.spawnTables[depth]!.creatures) {
        all[creature.id] = creature;
      }
    }
    all[dungeon.boss.id] = dungeon.boss;
  }
  return all;
}

/// The most [creature] can take off a hero wearing [armor], after the rules.
///
/// `step`'s own expression with the roll at its ceiling: the armour left after
/// pierce is what a blow has to get through, and the floor of one is left off
/// deliberately — this measures whether the floor was needed, so applying it
/// would hide the answer.
int _bestBlow(CreatureSpec creature, int armor) {
  final left = armor - creature.pierce;
  return creature.attackMax - (left > 0 ? left : 0);
}

void main() {
  /// The armour the pin is measured against, derived rather than written down.
  ///
  /// A number in this file would be a second copy of the fixture, and the copy
  /// that drifted would leave the pin green while measuring a hero nobody plays.
  final armor = heroArmor(survivabilityKit(1).loadout);

  group('the floor of one survives, and stops being the whole game', () {
    test(
      'every creature deep enough to matter outruns the graduate\'s mail',
      () {
        // arrange
        final deep = _deepCreatures();

        // act
        final stopped = {
          for (final creature in deep.values)
            if (_bestBlow(creature, armor) < _mustBeatTheFloorBy)
              creature.id: _bestBlow(creature, armor),
        };

        // assert
        expect(stopped, isEmpty, reason: 'armour bought these off: $stopped');
      },
    );

    test('the shallow nuisances are exempt, and they are these four', () {
      // arrange
      final deep = _deepCreatures().keys.toSet();

      // act
      final shallow = _allCreatures().keys.toSet().difference(deep);

      // assert — named rather than counted, because a nuisance is a design
      // decision and a test that hides which ones is a test that lets a deep
      // creature quietly become one. The list is not a grant: nothing is
      // written down as exempt anywhere. These five are the creatures that
      // stand only on depths one and two, and the spawn tables are what say
      // so. The spitter joined them this unit (ledger D76); the old pin was
      // {'rat', 'wolf', 'ghoul', 'crab'} and it moved because the set is
      // computed from the tables, not because any exemption was granted.
      expect(shallow, {'rat', 'wolf', 'ghoul', 'crab', 'spitter'});
    });

    test('the exempt four are still stopped by mail, which is the point', () {
      // arrange
      final all = _allCreatures();

      // act
      final blows = {
        for (final id in ['rat', 'wolf', 'ghoul', 'crab'])
          id: _bestBlow(all[id]!, armor),
      };

      // assert
      expect(blows.values, everyElement(lessThan(_mustBeatTheFloorBy)));
    });

    test('every dungeon still has something the mail turns into a scratch', () {
      // arrange
      final floored = <String, List<String>>{
        'the crypt': [
          for (final entry in spawnTableFor(1).entries) entry.creatureId,
        ],
        for (final dungeon in themedDungeons)
          dungeon.node.value: [
            for (final creature in dungeon.spawnTables[1]!.creatures)
              creature.id,
          ],
      };
      final all = _allCreatures();

      // act
      final scratched = {
        for (final where in floored.keys)
          where: floored[where]!.where((id) {
            final creature = all[id]!;
            final left = armor - creature.pierce;
            return creature.attackMin - (left > 0 ? left : 0) <= 1;
          }).toList(),
      };

      // assert — the floor of one is what stops armour from making a creature
      // harmless, and it can only do that if something still reaches it. Every
      // dungeon's first floor holds one, which is where armour is meant to feel
      // like an answer.
      expect(
        scratched.values,
        everyElement(isNotEmpty),
        reason: 'nothing reaches the floor of one: $scratched',
      );
    });
  });
}
