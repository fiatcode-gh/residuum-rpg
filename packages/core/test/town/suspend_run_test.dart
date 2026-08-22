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

Item _item(String id) => Item(id: id, base: _cap, rarity: Rarity.common);

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

/// A crawl the hero has walked into and moved around in, so position, energy,
/// depth and the drop counter have all left their entry values behind and a
/// resume that quietly reset one has something to be caught on.
GameState _run() => startRun(_townie(gold: 7), dungeon: _shuffling()).copyWith(
  hero: hero(const Position(3, 2), hp: 9).copyWith(energy: 40),
  inventory: [_item('carried-1')],
  depth: 2,
  nextDropNumber: 5,
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
  group('characterization: what leaving alive carries (C1)', () {
    test('the hero that comes home is the one that stood in the dungeon', () {
      // arrange
      final entered = _townie();
      final run = startRun(
        entered,
        dungeon: _shuffling(),
      ).copyWith(hero: hero(const Position(7, 2), hp: 11).copyWith(energy: 40));

      // act
      final home = endRun(entered, run, died: false);

      // assert
      expect(home.hero.position, const Position(7, 2));
      expect(home.hero.energy, 40);
      expect(home.hero.hp, 11);
    });

    test('gear worn in the dungeon comes home worn', () {
      // arrange
      final entered = _townie();
      final run = startRun(
        entered,
        dungeon: _shuffling(),
      ).copyWith(equipment: {EquipSlot.head: _item('found-worn')});

      // act
      final home = endRun(entered, run, died: false);

      // assert
      expect(home.equipment[EquipSlot.head]!.id, 'found-worn');
    });
  });

  group('suspendRun', () {
    test('carries the same six things endRun carries, and heals nothing', () {
      // arrange
      final entered = _townie(
        gold: 30,
        bank: [_item('vault-1')],
        bankedGold: 90,
      );
      final run = startRun(entered, dungeon: _shuffling()).copyWith(
        hero: hero(const Position(7, 2), hp: 4),
        inventory: [_item('loot-1')],
        equipment: {EquipSlot.head: _item('found-worn')},
        skills: {...untrainedSkills, SkillId.arms: const SkillState(level: 4)},
      );

      // act
      final camped = suspendRun(entered, run);

      // assert
      expect(camped, endRun(entered, run, died: false));
      expect(camped.hero.hp, 4);
      expect(camped.gold, 30);
      expect(camped.inventory.single.id, 'loot-1');
    });

    test('the visit comes home, which is what makes resume well-defined', () {
      // arrange
      final entered = _townie(visit: 3);
      final run = startRun(entered, dungeon: _shuffling());

      // act
      final camped = suspendRun(entered, run);

      // assert
      expect(camped.visit, run.visit);
    });

    test('the vault stays where the dungeon could not reach it', () {
      // arrange
      final entered = _townie(bank: [_item('vault-1')], bankedGold: 90);
      final run = startRun(entered, dungeon: _shuffling());

      // act
      final camped = suspendRun(entered, run);

      // assert
      expect(camped.bank.single.id, 'vault-1');
      expect(camped.bankedGold, 90);
    });

    test('the crawl it was called on is not changed or given up', () {
      // arrange
      final entered = _townie(gold: 12);
      final run = startRun(entered, dungeon: _shuffling());

      // act
      suspendRun(entered, run);

      // assert
      expect(run.gold, 12);
      expect(run.isGameOver, isFalse);
      expect(run.depth, 1);
    });
  });

  group('resumeRun', () {
    test('the town business the hero did while camped comes down too', () {
      // arrange
      final camped = suspendRun(_townie(), _run());
      final shopped = camped.copyWith(
        gold: camped.gold + 50,
        inventory: [...camped.inventory, _item('bought-1')],
        equipment: {EquipSlot.head: _item('bought-worn')},
        skills: {...untrainedSkills, SkillId.arms: const SkillState(level: 9)},
      );

      // act
      final resumed = resumeRun(shopped, _run());

      // assert
      expect(resumed.gold, 57);
      expect(resumed.inventory.map((item) => item.id), contains('bought-1'));
      expect(resumed.equipment[EquipSlot.head]!.id, 'bought-worn');
      expect(resumed.skills[SkillId.arms]!.level, 9);
    });

    test('a night at the inn shows in the hit points that go back down', () {
      // arrange
      final camped = suspendRun(_townie(), _run()).copyWith(gold: 20);
      final (rested, _) = restAtInn(camped, 12);

      // act
      final resumed = resumeRun(rested, _run());

      // assert
      expect(camped.hero.hp, 9);
      expect(resumed.hero.hp, rested.maxHp);
      expect(resumed.gold, 8);
    });

    test('banked gold stays in the vault rather than going down', () {
      // arrange
      final camped = suspendRun(_townie(), _run()).copyWith(bankedGold: 400);

      // act
      final resumed = resumeRun(camped, _run());

      // assert
      expect(resumed.gold, 7);
    });

    test('the dungeon is exactly where it was left', () {
      // arrange
      final suspended = _run();
      final camped = suspendRun(
        _townie(),
        suspended,
      ).copyWith(hero: hero(const Position(0, 0), hp: 3));

      // act
      final resumed = resumeRun(camped, suspended);

      // assert
      expect(resumed.hero.position, suspended.hero.position);
      expect(resumed.hero.energy, suspended.hero.energy);
      expect(resumed.hero.hp, 3);
      expect(resumed.depth, suspended.depth);
      expect(resumed.map.toAscii(), suspended.map.toAscii());
      expect(resumed.monsters, suspended.monsters);
      expect(resumed.explored, suspended.explored);
      expect(resumed.visible, suspended.visible);
      expect(resumed.rng.state, suspended.rng.state);
      expect(resumed.lootRng.state, suspended.lootRng.state);
      expect(resumed.nextDropNumber, suspended.nextDropNumber);
      expect(resumed.stairsDown, suspended.stairsDown);
      expect(resumed.stairsUp, suspended.stairsUp);
      expect(resumed.floors.keys, suspended.floors.keys);
      expect(resumed.groundItems, suspended.groundItems);
      expect(resumed.worldSeed, suspended.worldSeed);
      expect(resumed.isGameOver, suspended.isGameOver);
      expect(resumed.dropTables, suspended.dropTables);
    });

    test('resuming is not entering, so the dungeon does not reshuffle', () {
      // arrange
      final suspended = _run();
      final camped = suspendRun(_townie(), suspended);

      // act
      final resumed = resumeRun(camped, suspended);

      // assert
      expect(resumed.visit, suspended.visit);
      expect(
        startRun(camped, dungeon: _shuffling()).visit,
        suspended.visit + 1,
      );
    });

    test('the hero walks back onto the tile they left, not the spawn', () {
      // arrange
      final suspended = _run();

      // act
      final resumed = resumeRun(suspendRun(_townie(), suspended), suspended);

      // assert
      expect(resumed.hero.position, const Position(3, 2));
      expect(resumed.map.isWalkable(resumed.hero.position), isTrue);
      expect(
        resumed.hero.position,
        isNot(startRun(_townie(), dungeon: _shuffling()).hero.position),
      );
    });

    test('the floors below are the ones the suspended crawl would build', () {
      // arrange
      final suspended = _run();
      final camped = suspendRun(_townie(), suspended);

      // act
      final resumed = resumeRun(camped, suspended);

      // assert
      expect(
        resumed.buildFloor(3).map.toAscii(),
        suspended.buildFloor(3).map.toAscii(),
      );
      expect(
        resumed.buildFloor(3).heroSpawn,
        suspended.buildFloor(3).heroSpawn,
      );
    });
  });
}
