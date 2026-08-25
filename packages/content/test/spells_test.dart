import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// Every table this game rolls items off, by the name a failure should print.
Map<String, DropTable> _everyTable() => {
  for (final entry in dropTables.entries)
    'crypt depth ${entry.key}': entry.value,
  for (final dungeon in themedDungeons)
    for (final entry in dungeon.dropTables.entries)
      '${dungeon.node.value} depth ${entry.key}': entry.value,
  for (final dungeon in themedDungeons)
    '${dungeon.node.value} trophy': dungeon.trophyTable,
  'the road': roadDropTable,
  'the market': marketTable,
};

/// The books a table can actually give up, by book id.
Set<String> _booksIn(DropTable table) => {
  for (final entry in table.items)
    if (entry.value.isSpellBook && entry.weight > 0) entry.value.id,
};

void main() {
  group('the six spells', () {
    test('are exactly the ones this milestone ships', () {
      // arrange
      // act
      final ids = [for (final spell in spellbook) spell.id];

      // assert
      expect(ids, [
        'firebolt',
        'frost-lance',
        'mend',
        'ward',
        'bind',
        'banish',
      ]);
    });

    test('carry the numbers they were tuned to', () {
      // arrange
      // act
      final written = {
        for (final spell in spellbook)
          spell.id: (
            spell.school,
            spell.kind,
            spell.type,
            spell.requiredLevel,
            spell.manaCost,
            spell.min,
            spell.max,
          ),
      };

      // assert - an exact pin, so no spell's numbers can move without this
      // test and the tuning trail both being answered for
      expect(written, {
        'firebolt': (
          SkillId.wrath,
          SpellKind.bolt,
          DamageType.fire,
          0,
          2,
          2,
          4,
        ),
        'frost-lance': (
          SkillId.wrath,
          SpellKind.bolt,
          DamageType.frost,
          4,
          4,
          4,
          7,
        ),
        'mend': (SkillId.mending, SpellKind.mend, null, 0, 3, 8, 8),
        'ward': (SkillId.mending, SpellKind.ward, null, 3, 3, 6, 6),
        'bind': (SkillId.binding, SpellKind.bind, null, 0, 3, 3, 3),
        'banish': (SkillId.binding, SpellKind.banish, null, 4, 4, 0, 0),
      });
    });

    test('every spell belongs to a school that is a real skill', () {
      // arrange
      final schools = [for (final spell in spellbook) spell.school];

      // act
      final real = [for (final school in schools) school.isSchool];

      // assert
      expect(real, everyElement(isTrue));
    });

    test('every school opens with a spell a fresh hero can already read', () {
      // arrange
      const schools = [SkillId.wrath, SkillId.mending, SkillId.binding];

      // act
      final ungated = {
        for (final spell in spellbook)
          if (spell.requiredLevel == 0) spell.school,
      };

      // assert - a school whose every spell were gated could never train
      // itself past its own gate, because casting is the only thing that
      // trains one
      expect(ungated, schools.toSet());
    });

    test('every gate is reachable inside a delve or two of casting', () {
      // arrange - reaching level L from nothing costs L squared plus 3L casts,
      // at the one point per cast Contract 1 fixes
      int castsToReach(int level) => level * level + 3 * level;

      // act
      final costs = {
        for (final spell in spellbook)
          spell.id: castsToReach(spell.requiredLevel),
      };

      // assert - the spec's original 15/15/10 cost 270, 270 and 130 casts,
      // which is scores of floors of nothing but grinding; these are goals a
      // player meets while playing
      expect(costs.values, everyElement(lessThanOrEqualTo(28)));
    });

    test('spellsById answers for every spell and nothing else', () {
      // arrange
      // act
      final byId = spellsById;

      // act
      expect(byId.keys.toSet(), {for (final spell in spellbook) spell.id});
      expect(byId.length, spellbook.length);
    });

    test('a spell id nothing answers to comes back null, never thrown', () {
      // arrange
      // act
      final missing = spellOrNull('telekinesis');

      // assert
      expect(missing, isNull);
    });
  });

  group('the six books', () {
    test('there is exactly one book per spell, and no book without one', () {
      // arrange
      final taught = [for (final book in spellBooks) book.teaches];

      // act
      final spells = [for (final spell in spellbook) spell.id];

      // assert
      expect(taught..sort(), spells.toList()..sort());
    });

    test('every book teaches a spell this build actually casts', () {
      // arrange
      // act
      final known = [for (final book in spellBooks) spellOrNull(book.teaches!)];

      // assert
      expect(known, everyElement(isNotNull));
    });

    test('every book is in the armory, and answers to its own id', () {
      // arrange
      // act
      final found = [for (final book in spellBooks) baseItemById(book.id)];

      // assert
      expect(found, spellBooks);
    });

    test('a book is consumable, unworn and unswung', () {
      // arrange
      // act
      final shapes = [
        for (final book in spellBooks)
          (book.isConsumable, book.isEquippable, book.isWeapon, book.isPotion),
      ];

      // assert
      expect(shapes, everyElement((true, false, false, false)));
    });
  });

  group('where books are found', () {
    test('each dungeon gives up its own two and no others', () {
      // arrange
      Set<String> booksOf(Map<int, DropTable> tables) => {
        for (final table in tables.values) ..._booksIn(table),
      };

      // act
      final crypt = booksOf(dropTables);
      final cave = booksOf(seaCaveDropTables);
      final keep = booksOf(ruinedKeepDropTables);

      // assert - a book is a reason to walk somewhere in particular, which it
      // stops being the moment every place drops every book
      expect(crypt, {'book-of-bind', 'book-of-firebolt'});
      expect(cave, {'book-of-mend', 'book-of-frost-lance'});
      expect(keep, {'book-of-ward', 'book-of-banish'});
    });

    test('the three sets do not overlap at all', () {
      // arrange
      Set<String> booksOf(Map<int, DropTable> tables) => {
        for (final table in tables.values) ..._booksIn(table),
      };
      final crypt = booksOf(dropTables);
      final cave = booksOf(seaCaveDropTables);
      final keep = booksOf(ruinedKeepDropTables);

      // act
      final shared = crypt.intersection(cave)
        ..addAll(crypt.intersection(keep))
        ..addAll(cave.intersection(keep));

      // assert
      expect(shared, isEmpty);
    });

    test('no road fight and no trophy ever gives up a book', () {
      // arrange
      final closed = {
        'the road': roadDropTable,
        for (final dungeon in themedDungeons)
          '${dungeon.node.value} trophy': dungeon.trophyTable,
      };

      // act
      final offered = {
        for (final entry in closed.entries) entry.key: _booksIn(entry.value),
      };

      // assert - a trophy promises a rare, and a Common-forced book would
      // pay a winner in vendor trash
      expect(offered.values, everyElement(isEmpty));
    });

    test('the merchant shelves the two a fresh hero can read, and no more', () {
      // arrange
      // act
      final shelved = _booksIn(marketTable);

      // assert
      expect(shelved, {'book-of-firebolt', 'book-of-mend'});
    });

    test('every book in every table is one the armory knows', () {
      // arrange
      final tables = _everyTable();

      // act
      final unknown = {
        for (final entry in tables.entries)
          for (final weighted in entry.value.items)
            if (weighted.value.isSpellBook &&
                baseItemOrNull(weighted.value.id) == null)
              entry.key,
      };

      // assert
      expect(unknown, isEmpty);
    });

    test('every spell has somewhere its book can actually be found', () {
      // arrange
      final tables = _everyTable();

      // act
      final findable = {for (final table in tables.values) ..._booksIn(table)};

      // assert - a spell whose book drops nowhere is a spell nobody can cast
      expect(findable, {for (final book in spellBooks) book.id});
    });
  });

  group('what a book is worth', () {
    test('is its gate plus the flat term, before any tier multiplies it', () {
      // arrange
      Item shelved(BaseItem book) =>
          Item(id: 'x', base: book, rarity: Rarity.common);

      // act
      final prices = {
        for (final book in spellBooks) book.id: sellPriceOf(shelved(book)),
      };

      // assert
      expect(prices, {
        'book-of-firebolt': 10,
        'book-of-frost-lance': 14,
        'book-of-mend': 10,
        'book-of-ward': 13,
        'book-of-bind': 10,
        'book-of-banish': 14,
      });
    });

    test('is never the one gold a thing with no stats used to fetch', () {
      // arrange
      // act
      final prices = [
        for (final book in spellBooks)
          sellPriceOf(Item(id: 'x', base: book, rarity: Rarity.common)),
      ];

      // assert - worth is read off what a thing does, and what a book does is
      // not written in attack, armour or healing
      expect(prices, everyElement(greaterThan(1)));
    });

    test('a gated book is worth more than the one that opens its school', () {
      // arrange
      Item shelved(BaseItem book) =>
          Item(id: 'x', base: book, rarity: Rarity.common);

      // act
      final lance = sellPriceOf(shelved(bookOfFrostLance));
      final bolt = sellPriceOf(shelved(bookOfFirebolt));

      // assert
      expect(lance, greaterThan(bolt));
    });

    test('buying one always costs more than selling it back', () {
      // arrange
      // act
      final noArbitrage = [
        for (final book in spellBooks)
          buyPriceOf(Item(id: 'x', base: book, rarity: Rarity.common)) >
              sellPriceOf(Item(id: 'x', base: book, rarity: Rarity.common)),
      ];

      // assert
      expect(noArbitrage, everyElement(isTrue));
    });
  });

  group('what creatures are made of', () {
    List<CreatureSpec> everyCreature() => [
      ...bestiary,
      for (final dungeon in themedDungeons) ...dungeon.bestiary,
    ];

    test('no creature both resists and burns at the same type', () {
      // arrange
      final creatures = everyCreature();

      // act
      final contradictory = {
        for (final creature in creatures)
          if (creature.resists.intersection(creature.vulnerableTo).isNotEmpty)
            creature.id,
      };

      // assert - a row that said both would be a row nobody could read, and
      // the cast site would have to pick one arbitrarily
      expect(contradictory, isEmpty);
    });

    test('a spawned creature carries its make-up onto the floor', () {
      // arrange
      const spec = skeleton;

      // act
      final standing = spec.spawn(id: 'skeleton-1', at: const Position(1, 1));

      // assert
      expect(standing.resists, spec.resists);
      expect(standing.vulnerableTo, spec.vulnerableTo);
    });

    test('every dungeon holds something that resists and something that does '
        'not', () {
      // arrange
      final dungeons = {
        'the crypt': bestiary,
        for (final dungeon in themedDungeons)
          dungeon.node.value: dungeon.bestiary,
      };

      // act
      final answers = {
        for (final entry in dungeons.entries)
          entry.key: (
            entry.value.any((one) => one.resists.isNotEmpty),
            entry.value.any((one) => one.vulnerableTo.isNotEmpty),
          ),
      };

      // assert - a dungeon where nothing cares what you throw at it is a
      // dungeon where the choice of spell is not a choice
      expect(answers.values, everyElement((true, true)));
    });

    test('the sea-cave shrugs off the frost it teaches, and burns instead', () {
      // arrange
      final cave = theSeaCave.bestiary;

      // act
      final chilled = {
        for (final one in cave)
          if (one.resists.contains(DamageType.frost)) one.id,
      };
      final dry = {
        for (final one in cave)
          if (one.vulnerableTo.contains(DamageType.fire)) one.id,
      };

      // assert - the interesting direction is across dungeons: the cave hands
      // out Frost Lance and its own drowned shrug it off, so the answer to the
      // cave is the fire the crypt taught you
      expect(chilled, isNotEmpty);
      expect(dry, isNotEmpty);
      expect(chilled, dry);
    });

    test('the crypt holds one thing fire cannot touch', () {
      // arrange
      // act
      final proof = skeleton.resists;

      // assert - and the answer to it is the cave's frost, which is the trade
      // running the other way
      expect(proof, {DamageType.fire});
      expect(skeleton.vulnerableTo, {DamageType.frost});
    });

    test('no creature stat but resistance moved for magic', () {
      // arrange
      // act
      final shipped = {
        for (final one in [giantRat, direWolf, ghoul, skeleton, wight])
          one.id: (
            one.hp,
            one.attackMin,
            one.attackMax,
            one.speed,
            one.dropChance,
            one.pierce,
          ),
      };

      // assert - the tiered lever rule: resistance fields are content and free
      // with a trail, and none of these are
      expect(shipped, {
        'rat': (4, 1, 2, 10, 35, 0),
        'wolf': (8, 2, 3, 20, 40, 0),
        'ghoul': (10, 2, 4, 10, 50, 1),
        'skeleton': (16, 3, 5, 5, 60, 6),
        'wight': (20, 4, 6, 10, 70, 6),
      });
    });
  });

  group('the shipped spells, cast for real', () {
    GameState arena({
      Set<DamageType> resists = const {},
      Set<DamageType> vulnerableTo = const {},
      Set<String> knows = const {'firebolt'},
    }) {
      final map = FloorMap.parse('#######\n#.....#\n#######');
      const heroAt = Position(1, 1);
      final visible = computeFov(map, heroAt, fovRadius);
      return GameState(
        map: map,
        hero: const Actor(
          id: 'hero',
          name: 'you',
          glyph: '@',
          position: heroAt,
          hp: 20,
          maxHp: 20,
          attackMin: 1,
          attackMax: 2,
          speed: 10,
          energy: actThreshold,
        ),
        monsters: [
          Actor(
            id: 'target-1',
            name: 'the target',
            glyph: 't',
            position: const Position(4, 1),
            hp: 40,
            maxHp: 40,
            attackMin: 1,
            attackMax: 1,
            speed: 10,
            energy: actThreshold,
            resists: resists,
            vulnerableTo: vulnerableTo,
          ),
        ],
        rng: Rng(1),
        lootRng: Rng(2),
        visible: visible,
        explored: {...visible},
        buildFloor: (depth) => throw StateError('no floor below'),
        spells: spellsById,
        knownSpells: knows,
        mana: 20,
      );
    }

    SpellHit cast(GameState game, String spellId) {
      final (_, events) = step(game, CastSpellAction(spellId));
      return events.whereType<SpellHit>().single;
    }

    test('a firebolt off the shipped table deals what the table says', () {
      // arrange
      final game = arena();

      // act
      final hit = cast(game, 'firebolt');

      // assert - core's cast tests use their own fixtures, because core cannot
      // import content; this is the one test that casts the spell the game
      // actually ships
      expect(hit.damage, inInclusiveRange(firebolt.min, firebolt.max));
      expect(hit.spell, firebolt);
      expect(hit.bite, SpellBite.plain);
    });

    test('a frost lance off the shipped table deals what the table says', () {
      // arrange
      final game = arena(knows: const {'frost-lance'});

      // act
      final hit = cast(game, 'frost-lance');

      // assert
      expect(hit.damage, inInclusiveRange(frostLance.min, frostLance.max));
      expect(hit.spell.type, DamageType.frost);
    });

    test('the shipped firebolt is halved by a real resistance', () {
      // arrange
      final plain = arena();
      final tough = arena(resists: const {DamageType.fire});

      // act
      final full = cast(plain, 'firebolt');
      final dulled = cast(tough, 'firebolt');

      // assert
      expect(dulled.damage, full.damage ~/ 2);
      expect(dulled.bite, SpellBite.resisted);
    });

    test('the shipped firebolt is doubled by a real vulnerability', () {
      // arrange
      final plain = arena();
      final dry = arena(vulnerableTo: const {DamageType.fire});

      // act
      final full = cast(plain, 'firebolt');
      final doubled = cast(dry, 'firebolt');

      // assert
      expect(doubled.damage, full.damage * 2);
      expect(doubled.bite, SpellBite.vulnerable);
    });

    test('a ghoul burns and a skeleton does not', () {
      // arrange
      final onGhoul = arena(vulnerableTo: ghoul.vulnerableTo);
      final onBone = arena(resists: skeleton.resists);

      // act
      final burned = cast(onGhoul, 'firebolt');
      final shrugged = cast(onBone, 'firebolt');

      // assert - the bestiary and the spell table meet here, which is the only
      // place they do
      expect(burned.bite, SpellBite.vulnerable);
      expect(shrugged.bite, SpellBite.resisted);
    });

    test('casting the shipped spell spends the mana the table names', () {
      // arrange
      final game = arena();

      // act
      final (after, _) = step(game, const CastSpellAction('firebolt'));

      // assert
      expect(after.mana, 20 - firebolt.manaCost);
    });
  });
}
