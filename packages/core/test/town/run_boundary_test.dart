import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
##########
#........#
#........#
##########''';

const _cap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 6,
);

Item _item(String id) => Item(id: id, base: _cap, rarity: Rarity.common);

Item _vigorous(String id) =>
    Item(id: id, base: _cap, rarity: Rarity.fine, affixes: const [_vigour]);

/// A dungeon whose floors depend on the visit, so a reshuffle is visible.
Dungeon _shuffling() =>
    (visit) =>
        (depth) => Floor(
          map: FloorMap.parse(_room),
          heroSpawn: Position(1 + visit % 5, 1),
          monsters: [ghoul('ghoul-$depth-1', const Position(8, 2))],
          stairsDown: depth >= deepestDepth ? null : const Position(8, 1),
          stairsUp: depth <= 1 ? null : Position(1 + visit % 5, 1),
        );

Profile _townie({
  int hp = 20,
  int gold = 0,
  int bankedGold = 0,
  int visit = 0,
  List<Item> inventory = const [],
  List<Item> bank = const [],
  Equipment equipment = const {},
}) => Profile(
  hero: hero(const Position(0, 0), hp: hp),
  worldSeed: 5,
  gold: gold,
  bankedGold: bankedGold,
  visit: visit,
  inventory: inventory,
  bank: bank,
  equipment: equipment,
);

void main() {
  group('startRun', () {
    test('bumps the visit, which is what reshuffles the dungeon', () {
      // arrange
      final profile = _townie(visit: 3);

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.visit, 4);
      expect(run.hero.position, const Position(5, 1));
    });

    test('two entries in a row are two different dungeons', () {
      // arrange
      final profile = _townie();

      // act
      final first = startRun(profile, dungeon: _shuffling());
      final second = startRun(
        endRun(profile, first, died: false),
        dungeon: _shuffling(),
      );

      // assert
      expect(second.hero.position, isNot(first.hero.position));
    });

    test('equal profiles produce identical runs', () {
      // arrange
      final one = _townie(gold: 12, inventory: [_item('held-1')]);
      final other = _townie(gold: 12, inventory: [_item('held-1')]);

      // act
      final first = startRun(one, dungeon: _shuffling());
      final second = startRun(other, dungeon: _shuffling());

      // assert
      expect(
        (first.visit, first.hero.position, first.gold, first.depth),
        (second.visit, second.hero.position, second.gold, second.depth),
      );
      expect(first.map.toAscii(), second.map.toAscii());
    });

    test('carries the gear, the training, the pack and the purse in', () {
      // arrange
      final profile = _townie(
        gold: 40,
        inventory: [_item('held-1')],
        bank: [_item('vault-1')],
        bankedGold: 90,
        equipment: {EquipSlot.head: _item('worn-1')},
      );

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.gold, 40);
      expect(run.inventory.single.id, 'held-1');
      expect(run.equipment[EquipSlot.head]!.id, 'worn-1');
    });

    test('carries the training in', () {
      // arrange
      final profile = _townie().copyWith(
        skills: {...untrainedSkills, SkillId.arms: const SkillState(level: 7)},
      );

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.skills[SkillId.arms]!.level, 7);
    });

    test('starts on floor one with nothing remembered', () {
      // arrange
      final profile = _townie();

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.depth, 1);
      expect(run.floors, isEmpty);
      expect(run.stairsUp, isNull);
    });

    test('a wounded hero walks in wounded', () {
      // arrange
      final profile = _townie(hp: 6);

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.hero.hp, 6);
    });

    test('the hero arrives ready to act, on the floor it was given', () {
      // arrange
      final profile = _townie();

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.hero.energy, actThreshold);
      expect(run.map.isWalkable(run.hero.position), isTrue);
    });
  });

  test("bottoms out at the crypt's five when no delve depth is named", () {
    // arrange
    final profile = _townie();

    // act
    final run = startRun(profile, dungeon: _shuffling());

    // assert
    expect(run.deepest, deepestDepth);
  });

  test('asks how deep the delve goes for the visit it just bumped to', () {
    // arrange
    final profile = _townie(visit: 11);
    final asked = <int>[];

    // act
    final run = startRun(
      profile,
      dungeon: _shuffling(),
      deepest: (visit) {
        asked.add(visit);
        return 6;
      },
    );

    // assert
    expect(asked, [12]);
    expect(run.visit, 12);
    expect(run.deepest, 6);
  });

  group('endRun leaving alive', () {
    test('brings the whole haul home and does not heal', () {
      // arrange
      final entered = _townie(bank: [_item('vault-1')], bankedGold: 90);
      final run = startRun(entered, dungeon: _shuffling()).copyWith(
        inventory: [_item('loot-1')],
        hero: hero(const Position(1, 1), hp: 4),
      );

      // act
      final home = endRun(entered, run, died: false);

      // assert
      expect(home.hero.hp, 4);
      expect(home.inventory.single.id, 'loot-1');
      expect(home.bank.single.id, 'vault-1');
      expect(home.bankedGold, 90);
    });

    test('keeps the gold the hero walked out with', () {
      // arrange
      final entered = _townie(gold: 40);
      final run = startRun(entered, dungeon: _shuffling());

      // act
      final home = endRun(entered, run, died: false);

      // assert
      expect(home.gold, 40);
    });

    test('keeps the training the run bought', () {
      // arrange
      final entered = _townie();
      final run = startRun(entered, dungeon: _shuffling()).copyWith(
        skills: {...untrainedSkills, SkillId.arms: const SkillState(level: 4)},
      );

      // act
      final home = endRun(entered, run, died: false);

      // assert
      expect(home.skills[SkillId.arms]!.level, 4);
    });

    test('keeps the visit the run was played on', () {
      // arrange
      final entered = _townie(visit: 3);
      final run = startRun(entered, dungeon: _shuffling());

      // act
      final home = endRun(entered, run, died: false);

      // assert
      expect(home.visit, 4);
    });
  });

  group('endRun after a death', () {
    test('burns the carried pack and the carried purse', () {
      // arrange
      final entered = _townie(gold: 40);
      final run = startRun(
        entered,
        dungeon: _shuffling(),
      ).copyWith(inventory: [_item('loot-1')]);

      // act
      final home = endRun(entered, run, died: true);

      // assert
      expect(home.inventory, isEmpty);
      expect(home.gold, 0);
    });

    test('keeps the gear, the training and the vault', () {
      // arrange
      final entered = _townie(
        bank: [_item('vault-1')],
        bankedGold: 90,
        equipment: {EquipSlot.head: _item('worn-1')},
      );
      final run = startRun(entered, dungeon: _shuffling()).copyWith(
        skills: {...untrainedSkills, SkillId.arms: const SkillState(level: 4)},
      );

      // act
      final home = endRun(entered, run, died: true);

      // assert
      expect(home.equipment[EquipSlot.head]!.id, 'worn-1');
      expect(home.skills[SkillId.arms]!.level, 4);
      expect(home.bank.single.id, 'vault-1');
      expect(home.bankedGold, 90);
    });

    test('bumps the visit, so the dungeon that killed the hero reshuffles', () {
      // arrange
      final entered = _townie(visit: 3);
      final run = startRun(entered, dungeon: _shuffling());

      // act
      final home = endRun(entered, run, died: true);

      // assert
      expect(home.visit, 4);
    });

    test('wakes at the ceiling the surviving gear allows', () {
      // arrange
      final entered = _townie(equipment: {EquipSlot.head: _vigorous('worn-1')});
      final run = startRun(
        entered,
        dungeon: _shuffling(),
      ).copyWith(hero: hero(const Position(1, 1), hp: 0));

      // act
      final home = endRun(entered, run, died: true);

      // assert
      expect(home.hero.hp, 26);
      expect(home.hero.hp, home.maxHp);
    });

    test('never wakes above a hero who paid the inn instead', () {
      // arrange
      final entered = _townie(
        gold: 50,
        equipment: {EquipSlot.head: _vigorous('worn-1')},
      );
      final run = startRun(
        entered,
        dungeon: _shuffling(),
      ).copyWith(hero: hero(const Position(1, 1), hp: 0));

      // act
      final dead = endRun(entered, run, died: true);
      final (rested, _) = restAtInn(
        entered.copyWith(hero: entered.hero.copyWith(hp: 1)),
        12,
      );

      // assert
      expect(dead.hero.hp, rested.hero.hp);
    });

    test('gear picked up during the run comes home only if it was worn', () {
      // arrange
      final entered = _townie();
      final run = startRun(entered, dungeon: _shuffling()).copyWith(
        equipment: {EquipSlot.head: _item('found-worn')},
        inventory: [_item('found-carried')],
      );

      // act
      final home = endRun(entered, run, died: true);

      // assert
      expect(home.equipment[EquipSlot.head]!.id, 'found-worn');
      expect(home.inventory, isEmpty);
    });
  });

  group('magic through the four doors', () {
    const firebolt = Spell(
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

    test('startRun carries what the hero has learned down with them', () {
      // arrange
      final profile = _townie().copyWith(knownSpells: const {'firebolt'});

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.knownSpells, const {'firebolt'});
    });

    test('startRun injects the spell registry, as it injects drop tables', () {
      // arrange
      final profile = _townie();

      // act
      final run = startRun(
        profile,
        dungeon: _shuffling(),
        spells: const {'firebolt': firebolt},
      );

      // assert
      expect(run.spells, const {'firebolt': firebolt});
    });

    test('startRun opens the crawl with a full pool', () {
      // arrange
      final profile = _townie().copyWith(
        skills: {...untrainedSkills, SkillId.wrath: const SkillState(level: 4)},
      );

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.mana, heroMaxMana(profile.loadout));
      expect(run.mana, baseMana + 2);
    });

    test('startRun opens the crawl with no ward and nothing bound', () {
      // arrange
      final profile = _townie();

      // act
      final run = startRun(profile, dungeon: _shuffling());

      // assert
      expect(run.warded, 0);
      expect(run.bound, isEmpty);
    });

    test('endRun brings what was learned home', () {
      // arrange
      final profile = _townie();
      final run = startRun(profile, dungeon: _shuffling());

      // act
      final home = endRun(
        profile,
        run.copyWith(knownSpells: const {'mend'}),
        died: false,
      );

      // assert
      expect(home.knownSpells, const {'mend'});
    });

    test('dying burns the pack and the purse but never the spells', () {
      // arrange
      final profile = _townie();
      final run = startRun(profile, dungeon: _shuffling());

      // act
      final home = endRun(
        profile,
        run.copyWith(knownSpells: const {'mend'}),
        died: true,
      );

      // assert - learned exactly as skills are learned, and kept for the same
      // reason: the book was spent when it was read
      expect(home.knownSpells, const {'mend'});
      expect(home.inventory, isEmpty);
      expect(home.gold, 0);
    });

    test('suspendRun carries the spells out to the camp', () {
      // arrange
      final profile = _townie();
      final run = startRun(profile, dungeon: _shuffling());

      // act
      final camped = suspendRun(profile, run.copyWith(knownSpells: {'ward'}));

      // assert
      expect(camped.knownSpells, const {'ward'});
    });

    test(
      'resumeRun restores the run\'s mana, ward and binds, roll for roll',
      () {
        // arrange
        final profile = _townie();
        final opened = startRun(profile, dungeon: _shuffling());
        final spent = opened.copyWith(
          mana: 1,
          warded: 4,
          bound: const {'ghoul-1-1': 2},
        );
        final camped = suspendRun(profile, spent);

        // act
        final back = resumeRun(camped, spent);

        // assert - a camp is not a rest: what the crawl was holding is what it
        // holds when the hero climbs back down into it
        expect(back.mana, 1);
        expect(back.warded, 4);
        expect(back.bound, const {'ghoul-1-1': 2});
      },
    );

    test('resumeRun takes the known spells from the hero, not the crawl', () {
      // arrange
      final profile = _townie();
      final opened = startRun(profile, dungeon: _shuffling());
      final camped = suspendRun(
        profile,
        opened,
      ).copyWith(knownSpells: const {'bind'});

      // act
      final back = resumeRun(camped, opened);

      // assert - a book read at the camp is a book the hero climbs down knowing
      expect(back.knownSpells, const {'bind'});
    });

    test('resumeRun carries the spell registry back down', () {
      // arrange
      final profile = _townie();
      final opened = startRun(
        profile,
        dungeon: _shuffling(),
        spells: const {'firebolt': firebolt},
      );

      // act
      final back = resumeRun(suspendRun(profile, opened), opened);

      // assert
      expect(back.spells, const {'firebolt': firebolt});
    });
  });
}
