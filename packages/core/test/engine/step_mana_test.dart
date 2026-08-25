import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _floor = '''
######
#....#
######''';

const Spell _mend = Spell(
  id: 'mend',
  name: 'Mend',
  school: SkillId.mending,
  manaCost: 3,
  requiredLevel: 0,
  kind: SpellKind.mend,
  min: 8,
  max: 8,
);

/// A crawl whose stairs down are underfoot and whose floors are all alike.
GameState _onTheStairs({int mana = 0, int depth = 1, int heroHp = 20}) => crawl(
  ascii: _floor,
  heroAt: const Position(1, 1),
  heroHp: heroHp,
  depth: depth,
  mana: mana,
  spells: const {'mend': _mend},
  knownSpells: const {'mend'},
  stairsDown: const Position(1, 1),
  stairsUp: const Position(1, 1),
  buildFloor: (below) => Floor(
    map: FloorMap.parse(_floor),
    heroSpawn: const Position(1, 1),
    monsters: const [],
    stairsUp: const Position(1, 1),
    stairsDown: const Position(4, 1),
  ),
);

void main() {
  group('the per-floor mana budget', () {
    test('fills on arriving at a floor this run has never built', () {
      // arrange
      final game = _onTheStairs(mana: 1);

      // act
      final (below, _) = step(game, const DescendAction());

      // assert
      expect(below.mana, heroMaxMana(game.loadout));
    });

    test('does not fill on climbing back to a floor already walked', () {
      // arrange
      final below = step(_onTheStairs(mana: 1), const DescendAction()).$1;
      final spent = below.copyWith(mana: 2);

      // act
      final (above, _) = step(spent, const AscendAction());

      // assert
      expect(above.mana, 2);
    });

    test('does not fill on descending to a floor already built', () {
      // arrange - down, up, and down again onto the remembered floor
      final below = step(_onTheStairs(mana: 1), const DescendAction()).$1;
      final above = step(below.copyWith(mana: 2), const AscendAction()).$1;

      // act
      final (again, _) = step(above, const DescendAction());

      // assert - a stairs bounce buys time, and time buys nothing. A pool that
      // topped up here would make Mend a free infinite heal on any stairwell
      expect(again.mana, 2);
    });

    test('a bounce down, up and down again refills nothing at all', () {
      // arrange
      final opened = _onTheStairs(mana: 9, heroHp: 4);
      final below = step(opened, const DescendAction()).$1;
      final spent = step(below, const CastSpellAction('mend')).$1;

      // act
      final bounced = step(
        step(spent, const AscendAction()).$1,
        const DescendAction(),
      ).$1;

      // assert
      expect(spent.mana, below.mana - _mend.manaCost);
      expect(bounced.mana, spent.mana);
    });

    test('is capped by what the hero\'s schools can hold', () {
      // arrange
      final game = _onTheStairs().copyWith(mana: 0);
      final schooled = crawl(
        ascii: _floor,
        heroAt: const Position(1, 1),
        stairsDown: const Position(1, 1),
        skills: {...untrainedSkills, SkillId.wrath: const SkillState(level: 6)},
        buildFloor: game.buildFloor,
      );

      // act
      final (below, _) = step(schooled, const DescendAction());

      // assert
      expect(below.mana, baseMana + 3);
    });
  });
}
