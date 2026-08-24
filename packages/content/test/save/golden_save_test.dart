import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/standing.dart';

/// A committed version-1 document with the hero in town.
///
/// Any change to the format reddens this, which is the whole point: a save
/// format that drifts quietly is a save format that stops reading yesterday's
/// saves, and the player finds out by losing a hero.
const String _goldenTown =
    '{"version":1,"active":"hero-1","heroes":{"hero-1":{"label":"He'
    'ro 1","profile":{"hp":14,"gold":30,"bankedGold":120,"worldSeed'
    '":"9007199254740993","visit":3,"equipment":{"mainHand":{"id":"'
    'drop-3","base":"war-axe","rarity":"rare","affixes":["keen","of'
    '-embers"]}},"inventory":[{"id":"kit-2","base":"healing-potion"'
    ',"rarity":"common","affixes":[]}],"bank":[{"id":"drop-1","base'
    '":"iron-sword","rarity":"common","affixes":[]}],"skills":{"arm'
    's":{"level":4,"xp":2},"might":{"level":0,"xp":0},"bulwark":{"l'
    'evel":0,"xp":0},"fleetfoot":{"level":0,"xp":0}}},"run":null,'
    '"dungeon":null,'
    '"inside":false,'
    '"world":{"at":"northgate","home":"northgate","day":30,'
    '"discovered":["crypt","northgate","stonebridge"],"journey":null},'
    '"merchant":{"bought":[],"sold":[],"town":null}}}}';

/// A committed version-1 document with a crawl the hero is standing in, so the
/// run block's shape is pinned as tightly as the profile's.
///
/// `inside` is true here and false in the other two, so the three goldens
/// between them pin both answers to the question a run block alone cannot
/// answer.
const String _goldenRun =
    '{"version":1,"active":"hero-1","heroes":{"hero-1":{"label":"He'
    'ro 1","profile":{"hp":20,"gold":0,"bankedGold":0,"worldSeed":"'
    '77","visit":0,"equipment":{"mainHand":{"id":"kit-1","base":"ru'
    'sty-sword","rarity":"common","affixes":[]}},"inventory":[{"id"'
    ':"kit-2","base":"healing-potion","rarity":"common","affixes":['
    ']},{"id":"kit-3","base":"healing-potion","rarity":"common","af'
    'fixes":[]}],"bank":[],"skills":{"arms":{"level":0,"xp":0},"mig'
    'ht":{"level":0,"xp":0},"bulwark":{"level":0,"xp":0},"fleetfoot'
    '":{"level":0,"xp":0}}},"run":{"depth":2,"worldSeed":"77","visi'
    't":1,"gold":9,"isGameOver":false,"nextDropNumber":4,"rngState"'
    ':"-8613303245920329199","lootRngState":"2420599403871909411","'
    'map":"#####\\n#.>.#\\n#####","hero":{"id":"hero","name":"you",'
    '"glyph":"@","x":1,"y":1,"hp":13,"maxHp":20,"attackMin":1,"atta'
    'ckMax":2,"speed":10,"energy":100,"dropChance":0,"pierce":0},"m'
    'onsters":[{"id":"ghoul-1","name":"the ghoul","glyph":"g","x":3'
    ',"y":1,"hp":5,"maxHp":12,"attackMin":2,"attackMax":4,"speed":1'
    '0,"energy":40,"dropChance":25,"pierce":0}],"visible":[[1,1],[2'
    ',1]],"explored":[[1,1],[2,1],[3,1]],"stairsDown":[2,1],"stairs'
    'Up":[1,1],"groundItems":[{"x":2,"y":1,"items":[{"id":"floor-2-'
    '1","base":"leather-cap","rarity":"fine","affixes":["sturdy"]}]'
    '}],"inventory":[],"equipment":{},"skills":{"arms":{"level":1,"'
    'xp":1},"might":{"level":0,"xp":0},"bulwark":{"level":0,"xp":0}'
    ',"fleetfoot":{"level":0,"xp":0}},"floors":[{"depth":1,"map":"#'
    '##\\n#.#\\n###","monsters":[],"groundItems":[],"explored":[[1,'
    '1]],"stairsDown":[1,1],"stairsUp":null}]},'
    '"dungeon":"crypt",'
    '"inside":true,'
    '"world":{"at":"crypt","home":"stonebridge","day":0,'
    '"discovered":["crypt","northgate","stonebridge"],"journey":null},'
    '"merchant":{"bought"'
    ':[],"sold":[],"town":null}}}}';

/// A committed version-1 document with two heroes in it.
///
/// The roster's own shape is pinned here: that `active` is a written field and
/// not the first key, and that heroes are written in key order however the map
/// was assembled. Both are what stop a reorder from silently switching hero.
///
/// Ilse carries visit state and Bram does not, so this document pins the whole
/// of the merchant block — a bought id, a whole item reference and the town the
/// shelf was rolled for — rather than only the shape two empty lists would show.
///
/// Ilse is also two days out of Stonebridge while Bram has never left home, so
/// between them the two heroes pin both answers the world block can give: a leg
/// being walked, and standing still. A document where nobody travelled would
/// leave the journey shape unpinned entirely.
const String _goldenTwoHeroes =
    '{"version":1,"active":"hero-2","heroes":{"hero-1":{"label":"Il'
    'se","profile":{"hp":20,"gold":40,"bankedGold":0,"worldSeed":"1'
    '11","visit":0,"equipment":{"mainHand":{"id":"kit-1","base":"ru'
    'sty-sword","rarity":"common","affixes":[]}},"inventory":[{"id"'
    ':"kit-2","base":"healing-potion","rarity":"common","affixes":['
    ']},{"id":"kit-3","base":"healing-potion","rarity":"common","af'
    'fixes":[]}],"bank":[],"skills":{"arms":{"level":0,"xp":0},"mig'
    'ht":{"level":0,"xp":0},"bulwark":{"level":0,"xp":0},"fleetfoot'
    '":{"level":0,"xp":0}}},"run":null,'
    '"dungeon":null,'
    '"inside":false,'
    '"world":{"at":"stonebridge","home":"stonebridge","day":30,'
    '"discovered":["crypt","northgate","stonebridge"],'
    '"journey":{"from":"stonebridge","to":"northgate","daysLeft":2}},'
    '"merchant":{"bought":["market-stonebridge-0-gear-1"],'
    '"sold":[{"id":"drop-3","base":"iron-sword","rarit'
    'y":"common","affixes":[]}],"town":"stonebridge"}},'
    '"hero-2":{"label":"Bram","profile'
    '":{"hp":20,"gold":0,"bankedGold":0,"worldSeed":"222","visit":0'
    ',"equipment":{"mainHand":{"id":"kit-1","base":"rusty-sword","r'
    'arity":"common","affixes":[]}},"inventory":[{"id":"kit-2","bas'
    'e":"healing-potion","rarity":"common","affixes":[]},{"id":"kit'
    '-3","base":"healing-potion","rarity":"common","affixes":[]}],"'
    'bank":[],"skills":{"arms":{"level":0,"xp":0},"might":{"level":'
    '0,"xp":0},"bulwark":{"level":0,"xp":0},"fleetfoot":{"level":0,'
    '"xp":0}}},"run":null,'
    '"dungeon":null,'
    '"inside":false,'
    '"world":{"at":"stonebridge","home":"stonebridge","day":0,'
    '"discovered":["crypt","stonebridge"],"journey":null},'
    '"merchant":{"bought":[],"sold":[],"town":null}}}}';

/// Ilse, one of the two heroes of the roster golden, built once because two
/// tests assemble the same roster in two different orders.
///
/// She is on the road, which is the only way the journey block gets pinned.
///
/// A hero standing at a node writes `journey: null`, so a document with nobody
/// travelling would leave the whole shape of a leg unpinned — and a decoder that
/// read `at` and quietly dropped the legs would keep every golden green while
/// putting a travelling hero back in the town they set out from.
SavedHero _pinnedIlse() => SavedHero(
  label: 'Ilse',
  profile: newProfile(worldSeed: 111).copyWith(gold: 40),
  world: Whereabouts(
    at: stonebridge,
    home: stonebridge,
    discovered: {stonebridge, northgate, cryptNode},
    day: 30,
    journey: Journey(from: stonebridge, to: northgate, daysLeft: 2),
  ),
  merchant: MerchantVisit(
    bought: const ['market-stonebridge-0-gear-1'],
    sold: const [Item(id: 'drop-3', base: ironSword, rarity: Rarity.common)],
    town: stonebridge,
  ),
);

SavedHero _pinnedBram() =>
    SavedHero(label: 'Bram', profile: newProfile(worldSeed: 222));

Profile _pinnedTown() => newProfile(worldSeed: 9007199254740993).copyWith(
  hero: newProfile().hero.copyWith(hp: 14),
  equipment: {
    EquipSlot.mainHand: const Item(
      id: 'drop-3',
      base: warAxe,
      rarity: Rarity.rare,
      affixes: [keen, ofEmbers],
    ),
  },
  inventory: const [
    Item(id: 'kit-2', base: healingPotion, rarity: Rarity.common),
  ],
  bank: const [Item(id: 'drop-1', base: ironSword, rarity: Rarity.common)],
  gold: 30,
  bankedGold: 120,
  visit: 3,
  skills: const {
    SkillId.arms: SkillState(level: 4, xp: 2),
    SkillId.might: SkillState(),
    SkillId.bulwark: SkillState(),
    SkillId.fleetfoot: SkillState(),
  },
);

GameState _pinnedRun() => GameState(
  map: FloorMap.parse('#####\n#.>.#\n#####'),
  hero: newProfile(
    worldSeed: 77,
  ).hero.copyWith(position: const Position(1, 1), hp: 13, energy: actThreshold),
  monsters: [
    const Actor(
      id: 'ghoul-1',
      name: 'the ghoul',
      glyph: 'g',
      position: Position(3, 1),
      hp: 5,
      maxHp: 12,
      attackMin: 2,
      attackMax: 4,
      speed: 10,
      energy: 40,
      dropChance: 25,
    ),
  ],
  rng: Rng.fromState(-8613303245920329199),
  lootRng: Rng.fromState(2420599403871909411),
  visible: {const Position(1, 1), const Position(2, 1)},
  explored: {const Position(1, 1), const Position(2, 1), const Position(3, 1)},
  buildFloor: residuumDungeon(77)(1),
  depth: 2,
  worldSeed: 77,
  visit: 1,
  stairsDown: const Position(2, 1),
  stairsUp: const Position(1, 1),
  gold: 9,
  floors: {
    1: FloorMemory(
      map: FloorMap.parse('###\n#.#\n###'),
      monsters: const [],
      groundItems: const {},
      explored: {const Position(1, 1)},
      stairsDown: const Position(1, 1),
      stairsUp: null,
    ),
  },
  groundItems: {
    const Position(2, 1): const [
      Item(
        id: 'floor-2-1',
        base: leatherCap,
        rarity: Rarity.fine,
        affixes: [sturdy],
      ),
    ],
  },
  skills: const {
    SkillId.arms: SkillState(level: 1, xp: 1),
    SkillId.might: SkillState(),
    SkillId.bulwark: SkillState(),
    SkillId.fleetfoot: SkillState(),
  },
  dropTables: dropTables,
  nextDropNumber: 4,
);

/// A hero who has walked the map: living at the second town, thirty days in,
/// with everywhere uncovered.
///
/// Deliberately not [newWhereabouts]. A golden whose world block was the
/// starting one would pin the default and nothing else, so a decoder that
/// ignored the block entirely and handed back a fresh hero would look correct.
Whereabouts _pinnedWhereabouts() => Whereabouts(
  at: northgate,
  home: northgate,
  discovered: {stonebridge, northgate, cryptNode},
  day: 30,
);

void main() {
  group('the golden save, hero in town', () {
    test('the committed document decodes to the pinned hero', () {
      // arrange
      const written = _goldenTown;

      // act
      final read = decodeSave(written);

      // assert
      expect(read, isA<SaveDocument>());
      expect((read as SaveDocument).profile, _pinnedTown());
      expect(read.run, isNull);
      expect(read.inside, isFalse);
      expect(read.world, _pinnedWhereabouts());
    });

    test('the encoder reproduces it byte for byte', () {
      // arrange
      final profile = _pinnedTown();

      // act
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: profile,
          world: _pinnedWhereabouts(),
        ),
      );

      // assert
      expect(written, _goldenTown);
    });
  });

  group('the golden save, crawl suspended', () {
    test('the committed document decodes to the pinned crawl', () {
      // arrange
      const written = _goldenRun;

      // act
      final read = decodeSave(written) as SaveDocument;

      // assert
      expect(read.profile, newProfile(worldSeed: 77));
      expect(read.inside, isTrue);
      expect(read.run!.depth, 2);
      expect(read.run!.visit, 1);
      expect(read.run!.map.toAscii(), '#####\n#.>.#\n#####');
      expect(read.run!.hero.hp, 13);
      expect(read.run!.monsters.single.energy, 40);
      expect(read.run!.rng.state, -8613303245920329199);
      expect(read.run!.lootRng.state, 2420599403871909411);
      expect(read.run!.floors[1]!.map.toAscii(), '###\n#.#\n###');
      expect(
        read.run!.groundItems.values.single.single.displayName,
        'Fine Sturdy Leather Cap',
      );
      expect(read.run!.nextDropNumber, 4);
      expect(read.world, atTheCrypt());
    });

    test('the encoder reproduces it byte for byte', () {
      // arrange
      final run = _pinnedRun();

      // act
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 77),
          world: atTheCrypt(),
          run: run,
          dungeon: cryptNode,
          inside: true,
        ),
      );

      // assert
      expect(written, _goldenRun);
    });
  });

  group('the golden save, two heroes', () {
    test('the committed document decodes to both heroes', () {
      // arrange
      const written = _goldenTwoHeroes;

      // act
      final read = decodeSave(written) as SaveDocument;

      // assert
      expect(read.heroes.keys.toList()..sort(), ['hero-1', 'hero-2']);
      expect(read.active, 'hero-2');
      expect(read.heroes['hero-1']!.label, 'Ilse');
      expect(read.heroes['hero-2']!.label, 'Bram');
      expect(read.heroes['hero-1']!.profile.worldSeed, 111);
      expect(read.heroes['hero-1']!.profile.gold, 40);
      expect(read.heroes['hero-2']!.profile.worldSeed, 222);
      expect(read.profile, read.heroes['hero-2']!.profile);
      expect(read.heroes['hero-1']!.inside, isFalse);
      expect(read.heroes['hero-2']!.inside, isFalse);
      expect(read.heroes['hero-1']!.merchant.bought, [
        'market-stonebridge-0-gear-1',
      ]);
      expect(read.heroes['hero-1']!.merchant.sold.single.id, 'drop-3');
      expect(read.heroes['hero-1']!.merchant.town, stonebridge);
      expect(read.heroes['hero-1']!.world.journey!.to, northgate);
      expect(read.heroes['hero-1']!.world.journey!.daysLeft, 2);
      expect(read.heroes['hero-1']!.world.day, 30);
      expect(read.heroes['hero-2']!.world, newWhereabouts());
      expect(read.heroes['hero-2']!.merchant, MerchantVisit.none);
    });

    test('the encoder reproduces it byte for byte', () {
      // arrange
      final document = SaveDocument(
        active: 'hero-2',
        heroes: {'hero-1': _pinnedIlse(), 'hero-2': _pinnedBram()},
      );

      // act
      final written = encodeSave(document);

      // assert
      expect(written, _goldenTwoHeroes);
    });

    test('the roster is written in key order, not insertion order', () {
      // arrange
      final backwards = SaveDocument(
        active: 'hero-2',
        heroes: {'hero-2': _pinnedBram(), 'hero-1': _pinnedIlse()},
      );

      // act
      final written = encodeSave(backwards);

      // assert
      expect(written, _goldenTwoHeroes);
    });
  });
}
