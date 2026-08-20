import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const allDepths = [1, 2, 3, 4, 5];

Floor floorAt(int depth, {int worldSeed = 1}) =>
    buildFloor(depth, worldSeed: worldSeed, visit: 0);

void main() {
  _armouryAndLoot();
  group('the bestiary', () {
    test('every creature has its own id and its own glyph', () {
      // arrange
      const creatures = bestiary;

      // act
      final ids = creatures.map((creature) => creature.id).toSet();
      final glyphs = creatures.map((creature) => creature.glyph).toSet();

      // assert
      expect(creatures, hasLength(5));
      expect(ids, hasLength(creatures.length));
      expect(glyphs, hasLength(creatures.length));
    });

    test('every creature is drawn as a single character', () {
      // arrange
      const creatures = bestiary;

      // act
      final lengths = creatures.map((creature) => creature.glyph.length);

      // assert
      expect(lengths, everyElement(1));
    });

    test('every creature has a sane stat line', () {
      // arrange
      const creatures = bestiary;

      // assert
      for (final creature in creatures) {
        expect(creature.hp, greaterThan(0), reason: creature.id);
        expect(creature.speed, greaterThan(0), reason: creature.id);
        expect(
          creature.attackMax,
          greaterThanOrEqualTo(creature.attackMin),
          reason: creature.id,
        );
        expect(creature.attackMin, greaterThan(0), reason: creature.id);
        expect(creature.name, startsWith('the '), reason: creature.id);
      }
    });

    test('the speeds are not all the same, so the clock is visible', () {
      // arrange
      const creatures = bestiary;

      // act
      final speeds = creatures.map((creature) => creature.speed).toSet();

      // assert
      expect(speeds, containsAll([5, 10, 20]));
    });

    test('a spawned creature arrives alive and ready to act', () {
      // arrange
      const creature = direWolf;

      // act
      final actor = creature.spawn(id: 'wolf-1', at: const Position(3, 4));

      // assert
      expect(actor.id, 'wolf-1');
      expect(actor.name, 'the dire wolf');
      expect((actor.hp, actor.maxHp), (8, 8));
      expect(actor.speed, 20);
      expect(actor.energy, actThreshold);
      expect(actor.position, const Position(3, 4));
    });

    test('an unknown creature id is refused', () {
      // arrange
      const id = 'basilisk';

      // act
      void act() => creatureById(id);

      // assert
      expect(act, throwsArgumentError);
    });
  });

  group('the spawn tables', () {
    test('every depth from one to five has a table', () {
      // arrange
      const depths = allDepths;

      // act
      final tables = depths.map(spawnTableFor);

      // assert
      expect(tables, hasLength(depths.length));
      expect(spawnTables.keys.toSet(), depths.toSet());
    });

    test('a depth outside the dungeon is refused', () {
      // arrange
      const depth = 6;

      // act
      void act() => spawnTableFor(depth);

      // assert
      expect(act, throwsArgumentError);
    });

    test('every entry names a creature that exists', () {
      // arrange
      const depths = allDepths;

      // act
      final referenced = [
        for (final depth in depths)
          for (final entry in spawnTableFor(depth).entries) entry.creatureId,
      ];

      // assert
      expect(referenced, isNotEmpty);
      for (final id in referenced) {
        expect(() => creatureById(id), returnsNormally, reason: id);
      }
    });

    test('every table is non-empty with positive weights and counts', () {
      // arrange
      const depths = allDepths;

      // assert
      for (final depth in depths) {
        final table = spawnTableFor(depth);
        expect(table.entries, isNotEmpty, reason: 'depth $depth');
        expect(table.minCount, greaterThan(0), reason: 'depth $depth');
        expect(
          table.maxCount,
          greaterThanOrEqualTo(table.minCount),
          reason: 'depth $depth',
        );
        for (final entry in table.entries) {
          expect(entry.weight, greaterThan(0), reason: entry.creatureId);
        }
      }
    });

    test('every creature in the bestiary can be met somewhere', () {
      // arrange
      const depths = allDepths;

      // act
      final reachable = {
        for (final depth in depths)
          for (final entry in spawnTableFor(depth).entries) entry.creatureId,
      };

      // assert
      expect(reachable, bestiary.map((creature) => creature.id).toSet());
    });

    test('a roll only ever returns a creature from that table', () {
      // arrange
      final rng = Rng(4);
      final table = spawnTableFor(3);
      final allowed = table.entries.map((entry) => entry.creatureId).toSet();

      // act
      final rolled = {
        for (var draw = 0; draw < 200; draw++) table.rollCreature(rng).id,
      };

      // assert
      expect(allowed, containsAll(rolled));
      expect(rolled, hasLength(allowed.length));
    });

    test('a count stays inside the table range', () {
      // arrange
      final rng = Rng(9);
      final table = spawnTableFor(5);

      // act
      final counts = [
        for (var draw = 0; draw < 100; draw++) table.rollCount(rng),
      ];

      // assert
      expect(
        counts,
        everyElement(inInclusiveRange(table.minCount, table.maxCount)),
      );
    });
  });

  group('buildFloor', () {
    test('every floor puts its monsters on distinct walkable tiles', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (final floor in floors) {
        final places = floor.monsters.map((m) => m.position).toList();
        expect(places.toSet(), hasLength(places.length));
        expect(places.map(floor.map.isWalkable), everyElement(isTrue));
        expect(places, isNot(contains(floor.heroSpawn)));
      }
    });

    test('monster ids are unique on every floor', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (final floor in floors) {
        final ids = floor.monsters.map((monster) => monster.id).toList();
        expect(ids.toSet(), hasLength(ids.length));
      }
    });

    test('the monster count comes from that depth\'s table', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (var index = 0; index < depths.length; index++) {
        final table = spawnTableFor(depths[index]);
        expect(
          floors[index].monsters,
          hasLength(inInclusiveRange(table.minCount, table.maxCount)),
          reason: 'depth ${depths[index]}',
        );
      }
    });

    test('every monster on a floor belongs to that depth\'s table', () {
      // arrange
      const depths = allDepths;

      // act
      final floors = depths.map(floorAt).toList();

      // assert
      for (var index = 0; index < depths.length; index++) {
        final allowed = spawnTableFor(
          depths[index],
        ).entries.map((entry) => creatureById(entry.creatureId).glyph).toSet();
        expect(
          floors[index].monsters.map((monster) => monster.glyph).toSet(),
          everyElement(isIn(allowed)),
          reason: 'depth ${depths[index]}',
        );
      }
    });

    test('only the deepest floor has no stairs down', () {
      // arrange
      const depths = allDepths;

      // act
      final stairs = depths.map((depth) => floorAt(depth).stairsDown).toList();

      // assert
      expect(stairs.sublist(0, 4), everyElement(isNotNull));
      expect(stairs.last, isNull);
    });

    test('the same world seed builds the same five floors, twice over', () {
      // arrange
      const worldSeed = 31337;

      // act
      final first = [
        for (final depth in allDepths) floorAt(depth, worldSeed: worldSeed),
      ];
      final second = [
        for (final depth in allDepths) floorAt(depth, worldSeed: worldSeed),
      ];

      // assert
      for (var index = 0; index < first.length; index++) {
        expect(first[index].map.toAscii(), second[index].map.toAscii());
        expect(first[index].heroSpawn, second[index].heroSpawn);
        expect(first[index].stairsDown, second[index].stairsDown);
        expect(
          first[index].monsters.map((m) => (m.id, m.position)),
          second[index].monsters.map((m) => (m.id, m.position)),
        );
      }
    });

    test('two world seeds are two different dungeons', () {
      // arrange
      const depth = 2;

      // act
      final one = floorAt(depth, worldSeed: 1).map.toAscii();
      final another = floorAt(depth, worldSeed: 2).map.toAscii();

      // assert
      expect(one, isNot(another));
    });
  });

  group('newGame', () {
    test('arms the hero with the rusty sword at the baseline speed', () {
      // arrange
      final game = newGame();

      // act
      final hero = game.hero;

      // assert
      expect(hero.id, 'hero');
      expect(hero.name, 'you');
      expect(hero.glyph, '@');
      expect((hero.hp, hero.maxHp), (20, 20));
      expect((hero.attackMin, hero.attackMax), (1, 2));
      expect(heroAttack(hero, game.loadout), (3, 5));
      expect(hero.speed, 10);
      expect(hero.energy, actThreshold);
    });

    test('starts on the first floor, on ground it can stand on', () {
      // arrange
      final game = newGame();

      // act
      final start = game.hero.position;

      // assert
      expect(game.depth, 1);
      expect(game.map.isWalkable(start), isTrue);
      expect(game.stairsDown, isNotNull);
    });

    test('places the first floor\'s spawn table with distinct ids', () {
      // arrange
      final game = newGame();
      final table = spawnTableFor(1);

      // act
      final monsters = game.monsters;

      // assert
      expect(
        monsters,
        hasLength(inInclusiveRange(table.minCount, table.maxCount)),
      );
      expect(monsters.map((m) => m.id).toSet(), hasLength(monsters.length));
    });

    test(
      'starts with the hero seeing its own tile and nothing more explored',
      () {
        // arrange
        final game = newGame();

        // act
        final visible = game.visible;

        // assert
        expect(visible, contains(game.hero.position));
        expect(game.explored, visible);
        expect(game.isGameOver, isFalse);
      },
    );

    test(
      'hides every monster at the start, so the dark has something in it',
      () {
        // arrange
        final game = newGame();

        // act
        final seen = game.monsters.where(
          (monster) => game.visible.contains(monster.position),
        );

        // assert
        expect(seen, isEmpty);
      },
    );

    test('a monster reaches the hero and draws blood', () {
      // arrange
      var game = newGame();

      // act
      for (var turn = 0; turn < 200; turn++) {
        final (next, _) = step(game, const MoveAction(Direction.north));
        game = next;
        if (game.isGameOver || game.hero.hp < 20) break;
      }

      // assert
      expect(game.hero.hp, lessThan(20));
    });

    test('the same seed produces the same crawl', () {
      // arrange
      final one = newGame(worldSeed: 7);
      final another = newGame(worldSeed: 7);

      // act
      final first = _play(one, 12);
      final second = _play(another, 12);

      // assert
      expect(first, second);
    });

    test('a crawl can walk the stairs from depth one down to depth five', () {
      // arrange
      const worldSeed = 1;
      Floor bare(int depth) {
        final floor = buildFloor(depth, worldSeed: worldSeed, visit: 0);
        return Floor(
          map: floor.map,
          heroSpawn: floor.heroSpawn,
          monsters: const [],
          stairsDown: floor.stairsDown,
        );
      }

      final first = bare(1);
      final visible = computeFov(first.map, first.heroSpawn, fovRadius);
      var game = GameState(
        map: first.map,
        hero: newGame(
          worldSeed: worldSeed,
        ).hero.copyWith(position: first.heroSpawn),
        monsters: const [],
        rng: Rng(worldSeed),
        lootRng: Rng(worldSeed ^ lootStreamSalt),
        visible: visible,
        explored: {...visible},
        buildFloor: bare,
        worldSeed: worldSeed,
        stairsDown: first.stairsDown,
      );
      final depthsReached = <int>[game.depth];

      // act
      while (game.stairsDown != null) {
        for (final step_ in findPath(
          game.map,
          game.hero.position,
          game.stairsDown!,
        )) {
          final direction = game.hero.position.directionTo(step_)!;
          final (next, _) = step(game, MoveAction(direction));
          game = next;
        }
        final (below, events) = step(game, const DescendAction());
        game = below;
        expect(events.whereType<Descended>(), hasLength(1));
        depthsReached.add(game.depth);
      }

      // assert
      expect(depthsReached, [1, 2, 3, 4, 5]);
      expect(game.stairsDown, isNull);
      expect(game.hero.hp, 20);
    });

    test('the layout does not depend on how the fighting goes', () {
      // arrange
      final fighting = newGame(worldSeed: 55);
      final walking = newGame(worldSeed: 55);

      // act
      _play(fighting, 30, direction: Direction.north);
      _play(walking, 5, direction: Direction.east);
      final afterFighting = fighting.buildFloor(2);
      final afterWalking = walking.buildFloor(2);

      // assert
      expect(afterFighting.map.toAscii(), afterWalking.map.toAscii());
      expect(
        afterFighting.monsters.map((m) => (m.id, m.position)),
        afterWalking.monsters.map((m) => (m.id, m.position)),
      );
    });
  });
}

List<String> _play(
  GameState start,
  int turns, {
  Direction direction = Direction.east,
}) {
  final log = <String>[];
  var game = start;
  for (var turn = 0; turn < turns; turn++) {
    final (next, events) = step(game, MoveAction(direction));
    log.addAll(events.map((event) => event.toString()));
    game = next;
  }
  return log;
}

void _armouryAndLoot() {
  group('armory', () {
    test('every base item id is unique', () {
      // arrange
      const items = armory;

      // act
      final ids = items.map((item) => item.id).toList();

      // assert
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every base item draws as a weapon, armour or a potion', () {
      // arrange
      const items = armory;

      // act
      final glyphs = items.map((item) => item.glyph).toSet();

      // assert
      expect(glyphs, {')', '[', '!'});
    });

    test('a weapon needs hands and goes in the main hand', () {
      // arrange
      final weapons = armory.where((item) => item.isWeapon);

      // act
      final slots = weapons.map((item) => item.slot).toSet();

      // assert
      expect(weapons, isNotEmpty);
      expect(slots, {EquipSlot.mainHand});
      expect(
        weapons.map((item) => item.attackMax),
        everyElement(greaterThan(0)),
      );
    });

    test('armour has a slot, no hands, and protects', () {
      // arrange
      final pieces = armory.where((item) => item.isArmour);

      // act
      final problems = [
        for (final piece in pieces)
          if (piece.hands != null || piece.armor <= 0) piece.id,
      ];

      // assert
      expect(pieces, isNotEmpty);
      expect(problems, isEmpty);
    });

    test('the potion is worn nowhere and heals', () {
      // arrange
      final potions = armory.where((item) => item.isPotion).toList();

      // act
      final potion = potions.single;

      // assert
      expect(potion.slot, isNull);
      expect(potion.hands, isNull);
      expect(potion.heal, greaterThan(0));
    });

    test('every base item is reachable by id', () {
      // arrange
      const items = armory;

      // act
      final found = [for (final item in items) baseItemById(item.id)];

      // assert
      expect(found, items);
    });

    test('an unknown base item id throws rather than returning nothing', () {
      // arrange
      const missing = 'no-such-item';

      // act
      void lookUp() => baseItemById(missing);

      // assert
      expect(lookUp, throwsArgumentError);
    });
  });

  group('affix pool', () {
    test('every affix id is unique', () {
      // arrange
      const affixes = affixPool;

      // act
      final ids = affixes.map((affix) => affix.id).toList();

      // assert
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every affix carries a name and at least one bonus', () {
      // arrange
      const affixes = affixPool;

      // act
      final idle = [
        for (final affix in affixes)
          if (affix.affixName.isEmpty ||
              affix.attackMin +
                      affix.attackMax +
                      affix.armor +
                      affix.maxHp +
                      affix.speed ==
                  0)
            affix.id,
      ];

      // assert
      expect(idle, isEmpty);
    });

    test('no affix takes hit points away', () {
      // arrange
      const affixes = affixPool;

      // act
      final draining = [
        for (final affix in affixes)
          if (affix.maxHp < 0) affix.id,
      ];

      // assert — this is what makes the unequip clamp safe: with no negative
      // max-hp affix in the game, taking gear off can never push the ceiling
      // below the hero's own twenty, so the clamp's floor of one is defence in
      // depth rather than a rule the game leans on
      expect(draining, isEmpty);
    });

    test('the two pools together are the whole pool, and do not overlap', () {
      // arrange
      const weapon = weaponAffixes;
      const armour = armourAffixes;

      // act
      final overlap = weapon.toSet().intersection(armour.toSet());

      // assert
      expect(overlap, isEmpty);
      expect([...weapon, ...armour], affixPool);
    });

    test('every affix is reachable by id', () {
      // arrange
      const affixes = affixPool;

      // act
      final found = [for (final affix in affixes) affixById(affix.id)];

      // assert
      expect(found, affixes);
    });
  });

  group('drop tables', () {
    test('every depth one to five has a table', () {
      // arrange
      const depths = [1, 2, 3, 4, 5];

      // act
      final found = [for (final depth in depths) dropTableFor(depth)];

      // assert
      expect(found, hasLength(depths.length));
      expect(dropTables.keys.toList()..sort(), depths);
    });

    test('a depth with no table throws rather than building a bare floor', () {
      // arrange
      const tooDeep = 6;

      // act
      void lookUp() => dropTableFor(tooDeep);

      // assert
      expect(lookUp, throwsArgumentError);
    });

    test('every item a table can drop is a real base item', () {
      // arrange
      final entries = dropTables.values.expand((table) => table.items);

      // act
      final strangers = [
        for (final entry in entries)
          if (!armory.contains(entry.value)) entry.value.id,
      ];

      // assert
      expect(strangers, isEmpty);
    });

    test('every affix a table can roll is a real affix', () {
      // arrange
      final entries = dropTables.values.expand(
        (table) => [...table.weaponAffixes, ...table.armourAffixes],
      );

      // act
      final strangers = [
        for (final affix in entries)
          if (!affixPool.contains(affix)) affix.id,
      ];

      // assert
      expect(strangers, isEmpty);
    });

    test('both affix pools can always fill the richest tier', () {
      // arrange
      final tables = dropTables.entries;

      // act
      final short = [
        for (final table in tables)
          if (table.value.weaponAffixes.length < Rarity.legendary.affixCount ||
              table.value.armourAffixes.length < Rarity.legendary.affixCount)
            table.key,
      ];

      // assert — a rolled item promises exactly rarity.affixCount affixes, and
      // they are drawn without replacement, so a pool shorter than the richest
      // tier would quietly break that promise
      expect(short, isEmpty);
    });

    test('the healing potion can drop at every depth', () {
      // arrange
      final tables = dropTables.entries;

      // act
      final dry = [
        for (final table in tables)
          if (!table.value.items.any(
            (entry) => entry.value == healingPotion && entry.weight > 0,
          ))
            table.key,
      ];

      // assert — potions are the only healing in the game; a depth that cannot
      // drop one is a depth the hero cannot recover on
      expect(dry, isEmpty);
    });

    test('no depth can drop a Legendary this milestone', () {
      // arrange
      final tables = dropTables.entries;

      // act
      final reachable = [
        for (final table in tables)
          if (table.value.rarities.any(
            (entry) => entry.value == Rarity.legendary && entry.weight > 0,
          ))
            table.key,
      ];

      // assert
      expect(reachable, isEmpty);
    });

    test('every tier is named at every depth, even at weight zero', () {
      // arrange
      final tables = dropTables.values;

      // act
      final tiers = [
        for (final table in tables)
          table.rarities.map((entry) => entry.value).toSet(),
      ];

      // assert
      expect(tiers, everyElement(Rarity.values.toSet()));
    });

    test('weights are never negative and every table can be drawn from', () {
      // arrange
      final tables = dropTables.values;

      // act
      final problems = <String>[];
      for (final table in tables) {
        final weights = [
          ...table.items.map((entry) => entry.weight),
          ...table.rarities.map((entry) => entry.weight),
        ];
        if (weights.any((weight) => weight < 0))
          problems.add('negative weight');
        if (table.items.fold(0, (sum, entry) => sum + entry.weight) <= 0) {
          problems.add('no item can drop');
        }
        if (table.rarities.fold(0, (sum, entry) => sum + entry.weight) <= 0) {
          problems.add('no tier can be rolled');
        }
      }

      // assert
      expect(problems, isEmpty);
    });

    test('every floor scatters at least one item and never a silly number', () {
      // arrange
      final tables = dropTables.values;

      // act
      final bounds = [
        for (final table in tables) (table.minFloorItems, table.maxFloorItems),
      ];

      // assert
      expect(
        bounds,
        everyElement(
          predicate<(int, int)>(
            (bound) => bound.$1 >= 1 && bound.$1 <= bound.$2 && bound.$2 <= 8,
          ),
        ),
      );
    });
  });

  group('bestiary drop chances', () {
    test('every creature has a chance between nothing and certainty', () {
      // arrange
      const creatures = bestiary;

      // act
      final chances = [for (final creature in creatures) creature.dropChance];

      // assert
      expect(chances, everyElement(inInclusiveRange(0, 100)));
    });

    test('something in the dungeon can actually drop loot', () {
      // arrange
      const creatures = bestiary;

      // act
      final generous = creatures.where((creature) => creature.dropChance > 0);

      // assert
      expect(generous, isNotEmpty);
    });

    test('a spawned creature carries its own drop chance', () {
      // arrange
      const creature = ghoul;

      // act
      final actor = creature.spawn(id: 'ghoul-1', at: const Position(1, 1));

      // assert
      expect(actor.dropChance, creature.dropChance);
    });
  });

  group('the starting kit', () {
    test('arms the hero with the rusty sword and two potions', () {
      // arrange
      final game = newGame();

      // act
      final held = game.equipment[EquipSlot.mainHand];

      // assert
      expect(held?.base, rustySword);
      expect(held?.rarity, Rarity.common);
      expect(game.inventory.map((item) => item.base), [
        healingPotion,
        healingPotion,
      ]);
    });

    test('every starting item has its own id', () {
      // arrange
      final game = newGame();

      // act
      final ids = [
        ...game.inventory.map((item) => item.id),
        ...game.equipment.values.map((item) => item.id),
      ];

      // assert
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('the derived stats match the game before there was any gear', () {
      // arrange
      final game = newGame();

      // act
      final derived = (
        heroAttack(game.hero, game.loadout),
        heroArmor(game.loadout),
        heroDodgePercent(game.loadout),
        heroMaxHp(game.hero, game.loadout),
        heroSpeed(game.hero, game.loadout),
      );

      // assert
      expect(derived, ((3, 5), 0, 0, 20, 10));
    });

    test('all four skills start untrained', () {
      // arrange
      final game = newGame();

      // act
      final skills = game.skills;

      // assert
      expect(skills, untrainedSkills);
    });

    test('the crawl carries a drop table for every depth it can reach', () {
      // arrange
      final game = newGame();

      // act
      final depths = game.dropTables.keys.toList()..sort();

      // assert
      expect(depths, [1, 2, 3, 4, 5]);
    });
  });

  group('floor litter', () {
    test('the first floor is scattered with items inside the table bounds', () {
      // arrange
      final table = dropTableFor(1);

      // act
      final counts = [
        for (var seed = 1; seed <= 20; seed++)
          newGame(
            worldSeed: seed,
          ).groundItems.values.fold(0, (sum, items) => sum + items.length),
      ];

      // assert
      expect(
        counts,
        everyElement(
          inInclusiveRange(table.minFloorItems, table.maxFloorItems),
        ),
      );
    });

    test('every littered item has its own id', () {
      // arrange
      final game = newGame(worldSeed: 12);

      // act
      final ids = game.groundItems.values
          .expand((items) => items)
          .map((item) => item.id)
          .toList();

      // assert
      expect(ids, isNotEmpty);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('the litter is a property of the seed, not of the fighting', () {
      // arrange
      final fighting = newGame(worldSeed: 55);
      final walking = newGame(worldSeed: 55);

      // act
      for (var turn = 0; turn < 30; turn++) {
        final (next, _) = step(fighting, const MoveAction(Direction.north));
        if (next.isGameOver) break;
      }
      final afterFighting = fighting.buildFloor(3);
      final afterWalking = walking.buildFloor(3);

      // assert
      expect(
        _describeLitter(afterFighting.groundItems),
        _describeLitter(afterWalking.groundItems),
      );
    });

    test('two crawls on one seed find the same things lying about', () {
      // arrange
      final one = newGame(worldSeed: 3);
      final other = newGame(worldSeed: 3);

      // act
      final litter = (
        _describeLitter(one.groundItems),
        _describeLitter(other.groundItems),
      );

      // assert
      expect(litter.$1, litter.$2);
    });

    test('different seeds scatter different things', () {
      // arrange
      final names = <String>{};

      // act
      for (var seed = 1; seed <= 25; seed++) {
        names.addAll(
          newGame(worldSeed: seed).groundItems.values
              .expand((items) => items)
              .map((item) => item.displayName),
        );
      }

      // assert
      expect(names.length, greaterThan(5));
    });
  });
}

/// Every littered tile and what lies on it, as strings a diff can read.
///
/// The items themselves are value objects, but a map of *lists* of them is not
/// comparable by value, so a determinism pin has to compare something flat.
List<String> _describeLitter(Map<Position, List<Item>> groundItems) => [
  for (final tile in groundItems.entries)
    '${tile.key}: ${tile.value.map((item) => item.displayName).join(", ")}',
];
